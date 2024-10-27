AS := arm-none-eabi-as
LD := arm-none-eabi-ld
QEMU := qemu-arm

SOURCES := $(wildcard *.s)

OBJECTS := $(SOURCES:.s=.o)
%.o: %.s
	$(AS) $< -o $@

BINARIES := $(OBJECTS:.o=)
%: %.o
	$(LD) $< -o $@

.DEFAULT_GOAL := build
build: $(OBJECTS) $(BINARIES)

run: $(BINARIES)
	$(QEMU) $<

clean:
	rm $(OBJECTS) $(BINARIES) 2>/dev/null || true
