# Docker settings
DOCKER_IMAGE := randomdude/gcc-cross-x86_64-elf
DOCKER_RUN := docker run --rm -v $(CURDIR):/root/env -w /root/env $(DOCKER_IMAGE)

# Directories
SRC_DIR := src
BUILD_DIR := build
DIST_DIR := dist
KERNEL_SRC := $(SRC_DIR)/impl/kernel
X86_64_SRC := $(SRC_DIR)/impl/x86_64
ISO_DIR := targets/x86_64/iso

# Flags
CFLAGS := -c -fno-builtin -fno-stack-protector -fno-omit-frame-pointer -nostdlib -nodefaultlibs -g3 -I $(SRC_DIR)/intf -ffreestanding
LDFLAGS := -n -T targets/x86_64/linker.ld
ASMFLAGS := -f elf64

# Source files
KERNEL_SRCS := $(shell find $(KERNEL_SRC) -name *.c)
X86_64_C_SRCS := $(shell find $(X86_64_SRC) -name *.c)
X86_64_ASM_SRCS := $(shell find $(X86_64_SRC) -name *.asm)

# Object files
KERNEL_OBJS := $(patsubst $(KERNEL_SRC)/%.c,$(BUILD_DIR)/kernel/%.o,$(KERNEL_SRCS))
X86_64_C_OBJS := $(patsubst $(X86_64_SRC)/%.c,$(BUILD_DIR)/x86_64/%.o,$(X86_64_C_SRCS))
X86_64_ASM_OBJS := $(patsubst $(X86_64_SRC)/%.asm,$(BUILD_DIR)/x86_64/%.o,$(X86_64_ASM_SRCS))

# All object files
ALL_OBJS := $(KERNEL_OBJS) $(X86_64_C_OBJS) $(X86_64_ASM_OBJS)

# Final kernel binary and ISO
KERNEL_BIN := $(DIST_DIR)/x86_64/kernel.bin
KERNEL_ISO := $(DIST_DIR)/x86_64/kernel.iso

# Default target
all: $(KERNEL_ISO)

# Build everything inside Docker
build-in-docker:
	$(DOCKER_RUN) /bin/bash -c "\
		apt-get update && \
		apt-get install -y nasm xorriso grub-pc-bin grub-common && \
		make build-kernel && \
		make build-iso \
	"

# Build kernel
build-kernel: $(ALL_OBJS)
	mkdir -p $(dir $(KERNEL_BIN))
	x86_64-elf-ld $(LDFLAGS) $(ALL_OBJS) -o $(KERNEL_BIN)

# Build ISO
build-iso: $(KERNEL_BIN)
	mkdir -p $(ISO_DIR)/boot
	cp $< $(ISO_DIR)/boot/kernel.bin
	grub-mkrescue /usr/lib/grub/i386-pc -o $(KERNEL_ISO) $(ISO_DIR)

# Rule for C files
$(BUILD_DIR)/%.o: $(SRC_DIR)/impl/%.c
	mkdir -p $(@D)
	x86_64-elf-gcc $(CFLAGS) $< -o $@

# Rule for ASM files
$(BUILD_DIR)/x86_64/%.o: $(X86_64_SRC)/%.asm
	mkdir -p $(@D)
	nasm $(ASMFLAGS) $< -o $@

# Clean up
clean:
	rm -rf $(BUILD_DIR) $(DIST_DIR)

# Phony targets
.PHONY: all build-in-docker build-kernel build-iso clean

# Main target now uses Docker
$(KERNEL_ISO): build-in-docker

# Debug info
print-%:
	@echo $* = $($*)