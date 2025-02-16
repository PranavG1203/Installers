#!/bin/bash

echo "🚀 Updating system and installing necessary packages..."
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y curl wget git conntrack socat iptables ebtables ca-certificates gnupg lsb-release

echo "📦 Installing Docker..."
if ! command -v docker &>/dev/null; then
  sudo apt install -y docker.io
  sudo systemctl enable --now docker
  sudo usermod -aG docker $USER
  echo "⚠️  Please log out and log back in for Docker group changes to take effect."
fi

echo "🛑 Stopping and Deleting Existing Minikube..."
minikube stop || true
minikube delete --all --purge || true

echo "🗑️ Removing Old Minikube Installation..."
sudo rm -rf /usr/local/bin/minikube
rm -rf ~/.minikube ~/.kube

echo "🧹 Cleaning Up Systemd Services..."
sudo systemctl stop minikube || true
sudo systemctl disable minikube || true
sudo rm -f /etc/systemd/system/minikube.service
sudo systemctl daemon-reload

echo "⬇️ Downloading Minikube v1.34.0..."
curl -LO https://storage.googleapis.com/minikube/releases/v1.34.0/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm -f minikube-linux-amd64

echo "🔧 Installing Kubectl..."
if ! command -v kubectl &>/dev/null; then
  curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install kubectl /usr/local/bin/kubectl
  rm -f kubectl
fi

echo "🔄 Restarting Docker..."
sudo systemctl restart docker

echo "🚀 Starting Minikube with Custom Base Image..."
minikube start \
  --base-image=ghcr.io/pranavg1203/minikube-base:v0.0.45 \
  --image-repository=ghcr.io/pranavg1203

echo "✅ Minikube and Kubernetes are now set up!"
