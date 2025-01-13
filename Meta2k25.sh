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
    ubuntu|debian)
      apt-get update
      apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
      curl -fsSL https://download.docker.com/linux/$distro/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$distro $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
      apt-get update
      apt-get install -y docker-ce docker-ce-cli containerd.io
      ;;
    fedora|centos|rhel)
      dnf install -y dnf-plugins-core
      dnf config-manager --add-repo https://download.docker.com/linux/$(get_distro)/docker-ce.repo
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

   # Add current user to the docker group
  usermod -aG docker $USER
  newgrp docker
  
  echo "Docker installation completed."
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

# Main script execution
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

install_docker
install_minikube
install_kubectl

# Final message
echo "All tools installed successfully. You can now use Docker, Minikube, and kubectl."
