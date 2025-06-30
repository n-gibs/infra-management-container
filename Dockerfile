# -----------------------------------------------------------------------------
# Global Arguments
# -----------------------------------------------------------------------------
ARG ANSIBLE_VERSION
ARG TERRAFORM_VERSION
ARG AWS_CLI_VERSION
ARG UBUNTU_VERSION=24.04

# =============================================================================
# Multi-Stage Build: Tool Downloader  
# =============================================================================
FROM ubuntu:${UBUNTU_VERSION} AS downloader

ARG TERRAFORM_VERSION
ARG AWS_CLI_VERSION
ARG TARGETARCH

# Install only essential download dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

WORKDIR /downloads

# Download Terraform with architecture detection
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        TERRAFORM_ARCH="arm64"; \
    else \
        TERRAFORM_ARCH="amd64"; \
    fi && \
    wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TERRAFORM_ARCH}.zip" \
    && unzip terraform_${TERRAFORM_VERSION}_linux_${TERRAFORM_ARCH}.zip \
    && chmod +x terraform \
    && rm terraform_${TERRAFORM_VERSION}_linux_${TERRAFORM_ARCH}.zip

# Download AWS CLI with architecture detection
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        AWS_ARCH="aarch64"; \
    else \
        AWS_ARCH="x86_64"; \
    fi && \
    curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}-${AWS_CLI_VERSION}.zip" -o awscliv2.zip \
    && unzip -q awscliv2.zip \
    && rm awscliv2.zip

# =============================================================================
# Multi-Stage Build: Python Environment
# =============================================================================
FROM ubuntu:${UBUNTU_VERSION} AS python-builder

ARG ANSIBLE_VERSION

# Install Python and essential build dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create virtual environment and install core Ansible components
RUN python3 -m venv /opt/ansible-venv
RUN /opt/ansible-venv/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/ansible-venv/bin/pip install --no-cache-dir \
    ansible==${ANSIBLE_VERSION} \
    ansible-lint \
    boto3 \
    botocore \
    paramiko

# =============================================================================
# Final Runtime Image
# =============================================================================
FROM ubuntu:${UBUNTU_VERSION} AS runtime

ARG TERRAFORM_VERSION
ARG ANSIBLE_VERSION  
ARG AWS_CLI_VERSION

ENV TERRAFORM_VERSION=${TERRAFORM_VERSION} \
    ANSIBLE_VERSION=${ANSIBLE_VERSION} \
    AWS_CLI_VERSION=${AWS_CLI_VERSION} \
    PYTHONUNBUFFERED=1 \
    ANSIBLE_HOST_KEY_CHECKING=False \
    ANSIBLE_STDOUT_CALLBACK=yaml \
    TF_INPUT=0 \
    TF_IN_AUTOMATION=true \
    DEBIAN_FRONTEND=noninteractive

# Install system packages
RUN apt-get update && apt-get install -y \
    bash \
    ca-certificates \
    curl \
    git \
    openssh-client \
    python3 \
    jq \
    vim \
    unzip \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# User setup  
RUN useradd -m -d /home/infra -s /bin/bash infra \
    && mkdir -p /workspace /home/infra/.ssh /home/infra/.aws \
    && chown -R infra:infra /workspace /home/infra

# Copy tools from build stages
COPY --from=downloader /downloads/terraform /usr/local/bin/terraform
COPY --from=python-builder /opt/ansible-venv /opt/ansible-venv
COPY --from=downloader /downloads/aws /opt/aws-cli-install/aws

# Install AWS CLI and create symlinks
RUN /opt/aws-cli-install/aws/install --install-dir /opt/aws-cli --bin-dir /usr/local/bin \
    && rm -rf /opt/aws-cli-install \
    && ln -s /opt/ansible-venv/bin/ansible* /usr/local/bin/

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace
USER infra

HEALTHCHECK --interval=60s --timeout=5s --start-period=10s --retries=2 \
    CMD command -v terraform && command -v ansible && command -v aws || exit 1

LABEL maintainer="DevOps Team" \
      description="Infrastructure Management Container" \
      terraform.version="${TERRAFORM_VERSION}" \
      ansible.version="${ANSIBLE_VERSION}" \
      aws-cli.version="${AWS_CLI_VERSION}"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]