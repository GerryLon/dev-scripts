#!/bin/bash

# start development services

scriptDir=$(cd `dirname $0`; pwd)

# import public scripts
. "$scriptDir/public/index.sh"

softDir=/opt
startDir=`pwd`
appConf="$scriptDir/app.properties"

# mount  windows dir
function mountWorkspace() {
	mountFlag=`getProperty $appConf mount`
	if [ "x$mountFlag" != "x1" ]; then
		echoWarn "you do not wanna install git"
		return 1
	fi
	
	mountIp=`getProperty $appConf mountIp`
	mountUsername=`getProperty $appConf mountUsername gerrylon`
	mountPassword=`getProperty $appConf mountPassword gerrylon`
	mountSrcDir=`getProperty $appConf mountSrcDir workspace`
	mountDstDir=`getProperty $appConf mountDstDir /var/workspace`
	
	if ! isValidIp "$mountIp"; then
		echoError "invalid ip found: $mountIp, please check!"
		return 1
	fi

	df -h | grep -q "$mountDstDir"
	if [ $? -eq 0 ]; then
		echoInfo "//$mountIp/$mountSrcDir was already mounted to $mountDstDir"
		return
	fi
	echo "mounting //$mountIp/$mountSrcDir to $mountDstDir"
	[ ! -d $mountDstDir ] && echoWarn "creating dir: $mountDstDir" && mkdir -p "$mountDstDir"
	mount -t cifs -o username=$mountUsername,password=$mountPassword,vers=2.0,iocharset=utf8 //$mountIp/$mountSrcDir $mountDstDir

	df -h | grep -q "$mountDstDir"
	if [ $? -ne 0 ]; then
		echoError "mount error"
		return 1
	fi
	echoInfo "mount success"
	return $?
}
mountWorkspace

# start docker
if isCmdExist docker; then
	ps -ef | grep docker | grep -v grep
	
	if [ $? -eq 0 ]; then
		echoInfo 'docker is already running'
	else
		echoInfo "starting docker..."
		service docker start
	fi
else
	echoWarn 'docker is not installed'
fi

# start nginx
nginxCmd=`getProperty $appConf nginxRoot`/sbin/nginx
if [ -x $nginxCmd ]; then
	ps -ef | grep nginx | grep -v grep
	if [ $? -eq 0 ]; then
		echoInfo 'nginx is running'
	else
		echoInfo 'start nginx'
		$nginxCmd
	fi
fi

# start mysql
if isCmdExist mysql; then
    ps -ef | grep mysql | grep -v grep

    if [ $? -eq 0  ]; then
        echoInfo 'mysql is already running'
    else
        service mysql restart
    fi
fi

# nptdate cn.pool.ntp.org
if isCmdExist ntpdate; then
    echoInfo "sync time..."
    ntpdate cn.pool.ntp.org
fi


