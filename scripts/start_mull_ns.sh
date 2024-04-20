#!/usr/bin/env bash

set -e

ipv4_adr=$(sudo cat $HOME/.config/mull-wg/device_ip | awk -F '[,]' '{print $1}')
ipv6_adr=$(sudo cat $HOME/.config/mull-wg/device_ip | awk -F '[,]' '{print $2}')
serv_hostname=$(cat $HOME/.config/mull-wg/loc)
serv_conf_path=$HOME/.config/mull-wg/servers/$serv_hostname.conf
serv_pubkey=$(sudo sed -n "2p" "$serv_conf_path")
serv_addr=$(sudo sed -n "3p" "$serv_conf_path")

sudo ip netns add mull-wg-ns
sudo ip link add mull-wg type wireguard
sudo wg set mull-wg private-key $HOME/.config/mull-wg/key
sudo wg set mull-wg peer $serv_pubkey allowed-ips 0.0.0.0/0,::0/0
sudo wg set mull-wg peer $serv_pubkey endpoint $serv_addr
sudo ip link set mull-wg netns mull-wg-ns
sudo ip -n mull-wg-ns addr add $ipv4_adr dev mull-wg
sudo ip -n mull-wg-ns addr add $ipv6_adr dev mull-wg
sudo ip -n mull-wg-ns link set mull-wg up
sudo ip -n mull-wg-ns route add default dev mull-wg

# Create virtual lan tunnel out of namespace to init in order to circumvent the vpn for local traffic
sudo ip link add mullwg-veth0 type veth peer name veth1
sudo ip link set veth1 netns mull-wg-ns
sudo ip link set mullwg-veth0 up
sudo ip netns exec mull-wg-ns ip link set veth1 up
sudo ip addr add 10.54.0.1/24 dev mullwg-veth0
sudo ip netns exec mull-wg-ns ip addr add 10.54.0.2/24 dev veth1
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo iptables -t nat -A POSTROUTING -s 10.54.0.0/24 ! -o mullwg-veth0 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -s 10.54.0.0/24 ! -o lo -j MASQUERADE
sudo ip netns exec mull-wg-ns ip route add 100.64.0.0/10 via 10.54.0.1 # tailscale
sudo ip netns exec mull-wg-ns ip route add 10.177.0.0/16 via 10.54.0.1 # linode
sudo ip netns exec mull-wg-ns ip route add 172.16.0.0/12 via 10.54.0.1
sudo ip netns exec mull-wg-ns ip route add 192.168.0.0/16 via 10.54.0.1
sudo ip netns exec mull-wg-ns ip route add 127.0.0.0/8 via 10.54.0.1 # =localhost, does not seem to work