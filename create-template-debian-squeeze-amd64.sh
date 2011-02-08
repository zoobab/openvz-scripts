#!/bin/bash
CTID="999"
ARCH="amd64"
VER="squeeze"
TMPIP="192.168.20.1"
TMPCT="123456"
VZROOT="/var/lib/vz/private"

set -x

echo "cleaning the CT $TMPCT"
vzctl stop $TMPCT
vzctl destroy $TMPCT

echo "cleaning the CT $CTID"
vzctl stop $CTID
vzctl destroy $CTID

echo "debootstrap an $ARCH $VER in CT $CTID"
debootstrap --arch $ARCH $VER $VZROOT/$CTID http://ftp.de.debian.org/debian/

echo "Unlimited template"
touch /etc/vz/conf/$CTID.conf
vzctl set $CTID --applyconfig unlimited --save
echo "DISK_QUOTA=no" >> /etc/vz/conf/$CTID.conf

echo "Debian 6.0 config file"
cat << EOF > /etc/vz/dists/debian-6.0.conf
ADD_IP=debian-add_ip.sh
DEL_IP=debian-del_ip.sh
SET_HOSTNAME=debian-set_hostname.sh
SET_DNS=set_dns.sh
SET_USERPASS=set_userpass.sh
SET_UGID_QUOTA=set_ugid_quota.sh
POST_CREATE=postcreate.sh
EOF

echo "OSTEMPLATE=debian-6.0" >> /etc/vz/conf/$CTID.conf

echo "Set a temporary IP address $TMPIP"
vzctl set $CTID --ipadd $TMPIP --save

echo "Set the OpenDNS server"
vzctl set $CTID --nameserver 208.67.222.222 --nameserver 208.67.220.220 --save

echo "Creating /dev/ptmx"
mknod --mode $CTID $VZROOT/$CTID/dev/ptmx c 5 2

echo "Copying the sysctl.conf"
cp -v /etc/sysctl.conf $VZROOT/$CTID/etc/sysctl.conf

echo "Starting the CT $CTID"
vzctl start 999
sleep 15

echo "Changing the PATH"
vzctl exec $CTID "export PATH=/sbin:/usr/sbin:/bin:/usr/bin"

echo "Changing the sources.list to add non-free"
vzctl exec $CTID "echo -e \"deb http://ftp.de.debian.org/debian squeeze main non-free\ndeb http://ftp.de.debian.org/debian-security squeeze/updates main non-free contrib\" > /etc/apt/sources.list"
vzctl exec $CTID cat /etc/apt/sources.list

echo "apt-get update"
vzctl exec $CTID "apt-get update"

echo "apt-get dist-upgrade"
vzctl exec $CTID "apt-get dist-upgrade"

echo "apt-get install software we need"
vzctl exec $CTID "apt-get install -y --force-yes ssh less vim bzip2 telnet psmisc sudo screen ttyrec tshark"

echo "Bash as the default shell"
vzctl exec $CTID "rm /bin/sh /bin/sh.distrib ; ln -s /bin/bash /bin/sh"

echo "Configuring locales as EN US UTF8"
vzctl exec $CTID "apt-get install locales"
vzctl exec $CTID "echo \"en_US.UTF-8 UTF-8\" > /etc/locale.gen"
vzctl exec $CTID "ls -l /etc/locale.gen"
vzctl exec $CTID "/usr/sbin/locale-gen"

echo "disable getty"
vzctl exec $CTID "sed -i -e '/getty/d' /etc/inittab"

echo "Fix /etc/mtab"
vzctl exec $CTID "rm -f /etc/mtab"
vzctl exec $CTID "ln -s /proc/mounts /etc/mtab"

echo "Change the timezone"
vzctl exec $CTID "ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime"

echo "apt-get clean"
vzctl exec $CTID "apt-get clean"

echo "stoping the CT $CTID"
vzctl stop $CTID

echo "unset any IP address"
vzctl set $CTID --ipdel all --save

echo "blank the /etc/resolv.conf"
touch $VZROOT/$CTID/etc/resolv.conf

echo "blank the /etc/hostname file"
touch $VZROOT/$CTID/etc/hostname

echo "go to the $CTID directory"
cd /var/lib/vz/private/$CTID

echo "Creating a tar file debian-6.0-$ARCH-minimal.tar.gz"
tar --numeric-owner -zcf /var/lib/vz/template/cache/debian-6.0-$ARCH-minimal.tar.gz .

echo "How big is the generated tar file?"
ls -lh /var/lib/vz/template/cache/debian-6.0-$ARCH-minimal.tar.gz

echo "Testing with a test CTID $TMPCT"
vzctl create $TMPCT --ostemplate debian-6.0-$ARCH-minimal

echo "Starting CT $TMPCT"
vzctl start 123456
sleep 5

echo "Exec ps aux at CT $TMPCT"
vzctl exec $TMPCT ps aux

echo "Stopping $TMPCT"
vzctl stop $TMPCT

echo "Destroying $TMPCT"
vzctl destroy $TMPCT
rm /etc/vz/conf/$TMPCT.conf.destroyed
