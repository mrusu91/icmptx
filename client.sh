#!/bin/bash

set -o errexit

SERVER_PUBLIC_IP="PLEASE.FILL.ME.HERE"
TUN="tun0"
TUN_NETMASK="/24"
SERVER_TUN_IP="10.0.0.1"
CLIENT_TUN_IP="10.0.0.2"

DEFAULT_GW="$(ip route list | grep default | awk '{print $3}')"


function ensure_root() {
  if ! [ $(id -u) = 0 ]; then
    echo "ERROR: needs to run as root"
    return 1
  fi
}

function enable_tun() {
  ip addr add ${CLIENT_TUN_IP}${TUN_NETMASK} dev ${TUN}
  ip link set ${TUN} up
}

function add_routes() {
  ip route add ${SERVER_PUBLIC_IP} via ${DEFAULT_GW}
  ip route replace default via ${SERVER_TUN_IP}
  echo "Routes Added"
}

function remove_routes() {
  ip route delete ${SERVER_PUBLIC_IP} via ${DEFAULT_GW}
  ip route replace default via ${DEFAULT_GW}
  echo "Routes removed"
}

function cleanup() {
  kill -15 $1 || true
  remove_routes
  echo "ICMP Tunnel stopped"
}


ensure_root

sysctl -wq net.ipv4.ip_forward=1
sysctl -wq net.ipv4.icmp_echo_ignore_all=1

echo "Using server public ip $SERVER_PUBLIC_IP"
icmptx -c ${SERVER_PUBLIC_IP} &
bg_pid=$!
trap "cleanup $bg_pid" EXIT INT TERM

sleep 2
enable_tun
add_routes
echo "ICMP tunnel started"

echo "Press Ctrl-C to stop it"
wait $bg_pid
echo "...Stopping..."
