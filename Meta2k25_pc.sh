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

# Function to install Docker
install_docker() {
  echo "Installing Docker..."
  if command -v docker &>/dev/null; then
    echo "Docker is already installed."
    return
  fi

  distro=$(get_distro)
  case "$distro" in
    ubuntu|debian|linuxmint)
      apt-get update
      apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
      curl -fsSL https://download.docker.com/linux/$distro/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$distro $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
      apt-get update
      apt-get install -y docker-ce docker-ce-cli containerd.io
      ;;
    fedora|centos|rhel)
      dnf install -y dnf-plugins-core
      dnf config-manager --add-repo https://download.docker.com/linux/$distro/docker-ce.repo
      dnf install -y docker-ce docker-ce-cli containerd.io
      ;;
    arch)
      pacman -Syu --noconfirm docker
      ;;
    *)
      echo "Unsupported distribution for Docker installation."
      exit 1
      ;;
  esac

  systemctl enable docker
  systemctl start docker

  # Add current user to the docker group and apply changes immediately
  usermod -aG docker $SUDO_USER
  newgrp docker
  echo "New group changes applied for $SUDO_USER."
  echo "Docker installation completed."
}

# Function to install Docker Compose
install_docker_compose() {
  echo "Installing Docker Compose..."
  if command -v docker-compose &>/dev/null; then
    echo "Docker Compose is already installed."
    return
  fi

  curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  echo "Docker Compose installation completed."
}

# Function to install Minikube
install_minikube() {
  echo "Installing Minikube..."
  if command -v minikube &>/dev/null; then
    echo "Minikube is already installed."
    return
  fi

  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  install minikube-linux-amd64 /usr/local/bin/minikube
  rm -f minikube-linux-amd64
  echo "Minikube installation completed."
}

# Function to install kubectl
install_kubectl() {
  echo "Installing kubectl..."
  if command -v kubectl &>/dev/null; then
    echo "kubectl is already installed."
    return
  fi

  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  install kubectl /usr/local/bin/kubectl
  rm -f kubectl
  echo "kubectl installation completed."
}

# Ensure Git is installed
install_git() {
  echo "Installing Git..."
  if ! command -v git &>/dev/null; then
    apt-get update && apt-get install -y git
  fi
}

# Clone repositories to Desktop
clone_repositories() {
  install_git

  USER_HOME=$(eval echo ~$SUDO_USER)
  DESKTOP_PATH="$USER_HOME/Desktop"

  if [ ! -d "$DESKTOP_PATH" ]; then
    echo "Desktop directory not found, using home directory instead."
    DESKTOP_PATH="$USER_HOME"
  fi

  # Clone Fortune_teller repository
  REPO1_URL="https://github.com/Walchand-Linux-Users-Group/Fortune_teller.git"
  REPO1_DIR="$DESKTOP_PATH/Fortune_teller"

  if [ -d "$REPO1_DIR" ]; then
    echo "Fortune_teller repository already exists. Pulling latest changes..."
    su - $SUDO_USER -c "cd $REPO1_DIR && git pull"
  else
    su - $SUDO_USER -c "git clone $REPO1_URL $REPO1_DIR"
    echo "Fortune_teller repository cloned to $REPO1_DIR"
  fi

  # Clone second repository
  REPO2_URL="https://github.com/YOUR-USERNAME/YOUR-REPO.git"  # Replace with actual repo link
  REPO2_DIR="$DESKTOP_PATH/YOUR-REPO"

  if [ -d "$REPO2_DIR" ]; then
    echo "Second repository already exists. Pulling latest changes..."
    su - $SUDO_USER -c "cd $REPO2_DIR && git pull"
  else
    su - $SUDO_USER -c "git clone $REPO2_URL $REPO2_DIR"
    echo "Second repository cloned to $REPO2_DIR"
  fi
}

# Check versions of all installed tools
check_versions() {
  echo "Checking installed versions:"
  
  echo -n "Docker: "
  docker --version || echo "Not installed"

  echo -n "Docker Compose: "
  docker-compose --version || echo "Not installed"

  echo -n "Minikube: "
  minikube version || echo "Not installed"

  echo -n "kubectl: "
  kubectl version --client || echo "Not installed"

  echo -n "Git: "
  git --version || echo "Not installed"
}

# Main script execution
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

install_docker
install_docker_compose
install_minikube
install_kubectl
# clone_repositories
check_versions

# Final message
echo "All tools installed successfully! You can now use Docker, Minikube, kubectl, and Git."
