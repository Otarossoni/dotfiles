# 🗂️ Dotfiles

This repository contains my personal dotfiles and environment setup configurations, used to provision and configure Linux systems for development.

## ✨ Features

- Scripts to automate development environment setup
- Global Git settings

## 📦 Bootstrap Script

The `bootstrap/debian-ubuntu.sh` script automates the installation of common development tools on **Debian/Ubuntu-based** systems.

### Includes

- **Essential packages**: `git`, `curl`, `wget`, `gnupg`, `lsb-release`, and others
- **NVM & Node.js** (latest LTS version)
- **Go (Golang)** (latest stable version)
- **Visual Studio Code**
- **Google Chrome**
- **Postman** (via Snap)
- **Docker**
- **GNOME Tweaks**
- **Grub Customizer**
- **Discord**
- **Spotify**
- **Global Git configuration**
- **Firefox removal** (optional)

### Debian/Ubuntu Usage

```bash
# Clone this repository
git clone https://github.com/your-username/dotfiles.git
cd dotfiles

# Make the script executable
chmod +x bootstrap/debian-ubuntu.sh

# Run the script
./bootstrap/debian-ubuntu.sh
```

### Arch Usage

```bash
# Clone this repository
git clone https://github.com/your-username/dotfiles.git
cd dotfiles

# Make the script executable
chmod +x bootstrap/arch.sh

# Run the script
./bootstrap/arch.sh
```
