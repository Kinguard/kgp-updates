#!/bin/bash

LOGNAME="${LOGNAME}: OPI Distupgrade"
source /usr/share/kgp-bashlibrary/scripts/kgp-logging.sh

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
def_sdcard="/dev/mapper/opi"
def_opiloc="/var/opi"

log_notice "Starting up"

if enabled=$(kgp-sysinfo -p -c autoupdate -k enabled) ; then
	if [[ $enabled -ne 1 ]]
	then
		if [ -v FORCE_UPGRADE ] && [ $FORCE_UPGRADE = "yes" ]
		then
			log_notice "Upgrade disabled but force requested, proceeding"
		else
			log_notice "Updates disabled, terminating"
			exit 0
		fi
	fi
else
	kgp-notifier -q -l "LOG_DEBUG" -m "Missing 'autoupdate->enabled' parameter in 'sysconfig'." -i "sysctrl"
	log_err "Missing 'autoupdate->enabled' parameter in 'sysconfig'"
	exit 1
fi


if locked=$(kgp-sysinfo -l); then
	log_notice "System locked, not possible to run updates."
	exit 0
fi

if ! grep -iq "'installed'\s\+=>\s\+true" /usr/share/nextcloud/config/config.php
then
	log_notice "Update aborted, OC not setup yet"
	exit 0
fi


if [ $(kgp-sysinfo -pi Opi) -eq 1 -o $(kgp-sysinfo -pi Armada) -eq 1 ]
then
	log_debug "Try free up memory"

	sync
	echo 3 > /proc/sys/vm/drop_caches

else
	log_debug "None OP device, assume no memory constraint"
fi

log_info "Starting update"

apt_output=$( /bin/mktemp -t )
echo APT-GET Update was run: $( /bin/date +%c ) >> $apt_output
echo >> $apt_output
apt-get -q -y update > /dev/null

log_debug "update completed"

export DEBIAN_FRONTEND=noninteractive
apt-get -q -y -o Dpkg::Options::="--force-confnew" dist-upgrade &>> $apt_output

log_debug "upgrade completed"

if [ $? -ne 0 ]; then
	log_error "Upgrade failed!"
	apt_log="/var/log/dist-upgrade.log"
	cp $apt_output $apt_log
	kgp-notifier -l "LOG_ERR" -m "Upgrade failed, log in $apt_log. Please run upgrade manually from command line." -i "sysctrl"	
else
	log_debug "upgrade succeded, perform cleanups"
	# run cleanups
	echo "Cleaning apt cache" >> $apt_output
	apt-get -q -y clean &>> $apt_output
	clean_status=$?
	apt-get -q -y autoremove &>> $apt_output
	remove_status=$?
	if [[ $clean_status -ne 0 || $remove_status -ne 0 ]]; then
		log_error "cleanup failed!"
		cleanup_log="/var/log/apt-cleanup.log"
		cp $apt_output $cleanup_log
		kgp-notifier -l "LOG_WARNING" -m "apt clean up failed, see log in $cleanup_log" -i "sysctrl"
	fi
	
fi

rm $apt_output

if [[ -f /var/run/reboot-required ]]; then
	log_debug "Reboot requiered"
	kgp-notifier -q -l "LOG_NOTICE" -m "Reboot required due to updates of core functions." -i "sysctrl"
	rm /var/run/reboot-required
fi
log_notice "Completed"
exit 0
