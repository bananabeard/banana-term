.include "banana-term.inc"

.bss

netGetData: .res 1

.data

.if .defined(CURSOR_SHOW)
    cursorOn: .byte 0
.endif

.rodata

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

welcomeMessage:
    .byte PETSCII_CLEAR, PETSCII_LOWER_CASE
    .byte TERMINAL_BANANA_COLOR_PETSCII, "Banana"
    .byte TERMINAL_TEXT_COLOR_PETSCII, "-Term v"
    .byte "1.3" ; #VERSION#
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
        loadPointerY ptr2, welcomeMessage
        jsr screenPutString

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

        .if .defined(BELL_BORDER_COLOR) .or .defined(BELL_SOUND_VOLUME)
            jsr interruptSetup
        .endif

        ; restore serial driver address
        pla
        tax
        pla
        jsr netOpen

    @mainLoop:
        ; read keyboard
        kernalGetIn
        cmp #$00
        beq @keyboardEnd
        jsr netPut
    @keyboardEnd:

        ; read net
        jsr netGet
        bcc @noData
        ; got data
        .if .defined(CURSOR_SHOW)
            lda cursorOn
            beq @cursorOff
            ; cursor on
            lda #$00
            sta cursorOn
            jsr screenCursorOff
        .endif
    @cursorOff:
        lda netGetData
        jsr screenPutChar
        jmp @mainLoop
    @noData:
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
.endproc

; a: border color
; clobbers: a, y, ptr1, ptr2, ptr3, pt4
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

; a: error code
; ptr2: message
; never returns
.proc showErrorAndHalt
        pha
        lda ptr2
        pha
        lda ptr2+1
        pha
        lda #TERMINAL_BORDER_COLOR_ERROR
        jsr resetScreen
        jsr screenPutString
        pla
        sta ptr2+1
        pla
        sta ptr2
        pla
        jsr screenPutHexByte
    @loop:
        jmp @loop
.endproc
