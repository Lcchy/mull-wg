#!/usr/bin/env bash

set -e

if [ ! -f "/var/tmp/mull-wg/device_ip" ]; then
    echo "No login found."
    exit 1
fi

serv_hostname=$(cat /var/tmp/mull-wg/loc)
serv_conf_path=/var/tmp/mull-wg/servers/$serv_hostname.conf
serv_pubkey=$(sed -n "2p" "$serv_conf_path")
serv_addr=$(sed -n "3p" "$serv_conf_path")

# Remove all previous peers
ip netns exec mull-wg-ns wg show mull-wg peers | awk '{print $1}' | xargs -I {} ip netns exec mull-wg-ns wg set mull-wg peer {} remove

ip netns exec mull-wg-ns wg set mull-wg peer $serv_pubkey allowed-ips 0.0.0.0/0,::0/0
ip netns exec mull-wg-ns wg set mull-wg peer $serv_pubkey endpoint $serv_addr
