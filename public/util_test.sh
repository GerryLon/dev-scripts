#!/bin/bash

. "./util.sh"

if ! isCmdExist ls; then
	echo 'isCmdExists ls, BUG'
	exit 1
fi

if isCmdExist xxx; then
	echo 'isCmdExists xxx, BUG'
	exit 1
fi


mongodbRoot="/usr/local/mongodb"

realCmd=`selectCmd mongo "$mongodbRoot/bin/mongo"`
echo $?
echo $realCmd
# nothing output is OK

