FROM jenkins/jenkins:lts

# Switch to root user to install packages
USER root

# Install prerequisites (with --no-install-recommends to slim image)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI (not Docker daemon - will use host's Docker socket)
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Install Terraform (useful for infrastructure management in pipelines)
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/hashicorp.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends terraform && \
    rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2 via pip (more compatible with ARM/x86)
RUN pip3 install --no-cache-dir awscli --break-system-packages

# Add jenkins user to docker group (for Docker socket access)
RUN groupadd -f docker && usermod -aG docker jenkins

# Verify installations
RUN docker --version && aws --version && terraform --version

# Switch back to jenkins user
USER jenkins

# Expose Jenkins port
EXPOSE 8080

# The entrypoint is inherited from the base image
