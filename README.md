This docker image is built on top of alpine image to keep it tiny.

FastNetMon is built basically to monitor traffic usage by local network machines and export stats to Graphite. DDOS protection/lua scripting support is turned off.

Note: map volume to /configs folder in container to be able to store custom configs, below files have been linked to correct locations.
- fastnetmon.conf
- networks_list
- notify_about_attack.sh
