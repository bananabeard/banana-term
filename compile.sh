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

echo -e "\e[92m  ### \e[96mCompiling \e[91m${FLAVOR} prg \e[92m###\e[0m"

"${CC65_HOME}/bin/cl65" \
  -I "${CC65_HOME}/include" \
  -L "${CC65_HOME}/lib" \
  -l "${OUTPUT}/${NAME}-${VERSION}-${FLAVOR}.c.s" \
  -m "${OUTPUT}/${NAME}-${VERSION}-${FLAVOR}.map" \
  -T \
  -t "${PLATFORM}" \
  -Or -Os \
  -o "${OUTPUT}/${NAME}-${VERSION}-${FLAVOR}.prg" \
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

echo -e "\e[92m  ### \e[96mCreating \e[91m${FLAVOR} d64 \e[92m###\e[0m"

cc1541 \
  -q \
  -n "${NAME}" \
  -i "00 2a" \
  -f "${NAME}" -w "${OUTPUT}/${NAME}-${VERSION}-${FLAVOR}.prg" \
  -T DEL -f "version ${VERSION}" -L \
  -T DEL -f "${FLAVOR}" -L \
  "${OUTPUT}/${NAME}-${VERSION}-${FLAVOR}.d64"
if [ "0" != "$?" ]; then
  exit 1
fi
