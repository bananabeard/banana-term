#!/bin/bash
set -e

. ./variables.sh

function compileFlavor {
  FLAVOR_FILE="$1"
  FLAVOR="$(basename ${FLAVOR_FILE})"
  echo -e "\e[92m  ### \e[96mGenerating flavor \e[91m${FLAVOR_FILE} \e[92m###\e[0m"
  PLATFORM="$(cat ${FLAVOR_FILE} | grep PLATFORM | cut -d = -f 2 | xargs)"
  FLAVOR_SRC="${OUTPUT}/${FLAVOR}"
  if [ -e "${FLAVOR_SRC}" ]; then
    echo "${FLAVOR_SRC} already exists"
    exit 1
  fi
  mkdir -p "${FLAVOR_SRC}"
  for SRC_FILE in ${SRC}/*; do
    ./template-copy.py "${FLAVOR_FILE}" "${SRC_FILE}" "${FLAVOR_SRC}/$(basename ${SRC_FILE})"
  done
  ./compile.sh "${FLAVOR}" "${NAME}" "${OUTPUT}" "${PLATFORM}" "${FLAVOR_SRC}" "${VERSION}"
}

function compileFlavors {
  FLAVORS_DIR="$1"
  if [ -d "${FLAVORS_DIR}" ]; then
    for FLAVOR_FILE in ${FLAVORS_DIR}/*; do
      compileFlavor "${FLAVOR_FILE}"
      FLAVOR_NAME="$(basename ${FLAVOR_FILE})"
      for ADDRESS_FILE in ${ADDRESSES}/*; do
        ADDRESS_NAME="$(basename ${ADDRESS_FILE})"
        ADDRESS="$(cat ${ADDRESS_FILE})"
        FLAVOR_FILE_GENERATED="${FLAVORS_GENERATED_DIR}/${FLAVOR_NAME}-${ADDRESS_NAME}"
        cp "${FLAVOR_FILE}" "${FLAVOR_FILE_GENERATED}"
        echo "MODEM_COMMANDS = .byte \"atdt${ADDRESS}\", PETSCII_RETURN, \$00" >> "${FLAVOR_FILE_GENERATED}"
        compileFlavor "${FLAVOR_FILE_GENERATED}"
      done
    done
  fi
}

./compile-vanilla.sh

FLAVORS_GENERATED_DIR="${OUTPUT}/${FLAVORS}"
mkdir -p "${FLAVORS_GENERATED_DIR}"

for ADDRESS_FILE in ${ADDRESSES}/*; do
  ADDRESS_NAME="$(basename ${ADDRESS_FILE})"
  ADDRESS="$(cat ${ADDRESS_FILE})"
  for PLATFORM in "${PLATFORMS[@]}"; do
    FLAVOR_FILE_GENERATED="${FLAVORS_GENERATED_DIR}/${PLATFORM}-${ADDRESS_NAME}"
    echo "PLATFORM = ${PLATFORM}" > "${FLAVOR_FILE_GENERATED}"
    echo "MODEM_COMMANDS = .byte \"atdt${ADDRESS}\", PETSCII_RETURN, \$00" >> "${FLAVOR_FILE_GENERATED}"
    compileFlavor "${FLAVOR_FILE_GENERATED}"
  done
done

compileFlavors "${FLAVORS}"
compileFlavors "${FLAVORS_PRIVATE}"

cd "${OUTPUT}"
zip -9 "${NAME}-${VERSION}.zip" *.prg *.d64
cd ..
