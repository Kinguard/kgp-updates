#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
def_sdcard="/dev/mapper/opi"
def_opiloc="/var/opi"

if [ -e /etc/opi/opi-update.conf ]; then 
	source /etc/opi/opi-update.conf
	if [ $update != "yes" ]; then
		echo "Updates not enabled"
		exit 0
	fi
else
	echo "No config file, exiting"
	exit 0
fi



sd_card=$(sed -n "s%\(${def_sdcard}\)\s${def_opiloc}.*%\1% p" /proc/mounts) # get sd-card device
if [ -z $sd_card ] || [ ! -b $sd_card ]; then
	# the backend must be defined and the sd-card device must exist and be mounted
	echo "update aborted, no sd card found or sd card is not unlocked"
	exit 0
fi

echo "Starting update"

apt_output=$( /bin/mktemp -t )
echo APT-GET Update was run: $( /bin/date +%c ) >> $apt_output
echo >> $apt_output
apt-get -q -y update > /dev/null

export DEBIAN_FRONTEND=noninteractive
apt-get -q -y -o Dpkg::Options::="--force-confnew" dist-upgrade | grep -i installed >> $apt_output

if [ $? -ne 0 ]; then
	tmpfile=$( /bin/mktemp -t )
	$recipient=admin.localhost
	echo "return-path: $recipient" >> $tmpfile
	echo "for: $recipient" >> $tmpfile
	echo "from: opi" >> $tmpfile
	echo "to: $recipient" >> $tmpfile
	echo "subject: Error running upgrade" >> $tmpfile
	echo "An error was encounteded when running the upgrade scripts on your opi." >> $tmpfile
	echo >> $tmpfile

	cat $apt_output >> $tmpfile
	echo >> $tmpfile
	echo "If you can not understand this message, please contact support@openproducts.com" >> $tmpfile
	echo >> $tmpfile
	#/bin/cat $tmpfile | sendmail -t
	echo $tmpfile
	rm $tmpfile
fi
rm $apt_output
exit 0
