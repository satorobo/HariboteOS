; ipl.asm

    CYLS  equ 10

    ORG   0x7c00            ; The address where bootloader is loaded
    JMP   entry
    DB    0x90

    DB    0xeb, 0x4e, 0x90  ; BS_JmpBoot:     Jump Instruction to Boot Code
    DB    "HELLOIPL"        ; BS_OEMName:     Volume Name
    DW    512               ; BPB_BytsPerSec: Count of bytes per sector
    DB    1                 ; BPB_SecPerClus: Number of sectors per allocation unit
    DW    1                 ; BPB_RsvdSecCnt: First sector of the volume
    DB    2                 ; BPB_NumFATs:    The count of FATs(2 is recommended)
    DW    224               ; BPB_RootEntCnt: Number of directory entries in the root directory
    DW    2880              ; BPB_TotSec16:   Size of the volume(16-bit total count of sectors)
    DB    0xf0              ; BPB_Media:      For removable media, 0xf0 is frequently used
    DW    9                 ; BPB_FATSz16:    The old 16-bit count of sectors occupied by one FAT
    DW    18                ; BPB_SecPerTrk:  Sectors per track
    DW    2                 ; BPB_NumHeads:   Number of heads
    DD    0                 ; BPB_HiddSec:    Count of hidden sectors
    DD    2880              ; BPB_TotSec32:   The new 32-bit total count of sectors on the volume
    DB    0, 0, 0x29        ; BS_DrvNum, BS_Reserved1, BS_BootSig
    DD    0xffffffff        ; BS_VolID:       Volume serial number
    DB    "HELLO-OS   "     ; BS_VolLab:      Volume label
    DB    "FAT12   "        ; BS_FilSysType:  This is only informational
    RESB  18

entry:                      ; Initialize registers
    MOV   AX, 0
    MOV   SS, AX
    MOV   SP, 0x7c00
    MOV   DS, AX

    ;; BIOS interrupt call
    ;;    INT 0x13: Low Level Disk Services
    ;; ================ Function ================
    ;; AH = 0x02: Read Sectors
    ;; =============== Parameters ===============
    ;; AL = Sectors To Read Count
    ;; CH = Cylinder & 0xff
    ;; CL = Sector | (Cylinder & 0x300) >> 2
    ;; DH = Head
    ;; DL = Drive
    ;; ES:BS = Buffer Address Pointer
    ;;         (ES x 16 + BS)
    ;; ================ Resuults ================
    ;; FLAGS.CF = 0: No Error
    ;; FLAGS.CF = 1: Error
    ;; AH = Return Code
    ;; AL = Actual Sectors Read Count
    ;; ------------------------------------------

    ; Set Initial Parameters for Read Disk
    MOV   AX, 0x0820        ; Buffer Address Pointer
    MOV   ES, AX            ;   `-> 0x8200 = 0x0820 x 16 + 0
    MOV   CH, 0             ; Cylinder: 0
    MOV   DH, 0             ; Head:     0
    MOV   CL, 2             ; Sector:   2

readloop:
    MOV   SI, 0             ; counter for read error

retry:
    MOV   AH, 0x02          ; Read Sectors
    MOV   AL, 1             ; Read 1 sector
    MOV   BX, 0             ; Offset of Buffer Address
    MOV   DL, 0x00          ; A Drive
    INT   0x13              ; BIOS interrupt call: Low Level Disk Services
    JNC   next              ; Jump next if no read error occurred
    ADD   SI, 1             ; Increment read error counter
    CMP   SI, 5
    JAE   error             ; Jump error if read error occuured above 5
    MOV   AH, 0x00          ; Reset drive for retry
    MOV   DL, 0x00          ; Reset drive for retry
    INT   0x13              ; BIOS interrupt call again for retry
    JMP   retry

next:
    MOV   AX, ES
    ADD   AX, 0x0020
    MOV   ES, AX
    ADD   CL, 1             ; Set next sector
    CMP   CL, 18
    JBE   readloop
    MOV   CL, 1
    ADD   DH, 1             ; Set next head
    CMP   DH, 2
    JB    readloop
    MOV   DH, 0
    ADD   CH, 1             ; Set next cylinder
    CMP   CH, CYLS
    JB    readloop

    MOV   [0x0ff0], CH      ; Memorize the last read cylinder
    JMP   0xc200            ; Jump main process(jump to os.sys)

error:
    MOV   SI, msg

    ;; BIOS interrupt call
    ;;    INT 0x10: Video Services
    ;; ================ Function ================
    ;; AH = 0x0e: Write Character in TTY Mode
    ;; =============== Parameters ===============
    ;; AL = Character
    ;; BH = Page Number
    ;; BL = Color Code
    ;; ------------------------------------------

putloop:
    MOV   AL, [SI]          ; printed character
    ADD   SI, 1
    CMP   AL, 0
    JE    fin
    MOV   AH, 0x0e          ; Teletype output
    MOV   BX, 15            ; Color Code
    INT   0x10              ; BIOS interrupt call: Video Service
    JMP   putloop

fin:
    HLT
    JMP   fin

msg:
    DB    0x0a, 0x0a        ; 2 LF
    DB    "load error"      ; Message
    DB    0x0a              ; LF
    DB    0                 ; End of Message

    RESB  0x1fe-($-$$)

    DB  0x55, 0xaa          ; End of Boot Sector

