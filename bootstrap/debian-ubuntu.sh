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
    openssh-client \
    jq \
    build-essential \
    unzip \
    ripgrep
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

install_rust() {
  log "Installing Rust (rustup)..."

  if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    echo 'source "$HOME/.cargo/env"' >> "$HOME/.bashrc"
    echo 'source "$HOME/.cargo/env"' >> "$HOME/.zshrc"
    log "Rust installed successfully."
  else
    log "Rust already installed. Ensuring it's up to date..."
    source "$HOME/.cargo/env"
  fi

  rustup install stable
  rustup default stable
  log "Rust is now set to the latest stable version."
}

install_sdkman() {
  log "Installing SDKMAN!..."

  if [ ! -d "$HOME/.sdkman" ]; then
    curl -s "https://get.sdkman.io" | bash
  else
    log "SDKMAN! already installed. Skipping..."
  fi

  source "$HOME/.sdkman/bin/sdkman-init.sh"
  log "SDKMAN! ready to use."
}

install_java25() {
  log "Installing Java 25 (Temurin)..."

  if [ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    echo "❌ SDKMAN! not found. Please install it first."
    exit 1
  fi

  source "$HOME/.sdkman/bin/sdkman-init.sh"

  if ! sdk list java | grep -q "25.*tem"; then
    sdk install java 25-tem
  else
    sdk install java 25-tem || true
  fi

  sdk default java 25-tem
  log "Java 25 installed successfully!"
  java -version
}

install_jetbrains_toolbox() {
  log "Installing JetBrains Toolbox..."

  TMP_DIR=$(mktemp -d)
  cd "$TMP_DIR"

  TOOLBOX_URL=$(curl -s https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release \
    | grep -oP '(?<="linux":\{"link":")[^"]+')

  if [ -z "$TOOLBOX_URL" ]; then
    echo "❌ Could not determine JetBrains Toolbox download URL."
    return 1
  fi

  wget -O jetbrains-toolbox.tar.gz "$TOOLBOX_URL"
  tar -xzf jetbrains-toolbox.tar.gz
  cd jetbrains-toolbox-*
  ./jetbrains-toolbox & disown

  log "JetBrains Toolbox launched — install IntelliJ IDEA from there."
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
  sudo snap install discord
}

install_obsidian() {
  log "Installing Obsidian..."

  ARCH=$(dpkg --print-architecture)
  case "$ARCH" in
    amd64) ARCH_TAG="amd64" ;;
    arm64) ARCH_TAG="arm64" ;;
    *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
  esac

  OBSIDIAN_URL=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest \
    | grep "browser_download_url.*_${ARCH_TAG}.deb" \
    | cut -d '"' -f 4)

  if [ -z "$OBSIDIAN_URL" ]; then
    echo "❌ Could not find the latest Obsidian .deb package for ${ARCH_TAG}."
    exit 1
  fi

  wget -O /tmp/obsidian.deb "$OBSIDIAN_URL"
  sudo apt install -y /tmp/obsidian.deb || sudo apt --fix-broken install -y
  rm -f /tmp/obsidian.deb
}

install_dbeaver() {
  log "Installing DBeaver CE..."

  ARCH=$(dpkg --print-architecture)
  case "$ARCH" in
    amd64) ARCH_TAG="amd64" ;;
    arm64) ARCH_TAG="arm64" ;;
    *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
  esac

  DBEAVER_URL=$(curl -s https://api.github.com/repos/dbeaver/dbeaver/releases/latest \
    | grep "browser_download_url.*${ARCH_TAG}.deb" \
    | cut -d '"' -f 4)

  if [ -z "$DBEAVER_URL" ]; then
    echo "❌ Could not find the latest DBeaver .deb package for ${ARCH_TAG}."
    exit 1
  fi

  wget -O /tmp/dbeaver.deb "$DBEAVER_URL"
  sudo apt install -y /tmp/dbeaver.deb || sudo apt --fix-broken install -y
  rm -f /tmp/dbeaver.deb
}

