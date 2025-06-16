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
  qemu-full
  edk2-ovmf
  dnsmasq
  iptables-nft
  bridge-utils
  vde2
  openbsd-netcat
  libvirt
  usbredir
  spice
  spice-gtk
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

# Enable and start libvirtd service
echo "==> Enabling and starting libvirtd service..."
sudo systemctl enable --now libvirtd.service

# Add current user to docker and libvirt groups
echo "==> Adding current user to the docker and libvirt groups..."
sudo usermod -aG docker,libvirt "$USER"

# Load KVM kernel module (Intel or AMD detection)
echo "==> Loading KVM kernel modules..."
if grep -E -q 'vendor_id.*GenuineIntel' /proc/cpuinfo; then
  sudo modprobe kvm_intel
elif grep -E -q 'vendor_id.*AuthenticAMD' /proc/cpuinfo; then
  sudo modprobe kvm_amd
fi

# Ensure /dev/kvm exists
if [ ! -e /dev/kvm ]; then
  echo "ERROR: /dev/kvm does not exist. Virtualization support may be disabled in BIOS/UEFI."
else
  echo "==> /dev/kvm found. Virtualization is supported."
fi

# Set correct permissions on /home for QEMU (if Btrfs Snapshots, etc.)
echo "==> Setting permissions on /home for QEMU..."
chmod o+rx /home/"$USER"

echo "==> KVM/QEMU/libvirt setup completed. Please reboot or re-login to apply group changes."
