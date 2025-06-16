# Arch Linux Setup Script

This repository contains a post-installation script (`install-apps.sh`) to quickly set up a full-featured desktop environment on Arch Linux or any Arch-based distribution (e.g. CachyOS, EndeavourOS, Garuda, etc.).

It installs a collection of essential developer tools, creative apps, browsers, system utilities, media tools, and virtualization clients.

## Included Software

### Development Tools
- `vscodium` (AUR)
- `neovim`, `vim`
- `nodejs`, `yarn`
- `git`, `wget`

### Docker
- `docker`
- `docker-compose`

### Creative Tools
- `inkscape`, `gimp`, `krita`
- `kdenlive`, `davinci-resolve` (AUR)

### Web Browsers
- `firefox`
- `chromium`
- `brave` (AUR)

### Communication
- `discord`

### Notes & Productivity
- `bitwarden` (AUR)
- `joplin-desktop` (AUR)
- `libreoffice-fresh`
- `nextcloud-client`
- `evolution`

### Media
- `vlc`, `mpv`, `spotify` (AUR)

### Terminal & System Info
- `alacritty`
- `htop`, `btop`
- `neofetch`, `fastfetch`

### Virtualization (Client Tools)
- `virt-manager`, `virt-viewer`

---

## How to Use

1. Clone the repository:
   ```bash
   git clone https://github.com/nick4vh/arch-packages.git

2. Navigate into the cloned directory:
   ```bash
   cd arch-packages

3. Make the script executable:
   ```bash
   chmod +x install-apps.sh

4. Run the script:
    ```bash
    ./install-apps.sh

Alternatively, run it directly without cloning:
```bash
bash <(curl -s https://raw.githubusercontent.com/nick4vh/arch-packages/main/install-apps.sh)