install_spotify() {
  log "Installing Spotify..."
  curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
  echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
  sudo apt update
  sudo apt install -y spotify-client
}

install_latest_neovim() {
  log "Installing latest Neovim..."

  ARCH=$(dpkg --print-architecture)
  case "$ARCH" in
    amd64|x86_64) ARCH_TAG="x86_64" ;;
    arm64|aarch64) ARCH_TAG="arm64" ;;
    *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
  esac

  LATEST_URL=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | \
    jq -r ".assets[] | select(.name | contains(\"nvim-linux-${ARCH_TAG}.tar.gz\")) | .browser_download_url")


  if [ -z "$LATEST_URL" ]; then
    echo "❌ Could not find Neovim release URL for linux${ARCH_TAG}"
    exit 1
  fi

  wget -O /tmp/nvim.tar.gz "$LATEST_URL"
  sudo rm -rf /opt/nvim
  sudo mkdir -p /opt/nvim
  sudo tar -C /opt/nvim --strip-components=1 -xzf /tmp/nvim.tar.gz
  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  rm -f /tmp/nvim.tar.gz

  log "Neovim latest version installed successfully!"
}

install_alacritty() {
  log "Installing Alacritty..."

  sudo apt install -y cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev python3

  if ! command -v alacritty &> /dev/null; then
    git clone https://github.com/alacritty/alacritty.git /tmp/alacritty
    pushd /tmp/alacritty
    cargo build --release
    sudo cp target/release/alacritty /usr/local/bin
    sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
    sudo desktop-file-install extra/linux/Alacritty.desktop
    sudo update-desktop-database
    popd
    rm -rf /tmp/alacritty
  else
    log "Alacritty already installed. Skipping."
  fi
}

install_lazyvim() {
  log "Installing LazyVim..."

  NVIM_CONFIG_DIR="$HOME/.config/nvim"

  if [ ! -d "$NVIM_CONFIG_DIR" ]; then
    git clone https://github.com/LazyVim/starter "$NVIM_CONFIG_DIR"
    rm -rf "$NVIM_CONFIG_DIR/.git"
    log "LazyVim installed in $NVIM_CONFIG_DIR"
  else
    log "Neovim config directory already exists at $NVIM_CONFIG_DIR. Skipping LazyVim install."
  fi
}

install_nerd_fonts() {
  log "Installing Nerd Fonts..."

  mkdir -p ~/.local/share/fonts
  cd /tmp

  FONT="FiraCode"
  VERSION="3.0.2"

  wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v${VERSION}/${FONT}.zip" -O ${FONT}.zip
  unzip -o ${FONT}.zip -d ~/.local/share/fonts/${FONT}
  fc-cache -fv

  log "Nerd Font ${FONT} installed!"
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

configure_fn_keys() {
  log "Configuring function keys (F1–F12 as primary)..."

  if [ ! -f /etc/modprobe.d/hid_apple.conf ]; then
    echo 'options hid_apple fnmode=2' | sudo tee /etc/modprobe.d/hid_apple.conf
    sudo update-initramfs -u
    log "Permanent fnmode=2 configured. Please reboot to apply."
  else
    log "Permanent fnmode=2 already configured. Skipping."
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
install_rust
install_sdkman
install_java25
install_jetbrains_toolbox
install_vscode
install_chrome
install_postman
install_docker
install_gnome_tweaks
install_grub_customizer
install_discord
install_obsidian
install_dbeaver
install_spotify
install_latest_neovim
install_alacritty
install_lazyvim
install_nerd_fonts
generate_ssh_key
remove_firefox
configure_fn_keys

# Clean unused packages and apt cache
sudo apt autoremove -y
sudo apt clean

# Final log
completion_log
log "✅ All done! You may want to restart your terminal or source your shell config."