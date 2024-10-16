; Declare constants for the multiboot header
MBALIGN equ 1 << 0 ; align loaded modules on page boundaries
MEMINFO equ 1 << 1 ; provide a memory map
MBFLAGS equ MBALIGN | MEMINFO ; this is the Multiboot flag field
MAGIC equ 0x1BADB002 ; magic number lets bootloader find the header
CHECKSUM equ -(MAGIC + MBFLAGS) ; checksum of above to prove we are multiboot

section .multiboot
align 4
    dd MAGIC
    dd MBFLAGS
    dd CHECKSUM

section .bss
align 16
stack_bottom:
    resb 16384
stack_top:

section .text
global _start:function (_start.end - _start)
global in_port:function (in_port.end - in_port)
global gdt_flush
global outw
outw:
    mov dx, [esp + 4] ; port
    mov ax, [esp + 8] ; value
    out dx, ax
    ret

in_port:
    mov edx, [esp + 4]
    in al, dx
    ret
.end:

_start:
    mov esp, stack_top
    extern kernel_main
    call kernel_main
    cli
.hang: hlt
    jmp .hang
.end:

gdt_flush:
    mov eax, [esp + 4]
    lgdt [eax]

    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    jmp 0x08:.flush
.flush:
    ret