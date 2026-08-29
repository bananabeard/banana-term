#!/bin/bash
set -e

. ./variables.sh

function compileFlavors {
  FLAVORS="$1"
  if [ -d "${FLAVORS}" ]; then
    for FLAVOR_FILE in ${FLAVORS}/*; do
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
      ./compile.sh "${FLAVOR}" "${FLAVOR}" "${OUTPUT}" "${PLATFORM}" "${FLAVOR_SRC}" "${VERSION}"
    done
  fi
}

./compile-vanilla.sh
 compileFlavors "flavors"
 compileFlavors "flavors.private"
