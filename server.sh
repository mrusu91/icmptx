#!/bin/bash

set -o errexit

SERVER_PUBLIC_IP="PLEASE.FILL.ME.HERE"
TUN="tun0"
TUN_NETMASK="/24"
TUN_NETWORK="10.0.0.0"
SERVER_TUN_IP="10.0.0.1"


function ensure_root() {
  if ! [ $(id -u) = 0 ]; then
    echo "ERROR: needs to run as root"
    return 1
  fi
}

function enable_tun() {
  ip addr add ${SERVER_TUN_IP}${TUN_NETMASK} dev ${TUN}
  ip link set ${TUN} up
}

function enable_nat() {
  iptables \
    -t nat \
    -C POSTROUTING \
    -s ${TUN_NETWORK}${TUN_NETMASK} \
    -j MASQUERADE \
  || \
  iptables \
    -t nat \
    -A POSTROUTING \
    -s ${TUN_NETWORK}${TUN_NETMASK} \
    -j MASQUERADE
  echo "NAT enabled"
}

function disable_nat() {
  iptables \
    -t nat \
    -C POSTROUTING \
    -s ${TUN_NETWORK}${TUN_NETMASK} \
    -j MASQUERADE \
  && \
  iptables \
    -t nat \
    -D POSTROUTING \
    -s ${TUN_NETWORK}${TUN_NETMASK} \
    -j MASQUERADE
  echo "NAT disabled"
}

function cleanup() {
  kill -15 $1 || true
  disable_nat
  echo "ICMP Tunnel stopped"
}


ensure_root

sysctl -wq net.ipv4.ip_forward=1
sysctl -wq net.ipv4.icmp_echo_ignore_all=1

echo "Using server public ip $SERVER_PUBLIC_IP"
icmptx -s ${SERVER_PUBLIC_IP} &
bg_pid=$!
trap "cleanup $bg_pid" EXIT INT TERM

sleep 2
enable_tun
enable_nat
echo "ICMP tunnel started"

echo "Press Ctrl-C to stop it"
wait $bg_pid
echo "...Stopping..."
