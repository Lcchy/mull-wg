ARCHIVED: integrated into dotfiles nixOS configuration.

## Mullvad VPN wireguard split-tunnel via linux namespaces

Disclaimer: This is a personal project, use at your own risk.

The advantage of this approach is that, once set up, routing a program through
the vpn can be done without root access.
DNS requests go to the connected Mullvad server
Default Mullvad server is `de-ber-wg-005`.
The wireguard private key is generated locally and never shared.

#### Install (NixOS):

- Import the derivation from `default.nix` and add to systemPackages
- Import `module.nix` in your config and enable it (https://nixos.wiki/wiki/NixOS_modules)

#### Install (standard way):

- Install scripts and services: `./install.sh`

#### Usage:

- Generate wireguard key and register it with Mullvad: `./login.sh`
- Run a program through the vpn with `firejail --noprofile --netns=mull-wg-ns example_cmd`
- Choose a different vpn server by writing its hostname (find them as /var/tmp/mull-wg/servers/<hostname>.conf) in `/var/tmp/mull-wg/loc`. The systemd filesystem watcher will reload the namespace accordingly.

#### Namespace setup summary:

We initiate the wireguard interface in init (global) namespace and then move it to
our custom namespace so that it remembers to route through init.
We then set up the connection via `wg`, wg-quick seems inapropriate because of its own routing setup.
Debug with:
`sudo ip netns exec mull-wg-ns wg show`
`sudo ip netns exec mull-wg-ns ping wireguard.com`

#### File structure after install:
In `/var/tmp/mullvad-wg`:
- key : contains mullvad wg private key for device, root access.
- device_ip : Assigned Mullvad interface ip for current device, root access.
- servers/*.conf : mullvad wg server infos, unprotected, set by mull-wg-serv.service
- loc : current server setting hostname, unprotected, set by user (or get_device_loc.py, wip)
- scripts/* : program scripts, protected.
start_mull_ns.sh then assembles the above to setup the namespace and connection

#### TODO:

- Look into nsenter to replace firejail
- Look into speedtests for server choice

#### Useful links:

- Wg ns tutorial: https://volatilesystems.org/wireguard-in-a-separate-linux-network-namespace.html
- Wireguard namespace doc: https://www.wireguard.com/netns/#the-new-namespace-solution
- Mullvad api: https://api.mullvad.net/app/documentation/
