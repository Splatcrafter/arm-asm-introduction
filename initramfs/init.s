.section .text
.global _start
_start:

init:
	mov r0, #2        // stderr
	ldr r1, =message
	mov r2, #20       // len(message)
	mov r7, #4        // syscall `write`
	swi 0

	b init            // infinite loop

.section .data

message:
	.ascii " Hello Initramfs\n"
