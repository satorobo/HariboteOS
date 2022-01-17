; nasmfunc.asm
bits 32
global io_hlt
global write_mem8

section .text
io_hlt:
    HLT
    RET

write_mem8:             ; void write_mem8(int addr, int data)
    MOV   ECX, [ESP+4]  ; [ESP+4] point to addr
    MOV   AL, [ESP+8]   ; [ESP+8] point to data
    MOV   [ECX], AL
    RET
