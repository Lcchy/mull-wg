#!/usr/bin/env bash

set -e

if [ ! -f "/var/tmp/mull-wg/device_ip" ]; then
    echo "No login found."
    return 1
fi

ipv4_adr=$(cat /var/tmp/mull-wg/device_ip | awk -F '[,]' '{print $1}')
ipv6_adr=$(cat /var/tmp/mull-wg/device_ip | awk -F '[,]' '{print $2}')
serv_hostname=$(cat /var/tmp/mull-wg/loc)
serv_conf_path=/var/tmp/mull-wg/servers/$serv_hostname.conf
serv_pubkey=$(sed -n "2p" "$serv_conf_path")
serv_addr=$(sed -n "3p" "$serv_conf_path")

ip netns add mull-wg-ns
ip link add mull-wg type wireguard
wg set mull-wg private-key /var/tmp/mull-wg/key
wg set mull-wg peer $serv_pubkey allowed-ips 0.0.0.0/0,::0/0
wg set mull-wg peer $serv_pubkey endpoint $serv_addr
ip link set mull-wg netns mull-wg-ns
ip -n mull-wg-ns addr add $ipv4_adr dev mull-wg
ip -n mull-wg-ns addr add $ipv6_adr dev mull-wg
ip -n mull-wg-ns link set mull-wg up
ip -n mull-wg-ns route add default dev mull-wg

# Create virtual lan tunnel out of namespace to init in order to circumvent the vpn for local traffic
ip link add mullwg-veth0 type veth peer name veth1
ip link set veth1 netns mull-wg-ns
ip link set mullwg-veth0 up
ip netns exec mull-wg-ns ip link set veth1 up
ip addr add 10.54.0.1/24 dev mullwg-veth0
ip netns exec mull-wg-ns ip addr add 10.54.0.2/24 dev veth1
echo 1 | tee /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -s 10.54.0.0/24 ! -o mullwg-veth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.54.0.0/24 ! -o lo -j MASQUERADE
ip netns exec mull-wg-ns ip route add 100.64.0.0/10 via 10.54.0.1 # tailscale
ip netns exec mull-wg-ns ip route add 10.177.0.0/16 via 10.54.0.1 # linode
ip netns exec mull-wg-ns ip route add 172.16.0.0/12 via 10.54.0.1
ip netns exec mull-wg-ns ip route add 192.168.0.0/16 via 10.54.0.1
ip netns exec mull-wg-ns ip route add 127.0.0.0/8 via 10.54.0.1 # =localhost, does not seem to work