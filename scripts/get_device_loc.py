## WIP

import requests
import json
import pycountry
from geopy.distance import geodesic
import subprocess
import os, stat
import sys
import gi

gi.require_version("Geoclue", "2.0")
from gi.repository import Geoclue

# Fetch device location from d-bus geoclue Mozilla MLS
clue = Geoclue.Simple.new_sync("something", Geoclue.AccuracyLevel.EXACT, None)
location = clue.get_location()
curr_lat = location.get_property("latitude")
curr_long = location.get_property("longitude")
if False:
    # As a backup, fetch location data from ipinfo.io
    response = requests.get("http://ipinfo.io")
    data = response.json()
    curr_lat, curr_long = data["loc"].split(",")
curr_pos = (float(curr_lat), float(curr_long))

# Fetch server locations from Mullvad API
mullvad_response = requests.get("https://api.mullvad.net/public/relays/wireguard/v2")
mull_data = mullvad_response.json()

# Find closest vpn server
min_dist = 40075.017 / 2 + 1  # earth circonference
curr_best = ""
for mull_key, mull_loc in mull_data["locations"].items():
    mull_pos = (mull_loc["latitude"], mull_loc["longitude"])
    dist = geodesic(curr_pos, mull_pos).km
    if dist < min_dist:
        min_dist = dist
        curr_best = mull_key
mull_match = mull_data["locations"][curr_best]
match_city = mull_match["city"]
match_country = mull_match["country"]
print(json.dumps(mull_data["wireguard"]["relays"], indent=4))
for mull_relay in mull_data["wireguard"]["relays"]:
    if mull_relay["location"] == curr_best:
        match_wg_conf = mull_relay
print(
    f'Current location: {curr_pos}, Match found: {match_wg_conf["hostname"]} {match_city}/{match_country}, Distance {min_dist}km'
)
