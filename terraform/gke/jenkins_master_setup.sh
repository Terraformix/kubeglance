#!/bin/bash

set -e 

log() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $1"
}

# Function to check if command executed successfully
check_status() {
  if [ $? -eq 0 ]; then
    log "✅ $1 installed successfully"
  else
    log "❌ Error installing $1"
    exit 1
  fi
}

# Setup - Update system packages
log "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt update && sudo apt upgrade -y
check_status "System updates"

# Install Java (Required for Jenkins)
log "Installing Java..."
sudo apt install -y openjdk-17-jdk
check_status "Java"

# Install Jenkins
log "Installing Jenkins..."
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update -y
sudo apt install jenkins -y
sudo systemctl enable jenkins
sudo systemctl start jenkins
check_status "Jenkins"

log "Waiting for Jenkins to start..."
sleep 30

log "Installing Jenkins plugins from plugins.txt..."
# Create Jenkins plugin directory if it doesn't exist
sudo mkdir -p /var/lib/jenkins/plugins

# Download Jenkins CLI
log "Downloading Jenkins CLI..."
sudo wget http://localhost:8080/jnlpJars/jenkins-cli.jar -O /tmp/jenkins-cli.jar
check_status "Jenkins CLI download"

# Get the initial admin password
JENKINS_ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# Print installed versions
log "Installation complete. Printing installed versions:"
echo "----------------------------------------------"
echo "Java: $(java -version 2>&1 | head -n 1)"
echo "Jenkins: $(jenkins --version 2>&1 || echo 'Version check requires login')"
echo "----------------------------------------------"

# Final success message
log "Jenkins Master Node setup successfully!."

echo "Jenkins temporary password: $JENKINS_ADMIN_PASSWORD"