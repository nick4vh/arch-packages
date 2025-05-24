#!/usr/bin/env bash

set -e

echo "==> Starting installation..."

# Update the system
sudo pacman -Syu --noconfirm

# Official repository packages
PKGS_PACMAN=(
  neovim
  vim
  nodejs
  yarn
  git
  wget
  docker
  docker-compose
  filezilla
  inkscape
  gimp
  krita
  kdenlive
  firefox
  chromium
  discord
  obs-studio
  libreoffice-fresh
  nextcloud-client
  evolution
  vlc
  mpv
  alacritty
  htop
  btop
  neofetch
  fastfetch
  virt-manager
  virt-viewer
)

# AUR packages – yay must be installed
PKGS_AUR=(
  vscodium
  brave-bin
  joplin-desktop
  bitwarden
  spotify
  davinci-resolve
)

echo "==> Installing packages from the official repositories..."
sudo pacman -S --noconfirm --needed "${PKGS_PACMAN[@]}"

# Check if yay is installed
if ! command -v yay &> /dev/null; then
  echo "==> yay not found. Installing yay..."
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ..
  rm -rf yay
fi

echo "==> Installing AUR packages..."
yay -S --noconfirm --needed "${PKGS_AUR[@]}"

# Add current user to docker group
echo "==> Adding current user to the docker group..."
sudo usermod -aG docker "$USER"

echo "==> Installation completed. A reboot or re-login may be required."
