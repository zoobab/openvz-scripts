#!/bin/bash

if [ -z "$2" ]; then
	echo usage: $0 ctid ipaddr
	echo example: $0 521 192.168.20.152
	exit
fi

echo "================================================================"
echo "Download a debian Squeeze (6.0) template"
echo "================================================================"
wget http://localhost:8080/debian-6.0-amd64-minimal.tar.gz -O /var/lib/vz/template/cache/debian-6.0-amd64-minimal.tar.gz

echo "================================================================"
echo "Create a new container named $1"
echo "================================================================"
vzctl create $1 --ostemplate debian-6.0-amd64-minimal

echo "================================================================"
echo "Set the hostname"
echo "================================================================"
vzctl set $1 --hostname $1 --save

echo "================================================================"
echo "Set the IP address"
echo "================================================================"
vzctl set $1 --ipadd $2 --save

echo "================================================================"
echo "Set OpenDNS servers 208.67.222.222 and 208.67.220.220"
echo "================================================================"
vzctl set $1 --nameserver 208.67.222.222 --nameserver 208.67.220.220 --save

echo "================================================================"
echo "Stop and start the container named $1 and wait 10 secs"
echo "================================================================"
vzctl stop $1 && vzctl start $1 && sleep 10

echo "================================================================"
echo "Ping test to google.com"
echo "================================================================"
vzctl exec $1 ping -c 3 google.com

echo "================================================================"
echo "Restarting the node $1"
echo "================================================================"
vzctl restart $1

echo "================================================================"
echo "Test command 'ps aux' executed in the node $1"
echo "================================================================"
vzctl exec $1 ps aux
