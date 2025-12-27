#!/usr/bin/env bash

# Strict error handling
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   log_error "This script should NOT be run as root (don't use sudo)"
   exit 1
fi

log_info "Starting CachyOS post-installation setup..."

# Update the system
log_info "Updating system packages..."
sudo pacman -Syu --noconfirm

# Official repository packages
PKGS_PACMAN=(
    # Development tools
    neovim
    vim
    git
    base-devel  # Required for AUR builds
    
    # Programming languages & package managers
    nodejs
    npm
    yarn
    
    # Container & virtualization
    docker
    docker-compose
    docker-buildx
    libvirt
    virt-manager
    virt-viewer
    qemu-full
    edk2-ovmf
    dnsmasq
    iptables-nft
    bridge-utils
    vde2
    openbsd-netcat
    usbredir
    spice
    spice-gtk
    spice-vdagent
    
    # Network & file transfer
    wget
    curl
    rsync
    filezilla
    
    # Graphics & creative
    inkscape
    gimp
    krita
    kdenlive
    blender
    
    # Browsers
    firefox
    chromium
    
    # Communication
    discord
    
    # Recording & streaming
    obs-studio
    
    # Office & productivity
    libreoffice-fresh
    nextcloud-client
    evolution
    
    # Media players
    vlc
    mpv
    
    # Terminal & monitoring
    alacritty
    kitty
    htop
    btop
    neofetch
    fastfetch
    
    # System utilities
    man-db
    man-pages
    bash-completion
    reflector  # For mirror management
    pkgfile    # For command-not-found functionality
)

# AUR packages
PKGS_AUR=(
    visual-studio-code-bin  # Official VS Code binary
    brave-bin
    joplin-appimage         # AppImage version is more stable
    bitwarden
    spotify
    # davinci-resolve       # Commented out: very large download, uncomment if needed
)

# Install official packages
log_info "Installing packages from official repositories..."
if sudo pacman -S --noconfirm --needed "${PKGS_PACMAN[@]}"; then
    log_info "Official packages installed successfully"
else
    log_error "Some official packages failed to install. Check errors above."
    exit 1
fi

# Install yay if not present
if ! command -v yay &> /dev/null; then
    log_info "yay not found. Installing yay..."
    
    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    
    # Cleanup
    cd ~
    rm -rf "$TEMP_DIR"
    
    log_info "yay installed successfully"
else
    log_info "yay is already installed"
fi

# Install AUR packages
log_info "Installing AUR packages..."
for pkg in "${PKGS_AUR[@]}"; do
    if yay -S --noconfirm --needed "$pkg"; then
        log_info "Installed: $pkg"
    else
        log_warn "Failed to install: $pkg (continuing...)"
    fi
done

# Docker setup
log_info "Configuring Docker..."
sudo systemctl enable --now docker.service

if ! groups "$USER" | grep -q docker; then
    sudo usermod -aG docker "$USER"
    log_info "Added $USER to docker group"
else
    log_info "User already in docker group"
fi

# Libvirt/KVM setup
log_info "Configuring libvirt and KVM..."

# Enable and start libvirtd
sudo systemctl enable --now libvirtd.service
sudo systemctl enable --now virtlogd.service

# Add user to libvirt group
if ! groups "$USER" | grep -q libvirt; then
    sudo usermod -aG libvirt "$USER"
    log_info "Added $USER to libvirt group"
else
    log_info "User already in libvirt group"
fi

# Detect CPU vendor and configure KVM
log_info "Detecting CPU and configuring KVM..."
if grep -Eq 'vendor_id.*GenuineIntel' /proc/cpuinfo; then
    log_info "Intel CPU detected"
    sudo modprobe kvm_intel
    echo "kvm_intel" | sudo tee /etc/modules-load.d/kvm.conf > /dev/null
elif grep -Eq 'vendor_id.*AuthenticAMD' /proc/cpuinfo; then
    log_info "AMD CPU detected"
    sudo modprobe kvm_amd
    echo "kvm_amd" | sudo tee /etc/modules-load.d/kvm.conf > /dev/null
else
    log_warn "Could not detect CPU vendor. KVM module not loaded."
fi

# Check KVM support
if [[ -e /dev/kvm ]]; then
    log_info "/dev/kvm found - Virtualization is working"
    
    # Set KVM permissions
    sudo usermod -aG kvm "$USER"
else
    log_error "/dev/kvm not found!"
    log_error "Please enable virtualization (VT-x/AMD-V) in your BIOS/UEFI"
fi

# Configure libvirt default network
log_info "Starting libvirt default network..."
sudo virsh net-autostart default 2>/dev/null || true
sudo virsh net-start default 2>/dev/null || true

# Enable systemd-resolved (if needed for dnsmasq)
if systemctl is-enabled systemd-resolved &> /dev/null; then
    log_info "systemd-resolved is enabled"
else
    log_info "Enabling systemd-resolved..."
    sudo systemctl enable --now systemd-resolved
fi

# Update pkgfile database for command-not-found
log_info "Updating pkgfile database..."
sudo pkgfile --update

# Final checks and information
log_info "Installation completed successfully!"
echo ""
log_warn "IMPORTANT: You need to log out and log back in (or reboot) for group changes to take effect!"
echo ""
log_info "Summary:"
echo "  - Docker: enabled and started"
echo "  - Libvirt: enabled and started"
echo "  - User groups: docker, libvirt, kvm"
echo "  - KVM modules: configured to load at boot"
echo ""
log_info "After reboot, verify with:"
echo "  - docker run hello-world"
echo "  - virsh list --all"
echo "  - ls -la /dev/kvm"
echo ""
read -p "Do you want to reboot now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Rebooting system..."
    systemctl reboot
fi
