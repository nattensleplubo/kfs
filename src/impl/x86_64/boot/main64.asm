global long_mode_start
extern kernel_main

section .text
bits 64
global in_port

in_port:
	mov edx, [esp + 4] ; argument (port nbr) pushed to the edx register
	in al, dx ; Read one byte in an io port at the specified address by the DX register and puts the result in the AL register
	ret

long_mode_start:
    ; load null into all data segment registers
    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

	call kernel_main
    hlt
