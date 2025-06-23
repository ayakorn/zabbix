#!/usr/bin/bash
# Checks for any Zulip queue workers that are leaking memory and thus have a high vsize

#pid=$(/usr/bin/pgrep -xf 'python.* /home/zulip/deployments/current/manage.py process_queue .*')
pid=$(/usr/bin/pgrep -f zabbix)
if [ -z "$pid" ]; then
    echo "No workers running" >&2
    echo 0
fi

topvsize=$(/usr/bin/ps -o vsize,size,pid,user,command --sort -vsize $pid | /usr/bin/head -n2 | /usr/bin/tail -n1 | /usr/bin/cut -f2 -d' ')
echo $topvsize >&2
if [ "$topvsize" -gt 800000 ]; then
    echo 2
elif [ "$topvsize" -gt 600000 ]; then
    echo 1
else
    echo 0
fi

