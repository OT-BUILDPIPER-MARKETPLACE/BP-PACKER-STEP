# -------------------------------
# Base image (change freely)
# -------------------------------
FROM ubuntu:22.04
# FROM amazonlinux:2
# FROM debian:12
# FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

# -------------------------------
# Install runtime deps
# -------------------------------
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    jq \
    openssh-client \
    ca-certificates \
    passwd \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------
# Install Packer (REQUIRED)
# -------------------------------
ARG PACKER_VERSION=1.10.2

RUN curl -fsSL https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
    -o /tmp/packer.zip && \
    unzip /tmp/packer.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/packer && \
    rm -f /tmp/packer.zip

# -------------------------------
# Create buildpiper user & group
# -------------------------------
RUN groupadd -g 65522 buildpiper && \
    useradd -u 65522 -g buildpiper -m -d /home/buildpiper buildpiper

# -------------------------------
# BuildPiper directory layout
# -------------------------------
RUN mkdir -p \
    /bp/data \
    /bp/execution_dir \
    /bp/workspace \
    /opt/buildpiper/shell-functions \
    /home/buildpiper/reports \
    /home/buildpiper/packer && \
    chown -R buildpiper:buildpiper \
        /bp \
        /opt/buildpiper \
        /home/buildpiper

# -------------------------------
# Environment defaults
# -------------------------------
ENV SHELL_FUNCTIONS_PATH="/opt/buildpiper/shell-functions" \
    PACKER_CACHE_DIR="/bp/workspace/.packer-cache" \
    SLEEP_DURATION="5s"

# -------------------------------
# Copy BuildPiper shell functions
# -------------------------------
COPY --chown=buildpiper:buildpiper BP-BASE-SHELL-STEPS/ \
    /opt/buildpiper/shell-functions/

# -------------------------------
# Copy packer templates & entry script
# -------------------------------
COPY --chown=buildpiper:buildpiper packer/ /home/buildpiper/packer/
COPY --chown=buildpiper:buildpiper build.sh /home/buildpiper/build.sh

# -------------------------------
# Normalize scripts
# -------------------------------
RUN chmod +x /home/buildpiper/build.sh && \
    sed -i 's/\r$//' /home/buildpiper/build.sh

# -------------------------------
# Drop privileges
# -------------------------------
USER buildpiper
WORKDIR /home/buildpiper

# Ensure Packer is in PATH for non-root users
ENV PATH="/usr/local/bin:${PATH}"

# -------------------------------
# Entrypoint
# -------------------------------
ENTRYPOINT ["/bin/bash", "/home/buildpiper/build.sh"]
