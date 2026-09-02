.include "banana-term.inc"

.bss

; globals

.if .defined(CURSOR_SHOW)
    screenCursorColorBelow: .res 1
    .if .defined(CURSOR_SCREEN_CODE)
        screenCursorScreenCodeBelow: .res 1
    .endif
.endif

; static locals

screenPutStringIndex: .res 1

.data

; globals

screenCursorColor: .byte TERMINAL_TEXT_COLOR
screenCursorOffset: .word $0000
screenCursorReverse: .byte $00
screenCursorX: .byte $00
screenCursorY: .byte $00

.rodata

; tables

; jump table for control characters
screenControlChars:
    .word screenNoOp ; 0x00
    .word screenNoOp ; 0x01
    .word screenNoOp ; 0x02
    .word screenNoOp ; 0x03
    .word screenNoOp ; 0x04
    .word screenPutControlCharWhite ; 0x05
    .word screenNoOp ; 0x06
    .if .defined(BELL_BORDER_COLOR) .or .defined(BELL_SOUND_VOLUME) .or .defined(BELL_KERNAL)
        .word interruptBell ; 0x07
    .else
        .word screenNoOp ; 0x07
    .endif
    .word screenNoOp ; 0x08
    .word screenNoOp ; 0x09
    .word screenNoOp ; 0x0a
    .word screenNoOp ; 0x0b
    .word screenNoOp ; 0x0c
    .word screenMoveCursorNextLine ; 0x0d
    .word screenPutControlCharLowerCase ; 0x0e
    .word screenNoOp ; 0x0f

    .word screenNoOp ; 0x10
    .word screenMoveCursorDown ; 0x11
    .word screenPutControlCharReverseOn ; 0x12
    .word screenMoveCursorHome ; 0x13
    .word screenDel ; 0x14
    .word screenNoOp ; 0x15
    .word screenNoOp ; 0x16
    .word screenNoOp ; 0x17
    .word screenNoOp ; 0x18
    .word screenNoOp ; 0x19
    .word screenNoOp ; 0x1a
    .word screenNoOp ; 0x1b
    .word screenPutControlCharRed ; 0x1c
    .word screenMoveCursorRight ; 0x1d
    .word screenPutControlCharGreen ; 0x1e
    .word screenPutControlCharBlue ; 0x1f

    .word screenNoOp ; 0x80
    .word screenPutControlCharOrange ; 0x81
    .word screenNoOp ; 0x82
    .word screenNoOp ; 0x83
    .word screenNoOp ; 0x84
    .word screenNoOp ; 0x85
    .word screenNoOp ; 0x86
    .word screenNoOp ; 0x87
    .word screenNoOp ; 0x88
    .word screenNoOp ; 0x89
    .word screenNoOp ; 0x8a
    .word screenNoOp ; 0x8b
    .word screenNoOp ; 0x8c
    .word screenMoveCursorNextLine ; 0x8d
    .word screenPutControlCharUpperCase ; 0x8e
    .word screenNoOp ; 0x8f

    .word screenPutControlCharBlack ; 0x90
    .word screenMoveCursorUp ; 0x91
    .word screenPutControlCharReverseOff ; 0x92
    .word screenPutControlCharClear ; 0x93
    .word screenNoOp ; 0x94
    .word screenPutControlCharBrown ; 0x95
    .word screenPutControlCharLightRed ; 0x96
    .word screenPutControlCharDarkGray ; 0x97
    .word screenPutControlCharGray ; 0x98
    .word screenPutControlCharLightGreen ; 0x99
    .word screenPutControlCharLightBlue ; 0x9a
    .word screenPutControlCharLightGray ; 0x9b
    .word screenPutControlCharPurple ; 0x9c
    .word screenMoveCursorLeft ; 0x9d
    .word screenPutControlCharYellow ; 0x9e
    .word screenPutControlCharCyan ; 0x9f

screenHexCodes: .byte "0123456789abcdef"

