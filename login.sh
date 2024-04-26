#!/usr/bin/env bash
set -e

### Mullvad secrets
if ! [ -f /var/tmp/mull-wg/device_ip ]; then
    sudo touch /var/tmp/mull-wg/key
    sudo chmod 600 /var/tmp/mull-wg/key
    wg genkey | sudo tee /var/tmp/mull-wg/key 1> /dev/null
    wg_pubkey=$(sudo cat /var/tmp/mull-wg/key | wg pubkey)

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

    sudo touch /var/tmp/mull-wg/device_ip
    sudo chmod 600 /var/tmp/mull-wg/device_ip
    echo $response_body | sudo tee /var/tmp/mull-wg/device_ip 1> /dev/null

    sudo touch /var/tmp/mull-wg/loc
    sudo chown $USER:users /var/tmp/mull-wg/loc
    sudo chmod 644 /var/tmp/mull-wg/loc
    echo "de-ber-wg-005" > /var/tmp/mull-wg/loc

    echo "Success!"
else
    echo "Already found some login in /var/tmp/mull-wg/device_ip . Delete it to relogin."
fi
