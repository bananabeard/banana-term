#!/bin/bash

PROGRAM="$1"
ADDRESS="$2"

echo -e "\e[92m  ### \e[96mStarting \e[91mCommodore Plus/4 \e[92m###\e[0m"

xplus4 \
  -acia \
  -myaciadev 0 \
  +keyset \
  -maximized \
  -rsdev1 "${ADDRESS}" \
  -rsdev1baud 19200 \
  +rsdev1ip232 \
  "${PROGRAM}"
