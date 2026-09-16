#!/bin/bash
ADDRESSES="addresses"
BINARY_MAP="binary-map"
C64="c64"
FLAVORS="flavors"
FLAVORS_PRIVATE="${FLAVORS}-private"
NAME="banana-term"
OUTPUT="output"
RELEASE="release"
SRC="src"
ULTIMATE64="ultimate64"
VERSION=$(cat ${SRC}/main.s | grep '#VERSION#' | cut -d '"' -f 2)

PLATFORMS=("c128" "${C64}" "plus4" "${ULTIMATE64}")
