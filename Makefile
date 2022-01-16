ipl.bin: ipl.asm
	nasm ipl.asm -o ipl.bin

haribote.bin: haribote.asm
	nasm haribote.asm -o haribote.bin

os.sys: haribote.bin
	cat haribote.bin > os.sys

os.img: ipl.bin os.sys
	mformat -f 1440 -C -B ipl.bin -i os.img ::
	mcopy -i os.img os.sys ::

run: os.img
	qemu-system-x86_64 -cpu 486 -fda ./os.img

clean:
	@rm -f *.bin
	@rm -f *.img
	@rm -f *.sys

.PHONY: clean
