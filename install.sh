#!/usr/bin/env bash
# Full setup for tiago-bd-oliveira/dotfiles on a fresh Arch install.
# Usage: bash install.sh [--no-aur] [--no-packages] [--no-vscode]
set -uo pipefail

REPO_URL="https://github.com/tiago-bd-oliveira/dotfiles.git"
DOTFILES="$HOME/.dotfiles"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
STOW_PKGS=(x11 zsh git apps vscode)
SERVICES=(NetworkManager bluetooth sddm docker cronie)
USER_TIMERS=(rotate-wallpaper cleanup-downloads)   # apps/.config/systemd/user

DO_PACKAGES=1 DO_AUR=1 DO_VSCODE=1
for arg in "$@"; do
  case "$arg" in
    --no-packages) DO_PACKAGES=0 ;;
    --no-aur)      DO_AUR=0 ;;
    --no-vscode)   DO_VSCODE=0 ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

FAILED=()
log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  -> %s\033[0m\n' "$*"; }

[[ $EUID -eq 0 ]] && { echo "Run as your normal user, not root."; exit 1; }
command -v pacman >/dev/null || { echo "This script is for Arch Linux."; exit 1; }

# Keep sudo alive for the whole run
sudo -v || exit 1
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &

# ---------------------------------------------------------------- repo
log "Getting dotfiles"
sudo pacman -S --needed --noconfirm git stow base-devel
if [[ -d "$DOTFILES/.git" ]]; then
  git -C "$DOTFILES" pull --ff-only || warn "Could not pull; using local copy"
else
  git clone "$REPO_URL" "$DOTFILES" || exit 1
fi

# ---------------------------------------------------------------- pacman
install_list() {
  # $1 = installer command, rest = packages. Bulk first, then one by one.
  local -a cmd; read -ra cmd <<< "$1"; shift
  [[ $# -eq 0 ]] && return
  if ! "${cmd[@]}" "$@"; then
    warn "Bulk install failed, retrying packages individually"
    for p in "$@"; do
      "${cmd[@]}" "$p" || FAILED+=("$p")
    done
  fi
}

EXTRA_AUR=()
if (( DO_PACKAGES )); then
  log "Enabling multilib (needed for steam and lib32 packages)"
  if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
  fi

  log "Updating system"
  sudo pacman -Syu --noconfirm

  log "Installing repo packages"
  mapfile -t wanted < <(grep -vE '^\s*(#|$)' "$DOTFILES/system/packages.list")
  # Lookup table, not `printf | grep -q`: grep -q exits early, printf gets
  # SIGPIPE, and pipefail turns that into a false "not found"
  declare -A available=()
  while read -r p; do available[$p]=1; done < <(pacman -Slq)
  repo_pkgs=()
  for p in "${wanted[@]}"; do
    if [[ -n ${available[$p]-} ]]; then
      repo_pkgs+=("$p")
    else
      EXTRA_AUR+=("$p")   # not in repos, try the AUR later
    fi
  done
  install_list "sudo pacman -S --needed --noconfirm" "${repo_pkgs[@]}"
fi

# ---------------------------------------------------------------- AUR
if (( DO_AUR )); then
  if ! command -v yay >/dev/null; then
    log "Installing yay"
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin" &&
      (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
  fi
  if command -v yay >/dev/null; then
    log "Installing AUR packages (this can take a long time)"
    mapfile -t aur < <(grep -vE '^\s*(#|$)|^yay$' "$DOTFILES/system/aur-packages.list")
    install_list "yay -S --needed --noconfirm --answerdiff None --answerclean None" \
      "${aur[@]}" "${EXTRA_AUR[@]}"
  else
    warn "yay install failed; skipping AUR packages"
  fi
fi

# ---------------------------------------------------------------- zsh
log "Setting up Oh My Zsh + plugins"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ZC="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
clone() { [[ -d "$2" ]] || git clone --depth=1 "$1" "$2"; }
clone https://github.com/romkatv/powerlevel10k.git              "$ZC/themes/powerlevel10k"
clone https://github.com/zsh-users/zsh-autosuggestions.git      "$ZC/plugins/zsh-autosuggestions"
clone https://github.com/zsh-users/zsh-syntax-highlighting.git  "$ZC/plugins/zsh-syntax-highlighting"

# ---------------------------------------------------------------- stow
log "Linking dotfiles with stow (existing files backed up to $BACKUP)"
cd "$DOTFILES" || exit 1
# Pre-create so stow links the unit files, not the whole dir (enable writes into it)
mkdir -p "$HOME/.config/systemd/user"
for pkg in "${STOW_PKGS[@]}"; do
  [[ -d "$pkg" ]] || continue
  while IFS= read -r -d '' f; do
    rel="${f#"$pkg"/}"
    target="$HOME/$rel"
    # Already served from the repo (e.g. via a folded dir symlink) — moving it would delete the source
    [[ "$(realpath -m "$target")" == "$DOTFILES"/* ]] && continue
    if [[ -e "$target" && ! -L "$target" ]]; then
      mkdir -p "$BACKUP/$(dirname "$rel")"
      mv "$target" "$BACKUP/$rel"
    fi
  done < <(find "$pkg" -type f -print0)
  stow --restow --target="$HOME" "$pkg" || FAILED+=("stow:$pkg")
done

# ---------------------------------------------------------------- shell & services
if [[ "$SHELL" != *zsh ]] && command -v zsh >/dev/null; then
  log "Changing default shell to zsh"
  chsh -s "$(command -v zsh)" || FAILED+=("chsh")
fi

log "Enabling services"
for s in "${SERVICES[@]}"; do
  if [[ -n $(systemctl list-unit-files "$s.service" --no-legend 2>/dev/null) ]]; then
    sudo systemctl enable "$s.service" || FAILED+=("service:$s")
  else
    warn "Skipped $s (not installed)"
  fi
done
getent group docker >/dev/null && sudo usermod -aG docker "$USER"

log "Enabling user timers"
if systemctl --user daemon-reload 2>/dev/null; then
  for t in "${USER_TIMERS[@]}"; do
    systemctl --user enable --now "$t.timer" || FAILED+=("timer:$t")
  done
else
  # No user manager reachable (e.g. run over plain su); link them in by hand
  mkdir -p "$HOME/.config/systemd/user/timers.target.wants"
  for t in "${USER_TIMERS[@]}"; do
    ln -sf "$HOME/.config/systemd/user/$t.timer" "$HOME/.config/systemd/user/timers.target.wants/$t.timer"
  done
  warn "User systemd not running; timers will start on next login"
fi

# ---------------------------------------------------------------- vscode
if (( DO_VSCODE )) && command -v code >/dev/null; then
  log "Installing VS Code extensions"
  while read -r ext; do
    code --install-extension "$ext" --force || FAILED+=("vscode:$ext")
  done < <(grep -vE '^\s*(#|$)' "$DOTFILES/vscode/extensions.list")
fi

# ---------------------------------------------------------------- done
log "Done!"
if (( ${#FAILED[@]} )); then
  warn "These failed and need a manual look:"
  printf '     %s\n' "${FAILED[@]}"
fi
echo "Reboot to start SDDM/Hyprland and use zsh."
