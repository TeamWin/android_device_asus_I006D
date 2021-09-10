#!/sbin/sh

# The below variables shouldn't need to be changed
# unless you want to call the script something else
SCRIPTNAME="fastboot_boot_check"
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

check_fastboot_boot()
{
	is_fastboot_boot=$(getprop ro.boot.fastboot)
	twrpfastboot=$(grep twrpfastboot /proc/cmdline)
	skip_initramfs_present=$(grep skip_initramfs /proc/cmdline)
	if [ -n "$is_fastboot_boot" ] || { [ -z "$is_fastboot_boot" ] && { [ -n "$twrpfastboot" ] || [ -n "$skip_initramfs_present" ]; }; }; then
		$setprop_bin ro.boot.fastboot 1
		is_fastboot_boot=$(getprop ro.boot.fastboot)
		log_print 1 "Fastboot boot detected. ro.boot.fastboot=$is_fastboot_boot"
	else
		$setprop_bin ro.boot.fastboot 0
		is_fastboot_boot=$(getprop ro.boot.fastboot)
		log_print 1 "Recovery mode boot detected. ro.boot.fastboot=$is_fastboot_boot"
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
	log_print 1 "$SCRIPTNAME script complete."
	exit 0
}

log_print 1 "Running $SCRIPTNAME script..."

check_resetprop
check_fastboot_boot

finish
