.include "banana-term.inc"

.bss

modemCommandsIndex: .res 1
serialGetChar: .res 1

.data

connected: .byte 0

.if .defined(CURSOR_SHOW)
    cursorOn: .byte 0
.endif

.if .defined(__C128__) .or .defined(__PLUS4__)
    functionKeyCodes:
        .byte PETSCII_F1, PETSCII_F2, PETSCII_F3, PETSCII_F4, PETSCII_F5, PETSCII_F6, PETSCII_F7, PETSCII_F8
        .if .defined(__C128__)
            .byte PETSCII_RUN, PETSCII_FLASH_OFF
        .endif
.elseif .defined(__C64__)
    ; nothing to do
.else
    .assert 0, error, "target not supported"
.endif

.rodata

; must be terminated by a zero byte
; must be less than 256 bytes
modemCommands:
    .res 256, $00 ; ##MODEM_COMMANDS

modemCommandsError:
    .byte "Modem commands failed.", PETSCII_RETURN
    .byte "Error code: "
    .byte $00

serialDisconnected:
    .byte "Disconnected.", PETSCII_RETURN
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

serialOpenError:
    .byte "Serial port open failed.", PETSCII_RETURN
    .byte "Error code: "
    .byte $00

serialOpenOk:
    .byte "Serial port is open.", PETSCII_RETURN
    .byte $00

serialPutError:
    .byte "Serial put failed.", PETSCII_RETURN
    .byte "Error code: "
    .byte $00

serialOpenParameters:
    .byte SERIAL_BAUD
    .byte SER_BITS_8
    .byte SER_STOP_1
    .byte SER_PAR_NONE
    .byte SER_HS_HW

welcomeMessage:
    .byte PETSCII_CLEAR
    .byte TERMINAL_BANANA_COLOR_PETSCII, "Banana"
    .byte TERMINAL_TEXT_COLOR_PETSCII, "-Term v"
    .byte "1.1" ; #VERSION#
    .byte PETSCII_RETURN
    .byte "  "
    .if .defined(__C128__) .or .defined(__C64__)
        .if .defined(__C128__)
            .byte "C128"
        .else
            .byte "C64"
        .endif
        .byte ", SwiftLink, $DE00, NMI", PETSCII_RETURN
    .elseif .defined(__PLUS4__)
        .byte "Plus/4, ACIA", PETSCII_RETURN
    .else
        .assert 0, error, "target not supported"
    .endif
    .byte "  "

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
    .else
        .assert 0, error, "unsupported baud rate"
    .endif
    .byte "-8N1, old-style RTS/CTS", PETSCII_RETURN
    .byte PETSCII_RETURN
    .byte $00

.code

; input:
;   a, x: pointer to driver
.proc _mainAssembly
        ; save serial driver address
        pha
        txa
        pha

        lda #TERMINAL_BACKGROUND_COLOR
        sta SCREEN_BACKGROUND_COLOR
        lda #TERMINAL_BORDER_COLOR
        sta SCREEN_BORDER_COLOR

        lda #PETSCII_LOCK_CASE
        kernalChrOut
        jsr screenPutControlCharLowerCase

        ; replace functionkey shortcuts to functionkey petscii control codes
        .if .defined(__C128__) .or .defined(__PLUS4__)
                sei
                ldx #FUNCTION_KEY_DEFINITIONS-1
            @functionKeysLoop:
                lda #$01
                sta FUNCTION_KEY_DEFINITION_DATA,x
                lda functionKeyCodes,X
                sta FUNCTION_KEY_DEFINITION_DATA+FUNCTION_KEY_DEFINITIONS,x
                dex
                bpl @functionKeysLoop
                cli
        .elseif .defined(__C64__)
            ; nothing to do
        .else
            .assert 0, error, "target not supported"
        .endif

        loadPointerY ptr2, welcomeMessage
        jsr screenPutString

        .if .defined(BELL_BORDER_COLOR) .or .defined(BELL_SOUND_VOLUME)
            jsr interruptSetup
        .endif

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
        sta modemCommandsIndex
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

    @mainLoop:
        lda connected
        bne @connectionChecked
        lda ACIA_STATUS
        and #ACIA_STATUS_DCD
        bne @connectionChecked
        lda #$01
        sta connected
    @connectionChecked:

        ; read keyboard
        kernalGetIn
        cmp #$00
        beq @keyboardEnd
        jsr ser_put
        cmp #SER_ERR_OK
        beq @keyboardEnd
        cmp #SER_ERR_OVERFLOW
        beq @putOverflow
        loadPointerY ptr2, serialPutError
        jmp showErrorAndHalt
    @putOverflow:
        .if .defined(BELL_BORDER_COLOR) .or .defined(BELL_SOUND_VOLUME) .or .defined(BELL_KERNAL)
            jsr interruptBell
        .endif
    @keyboardEnd:

        ; read serial
        loadPointerY ptr1, serialGetChar
        jsr ser_get
        cmp #SER_ERR_OK
        beq @gotChar
        cmp #SER_ERR_NO_DATA
        beq @noChar
        loadPointerY ptr2, serialGetError
        jmp showErrorAndHalt
    @noChar:
        lda connected
        beq @showCursor
        lda ACIA_STATUS
        and #ACIA_STATUS_DCD
        beq @showCursor
        lda #$00
        sta connected
        jsr showDisconnected
    @showCursor:
        .if .defined(CURSOR_SHOW)
            lda cursorOn
            bne @cursorOn
            ; cursor off
            lda #$01
            sta cursorOn
            jsr screenCursorOn
        .endif
    @cursorOn:
        jmp @mainLoop
    @gotChar:
        .if .defined(CURSOR_SHOW)
            lda cursorOn
            beq @cursorOff
            ; cursor on
            lda #$00
            sta cursorOn
            jsr screenCursorOff
        .endif
    @cursorOff:
        ldy #$00
        lda (ptr1),y
        jsr screenPutChar
        jmp @mainLoop
.endproc

; a: border color
; clobbers: a, y, ptr1, ptr2
.proc resetScreen
        pha
        .if .defined(BELL_BORDER_COLOR) .or .defined(BELL_SOUND_VOLUME)
            jsr interruptStopBell
        .endif
        pla
        sta SCREEN_BORDER_COLOR
        jsr screenPutControlCharLowerCase
        lda #TERMINAL_TEXT_COLOR
        sta screenCursorColor
        lda #$00
        sta screenCursorReverse
        jsr screenMoveCursorNextLine
        rts
.endproc

; clobbers: a, y, ptr1, ptr2
.proc showDisconnected
        lda #TERMINAL_BORDER_COLOR_DISCONNECTED
        jsr resetScreen
        loadPointerY ptr2, serialDisconnected
        jsr screenPutString
        rts
.endproc

; a: error code
; ptr2: message
; never returns
.proc showErrorAndHalt
        pha
        lda #TERMINAL_BORDER_COLOR_ERROR
        jsr resetScreen
        jsr screenPutString
        pla
        jsr screenPutHexByte
    @loop:
        jmp @loop
.endproc
