ipl.bin: ipl.asm
	nasm ipl.asm -o ipl.bin

os.img: ipl.bin
	mformat -f 1440 -C -B ipl.bin -i os.img

run: os.img
	qemu-system-x86_64 -cpu 486 -fda ./os.img

clean:
	@rm -f *.bin
	@rm -f *.img

.PHONY: clean
