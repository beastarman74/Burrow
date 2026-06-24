#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-/config/tunnels.conf}"

if [[ ! -f "$CONFIG_FILE" ]]; then
    exit 1
fi

source "$CONFIG_FILE"

TOTAL_ELEMENTS=${#TUNNELS[@]:-0}
CHUNK_SIZE=6 # Match the new chunk size

if [[ "$TOTAL_ELEMENTS" -eq 0 ]]; then
    exit 1
fi

for (( i=0; i<TOTAL_ELEMENTS; i+=CHUNK_SIZE )); do
    t_type="${TUNNELS[i]}"
    t_listen="${TUNNELS[i+4]}"
    
    # We only check 'L' (Local) tunnels.
    if [[ "${t_type^^}" == "L" ]]; then
        if ! timeout 2 bash -c "</dev/tcp/127.0.0.1/$t_listen" 2>/dev/null; then
            echo "Healthcheck failed: Local port $t_listen is not accepting connections."
            exit 1
        fi
    fi
done

echo "All local tunnel ports are healthy."
exit 0
