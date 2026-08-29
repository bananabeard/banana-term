#!/usr/bin/python3
import sys

flavor_map = dict()

with open(sys.argv[1], "r") as flavor_file:
    for line in flavor_file:
        index = line.find("=")
        if index >= 0:
            key = line[:index].strip()
            value = line[index+1:].strip()
            flavor_map[key] = value

with open(sys.argv[2], "r") as input_file:
    with open(sys.argv[3], "w") as output_file:
        for line in input_file:
            line = line.rstrip()
            index = line.rfind("##")
            if index >=0:
                key = line[index+2:]
                if key in flavor_map:
                    line = flavor_map[key]
            output_file.write(line)
            output_file.write("\n")
