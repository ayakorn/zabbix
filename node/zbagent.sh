#!/bin/bash

PID=/tmp/zabbix_agentd.pid

basedir=$(dirname $0)

if [ -f $basedir/zb.conf ]
then
    . $basedir/zb.conf
fi

_stop() {
    if [ -f $PID ]
    then
        pid=$(cat $PID)
        echo kill $pid
        kill $pid
    else
        echo not found pid
    fi
}

_start() {
    $basedir/sbin/zabbix_agentd --config $basedir/etc/zabbix_agentd.conf
    sleep 3
    pid=$(cat $PID)
    echo "start agent with pid $pid"
}

case $1 in
    stop) _stop
        ;;
    start) _start
        ;;
    restart) _stop
        sleep 1
        _start
        ;;
esac
