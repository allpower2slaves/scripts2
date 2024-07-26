#!/bin/sh
# function to get parseable gpu setup (i hope)
# requirements: lsblk from linux-utils package and gnu coreutils (i think)
# posix compatibility wasnt tested !!!

get_gpu(){
	gpus=$(lspci -vmm | grep -A1  "VGA compatible controller" | grep -v "^Class:" | cut -d ':' -f 2-  | tr -d '\t' | grep -v "^--" | cut -d ' ' -f 1 | tr '[:upper:]' '[:lower:]' | sort -u | tr -d '\n')
	echo "$gpus" #debug

	case $gpus in 
		"nvidia")
			echo "nvidia"
			;;
		"intel")
			echo "intel"
			;;
		"advanced")
			echo "amd"
			;;
		"intelnvidia")
			#echo "intelnvidia (optimus)"
			echo "optimus"
			;;
		"advancednvidia")
			#echo "advancednvidia (optimus)"
			echo "optimus"
			;;
		"advancedintel")
			#echo "amd and intel"
			;;
		"*")
			echo "unknown gpu" #debug
		esac
}
get_gpu
