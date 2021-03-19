#!/bin/bash

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

BUILD_FILE=src/autoload/Build.gd

cat << EOF > $BUILD_FILE
extends Node

var encryption_password := '${ENCRYPTION_PASSWORD:-dev}'
EOF

cat << EOF >> $BUILD_FILE
func _ready() -> void:
	OnlineMatch.client_version = '$CLIENT_VERSION'
EOF

if [ -n "$NAKAMA_SERVER_KEY" -a -n "$NAKAMA_HOST" -a -n "$NAKAMA_PORT" ]; then
NAKAMA_SERVER_KEY=$(base64 -d <<< "$NAKAMA_SERVER_KEY")
cat << EOF >> $BUILD_FILE
	Online.nakama_host = '$NAKAMA_HOST'
	Online.nakama_port = $NAKAMA_PORT
	Online.nakama_server_key = '$NAKAMA_SERVER_KEY'
	Online.nakama_scheme = 'https'
	
EOF
fi

if [ -n "$ICE_SERVERS" ]; then
cat << EOF >> $BUILD_FILE
	OnlineMatch.ice_servers = $ICE_SERVERS
EOF
fi

