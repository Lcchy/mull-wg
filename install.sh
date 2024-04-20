#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"
REPO_DIR="$(pwd)"

sudo mkdir -p $HOME/.config/mull-wg/servers
sudo chown -R $USER:users $HOME/.config/mull-wg/servers
sudo mkdir -p $HOME/.config/mull-wg/scripts

### Mullvad secrets
if ! [ -f $HOME/.config/mull-wg/device_ip ]; then
    sudo touch $HOME/.config/mull-wg/key
    sudo chmod 600 $HOME/.config/mull-wg/key
    wg genkey | sudo tee $HOME/.config/mull-wg/key 1> /dev/null
    wg_pubkey=$(sudo cat $HOME/.config/mull-wg/key | wg pubkey)

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

    sudo touch $HOME/.config/mull-wg/device_ip
    sudo chmod 600 $HOME/.config/mull-wg/device_ip
    echo $response_body | sudo tee $HOME/.config/mull-wg/device_ip 1> /dev/null
fi

sudo cp $REPO_DIR/scripts/* $HOME/.config/mull-wg/scripts/
sudo chmod 644 $HOME/.config/mull-wg/scripts/*

sudo touch $HOME/.config/mull-wg/loc
sudo chown $USER:users $HOME/.config/mull-wg/loc
sudo chmod 644 $HOME/.config/mull-wg/loc
echo "de-ber-wg-005" > $HOME/.config/mull-wg/loc


echo "Installation success."