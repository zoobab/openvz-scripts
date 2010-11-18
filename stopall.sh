#!/bin/bash
# Usage: execall.sh "ping -c 3 google.com"
for i in `vzlist | cut -d" " -f 8`; do echo $i && vzctl stop $i; done
