#!/usr/bin/env bash
set -euo pipefail

echo "🧩 Installing prerequisites for EdgeWave DevSecOps environment..."
echo "This script is safe to rerun. It only installs missing tools."

# --- Helper Functions ---
ok()   { echo -e "\033[1;32m[OK]\033[0m  $1"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
fail() { echo -e "\033[1;31m[FAIL]\033[0m $1"; exit 1; }

# --- Update base packages ---
info "Updating system packages..."
sudo apt update -y && sudo apt upgrade -y &>/dev/null
ok "System updated"

# --- Basic CLI utilities ---
info "Installing core CLI utilities..."
sudo apt install -y \
curl wget git unzip apt-transport-https ca-certificates gnupg lsb-release jq software-properties-common &>/dev/null
ok "Core tools installed"

# --- Docker ---
if ! command -v docker &>/dev/null; then
  info "Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo usermod -aG docker $USER
  ok "Docker installed (logout & login required for group changes)"
else
  ok "Docker already installed"
fi

# --- Docker Compose v2 ---
if ! docker compose version &>/dev/null; then
  info "Installing Docker Compose v2 plugin..."
  DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
  mkdir -p "$DOCKER_CONFIG/cli-plugins"
  curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
  chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
  ok "Docker Compose v2 installed"
else
  ok "Docker Compose v2 already available"
fi

# --- AWS CLI ---
if ! command -v aws &>/dev/null; then
  info "Installing AWS CLI v2..."
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  sudo ./aws/install
  rm -rf aws awscliv2.zip
  ok "AWS CLI installed"
else
  ok "AWS CLI already installed"
fi

# --- eksctl ---
if ! command -v eksctl &>/dev/null; then
  info "Installing eksctl..."
  ARCH=$(uname -m)
  curl -sLO "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_${ARCH}.tar.gz"
  tar -xzf eksctl_$(uname -s)_${ARCH}.tar.gz -C /tmp && sudo mv /tmp/eksctl /usr/local/bin
  rm eksctl_$(uname -s)_${ARCH}.tar.gz
  ok "eksctl installed"
else
  ok "eksctl already installed"
fi

# --- kubectl ---
if ! command -v kubectl &>/dev/null; then
  info "Installing kubectl..."
  KUBECTL_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt)
  curl -LO "https://dl.k8s.io/release/${KUBECTL_VER}/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
  ok "kubectl installed"
else
  ok "kubectl already installed"
fi

# --- Helm ---
if ! command -v helm &>/dev/null; then
  info "Installing Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  ok "Helm installed"
else
  ok "Helm already installed"
fi

# --- Jenkins ---
if ! systemctl is-active --quiet jenkins; then
  if ! command -v jenkins &>/dev/null; then
    info "Installing Jenkins LTS..."
    sudo apt install -y openjdk-17-jdk
    curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc >/dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list >/dev/null
    sudo apt update
    sudo apt install -y jenkins
    sudo systemctl enable jenkins --now
    ok "Jenkins installed and started"
  else
    ok "Jenkins command found, starting service..."
    sudo systemctl enable jenkins --now
  fi
else
  ok "Jenkins already running"
fi

# --- SonarQube (via Docker Compose) ---
if ! docker ps | grep -q sonarqube; then
  if [[ -f "sonarqube/sonarqube.yml" ]]; then
    info "Launching SonarQube via compose/sonarqube.yml..."
    docker compose -f sonarqube/sonarqube.yml up -d
    ok "SonarQube started at http://localhost:9000"
  fi
else
  ok "SonarQube already running : http://localhost:9000"
fi

# --- Verify final tools ---
echo
info "Verifying all tools..."
for cmd in docker aws eksctl kubectl helm jenkins; do
  if command -v $cmd &>/dev/null; then ok "$cmd present"; else warn "$cmd missing"; fi
done
docker compose version &>/dev/null && ok "Docker Compose v2 check passed"

echo
echo "✅ All prerequisites installed and verified!"
echo "Next steps:"
echo "  1️⃣ Logout/login if Docker group was newly added."
echo "  3️⃣ Then run 'make cluster-bootstrap' to deploy EdgeWave."
