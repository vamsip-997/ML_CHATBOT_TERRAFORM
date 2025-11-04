#!/usr/bin/env bash
# simple ping script: ./ping.sh [host] [count]
HOST="${1:-google.com}"
COUNT="${2:-4}"

if ! command -v ping >/dev/null 2>&1; then
    echo "ping command not found" >&2
    exit 1
fi

echo "Pinging $HOST ($COUNT times)..."
ping "$COUNT" "$HOST"-c 