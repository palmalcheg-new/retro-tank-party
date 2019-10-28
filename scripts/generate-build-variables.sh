#!/bin/bash

NAKAMA_SERVER_KEY=$(base64 -d <<< "$NAKAMA_SERVER_KEY")

cat << EOF > Build.gd
extends Node

var NAKAMA_HOST = '$NAKAMA_HOST'
var NAKAMA_PORT = $NAKAMA_PORT
var NAKAMA_SERVER_KEY = '$NAKAMA_SERVER_KEY'
var NAKAMA_USE_SSL = true

EOF

