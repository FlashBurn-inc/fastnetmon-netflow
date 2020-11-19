This repository contains two docker images is built on top of alpine image to keep it tiny.

1) **Dockerfile.**
FastNetMon v.1.1.7 is built basically to monitor traffic usage by local network machines and export stats to Graphite. DDOS protection/lua scripting support is turned off.

Note: map volume to /configs folder in container to be able to store custom configs, below files have been linked to correct locations.
- fastnetmon.conf
- networks_list
- notify_about_attack.sh

2) **Dockerfile-exabgp.**
FastNetMon v.1.1.7 is built to monitor and block traffic usage by local network machines and export stats to Graphite. DDOS protection is turned on.

Note: map volume to /configs folder in container to be able to store custom configs, below files have been linked to correct locations.
- fastnetmon.conf
- networks_list
- notify_about_attack.sh
- exabgp_blackhole.conf
