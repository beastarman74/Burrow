#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-/config/tunnels.conf}"
SSH_DIR="${SSH_DIR:-/root/.ssh}"

echo "Starting Burrow Tunnel manager..."

cleanup() {
    echo "Received termination signal. Stopping tunnels..."
    local pids=$(jobs -p)
    if [[ -n "$pids" ]]; then
        kill $pids 2>/dev/null || true
    fi
    echo "All tunnels stopped. Exiting."
    exit 0
}

trap cleanup SIGTERM SIGINT

if [[ -z "${SSHKEY:-}" ]]; then
    echo "Error: SSHKEY environment variable is not set." >&2
    exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file $CONFIG_FILE not found." >&2
    exit 1
fi

source "$CONFIG_FILE"

setup_tunnel() {
    local type="${1^^}" # Convert to uppercase
    local user="$2"
    local host="$3"
    local port="$4"
    local listen_port="$5"
    local dest_port="$6"

    local tunnel_arg=""

    if [[ "$type" == "L" ]]; then
        tunnel_arg="-L *:${listen_port}:localhost:${dest_port}"
        echo "Setup [LOCAL]  ${user}@${host}:${port} | Listening locally on ${listen_port} -> Forwarding to remote ${dest_port}"
    elif [[ "$type" == "R" ]]; then
        tunnel_arg="-R *:${listen_port}:localhost:${dest_port}"
        echo "Setup [REMOTE] ${user}@${host}:${port} | Listening remotely on ${listen_port} -> Forwarding to local ${dest_port}"
    else
        echo "Error: Unknown tunnel type '$type'. Must be 'L' or 'R'." >&2
        return 1
    fi

    autossh -NT -M 0 \
        -i "${SSH_DIR}/${SSHKEY}" \
        -o "ServerAliveInterval=60" \
        -o "ServerAliveCountMax=2" \
        -o "StrictHostKeyChecking=no" \
        -o "ExitOnForwardFailure=yes" \
        $tunnel_arg \
        -p "${port}" "${user}@${host}" &
}

TOTAL_ELEMENTS=${#TUNNELS[@]}
CHUNK_SIZE=6 # Increased to 6 to account for the 'Type' parameter

if [[ "$TOTAL_ELEMENTS" -eq 0 ]]; then
    echo "Error: TUNNELS array is empty." >&2
    exit 1
fi

if (( TOTAL_ELEMENTS % CHUNK_SIZE != 0 )); then
    echo "Error: TUNNELS array missing parameters. Elements ($TOTAL_ELEMENTS) not a multiple of $CHUNK_SIZE." >&2
    exit 1
fi

for (( i=0; i<TOTAL_ELEMENTS; i+=CHUNK_SIZE )); do
    t_type="${TUNNELS[i]}"
    t_user="${TUNNELS[i+1]}"
    t_host="${TUNNELS[i+2]}"
    t_port="${TUNNELS[i+3]}"
    t_listen="${TUNNELS[i+4]}"
    t_dest="${TUNNELS[i+5]}"

    setup_tunnel "$t_type" "$t_user" "$t_host" "$t_port" "$t_listen" "$t_dest"
done

echo "All configured burrows initiated."

while true; do
    wait -n || true
done
