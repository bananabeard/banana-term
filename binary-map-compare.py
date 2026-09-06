#!/usr/bin/python3
import hashlib
import os
import sys

def put_key_offset(key_offsets2, key2, offset2):
    if key2 in key_offsets2:
        key_offsets2[key2] = key_offsets2[key2] + [offset2]
    else:
        key_offsets2[key2] = [offset2]

def put_value_key(value_keys2, value2, key2):
    if value2 in value_keys2:
        raise Exception("duplicate value ${0:02x}, keys: {1:s}, {2:s}".format(value2, key2, value_keys2[value2]))
    value_keys2[value2] = key2

def write_interval(file2, interval2):
    if interval2[0] == interval2[1]:
        line2 = "    ${0:04x}\n".format(interval2[0])
    else:
        line2 = "    ${0:04x} - ${1:04x}\n".format(interval2[0], interval2[1])
    file2.write(line2)

valueKeys = dict()

with open(sys.argv[1], "r") as flavor_file:
    for line in flavor_file:
        line = line.strip()
        index = line.find("=")
        if index >= 0:
            key = line[:index].strip()
            line = line[index+1:].strip()
            index = line.rfind("$")
            if index >= 0:
                number = line[index+1:]
                if len(number) == 2:
                    put_value_key(valueKeys, int(number, 16), key)
                elif len(number) == 4:
                    put_value_key(valueKeys, int(number[:2], 16), key + " high byte")
                    put_value_key(valueKeys, int(number[2:], 16), key + " low byte")
                else:
                    raise Exception("unexpected number {0:s}".format(number))

with open(sys.argv[2], "rb") as file:
    data0 = file.read()
with open(sys.argv[3], "rb") as file:
    data1 = file.read()
with open(sys.argv[4], "rb") as file:
    data2 = file.read()

if len(data0) != len(data1):
    raise Exception("{0:s} and {1:s} has different lengths".format(sys.argv[2], sys.argv[3]))
if len(data0) != len(data2):
    raise Exception("{0:s} and {1:s} has different lengths".format(sys.argv[2], sys.argv[4]))

keyOffsets = dict()

for index in range(len(data0)):
    if data1[index] == data2[index]:
        if data0[index] != data1[index]:
            if (data0[index] >= ord('0')) and (data0[index] <= ord('9')) and (data1[index] == ord('X')):
                put_key_offset(keyOffsets, "BAUD_RATE string", index)
            else:
                raise Exception(
                    "{0:s} and {1:s} has different value at index ${2:04x}".format(sys.argv[2], sys.argv[3], index))
    else:
        value = data1[index]
        if value not in valueKeys:
            raise Exception("value ${0:02x} at index ${1:04x} has no key".format(value, index))
        if data2[index] != value + 0x80:
            raise Exception("value ${0:02x} at index ${1:04x} is not ${2:02x}".format(data2[index], index, value))
        key = valueKeys[value]
        put_key_offset(keyOffsets, key, index)

with open(sys.argv[5], "w") as file:
    file.write("map file for {0:s}\n".format(os.path.basename(sys.argv[2])))
    file.write("    file size: {0:d}\n".format(len(data0)))
    hash = hashlib.md5()
    hash.update(data0)
    file.write("    md5sum:    {0:s}\n".format(hash.hexdigest()))
    hash = hashlib.sha256()
    hash.update(data0)
    file.write("    sha256sum: {0:s}\n".format(hash.hexdigest()))
    keys = list(keyOffsets.keys())
    keys.sort()
    for key in keys:
        file.write("\n")
        file.write(key + ":\n")
        interval = None
        for offset in keyOffsets[key]:
            if interval is None:
                interval = (offset, offset)
            elif interval[1] + 1 == offset:
                interval = (interval[0], offset)
            else:
                write_interval(file, interval)
                interval = (offset, offset)
        write_interval(file, interval)