.if SCREEN_HEIGHT = 25
    screenRowOffsets:
        .word  0*SCREEN_WIDTH,  1*SCREEN_WIDTH,  2*SCREEN_WIDTH,  3*SCREEN_WIDTH,  4*SCREEN_WIDTH
        .word  5*SCREEN_WIDTH,  6*SCREEN_WIDTH,  7*SCREEN_WIDTH,  8*SCREEN_WIDTH,  9*SCREEN_WIDTH
        .word 10*SCREEN_WIDTH, 11*SCREEN_WIDTH, 12*SCREEN_WIDTH, 13*SCREEN_WIDTH, 14*SCREEN_WIDTH
        .word 15*SCREEN_WIDTH, 16*SCREEN_WIDTH, 17*SCREEN_WIDTH, 18*SCREEN_WIDTH, 19*SCREEN_WIDTH
        .word 20*SCREEN_WIDTH, 21*SCREEN_WIDTH, 22*SCREEN_WIDTH, 23*SCREEN_WIDTH, 24*SCREEN_WIDTH
.else
    .assert 0, error, "screen height is not supported"
.endif

.code

.if .defined(CURSOR_SHOW)
    ; clobbers: a, y, ptr2
    .proc screenCursorOff
        .assert (<COLOR_RAM = 0), error, "color ram is not aligned"
        .assert (<SCREEN_MEMORY = 0), error, "screen memory is not aligned"
        ; restore color
        clc
        ldy #$00
        lda screenCursorOffset
        sta ptr2
        lda screenCursorOffset+1
        adc #>COLOR_RAM
        sta ptr2+1
        lda screenCursorColorBelow
        sta (ptr2),y
        ; restore screen code
        lda ptr2+1
        adc #>(SCREEN_MEMORY-COLOR_RAM)
        sta ptr2+1
        .if .defined(CURSOR_SCREEN_CODE)
            lda screenCursorScreenCodeBelow
        .else
            lda (ptr2),y
            eor #SCREEN_CODE_REVERSE
        .endif
        sta (ptr2),y
        rts
    .endproc

    ; clobbers: a, y, ptr2
    .proc screenCursorOn
        .assert (<COLOR_RAM = 0), error, "color ram is not aligned"
        .assert (<SCREEN_MEMORY = 0), error, "screen memory is not aligned"
        ; save color
        clc
        ldy #$00
        lda screenCursorOffset
        sta ptr2
        lda screenCursorOffset+1
        adc #>COLOR_RAM
        sta ptr2+1
        lda (ptr2),y
        sta screenCursorColorBelow
        ; set color
        lda screenCursorColor
        sta (ptr2),y
        ; save and set screen code
        lda ptr2+1
        adc #>(SCREEN_MEMORY-COLOR_RAM)
        sta ptr2+1
        lda (ptr2),y
        .if .defined(CURSOR_SCREEN_CODE)
            sta screenCursorScreenCodeBelow
            lda #CURSOR_SCREEN_CODE
        .else
            eor #SCREEN_CODE_REVERSE
        .endif
        sta (ptr2),y
        rts
    .endproc
.endif

; clobbers: a, y, status, ptr1, ptr2, ptr3, ptr4
.proc screenDel
        .assert (<COLOR_RAM = 0), error, "color ram is not aligned"
        .assert (<SCREEN_MEMORY = 0), error, "screen memory is not aligned"
        lda screenCursorX
        beq @firstColumn
        ; not first column
        ; memcpy
        ; length = SCREEN_WIDTH - screenCursorX
        ; y = 256 - length = (256 - SCREEN_WIDTH) + screenCursorX
        lda #(256-SCREEN_WIDTH)
        clc
        adc screenCursorX
        tay
        ; ptr3/4 = screenOffset - y
        lda screenCursorOffset+1
        sta ptr3+1
        sty ptr3
        sec
        lda screenCursorOffset
        sbc ptr3
        sta ptr3
        sta ptr4
        bcs @prt3AlmostSet
        dec ptr3+1
    @prt3AlmostSet:
        clc
        lda ptr3+1
        adc #>COLOR_RAM
        sta ptr3+1
        clc
        adc #>(SCREEN_MEMORY-COLOR_RAM)
        sta ptr4+1
        ; ptr3/4 set
        ; ptr1/2 = ptr3/4 - 1
        lda ptr3+1
        sta ptr1+1
        lda ptr4+1
        sta ptr2+1
        lda ptr3
        sta ptr1
        sta ptr2
        bne @decPtr12
        dec ptr1+1
        dec ptr2+1
    @decPtr12:
        dec ptr1
        dec ptr2
        jsr memcpyDoubleAscending
        ; clear last column
        ldy #$ff
        lda screenCursorColor
        sta (ptr3),y
        lda #SCREEN_CODE_SPACE
        sta (ptr4),y
        jmp screenMoveCursorLeft
    @firstColumn:
        lda screenCursorY
        beq @end
        ; not first row
        clc
        jsr screenMoveCursorLeft
        lda screenCursorOffset
        sta ptr1
        lda screenCursorOffset+1
        adc #>COLOR_RAM
        sta ptr1+1
        ldy #$00
        lda screenCursorColor
        sta (ptr1),y
        lda ptr1+1
        adc #>(SCREEN_MEMORY-COLOR_RAM)
        sta ptr1+1
        lda #SCREEN_CODE_SPACE
        sta (ptr1),y
    @end:
        rts
