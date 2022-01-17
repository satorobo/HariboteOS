; nasmhead.asm

BOTPAC  EQU   0x00280000  ; The address where bootpack is loaded
DSKCAC  EQU   0x00100000  ; Disk cache address
DSKCAC0 EQU   0x00008000  ; Disk cache address(real mode)

; BOOT_INFO
CYLS    EQU   0x0ff0      ; Set in IPL
LEDS    EQU   0x0ff1
VMODE   EQU   0x0ff2      ; Color info(X bit color)
SCRNX   EQU   0x0ff4      ; Resolusion(horizontal)
SCRNY   EQU   0x0ff6      ; Resolusion(vertical)
VRAM    EQU   0x0ff8      ; Start address of graphic buffer

        ORG 0xc200                  ; The address where this process is loaded

; Set Video Mode

        ;; BIOS interrupt call
        ;;    INT 0x10: Video Services
        ;; ================ Function ================
        ;; AH = 0x00: Set Video Mode
        ;; =============== Parameters ===============
        ;; AL = Video Mode Flag
        ;;      0x03: 16 color text, 80x25
        ;;      0x12: VGA graphics, 640x480, 4bit color
        ;;      0x13: VGA graphics, 320x200, 8bit color
        ;;      0x6a: Extended VGA graphics, 800x600, 4bit color
        ;; ------------------------------------------

        MOV   AL, 0x13              ; VGA graphics, 320x200, 8bit color
        MOV   AH, 0x00
        INT       0x10              ; BIOS interrupt call: Video Service
        MOV   BYTE  [VMODE], 8      ; Memorize the video mode(referred by C)
        MOV   WORD  [SCRNX], 320
        MOV   WORD  [SCRNY], 200
        MOV   DWORD [VRAM],  0x000a0000

; Get keyboard LED status from BIOS

        ;; BIOS interrupt call
        ;;    INT 0x16: Keyboard Services
        ;; ================ Function ================
        ;; AH = 0x02: Get the Keyboard State
        ;; ------------------------------------------

        MOV   AH, 0x02              ; Get the Keyboard State
        INT   0x16                  ; BIOS interrupt call: Keyboard Services
        MOV   [LEDS], AL

; Disable any interrupts in PIC
;   The system may hang up before executing the CLI instruction
;   when initilize PIC in the AT compatible machine

        MOV   AL, 0xff
        OUT   0x21, AL
        NOP                         ; Avoid executing OUT continuously
        OUT   0xa1, AL

        CLI                         ; Disable interrupts in CPU

; Set A20 GATE so that the CPU can access more than 1MB of memory

        CALL  waitkbdout
        MOV   AL, 0xd1
        OUT   0x64, AL
        CALL  waitkbdout
        MOV   AL, 0xdf              ; Enable A20
        OUT   0x60, AL
        CALL  waitkbdout

; Transfer protect mode

; [INSTRSET "i486p"]

        LGDT  [GDTR0]
        MOV   EAX, CR0              ; CR0: Conrtol Register
        AND   EAX, 0x7fffffff       ; Disable paging
        OR    EAX, 0x00000001       ; Enable Protect Mode
        MOV   CR0, EAX
        JMP   pipelineflush

pipelineflush:
        MOV   AX, 1*8               ; read/write segment(32bit)
        MOV   DS, AX
        MOV   ES, AX
        MOV   FS, AX
        MOV   GS, AX
        MOV   SS, AX

; Load bootpack

        MOV   ESI, bootpack         ; Source
        MOV   EDI, BOTPAC           ; Destination
        MOV   ECX, 512*1024/4       ; Size
        CALL  memcpy

; Load Disk Data

        ; boot sector
        MOV   ESI, 0x7c00           ; Source
        MOV   EDI, DSKCAC           ; Destination
        MOV   ECX, 512/4            ; Size
        CALL  memcpy

        ; residual
        MOV   ESI, DSKCAC0+512      ; Source
        MOV   EDI, DSKCAC+512       ; Destination
        MOV   ECX, 0
        MOV   CL, BYTE [CYLS]
        IMUL  ECX, 512*18*2/4       ; Cylinder => Bytes
        SUB   ECX, 512/4            ; Subtract the size of IPL
        CALL  memcpy

; Boot bootpack

        MOV   EBX, BOTPAC
        MOV   ECX, [EBX+16]
        ADD   ECX, 3                ; ECX += 3;
        SHR   ECX, 2                ; ECX /= 4;
        JZ    skip                  ; Jump skip if there is nothing to be loaded
        MOV   ESI, [EBX+20]         ; Source
        ADD   ESI, EBX
        MOV   EDI, [EBX+12]         ; Destination
        CALL  memcpy

skip:
        MOV   ESP, [EBX+12]         ; Initialize Stack Pointer
        JMP   DWORD 2*8:0x0000001b

waitkbdout:
        IN    AL, 0x64
        AND   AL, 0x02
        JNZ   waitkbdout            ; Jump waitkbdout if result of previous AND is NOT 0
        RET

memcpy:
        MOV   EAX, [ESI]
        ADD   ESI, 4
        MOV   [EDI], EAX
        ADD   EDI, 4
        SUB   ECX, 1
        JNZ   memcpy
        RET

        ALIGNB  16

GDT0:
        RESB  8                     ; Null selector
        DW    0xffff, 0x0000, 0x9200, 0x00cf  ; read/write segment(32bit)
        DW    0xffff, 0x0000, 0x9a28, 0x0047  ; executable segment for bootpack(32bit)

        DW    0

GDTR0:
        DW    8*3-1
        DD    GDT0

        ALIGNB  16

bootpack:
