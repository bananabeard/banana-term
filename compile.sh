#!/bin/bash
set -e

if [ -z "${CC65_HOME+x}" ]; then
  CC65_HOME="${HOME}/lib/cc65"
fi
if [ ! -d "${CC65_HOME}" ]; then
  echo "couldn't find cc65"
  exit 1
fi

FLAVOR="$1"
NAME="$2"
OUTPUT="$3"
PLATFORM="$4"
SRC="$5"
VERSION="$6"

FLAVOR2=""
if [ -n "${FLAVOR}" ]; then
  FLAVOR2="-${FLAVOR}"
fi

echo -e "\e[92m  ### \e[96mCompiling to \e[91m${NAME} prg \e[92m###\e[0m"

"${CC65_HOME}/bin/cl65" \
  -I "${CC65_HOME}/include" \
  -L "${CC65_HOME}/lib" \
  -l "${OUTPUT}/banana-term-${PLATFORM}-${VERSION}${FLAVOR2}.c.s" \
  -m "${OUTPUT}/banana-term-${PLATFORM}-${VERSION}${FLAVOR2}.map" \
  -T \
  -t "${PLATFORM}" \
  -Or -Os \
  -o "${OUTPUT}/banana-term-${PLATFORM}-${VERSION}${FLAVOR2}.prg" \
  --warn-align-waste \
  --warnings-as-errors \
  "${SRC}/interrupt.s" \
  "${SRC}/main.s" \
  "${SRC}/memory.s" \
  "${SRC}/screen.s" \
  "${SRC}/main.c"
if [ "0" != "$?" ]; then
  exit 1
fi

echo -e "\e[92m  ### \e[96mCompiling \e[91m${NAME} d64 \e[92m###\e[0m"

cc1541 \
  -q \
  -n "banana-term" \
  -i "00 2a" \
  -f "banana-term" -w "${OUTPUT}/banana-term-${PLATFORM}-${VERSION}${FLAVOR2}.prg" \
  -T DEL -f "${PLATFORM}" -L \
  -T DEL -f "version ${VERSION}" -L \
  "${OUTPUT}/banana-term-${PLATFORM}-${VERSION}${FLAVOR2}.d64"
if [ "0" != "$?" ]; then
  exit 1
fi

if [ -n "${FLAVOR}" ]; then
  cc1541 \
    -q \
    -T DEL -f "${FLAVOR}" -L \
    "${OUTPUT}/banana-term-${PLATFORM}-${VERSION}${FLAVOR2}.d64"
  if [ "0" != "$?" ]; then
    exit 1
  fi
fi
