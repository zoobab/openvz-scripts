#!/bin/bash
set -e
####################################################################################
if [ -z "$3" ]; then
    echo usage: $0 distro YYYYMMDDTHHMMSSZ server_root_url
    echo example: $0 squeeze 20111201T040728Z http://snapshot.debian.org/archive/debian/
    exit
fi
####################################################################################
CTID="999"
HOSTNAME="minimal"
ARCH="amd64"
VER="$1"
IPADDR="192.168.20.1"
VZROOT="/var/lib/vz"
VZROOT_PRIVATE="${VZROOT}/private"
VZROOT_CACHE="${VZROOT}/template/cache"
TIMESTAMP="$2"
SERVER_ROOT_URL="$3"
SNAP_DATE="`echo ${TIMESTAMP} | cut -d "T" -f1`"
SNAP_TIME="`echo ${TIMESTAMP} | sed -e s/${SNAP_DATE}//g`"
SERVER="${SERVER_ROOT_URL}${SNAP_DATE}${SNAP_TIME}/"
OUTPUT="debian-${VER}-${TIMESTAMP}-${ARCH}-${BUILD_NUMBER}"
OUTPUT_TAR="${OUTPUT}.tgz"
####################################################################################
function banner {
echo "================================================================"
echo "$1"
echo "================================================================"
}
####################################################################################
banner "Cleanup of the previous $HOSTNAME containers"
if vzlist -H -a -o ctid | grep $CTID;
then
    LIST_SAME_CTID="`vzlist -H -a -o ctid | grep $CTID`"
    echo "Lisf of previous $HOSTNAME containers:"
    for i in "$LIST_SAME_CTID"; do echo $i; done
    echo "Destroying previous $HOSTNAME containers with same $CTID:"
    for i in "`vzlist -H -a -o ctid | grep $CTID | awk '{print($1)}'`"; do vzctl stop $i && vzctl destroy $i; done
fi
####################################################################################
banner "debootstrap an $ARCH $VER in CT $CTID"
debootstrap --arch $ARCH --components="main,contrib,non-free" $VER ${VZROOT_PRIVATE}/$CTID $SERVER 
####################################################################################
banner "Unlimited template"
touch /etc/vz/conf/$CTID.conf
vzctl set $CTID --applyconfig unlimited --save
####################################################################################
banner "Set OSTEMPLATE variable in $CTID config file"
echo "OSTEMPLATE=debian" >> /etc/vz/conf/$CTID.conf
####################################################################################
banner "Set a temporary IP address $IPADDR"
vzctl set $CTID --ipadd $IPADDR --save
####################################################################################
echo "Set the Google DNS server"
vzctl set $CTID --nameserver 8.8.8.8 --nameserver 8.8.4.4 --save
####################################################################################
banner "Starting the CT $CTID"
vzctl start 999
sleep 15
####################################################################################
banner "disable getty"
vzctl exec $CTID "sed -i -e '/getty/d' /etc/inittab"
####################################################################################
banner "Fix /etc/mtab"
vzctl exec $CTID "rm -f /etc/mtab"
vzctl exec $CTID "ln -s /proc/mounts /etc/mtab"
####################################################################################
banner "Change the timezone"
vzctl exec $CTID "ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime"
####################################################################################
banner "Stop the CT $CTID"
vzctl stop $CTID
####################################################################################
banner "Unset any IP address"
vzctl set $CTID --ipdel all --save
####################################################################################
banner "Creating a tar file ${OUTPUT_TAR}"
mkdir -pv ${WORKSPACE}/${BUILD_TAG}
vzdump --compress $CTID --dumpdir "${WORKSPACE}/${BUILD_TAG}/" 
mv ${WORKSPACE}/${BUILD_TAG}/*.tgz  ${WORKSPACE}/${BUILD_TAG}/${OUTPUT_TAR}
cp -v ${WORKSPACE}/${BUILD_TAG}/${OUTPUT_TAR} ${VZROOT_CACHE}/${OUTPUT_TAR}
chown -Rv ${HUDSON_USER}.${HUDSON_GROUP} ${WORKSPACE}/
####################################################################################
banner "How big is the generated tar file?"
ls -lh ${VZROOT_CACHE}/${OUTPUT_TAR}
####################################################################################
banner "Destroy $CTID"
vzctl destroy $CTID
####################################################################################
banner "The end"
####################################################################################
