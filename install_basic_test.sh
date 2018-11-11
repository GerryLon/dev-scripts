#!/bin/bash

. "./public/index.sh"

etcProfile='/etc/profile'
# startDir=`pwd`
scriptDir=$(cd `dirname $0`; pwd)

gopath=`readProperties $scriptDir/app.properties gopath`
if [ $? -eq 0 ]; then
	echo "gopath $gopath"
else
	echo "gopath is null"
fi






