#!/bin/bash
set -e

. ./variables.sh

function compileFlavor {
  FLAVOR_FILE="$1"
  FLAVOUR_OUTPUT="$2"
  FLAVOR="$(basename ${FLAVOR_FILE})"
  echo -e "\e[92m  ### \e[96mGenerating flavor \e[91m${FLAVOR_FILE} \e[92m###\e[0m"
  PLATFORM="$(cat ${FLAVOR_FILE} | grep PLATFORM | cut -d = -f 2 | xargs)"
  FLAVOR_SRC="${FLAVOUR_OUTPUT}/${FLAVOR}"
  if [ -e "${FLAVOR_SRC}" ]; then
    echo "${FLAVOR_SRC} already exists"
    exit 1
  fi
  mkdir -p "${FLAVOR_SRC}"
  for SRC_FILE in ${SRC}/*; do
    ./template-copy.py "${FLAVOR_FILE}" "${SRC_FILE}" "${FLAVOR_SRC}/$(basename ${SRC_FILE})"
  done
  ./compile.sh "${FLAVOR}" "${NAME}" "${FLAVOUR_OUTPUT}" "${PLATFORM}" "${FLAVOR_SRC}" "${VERSION}"
}

function compileFlavors {
  FLAVORS_DIR="$1"
  if [ -d "${FLAVORS_DIR}" ]; then
    for FLAVOR_FILE in ${FLAVORS_DIR}/*; do
      compileFlavor "${FLAVOR_FILE}" "${OUTPUT}"
      FLAVOR_NAME="$(basename ${FLAVOR_FILE})"
      for ADDRESS_FILE in ${ADDRESSES}/*; do
        ADDRESS_NAME="$(basename ${ADDRESS_FILE})"
        ADDRESS="$(cat ${ADDRESS_FILE})"
        FLAVOR_FILE_GENERATED="${FLAVORS_GENERATED_DIR}/${FLAVOR_NAME}-${ADDRESS_NAME}"
        cp "${FLAVOR_FILE}" "${FLAVOR_FILE_GENERATED}"
        echo "MODEM_COMMANDS = .byte \"atdt${ADDRESS}\", PETSCII_RETURN, \$00" >> "${FLAVOR_FILE_GENERATED}"
        compileFlavor "${FLAVOR_FILE_GENERATED}" "${OUTPUT}"
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
  for PLATFORM in "${PLATFORMS[@]}"; do
    FLAVOR_FILE_GENERATED="${FLAVORS_GENERATED_DIR}/${PLATFORM}-${ADDRESS_NAME}"
    echo "PLATFORM = ${PLATFORM}" > "${FLAVOR_FILE_GENERATED}"
    echo "MODEM_COMMANDS = .byte \"atdt${ADDRESS}\", PETSCII_RETURN, \$00" >> "${FLAVOR_FILE_GENERATED}"
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
  cp ${OUTPUT}/${NAME}-${VERSION}-${PLATFORM}*.d64 "${OUTPUT}/${RELEASE}/${PLATFORM}"
  cp ${OUTPUT}/${NAME}-${VERSION}-${PLATFORM}*.prg "${OUTPUT}/${RELEASE}/${PLATFORM}"
  cp start-${PLATFORM}*.sh "${OUTPUT}/${RELEASE}/${PLATFORM}"
done
cd "${OUTPUT}/${RELEASE}"
zip -9r "${NAME}-${VERSION}.zip" *
cd ../..
