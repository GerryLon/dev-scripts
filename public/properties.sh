#!/bin/bash

# Usage:
# getProperty propertiFile key [defaultValue]
function getProperty() {
	if [ $# -lt 2 ]; then
		echo 'Usage: getProperty propertiFile key [defaultValue]'
		return 1
	fi

	local propFile="$1"
	local key="$2"
	
	if [ ! -r "$propFile" ]; then
		echo 'properties fils is not readable'
		return 2
	fi

	local val=$(cat "$propFile" | grep -vE  '^$' | grep -vE '^\s*#' | grep "$key\s*=" | awk -F '=' '{print $2}' | sed -r 's/^\s*|\s*#.*$//g')
	
	# echo "val is: $val"
	if [ -n "$val" ]; then
		echo -n "$val"
		return 0
	elif [ -n "$3" ]; then # defaultValue
		echo -n "$3"
		return 0
	else
		return 3
	fi
}

# setProperty propertiFile key val
function setProperty() {
	if [ $# -ne 3 ]; then
		echo 'Usage: setProperty propertiFile key val'
		return 1
	fi

	local propFile="$1"
	local key="$2"
	local val="$3"
	
    if [ ! -r "$propFile" ]; then
		echo 'properties fils is not readable'
		return 2
	fi

	getProperty "$propFile" "$key" >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		sed -i "s/^\s*$key\s*=.*$/$key=$val/g" "$propFile"	
	else
		echo "$key=$val" >> "$propFile"
	fi

	return $?
}

# getProperty $1 $2 $3
