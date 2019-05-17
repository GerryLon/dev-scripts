#!/bin/bash

scriptDir=$(cd `dirname $0`; pwd)
echo $scriptDir

docker run -d -v /root/vflow/es/kibana.yml:/usr/share/kibana/config/kibana.yml -p 5601:5601 kibana:6.7.2
