#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

apt_output=$( /bin/mktemp -t )
echo APT-GET Update was run: $( /bin/date +%c ) >> $apt_output
echo >> $apt_output
apt-get -q -y update > /dev/null
apt-get -q -y dist-upgrade | grep -i installed >> $apt_output

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
exit 0
