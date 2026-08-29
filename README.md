Banana-term is a PETSCII terminal program for the Commodore 64, Plus/4, and 128. The indented use-case is everyday one-click use in emulators. Feedback on real machines would be nice.

Features:
- Supports the Commodore 64 and 128 with a Swiftlink cartridge. This includes the Ultimate 64 and the Commodore 64 Ultimate machines. The ACIA address must be $DE00.
- Supports the Commodore Plus/4.
- Only 40 columns mode.
- There's no phonebook. The program can be compiled to autodial a specific number. Alternatively it can be used with a direct link or by manual dialing.
- There's no support for downloading or uploading files.
- The program can be compiled to use a custom color scheme. The Plus/4 version comes with 3 color schemes, one with the colors of the Plus/4 basic editor, and two attempts at mimicking the colors of the VIC-II chip.
- The program can be compiled to show a cursor with a fixed character, to show a cursor as inverted characters on the screen, or not to show a cursor. The cursor doesn't blink.
- The program uses the maximum baud rates by default, which is 38400 for the C128 and the C64, and 19200 for the Plus/4. The program also supports by recompilation baud rates 300, 600, 1200, 2400, 4800, 9600, 19200, 38400, and 57600.
- The serial driver doesn't support detecting the loss of carrier. The program have to be restarted to reconnect.

## PETSCII

The PETSCII interpreter is bespoke, and the kernal chrout routine is used only sparingly.
- PETSCII is interpreted the same way on all three machines.
- Physical and logical lines are always the same.
- The return always moves the cursor down one line, and to the first column.
- The screen is always scrolled by one line.
- Inst is not supported.
- The bell character is supported. The program can be compiled to flash the border, play a short tone, do nothing, or use the kernal bell character on the C128.

## Setup

There are multiple way to set up the program for easy use.
- For VICE there are scripts to show the correct settings for a direct connection. These scripts can be used with the unmodified programs in the release.
- For the Ultimate 64 an autodialing variant should be compiled for each address planned to dial.

## Compilation

To compile the program you must have:
- Bash
- a very recent cc65. CC65_HOME must be set.
- cc1541
- python3

The `compile-all.sh` script recompiles everything and leaves the result in the `output` directory.
- For all configuration there will be a  prg file, and a d64 file with the prg embedded in it.
- There is a default configuration for all three supported machines.
- There will be a prg and d64 for every file in the `flavors` and `flavors.private` directories. Look at the provided flavor files and at `flavor.option` file to get an idea about the available options. The compilation process always substitutes a whole line in place of a whole line. This is the reason for the arcane syntax of the flavor files.

## Speed

I performed some rudimentary measurements of the throughput of the program.
The test was simple. I sent whole-screen updates to the terminal, and increased the border color any time there were no new data in the incoming serial buffer.
In this way the border flickers when PETSCII interpreter is faster than the incoming data, and there's no flicker when the PETSCII interpreter is behind the data.
- C128: flicker at 9600 baud, no flicker at 19200.
- C64: flicker at 19200 baud, no flicker at 38400.
- Plus/4: flicker at 19200 baud, and that's the maximum rate.
