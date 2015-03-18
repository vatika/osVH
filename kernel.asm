; kernel.asm

; nasm directive - 32 bit
; the bootloader, x86. 
bits 32
section .text
        ;multiboot spec
        align 4
        dd 0x1BADB002            ;magic
        dd 0x00                  ;flags
        dd - (0x1BADB002 + 0x00) ;checksum. m+f+c should be zero. sanity check.

; global functions
global start
global keyboard_handler
global read_port
global write_port
global load_idt

; functions that will be linked 
; later in the loader. Hence,
; externally defined. actual 
; functions written in kernel.c file.
extern kmain
extern keyboard_handler_main


read_port:
	mov edx, [esp + 4]
	in al,dx ;special x86 instruction to read from the device port.
	ret

write_port:
	mov edx, [esp + 4] ; the address are of the stack variables. [esp + 4] & [esp + 8]
	mov al, [esp + 4 + 4]
	out dx, al ;special x86 instruction to write to device port.
	ret

load_idt:
	mov edx, [esp + 4]
	lidt [edx]      ; special instruction to load the idt_ptr
	sti		; turning the interrupts on again
	ret

; the function called whenever
; a key is pressed and thus an
; interrupt is raised.
keyboard_handler:
	call keyboard_handler_main
	iretd    ;special return - interrupt handler return (a return from trap instruction).

; this is where the kernel starts 
; from x86 standard for the function 
; that runs first
; only a wrapper for kmain
start:
	cli 			;block interrupts
	call kmain
	hlt		 	;halt the CPU
