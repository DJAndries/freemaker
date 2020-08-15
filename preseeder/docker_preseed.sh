#!/bin/sh
set -e

if [ "$#" -lt 1 ]; then
  echo "usage: docker_preseed.sh <debian iso image>"
  exit 1
fi

mkdir -p out

docker build -t preseeder .
docker run -it --rm -v $(realpath $1):/usr/src/debian.iso -v $(realpath ./preseed.cfg):/usr/src/preseed.cfg -v $(realpath ./out):/usr/src/out preseeder ./preseed_iso.sh ./debian.iso ./preseed.cfg
docker rmi preseeder
