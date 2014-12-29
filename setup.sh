#!/bin/bash
#
# Writing image to SD: sudo dd if=sd.img of=/dev/disk2 bs=4096
#
# BBB Install Script
# git clone https://github.com/michaelvaes/BeagleboneBlack.git
#
source .bash_colors;

# Run under /root
cd /root;

clr_blue "--------------------------------------------------------------------------------";
clr_blue " Start at `date`";
clr_blue "--------------------------------------------------------------------------------";
echo

clr_green "------------------------------------------------------------";
clr_green " Partitioning";
clr_green "------------------------------------------------------------";
read -p "Linux partition expanded on SD Card? [y/n]: " sAnswer
case $sAnswer in
    [Yy]* ) 
        ;;
    * ) 
		echo " Please expand SD Card partition first."; 
		echo " More info at http://elinux.org/Beagleboard:Expanding_File_System_Partition_On_A_microSD";
		exit;
        ;;
esac
unset sAnswer
echo

clr_green "------------------------------------------------------------";
clr_green " Setting root password";
clr_green "------------------------------------------------------------";
passwd
echo 

clr_green "------------------------------------------------------------";
clr_green " Profile updates";
clr_green "------------------------------------------------------------";
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
cat > /root/.vimrc <<EOF
set noai
set hlsearch
set ignorecase
set incsearch
set nocompatible
set number
set ruler
set showmatch
set sm
set tabstop=2
set wrap
syntax on
EOF
source /root/.profile
locale-gen en_US.UTF-8;
dpkg-reconfigure locales;
echo

clr_green "------------------------------------------------------------";
clr_green " Updating network configuration";
clr_green "------------------------------------------------------------";
read -p "Did you add the DNS config to the server? [y/n]: " sAnswer;
case $sAnswer in
    [Yy]* ) 
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
    address 192.168.7.2
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

clr_green "------------------------------------------------------------";
clr_green " Updating";
clr_green "------------------------------------------------------------";
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
echo

clr_green "------------------------------------------------------------";
clr_green " Software installs";
clr_green "------------------------------------------------------------";
clr_blue "Removing some packages";
apt-get remove 'node*';
echo
clr_blue "Upgrading all packages";
apt-get upgrade;
echo
clr_blue "Installing new packages";
apt-get install ntpdate strace ethtool sharutils bc dnsutils exim4-base exim4-config exim4-daemon-light git;
echo

clr_green "------------------------------------------------------------";
clr_green " Mail config";
clr_green "------------------------------------------------------------";
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

clr_green "------------------------------------------------------------";
clr_green " SSH config";
clr_green "------------------------------------------------------------";
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak;
sed -iE "s/^Banner/#Banner/g" /etc/ssh/sshd_config;
sed -iE "s/^PermitEmptyPasswords yes/PermitEmptyPasswords no/g" /etc/ssh/sshd_config;
/etc/init.d/ssh restart;
echo

clr_green "------------------------------------------------------------";
clr_green " Installing crontabs";
clr_green "------------------------------------------------------------";
cat > /var/spool/cron/crontabs/root <<EOF
SHELL=/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

@reboot sleep 60 && ntpdate -bsu europe.pool.ntp.org
* */4 * * * ntpdate -bsu europe.pool.ntp.org

* * * * * bash /root/BeagleboneBlack/Scripts/BBBStats/ServerStats.bash

# Temperature sensing
#@reboot echo w1 > /sys/devices/bone_capemgr.9/slots;
#* * * * * source /root/BeagleboneBlack/Scripts/BBBStats/ThingSpeak.bash && tsPushTemperatures > /dev/null

EOF
echo

clr_green "--------------------------------------------------------------------------------";
clr_green " Completed at `date`";
clr_green "--------------------------------------------------------------------------------";
echo

clr_red "--------------------------------------------------------------------------------";
clr_red " Reboot";
clr_red "--------------------------------------------------------------------------------";
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