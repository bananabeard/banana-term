#!/bin/bash
set -e

. ./variables.sh

function compileFlavor {
  FLAVOR_FILE2="$1"
  FLAVOUR_OUTPUT2="$2"
  FLAVOR2="$(basename ${FLAVOR_FILE2})"
  echo -e "\e[92m  ### \e[96mGenerating flavor \e[91m${FLAVOR_FILE2} \e[92m###\e[0m"
  PLATFORM2="$(cat ${FLAVOR_FILE2} | grep PLATFORM | cut -d = -f 2 | xargs)"
  FLAVOR_SRC2="${FLAVOUR_OUTPUT2}/${FLAVOR2}"
  if [ -e "${FLAVOR_SRC2}" ]; then
    echo "${FLAVOR_SRC2} already exists"
    exit 1
  fi
  mkdir -p "${FLAVOR_SRC2}"
  for SRC_FILE2 in ${SRC}/*; do
    ./template-copy.py "${FLAVOR_FILE2}" "${SRC_FILE2}" "${FLAVOR_SRC2}/$(basename ${SRC_FILE2})"
  done
  ./compile.sh "${FLAVOR2}" "${NAME}" "${FLAVOUR_OUTPUT2}" "${PLATFORM2}" "${FLAVOR_SRC2}" "${VERSION}"
}

function compileFlavors {
  FLAVORS_DIR3="$1"
  if [ -d "${FLAVORS_DIR3}" ]; then
    for FLAVOR_FILE3 in ${FLAVORS_DIR3}/*; do
      compileFlavor "${FLAVOR_FILE3}" "${OUTPUT}"
      FLAVOR_NAME3="$(basename ${FLAVOR_FILE3})"
      for ADDRESS_FILE3 in ${ADDRESSES}/*; do
        ADDRESS_NAME3="$(basename ${ADDRESS_FILE3})"
        ADDRESS3="$(cat ${ADDRESS_FILE3})"
        ADDRESS_HOST3="$(echo ${ADDRESS3} | sed -r 's/(.*)\:([^:]*)/\1/')"
        ADDRESS_PORT3="$(echo ${ADDRESS3} | sed -r 's/(.*)\:([^:]*)/\2/')"
        FLAVOR_FILE_GENERATED3="${FLAVORS_GENERATED_DIR}/${FLAVOR_NAME3}-${ADDRESS_NAME3}"
        cp "${FLAVOR_FILE3}" "${FLAVOR_FILE_GENERATED3}"
        echo "MODEM_COMMANDS = .byte \"atdt${ADDRESS3}\", PETSCII_RETURN, \$00" >> "${FLAVOR_FILE_GENERATED3}"
        echo "ULTIMATE64_ADDRESS = .byte \"${ADDRESS_HOST3}\", \$00" >> "${FLAVOR_FILE_GENERATED3}"
        echo "ULTIMATE64_PORT = .word ${ADDRESS_PORT3}" >> "${FLAVOR_FILE_GENERATED3}"
        compileFlavor "${FLAVOR_FILE_GENERATED3}" "${OUTPUT}"
      done
    done
  fi
}

./compile-vanilla.sh

## binary-map

mkdir -p "${OUTPUT}/${BINARY_MAP}/${OUTPUT}"
mkdir -p "${OUTPUT}/${RELEASE}"
for PLATFORM in "${PLATFORMS[@]}"; do
  echo -e "\e[92m  ### \e[96mGenerating ${PLATFORM} binary map \e[92m###\e[0m"
  mkdir -p "${OUTPUT}/${RELEASE}/${PLATFORM}"
  cp "${BINARY_MAP}" "${OUTPUT}/${BINARY_MAP}/${PLATFORM}-${BINARY_MAP}1"
  echo "PLATFORM = ${PLATFORM}" >> "${OUTPUT}/${BINARY_MAP}/${PLATFORM}-${BINARY_MAP}1"
  ./binary-map-copy.py \
    "${OUTPUT}/${BINARY_MAP}/${PLATFORM}-${BINARY_MAP}1" \
    "${OUTPUT}/${BINARY_MAP}/${PLATFORM}-${BINARY_MAP}2"
  compileFlavor "${OUTPUT}/${BINARY_MAP}/${PLATFORM}-${BINARY_MAP}1" "${OUTPUT}/${BINARY_MAP}/${OUTPUT}"
  compileFlavor "${OUTPUT}/${BINARY_MAP}/${PLATFORM}-${BINARY_MAP}2" "${OUTPUT}/${BINARY_MAP}/${OUTPUT}"
  ./binary-map-compare.py \
    "${BINARY_MAP}" \
    "${OUTPUT}/${NAME}-${VERSION}-${PLATFORM}.prg" \
    "${OUTPUT}/${BINARY_MAP}/${OUTPUT}/${NAME}-${VERSION}-${PLATFORM}-${BINARY_MAP}1.prg" \
    "${OUTPUT}/${BINARY_MAP}/${OUTPUT}/${NAME}-${VERSION}-${PLATFORM}-${BINARY_MAP}2.prg" \
    "${OUTPUT}/${RELEASE}/${PLATFORM}/${NAME}-${VERSION}-${PLATFORM}.map"
done

## vanilla + addresses

FLAVORS_GENERATED_DIR="${OUTPUT}/${FLAVORS}"
mkdir -p "${FLAVORS_GENERATED_DIR}"

for ADDRESS_FILE in ${ADDRESSES}/*; do
  ADDRESS_NAME="$(basename ${ADDRESS_FILE})"
  ADDRESS="$(cat ${ADDRESS_FILE})"
  ADDRESS_HOST="$(echo ${ADDRESS} | sed -r 's/(.*)\:([^:]*)/\1/')"
  ADDRESS_PORT="$(echo ${ADDRESS} | sed -r 's/(.*)\:([^:]*)/\2/')"
  for PLATFORM in "${PLATFORMS[@]}"; do
    FLAVOR_FILE_GENERATED="${FLAVORS_GENERATED_DIR}/${PLATFORM}-${ADDRESS_NAME}"
    echo "PLATFORM = ${PLATFORM}" > "${FLAVOR_FILE_GENERATED}"
    echo "MODEM_COMMANDS = .byte \"atdt${ADDRESS}\", PETSCII_RETURN, \$00" >> "${FLAVOR_FILE_GENERATED}"
    echo "ULTIMATE64_ADDRESS = .byte \"${ADDRESS_HOST}\", \$00" >> "${FLAVOR_FILE_GENERATED}"
    echo "ULTIMATE64_PORT = .word ${ADDRESS_PORT}" >> "${FLAVOR_FILE_GENERATED}"
    compileFlavor "${FLAVOR_FILE_GENERATED}" "${OUTPUT}"
  done
done

## flavors + addresses

compileFlavors "${FLAVORS}" "${OUTPUT}"

## release

echo -e "\e[92m  ### \e[96mCreating release \e[92m###\e[0m"
cp README*.md "${OUTPUT}/${RELEASE}"
touch "${OUTPUT}/${RELEASE}/version-${VERSION}"
for PLATFORM in "${PLATFORMS[@]}"; do
  cp `find output -maxdepth 1 -type f | grep -E -e "${OUTPUT}/${NAME}-${VERSION}-${PLATFORM}.*(d64|prg)" | grep -F -v ".private"` "${OUTPUT}/${RELEASE}/${PLATFORM}"
  if [ -e "start-${PLATFORM}.sh" ]; then
    cp start-${PLATFORM}*.sh "${OUTPUT}/${RELEASE}/${PLATFORM}"
  fi
done
cd "${OUTPUT}/${RELEASE}"
zip -9r "${NAME}-${VERSION}.zip" *
cd ../..
