; hello-os

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
    MOV   ES, AX
    MOV   SI, msg

putloop:
    MOV   AL, [SI]          ; printed character
    ADD   SI, 1
    CMP   AL, 0
    JE    fin
    MOV   AH, 0x0e          ; Teletype output
    MOV   BX, 15            ; Color code
    INT   0x10              ; BIOS interrupt call: video service
    JMP   putloop

fin:
    HLT
    JMP   fin

msg:
    DB    0x0a, 0x0a        ; 2 LF
    DB    "hello, world"    ; Message
    DB    0x0a              ; LF
    DB    0                 ; End of Message

    RESB  0x1fe-($-$$)

    DB  0x55, 0xaa

    DB  0xf0, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00
    RESB  4600
    DB  0xf0, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00
    RESB  1469432

