#!/bin/bash

dir=/var/log/zulip/queue_error
tmp1=/var/tmp/zbzl_qerr.log

prevmodify=0
if [ -f $tmp1 ]
then
    prevmodify=$(cat $tmp1)
fi

lastfile=$(ls -t /var/log/zulip/queue_error/*.errors 2>/dev/null | head -1)
if [ "$lastfile" != "" ]
then
    lastmodify=$(stat -c %Y $lastfile)
fi

if [[ $lastmodify -gt $prevmodify || $lastmodify -eq 0 ]]
then
    echo 1
else
    echo 0
fi

echo $lastmodify > $tmp1
