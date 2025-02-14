#!/bin/bash

set -e

# Function to check the Linux distribution
get_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo $ID
  else
    echo "Unknown"
  fi
}

# Function to check if the system is running GNOME
is_gnome() {
  if [ "$(echo $XDG_CURRENT_DESKTOP | grep -i 'gnome')" ]; then
    return 0
  else
    return 1
  fi
}

# Function to install Docker and Docker Compose
install_docker() {
  echo "Installing Docker..."
  if command -v docker &>/dev/null; then
    echo "Docker is already installed."
  else
    distro=$(get_distro)
    case "$distro" in
      ubuntu|debian|linuxmint)
        apt-get update
        apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/$distro/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$distro $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        ;;
      fedora|centos|rhel)
        dnf install -y dnf-plugins-core
        dnf config-manager --add-repo https://download.docker.com/linux/$(get_distro)/docker-ce.repo
        dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        ;;
      arch)
        pacman -Syu --noconfirm docker docker-compose
        ;;
      *)
        echo "Unsupported distribution for Docker installation."
        return 1
        ;;
    esac
  fi

  systemctl enable --now docker
  usermod -aG docker $USER
  echo "Docker installation completed. You may need to restart your shell for user group changes."
}

# Function to install Minikube
install_minikube() {
  echo "Installing Minikube..."
  if ! command -v minikube &>/dev/null; then
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    install minikube-linux-amd64 /usr/local/bin/minikube
    rm -f minikube-linux-amd64
    echo "Minikube installation completed."
  else
    echo "Minikube is already installed."
  fi
}

# Function to install kubectl
install_kubectl() {
  echo "Installing kubectl..."
  if ! command -v kubectl &>/dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install kubectl /usr/local/bin/kubectl
    rm -f kubectl
    echo "kubectl installation completed."
  else
    echo "kubectl is already installed."
  fi
}

# Function to clone repositories
clone_repos() {
  echo "Cloning repositories..."
  mkdir -p ~/Desktop
  git clone https://github.com/Walchand-Linux-Users-Group/Fortune_teller.git ~/Desktop/Fortune_teller || echo "Repository already exists."
  git clone https://github.com/AnotherUser/AnotherRepo.git ~/Desktop/AnotherRepo || echo "Repository already exists."
  echo "Repositories cloned successfully."
}

# Function to set Cloudinary image as wallpaper (only for GNOME)
set_wallpaper() {
  if is_gnome; then
    echo "Setting GNOME wallpaper..."
    WALLPAPER_URL="https://res.cloudinary.com/dfuwno067/image/upload/v1739529086/META_Wallpaper_yrwn0j.png"
    
    # Try setting wallpaper with direct URL (might not work)
    gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER_URL" || {
      echo "Direct URL failed, downloading wallpaper..."
      wget -O /tmp/wallpaper.jpg "$WALLPAPER_URL"
      gsettings set org.gnome.desktop.background picture-uri "file:///tmp/wallpaper.jpg"
    }
    
    gsettings set org.gnome.desktop.background picture-options "zoom"
    echo "Wallpaper set successfully."
  else
    echo "GNOME not detected, skipping wallpaper setup."
  fi
}

# Function to check versions of installed tools
check_versions() {
  echo "Checking installed versions..."
  docker --version || echo "Docker not found"
  docker-compose --version || echo "Docker Compose not found"
  minikube version || echo "Minikube not found"
  kubectl version --client || echo "kubectl not found"
}

# Main script execution
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

install_docker
install_minikube
install_kubectl
clone_repos
set_wallpaper
check_versions

echo "All tasks completed successfully!"
