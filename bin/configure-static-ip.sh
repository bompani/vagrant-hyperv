#!/bin/sh
. /etc/os-release

echo 'Setting static IP address for Hyper-V... '

case $ID_LIKE in

  *debian*)
cat << EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses: [$1/24]
      gateway4: 10.42.100.1
      nameservers:
        addresses: [137.204.25.71,137.204.25.213,137.204.25.77]
EOF
    ;;
  *rhel*)
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
BOOTPROTO=none
ONBOOT=yes
PREFIX=24
IPADDR=$1
GATEWAY=10.42.100.1
DNS1=137.204.25.213
DNS2=8.8.4.4
DNS3=137.204.25.77
EOF
    ;;
esac
