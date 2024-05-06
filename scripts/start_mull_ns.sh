#!/usr/bin/env bash

set -e

# Create wg interface and move it to its namespace
ip netns add mull-wg-ns
ip link add mull-wg type wireguard
ip link set mull-wg netns mull-wg-ns
ip -n mull-wg-ns link set mull-wg up

# Set params relative to our device
ipv4_adr=$(cat /var/tmp/mull-wg/device_ip | awk -F '[,]' '{print $1}')
ipv6_adr=$(cat /var/tmp/mull-wg/device_ip | awk -F '[,]' '{print $2}')
ip -n mull-wg-ns route add default dev mull-wg
ip netns exec mull-wg-ns wg set mull-wg private-key /var/tmp/mull-wg/key
ip -n mull-wg-ns addr add $ipv4_adr dev mull-wg
ip -n mull-wg-ns addr add $ipv6_adr dev mull-wg

# Create virtual lan tunnel out of namespace to init in order to circumvent the vpn for local traffic
ip link add mullwg-veth0 type veth peer name veth1
ip link set veth1 netns mull-wg-ns
ip link set mullwg-veth0 up
ip netns exec mull-wg-ns ip link set veth1 up
ip addr add 10.54.0.1/24 dev mullwg-veth0
ip netns exec mull-wg-ns ip addr add 10.54.0.2/24 dev veth1
echo 1 | tee /proc/sys/net/ipv4/ip_forward 1> /dev/null
iptables -t nat -A POSTROUTING -s 10.54.0.0/24 ! -o mullwg-veth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.54.0.0/24 ! -o lo -j MASQUERADE

# Route private IPs through the veth bridge into the host netns
cat /var/tmp/mull-wg/bypass | xargs -I {} ip netns exec mull-wg-ns ip route add {} via 10.54.0.1
