;
; spenis16.asm - First go at an OS, this is just going to be a better speNIS for now, real mode, some commands
;
; This is the bootloader and a kernel combined together. It will not utilize any secondary storage. The kernel is
; so small that it should fit into primary storage just fine. In fact, it fits into less than a single sector!
;


org	0x7c00					; add offsets starting with 0x7c00
bits	16					; tell NASM that we are using 16 bit code only

	xor	ax, ax				; set up segments
	mov	ds, ax
	mov	es, ax
	mov	ss, ax				; set up stack
	mov	sp, 0x7c00			; stack grows down from 0x7c00

	mov	si, welcome			; print the welcome message
	call	print_string

mainloop:
	mov	si, prompt
	call	print_string

	mov	di, buffer
	call	get_string
	
	mov	si, buffer
	cmp	byte [si], 0			; is it a blank line?
	je	mainloop			; if yes, ignore it

	mov	si, buffer
	mov	di, cmd_hello			; 'hello' command
	call	strcmp
	jc	.helloworld

	mov	si, buffer
	mov	di, cmd_help			; 'help' command
	call	strcmp
	jc	.help

	mov	si, badcommand
	call	print_string
	jmp	mainloop

.helloworld:
	mov	si, msg_helloworld
	call	print_string

	jmp	mainloop

.help:
	mov	si, msg_help
	call	print_string

	jmp	mainloop

welcome db 'Welcome to speNIS!', 0x0d, 0x0a, 0
msg_helloworld db 'Hello World!', 0x0d, 0x0a, 0
badcommand db 'Unknown command.', 0x0d, 0x0a, 0
prompt db '>', 0
cmd_hello db 'hello', 0
cmd_help db 'help', 0
msg_help db 'speNIS: Commands: hello, help', 0x0d, 0x0a, 0
buffer times 64 db 0

; calls

print_string:
	lodsb					; get a byte from SI register

	or	al, al				; or the AL register by itself
	jz	.done				; if result is zero then done

	mov	ah, 0x0e
	int 	0x10				; Otherwise print the character

	jmp	print_string

.done:
	ret

get_string:
	xor	cl, cl

.loop:
	xor	ah, ah
	int	0x16				; Wait for keypress from keyboard

	cmp	al, 0x08			; was backspace key pressed?
	je	.backspace			; if so, then handle that

	cmp	al, 0x0d			; was return key pressed?
	je	.done				; if so, then done

	cmp 	cl, 0x3f			; 63 chars inputted?
	je	.loop				; if yes, then only allow backspace and return

	mov	ah, 0x0e
	int	0x10				; print the character

	stosb					; put character in buffer
	inc	cl
	jmp	.loop

.backspace:
	cmp	cl, 0				; beginning of string?
	je	.loop				; if yes, then ignore the key

	dec	di
	mov	byte [di], 0			; delete character
	dec	cl				; decrement counter

	mov	ah, 0x0e
	mov	al, 0x08
	int	0x10				; do backspace on screen

	mov 	al, ' '
	int 	0x10				; blank character out that was backspaced

	mov	al, 0x08
	int	0x10				; backspace again

	jmp	.loop				; go to main loop

.done:
	mov	al, 0				; null terminator
	stosb

	mov	ah, 0x0e
	mov	al, 0x0d
	int	0x10
	mov	al, 0x0a
	int	0x10				; newline

	ret

strcmp:
.loop:
	mov	al, [si]			; grab a byte from SI
	mov	bl, [di]			; grab a byte from DI
	cmp	al, bl				; are they equal?
	jne	.notequal			; if no then done

	cmp 	al, 0				; are both bytes null?
	je	.done				; of yes then done

	inc	di				; increment DI
	inc	si				; increment SI
	jmp	.loop				; then loop

.notequal:
	clc					; not equal, clear the carry flag
	ret

.done:
	stc					; equal, set carry flag
	ret

	times	510-($-$$) db 0			; fill
	dw	0xaa55				; magic
