## Mullvad VPN wireguard setup

Disclaimer: This is purely a personal project, use at your own risk.

The advantage of this approach is that, once set up, routing a program through
the vpn can be done without root access. 
DNS is not set in the namespace so your system DNS will leak through the connection.
Default Mulllvad server is `de-ber-wg-005`.
The wireguard private key is generated locally and never shared.

#### Usage:

- Run once: `./install.sh`
- Route a program through the vpn with `firejail --noprofile --netns=mull-wg-ns example_cmd`
- Choose a different vpn server by writing its hostname (find them in /etc/mull-wg/servers/<hostname>.conf) into `/etc/mull-wg/loc`

#### Namespace setup:

We initiate the wireguard interface in init (global) namespace and then move it to
our custom namespace so that it remembers to route through init.
We then set up the connection via `wg`, wg-quick seems inapropriate because of its own routing setup.
Debug with:
sudo ip netns exec mull-wg-ns wg show
sudo ip netns exec mull-wg-ns ping google.com

#### File structure after install:
In /etc/mullvad-wg:
- key : contains mullvad wg private key for device, root access.
- device_ip : Assigned Mullvad interface ip for current device, root access.
- servers/*.conf : mullvad wg server infos, unprotected, set by mull-wg-serv.service
- loc : current server setting hostname, unprotected, set by user (or get_device_loc.py, wip)
- scripts/* : program scripts, protected.
start_mull_ns.sh then assembles the above to setup namespace and connection

#### TODO:

- Add script for choosing mullvad server interactively
- Integrate location script to choose server automatically
- Look into nsenter to replace firejail
- Look into speedtests for auto choice of server

#### Useful links:

- Wg ns tutorial: https://volatilesystems.org/wireguard-in-a-separate-linux-network-namespace.html
- Wireguard namespace doc: https://www.wireguard.com/netns/#the-new-namespace-solution
- Mullvad api: https://api.mullvad.net/app/documentation/