.endproc

; clobbers: a, status
.proc screenMoveCursorDown
        lda screenCursorY
        cmp #(SCREEN_HEIGHT-1)
        bcs @lastLine
        ; _screenY < SCREEN_HEIGHT-1
        inc screenCursorY
        lda screenCursorOffset
        clc

   adc #SCREEN_WIDTH
        sta screenCursorOffset
        bcc @end
        inc screenCursorOffset+1
    @end:
        rts
    @lastLine:
        jmp screenScrollOneLine
.endproc

; clobbers: a, status
.proc screenMoveCursorLeft
        lda screenCursorX
        bne @screenXNotZero
        ; _screenX == 0
        lda screenCursorY
        beq @return
        ; _screenY != 0
        lda #SCREEN_WIDTH-1
        sta screenCursorX
        dec screenCursorY
        jmp @decScreenOffset
    @screenXNotZero:
        dec screenCursorX
    @decScreenOffset:
        lda screenCursorOffset
        bne @screenOffsetNotZero
        ; low byte of _screenOffset == 0
        dec screenCursorOffset+1
    @screenOffsetNotZero:
        dec screenCursorOffset
    @return:
        rts
.endproc

; clobbers: a, status
.proc screenMoveCursorHome
    lda #$00
    sta screenCursorOffset
    sta screenCursorOffset+1
    sta screenCursorX
    sta screenCursorY
    rts
.endproc

; clobbers: a
.proc screenMoveCursorLastLineFirstColumn
    lda #<(SCREEN_WIDTH*(SCREEN_HEIGHT-1))
    sta screenCursorOffset
    lda #>(SCREEN_WIDTH*(SCREEN_HEIGHT-1))
    sta screenCursorOffset+1
    lda #$00
    sta screenCursorX
    lda #(SCREEN_HEIGHT-1)
    sta screenCursorY

    rts
.endproc

; clobbers: a, y, status
.proc screenMoveCursorNextLine
        ldy screenCursorY
        cpy #(SCREEN_HEIGHT-1)
        bcs @lastLine
        ; _screenY < SCREEN_HEIGHT-1
        lda #$00
        sta screenCursorX
        iny
        sty screenCursorY
        tya
        asl
        tay
        lda screenRowOffsets,y
        sta screenCursorOffset
        iny
        lda screenRowOffsets,y
        sta screenCursorOffset+1
        rts
    @lastLine:
        ; _screenY >= SCREEN_HEIGHT-1
        jsr screenScrollOneLine
        jmp screenMoveCursorLastLineFirstColumn
.endproc

; clobbers: a, status
.proc screenMoveCursorRight
        lda screenCursorX
        cmp #(SCREEN_WIDTH-1)
        bcc @screenXNotLastColumn
        ; _screenX >= SCREEN_WIDTH-1
        lda screenCursorY
        cmp #(SCREEN_HEIGHT-1)
        bcs @lastLineLastColumn
        ; _screenY < SCREEN_HEIGHT-1
        lda #$00
        sta screenCursorX
        inc screenCursorY
        jmp @incScreenOffset
    @screenXNotLastColumn:
        inc screenCursorX
    @incScreenOffset:
        inc screenCursorOffset
        bne @end
        inc screenCursorOffset+1
    @end:
        rts
    @lastLineLastColumn:
        jsr screenScrollOneLine
        jmp screenMoveCursorLastLineFirstColumn
.endproc

; clobbers: a, status
.proc screenMoveCursorUp
    lda screenCursorY
    beq @end
    ; _screenY > 0
    dec screenCursorY
    lda screenCursorOffset
    sec
    sbc #SCREEN_WIDTH
    sta screenCursorOffset
    bcs @end
    dec screenCursorOffset+1
@end:
    rts
.endproc

; clobbers: nothing
.proc screenNoOp
    rts
