#!/bin/bash

if [ -z "$NAKAMA_SERVER_KEY" -o -z "$NAKAMA_HOST" -o -z "$NAKAMA_PORT" -o -z "$ICE_SERVER" ]; then
	exit 0
fi

NAKAMA_SERVER_KEY=$(base64 -d <<< "$NAKAMA_SERVER_KEY")

# Use the Git hash if no CLIENT_VERSION is given.
if [ -z "$CLIENT_VERSION" ]; then
	# GitLab CI:
	if [ -n "$CI_COMMIT_SHA" ]; then
		CLIENT_VERSION="$CI_COMMIT_SHA"

	# GitHub Actions:
	elif [ -n "$GITHUB_SHA" ]; then
		CLIENT_VERSION="$GITHUB_SHA"
	fi
fi

cat << EOF > autoload/Build.gd
extends Node

func _ready() -> void:
	Online.nakama_host = '$NAKAMA_HOST'
	Online.nakama_port = $NAKAMA_PORT
	Online.nakama_server_key = '$NAKAMA_SERVER_KEY'
	Online.nakama_scheme = 'https'
	
	OnlineMatch.client_version = '$CLIENT_VERSION'

	OnlineMatch.ice_servers = [
		{
			"urls": ["$ICE_SERVER"],
			"username": "$ICE_SERVER_USERNAME",
			"credentials": "$ICE_SERVER_CREDENTIALS",
			# GDNative WebRTC plugin erroneously uses 'credential' (with the 's')
			# See: https://github.com/godotengine/webrtc-native/pull/26
			"credential": "$ICE_SERVER_CREDENTIALS",
		},
	]

EOF

