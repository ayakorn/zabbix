#!/bin/bash

mode=0

while getopts "f:m:" opt; do
    case "$opt" in
        f)  export url=$OPTARG
            ;;
        m)  export mode=$OPTARG
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

if [ "$mode" == "0" ]
then
    tmpfile=/tmp/zblp_tomcatheap.$$

    rdom () { local IFS=\> ; read -d \< E C ;}

    curl --connect-timeout 5 -s "$url/monitoring?format=xml&part=jvm" | while rdom; do
        if [[ $E = "usedMemory" ]]; then
            echo "$E=$C"
        fi
        if [[ $E = "maxMemory" ]]; then
            echo "$E=$C"
        fi
    done > $tmpfile
    if [ -s $tmpfile ]
    then
        usedMemory=$(cat $tmpfile | awk -F= '/usedMemory/ {print $2}')
        maxMemory=$(cat $tmpfile | awk -F= '/maxMemory/ {print $2}')
        pct=$(expr $usedMemory \* 100 / $maxMemory)
        echo -e "$maxMemory"
    else
        echo -e "0"
    fi
    rm $tmpfile
else
    echo -e $(curl --connect-timeout 5 -s "$url/status/memory/max")
fi
