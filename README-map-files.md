# Banana-term map files

There are map files for the vanilla release PRGs that shows the location of the compile-time parameters. These parameters can be modified by a hex-editor.

## Hardware color codes

Parameters:

- BELL_BORDER_COLOR
- COLOR_BLACK
- COLOR_WHITE
- COLOR_RED
 -COLOR_CYAN
- COLOR_PURPLE
- COLOR_GREEN
- COLOR_BLUE
- COLOR_YELLOW
- COLOR_ORANGE
- COLOR_BROWN
- COLOR_LIGHT_RED
- COLOR_DARK_GRAY
- COLOR_GRAY
- COLOR_LIGHT_GREEN
- COLOR_LIGHT_BLUE
- COLOR_LIGHT_GRAY
- TERMINAL_BACKGROUND_COLOR
- TERMINAL_BORDER_COLOR
- TERMINAL_BORDER_COLOR_DISCONNECTED
- TERMINAL_BORDER_COLOR_ERROR
- TERMINAL_TEXT_COLOR

Valid values for the C64, and the C128 are from 0 to 15:

- $0: black
- $1: white
- $2: red
- $3: cyan
- $4: purple
- $5: green
- $6: blue
- $7: yellow
- $8: orange
- $9: brown
- $a: light red
- $b: dark gray
- $c: gray
- $d: light green
- $e: light blue
- $f: light gray

Valid values for the C64, and the C128 are from 0 to 127. The upper 3 bits are the luminance, where 0 is the darkest. The lower 4 bits are the color:

- $0: black
- $1: white
- $2: red
- $3: cyan
- $4: purple
- $5: green
- $6: blue
- $7: yellow
- $8: orange
- $9: brown
- $a: yellow-green
- $b: pink
- $c: blue-green
- $d: light blue
- $e: dark blue
- $f: light green

## PETSCII color codes

Parameters:

- TERMINAL_BANANA_COLOR_PETSCII
- TERMINAL_TEXT_COLOR_PETSCII

Valid values are the PETSCII color codes:

- $05: white
- $1c: red
- $1e: green
- $1f: blue
- $81: orange
- $90: black
- $95: brown
- $96: C64,C128: light red; Plus/4: yellow-green
- $97: C64,C128: dark gray; Plus/4: pink
- $98: C64,C128: gray; Plus/4: blue-green
- $99: C64,C128: light green; Plus/4: light blue
- $9a: C64,C128: light blue; Plus/4: dark blue
- $9b: C64,C128: light gray; Plus/4: light green
- $9c: purple
- $9e: yellow
- $9f: cyan

## BELL_RASTER_INTERRUPTS
The duration of the bell in the number of raster interrupts. Valid values are from 1 to 255.

- The C64 and the C128 have one raster interrupt per frame.
- The Plus/4 has two raster interrupts per frame.
- NTSC machines have 60 frames per second.
- PAL machines have 50 frames per second.

## BELL_SOUND_FREQUENCY

The bell sound is a square wave with 50% duty cycle.

- The C64 and the C128 have valid values from 0 to 65535.
- The NTSC C64 and C128 formula is frq[Hz]*2^24/1022727.
- The PAL C64 and C128 formula is frq[Hz]*2^24/985248.
- The plus/4 has valid values from 0 to 1023.
- The NTSC Plus/4 formula is 1023-(111860.78125/frq[Hz]).
- The PAL Plus/4 formula is 1023-(110840.46875/frq[Hz]).

## BELL_SOUND_VOLUME

Zero is the most quiet.

- The C64 and the C128 have valid values from 0 to 15.
- The Plus/4 has valid values from 0 to 8.

## MODEM_COMMANDS

This is the buffer for the autodial commands. The buffer is 256 bytes. The string must be zero terminated. Don't forget to include RETURNs ($0d).

## SERIAL_BAUD

The cc65 serial driver defines valid values, they are in `ser-kernel.inc`.

- $00: 45.5
- $01: 50
- $02: 75
- $03: 110
- $04: 134.5
- $05: 150
- $06: 300
- $07: 600
- $08: 1200
- $09: 1800
- $0a: 2400
- $0b: 3600
- $0c: 4800
- $0d: 7200
- $0e: 9600
- $0f: 19200
- $10: 38400
- $11: 57600
- $12: 115200
- $13: 230400
- $14: 31250
- $15: 62500
- $16: 56.875

## Ultimate-64 mode address

- ULTIMATE64_ADDRESS: The ip address or host name of the server. The buffer is 252 bytes. The string must be zero terminated.
- ULTIMATE64_PORT: The TCP port of the server. The first byte is the least significant byte, the second is the most significant.