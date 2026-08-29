.include "banana-term.inc"

.bss

.if .defined(BELL_BORDER_COLOR) .or .defined(BELL_SOUND_VOLUME)
    interruptAcknowledgeInterrupt: .res 1
.endif

.data

.if .defined(BELL_BORDER_COLOR) .or .defined(BELL_SOUND_VOLUME)
    interruptBellRemainingTime: .byte 0
.endif

.code

.if .defined(BELL_BORDER_COLOR) .or .defined(BELL_SOUND_VOLUME)
    .macro interruptStopBellMacro
        .if .defined(BELL_BORDER_COLOR)
            lda #TERMINAL_BORDER_COLOR
            sta SCREEN_BORDER_COLOR
        .endif
        .if .defined(BELL_SOUND_VOLUME)
            .if .defined(__C64__) .or .defined(__C128__)
                lda #$00
                sta SID_Ctl1
                sta SID_Amp
            .elseif .defined(__PLUS4__)
                lda #$00
                sta TED_SCR
            .else
                .assert 0, error, "target not supported"
            .endif
        .endif
    .endmac
.endif

.if .defined(BELL_BORDER_COLOR) .or .defined(BELL_SOUND_VOLUME) .or .defined(BELL_KERNAL)
    .proc interruptBell
        .if .defined(BELL_BORDER_COLOR) .or .defined(BELL_SOUND_VOLUME)
            sei
            lda #BELL_RASTER_INTERRUPTS
            sta interruptBellRemainingTime
            .if .defined(BELL_BORDER_COLOR)
                lda #BELL_BORDER_COLOR
                sta SCREEN_BORDER_COLOR
            .endif
            .if .defined(BELL_SOUND_VOLUME)
                .if .defined(__C64__) .or .defined(__C128__)
                    lda #<BELL_SOUND_FREQUENCY
                    sta SID_S1Lo
                    lda #>BELL_SOUND_FREQUENCY
                    sta SID_S1Hi
                    lda #$00
                    sta SID_PB1Lo
                    lda #$08
                    sta SID_PB1Hi
                    lda #$00
                    sta SID_AD1
                    lda #$f0
                    sta SID_SUR1
                    lda #BELL_SOUND_VOLUME
                    sta SID_Amp
                    lda #$41
                    sta SID_Ctl1
                .elseif .defined(__PLUS4__)
                    lda #<BELL_SOUND_FREQUENCY
                    sta TED_V1FRQLO
                    lda TED_BMPADDR
                    and #$fc
                    ora #>BELL_SOUND_FREQUENCY
                    sta TED_BMPADDR
                    lda #$10|BELL_SOUND_VOLUME
                    sta TED_SCR
                .else
                    .assert 0, error, "target not supported"
                .endif
            .endif
            cli
        .endif
        .if .defined(BELL_KERNAL)
            .if .defined(__C128__)
                lda #PETSCII_BELL
                kernalChrOut
            .else
                .assert 0, error, "kernal bell is not supported"
            .endif
        .endif
        rts
    .endproc
.endif

.if .defined(BELL_BORDER_COLOR) .or .defined(BELL_SOUND_VOLUME)
    .proc interruptHandler
            ; check raster interrupt flag
            .if .defined(__C64__) .or .defined(__C128__)
                    lda #$01
                    bit VIC_IRR
                    beq interruptSaveJump
                    lda interruptAcknowledgeInterrupt
                    beq @rasterInterrupt
                    lda #$01
                    sta VIC_IRR
            .elseif .defined(__PLUS4__)
                    lda #$02
                    bit TED_IRR
                    beq interruptSaveJump
                    lda interruptAcknowledgeInterrupt
                    beq @rasterInterrupt
                    lda #$02
                    sta TED_IRR
            .else
                .assert 0, error, "target not supported"
            .endif
        @rasterInterrupt:
            ; raster interrupt
            lda interruptBellRemainingTime
            beq interruptSaveJump
            dec interruptBellRemainingTime
            bne interruptSaveJump
            ; shut off bell
            interruptStopBellMacro
        interruptSaveJump:
            jmp $ffff
    .endproc

    ; clobbers: a, status
    .proc interruptSetup
            ; self-modifying code
            sei
            lda IRQVec
            sta interruptHandler::interruptSaveJump+1
            lda IRQVec+1
            sta interruptHandler::interruptSaveJump+2
            lda #<interruptHandler
            sta IRQVec
            lda #>interruptHandler
            sta IRQVec+1
            .if .defined(__C64__) .or .defined(__C128__)
                lda VIC_IMR
                and #$01
                eor #$01
                sta interruptAcknowledgeInterrupt
                beq @interruptSetUp
                lda #$00
                sta VIC_HLINE
                lda VIC_CTRL1
                and #$7f
                sta VIC_CTRL1
                lda VIC_IMR
                ORA #$01
                sta VIC_IMR
            .elseif .defined(__PLUS4__)
                lda TED_IMR
                and #$02
                eor #$02
                sta interruptAcknowledgeInterrupt
                beq @interruptSetUp
                lda #$00
                sta TED_HLINE
                lda TED_IMR
                and #$fe
                ora #$02
                sta TED_IMR
            .else
                .assert 0, error, "target not supported"
            .endif
        @interruptSetUp:
            cli
            rts
    .endproc
.endif

.if .defined(BELL_BORDER_COLOR) .or .defined(BELL_SOUND_VOLUME)
    .proc interruptStopBell
        sei
        lda #$00
        sta interruptBellRemainingTime
        cli
        interruptStopBellMacro
        rts
    .endproc
.endif
