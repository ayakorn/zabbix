#!/bin/bash

# add cron to remove tmp file after 5 days
# 2 1 * * * find /var/tmp -type f -name zblp_* -mtime +5 -print0 2>/dev/null | xargs -r -0 rm

serverText=""
scpRemoteHost=""
site="default"

while getopts "f:" opt; do
    case "$opt" in
    f)  export url=$OPTARG
        ;;
    esac
done

if [ "$url" == "" ]
then
    echo "-f http://localhost:7080/lesspaper" >&2
    echo ZBX_NOTSUPPORTED
    exit
fi

url=${url%/}    # remove last /

#curl -s "$url/monitoring?part=lastValue&graph=usedConnections" 2>/dev/null | awk '{printf "%d\n", $1}'
curl -s "$url/monitoring?part=jvm&format=xml" | grep -o '<maxConnectionCount>[0-9]*</maxConnectionCount>' | grep -o '[0-9]\+'
