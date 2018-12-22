#!/bin/bash

# some utilities for shell scripts

function log() {
    local msg="$1"
    local logFile="$2"
    if [ -z "$msg" ] || [ -z "$logFile" ]; then
        return 1
    fi
	echo "[`date +"%Y-%m-%d %H:%M:%S"]` $msg" >> $logFile
}

# is a command exists?
# call like isCmdExist vim
function isCmdExist() {
	local cmd="$1"
	if [ -z "$cmd" ]; then
		echo "Usage isCmdExist yourCmd"
		return 1
	fi

	which "$cmd" >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		return 0
	fi

	return 2
}

# nginx or /usr/local/nginx/sbin/nginx or more
# if one of given command is executable, return it, or return null
function selectCmd() {
    local realCmd=

    for i in "$@"; do
        if isCmdExist $i; then
            echo "test33: $i"
            realCmd=$i
            break
        fi
    done

    echo $realCmd

    if [ -z $realCmd ]; then
        return 1;
    fi
    return 0
}

# check ipv4
function isValidIp() {
	local ip=$1
	local ret=1
	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		ip=(${ip//\./ }) # split by ., then ip is an array
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
		ret=$?
	fi

	return $ret
}

# echo text with red bg, white fg
function echoError() {
	local text="$1"
	if [ -z "$text" ]; then
 		echo "text is null"
  		return 1
	fi

    echo -e "\033[41;37m$text\033[0m"
}

# echo text with green bg and white fg
function echoSuccess() {
	local text="$1"
	if [ -z "$text" ]; then
 		echo "text is null"
		return 1
	fi
	
	echo -e "\033[42;37m$text\033[0m"
}

# blue bg, white fg
function echoInfo() {
	local text="$1"
	if [ -z "$text" ]; then
 		echo "text is null"
		return 1
	fi
	
	echo -e "\033[44;37m$text\033[0m"
}

# yello bg, red fg
function echoWarn() {
	local text="$1"
	if [ -z "$text" ]; then
 		echo "text is null"
		return 1
	fi
	
	echo -e "\033[43;31m$text\033[0m"
}

# make soft link force for all execute files with given dir
function lnsfFiles() {
    local sourceDir="$1"
    local targetDir="$2"

    if [ ! -d $dir ]; then
        return 1
    fi

    for i in `ls $sourceDir`; do
        ln -sf "$sourceDir/$i" "$targetDir/$i"
    done
}

