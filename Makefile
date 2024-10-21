# Docker settings
DOCKER_IMAGE=kernel-builder
DOCKER_CONTAINER=kernel-dev
DOCKER_RUN=docker run --rm -v $(PWD):/kernel -w /kernel

# QEMU settings
QEMU=qemu-system-i386
QEMU_FLAGS=-display gtk,gl=off

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

fclean: clean
	docker rmi -f $(DOCKER_IMAGE) 2>/dev/null || true
	rm -rf $(ISO_DIR) $(ISO_IMAGE)

# Rebuild everything from scratch
re: fclean all

# Run in QEMU (with display forwarding)
run: $(ISO_IMAGE)
	$(DOCKER_RUN) -it \
		--device=/dev/kvm \
		-e DISPLAY=${DISPLAY} \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		$(DOCKER_IMAGE) \
		$(QEMU) $(QEMU_FLAGS) -cdrom $(ISO_IMAGE) 2>/dev/null

# Debug with GDB
debug: $(ISO_IMAGE)
	$(DOCKER_RUN) -it \
		--device=/dev/kvm \
		-e DISPLAY=${DISPLAY} \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-p 1234:1234 \
		$(DOCKER_IMAGE) \
		$(QEMU) $(QEMU_FLAGS) -cdrom $(ISO_IMAGE) -s -S 2>/dev/null

# Interactive shell in Docker container
shell:
	$(DOCKER_RUN) -it $(DOCKER_IMAGE) /bin/bash

# Print variables for debugging
print-%:
	@echo '$*=$($*)'

# Helper target to check if Docker is available
check-docker:
	@which docker > /dev/null || (echo "Docker is not installed" && exit 1)

# Helper target to check if display is set for X11
check-display:
	@test "$$DISPLAY" || (echo "DISPLAY is not set" && exit 1)

# Helper target to setup X11 permissions
setup-x11:
	@xhost +local:docker || true

# Full setup target
setup: check-docker check-display setup-x11 docker-image

.PHONY: all clean run debug docker-image docker-build shell setup check-docker check-display setup-x11
