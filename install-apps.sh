#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [[ $EUID -eq 0 ]]; then
    log_error "Please run this script as your normal user (without sudo)."
    exit 1
fi

log_info "Updating system..."
sudo pacman -Syu --noconfirm

PKGS_PACMAN=(

    neovim
    vim
    git
    base-devel

    nodejs
    npm

    docker
    docker-buildx

    libvirt
    libvirt-python
    virt-install
    virt-manager
    virt-viewer

    qemu-full
    edk2-ovmf
    swtpm
    virtio-win

    dnsmasq
    iptables-nft
    vde2
    openbsd-netcat
    usbredir

    spice
    spice-gtk
    spice-vdagent

    remmina
    freerdp

    wget
    curl
    rsync
    filezilla

    inkscape
    gimp
    krita
    blender
    kdenlive

    firefox
    chromium

    discord
    obs-studio

    libreoffice-fresh
    nextcloud-client
    okular

    vlc
    mpv

    kitty
    alacritty

    htop
    btop
    fastfetch

    bash-completion
    man-db
    man-pages
    reflector
    pkgfile
)

PKGS_AUR=(
    visual-studio-code-bin
    brave-bin
    spotify
    bitwarden
    joplin-appimage
)

log_info "Installing packages..."
sudo pacman -S --needed --noconfirm "${PKGS_PACMAN[@]}"

################################################################################
# yay
################################################################################

if ! command -v yay >/dev/null; then
    log_info "Installing yay..."

    TMP=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$TMP/yay-bin"

    pushd "$TMP/yay-bin"
    makepkg -si --noconfirm
    popd

    rm -rf "$TMP"
fi

################################################################################
# AUR
################################################################################

for pkg in "${PKGS_AUR[@]}"; do
    yay -S --needed --noconfirm "$pkg" || log_warn "$pkg failed."
done

################################################################################
# Docker
################################################################################

log_info "Configuring Docker..."

sudo systemctl enable --now docker.service

if ! groups "$USER" | grep -qw docker; then
    sudo usermod -aG docker "$USER"
fi

################################################################################
# Libvirt
################################################################################

log_info "Configuring Libvirt..."

sudo systemctl enable --now \
    libvirtd.service \
    virtlogd.service \
    virtnetworkd.service

if ! groups "$USER" | grep -qw libvirt; then
    sudo usermod -aG libvirt "$USER"
fi

if ! groups "$USER" | grep -qw kvm; then
    sudo usermod -aG kvm "$USER"
fi

################################################################################
# KVM
################################################################################

if grep -q GenuineIntel /proc/cpuinfo; then

    sudo modprobe kvm_intel

    echo kvm_intel | sudo tee /etc/modules-load.d/kvm.conf >/dev/null

    echo "options kvm_intel nested=1" |
        sudo tee /etc/modprobe.d/kvm.conf >/dev/null

elif grep -q AuthenticAMD /proc/cpuinfo; then

    sudo modprobe kvm_amd

    echo kvm_amd | sudo tee /etc/modules-load.d/kvm.conf >/dev/null

    echo "options kvm_amd nested=1" |
        sudo tee /etc/modprobe.d/kvm.conf >/dev/null
fi

################################################################################
# Default libvirt network
################################################################################

if ! sudo virsh -c qemu:///system net-info default >/dev/null 2>&1; then

    log_info "Creating libvirt default network..."

    sudo mkdir -p /etc/libvirt/qemu/networks

    sudo tee /etc/libvirt/qemu/networks/default.xml >/dev/null <<EOF
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF

    sudo virsh -c qemu:///system net-define \
        /etc/libvirt/qemu/networks/default.xml
fi

sudo virsh -c qemu:///system net-autostart default
sudo virsh -c qemu:///system net-start default || true

################################################################################
# systemd-resolved
################################################################################

sudo systemctl enable --now systemd-resolved

################################################################################
# UFW
################################################################################

if command -v ufw >/dev/null; then

    log_info "Configuring UFW..."

    HOST_IFACE=$(ip route | awk '/default/ {print $5; exit}')

    sudo ufw allow in on virbr0
    sudo ufw allow out on virbr0
    sudo ufw route allow in on virbr0 out on "$HOST_IFACE"

    sudo sed -i \
        's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' \
        /etc/default/ufw

    sudo ufw enable
    sudo ufw reload
fi

################################################################################
# pkgfile
################################################################################

sudo pkgfile --update

################################################################################
# VirtIO ISO
################################################################################

ISO=$(find /usr/share -name "virtio-win*.iso" 2>/dev/null | head -n1)

if [[ -n "$ISO" ]]; then
    log_info "VirtIO ISO available:"
    echo "  $ISO"
fi

################################################################################
# Checks
################################################################################

echo
log_info "Verification"

echo "--------------------------------"

echo "KVM:"
[[ -e /dev/kvm ]] && echo "  OK"

echo

echo "Libvirt:"
sudo virsh -c qemu:///system net-list --all

echo

echo "Docker:"
systemctl is-enabled docker

echo

echo "Done!"
echo
log_warn "Please LOG OUT or REBOOT so that docker/libvirt/kvm group membership becomes active."
echo

read -rp "Reboot now? [y/N] " REPLY

if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    sudo reboot
fi
