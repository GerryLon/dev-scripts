#!/bin/bash

scriptDir=$(cd `dirname $0`; pwd)

newOne="$1"

if [[ x"$newOne" == xtrue ]]; then
	echo "stop current and run a new one"
	docker ps | grep elasticsearch/elasticsearch:6.7.2 | awk '{print $1}' | xargs docker stop
else
	if [[ `docker ps | grep elasticsearch/elasticsearch:6.7.2` ]]; then
		echo "already has one running"
		exit 1
	fi
fi

if [[ ! -d "$scriptDir/data" ]]; then
	echo "mkdir $scriptDir/data"
	mkdir -p "$scriptDir/data"
	chmod 777 "$scriptDir/data"
fi

docker run -d -v $scriptDir/data:/usr/share/elasticsearch/data -v $scriptDir/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" -e ELASTIC_PASSWORD=admin docker.elastic.co/elasticsearch/elasticsearch:6.7.2

