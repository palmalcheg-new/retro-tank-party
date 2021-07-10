#!/bin/bash

PLATFORM=${1:-all}
BUILD=${2:-both}

download() {
	if `which wget >/dev/null 2>&1`; then
		wget "$1" -O "$2"
	else
		curl -L "$1" -o "$2"
	fi
}

# Since all platforms are now in the same download, we aren't using $PLATFORM
# for anything.

if [ "$BUILD" = "release" -o "$BUILD" = "both" ]; then
	download https://github.com/godotengine/webrtc-native/releases/download/0.5/godot-webrtc-native-release-0.5.zip godot-webrtc-native-release.zip
	unzip -o -a godot-webrtc-native-release.zip -x '*.tres'
	rm godot-webrtc-native-release.zip
fi

if [ "$BUILD" = "debug" -o "$BUILD" = "both" ]; then
	download https://github.com/godotengine/webrtc-native/releases/download/0.5/godot-webrtc-native-debug-0.5.zip godot-webrtc-native-debug.zip
	unzip -o -a godot-webrtc-native-debug.zip -x '*.tres'
	rm godot-webrtc-native-debug.zip
fi

