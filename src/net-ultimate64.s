.include "banana-term.inc"

;CI_CHECK_BYTE_AVAILABLE = 1

CI_ID = $c9

CI_REG_C = $df1c
CI_REG_D = $df1d
CI_REG_E = $df1e
CI_REG_F = $df1f

DOS_IDENTIFY_LENGTH = 2

NET_IDENTIFY_LENGTH         = 2
NET_OPEN_TCP_LENGTH         = 4
NET_READ_SOCKET_BUFFER_SIZE = 255
NET_READ_SOCKET_LENGTH      = 5
NET_WRITE_SOCKET_LENGTH     = 4

.bss

    executeStatusCode:
        .res 1

    netReadSocketBuffer:
        .res NET_READ_SOCKET_BUFFER_SIZE-1
    netReadSocketBufferSize:
        .res 1

.data

    netOpenTcp:
        .byte $03, $07
    netOpenTcpPort:
        .res 2 ; ##ULTIMATE64_PORT
    netOpenTcpAddress:
        .res 256-NET_OPEN_TCP_LENGTH ; ##ULTIMATE64_ADDRESS

    netReadSocket:
        .byte $03, $10
    netReadSocketHandle:
        .res 1
        .word NET_READ_SOCKET_BUFFER_SIZE

    netWriteSocket:
        .byte $03, $11
    netWriteSocketHandle:
        .res 1
    netWriteSocketData:
        .res 1

.rodata

    dosIdentify:
        .byte $01, $01

    executeNoFirstStatusByte:
        .byte "Command result doesn't have the 1st status byte.", PETSCII_RETURN
        .byte "Status register: "
        .byte $00

    executeNoSecondStatusByte:
        .byte "Command result doesn't have the 2nd status byte.", PETSCII_RETURN
        .byte "Status register: "
        .byte $00

    executeNotDataLast:
        .byte "Command interface state is not data last.", PETSCII_RETURN
        .byte "Status register: "
        .byte $00

    identifyError:
        .byte "Ultimate command interface identification error.", PETSCII_RETURN
        .byte $00

    idError:
        .byte "Ultimate command interface not found.", PETSCII_RETURN
        .byte "Id register: "
        .byte $00

    netIdentify:
        .byte $03, $01

    netOpenTcpError:
        .byte "Open tcp failed.", PETSCII_RETURN
        .byte $00

    netOpenTcpMessage1:
        .byte "Opening tcp to "
        .byte $00

    netOpenTcpMessage2:
        .byte ":$"
        .byte $00

    .if .defined(CI_CHECK_BYTE_AVAILABLE)
        netOpenTcpNoData:
            .byte "Open tcp has no data.", PETSCII_RETURN
            .byte $00
    .endif

    netOpenTcpOk:
        .byte "Tcp is open.", PETSCII_RETURN
        .byte $00

    netReadSocketDisconnected:
        .byte "Disconncted on read socket.", PETSCII_RETURN
        .byte $00

    netReadSocketError:
        .byte "Read socket failed.", PETSCII_RETURN
        .byte $00

    .if .defined(CI_CHECK_BYTE_AVAILABLE)
        netReadSocketNoData:
            .byte "Read socket has no data.", PETSCII_RETURN
            .byte $00
    .endif

    netWriteSocketDisconnected:
        .byte "Disconnected on write socket.", PETSCII_RETURN
        .byte $00

    netWriteSocketError:
        .byte "Write socket failed.", PETSCII_RETURN
        .byte $00

    .if .defined(CI_CHECK_BYTE_AVAILABLE)
        netWriteSocketNoData:
            .byte "Write socket has no data.", PETSCII_RETURN
            .byte $00
    .endif

.code