.endproc

; input:
;   a: char to put
; clobbers: a, y, status, ptr1
.proc screenPutChar
        tay
        and #$60
        beq @controlChar
        tya
        jmp screenPutRegularChar
    @controlChar:
        tya
        cmp #$80
        bcc @controlCharSquashed
        eor #$a0
    @controlCharSquashed:
; self-modifying code
        asl
        tay
        lda screenControlChars,y
        sta @jump+1
        iny
        lda screenControlChars,y
        sta @jump+2
    @jump:
        jmp $ffff
.endproc

; clobbers: a, status
.proc screenPutControlCharBlack
    lda #COLOR_BLACK
    sta screenCursorColor
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharBlue
    lda #COLOR_BLUE
    sta screenCursorColor
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharBrown
    lda #COLOR_BROWN
    sta screenCursorColor
    rts
.endproc

; clobbers: a, y, status, ptr1
.proc screenPutControlCharClear
    .assert (SCREEN_HEIGHT * SCREEN_WIDTH = 1000), error, "screen size is not supported"
    .macro clearMacro address, value
        loadPointerY ptr1, address
        lda #value
        ldy #$00
        jsr memset
        inc ptr1+1
        ldy #$00
        jsr memset
        inc ptr1+1
        ldy #$00
        jsr memset
        inc ptr1+1
        ldy #(SCREEN_HEIGHT*SCREEN_WIDTH-3*256)
        jsr memset
    .endmacro
    clearMacro SCREEN_MEMORY, SCREEN_CODE_SPACE
    clearMacro COLOR_RAM, TERMINAL_BACKGROUND_COLOR
    jmp screenMoveCursorHome
.endproc

; clobbers: a, status
.proc screenPutControlCharCyan
    lda #COLOR_CYAN
    sta screenCursorColor
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharDarkGray
    lda #COLOR_DARK_GRAY
    sta screenCursorColor
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharGray
    lda #COLOR_GRAY
    sta screenCursorColor
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharGreen
    lda #COLOR_GREEN
    sta screenCursorColor
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharLightBlue
    lda #COLOR_LIGHT_BLUE
    sta screenCursorColor
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharLightGray
    lda #COLOR_LIGHT_GRAY
    sta screenCursorColor
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharLightGreen
    lda #COLOR_LIGHT_GREEN
    sta screenCursorColor
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharLightRed
    lda #COLOR_LIGHT_RED
    sta screenCursorColor
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharLowerCase
    lda #PETSCII_LOWER_CASE
    kernalChrOut
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharOrange
    lda #COLOR_ORANGE
    sta screenCursorColor
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharPurple
    lda #COLOR_PURPLE
    sta screenCursorColor
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharRed
    lda #COLOR_RED
    sta screenCursorColor
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharReverseOff
    lda #$00
    sta screenCursorReverse
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharReverseOn
    lda #SCREEN_CODE_REVERSE
    sta screenCursorReverse
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharUpperCase
    lda #PETSCII_UPPER_CASE
    kernalChrOut
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharWhite
    lda #COLOR_WHITE
    sta screenCursorColor
    rts
.endproc

; clobbers: a, status
.proc screenPutControlCharYellow
    lda #COLOR_YELLOW
    sta screenCursorColor
    rts
.endproc

; input:
;   a: the byte to
; clobbers: a, x, y, status
.proc screenPutHexByte
    tax
    lsr
    lsr
    lsr
    lsr
    tay
    lda screenHexCodes,y
    jsr screenPutRegularChar
    txa
    and #$0f
    tay
    lda screenHexCodes,y
    jsr screenPutRegularChar
    rts
.endproc

; input:
;   a: char to put, a & 0x60 != 0 must be true
; clobbers: a, (x), y, status, (ptr1)
.proc screenPutRegularChar
        cmp #$60
        bcc @below60
        cmp #$c0
        bcs @atLeastC0
        cmp #$80
        bcc @below80AtLeast60
        eor #$c0;
        jmp @putChar
    @below80AtLeast60:
        and #$df;
        jmp @putChar
    @atLeastC0:
        cmp #$ff
        beq @exceptionFf
        and #$7f
        jmp @putChar
    @exceptionFf:
        lda #$5e
        jmp @putChar
    @below60:
        and #$bf
    @putChar:
        .assert (<COLOR_RAM = 0), error, "color ram is not aligned"
        .assert (<SCREEN_MEMORY = 0), error, "screen memory is not aligned"

