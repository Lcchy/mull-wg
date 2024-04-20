#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"
REPO_DIR="$(pwd)"

sudo mkdir -p /var/mull-wg/servers
sudo chown -R $USER:users /var/mull-wg/servers
sudo mkdir -p /var/mull-wg/scripts

### Mullvad secrets
if ! [ -f /var/mull-wg/device_ip ]; then
    sudo touch /var/mull-wg/key
    sudo chmod 600 /var/mull-wg/key
    wg genkey | sudo tee /var/mull-wg/key 1> /dev/null
    wg_pubkey=$(sudo cat /var/mull-wg/key | wg pubkey)

    # Get assigned ip in mullvad network for our device
    read -sp "Enter Mullvad account number: " mull_acc_nb
    response=$(curl -s -w "\n%{http_code}" https://api.mullvad.net/wg/ -d account=$mull_acc_nb --data-urlencode pubkey=$wg_pubkey)
    response_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | sed '$d')
    if [ $response_code -ne 201 ]
    then
        echo $response_body > /dev/stderr
        exit 1
    fi

    sudo touch /var/mull-wg/device_ip
    sudo chmod 600 /var/mull-wg/device_ip
    echo $response_body | sudo tee /var/mull-wg/device_ip 1> /dev/null
fi

sudo cp $REPO_DIR/scripts/* /var/mull-wg/scripts/
sudo chmod 644 /var/mull-wg/scripts/*

sudo touch /var/mull-wg/loc
sudo chown $USER:users /var/mull-wg/loc
sudo chmod 644 /var/mull-wg/loc
echo "de-ber-wg-005" > /var/mull-wg/loc


echo "Installation success."