#!/bin/bash

# work dir
scriptDir=$(cd `dirname $0`; pwd)

# import public scripts
. "$scriptDir/public/index.sh"
appName="${0##*[\\/]}" # xx.sh
appName=(${appName//\./ })
logFile="$scriptDir/${appName[0]}"".log" # xx.log
etcProfile='/etc/profile'
startDir=`pwd`
appConf="$scriptDir/app.properties"
softDir=`getProperty $appConf softDir`

rm -rf $logFile
echoInfo "install log will be set at:"
echoInfo "$logFile"
echo

# write log to $logFile when install soft
function appLog() {
    log $1 $logFile
}

function failedAppLog() {
    log "failed: $1" $logFile
}

function successAppLog() {
    log "success: $1" $logFile
}

if [ $UID -ne 0 ]; then
	echoInfo 'You are not root user'
	exit 1
fi

[ ! -d $softDir ] && echoInfo "$softDir not exist, creating..." && mkdir -p "$softDir"

# install wget
if ! isCmdExist wget; then
	echoInfo 'installing wget'
	yum install -y wget
else
	echoInfo 'wget was already installed'
fi

# install aliyun yum repository
echoInfo 'checking aliyun yum repository'
if ! yum repolist | grep -q 'aliyun.com'; then
	echoInfo 'installing aliyun yum repository ...'
	mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
	wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
	yum makecache
else
	echoInfo 'aliyun yum repository was already installed'
fi

# install sys tools
function installSystools() {
	local systools=""
	local systoolsFromConf=`getProperty $appConf systools`
	local systoolsArr=(${systoolsFromConf//,/ }) # split by , to array
	for i in "${!systoolsArr[@]}"; do
		# if ! isCmdExist "${systoolsArr[i]}"; then
		rpm -q "${systoolsArr[i]}"
		if [ $? -ne 0 ]; then
			systools="$systools ${systoolsArr[i]}"
		else
			echoInfo "${systoolsArr[i]} was already installed"
		fi
	done
	if [ -n "$systools" ]; then
		echoInfo "installing $systools"
		# notice: $systools instead of "$systools"
		yum install -y $systools
	fi

	cat /etc/vimrc | grep -q 'set ts=4'
	if [ $? -ne 0 ]; then
		echo "set nu
set ts=4
set ai
set shiftwidth=4
	" >> /etc/vimrc
	fi
}
installSystools

function installGit() {
    local soft=git
    local installFlag=$(getProperty $appConf $soft)
	if [ "$installFlag" != "1" ]; then
		echoWarn "you do not wanna install $soft"
		return
	fi
    
    local gitVersion=$(getProperty $appConf gitVersion)
    local gitRoot=$(getProperty $appConf gitRoot)

	# install git
	if ! isCmdExist git; then
		echoInfo 'installing git ...'
		# kernel dependency
		yum install -y curl-devel expat-devel gettext-devel openssl-devel zlib-devel
		
		# avoid "tclsh failed; using unoptimized loading"
		yum install -y tcl build-essential tk gettext

		# install from source code,will cause error, should install below
		yum install -y perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker
		
		local gitBall="git-$gitVersion.tar.xz"
		
        wget -O "$softDir/$gitBall" -c "https://mirrors.edge.kernel.org/pub/software/scm/git/$gitBall"
        cd $softDir && tar -xJf "$gitBall"
        cd "$softDir/git-$gitVersion"
        ./configure --prefix="$gitRoot"
        make all
        make install
        
        if [ $? -ne 0 ]; then
            echoWarn "install $soft failed!!!"
            return
        fi

        lnsfFiles "$gitRoot/bin" "/usr/local/bin"
		git version >/dev/null 2>&1
		
		if [ $? -ne 0 ]; then
            failedAppLog "install git"
			echoError 'install git failed, please check!'
            return 1
		else
			echoInfo 'install git success'
		fi
        cd $startDir
	else
		echoInfo 'git was already installed'
	fi
	git version
	echo 'config git alias'
	git config --global alias.st "status"
	git config --global alias.br "branch"
	git config --global alias.co "checkout"
	git config --global alias.cm "commit -m"
	git config --global alias.df "diff"
	git config --global alias.sh "stash"
}
installGit

function installGo() {
	local installFlag=$(getProperty $appConf go)
	if [ "$installFlag" != "1" ]; then
		echoWarn "you do not wanna install golang"
		return
	fi

	# install golang
	if ! isCmdExist go; then
		echoInfo 'installing golang ...'
		goroot=`getProperty $appConf goroot`
		gopath=`getProperty $appConf gopath`

		test ! -d $goroot && mkdir -p $goroot
		test ! -d $gopath && mkdir -p $gopath

		golangBall='go1.11.linux-amd64.tar.gz'

		wget -O "$softDir/$golangBall" -c "https://studygolang.com/dl/golang/$golangBall"	
		if [ $? -ne 0 ]; then
			echoError 'download golang tarball failed, please check!'
			exit 1
		fi

		tar -C /usr/local -xzf "$softDir/$golangBall"
		
		echo "# added on `date +"%Y-%m-%d %H:%M:%S"`
export GOROOT=$goroot
export GOPATH=$gopath
export GOBIN=
export PATH=\$PATH:\$GOROOT/bin:\${GOPATH//://bin:}/bin" >> $etcProfile
		source $etcProfile
		
		go version >/dev/null 2>&1

		if [ $? -ne 0 ]; then
            failedAppLog "install go"
			echoError 'install golang failed, please check!'
			exit 1
		else
			echoInfo 'install golang success'
		fi
	else
		echoInfo 'go was already installed'
	fi
	go version
}
installGo

function installRedis() {
	local installFlag=$(getProperty $appConf redis)
	if [ "$installFlag" != "1" ]; then
		echoWarn "you do not wanna install redis"
		return
	fi

	local redisRoot=`getProperty $appConf redisRoot`
	# redisRoot=${redisRoot:-'/usr/local/redis'} # redis root default value	
	if [ $? -ne 0 ]; then
		redisRoot=/usr/local/redis
		echoWarn "redisRoot is not set, using defaults: $redisRoot"
	else
		echoInfo "Config: redisRoot=$redisRoot"
	fi
	[ ! -d "$redisRoot" ] && echo "creating dir: $redisRoot" && mkdir -p "$redisRoot"

	if ! isCmdExist "$redisRoot/bin/redis-server"; then
		redisVersion=`getProperty $appConf redisVersion`
		if [ $? -ne 0 ]; then
			redisVersion=4.0.11
			echoWarn "redisVersion is not set, using defaults: $redisVersion"
		else
			echoInfo "Config: redisVersion=$redisVersion"
		fi
		redisSrcDir="redis-$redisVersion"
		redisBall="$redisSrcDir.tar.gz"
		
		# [ ! -f "$softDir/redis-$redisVersion.tar.gz" ] \
		echoInfo "downloading redis-$redisVersion.tar.gz"
		wget -O "$softDir/$redisBall" -c "http://download.redis.io/releases/$redisBall"
	 	[ $? -ne 0 ] && echo "download $redisBall failed" && failedAppLog "download $redisBall" && exit 1
		cd "$softDir"
		tar -zxf "$redisBall"
		cd "$redisSrcDir"
		make && cd src && make install PREFIX="$redisRoot"
		[ $? -ne 0 ] && echoError 'make redis failed' && failedAppLog "make redis" && exit 1
		[ ! -d "$redisRoot/conf" ] && echo "mkdir $redisRoot/conf" && mkdir "$redisRoot/conf"
		cp ../redis.conf "$redisRoot/conf"
		echo 'make soft link for redis commands in /usr/local/bin'
		for i in `ls $redisRoot/bin`; do
			ln -s "$redisRoot/bin/$i" "/usr/local/bin/$i"
		done

		echoInfo 'install redis success'
		cd $startDir
	else
		echoInfo "redis was already installed"
	fi
	"$redisRoot"/bin/redis-server -v
}
installRedis

function installDocker() {	
	local installFlag=$(getProperty $appConf docker)
	if [ "$installFlag" != "1" ]; then
		echoWarn "you do not wanna install docker"
		return
	fi
	
	if ! isCmdExist docker; then
		echoInfo 'installing docker'
		rpm -Uvh http://ftp.riken.jp/Linux/fedora/epel/6Server/x86_64/epel-release-6-8.noarch.rpm
		yum install -y docker-io
		
		[ $? -ne 0 ] && echoError 'install docker failed' && failedAppLog "install docker"  && exit 1
		local dockerStartOnBoot=$(getProperty $appConf dockerStartOnBoot)
		[ "$dockerStartOnBoot" == "1" ] && echo "Config: dockerStartOnBoot=1" && chkconfig docker on && chkconfig --list
	else
		echoInfo 'docker was already installed, version:'
		docker version && echo
	fi
	return $?
}
installDocker

function installNginx() {
	local installFlag=$(getProperty $appConf nginx)
	if [ "$installFlag" != "1" ]; then
		echoWarn "you do not wanna install nginx"
		return
	fi

	local nginxVersion=`getProperty $appConf nginxVersion 1.14.1`
	local nginxRoot=`getProperty $appConf nginxRoot /usr/local/nginx`
	local nginxBall="nginx-$nginxVersion.tar.gz"
	
	if [ -x $nginxRoot/sbin/nginx ]; then
		echoInfo 'nginx was already installed'
		$nginxRoot/sbin/nginx -v
		return 0
	fi

	echoInfo "installing nginx"

	wget -O "$softDir/$nginxBall" -c "http://nginx.org/download/$nginxBall"
	cd "$softDir"
	tar -zxf $nginxBall
	
	local pcreBall="pcre-8.42.tar.gz"
	wget -O "$softDir/$pcreBall" -c "https://ftp.pcre.org/pub/pcre/$pcreBall" \
		&& tar -zxf "$pcreBall" \
		|| { echoError "doanload $pcreBall failed" && failedAppLog "download $pcreBall"; }
	
	local zlibBall="zlib-1.2.11.tar.gz"
	wget -O "$softDir/$zlibBall" -c "http://zlib.net/$zlibBall" \
		&& tar -zxf "$zlibBall" \
		|| { echoError "doanload $zlibBall failed" && failedAppLog "download $zlibBall"; }

	cd "$softDir/nginx-$nginxVersion"
	./configure --prefix=$nginxRoot \
		--with-pcre=$softDir/pcre-8.42 \
		--with-zlib=$softDir/zlib-1.2.11
	
	make && make install
	
	[ $? -ne 0 ] && echoError "install nginx failed" && failedAppLog "install nginx"  && exit 1
	
	echoInfo "install nginx success"
	$nginxRoot/sbin/nginx -v
	cd $startDir
	return 0
}
installNginx

function installMysql() {
	local installFlag=$(getProperty $appConf mysql)
	if [ "$installFlag" != "1" ]; then
		echoWarn "you do not wanna install mysql"
		return
	fi
   
    if isCmdExist mysql; then
        echoInfo "mysql was already installed"
        return 0
    fi
    yum remove -y mariadb* # for centos7
    ps -ef | grep mysql | grep -v grep
    if [ $? -eq 0 ]; then
        echoInfo "mysql is running..."
        return 0
    fi

    local mysqlServerBall='MySQL-server-5.5.62-1.el6.x86_64.rpm'
    local mysqlClientBall='MySQL-client-5.5.62-1.el6.x86_64.rpm'
    wget -O "$softDir/$mysqlServerBall" -c "https://dev.mysql.com/get/Downloads/MySQL-5.5/$mysqlServerBall" \
        || { echoInfo "download $mysqlServerBall failed" && failedAppLog "download $mysqlServerBall" && exit 1; }
    wget -O "$softDir/$mysqlClientBall" -c "https://dev.mysql.com/get/Downloads/MySQL-5.5/$mysqlClientBall" \
        || { echoInfo "download $mysqlClientBall failed" && failedAppLog "download $mysqlClientBall" && exit 1; }
    yum remove -y mysql*
    cd $softDir
    
    if rpm -qa | grep  MySQL-server; then
        echo 'mysql server was already installed'
    else
        echoInfo "installing mysql server"
        yum -y localinstall $mysqlServerBall
        [ $? -ne 0 ] && echoError "install mysql server failed" \
            && failedAppLog "install mysql server"  && exit 1
    fi

    if rpm -qa | grep  -q MySQL-client; then
        echo 'mysql client was already installed'
    else
        echoInfo "installing mysql client"
        yum -y localinstall $mysqlClientBall
        [ $? -ne 0 ] && echoError "install mysql client failed" \
            && failedAppLog "install mysql client" && exit 1
    fi

    echoInfo "install mysql success"
    cd $startDir

    local mysqlPassword=`getProperty $appConf mysqlPassword`
    
    echoInfo "set mysql password"
    service mysql restart && mysqladmin -uroot password $mysqlPassword
    [ $? -eq 0 ] && echoInfo "set mysql password success" || echo "set mysql password failed!"
}
installMysql

function installNodejs() {
	local installFlag=$(getProperty $appConf nodejs)
	if [ "$installFlag" != "1" ]; then
		echoWarn "you do not wanna install nodejs"
		return
	fi
    
    local nodejsVersion=$(getProperty $appConf nodejsVersion)
    local nodejsRoot=$(getProperty $appConf nodejsRoot)

    if isCmdExist node; then
        echoInfo "nodejs was already installed, version: `node -v`"
        return 0
    fi

    local nodejsBall="node-v$nodejsVersion-linux-x64.tar.xz"
    wget -O "$softDir/$nodejsBall" -c "https://nodejs.org/dist/v$nodejsVersion/$nodejsBall" \
        || { echoError "download $nodejsBall failed" \
        && failedAppLog "download $nodejsBall" && exit 1; }

    cd $softDir && tar -xJf $nodejsBall
    test -d $nodejsRoot || mkdir $nodejsRoot
    cp -rfu "node-v$nodejsVersion-linux-x64"/* $nodejsRoot
    # mv "$softDir/node-v$nodejsVersion-linux-x64" $nodejsRoot

    # create symbol link for nodejs relative command: node npm etc.
    for i in `ls $nodejsRoot/bin`; do
        test -x "$nodejsRoot/bin/$i" && ln -sf "$nodejsRoot/bin/$i" "/usr/local/bin/$i"
    done

    echoInfo "install nodejs success"
    node -v
    cd $startDir
}
installNodejs

function installMongodb() {
    local soft=mongodb
	local installFlag=$(getProperty $appConf $soft)
	if [ "$installFlag" != "1" ]; then
		echoWarn "you do not wanna install $soft"
		return
	fi
    
    local mongodbVersion=$(getProperty $appConf mongodbVersion)
    local mongodbRoot=$(getProperty $appConf mongodbRoot)
    local mongodbDataDir=$(getProperty $appConf mongodbDataDir)
    
    local mainCmd=`selectCmd mongo "$mongodbRoot/bin/mongo"`

    if [ -n "$mainCmd" ]; then
        echo "$soft was already installed"
        return 0
    fi
    
    local softBall="mongodb-linux-x86_64-$mongodbVersion.tgz"
    wget -O "$softDir/$softBall" -c "https://fastdl.mongodb.org/linux/$softBall" \
        || { echo "download $softBall" \
        && failedAppLog "download $softBall" && exit 1; }

    cd $softDir && tar -xzf $softBall
    mv "mongodb-linux-x86_64-$mongodbVersion" "$mongodbRoot"

    # soft link, optional
    for i in `ls $mongodbRoot/bin`; do
        test -x "$mongodbRoot/bin/$i" && ln -sf "$mongodbRoot/bin/$i" "/usr/local/bin/$i"
    done

    if ps -ef | grep -q mongo | grep -v grep; then
        echo "$soft is running"
        return 0
    fi

    # --syslog:log will be write to /var/log/message
    # --fork daemon mode running
    mkdir -p "$mongodbDataDir"
    sh -c "$mongodbRoot/bin/mongod --dbpath=$mongodbDataDir --syslog --fork"
}
installMongodb

function installVimPlugins() {
    local soft=vimPlugins
	local installFlag=$(getProperty $appConf $soft)
	if [ "$installFlag" != "1" ]; then
		echoWarn "you do not wanna install $soft"
		return
	fi

    # sh -c "$startDir/public/vim_bootstrap.sh"
    cd $startDir
    wget -c -O "$startDir/bootstrap.sh" "https://raw.githubusercontent.com/GerryLon/spf13-vim/gerrylon_dev/bootstrap.sh" \
        || { echo "download vim_bootstrap.sh failed" \
        && failedAppLog "download vim_bootstrap.sh" && exit 1; }
    chmod u+x "$startDir/bootstrap.sh"
    $startDir/bootstrap.sh
    cd $startDir
}
installVimPlugins

function startServicesOnBoot() {
    local startOnBoot=`getProperty $appConf startServicesOnBoot`
    if [ "$startOnBoot" != '1' ]; then
        echoWarn 'startServicesOnBoot disabled'
        return 1
    fi

    grep -q "$scriptDir/start_services.sh" /etc/rc.local

    if [ $? -ne 0 ]; then
        echo "[ -x $scriptDir/start_services.sh ] && $scriptDir/start_services.sh || echo \"start_services failed at \`date +'%Y-%m-%d %H:%M.%S'\`\" >> /var/log/start_services.log" >> /etc/rc.local
    fi
}
startServicesOnBoot
