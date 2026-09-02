.include "cbm_kernal.inc"
.include "ser-error.inc"
.include "ser-kernel.inc"
.include "zeropage.inc"

.if .defined(__C128__)
    .include "banana-c128.inc"
.elseif .defined(__C64__)
    .include "banana-c64.inc"
.elseif .defined(__PLUS4__)
    .include "banana-plus4.inc"
.else
    .assert 0, error, "target not supported"
.endif

BELL_BORDER_COLOR = COLOR_YELLOW ; ##BELL_BORDER_COLOR
BELL_RASTER_INTERRUPTS = 3*RASTER_INTERRUPTS_PER_SCREEN ; ##BELL_RASTER_INTERRUPTS

;CURSOR_SCREEN_CODE = $66 ; ##CURSOR_SCREEN_CODE
CURSOR_SHOW = 1 ; ##CURSOR_SHOW

PETSCII_WHITE = $05
PETSCII_BELL = $07
PETSCII_RETURN = $0d
PETSCII_LOWER_CASE = $0e
PETSCII_RUN = $83
PETSCII_FLASH_OFF = $84
PETSCII_F1 = $85
PETSCII_F3 = $86
PETSCII_F5 = $87
PETSCII_F7 = $88
PETSCII_F2 = $89
PETSCII_F4 = $8a
PETSCII_F6 = $8b
PETSCII_F8 = $8c
PETSCII_UPPER_CASE = $8e
PETSCII_CLEAR = $93
PETSCII_YELLOW = $9e

SCREEN_CODE_REVERSE = $80
SCREEN_CODE_SPACE = $20

SCREEN_HEIGHT = 25
SCREEN_WIDTH = 40

TERMINAL_BACKGROUND_COLOR          = COLOR_BLACK ; ##TERMINAL_BACKGROUND_COLOR
TERMINAL_BANANA_COLOR_PETSCII      = PETSCII_YELLOW ; ##TERMINAL_BANANA_COLOR_PETSCII
TERMINAL_BORDER_COLOR              = COLOR_BLACK ; ##TERMINAL_BORDER_COLOR_ERROR
TERMINAL_BORDER_COLOR_DISCONNECTED = COLOR_PURPLE ; ##TERMINAL_BORDER_COLOR_DISCONNECTED
TERMINAL_BORDER_COLOR_ERROR        = COLOR_RED ; ##TERMINAL_BORDER_COLOR_ERROR
TERMINAL_TEXT_COLOR                = COLOR_WHITE ; ##TERMINAL_TEXT_COLOR
TERMINAL_TEXT_COLOR_PETSCII        = PETSCII_WHITE ; ##TERMINAL_TEXT_COLOR_PETSCII

.if .defined(BELL_KERNAL) .and .defined(BELL_SOUND_VOLUME)
    .assert 0, error, "cannot have both kernal and sound bells"
.endif
.if .defined(BELL_SOUND_FREQUENCY)
    .if .defined(__C128__) .or .defined(__C64__)
        .if BELL_SOUND_FREQUENCY<0 .or BELL_SOUND_FREQUENCY>=65536
            .assert 0, error, "bell sound frequency must be in the range [0, 1023]"
        .endif
    .elseif .defined(__PLUS4__)
        .if BELL_SOUND_FREQUENCY<0 .or BELL_SOUND_FREQUENCY>=1024
            .assert 0, error, "bell sound frequency must be in the range [0, 1023]"
        .endif
    .else
        .assert 0, error, "target not supported"
    .endif
.endif
.if .defined(BELL_SOUND_VOLUME)
    .if .defined(__C128__) .or .defined(__C64__)
        .if BELL_SOUND_VOLUME<0 .or BELL_SOUND_VOLUME>=16
            .assert 0, error, "bell sound volume must be in the range [0, 15]"
        .endif
    .elseif .defined(__PLUS4__)
        .if BELL_SOUND_VOLUME<0 .or BELL_SOUND_VOLUME>=9
            .assert 0, error, "bell sound volume must be in the range [0, 8]"
        .endif
    .else
        .assert 0, error, "target not supported"
    .endif
.endif

; clobbers: y
.macro loadPointerY pointer, address
    ldy #<address
    sty pointer
    ldy #>address
    sty pointer+1
.endmacro

.if .defined(BELL_BORDER_COLOR) .or .defined(BELL_SOUND_VOLUME) .or .defined(BELL_KERNAL)
    .global interruptBell
.endif
.if .defined(BELL_BORDER_COLOR) .or .defined(BELL_SOUND_VOLUME)
    .global interruptSetup
    .global interruptStopBell
.endif

.global _mainAssembly

.global memcpyDoubleAscending
.global memset

.global screenCursorColor
.if .defined(CURSOR_SHOW)
    .global screenCursorOff
    .global screenCursorOn
.endif
.global screenCursorReverse
.global screenMoveCursorNextLine
.global screenPutChar
.global screenPutControlCharLowerCase
.global screenPutHexByte
.global screenPutString
