FROM ubuntu:22.04

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
    # Added packages for X11 and accessibility
    libgl1 \
    libpulse0 \
    && rm -rf /var/lib/apt/lists/*

# Create required directories and files for accessibility
RUN mkdir -p /run/user/1000/at-spi/

# Set working directory
WORKDIR /kernel

# Set environment variables to handle X11 and accessibility
ENV NO_AT_BRIDGE=1
ENV TERM=xterm
