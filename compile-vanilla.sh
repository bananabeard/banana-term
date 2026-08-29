#!/bin/bash
set -e

. ./variables.sh

rm -fr "${OUTPUT}"
mkdir -p "${OUTPUT}"

./compile.sh "" "Commodore 128"    "${OUTPUT}" "c128"  "${SRC}" "${VERSION}"
./compile.sh "" "Commodore 64"     "${OUTPUT}" "c64"   "${SRC}" "${VERSION}"
./compile.sh "" "Commodore Plus/4" "${OUTPUT}" "plus4" "${SRC}" "${VERSION}"
