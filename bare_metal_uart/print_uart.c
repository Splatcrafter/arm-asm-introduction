volatile unsigned int * const UART0DR = (unsigned int *)0x101f1000;  // address where the UART0 is mapped

void print_uart0(const char *s) {
    while(*s != '\0') {	                // Loop until end of string
        *UART0DR = (unsigned int)(*s);  // Transmit char
        s++;                            // Next char
    }
}

void c_entry() {
    print_uart0("Hello world!\n");
    print_uart0("Ctrl+A X to quit qemu\n");
}
