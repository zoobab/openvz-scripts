#!/bin/bash
# Usage: enabletun.sh CTID
vzctl set $1 --devices c:10:200:rw --save
vzctl stop $1
vzctl set $1 --capability net_admin:on --save
vzctl start $1
vzctl exec $1 mkdir -p /dev/net
vzctl exec $1 mknod /dev/net/tun c 10 200
vzctl exec $1 chmod 600 /dev/net/tun
