#!/bin/bash
OUTPUT="output"
SRC="src"
VERSION=$(cat ${SRC}/main.s | grep '#VERSION#' | cut -d '"' -f 2)
