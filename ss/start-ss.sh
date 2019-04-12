#!/bin/bash

ssPort=12345
ssPasswd='your password here'

iptables -A INPUT -p tcp --dport $ssPort -j ACCEPT
iptables -A INPUT -p udp --dport $ssPort -j ACCEPT
iptables -A OUTPUT -p tcp --sport $ssPort -j ACCEPT
iptables -A OUTPUT -p udp --sport $ssPort -j ACCEPT
service iptables save

# docker run --restart=always --name=myshadowsocks -d -p $ssPort:$ssPort -p $ssPort:$ssPort/udp oddrationale/docker-shadowsocks -s 0.0.0.0 -p $ssPort -k $ssPort  -m aes-256-cfb

docker build -t myss:1.0 .
docker run -d --restart=always -p $ssPort:$ssPort myss:1.0 -s 0.0.0.0 -p $ssPort -k $ssPasswd -m aes-256-cfb 

if [ "$?" -eq 0 ]; then
	echo "start ss success!"
else
	echo "start ss failed!"
fi
