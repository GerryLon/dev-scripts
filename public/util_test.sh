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

# nothing output is OK

