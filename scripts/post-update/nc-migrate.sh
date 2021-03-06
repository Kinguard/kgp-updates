#! /bin/bash

#
# This script is to be run with a setup system and a completed update
# it will try to migrate nextcloud to the latest available version by
# upgrading to any inbetween versions on the way making sure we get the
# system migrated properly.
#
# TODO: this script most likely should belong in another package than in
# the opi-update one.
#

LOGNAME="${LOGNAME}: NC Migration"
source /usr/share/kgp-bashlibrary/scripts/kgp-logging.sh

# Check if system locked, then we dont do this.

if [ $(kgp-sysinfo -l) -eq 1 ]
then
	log_notice "System locked, not performing migration"
	exit 0
fi

# Dont try migrate if updates disabled
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
	log_warn "Missing 'autoupdate->enabled' parameter in 'sysconfig'"
	exit 0
fi

TMP_NC="$(dpkg-query -W -f '${Package} ${db:Status-Abbrev} ${version}\n' 'nextcloud*')"

while read -r line
do
	CNC=$(echo $line | cut -f1 -d ' ')
	CNCS=$(echo $line | cut -f2 -d ' ')

	if [ $CNCS = "ii" ]
	then
		CURR_NC=$CNC
		NCV=$(echo $line | cut -f3 -d' ')
		log_debug "Found installed $CURR_NC version $NCV"
	fi
done <<< "$TMP_NC"

if [ -z "$CURR_NC" ]
then
	log_err "Nextcloud seems not to be properly installed??"
	exit 1
fi

# Get available versions
AVNC=$(apt-cache search --names-only '^nextcloud*' \
	| grep -P '^nextcloud(\d+\s|\s)-.*$' \
	| cut -f 1 -d' ' \
	| sort -V )

# Work through versions make sure we run latest version
export DEBIAN_FRONTEND=noninteractive
FOUND=0
for V in $AVNC
do
	log_debug "Process $V"
	if [ $V = $CURR_NC ]
	then
		FOUND=1
		continue
	fi
	if [ $FOUND -eq 1 ]
	then
		log_info "Install $V"
		apt-get -q -y -o Dpkg::Options::="--force-confnew" install $V
	fi
done

# Cleanup
ALL_NC="$(dpkg-query -W -f '${Package} ${db:Status-Abbrev} ${version}\n' 'nextcloud*')"

while read -r line
do
	TNC=$(echo $line | cut -f1 -d ' ')
	TNCS=$(echo $line | cut -f2 -d ' ')

	# Todo, only purge removed versions, ie "rc" status?
	if [ $TNCS = "rc" ]
	then
		TCV=$(echo $line | cut -f3 -d' ')
		log_info "Purging removed nextcloud: $TNC version: $TCV"
		apt-get -q -y purge $TNC
	fi
done <<< "$ALL_NC"