; input:
;   x: length of command, 0 == 256
;   ptr1: command, must be zero terminated, and no more than 256 bytes
; output:
;   a: status code
; clobbers: a, x, y, status
.proc ciExecute
        ; clear all control bits
        lda #$00
        sta CI_REG_C

        ; check state idle, no error, no abort, no command busy
        lda CI_REG_C
        tay
        and #$3d ; state + error + abort_p + cmd_busy
        beq @stateOk
        tya
        and #$31
        beq @afterAbort
        ; abort
        lda #$04
        sta CI_REG_C
    @afterAbort:
        tya
        and #$08
        beq @afterClearError
        ; clear error
        lda #$08
        sta CI_REG_C
    @afterClearError:
        lda CI_REG_C
        and #$3d ; state + error + abort_p + cmd_busy
        bne @afterClearError
    @stateOk:
        ; state idle
        ; no error
        ; no abort
        ; no command busy

        ; send command
        ldy #$00
    @sendCommandLoop:
        lda (ptr1),y
        sta CI_REG_D
        iny
        dex
        bne @sendCommandLoop
        ; push command
        lda #$01
        sta CI_REG_C

    @waitForStateNotBusy:
        lda CI_REG_C
        and #$30
        cmp #$10
        beq @waitForStateNotBusy
        ; state not busy

        ; check state data last
        lda CI_REG_C
        tax
        and #$30
        cmp #$20
        beq @stateDataLast
        txa
        loadPointerY ptr2, executeNotDataLast
        jmp showErrorAndHalt
    @stateDataLast:

        ; check first status code byte
        .if .defined(CI_CHECK_BYTE_AVAILABLE)
            lda CI_REG_C
            tax
            and #$40
            bne @statusFirstByte
            txa
            loadPointerY ptr2, executeNoFirstStatusByte
            jmp showErrorAndHalt
        .endif
    @statusFirstByte:
        lda CI_REG_F
        jsr hexToNumber
        asl
        asl
        asl
        asl
        sta executeStatusCode
        ; check second status code byte
        .if .defined(CI_CHECK_BYTE_AVAILABLE)
            lda CI_REG_C
            tax
            and #$40
            bne @statusSecondByte
            txa
            loadPointerY ptr2, executeNoSecondStatusByte
            jmp showErrorAndHalt
        .endif
    @statusSecondByte:
        lda CI_REG_F
        jsr hexToNumber
        clc
        adc executeStatusCode
        rts
.endproc

; input:
;   x: length of the identofy command, 0 == 256
;   ptr1: command, must be zero terminated, and no more than 256 bytes
; output:
;   a: status code
; clobbers: a, x, y, status
.proc ciIdentify
        jsr ciExecute
        cmp #$00
        beq @printData
        loadPointerY ptr2, identifyError
        jmp ciShowErrorAndHalt
    @printData:
        lda CI_REG_C
        and #$80
        beq @printDataEnd
        lda CI_REG_E
        jsr screenPutChar
        jmp @printData
    @printDataEnd:
        jsr screenMoveCursorNextLine
        ; acknowledge
        lda #$02
        sta CI_REG_C
        rts
.endproc

; input
;   a: status code
;   ptr2: message
; never returns
.proc ciShowDisconnectedAndHalt
    ldy #TERMINAL_BORDER_COLOR_DISCONNECTED
    jmp ciShowMessageAndHalt
.endproc

; input
;   a: status code
;   ptr2: message
; never returns
.proc ciShowErrorAndHalt
    ldy #TERMINAL_BORDER_COLOR_ERROR
    jmp ciShowMessageAndHalt
.endproc

; input
;   a: status code
;   y: border color
;   ptr2: message
; never returns
.proc ciShowMessageAndHalt
        pha
        lda ptr2
        pha
        lda ptr2+1
        pha
        tya
        jsr resetScreen
        pla
        sta ptr2+1
        pla
        sta ptr2
        jsr screenPutString
        pla
        jsr screenPutHexByte
    @printStatus:
        lda CI_REG_C
        and #$40
        beq @printStatusEnd
        lda CI_REG_F
        jsr screenPutChar
        jmp @printStatus
    @printStatusEnd:
        ; acknowledge
        lda #$02
        sta CI_REG_C
    @loop:
        jmp @loop
.endproc

; input:
;   a: 0-9a-f
; clobbers: status
.proc hexToNumber
        cmp #$3a ; ':'
        bcs @letter
        ; digit, $30-$39, '0'-'9'
        and #$0f
        rts
    @letter:
        cmp #$47 ; 'g'
        bcs @uppercase
        ; lowercase, $41-$46, 'a'-'f', carry clear
        adc #$c9
        rts
    @uppercase:
        ; $61-$66, 'A'-'F', carry set
        sbc #$57
        rts
.endproc

