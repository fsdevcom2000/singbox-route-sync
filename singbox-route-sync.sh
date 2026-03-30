#!/bin/bash

LOGFILE="/var/log/singbox-route-sync.log"
MIKROTIK_HOST="192.168.0.1"
MIKROTIK_USER="route-sync"
MIKROTIK_PASS="YOUR_PASSWORD"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOGFILE"
}

log "=== Starting route update ==="

# Waiting for the singbox0 interface to appear.
for i in {1..20}; do
    if ip link show singbox0 >/dev/null 2>&1; then
        log "Interface singbox0 found"
        break
    fi
    sleep 1
done

if ! ip link show singbox0 >/dev/null 2>&1; then
    log "ERROR: singbox0 interface never appeared"
    exit 1
fi

# Getting a list of addresses from a MikroTik router
RAW=$(sshpass -p "$MIKROTIK_PASS" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
    $MIKROTIK_USER@$MIKROTIK_HOST "/ip firewall address-list print where list=proxy" 2>&1)

if [ $? -ne 0 ]; then
    log "ERROR SSH: $RAW"
    exit 1
fi

log "Data received from MikroTik router"

# Parse only IPs and subnets
NETS=$(echo "$RAW" \
    | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?' \
    | grep -vE '^10\.|^192\.168\.|^172\.(1[6-9]|2[0-9]|3[0-1])\.')


if [ -z "$NETS" ]; then
    log "ERROR: Address list is empty - routes not updated"
    exit 1
fi

log "Found $(echo "$NETS" | wc -l) subnets"

# Update routes
for net in $NETS; do
    if ip route replace "$net" dev singbox0 2>/dev/null; then
        log "The route has been updated:: $net"
    else
        log "ERROR: Failed to update route $net"
    fi
done

log "=== Route update completed ==="
