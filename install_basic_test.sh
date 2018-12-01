#!/bin/bash

. "./public/index.sh"

etcProfile='/etc/profile'
# startDir=`pwd`
scriptDir=$(cd `dirname $0`; pwd)
appConf="$scriptDir/app.properties"

gopath=`getProperty $scriptDir/app.properties gopath`
if [ $? -eq 0 ]; then
	echo "gopath $gopath"
else
	echo "gopath is null"
fi

redisRoot=`getProperty  $scriptDir/app.properties  redisRoot`
redisRoot=${redisRoot:-'/usr/local/redis33'} # redis root default value
echo "redisRoot: $redisRoot"

echo '-------------systools--------------'
function installSystools() {
	local systools=""
	local systoolsFromConf=`getProperty $appConf systools`
	local systoolsArr=(${systoolsFromConf//,/ }) # split by , to array
	for i in "${!systoolsArr[@]}"; do
		# if ! isCmdExist "${systoolsArr[i]}"; then
		rpm -qa | grep -q "${systoolsArr[i]}"
		if [ $? -ne 0 ]; then
			systools="$systools ${systoolsArr[i]}"
		fi
	done
	if [ -n "$systools" ]; then
		echoInfo "installing $systools"
        echo "systools to be installed: $systools"
		yum install -y $systools
	fi
}
installSystools
echo '-------------systools--------------'
