#!/bin/bash

set -euo pipefail

#---------------------------------------------
#   Arch Linux Bootstrap Script
#   Installs common developer tools
#---------------------------------------------

# Functions
log() {
  echo -e "\n🔧 $1"
}

install_pacman_packages() {
  log "Updating pacman and installing base packages..."
  sudo pacman -Syu --noconfirm
  sudo pacman -S --noconfirm \
    git \
    curl \
    wget \
    ca-certificates \
    lsb-release \
    remmina \
    openssh \
    base-devel \
    cmake \
    python \
    zsh
}

install_yay() {
  log "Installing yay (AUR helper)..."
  if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    pushd /tmp/yay
    makepkg -si --noconfirm
    popd
    rm -rf /tmp/yay
  else
    log "yay is already installed. Skipping."
  fi
}

install_nvm_and_node() {
  log "Installing NVM and latest LTS Node.js..."
  export NVM_DIR="$HOME/.nvm"
  if [ ! -d "$NVM_DIR" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  fi
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm install --lts
  nvm alias default lts/*
}

install_golang() {
  log "Installing Go..."
  sudo pacman -S --noconfirm go
}

install_rust() {
  log "Installing Rust..."
  if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    echo 'source "$HOME/.cargo/env"' >> ~/.bashrc
    echo 'source "$HOME/.cargo/env"' >> ~/.zshrc
  fi
  rustup install stable
  rustup default stable
}

install_sdkman_and_java() {
  log "Installing SDKMAN and Java 25..."
  if [ ! -d "$HOME/.sdkman" ]; then
    curl -s "https://get.sdkman.io" | bash
  fi

  export SDKMAN_DIR="$HOME/.sdkman"
  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

  sdk install java 25-open
  sdk default java 25-open

  log "Java 25 installed successfully via SDKMAN."
}

install_jetbrains_toolbox() {
  log "Installing JetBrains Toolbox (AUR)..."
  yay -S --noconfirm jetbrains-toolbox
}

install_vscode() {
  log "Installing Visual Studio Code (AUR)..."
  yay -S --noconfirm visual-studio-code-bin
}

install_chrome() {
  log "Installing Google Chrome (AUR)..."
  yay -S --noconfirm google-chrome
}

install_postman() {
  log "Installing Postman (AUR)..."
  yay -S --noconfirm postman-bin
}

install_docker() {
  log "Installing Docker..."
  sudo pacman -S --noconfirm docker
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker "$USER"
  log "Docker installed and user added to docker group. Logout/reboot may be required."
}

install_discord() {
  log "Installing Discord (AUR)..."
  yay -S --noconfirm discord
}

install_obsidian() {
  log "Installing Obsidian (AUR)..."
  yay -S --noconfirm obsidian
}

install_dbeaver() {
  log "Installing DBeaver Community Edition (AUR)..."
  yay -S --noconfirm dbeaver
}

install_spotify() {
  log "Installing Spotify (AUR)..."
  yay -S --noconfirm spotify
}

generate_ssh_key() {
  log "Generating SSH key..."
  SSH_KEY="$HOME/.ssh/id_ed25519"
  if [ ! -f "$SSH_KEY" ]; then
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$USER@$(hostname)" -f "$SSH_KEY" -N ""
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY"
  else
    log "SSH key already exists. Skipping generation."
  fi
}

remove_firefox() {
  log "Removing Firefox..."
  sudo pacman -Rns --noconfirm firefox || true
}

configure_fn_keys() {
  log "Configuring function keys (F1–F12 as primary)..."
  if [ ! -f /etc/modprobe.d/hid_apple.conf ]; then
    echo 'options hid_apple fnmode=2' | sudo tee /etc/modprobe.d/hid_apple.conf
    sudo mkinitcpio -P
    log "fnmode=2 set. Please reboot to apply changes."
  else
    log "fnmode=2 already configured. Skipping."
  fi
}

completion_log() {
  log "🔍 Installed Versions:"
  echo "Git:           $(git --version | cut -d ' ' -f3)"
  echo "Node.js:       $(node -v 2>/dev/null || echo 'Not installed')"
  echo "npm:           $(npm -v 2>/dev/null || echo 'Not installed')"
  echo "Go:            $(go version 2>/dev/null | awk '{print $3}')"
  echo "Java:          $(java -version 2>&1 | head -n 1 || echo 'Not installed')"
  echo "Docker:        $(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')"
  echo "VSCode:        $(code --version 2>/dev/null | head -n1 || echo 'Not installed')"
  echo "Chrome:        $(google-chrome --version 2>/dev/null || echo 'Not installed')"
  echo ""
  echo "📎 SSH Public Key:"
  cat ~/.ssh/id_ed25519.pub 2>/dev/null || echo "No SSH key found."
}

# Execution
install_pacman_packages
install_yay
install_nvm_and_node
install_golang
install_rust
install_sdkman_and_java
install_jetbrains_toolbox
install_vscode
install_chrome
install_postman
install_docker
install_discord
install_obsidian
install_dbeaver
install_spotify
generate_ssh_key
remove_firefox
configure_fn_keys

completion_log
log "✅ All done! You may want to restart your terminal or reboot your system."
