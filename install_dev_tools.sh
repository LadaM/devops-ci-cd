#!/bin/bash
# install_dev_tools.sh
# Ubuntu 24.04+: Install Docker CE, Docker Compose v2, Python3 + venv + pip, and Django (in a venv)

set -euo pipefail

echo "=== Starting DevOps tools installation ==="

# --- Basics ---
sudo apt-get update -y
sudo apt-get install -y curl ca-certificates gnupg lsb-release

source /etc/os-release
DISTRO_ID=${ID:-ubuntu}
CODENAME=${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || echo noble)}
ARCH="$(dpkg --print-architecture)"

# --- Docker CE (official repo) ---
if ! command -v docker >/dev/null 2>&1; then
  echo "--- Installing Docker CE ---"
  sudo install -m 0755 -d /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL "https://download.docker.com/linux/${DISTRO_ID}/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
  fi
  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO_ID} ${CODENAME} stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  fi
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  if ! id -nG "$USER" | grep -qw docker; then
    sudo usermod -aG docker "$USER"
    echo "  -> Added $USER to 'docker' group (open a new shell or run: newgrp docker)."
  fi
else
  echo "Docker already installed: $(docker --version)"
fi

# --- Docker Compose v2 (plugin) + compatibility wrapper ---
if ! docker compose version >/dev/null 2>&1; then
  echo "--- Installing Docker Compose v2 plugin ---"
  sudo apt-get install -y docker-compose-plugin
else
  echo "Docker Compose v2 already installed: $(docker compose version | head -n1)"
fi

# Provide 'docker-compose' command as a wrapper to 'docker compose'
if ! command -v docker-compose >/dev/null 2>&1; then
  echo "--- Creating docker-compose compatibility wrapper ---"
  sudo tee /usr/local/bin/docker-compose >/dev/null <<'EOF'
#!/usr/bin/env bash
exec docker compose "$@"
EOF
  sudo chmod +x /usr/local/bin/docker-compose
fi

# --- Python 3, pip, venv ---
if ! command -v python3 >/dev/null 2>&1; then
  echo "--- Installing Python 3 ---"
  sudo apt-get install -y python3
fi
sudo apt-get install -y python3-venv python3-pip
echo "Python: $(python3 -V)"
echo "pip: $(pip3 --version)"

# Ensure user bin on PATH (for our symlink below)
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  mkdir -p "$HOME/.local/bin"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
  export PATH="$HOME/.local/bin:$PATH"
fi

# --- Django in a virtualenv (avoids externally-managed-environment) ---
VENV_DIR="$HOME/.venvs/devops-tools"
if [ ! -x "$VENV_DIR/bin/python" ]; then
  echo "--- Creating virtualenv at $VENV_DIR ---"
  mkdir -p "$(dirname "$VENV_DIR")"
  python3 -m venv "$VENV_DIR"
fi

echo "--- Ensuring Django inside the venv ---"
"$VENV_DIR/bin/python" -m pip install --upgrade pip setuptools wheel
# Install latest stable Django compatible with Python 3.12
"$VENV_DIR/bin/python" -m pip install --upgrade "django"

# Symlink django-admin for convenience
if [ ! -e "$HOME/.local/bin/django-admin" ]; then
  ln -s "$VENV_DIR/bin/django-admin" "$HOME/.local/bin/django-admin"
fi

# --- Summary / versions ---
echo "=== Versions ==="
docker --version || true
docker compose version || true
python3 -V || true
"$VENV_DIR/bin/python" -m django --version || true
django-admin --version || true

echo "=== Done. To use the venv: source \"$VENV_DIR/bin/activate\" ==="
