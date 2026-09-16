# Banana-term

Banana-term is a PETSCII terminal program for the Commodore 64, Plus/4, and 128. The indented use-case is everyday one-click use in emulators. Feedback on real machines would be nice.

- Supports the Commodore 64 and 128 with a Swiftlink cartridge. This includes the Ultimate 64 and the Commodore 64 Ultimate machines. The ACIA address must be $DE00.
- Supports the Ultimate-64 board and the command interface.
- Supports the Commodore Plus/4.
- Only 40 columns mode.
- There's no phonebook. The program can be compiled to autodial a specific number. Alternatively it can be used with a direct link or by manual dialing.
- There's no support for downloading or uploading files.
- Banana-term can be compiled to use a custom color scheme. The Plus/4 version comes with 2 color schemes, one with the colors of the Plus/4 basic editor, and one that attempts at mimicking the colors of the VIC-II chip.
- Banana-term can be compiled to show a cursor with a fixed character, to show a cursor as inverted characters on the screen, or not to show a cursor. The cursor doesn't blink.
- Banana-term uses the maximum baud rates by default, which is 38400 for the C64, and 19200 for the Plus/4 and the C128. Banana-term also supports by recompilation the baud rates 300, 600, 1200, 2400, 4800, 9600, 19200, 38400, and 57600.

## PETSCII

The PETSCII interpreter is bespoke, and the kernal chrout routine is used only sparingly.

- PETSCII is interpreted the same way on all three machines.
- Physical and logical lines are always the same.
- The return always moves the cursor down one line, and to the first column.
- The screen is always scrolled by one line.
- Inst is not supported.
- The bell character is supported. Banana-term can be compiled to flash the border, play a tone, do nothing, or use the kernal bell character on the C128.

## Setup

There are multiple ways to set up banana-term for easy use. Various parameters and the address to be dialed can be customized by recompiling or by editing the precompiled binaries.

- For VICE there are scripts to show the correct settings for a direct connection. These scripts can be used with the unmodified programs in the release.
- For modems, for VICE with tcpser, and for the Ultimate-64 with Swiftlink cartridge an autodialing variant should be used, prepared for each address planned to dial.
- For the Ultimate-64 with command interface an ultimate64 variant should be used, prepared for each address planned to dial.

## Customization with a hex-editor

There are map files for the vanilla release PRGs that shows the location of the compile-time parameters. These parameters can be modified by a hex-editor.

See the README on the map files for the list of parameters and their valid values.

## Compilation

To compile banana-term you must have:

- Bash
- a very recent cc65. CC65_HOME must be set.
- cc1541
- python3

The `compile-all.sh` script recompiles everything and leaves the result in the `output` directory.

- There will be a PRG and a D64 containing the PRG for all configuration.
- Configurations are all possible combinations of addresses and flavors.
- Addresses are stored in the `addresses` directory. Each file must contain one line. Banana-term will autodial the address with the `ATDT` command.
There will be a configuration without an address.
- Flavors are the three vanilla configurations and one flavor for each file in the `flavors` directory. Look at the provided flavor files and at `flavor.option` file to get an idea about the available options. The compilation process always substitutes a whole line in place of a whole line. This is the reason for the arcane syntax of the flavor files.

## Speed comparison

I performed some rudimentary measurements of the overall speed of a few terminal programs. I pointed my phone on the screen, sent a whole-screen update, and counted the number of frames it took to redraw the screen. The recordings were at 30 fps.

| Machine     | Program        | Connection              | Frames |
| ----------- | -------------- | ----------------------- | -----: |
| Ultimate-64 | CCGMS Ultimate | Swiftlink, 38400, wifi  |     68 |
| Ultimate-64 | CCGMS Future   | Swiftlink, 38400, wifi  |     61 |
| Ultimate-64 | UltimateTerm   | command interface, wifi |     21 |
| Ultimate-64 | banana-term    | Swiftlink, 38400, wifi  |     18 |
| Ultimate-64 | banana-term    | command interface, wifi |     12 |
| VICE C128   | banana-term    | ACIA, 19200, local      |     25 |
| VICE C64    | banana-term    | ACIA, 38400, local      |     16 |
| VICE Plus/4 | banana-term    | ACIA, 19200, local      |     24 |

## Serial speed

I performed some rudimentary measurements of the throughput of banana-term.
The test was simple. I sent whole-screen updates to the terminal, and increased the border color any time there were no new data in the incoming serial buffer.
In this way the border flickers when the PETSCII interpreter is faster than the incoming data, and there's no flicker when the PETSCII interpreter is lagging behind the data.

- C128: flicker at 9600 baud, no flicker at 19200.
- C64: flicker at 19200 baud, no flicker at 38400.
- Plus/4: flicker at 19200 baud, and that's the maximum rate.

## Known issues

- The serial driver sometimes crashes on the C128. While the [issue](https://github.com/cc65/cc65/issues/2443) have been brought up quite a while ago, it's still not clear what causes it. The workaround for the time being is to use 19200 baud rate on the C128, and not 38400. This seems to make the problem go away in VICE.
- The serial driver doesn't support detecting the loss of carrier. In fact, the design of the ACIA chip doesn't allow the reliable detection of the carrier.
- The Plus/4 version has a short pause before it starts to read the keyboard. This needs further investigations.
- The Ultimate-64 firmware version 3.15a blocks on a write when the send buffer is full until the buffer has free space again. The write API has provisions to report back the number of bytes successfully written to the buffer, and there's code in banana-term to handle the situation. The future is uncertain though, as the read call has a similar byte count, but on empty reads the result is not a `00,OK` with zero bytes, but an undocumented error `02`.