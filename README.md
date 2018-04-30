# icmptx

Useful scripts for IP-over-ICMP tunnel

## WARNING
icmptx tunnel is **not secure!** You should use a VPN  on top of this tunnel

## How to use it
* Install icmptx on both client and server machines:
  - Ubuntu: `sudo apt install icmptx`
* Double check the `.sh` files
* Run `server.sh` on the server machine
* Run `client.sh` on the client machine

## Notes
* If your server is an AWS EC2 instance, make sure `Source/Dest check` is disabled.
