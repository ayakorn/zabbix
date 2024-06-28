#!/bin/bash

# add cron to run script every day
# 2 5 * * * /home/lesspaper/zabbix/lp/zb_backuplog.sh -z zabbix -s lesspaper2 -k os > /tmp/zbsendos.log
# 3 5 * * * /home/lesspaper/zabbix/lp/zb_backuplog.sh -z zabbix -s lesspaper2db -k pg > /tmp/zbsendpg.log

zbhome=~/zabbix
zhost=zabbix
key=os

while getopts "h:z:s:k:" opt; do
    case "$opt" in
    h)  zbhome=$OPTARG
        ;;
    z)  zhost=$OPTARG
        ;;
    s)  host=$OPTARG
        ;;
    k)  key=$OPTARG
        ;;
    esac
done

if [ "$host" == "" ]
then
    echo "$0 -h [zbhome] -z [zbhost] -s [host] -k [os|pg]"
    exit 0
fi

lastmod=$(expr $(expr $(date +%s) - $(stat /tmp/backup$key.log -c %Y)) / 60 / 60)
if [ "$lastmod" -lt 15 ]
then
    $zbhome/bin/zabbix_sender -z $zhost -s $host -k backup.$key -o "$(tail /tmp/backup$key.log | sed 's/"/\\"/g')"
fi

