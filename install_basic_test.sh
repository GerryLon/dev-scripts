#!/bin/bash

. "./public/index.sh"

etcProfile='/etc/profile'
# startDir=`pwd`
scriptDir=$(cd `dirname $0`; pwd)

gopath=`getProperty $scriptDir/app.properties gopath`
if [ $? -eq 0 ]; then
	echo "gopath $gopath"
else
	echo "gopath is null"
fi

redisRoot=`getProperty  $scriptDir/app.properties  redisRoot`
redisRoot=${redisRoot:-'/usr/local/redis33'} # redis root default value
echo "redisRoot: $redisRoot"




