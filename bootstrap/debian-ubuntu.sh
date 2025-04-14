#!/bin/bash

set -euo pipefail

#---------------------------------------------
#   Linux Bootstrap Script
#   Installs common developer tools
#   Tested on Debian/Ubuntu-based systems
#---------------------------------------------

# Functions
log() {
  echo -e "\n🔧 $1"
}

install_apt_packages() {
  log "Updating apt and installing packages..."
  sudo apt update && sudo apt upgrade -y
  sudo apt install -y \
    git \
    curl \
    wget \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    remmina \
    openssh-client
}

install_nvm_and_node() {
  log "Installing NVM (Node Version Manager)..."
  export NVM_DIR="$HOME/.nvm"
  if [ ! -d "$NVM_DIR" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  fi
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

  log "Installing latest LTS version of Node.js..."
  nvm install --lts
  set +u
  nvm use --lts
  nvm alias default 'lts/*'
  set -u
}

install_golang() {
  log "Installing latest Go (Golang)..."

  GO_URL=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
  GO_VERSION=${GO_URL#go}
  ARCH=$(dpkg --print-architecture)

  case "$ARCH" in
    amd64) GO_ARCH="amd64" ;;
    arm64) GO_ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
  esac

  wget "https://go.dev/dl/${GO_URL}.linux-${GO_ARCH}.tar.gz" -O /tmp/go.tar.gz
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf /tmp/go.tar.gz
  rm -f /tmp/go.tar.gz

  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
  export PATH=$PATH:/usr/local/go/bin
}

install_vscode() {
  log "Installing Visual Studio Code..."
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
  sudo sh -c 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
  sudo apt update
  sudo apt install -y code
  rm -f packages.microsoft.gpg
}

install_chrome() {
  log "Installing Google Chrome..."
  wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb
  sudo apt install -y /tmp/chrome.deb || sudo apt --fix-broken install -y
  rm -f /tmp/chrome.deb
}

install_postman() {
  log "Installing Postman via Snap..."
  sudo snap install postman
}

install_docker() {
  log "Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  rm -f get-docker.sh
  sudo usermod -aG docker "$USER"
  log "Docker installed. You may need to log out and back in for group changes to apply."
}

install_gnome_tweaks() {
  log "Installing GNOME Tweaks..."
  sudo apt install -y gnome-tweaks
}

install_grub_customizer() {
  log "Installing GRUB Customizer..."
  sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer
  sudo apt update
  sudo apt install -y grub-customizer
}

install_discord() {
  log "Installing Discord..."
  wget -O /tmp/discord.deb "https://discordapp.com/api/download?platform=linux&format=deb"
  sudo apt install -y /tmp/discord.deb
  rm -f /tmp/discord.deb
}

install_spotify() {
  log "Installing Spotify..."
  curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
  echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
  sudo apt update
  sudo apt install -y spotify-client
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
  sudo apt remove -y firefox || true
}

completion_log() {
  log "🔍 Installed Versions:"
  echo "Git:           $(git --version | cut -d ' ' -f3)"
  echo "Node.js:       $(node -v 2>/dev/null || echo 'Not installed')"
  echo "npm:           $(npm -v 2>/dev/null || echo 'Not installed')"
  echo "Go:            $(go version 2>/dev/null | awk '{print $3}')"
  echo "Docker:        $(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')"
  echo "VSCode:        $(dpkg -s code 2>/dev/null | grep Version | awk '{print $2}')"
  echo "Google Chrome: $(google-chrome --version 2>/dev/null || echo 'Not installed')"
  echo "Postman:       $(snap list postman 2>/dev/null | grep postman | awk '{print $2}' || echo 'Not installed')"
  echo "Discord:       $(dpkg -s discord 2>/dev/null | grep Version | awk '{print $2}' || echo 'Not installed')"
  echo "Spotify:       $(dpkg -s spotify-client 2>/dev/null | grep Version | awk '{print $2}' || echo 'Not installed')"
  echo ""
  echo "📎 SSH Public Key:"
  cat ~/.ssh/id_ed25519.pub 2>/dev/null || echo "No SSH key found."
}

# Run all installers
install_apt_packages
install_nvm_and_node
install_golang
install_vscode
install_chrome
install_postman
install_docker
install_gnome_tweaks
install_grub_customizer
install_discord
install_spotify
generate_ssh_key
remove_firefox

# Clean unused packages and apt cache
sudo apt autoremove -y
sudo apt clean

# Final log
completion_log
log "✅ All done! You may want to restart your terminal or source your shell config."
