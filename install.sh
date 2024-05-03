#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"
REPO_DIR="$(pwd)"

mkdir -p /var/tmp/mull-wg/scripts
cp $REPO_DIR/scripts/* /var/tmp/mull-wg/scripts/
chmod 644 /var/tmp/mull-wg/scripts/*
chown -R root:root /var/tmp/mull-wg/scripts

# Services
cp $REPO_DIR/systemd/mull-wg-serv.service ~/.config/systemd/user/
cp $REPO_DIR/systemd/mull-wg-serv.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl start --user mull-wg-serv.service
systemctl enable --user --now mull-wg-serv.timer

sudo cp $REPO_DIR/systemd/mull-wg-ns.service /etc/systemd/system/
sudo cp $REPO_DIR/systemd/mull-wg-watcher.* /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now mull-wg-ns.service
sudo systemctl enable --now mull-wg-watcher.{path,service}

echo "Setting standard local IP ranges to bypass VPN. Edit them in /var/tmp/bypass"
cat <<EOF > /var/tmp/mull-wg/bypass
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
EOF

echo "Installation success."
