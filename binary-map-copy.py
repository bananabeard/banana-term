#!/usr/bin/python3
import sys

with open(sys.argv[1], "r") as input_file:
    with open(sys.argv[2], "w") as output_file:
        for line in input_file:
            line = line.strip()
            index = line.rfind("$")
            if index >=0:
                number = line[index+1:]
                line = line[:index+1]
                if len(number) == 2:
                    number = "{0:2x}".format(int(number, 16) + 0x80)
                elif len(number) == 4:
                    number = "{0:4x}".format(int(number, 16) + 0x8080)
                else:
                    raise Exception("unexpected number {0:s}".format(number))
                line = line + number
            output_file.write(line)
            output_file.write("\n")
