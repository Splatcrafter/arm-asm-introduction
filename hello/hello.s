.section .text
.global _start
_start:

hello:
	mov r0, #1        // stdout
	ldr r1, =message  // address of message
	mov r2, #12       // len(message)
	mov r7, #4        // syscall `write` (https://arm.syscall.sh/)
	swi 0

exit:
	mov r0, #0        // exit code `OK`  (https://man.freebsd.org/cgi/man.cgi?query=sysexits)
	mov r7, #1        // syscall `exit`  (https://arm.syscall.sh/)
	swi 0	          // software interrupt `syscall`  (https://man7.org/linux/man-pages/man2/syscall.2.html)


.section .data

message:
	.ascii "Hello World\n"
