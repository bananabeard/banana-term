.include "banana-term.inc"

.bss

modemCommandsIndex: .res 1

.rodata

; must be terminated by a zero byte
; must be less than 256 bytes
modemCommands:
    .res 256, $00 ; ##MODEM_COMMANDS

modemCommandsError:
    .byte "Modem commands failed.", PETSCII_RETURN
    .byte "Error code: "
    .byte $00

serialGetError:
    .byte "Serial get failed.", PETSCII_RETURN
    .byte "Error code: "
    .byte $00

serialInstallError:
    .byte "Serial driver install failed.", PETSCII_RETURN
    .byte "Error code: "
    .byte $00

serialInstallOk:
    .byte "Serial driver is installed.", PETSCII_RETURN
    .byte $00

serialMessage:
    .if .defined(__C128__) .or .defined(__C64__)
        .if .defined(__C128__)
            .byte "C128"
        .else
            .byte "C64"
        .endif
        .byte ", SwiftLink, $DE00, NMI"
    .elseif .defined(__PLUS4__)
        .byte "Plus/4, ACIA"
    .else
        .assert 0, error, "target not supported"
    .endif
    .byte PETSCII_RETURN
    .if SERIAL_BAUD = SER_BAUD_300
        .byte "300"
    .elseif SERIAL_BAUD = SER_BAUD_600
        .byte "600"
    .elseif SERIAL_BAUD = SER_BAUD_1200
        .byte "1200"
    .elseif SERIAL_BAUD = SER_BAUD_2400
        .byte "2400"
    .elseif SERIAL_BAUD = SER_BAUD_4800
        .byte "4800"
    .elseif SERIAL_BAUD = SER_BAUD_9600
        .byte "9600"
    .elseif SERIAL_BAUD = SER_BAUD_19200
        .byte "19200"
    .elseif SERIAL_BAUD = SER_BAUD_38400
        .byte "38400"
    .elseif SERIAL_BAUD = SER_BAUD_57600
        .byte "57600"
    .elseif .defined(DISABLE_CHECKS)
        .byte "xxxxx"
    .else
        .assert 0, error, "unsupported baud rate"
    .endif
    .byte "-8N1, old-style RTS/CTS", PETSCII_RETURN
    .byte $00

serialOpenError:
    .byte "Serial port open failed.", PETSCII_RETURN
    .byte "Error code: "
    .byte $00

serialOpenOk:
    .byte "Serial port is open.", PETSCII_RETURN
    .byte $00

serialOpenParameters:
    .byte SERIAL_BAUD
    .byte SER_BITS_8
    .byte SER_STOP_1
    .byte SER_PAR_NONE
    .byte SER_HS_HW

serialPutError:
    .byte "Serial put failed.", PETSCII_RETURN
    .byte "Error code: "
    .byte $00

.code

; output:
;   c flag: set == got data
;   netGetData: data
.proc netGet
        loadPointerY ptr1, netGetData
        jsr ser_get
        cmp #SER_ERR_OK
        bne @notOk
        rts
    @notOk:
        cmp #SER_ERR_NO_DATA
        bne @error
        clc
        rts
    @error:
        loadPointerY ptr2, serialGetError
        jmp showErrorAndHalt
.endproc

; input:
;   a, x: pointer to driver
.proc netOpen
        ; save serial driver address
        pha
        txa
        pha

        loadPointerY ptr2, serialMessage
        jsr screenPutString

        ; restore serial driver address
        pla
        tax
        pla
        jsr _ser_install
        cmp #SER_ERR_OK
        beq @serialInstallOk
        loadPointerY ptr2, serialInstallError
        jmp showErrorAndHalt
    @serialInstallOk:
        loadPointerY ptr2, serialInstallOk
        jsr screenPutString

        loadPointerY ptr1, serialOpenParameters
        jsr ser_open
        cmp #SER_ERR_OK
        beq @serialOpenOk
        loadPointerY ptr2, serialOpenError
        jmp showErrorAndHalt
    @serialOpenOk:
        loadPointerY ptr2, serialOpenOk
        jsr screenPutString

        ; modem commands
        ldx #$00
        stx modemCommandsIndex
    @modemCommandsLoop:
        ldx modemCommandsIndex
        lda modemCommands,x
        beq @modemCommandsEnd
        inx
        stx modemCommandsIndex
        jsr ser_put
        cmp #SER_ERR_OK
        beq @modemCommandsPutOk
        loadPointerY ptr2, modemCommandsError
        jmp showErrorAndHalt
    @modemCommandsPutOk:
        jmp @modemCommandsLoop
    @modemCommandsEnd:

        rts
.endproc

; input:
;   a: byte to send
.proc netPut
        jsr ser_put
        cmp #SER_ERR_OK
        beq @putEnd
        cmp #SER_ERR_OVERFLOW
        beq @putOverflow
        loadPointerY ptr2, serialPutError
        jmp showErrorAndHalt

    @putOverflow:
        .if .defined(BELL_BORDER_COLOR) .or .defined(BELL_SOUND_VOLUME) .or .defined(BELL_KERNAL)
            jsr interruptBell
        .endif

    @putEnd:
        rts
.endproc
