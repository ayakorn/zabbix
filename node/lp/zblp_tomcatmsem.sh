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

echo -e $(curl --connect-timeout 5 -s "$url/status/availableMailSender")
