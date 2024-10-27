# [ARM assembly](https://developer.arm.com/documentation/dui0489/i/arm-and-thumb-instructions/arm-and-thumb-instruction-summary) and [GNU Binutils](https://en.wikipedia.org/wiki/GNU_Binutils)

## Setup

We need:
* `arm-none-eabi-as` assembler
* `arm-none-eabi-ld` linker
* `qemu-arm` arm binary emulator

### Nix

```sh
nix shell nixpkgs#gcc-arm-embedded nixpkgs#qemu
```


## Examples

### 1. Syscall exit

Lets start by exiting gracefully…

Our equivalent to `exit(0)` looks like this:
```asm
mov r0, #0
mov r7, #1
swi 0
```

1. To return with exit code 0 ([`OK`](https://man.freebsd.org/cgi/man.cgi?query=sysexits)), we write it into register `r0` (as expected for [syscall `exit`](https://arm.syscall.sh/)).
2. In register `r0` the number of the syscall is required. For `exit` it is [`#1`](https://arm.syscall.sh/).
3. To trigger the syscall on `arm/EABI`, the [software interrupt number 0](https://man7.org/linux/man-pages/man2/syscall.2.html) is requested by the instruction `swi`.

```
cd exit
make build 
# arm-none-eabi-as exit.s -o exit.o
# arm-none-eabi-ld exit.o -o exit
```

```sh
qemu-arm exit
echo $?  ## get the exit code of the last command
#-> 0
```

Our first asm-program did nothing, but it exited with status OK


### 2. Hello World

Let's print "Hello World"…

```asm
mov r0, #1        // stdout
ldr r1, =message  // address of message
mov r2, #12       // len(message)
mov r7, #4        // syscall `write` 
swi 0

.section .data
message:
  .ascii "Hello World\n"
```

1. We put our String into the `.data` segment. The address where it is stored will be accessible via the label `message`.
2. Printing a message is done with the [`write` syscall `#4`](https://arm.syscall.sh/). For writing to stdout in [Booting Linux](https://en.wikipedia.org/wiki/POSIX), [file descriptor 1](https://en.wikipedia.org/wiki/File_descriptor) is used.

```sh
cd hello
make run
#-> Hello World
```

#### Inspect the binary
Hexdump
```sh
xxd hello.o
```

Compare size (in bytes) of objectfile and linked binary
```sh
stat -c "%s %n" -- hello.o hello
#-> 764 hello.o
#-> 5080 hello
```

Sizes of sections inside binary files
```sh
size hello.o hello
#->   text    data     bss     dec     hex filename
#->     36      12       0      48      30 hello.o
#->     36      12       0      48      30 hello
```

##### Details of the ELF binary
```sh
readelf hello --file-header
```
```
ELF Header:
  Magic:   7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00 
  Class:                             ELF32
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              EXEC (Executable file)
  Machine:                           ARM
  Version:                           0x1
  Entry point address:               0x8000
  Start of program headers:          52 (bytes into file)
  Start of section headers:          4720 (bytes into file)
  Flags:                             0x5000200, Version5 EABI, soft-float ABI
  Size of this header:               52 (bytes)
  Size of program headers:           32 (bytes)
  Number of program headers:         2
  Size of section headers:           40 (bytes)
  Number of section headers:         9
  Section header string table index: 8
```

```sh
readelf hello --sections 
```
```
There are 9 section headers, starting at offset 0x1270:

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        00008000 001000 000024 00  AX  0   0  4
  [ 2] .data             PROGBITS        00009024 001024 00000c 00  WA  0   0  1
  [ 3] .persistent       PROGBITS        00009030 001030 000000 00  WA  0   0  1
  [ 4] .noinit           NOBITS          00009030 000000 000000 00  WA  0   0  1
  [ 5] .ARM.attributes   ARM_ATTRIBUTES  00000000 001030 000012 00      0   0  1
  [ 6] .symtab           SYMTAB          00000000 001044 000170 10      7  13  4
  [ 7] .strtab           STRTAB          00000000 0011b4 000070 00      0   0  1
  [ 8] .shstrtab         STRTAB          00000000 001224 00004b 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute)
```


#### Disassemble
```sh
arm-none-eabi-objdump -S hello
```
```asm
hello:     file format elf32-littlearm


Disassembly of section .text:

00008000 <_start>:
    8000:       e3a00001        mov     r0, #1
    8004:       e59f1014        ldr     r1, [pc, #20]   @ 8020 <exit+0xc>
    8008:       e3a0200c        mov     r2, #12
    800c:       e3a07004        mov     r7, #4
    8010:       ef000000        svc     0x00000000

00008014 <exit>:
    8014:       e3a00000        mov     r0, #0
    8018:       e3a07001        mov     r7, #1
    801c:       ef000000        svc     0x00000000
    8020:       00009024        .word   0x00009024
```

> Note how the address of the message is indirectly provided:
> 1. `ldr r1, [pc, #20]` uses the indirect address from the location with offset `#20` from the program counter `pc`
> 2. There (@ `0x8020`) we find the actual address `0x9024` in the `.data` segment

We can verify this and see, that the `message` symbol is stored exactly there:

```sh
readelf hello --symbols | grep 9024
```
```
     2: 00009024     0 SECTION LOCAL  DEFAULT    2 .data
     9: 00009024     0 NOTYPE  LOCAL  DEFAULT    2 message
    12: 00009024     0 NOTYPE  LOCAL  DEFAULT    2 $d
    22: 00009024     0 NOTYPE  GLOBAL DEFAULT    2 __data_start
```

```sh
readelf hello -x .data
```
```
Hex dump of section '.data':
  0x00009024 48656c6c 6f20576f 726c640a          Hello World.
```

```sh
arm-none-eabi-objcopy hello /dev/null --dump-section .data=/dev/stdout | xxd -o 0x9024 -c 4
```
```xxd
00009024: 4865 6c6c  Hell
00009028: 6f20 576f  o Wo
0000902c: 726c 640a  rld.
```

With the knowledge how the `.data` segment is mapped from file offset `Off` to ram address `Addr`, we can also hexdump this segment directly:

```sh
readelf --sections hello |grep -e Addr -e .data
```
```
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 2] .data             PROGBITS        00009024 001024 00000c 00  WA  0   0  1
```

```sh
xxd -s 0x1024 -l 0xc -o $((0x9024-0x1024)) -c 4 hello
```
```
00009024: 4865 6c6c  Hell
00009028: 6f20 576f  o Wo
0000902c: 726c 640a  rld.
```

## Further reading

* [ARM instruction summary](https://developer.arm.com/documentation/dui0489/i/arm-and-thumb-instructions/arm-and-thumb-instruction-summary)
* [Calling convention](https://developer.arm.com/documentation/den0013/d/Application-Binary-Interfaces/Procedure-Call-Standard)
* [Booting a bare-metal system](https://developer.arm.com/documentation/den0013/d/Boot-Code/Booting-a-bare-metal-system) and [Booting Linux](https://developer.arm.com/documentation/den0013/d/Boot-Code/Booting-Linux)
