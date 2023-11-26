#!/bin/bash
set -e

cd "$(dirname "$0")"
REPO_DIR="$(pwd)"

sudo mkdir -p /etc/mull-wg/servers
sudo chown -R $USER:$USER /etc/mull-wg/servers
sudo mkdir -p /etc/mull-wg/scripts

### Mullvad secrets
if ! [ -f /etc/mull-wg/key ]; then
    sudo touch /etc/mull-wg/key
    sudo chmod 600 /etc/mull-wg/key
    wg genkey | sudo tee /etc/mull-wg/key 1> /dev/null
    wg_pubkey=$(sudo cat /etc/mull-wg/key | wg pubkey)

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

    sudo touch /etc/mull-wg/device_ip
    sudo chmod 600 /etc/mull-wg/device_ip
    echo $response_body | sudo tee /etc/mull-wg/device_ip 1> /dev/null
fi

# Install scripts
sudo cp $REPO_DIR/scripts/* /etc/mull-wg/scripts/
sudo chmod 644 /etc/mull-wg/scripts/*

# Services
sudo touch /etc/mull-wg/loc
sudo chown $USER:$USER /etc/mull-wg/loc
sudo chmod 644 /etc/mull-wg/loc
echo "de-ber-wg-005" > /etc/mull-wg/loc
cp $REPO_DIR/systemd/mull-wg-serv.service ~/.config/systemd/user/
cp $REPO_DIR/systemd/mull-wg-serv.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl start --user mull-wg-serv.service
systemctl enable --user --now mull-wg-serv.timer

sudo cp $REPO_DIR/systemd/mull-wg-ns.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now mull-wg-ns.service

echo "Installation success."