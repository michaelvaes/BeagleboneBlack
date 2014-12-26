#!/bin/bash
#
# Writing image to SD: sudo dd if=sd.img of=/dev/disk2 bs=4096
#
# BBB Install Script
# June 27th, 2014: initial creation
#
#
#
echo "--------------------------------------------------------------------------------";
echo " Start at " `date`;
echo "--------------------------------------------------------------------------------";

read -p "Linux partition expanded on SD Card? [y/n]: " sAnswer
case $sAnswer in
    [Yy]* ) echo "Continueing..."; break;;
    [Nn]* ) 
		echo "Please expand SD Card partition first."; 
		echo "More info at http://elinux.org/Beagleboard:Expanding_File_System_Partition_On_A_microSD";
		exit;;
esac

echo "Setting root password";
passwd

echo "Updating network configuration /etc/network/interfaces";
read -p "eth0/USB IP addess 192.168.[07].xxx: " sIP
cat > /etc/network/interfaces <<EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
allow-hotplug eth0
iface eth0 inet static
    address 192.168.0.$sIP
    netmask 255.255.255.0
    network 192.168.0.0
    gateway 192.168.0.1

# Ethernet/RNDIS gadget (g_ether)
# ... or on host side, usbnet and random hwaddr
# Note on some boards, usb0 is automaticly setup with an init script
iface usb0 inet static
    address 192.168.7.$sIP
    netmask 255.255.255.0
    network 192.168.7.0
    gateway 192.168.7.1
EOF

echo "Setting locales";
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

echo "Updating apt-get to use local sources (Belgium) /etc/apt/sources.list";
cat > /etc/apt/sources.list <<EOF
deb http://ftp.be.debian.org/debian/ wheezy main contrib non-free
#deb-src http://ftp.us.debian.org/debian/ wheezy main contrib non-free

deb http://ftp.be.debian.org/debian/ wheezy-updates main contrib non-free
#deb-src http://ftp.us.debian.org/debian/ wheezy-updates main contrib non-free

deb http://security.debian.org/ wheezy/updates main contrib non-free
#deb-src http://security.debian.org/ wheezy/updates main contrib non-free

#deb http://ftp.debian.org/debian wheezy-backports main contrib non-free
##deb-src http://ftp.debian.org/debian wheezy-backports main contrib non-free

deb [arch=armhf] http://debian.beagleboard.org/packages wheezy-bbb main
#deb-src [arch=armhf] http://debian.beagleboard.org/packages wheezy-bbb main
EOF
apt-get update;

echo "Upgrading all packages";
apt-get upgrade;

echo "Installing packages";
apt-get install ntpdate strace ethtool mail;

echo "/etc/ssh/sshd_config - Backup: /etc/ssh/sshd_config.bak";
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak;
echo "/etc/ssh/sshd_config - Disable SSH Banner";
sed -iE "s/^Banner/#Banner/g" /etc/ssh/sshd_config && grep 'Banner' /etc/ssh/sshd_config;
echo "/etc/ssh/sshd_config - Disable empty passwords";
sed -iE "s/^PermitEmptyPasswords yes/PermitEmptyPasswords no/g" /etc/ssh/sshd_config && grep 'PermitEmptyPasswords' /etc/ssh/sshd_config;
/etc/init.d/ssh restart;

echo "Installing Dropbox-uploader";
curl "https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh" -o dropbox_uploader.sh;
chmod +x dropbox_uploader.sh;
cat > ~/.dropbox_uploader <<EOF
APPKEY=wtv8rxw2p7v4x7o
APPSECRET=8u9f15po80fx9iq
ACCESS_LEVEL=dropbox
OAUTH_ACCESS_TOKEN=34c92ec086hjxdpw
OAUTH_ACCESS_TOKEN_SECRET=mww2ltmc1apfo4f
EOF
alias dropb='/root/dropbox_uploader.sh';
echo "Installing Dropbox-uploader: /root/BeagleboneBlack/";
dropb -f /root/.dropbox_uploader -q download Scripts/BeagleboneBlack/ /root;

echo "Installing crontabs";
cat > /var/spool/cron/crontabs/root <<EOF
SHELL=/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

@reboot sleep 60 && ntpdate -bsu europe.pool.ntp.org
* */4 * * * ntpdate -bsu europe.pool.ntp.org

*/5 * * * * /root/dropbox_uploader.sh -f /root/.dropbox_uploader -q download Scripts/BeagleboneBlack/ /root
#*/6 * * * * /root/dropbox_uploader.sh -f /root/.dropbox_uploader -q upload /root/BeagleboneBlack/ Scripts/

* * * * * bash /root/BeagleboneBlack/Scripts/BBBStats/ServerStats.bash
#* * * * * source /root/BeagleboneBlack/Scripts/BBBStats/ThingSpeak.bash && tsPushTemperatures

EOF

echo "--------------------------------------------------------------------------------";
echo " Completed at " `date`;
echo "--------------------------------------------------------------------------------";
