#!/bin/bash

# work dir
scriptDir=$(cd `dirname $0`; pwd)

# import public scripts
. "$scriptDir/public/index.sh"

etcProfile='/etc/profile'
softDir=/opt
startDir=`pwd`
appConf="$scriptDir/app.properties"

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
systools=""
for i in man strace vim gcc; do
	if ! isCmdExist "$i"; then
		systools="$systools $i"	
	else
		echoInfo "$i was already installed"
	fi
done
if [ -n "$systools" ]; then
	echoInfo "installing $systools"
	# notice: $systools instead of "$systools"
	yum install -y $systools
fi

cat /etc/vimrc | grep -q 'set ts=4'
if [ $? -ne 0 ]; then
	echo "
set nu
set ts=4
set ai
" >> /etc/vimrc
fi

# install git
if ! isCmdExist git; then
	echoInfo 'installing git ...'
	# kernel dependency
	yum install -y curl-devel expat-devel gettext-devel openssl-devel zlib-devel

	# install from source code,will cause error, should install below
	yum install -y perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker
	
	# uncompress git-x.y.z.tar.gz
	yum install -y xz

	gitBall='git-2.3.9.tar.xz'
	
	wget -O "$softDir/$gitBall" -c "https://mirrors.edge.kernel.org/pub/software/scm/git/$gitBall"
	tar -C "$softDir" -xJf "$softDir/$gitBall"
	cd "$softDir/git-2.3.9"
	make prefix=/usr/local all
	sudo make prefx=/usr/local install
	cd -

	if ! git version; then
		echoError 'install git failed, please check!'
		exit 1
	else
		echoInfo 'install git success'
	fi
else
	echoInfo 'git was already installed'
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
		echoError 'install golang failed, please check!'
		exit 1
	else
		echoInfo 'install golang success'
	fi
else
	echoInfo 'go was already installed'
fi
go version

redisRoot=`getProperty $appConf redisRoot`
# redisRoot=${redisRoot:-'/usr/local/redis'} # redis root default value	
if [ $? -ne 0 ]; then
	redisRoot=/usr/local/redis
	echoWarn "redisRoot is not set, using defaults: $redisRoot"
else
	echoInfo "load Config from $appConf, redisRoot=$redisRoot"
fi
[ ! -d "$redisRoot" ] && echo "creating dir: $redisRoot" && mkdir -p "$redisRoot"

if ! isCmdExist "$redisRoot/bin/redis-server"; then
	redisVersion=`getProperty $appConf redisVersion`
	if [ $? -ne 0 ]; then
		redisVersion=4.0.11
		echoWarn "redisVersion is not set, using defaults: $redisVersion"
	else
		echoInfo "load Config from $appConf, redisVersion=$redisVersion"
	fi
	redisSrcDir="redis-$redisVersion"
	redisBall="$redisSrcDir.tar.gz"
	
	# [ ! -f "$softDir/redis-$redisVersion.tar.gz" ] \
	echoInfo "downloading redis-$redisVersion.tar.gz"
	wget -O "$softDir/$redisBall" -c "http://download.redis.io/releases/$redisBall"
	[ $? -ne 0 ] && echo "doanload $redisBall failed" && exit 1
	cd "$softDir"
	tar -zxf "$redisBall"
	cd "$redisSrcDir"
	make && cd src && make install PREFIX="$redisRoot"
	[ ! -d "$redisRoot/conf" ] && echo "mkdir $redisRoot/conf" && mkdir "$redisRoot/conf"
	cp ../redis.conf "$redisRoot/conf"
	echo 'make soft link for redis commands in /usr/local/bin'
	for i in `ls $redisRoot/bin`; do
		ln -s "$redisRoot/bin/$i" "/usr/local/bin/$i"
	done

	cd $startDir
fi














