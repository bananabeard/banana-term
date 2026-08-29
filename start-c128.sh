#!/bin/bash

PROGRAM="$1"
ADDRESS="$2"

echo -e "\e[92m  ### \e[96mStarting \e[91mCommodore 128 \e[92m###\e[0m"

x128 \
  -acia1 \
  -acia1base 0xDE00 \
  -acia1irq 1 \
  -acia1mode 1 \
  -myaciadev 2 \
  -hidevdcwindow \
  +keyset \
  -maximized \
  -rsdev3 "${ADDRESS}" \
  -rsdev3baud 19200 \
  "${PROGRAM}"
