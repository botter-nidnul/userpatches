#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot
# The sd card's root path is accessible via $SDCARD variable.

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

Main() {
	case $RELEASE in
		stretch)
			# your code here
			;;
		buster)
			# buster is all that i've tested, but I think the other distros should work with the Urbit packages too
			InstallUrbitTurnkey
			InstallUrbitFstrim
			InstallNymeaNetworkManager
			InstallRPiMonitor
			;;
		bullseye)
			# your code here
			;;
		bionic)
			# your code here
			;;
		focal)
			# your code here
			;;
	esac
} # Main

InstallUrbitTurnkey() {

	# set root password, avoid being prompted on boot to set it
	echo root:turnkeyurbit | chpasswd
	rm /root/.not_logged_in_yet
	export DEBIAN_FRONTEND=noninteractive
	export APT_LISTCHANGES_FRONTEND=none

	# Add urbit-on-arm repository
	cat > /etc/apt/sources.list.d/urbit-on-arm.list <<- EOF
	deb http://urbit-on-arm.s3-website.us-east-2.amazonaws.com buster custom
	EOF

	# Add urbit-on-arm key
	curl https://s3.us-east-2.amazonaws.com/urbit-on-arm/urbit-on-arm_public.gpg | apt-key add -

	# update then install urbit packages
	apt-get update
	apt-get --yes install urbit-turnkey

} # InstallUrbitTurnkey

InstallUrbitFstrim() {

	apt-get --yes install fstrim-urbit
	
} # InstallUrbitFstrim

InstallNymeaNetworkManager() {

# Add nymea repository
cat > /etc/apt/sources.list.d/nymea.list <<- EOF
deb http://repository.nymea.io buster main
EOF

apt-key adv --keyserver keyserver.ubuntu.com --recv-key A1A19ED6

apt-get update
apt-get --yes install bluetooth bluez bluez-tools
apt-get --yes install nymea-networkmanager

} # InstallNymeaNetworkManager

InstallRPiMonitor() {

apt-get --yes install rpimonitor
apt-get --yes install shellinabox
/etc/init.d/rpimonitor install_auto_package_status_update

# On other SoCs than H3 make minor adjustments to config to reflect Armbian reality:
sed -e "s/^web.status.1.name=.*/web.status.1.name=$BOARD/" \
	-e "s/^web.statistics.1.name=.*/web.statistics.1.name=$BOARD/" \
	</etc/rpimonitor/template/raspbian.conf >/etc/rpimonitor/template/armbian.conf
cd /etc/rpimonitor/
ln -sf /etc/rpimonitor/template/armbian.conf data.conf
# fix temperature everywhere
sed -i -e 's|^dynamic.12.source=.*|dynamic.12.source=/etc/armbianmonitor/datasources/soctemp|' \
	-e 's|^dynamic.12.postprocess=.*|dynamic.12.postprocess=sprintf("%.1f", $1/1000)|' \
	/etc/rpimonitor/template/temperature.conf
# monitor big cores on big.LITTLE
if [ $(grep -c '^processor' /proc/cpuinfo) -ge 4 ]; then
	sed -i 's|/sys/devices/system/cpu/cpu0/cpufreq/|/sys/devices/system/cpu/cpu4/cpufreq/|g' \
	/etc/rpimonitor/template/cpu.conf
fi
# display processor architecture instead of undefined
sed -i -e "s_^static.4.source=.*_static.4.source=lscpu | awk -F' ' '/^Architecture/ {print \$2}'_" \
	-e "s/^static.4.regexp=.*/static.4.regexp=/" /etc/rpimonitor/template/version.conf

cat >> /etc/rpimonitor/data.conf <<- ADDLINES
web.addons.2.name=Shellinabox
web.addons.2.addons=shellinabox
web.addons.3.name=Top3
web.addons.3.addons=top3
include=/etc/rpimonitor/template/version.conf
include=/etc/rpimonitor/template/uptime.conf
include=/etc/rpimonitor/template/cpu.conf
include=/etc/rpimonitor/template/temperature.conf
include=/etc/rpimonitor/template/memory.conf
include=/etc/rpimonitor/template/swap.conf
include=/etc/rpimonitor/template/network.conf
include=/etc/rpimonitor/template/storage.conf
include=/etc/rpimonitor/template/services.conf
include=/etc/rpimonitor/template/wlan.conf
ADDLINES

} # InstallRPiMonitor

Main "$@"
