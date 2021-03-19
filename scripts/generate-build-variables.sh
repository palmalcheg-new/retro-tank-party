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

cat << EOF > autoload/Build.gd
extends Node

var encryption_password := '${ENCRYPTION_PASSWORD:-dev}'
EOF

cat << EOF >> autoload/Build.gd
func _ready() -> void:
	OnlineMatch.client_version = '$CLIENT_VERSION'
EOF

if [ -n "$NAKAMA_SERVER_KEY" -a -n "$NAKAMA_HOST" -a -n "$NAKAMA_PORT" ]; then
NAKAMA_SERVER_KEY=$(base64 -d <<< "$NAKAMA_SERVER_KEY")
cat << EOF >> autoload/Build.gd
	Online.nakama_host = '$NAKAMA_HOST'
	Online.nakama_port = $NAKAMA_PORT
	Online.nakama_server_key = '$NAKAMA_SERVER_KEY'
	Online.nakama_scheme = 'https'
	
EOF
fi

if [ -n "$ICE_SERVERS" ]; then
cat << EOF >> autoload/Build.gd
	OnlineMatch.ice_servers = $ICE_SERVERS
EOF
fi

