#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"
REPO_DIR="$(pwd)"

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