Inspired by PortSSHare by davidhfrankelcodes: https://github.com/davidhfrankelcodes/portsshare

Burrow SSH provides the same functionality with a simplified format for the tunnels which is ready in one go into an array. It also has a built in healthcheck.

Format for tunnels.conf file:

```
# Format: "Local/RemoteTunnel user  host  ssh_port  local_port  remote_port"
#
TUNNELS=(
  # Tunnel 1 - Server x App y
  "L"	"user1"	"123.123.123.123"	"22"	"10001"	"2226"
  # Tunnel 2 - server y App Dozzle 
  "L"	"user2"	"124.124.124.124"	"22"	"10002"	"9999"
  # adminer - Server x 
  "L"	"user3"	"125.125.125.125"	"22"	"10003"	"8081"
)
```
Example compose.yaml file:
```
services:
  burrow-tunnels:
    container_name: burrow
    image: beastarman/burrow:latest
    restart: unless-stopped
    environment:
      # set SSHKEY variable from .env file
      SSHKEY: ${SSHKEY}
    volumes:
      # mount keys folder into the container. 1 key for all connections 
      - ./keys:/root/.ssh
      # mount the tunnel configuration file into the container
      - ./tunnels.conf:/config/tunnels.conf 
    ports:
      # set number of ports as required
      - 10000-10050:10000-10050
```

