#!/bin/bash
# Usage: execall.sh "ping -c 3 google.com"
for i in `vzlist -o ctid -H`; do echo -e "\n=============NODE $i==============\n" && vzctl exec $i $1 ; done
