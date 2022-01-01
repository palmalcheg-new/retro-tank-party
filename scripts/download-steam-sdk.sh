#!/bin/bash

if [ -z "$STEAM_SDK_URL" ]; then
	echo "The STEAM_SDK_URL must be set to use this script." > /dev/stderr
	exit 1
fi

WORKDIR=/tmp/steam-sdk

DST="${!#}"
SRC=("${@:1:$#-1}")

rm -rf $WORKDIR
mkdir $WORKDIR
wget -q "$STEAM_SDK_URL" -O "$WORKDIR/pack.zip"
(cd $WORKDIR && unzip -q pack.zip)

for x in "${SRC[@]}"; do
	cp -r "$WORKDIR/sdk/$x" "$DST"
done

rm -rf $WORKDIR

