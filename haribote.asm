; haribote.asm

    ORG 0xc200              ; The address where this process is loaded

    ;; BIOS interrupt call
    ;;    INT 0x10: Video Services
    ;; ================ Function ================
    ;; AH = 0x00: Set Vide Mode
    ;; =============== Parameters ===============
    ;; AL = Vide Mode Flag
    ;;      0x03: 16 color text, 80x25
    ;;      0x12: VGA graphics, 640x480, 4bit color
    ;;      0x13: VGA graphics, 320x200, 8bit color
    ;;      0x6a: Extended VGA graphics, 800x600, 4bit color
    ;; ------------------------------------------

    MOV AL, 0x13            ; VGA graphics, 320x200, 8bit color
    MOV AH, 0x00
    INT   0x10              ; BIOS interrupt call: Video Service

fin:
    HLT
    JMP fin
