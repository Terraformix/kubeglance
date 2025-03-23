FROM jenkins/jenkins:lts

USER root

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    unzip \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI (v2)
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip ./aws

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Set permissions
RUN chown -R jenkins:jenkins /usr/local/bin/kubectl /usr/local/bin/aws /usr/local/bin/helm

USER jenkins

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/jenkins.sh"]
