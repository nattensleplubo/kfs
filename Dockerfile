FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    build-essential \
    nasm \
    xorriso \
    grub-pc-bin \
    grub-common \
    gcc-multilib \
    make \
    qemu-system-x86 \
    gdb \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /kernel

# Create non-root user
RUN useradd -m -u 1000 builder && \
    chown -R builder:builder /kernel

USER builder
