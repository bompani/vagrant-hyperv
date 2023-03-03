#!/bin/bash

MACADDRESS=""
IP=""
NETMASK="" 

usage() {
  echo "Usage: $0  -m MAC-Address -i IP-Address -n netmask" 1>&2 
}

exit_abnormal() {
  usage
  exit 1
}

while getopts "m:i:n:" options; do 
  case "${options}" in
    m)
      MACADDRESS=${OPTARG}
      ;;
    i)
      IP=${OPTARG}
      ;;
    n)
      NETMASK=${OPTARG}
      ;;
    :)
      echo "Error: -${OPTARG} requires an argument."
      exit_abnormal
      ;;
    *)
      exit_abnormal
      ;;
  esac
done

if [ "$MACADDRESS" = "" ] || [ "$IP" = "" ] || [ "$NETMASK" = "" ]; then
  echo "Error: missing required argument."
  exit_abnormal
fi

interfaceMAC=$(echo "$MACADDRESS" | sed -r 's/-/:/g' | tr '[:upper:]' '[:lower:]')
interface=$(ip -br link | awk "\$3 ~ /$interfaceMAC/ {print \$1}")
if [ -z "$interface" ]
then
  echo "Did not find interface"
  exit 1
fi

. /etc/os-release

echo 'Setting static IP address for Hyper-V... '

case $ID_LIKE in

  *debian*)
cat << EOF > /etc/netplan/01-netcfg-$interface.yaml
network:
  version: 2
  ethernets:
    $interface:
      dhcp4: no
      addresses: [$IP/$NETMASK]
EOF
    ;;
  *rhel*)
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-$interface
DEVICE=$interface
BOOTPROTO=none
ONBOOT=yes
PREFIX=$NETMASK
IPADDR=$IP
EOF
    ;;
esac


exit 0