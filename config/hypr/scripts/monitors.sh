#!/bin/zsh
LAPTOP_DESCRIPTION="description: Samsung Display Corp. 0x419D"
LG_DESCRIPTION="description: LG Electronics LG HDR 4K 306NTGY9H975"

get_monitors() {
	echo $(hyprctl monitors)
}

monitor_off() {
	if [[ $(get_monitors) == *$LG_DESCRIPTION* ]]; then
		hyprctl keyword monitor "eDP-1, disable"
	fi
}

monitor_on() {
	if [[ $(get_monitors) == *$LG_DESCRIPTION* ]]; then
		hyprctl keyword monitor "eDP-1,preferred,auto,2"
	fi
}


case "$1" in
	"--on")
		monitor_on
		;;
	"--off")
		monitor_off
		;;
	*)
		get_monitors
		;;
esac
