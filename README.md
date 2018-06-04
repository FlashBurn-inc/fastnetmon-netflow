This docker image is built on top of alpine image to keep it tiny.

FastNetMon is built basically to monitor traffic usage by local network machines and export stats to Graphite. DDOS protection/lua scripting support is turned off.

Following environment variables are expected to be passed to container:

- LOCAL_NETWORKS="192.168.0.0/24\n172.16.0.0/24"

  Your local networks to be monitored for traffic usage. Separated by \n since it is passed as is to fastnetmon's /etc/networks_list file

- GRAPHITE="graphite.server.address"

  FQDN or IP address of graphite server to export metrics to.
