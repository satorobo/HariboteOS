; haribote.asm

; BOOT_INFO
CYLS    EQU   0x0ff0  ; Set in IPL
LEDS    EQU   0x0ff1
VMODE   EQU   0x0ff2  ; Color info(X bit color)
SCRNX   EQU   0x0ff4  ; Resolusion(horizontal)
SCRNY   EQU   0x0ff6  ; Resolusion(vertical)
VRAM    EQU   0x0ff8  ; Start address of graphic buffer

        ORG 0xc200                  ; The address where this process is loaded

; Set Video Mode

        ;; BIOS interrupt call
        ;;    INT 0x10: Video Services
        ;; ================ Function ================
        ;; AH = 0x00: Set Vide Mode
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
        MOV   BYTE  [VMODE], 8      ; Memorize the video mode
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

fin:
        HLT
        JMP fin
