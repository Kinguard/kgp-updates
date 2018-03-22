#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
def_sdcard="/dev/mapper/opi"
def_opiloc="/var/opi"

verbose=$1
function report {
	if [ ! -z $verbose ] && [ $verbose == '-v' ] ; then
		echo $1
	fi
}

if [ -e /etc/opi/opi-update.conf ]; then 
	source /etc/opi/opi-update.conf
	if [ $update != "yes" ]; then
		report "Updates not enabled"
		exit 0
	fi
else
	report "No config file, exiting"
	exit 0
fi

sd_card=$(sed -n "s%\(${def_sdcard}\)\s${def_opiloc}.*%\1% p" /proc/mounts) # get sd-card device
if [ -z $sd_card ] || [ ! -b $sd_card ]; then
	# the backend must be defined and the sd-card device must exist and be mounted
	report "update aborted, no sd card found or sd card is not unlocked"
	exit 0
fi

if ! grep -iq "'installed'\s\+=>\s\+true" /usr/share/nextcloud/config/config.php
then
	report "update aborted, OC not setup yet"
	exit 0
fi

report "Try free up memory"

sync
echo 3 > /proc/sys/vm/drop_caches

report "Starting update"

apt_output=$( /bin/mktemp -t )
echo APT-GET Update was run: $( /bin/date +%c ) >> $apt_output
echo >> $apt_output
apt-get -q -y update > /dev/null

export DEBIAN_FRONTEND=noninteractive
apt-get -q -y -o Dpkg::Options::="--force-confnew" dist-upgrade &>> $apt_output

if [ $? -ne 0 ]; then
	apt_log="/var/log/dist-upgrade.log"
	cp $apt_output $apt_log
	kgp-notifier -l "LOG_ERR" -m "Upgrade failed, log in $apt_log. Please run upgrade manually from command line." -i "sysctrl"	
else
	# run cleanups
	echo "Cleaning apt cache" >> $apt_output
	apt-get clean &>> $apt_output
	clean_status=$?
	apt-get autoremove &>> $apt_output
	remove_status=$?
	if [[ $clean_status -ne 0 || $remove_status -ne 0 ]]; then
		cleanup_log="/var/log/apt-cleanup.log"
		kgp-notifier -l "LOG_WARN" -m "apt clean up failed, see log in $cleanup_log" -i "sysctrl"
	fi
	
fi

rm $apt_output

if [[ -f /var/run/reboot-required ]]; then
	kgp-notifier -q -l "LOG_NOTICE" -m "Core functions upgraded, reboot required." -i "sysctrl"
	rm /var/run/reboot-required
fi
exit 0
