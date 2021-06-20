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

if [ "$PLATFORM" = "macosx" -o "$PLATFORM" = "all" ]; then
	download https://github.com/godotengine/webrtc-native/files/3796078/webrtc_0.3_mac_only-with-debug.zip webrtc_0.3_mac_only-with-debug.zip
	unzip -o -a webrtc_0.3_mac_only-with-debug.zip
	cp -r webrtc_mac/webrtc/lib webrtc/
	cp -r webrtc_mac/webrtc_debug/lib webrtc_debug/
	rm -rf webrtc_0.3_mac_only-with-debug.zip __MACOSX webrtc_mac
	rm -f webrtc/webrtc.tres webrtc_debug/webrtc_debug.tres
fi

if [ "$PLATFORM" != "macosx" ]; then
	if [ "$BUILD" = "release" -o "$BUILD" = "both" ]; then
		download https://github.com/godotengine/webrtc-native/releases/download/0.3/webrtc_native_0.3_multi-release.zip webrtc_native_0.3_multi-release.zip
		unzip -o -a webrtc_native_0.3_multi-release.zip
		rm webrtc_native_0.3_multi-release.zip
		rm -f webrtc/webrtc.tres
	fi

	if [ "$BUILD" = "debug" -o "$BUILD" = "both" ]; then
		download https://github.com/godotengine/webrtc-native/releases/download/0.3/webrtc_native_0.3_multi-debug.zip webrtc_native_0.3_multi-debug.zip 
		unzip -o -a webrtc_native_0.3_multi-debug.zip
		rm webrtc_native_0.3_multi-debug.zip
		rm -f webrtc_debug/webrtc_debug.tres
	fi
fi

