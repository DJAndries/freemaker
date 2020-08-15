#!/bin/sh

if [ -z "$(ls ./out/debian-preseeded.iso)" ]; then
  echo "No preseeded iso available!"
  exit 1
fi

curl --progress-bar -F'file=@./out/debian-preseeded.iso' https://0x0.st | tee /dev/null
