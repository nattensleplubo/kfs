# Docker settings
DOCKER_IMAGE=kernel-builder
DOCKER_CONTAINER=kernel-dev
DOCKER_RUN=docker run --rm -v $(PWD):/kernel -w /kernel

# Compiler and linker settings
ASM=nasm
CC=gcc
LD=ld

# Compiler and assembler flags
CFLAGS=-m32 -c -fno-builtin -fno-stack-protector -fno-omit-frame-pointer -nostdlib -nodefaultlibs -g3
ASMFLAGS=-f elf32
LDFLAGS=-m elf_i386 -T src/linker.ld -nostdlib

# Directories
SRC_DIR=src
SCRIPTS_DIR=scripts
BUILD_DIR=build
ISO_DIR=isodir

# Source files
ASM_SOURCES=$(wildcard $(SRC_DIR)/*.asm)
C_SOURCES=$(wildcard $(SRC_DIR)/*.c)

# Object files
ASM_OBJECTS=$(ASM_SOURCES:$(SRC_DIR)/%.asm=$(BUILD_DIR)/%.o)
C_OBJECTS=$(C_SOURCES:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)
OBJECTS=$(ASM_OBJECTS) $(C_OBJECTS)

# Final kernel binary
KERNEL=$(BUILD_DIR)/kernel.bin

# ISO image
ISO_IMAGE=kernel.iso

# Default target
all: docker-build

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compile assembly files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm | $(BUILD_DIR)
	$(DOCKER_RUN) $(DOCKER_IMAGE) $(ASM) $(ASMFLAGS) $< -o $@

# Compile C files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	$(DOCKER_RUN) $(DOCKER_IMAGE) $(CC) $(CFLAGS) -c $< -o $@

# Link the kernel
$(KERNEL): $(OBJECTS)
	$(DOCKER_RUN) $(DOCKER_IMAGE) $(LD) $(LDFLAGS) $(OBJECTS) -o $@

# Create ISO image
$(ISO_IMAGE): $(KERNEL)
	$(DOCKER_RUN) $(DOCKER_IMAGE) /bin/bash -c "\
		mkdir -p $(ISO_DIR)/boot/grub && \
		cp $(KERNEL) $(ISO_DIR)/boot/ && \
		cp $(SCRIPTS_DIR)/grub.cfg $(ISO_DIR)/boot/grub/ && \
		grub-mkrescue -o $(ISO_IMAGE) $(ISO_DIR)"

# Build Docker image
docker-image:
	docker build -t $(DOCKER_IMAGE) .

# Build using Docker
docker-build: docker-image $(ISO_IMAGE)

# Clean build files
clean:
	rm -rf $(BUILD_DIR) $(ISO_DIR) $(ISO_IMAGE)

# Run in QEMU (with display forwarding)
run: $(ISO_IMAGE)
	$(DOCKER_RUN) -it \
		--device=/dev/kvm \
		-e DISPLAY=${DISPLAY} \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		$(DOCKER_IMAGE) \
		qemu-system-i386 -cdrom $(ISO_IMAGE)

# Debug with GDB
debug: $(ISO_IMAGE)
	$(DOCKER_RUN) -it \
		--device=/dev/kvm \
		-e DISPLAY=${DISPLAY} \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-p 1234:1234 \
		$(DOCKER_IMAGE) \
		qemu-system-i386 -cdrom $(ISO_IMAGE) -s -S

# Interactive shell in Docker container
shell:
	$(DOCKER_RUN) -it $(DOCKER_IMAGE) /bin/bash

.PHONY: all clean run debug docker-image docker-build shell
