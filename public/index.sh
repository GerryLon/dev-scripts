#!/bin/bash

# current script absolute path
# absPath=`readlink -f $0`
# currDir=$(cd `dirname $0`; pwd)
currDir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )

# echo "abs: $absPath"
# echo "curr: $currDir"

# import dependency
. "$currDir/util.sh"
. "$currDir/properties.sh"

# scriptIdPrefix='_'
# scriptId=`echo -n $absPath | md5sum | awk '{print $1}'`
# scriptId="$scriptIdPrefix$scriptId"
# 
# # show $scriptId has been exported
# env | grep $scriptId
# 
# if [ $? -eq 0 ]; then
# 	echoError "$absPath already been included, DO NOT Repeat!"
# 	exit 1
# fi
# 
# export $scriptId=1
