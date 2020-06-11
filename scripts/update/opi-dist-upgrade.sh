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


if enabled=$(kgp-sysinfo -p -c autoupdate -k enabled) ; then
	if [[ $enabled -ne 1 ]] ; then
		report "Updates disabled"
		exit 0
	fi
else
	kgp-notifier -q -l "LOG_DEBUG" -m "Missing 'autoupdate->enabled' parameter in 'sysconfig'." -i "sysctrl"
	report "Missing 'autoupdate->enabled' parameter in 'sysconfig'"
	exit 1
fi


if locked=$(kgp-sysinfo -l); then
	report "System locked, not possible to run updates."
	exit 0
fi

if ! grep -iq "'installed'\s\+=>\s\+true" /usr/share/nextcloud/config/config.php
then
	report "Update aborted, OC not setup yet"
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
		kgp-notifier -l "LOG_WARNING" -m "apt clean up failed, see log in $cleanup_log" -i "sysctrl"
	fi
	
fi

rm $apt_output

if [[ -f /var/run/reboot-required ]]; then
	kgp-notifier -q -l "LOG_NOTICE" -m "Reboot required due to updates of core functions." -i "sysctrl"
	rm /var/run/reboot-required
fi
exit 0
