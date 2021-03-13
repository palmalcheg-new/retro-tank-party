#!/bin/bash

if [ -z "$STEAM_REDISTRIBUTABLES_URL" ]; then
	echo "The STEAM_REDISTRIBUTABLES_URL must be set to use this script." > /dev/stderr
	exit 1
fi

WORKDIR=/tmp/steam-redistributables

SRC="$1"
DST="$2"

rm -rf $WORKDIR
mkdir $WORKDIR
wget -q "$STEAM_REDISTRIBUTABLES_URL" -O "$WORKDIR/pack.zip"
(cd $WORKDIR && unzip -q pack.zip)

cp "$WORKDIR/$SRC" "$DST"

rm -rf $WORKDIR

