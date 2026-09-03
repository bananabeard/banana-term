#!/bin/bash
ADDRESSES="addresses"
FLAVORS="flavors"
FLAVORS_PRIVATE="${FLAVORS}-private"
NAME="banana-term"
OUTPUT="output"
PLATFORMS=("c128" "c64" "plus4")
SRC="src"
VERSION=$(cat ${SRC}/main.s | grep '#VERSION#' | cut -d '"' -f 2)
