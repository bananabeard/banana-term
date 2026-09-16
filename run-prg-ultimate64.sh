#!/bin/bash
curl -XPOST "http://$1/v1/runners:run_prg" -H 'Content-Type: application/octet-stream' --data-binary "@$2"
