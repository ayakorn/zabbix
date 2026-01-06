#!/bin/bash

url=http://localhost:7080/lesspaper
export verbose=0
export zbhost=__NO__
export zbserver=__NO__
export zbhome=~/zabbix

while getopts "f:z:h:s:k:v" opt; do
    case "$opt" in
    f)  if [ "$OPTARG" != "__NO__" ]
        then
            export url=$OPTARG
        fi
        ;;
    z)  export zbserver=$OPTARG
        ;;
    h)  export zbhost=$OPTARG
        ;;
    s)  export zbhome=$OPTARG
        ;;
    k)  export key=$OPTARG
        ;;
    v)  export verbose=1
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

status=$(curl --connect-timeout 5 -s "$url/status/availableMailSender")

if [ $verbose ]
then
    echo $status
else
    $zbhome/bin/zabbix_sender -z $zbserver -s $zbhost -k "lesspaper.site.$key.mailsemaphore" -o $status
fi
