#! /bin/bash

# This script is to be run with a setup, unlocked and up2date sysem
# It will make sure that we only run one version of php, the latest.
#
# The reason for this is that when we update a system from debian
# stretch to buster we will still have the php 7.0 version in parallell
# with the 7.3 one. That is just a waste of resources and thus this script
# will remove the 7.0 one if 7.3 found successfully installed.

# Check if system locked, then we dont do this.


. $1/utils.sh

log_debug "php version check, start"

if [ $(kgp-sysinfo -l) -eq 1 ]
then
	log_info "System locked, not performing migration"
	exit 0
fi

# Dont try migrate if updates disabled
if enabled=$(kgp-sysinfo -p -c autoupdate -k enabled) ; then
	if [[ $enabled -ne 1 ]] ; then
		log_info "Updates disabled, terminating"
		exit 0
	fi
else
	log_warn "Missing 'autoupdate->enabled' parameter in 'sysconfig'"
	exit 0
fi

FPM70=$(dpkg-query -W -f '${Package} ${db:Status-Abbrev} ${version}\n' 'php7.0-fpm' 2> /dev/null )

if [ $? -ne 0 ]
then
	log_debug "php7 most likely not installed"
	exit 0
fi

FPM73=$(dpkg-query -W -f '${Package} ${db:Status-Abbrev} ${version}\n' 'php7.3-fpm' 2> /dev/null )

if [ $? -ne 0 ]
then
	log_warn "php73 not installed, where am i??"
	exit 0
fi

STATUS=$(echo $FPM73 | cut -f2 -d ' ')

if [ $STATUS != "ii" ]
then
	log_info "PHP 7.3 not properly installed, bailing out"
	exit 0
fi

# We should have a properly installed php7.3 and some form of php 7.0 as well.
# Remove all 7.0 ones.

log_info "Purging php 7.0"
dpkg -l | grep php7.0 | cut -d' ' -f 3 | xargs apt -y purge

log_debug "php version check, completed"

