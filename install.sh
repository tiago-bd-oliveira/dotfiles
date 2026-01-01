#!/bin/bash

# --- VARIABLES ---
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$HOME/.config"

echo "-----------------------------------------"
echo "Starting Arch Restoration Script..."
echo "-----------------------------------------"

# --- 1. SYSTEM UPDATES & DEPENDENCIES ---
echo "Installing git and base-devel..."
sudo pacman -S --needed git base-devel

# --- 2. INSTALL YAY (AUR Helper) ---
if ! command -v yay &> /dev/null; then
    echo "Installing Yay..."
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    echo "Yay is already installed."
fi

# --- 3. RESTORE PACKAGES ---
if [ -f "$DOTFILES_DIR/pacman_pkglist.txt" ]; then
    echo "Installing Native Packages..."
    sudo pacman -S --needed - < "$DOTFILES_DIR/pacman_pkglist.txt"
fi

if [ -f "$DOTFILES_DIR/aur_pkglist.txt" ]; then
    echo "Installing AUR Packages..."
    yay -S --needed - < "$DOTFILES_DIR/aur_pkglist.txt"
fi

# --- 4. LINK CONFIG FOLDERS (Stow-style) ---
# This links your folders (qtile, kitty, picom, fastfetch) to ~/.config/
# It backs up existing folders if they exist.

link_config() {
    local app_name=$1
    local src="$DOTFILES_DIR/config/$app_name"
    local dest="$CONFIG_DIR/$app_name"

    if [ -d "$src" ]; then
        echo "Configuring $app_name..."
        mkdir -p "$CONFIG_DIR"
        
        if [ -d "$dest" ] && [ ! -L "$dest" ]; then
            echo "  Backing up existing $dest to $dest.backup"
            mv "$dest" "$dest.backup"
        fi

        # Remove dead symlink if it exists
        if [ -L "$dest" ]; then
            unlink "$dest"
        fi

        ln -s "$src" "$dest"
        echo "  Linked: $src -> $dest"
    else
        echo "  Warning: Config source for $app_name not found."
    fi
}

link_config "qtile"
link_config "kitty"
link_config "picom"
link_config "fastfetch"

# --- 5. RESTORE SSH KEYS ---
# Checks if the backup folder exists locally (it won't exist if you cloned from git without copying secrets manually)
if [ -d "$DOTFILES_DIR/secret_ssh_backup" ]; then
    echo "Restoring SSH Keys..."
    mkdir -p "$HOME/.ssh"
    cp "$DOTFILES_DIR/secret_ssh_backup/"* "$HOME/.ssh/"
    
    # CRITICAL: Fix permissions
    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh/id_ed25519"
    chmod 644 "$HOME/.ssh/id_ed25519.pub"
    echo "SSH keys restored with correct permissions."
else
    echo "Skipping SSH restore (backup folder not found)."
fi

# --- 6. RESTORE GPG KEYS ---
if command -v gpg &> /dev/null; then
    echo "Restoring GPG Keys..."
    if [ -f "$DOTFILES_DIR/my-private-key.asc" ]; then
        gpg --import "$DOTFILES_DIR/my-private-key.asc"
    fi
    if [ -f "$DOTFILES_DIR/my-public-key.asc" ]; then
        gpg --import "$DOTFILES_DIR/my-public-key.asc"
    fi
fi

# --- 7. SHELL SETUP (Zsh + P10k) ---
# Note: Your tree view didn't show .zshrc or .p10k.zsh in the root. 
# If they are there, uncomment the lines below.

# echo "Linking .zshrc and .p10k.zsh..."
# ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
# ln -sf "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"

echo "-----------------------------------------"
echo "Restoration Complete!"
echo "Please restart your session or reboot."
echo "-----------------------------------------"
