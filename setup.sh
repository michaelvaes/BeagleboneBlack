#!/bin/bash
#
# Writing image to SD: sudo dd if=sd.img of=/dev/disk2 bs=4096
#
# BBB Install Script
# git clone https://github.com/michaelvaes/BeagleboneBlack.git
#
alias echo='echo -e';
GREEN='\e[32m';
RED='\e[91m';

echo "${GREEN}--------------------------------------------------------------------------------";
echo "${GREEN} Start at " `date`;
echo "${GREEN}--------------------------------------------------------------------------------";
echo

echo "${GREEN}------------------------------------------------------------";
echo "${GREEN} Partitioning";
echo "${GREEN}------------------------------------------------------------";
read -p "Linux partition expanded on SD Card? [y/n]: " sAnswer
case $sAnswer in
    [Yy]* ) 
        echo "Continueing...";
        ;;
    * ) 
		echo "Please expand SD Card partition first."; 
		echo "More info at http://elinux.org/Beagleboard:Expanding_File_System_Partition_On_A_microSD";
		exit;
        ;;
esac
unset sAnswer
echo

echo "${GREEN}------------------------------------------------------------";
echo "${GREEN} Setting root password";
echo "${GREEN}------------------------------------------------------------";
passwd
echo 

echo "${GREEN}------------------------------------------------------------";
echo "${GREEN} Profile update";
echo "${GREEN}------------------------------------------------------------";
cat > /root/.profile <<EOF
export EDITOR=vi;
export VISUAL=vi;
export HISTFILESIZE=10000;
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
unset LC_CTYPE;
mesg y;
if [ -d ~/bin ] ; then
  export PATH="~/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
fi
EOF
source /root/.profile
locale-gen en_US.UTF-8;
dpkg-reconfigure locales;
echo

echo "${GREEN}------------------------------------------------------------";
echo "${GREEN} Updating network configuration";
echo "${GREEN}------------------------------------------------------------";
read -p "Did you add the DNS config to the server? [y/n]: " sAnswer;
case $sAnswer in
    [Yy]* ) 
        echo "Continueing...";
        ;;
    * ) 
        exit;
        ;;
esac
unset sAnswer
echo

read -p "FQDN hostname: " sHostname;
echo $sHostname > /etc/hostname;
hostname $sHostname;
read -p "eth0/USB IP address 192.168.[07].xxx: " sIP;
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
cat > /etc/resolv.conf <<EOF
nameserver 192.168.0.100
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
echo

echo "${GREEN}------------------------------------------------------------";
echo "${GREEN} Updating";
echo "${GREEN}------------------------------------------------------------";
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

echo "${GREEN}------------------------------------------------------------";
echo "${GREEN} Software installs";
echo "${GREEN}------------------------------------------------------------";
echo "Removing some packages";
apt-get remove 'node*';

echo "Upgrading all packages";
apt-get upgrade;

echo "Installing new packages";
apt-get install ntpdate strace ethtool sharutils bc dnsutils exim4-base exim4-config exim4-daemon-light git;
echo

echo "${GREEN}------------------------------------------------------------";
echo "${GREEN} Mail config";
echo "${GREEN}------------------------------------------------------------";
sed -iE "s/root: root/root: postmaster@michaelvaes.be/g" /etc/aliases;
cat /etc/hostname > /etc/mailname;
cat > /etc/exim4/update-exim4.conf.conf <<EOF
# /etc/exim4/update-exim4.conf.conf
#
# Edit this file and /etc/mailname by hand and execute update-exim4.conf
# yourself or use 'dpkg-reconfigure exim4-config'
#
# Please note that this is _not_ a dpkg-conffile and that automatic changes
# to this file might happen. The code handling this will honor your local
# changes, so this is usually fine, but will break local schemes that mess
# around with multiple versions of the file.
#
# update-exim4.conf uses this file to determine variable values to generate
# exim configuration macros for the configuration file.
#
# Most settings found in here do have corresponding questions in the
# Debconf configuration, but not all of them.
#
# This is a Debian specific file

dc_eximconfig_configtype='smarthost'
dc_other_hostnames=''
dc_local_interfaces='127.0.0.1 ; ::1'
dc_readhost=''
dc_relay_domains=''
dc_minimaldns='false'
dc_relay_nets=''
dc_smarthost='uit.telenet.be'
CFILEMODE='644'
dc_use_split_config='false'
dc_hide_mailname='false'
dc_mailname_in_oh='true'
dc_localdelivery='mail_spool'
EOF
update-exim4.conf;
echo

echo "${GREEN}------------------------------------------------------------";
echo "${GREEN} SSH config";
echo "${GREEN}------------------------------------------------------------";
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak;
sed -iE "s/^Banner/#Banner/g" /etc/ssh/sshd_config;
sed -iE "s/^PermitEmptyPasswords yes/PermitEmptyPasswords no/g" /etc/ssh/sshd_config;
/etc/init.d/ssh restart;
echo

echo "${GREEN}------------------------------------------------------------";
echo "${GREEN} Installing crontabs";
echo "${GREEN}------------------------------------------------------------";
cat > /var/spool/cron/crontabs/root <<EOF
SHELL=/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

@reboot sleep 60 && ntpdate -bsu europe.pool.ntp.org
* */4 * * * ntpdate -bsu europe.pool.ntp.org

* * * * * bash /root/BeagleboneBlack/Scripts/BBBStats/ServerStats.bash
#* * * * * source /root/BeagleboneBlack/Scripts/BBBStats/ThingSpeak.bash && tsPushTemperatures

EOF
echo

echo "${GREEN}--------------------------------------------------------------------------------";
echo "${GREEN} Completed at " `date`;
echo "${GREEN}--------------------------------------------------------------------------------";
echo

echo "${RED}--------------------------------------------------------------------------------";
echo "${RED} Reboot";
echo "${RED}--------------------------------------------------------------------------------";
read -p "Do you want to reboot now? [y/n]: " sAnswer
case $sAnswer in
    [Yy]* ) 
        echo "Rebooting...";
        echo "Reconnect to " `hostname`;
        reboot;
        ;;
    * ) 
        exit;
        ;;
esac
unset sAnswer