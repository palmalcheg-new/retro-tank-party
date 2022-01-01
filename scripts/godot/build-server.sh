#!/bin/bash

OPTS="-j${NUM_CORES} platform=server production=yes"

if [ "$TOOLS" = "yes" ]; then
	OPTS="$OPTS tools=yes target=release_debug"
else
	OPTS="$OPTS tools=no target=release"
fi

if [ "$BITS" = "32" ]; then
	export PATH="${GODOT_SDK_LINUX_X86}/bin:${BASE_PATH}"
	OPTS="$OPTS bits=32"
else
	export PATH="${GODOT_SDK_LINUX_X86_64}/bin:${BASE_PATH}"
	OPTS="$OPTS bits=64"
fi

echo "Running: scons $OPTS $SCONS_OPTS..."
exec scons $OPTS $SCONS_OPTS

