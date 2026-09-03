#!/bin/bash
set -e

. ./variables.sh

rm -fr "${OUTPUT}"
mkdir -p "${OUTPUT}"

for PLATFORM in "${PLATFORMS[@]}"; do
  ./compile.sh "${PLATFORM}" "${NAME}" "${OUTPUT}" "${PLATFORM}" "${SRC}" "${VERSION}"
done
