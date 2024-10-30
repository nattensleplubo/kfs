# Host system commands
DOCKER=docker
RM=rm -rf

# Docker settings
DOCKER_IMAGE=kernel-builder
DOCKER_FILE=Dockerfile
DOCKER_CONTAINER=kernel-build-container

# Build commands (these will run inside docker)
ASM=nasm
CC=gcc
LD=ld

# Compiler flags as specified in the subject
CFLAGS=-fno-builtin \
       -fno-stack-protector \
       -nostdlib \
       -nodefaultlibs \
       -m32 \
       -I./src \
       -Wall \
       -Wextra \
       -c

# Assembler flags
ASMFLAGS=-f elf32

# Output directories
BUILD_DIR=build
ISO_DIR=iso
BOOT_DIR=$(ISO_DIR)/boot
GRUB_DIR=$(BOOT_DIR)/grub

# Source files
ASM_SOURCES=src/boot.asm
C_SOURCES=src/kernel.c \
         src/keys.c

# Object files
ASM_OBJECTS=$(ASM_SOURCES:src/%.asm=$(BUILD_DIR)/%.o)
C_OBJECTS=$(C_SOURCES:src/%.c=$(BUILD_DIR)/%.o)

# Final binary
KERNEL_BIN=$(BOOT_DIR)/kernel.bin

# ISO image
ISO_IMAGE=kernel.iso

# Default target
all: build-docker

# Build docker image if it doesn't exist
docker-image:
	@if [ ! "$$($(DOCKER) images -q $(DOCKER_IMAGE) 2> /dev/null)" ]; then \
		$(DOCKER) build -t $(DOCKER_IMAGE) -f $(DOCKER_FILE) .; \
	fi

# Run the build process inside docker
build-docker: docker-image
	$(DOCKER) run --rm \
		--name $(DOCKER_CONTAINER) \
		-v $(PWD):/kernel \
		$(DOCKER_IMAGE) \
		make build-kernel

# The actual kernel build process (runs inside docker)
build-kernel: $(ISO_IMAGE)

# Create build directories
directories:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(BOOT_DIR)
	@mkdir -p $(GRUB_DIR)

# Compile assembly files
$(BUILD_DIR)/%.o: src/%.asm
	@mkdir -p $(dir $@)
	$(ASM) $(ASMFLAGS) $< -o $@

# Compile C files
$(BUILD_DIR)/%.o: src/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $< -o $@

# Link everything together
$(KERNEL_BIN): directories $(ASM_OBJECTS) $(C_OBJECTS)
	$(LD) -m elf_i386 -T src/linker.ld -o $@ $(ASM_OBJECTS) $(C_OBJECTS)

# Create ISO image
$(ISO_IMAGE): $(KERNEL_BIN)
	@cp scripts/grub.cfg $(GRUB_DIR)
	grub-mkrescue -o $@ $(ISO_DIR)

# Clean built files
clean:
	$(RM) $(BUILD_DIR)
	$(RM) $(ISO_DIR)
	$(RM) $(ISO_IMAGE)

# Clean everything including docker image
fclean: clean
	$(DOCKER) rmi -f $(DOCKER_IMAGE) 2>/dev/null || true

# Clean and rebuild
re: clean all

# Run the kernel in QEMU (helpful for testing)
run: all
	qemu-system-i386 -cdrom $(ISO_IMAGE)

# Debug with GDB
debug: all
	qemu-system-i386 -cdrom $(ISO_IMAGE) -s -S

.PHONY: all clean fclean re run debug directories docker-image build-docker build-kernel
