
# Utility function to alert user on a condition
# This is meant to be overridden in board specific implementations

#
# Arguments is a loglevel and an optional message
#
# Loglevel is one of (See man 3 syslog for details):
# 	LOG_DEBUG	(8)
#	LOG_INFO	(7)
#	LOG_NOTICE	(6)
#	LOG_WARNING	(5)
#	LOG_ERR		(4)
#	LOG_CRIT	(3)
#	LOG_ALERT	(2)
#	LOG_EMERG	(1)

alert()
{
	if [ -z "$1" ]
	then
		echo "Missing loglevel"
		return
	fi

	arg="${2-}"

	case $1 in
	LOG_DEBUG)
		if [ $LOGLEVEL -ge 8 ]
		then
			_log_debug "$arg"
		fi
	;;
	LOG_INFO)
		if [ $LOGLEVEL -ge 7 ]
		then
			_log_info "$arg"
		fi
	;;	
	LOG_NOTICE)
		if [ $LOGLEVEL -ge 6 ]
		then
			_log_notice "$arg"
		fi
	;;
	LOG_WARNING)
		if [ $LOGLEVEL -ge 5 ]
		then
			_log_warn "$arg"
		fi
	;;
	LOG_ERR)
		if [ $LOGLEVEL -ge 4 ]
		then
			_log_err "$arg"
		fi
	;;
	LOG_CRIT)
		if [ $LOGLEVEL -ge 3 ]
		then
			_log_crit "$arg"
		fi
	;;
	LOG_ALERT)
		if [ $LOGLEVEL -ge 2 ]
		then
			_log_alert "$arg"
		fi
	;;
	LOG_EMERG)
		if [ $LOGLEVEL -ge 1 ]
		then
			_log_emerg "$arg"
		fi
	;;
	*)
		echo "Unknown loglevel ($1)"
	esac

}

_log_debug()
{
	echo "kgp-update, debug: $1"
}

_log_info()
{
	echo "kgp-update, info: $1"
}

_log_notice()
{
	echo "kgp-update, notice: $1"
}

_log_warn()
{
	echo "kgp-update, warning: $1"
}

_log_err()
{
	echo "kgp-update, error: $1"
}

_log_crit()
{
	echo "kgp-update, critical: $1"
}

_log_alert()
{
	echo "kgp-update, alert: $1"
}

_log_emerg()
{
	echo "kgp-update, emergency: $1"
}

#
# Convenience log wrappers
#

log_debug()
{
	alert LOG_DEBUG "${1-}"
}

log_info()
{
	alert LOG_INFO "${1-}"
}

log_notice()
{
	alert LOG_NOTICE "${1-}"
}

log_warn()
{
	alert LOG_WARNING "${1-}"
}

log_err()
{
	alert LOG_ERR "${1-}"
}

log_crit()
{
	alert LOG_CRIT "${1-}"
}

log_alert()
{
	alert LOG_ALERT "${1-}"
}

log_emerg()
{
	alert LOG_EMERG "${1-}"
}
