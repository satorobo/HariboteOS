nasmhead.bin: nasmhead.asm
	nasm -o nasmhead.bin nasmhead.asm

nasmfunc.o: nasmfunc.asm
	nasm -f elf32 -o nasmfunc.o nasmfunc.asm

bootpack.o: bootpack.c
	gcc -c -m32 -fno-pic -o bootpack.o bootpack.c

bootpack.bin: bootpack.o nasmfunc.o
	ld -m elf_i386 -e HariMain -o bootpack.bin -Tos.ls bootpack.o nasmfunc.o

os.sys: nasmhead.bin bootpack.bin
	cat  nasmhead.bin bootpack.bin > os.sys

ipl.bin: ipl.asm
	nasm -o ipl.bin ipl.asm

os.img: ipl.bin os.sys
	mformat -f 1440 -C -B ipl.bin -i os.img ::
	mcopy -i os.img os.sys ::

run: os.img
	qemu-system-x86_64 -cpu 486 -fda ./os.img

clean:
	@rm -f *.bin
	@rm -f *.o
	@rm -f *.img
	@rm -f *.sys

debug:
	qemu-system-x86_64 -cpu 486 -vga std -fda os.img -gdb tcp::10000 -S &

.PHONY: clean debug
