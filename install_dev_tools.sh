#!/bin/bash
# install_dev_tools.sh
# Bash script to install Docker, Docker Compose, Python, and Django on Ubuntu/Debian.

set -e  # exit immediately if a command fails

echo "=== Starting DevOps tools installation ==="

# --- Docker ---
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  sudo apt-get update -y
  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  sudo usermod -aG docker $USER
  echo "Docker installed successfully."
else
  echo "Docker already installed."
fi

# --- Docker Compose ---
if ! command -v docker-compose &> /dev/null; then
  echo "Installing Docker Compose..."
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  echo "Docker Compose installed successfully."
else
  echo "Docker Compose already installed."
fi

# --- Python ---
if ! command -v python3 &> /dev/null; then
  echo "Installing Python 3..."
  sudo apt-get update -y
  sudo apt-get install -y python3 python3-pip
elif [[ $(python3 -V | awk '{print $2}' | cut -d. -f1) -lt 3 ]] || \
     [[ $(python3 -V | awk '{print $2}' | cut -d. -f2) -lt 9 ]]; then
  echo "Upgrading Python to >=3.9..."
  sudo apt-get update -y
  sudo apt-get install -y python3.10 python3.10-venv python3-pip
else
  echo "Python 3.9+ already installed."
fi

# --- Django ---
if ! python3 -m django --version &> /dev/null; then
  echo "Installing Django..."
  pip3 install --user django
  echo "Django installed successfully."
else
  echo "Django already installed."
fi

echo "=== All tools installed successfully ==="
