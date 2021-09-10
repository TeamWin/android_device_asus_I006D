#!/sbin/sh

# The below variables shouldn't need to be changed
# unless you want to call the script something else
SCRIPTNAME="temp_mount"
LOGFILE=/tmp/recovery.log

# Set default log level
DEFAULT_LOGLEVEL=1
# 0 Errors only
# 1 Errors and Information
# 2 Errors, Information, and Debugging
CUSTOM_LOGLEVEL=$(getprop $SCRIPTNAME.loglevel)
if [ -n "$CUSTOM_LOGLEVEL" ]; then
	__VERBOSE="$CUSTOM_LOGLEVEL"
else
	__VERBOSE="$DEFAULT_LOGLEVEL"
fi

# Exit codes:
# 0 Success
# 1 Unknown encryption type
# 2 Temp Mount Failure

# Function for logging to the recovery log
log_print()
{
	# 0 = Error; 1 = Information; 2 = Debugging
	case $1 in
		0|error)
			LOG_LEVEL="E"
			;;
		1|info)
			LOG_LEVEL="I"
			;;
		2|debug)
			LOG_LEVEL="DEBUG"
			;;
		*)
			LOG_LEVEL="UNKNOWN"
			;;
	esac
	if [ $__VERBOSE -ge "$1" ]; then
		echo "$LOG_LEVEL:$SCRIPTNAME::$2" >> "$LOGFILE"
	fi
}

check_dynamic()
{
	dynamic_partitions=$(getprop ro.boot.dynamic_partitions)
	if [ "$dynamic_partitions" = "true" ]; then
		unset suffix
	fi
}

check_resetprop()
{
	if [ -e /system/bin/resetprop ] || [ -e /sbin/resetprop ]; then
		log_print 2 "Resetprop binary found!"
		setprop_bin=resetprop
	else
		log_print 2 "Resetprop binary not found. Falling back to setprop."
		setprop_bin=setprop
	fi
}

finish()
{
    is_vendor_mounted=$(getprop $SCRIPTNAME.vendor_mounted)
	if [ "$is_vendor_mounted" = 1 ]; then
		umount "$TEMPVEN"
		$setprop_bin $SCRIPTNAME.vendor_mounted 0
		rmdir "$TEMPVEN"
	fi
	log_print 1 "$SCRIPTNAME script complete."
	exit 0
}

finish_error()
{
    is_vendor_mounted=$(getprop $SCRIPTNAME.vendor_mounted)
	if [ "$is_vendor_mounted" = 1 ]; then
		umount "$TEMPVEN"
		$setprop_bin $SCRIPTNAME.vendor_mounted 0
		rmdir "$TEMPVEN"
	fi
	log_print 0 "$SCRIPTNAME script complete. See log for errors."
	exit 2
}


temp_mount()
{
	is_mounted=$(ls -A "$1" 2>/dev/null)
	if [ -n "$is_mounted" ]; then
		log_print 1 "$2 already mounted."
	else
		mkdir "$1"
		if [ -d "$1" ]; then
			log_print 2 "Temporary $2 folder created at $1."
		else
			log_print 0 "Unable to create temporary $2 folder."
			finish_error
		fi
		mount -t ext4 -o ro "$3" "$1"
		is_mounted=$(ls -A "$1" 2>/dev/null)
		if [ -n "$is_mounted" ]; then
			log_print 2 "$2 mounted at $1."
			$setprop_bin $SCRIPTNAME."$2"_mounted 1
			log_print 2 "$SCRIPTNAME.$2_mounted=$(getprop "$SCRIPTNAME"."$2"_mounted)"
		else
			log_print 0 "Unable to mount $2 to temporary folder."
			finish_error
		fi
	fi
}

log_print 1 "Running $SCRIPTNAME script..."

ab_device=$(getprop ro.build.ab_update)
if [ -n "$ab_device" ]; then
	log_print 2 "A/B device detected! Finding current boot slot..."
	suffix=$(getprop ro.boot.slot_suffix)
	if [ -z "$suffix" ]; then
		suf=$(getprop ro.boot.slot)
		if [ -n "$suf" ]; then
			suffix="_$suf"
		fi
	fi
	log_print 2 "Current boot slot: $suffix"
fi

boot_mode=$(getprop sys.usb.config)
if [ "$boot_mode" = "fastboot" ]; then
	log_print 1 "No temp mounting required. Exiting script."
	exit 0
else
	check_resetprop
	check_dynamic

	TEMPVEN=/v
	venpath="/dev/block/bootdevice/by-name/vendor$suffix"

	temp_mount "$TEMPVEN" "vendor" "$venpath"
	sleep 4
	finish
fi
