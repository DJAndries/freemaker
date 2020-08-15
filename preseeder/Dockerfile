FROM debian:latest

WORKDIR /usr/src

RUN apt update

RUN apt install -y bsdtar genisoimage cpio

ADD preseed_iso.sh ./
RUN chmod +x preseed_iso.sh
