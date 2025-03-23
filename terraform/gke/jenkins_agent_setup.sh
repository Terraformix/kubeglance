#!/bin/bash

set -e 

log() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $1"
}

check_status() {
  if [ $? -eq 0 ]; then
    log "✅ $1 installed successfully"
  else
    log "❌ Error installing $1"
    exit 1
  fi
}

sudo useradd -m -s /bin/bash jenkins

# Setup - Update system packages
log "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt update && sudo apt upgrade -y
check_status "System updates"

# Install Java (Required for Jenkins)
log "Installing Java..."
sudo apt install -y openjdk-17-jdk
check_status "Java"

# # Install Docker
log "Installing Docker..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker jenkins
sudo systemctl enable docker
check_status "Docker"

# Install kubectl
log "Installing kubectl..."
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
sudo curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl
check_status "kubectl"

# Install Helm
log "Installing Helm..."
curl -fsSL https://baltocdn.com/helm/signing.asc | sudo gpg --dearmor -o /usr/share/keyrings/helm.gpg > /dev/null
sudo apt install -y apt-transport-https
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list > /dev/null
sudo apt update
sudo apt install -y helm
check_status "Helm"

# Install Google Cloud CLI
log "Installing Google Cloud SDK..."
sudo apt-get update -y
sudo apt-get install apt-transport-https ca-certificates gnupg curl -y
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin
sudo apt-get install google-cloud-cli -y
check_status "Google Cloud SDK"


# Print installed versions
log "Installation complete. Printing installed versions:"
echo "----------------------------------------------"
echo "Java: $(java -version 2>&1 | head -n 1)"
echo "Docker: $(docker --version)"
echo "kubectl: $(kubectl version --client --output=yaml | grep gitVersion | head -n 1)"
echo "Helm: $(helm version --short)"
#echo "Google Cloud SDK: $(gcloud --version | head -n 1)"
echo "----------------------------------------------"

