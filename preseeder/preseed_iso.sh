#!/bin/sh
set -e

if [ "$#" -lt 2 ]; then
  echo "usage: preseed_iso.sh <debian iso> <preseed cfg>"
  exit 1
fi

mkdir -p isofiles

echo "Extracting iso"
bsdtar -C ./isofiles -xf $1

echo "Adding preseed to initrd"
gunzip ./isofiles/install.amd/initrd.gz
echo $2 | cpio -H newc -o -A -F ./isofiles/install.amd/initrd
gzip ./isofiles/install.amd/initrd

echo "Regenerating md5sum"
cd ./isofiles
find -follow -type f ! -name md5sum.txt -print0 | xargs -0 md5sum > md5sum.txt
cd ..

echo "Creating new ISO"
genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
  -boot-load-size 4 -boot-info-table -o ./out/debian-preseeded.iso ./isofiles