; self-modifying code
        ora screenCursorReverse         ; 4 / 3
        tay                             ; 2
        clc                             ; 2
        lda screenCursorOffset          ; 4 / 3
        sta @storeColor+1               ; 4
        sta @storeScreenCode+1          ; 4
        lda screenCursorOffset+1        ; 4 / 3
        adc #>COLOR_RAM                 ; 2
        sta @storeColor+2               ; 4
        adc #>(SCREEN_MEMORY-COLOR_RAM) ; 2
        sta @storeScreenCode+2          ; 4
        lda screenCursorColor           ; 4 / 3
    @storeColor:
        sta $ffff                       ; 4
    @storeScreenCode:
        sty $ffff                       ; 4
                                        ; 48 / 44 - cycles absolute/zero-page

; needs ptr1 in zero-page
;        clc                 ; 2
;        ldy screenCursorOffset   ; 4 / 3
;        sty ptr1                 ; 3
;        ldy #$00                 ; 2
;        tax                      ; 2
;        lda screenCursorOffset+1 ; 4 / 3
;        adc #>COLOR_RAM          ; 2
;        sta ptr1+1               ; 4
;        lda screenCursorColor    ; 4 / 3
;        sta (ptr1),y             ; 6
;        lda screenCursorOffset+1 ; 4 / 3
;        adc #>SCREEN_MEMORY      ; 2
;        sta ptr1+1               ; 4
;        txa                      ; 2
;        ora screenCursorReverse  ; 4 / 3
;        sta (ptr1),y             ; 6
;                                 ; 55 / 50 - cycles absolute/zero-page

        jmp screenMoveCursorRight
.endproc

; input:
;   ptr2: pointer to the start of a zero terminated string
;         string must fit in a page
; clobbers: a, y, status, ptr1
.proc screenPutString
        ldy #$00
        sty screenPutStringIndex
    @loop:
        ldy screenPutStringIndex
        lda (ptr2),y
        beq @end
        jsr screenPutChar
        inc screenPutStringIndex
        jmp @loop
    @end:
        rts
.endproc

; clobbers: a, y, status, ptr1, ptr2
.proc screenScrollOneLine
    .assert (SCREEN_HEIGHT * SCREEN_WIDTH = 1000), error, "screen size is not supported"
    .assert (<COLOR_RAM = 0), error, "color ram is not aligned"
    .assert (<SCREEN_MEMORY = 0), error, "screen memory is not aligned"

    ; scroll whole screen up by one line
    loadPointerY ptr1, SCREEN_MEMORY
    loadPointerY ptr2, COLOR_RAM
    loadPointerY ptr3, (SCREEN_MEMORY+SCREEN_WIDTH)
    loadPointerY ptr4, (COLOR_RAM+SCREEN_WIDTH)
    ldy #$00
    jsr memcpyDoubleAscending
    inc ptr1+1
    inc ptr2+1
    inc ptr3+1
    inc ptr4+1
    ldy #$00
    jsr memcpyDoubleAscending
    inc ptr1+1
    inc ptr2+1
    inc ptr3+1
    inc ptr4+1
    ldy #$00
    jsr memcpyDoubleAscending
    loadPointerY ptr1, (SCREEN_MEMORY+SCREEN_WIDTH*(SCREEN_HEIGHT-1)-$100)
    loadPointerY ptr2, (COLOR_RAM+SCREEN_WIDTH*(SCREEN_HEIGHT-1)-$100)
    loadPointerY ptr3, (SCREEN_MEMORY+SCREEN_WIDTH*SCREEN_HEIGHT-$100)
    loadPointerY ptr4, (COLOR_RAM+SCREEN_WIDTH*SCREEN_HEIGHT-$100)
    ldy #(4*256-SCREEN_WIDTH*(SCREEN_HEIGHT-1))
    jsr memcpyDoubleAscending

    ; clear last line
    loadPointerY ptr1, (SCREEN_MEMORY+SCREEN_WIDTH*(SCREEN_HEIGHT-1))
    lda #SCREEN_CODE_SPACE
    ldy #SCREEN_WIDTH
    jsr memset
    loadPointerY ptr1, (COLOR_RAM+SCREEN_WIDTH*(SCREEN_HEIGHT-1))
    lda screenCursorColor
    ldy #SCREEN_WIDTH
    jsr memset
    
    rts
.endproc
