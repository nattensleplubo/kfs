FROM ubuntu:20.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    build-essential \
    nasm \
    gcc \
    gcc-multilib \
    grub-common \
    grub-pc-bin \
    xorriso \
    make \
    qemu-system-x86 \
    gdb \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /kernel

# Default command (can be overridden)
CMD ["/bin/bash"]