; output:
;   c flag: set == got data
;   netGetData: data
.proc netGet
        ; check buffer
        ldy netReadSocketBufferSize
        beq @bufferEmpty
        dey
        sty netReadSocketBufferSize
        loadPointerX ptr1, netReadSocketBuffer
        lda (ptr1),y
        sta netGetData
        sec
        rts
    @bufferEmpty:
        ; read socket
        ldx #NET_READ_SOCKET_LENGTH
        loadPointerY ptr1, netReadSocket
        jsr ciExecute
        cmp #$00
        bne @readError
        ; check payload size lsb
        .if .defined(CI_CHECK_BYTE_AVAILABLE)
            lda CI_REG_C
            and #$80
            beq @noData
        .endif
        ldy CI_REG_E
        beq @noPayload
        ; ignore payload size hsb
        .if .defined(CI_CHECK_BYTE_AVAILABLE)
            lda CI_REG_C
            and #$80
            beq @noData
        .endif
        ldx CI_REG_E

        ; prepare to return first byte
        .if .defined(CI_CHECK_BYTE_AVAILABLE)
            lda CI_REG_C
            and #$80
            beq @noData
        .endif
        lda CI_REG_E
        sta netGetData

        ; read reast of the bytes to the buffer
        dey
        beq @readLoopEnd
        sty netReadSocketBufferSize
        loadPointerX ptr1, netReadSocketBuffer
        tya
        tax
        dey
    @readLoop:
        .if .defined(CI_CHECK_BYTE_AVAILABLE)
            lda CI_REG_C
            and #$80
            beq @noData
        .endif
        lda CI_REG_E
        sta (ptr1),y
        dey
        dex
        bne @readLoop
    @readLoopEnd:
        ; acknowledge
        lda #$02
        sta CI_REG_C
        ; netGetData already filled
        sec
        rts
    @noPayload:
        clc
        rts
    .if .defined(CI_CHECK_BYTE_AVAILABLE)
        @noData:
            loadPointerY ptr2, netReadSocketNoData
            jmp showErrorAndHalt
    .endif
    @readError:
        cmp #$02
        beq @noPayload
        cmp #$01 ; "01,connection closed by host"
        beq @disconnected
        loadPointerY ptr2, netReadSocketError
        jmp ciShowErrorAndHalt
    @disconnected:
        loadPointerY ptr2, netReadSocketDisconnected
        jmp ciShowDisconnectedAndHalt
.endproc

; input:
;   a, x: pointer to driver, ignored
.proc netOpen
        ; check command interface id
        lda CI_REG_D
        cmp #CI_ID
        beq @hasId
        loadPointerY ptr2, idError
        jmp showErrorAndHalt
    @hasId:

        ; print dos and net identification
        ldx #DOS_IDENTIFY_LENGTH
        loadPointerY ptr1, dosIdentify
        jsr ciIdentify
        ldx #NET_IDENTIFY_LENGTH
        loadPointerY ptr1, netIdentify
        jsr ciIdentify

        ; print open tcp message
        loadPointerY ptr2, netOpenTcpMessage1
        jsr screenPutString
        loadPointerY ptr2, netOpenTcpAddress
        jsr screenPutString
        loadPointerY ptr2, netOpenTcpMessage2
        jsr screenPutString
        lda netOpenTcpPort+1
        jsr screenPutHexByte
        lda netOpenTcpPort
        jsr screenPutHexByte
        jsr screenMoveCursorNextLine
        ; open tcp connection
        ; count command length
        loadPointerY ptr1, netOpenTcp
        ldy #NET_OPEN_TCP_LENGTH
    @countOpenCommandLength:
        lda (ptr1),y
        beq @commandLengthCounted
        iny
        jmp @countOpenCommandLength
    @commandLengthCounted:
        iny
        tya
        tax
        loadPointerY ptr1, netOpenTcp
        jsr ciExecute
        cmp #$00
        beq @openSuccess
        loadPointerY ptr2, netOpenTcpError
        jmp ciShowErrorAndHalt
    @openSuccess:
        .if .defined(CI_CHECK_BYTE_AVAILABLE)
            lda CI_REG_C
            and #$80
            bne @openHasData
            loadPointerY ptr2, netOpenTcpNoData
            jmp showErrorAndHalt
        .endif
    @openHasData:
        lda CI_REG_E
        sta netReadSocketHandle
        sta netWriteSocketHandle
        ; acknowledge
        lda #$02
        sta CI_REG_C
        loadPointerY ptr2, netOpenTcpOk
        jsr screenPutString

        ; set read buffer empty
        lda #$00
        sta netReadSocketBufferSize

        rts
.endproc

; input:
;   a: byte to send
.proc netPut
        sta netWriteSocketData
        ldx #NET_WRITE_SOCKET_LENGTH
        loadPointerY ptr1, netWriteSocket
        jsr ciExecute
        cmp #$00
        bne @writeError
        ; check response
        .if .defined(CI_CHECK_BYTE_AVAILABLE)
            lda CI_REG_C
            and #$80
            beq @noData
        .endif
        ldx CI_REG_E
        ; acknowledge
        lda #$02
        sta CI_REG_C
        ; check actual length of write
        cpx #$01
        beq @end
        ; not sent, always returns $01 though
        .if .defined(BELL_BORDER_COLOR) .or .defined(BELL_SOUND_VOLUME) .or .defined(BELL_KERNAL)
            jsr interruptBell
        .endif
    @end:
        rts
    .if .defined(CI_CHECK_BYTE_AVAILABLE)
        @noData:
            loadPointerY ptr2, netWriteSocketNoData
            jmp showErrorAndHalt
    .endif
    @writeError:
        cmp #$12 ; "12,send error: 104"
        beq @disconnected
        loadPointerY ptr2, netWriteSocketError
        jmp ciShowErrorAndHalt
    @disconnected:
        loadPointerY ptr2, netWriteSocketDisconnected
        jmp ciShowDisconnectedAndHalt
.endproc
