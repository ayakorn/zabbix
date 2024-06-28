#!/bin/bash

url=$1
if [ "$url" == "" ]
then
    echo $0 url
    exit 1
fi
datfile=/var/tmp/zblp_melody-$(echo $url | awk -F'/' '{printf "%s-%s", $3, $4}').dat

rdom () { local IFS=\> ; read -d \< E C ;}

items=('usedConnectionCount' 'maxConnectionCount' 'usedMemory' 'maxMemory')

curl  --connect-timeout 5 -s "$url/monitoring?format=xml&part=jvm" | while rdom; do
#cat jvm.xml | while rdom; do
    if [[ ${items[@]} =~ "$E" ]]; then
        if [[ "$E" != "" ]]; then
            echo "$E=$C"
        fi
    fi
done 
