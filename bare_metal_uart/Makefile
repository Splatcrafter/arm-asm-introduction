AS := arm-none-eabi-as
CC := arm-none-eabi-gcc
LD := arm-none-eabi-ld
OC := arm-none-eabi-objcopy
CPU := arm926ej-s
QEMU_SYSTEM := qemu-system-arm

LINKER_SCRIPT := print_uart.ld

SOURCES_S := $(wildcard *.s)
SOURCES_C := $(wildcard *.c)

OBJECTS_S := $(SOURCES_S:.s=.o)
%.o: %.s
	$(AS) -mcpu=$(CPU) -g $< -o $@

OBJECTS_C := $(SOURCES_C:.c=.o)
%.o: %.c
	$(CC) -c -mcpu=$(CPU) -g $< -o $@

ELF := $(OBJECTS_C:.o=.elf)
%.elf: %.o
	$(LD) -T $(LINKER_SCRIPT) $< -o $@

BINARY := $(ELF:.elf=.bin)
%.bin: %.elf
	$(OC) -O binary $< $@

.DEFAULT_GOAL := build
build: $(OBJECTS_S) $(OBJECTS_C) $(ELF) $(BINARY)

run: $(BINARY)
	$(QEMU_SYSTEM) -M versatilepb -m 128M -nographic -kernel $<   ## press Ctrl+A X to quit qemu

clean:
	rm $(OBJECTS_S) $(OBJECTS_C) $(ELF) $(BINARY) 2>/dev/null || true

