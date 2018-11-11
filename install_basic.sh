#!/bin/bash

# work dir
scriptDir=$(cd `dirname $0`; pwd)

# import public scripts
. "$scriptDir/public/index.sh"

etcProfile='/etc/profile'
softDir=/opt
# startDir=`pwd`
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

# install man
! isCmdExist man && echoInfo 'installing man' && yum install -y man

# install vim
if ! isCmdExist vim; then
	echoInfo 'installing vim ...'
	yum install -y vim
else
	echoInfo 'vim was already installed'
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
	yum install -y gcc curl-devel expat-devel gettext-devel openssl-devel zlib-devel

	# install from source code,will cause error, should install below
	yum install -y perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker
	
	# uncompress git-x.y.z.tar.gz
	yum install -y xz

	gitBall='git-2.3.9.tar.xz'
	
	if [ ! -f "$softDir/$gitBall" ]; then
		wget -O "$softDir/$gitBall" "https://mirrors.edge.kernel.org/pub/software/scm/git/$gitBall"
	fi
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
	goroot='/usr/local/go'
	gopath=`getProperty $appConf gopath`

	test ! -d $goroot && mkdir -p $goroot
	test ! -d $gopath && mkdir -p $gopath

	golangBall='go1.11.linux-amd64.tar.gz'

	if [ ! -f "$softDir/$golangBall" ]; then
		wget -O "$softDir/$golangBall" "https://studygolang.com/dl/golang/$golangBall"
		
		if [ $? -ne 0 ]; then
			echoError 'download golang tarball failed, please check!'
			exit 1
		fi
	fi

	tar -C /usr/local -xzf "$softDir/go1.11.linux-amd64.tar.gz"
	
	echo "# added on `date +"%Y-%m-%d %H:%M:%S"`
export GOROOT=$goroot
export GOPATH=$gopath
export GOBIN=
export PATH=\$PATH:\$GOROOT/bin:\${GOPATH//://bin:}/bin" >> $etcProfile
	source $etcProfile
	
	go version

	if [ $? -ne 0 ]; then
		echoError 'install golang failed, please check!'
		exit 1
	else
		echoInfo 'install golang success'
	fi
else
	echoInfo 'go was already installed'
fi
















