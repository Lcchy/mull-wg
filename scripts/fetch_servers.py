import requests

mull_conf_path = "/etc/mull-wg/servers/"

# Fetch server locations from Mullvad API
mullvad_response = requests.get("https://api.mullvad.net/public/relays/wireguard/v2")
mull_data = mullvad_response.json()

for mull_relay in mull_data["wireguard"]["relays"]:
    conf_str = "# Publickey, endpoint addr\n"
    conf_str += "{}\n".format(mull_relay["public_key"])
    conf_str += "{}:51820\n".format(mull_relay["ipv4_addr_in"])
    with open(mull_conf_path + mull_relay["hostname"] + ".conf", "w") as f:
        f.write(conf_str)
