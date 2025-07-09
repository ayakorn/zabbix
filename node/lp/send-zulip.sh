#!/bin/bash

PATH=$PATH:$HOME/zabbix/bin

tmpuserrealm=/var/tmp/zbzl_userrealm.$(date +%w)
tmpsession1=/var/tmp/zbzl_session1.dat
tmpsession2=/var/tmp/zbzl_session2.dat
tmpzbdata=/var/tmp/zbzl_data

if [ ! -f $tmpuserrealm ]
then
    echo "select '''' || a.id || '''', b.name from zerver_userprofile a left join zerver_realm b on a.realm_id = b.id order by 1;" | psql -tAF $'\t' -h /var/run/postgresql zulip -U zulip > $tmpuserrealm
fi

echo "select session_data From django_session where expire_date >= 'now'" | psql -tA -h /var/run/postgresql zulip -U zulip > $tmpsession1
cd /home/zulip/deployments/current
./manage.py parse_session --file $tmpsession1 | grep -o "'_auth_user_id': '[0-9]*'" | cut -d':' -f2 | sort > $tmpsession2

join -1 1 -2 1 /var/tmp/zbzl_session2.dat /var/tmp/zbzl_userrealm.3 | awk '{print $2}' | sort | uniq -c | awk '
    {
        printf "zulip zulip.session.%s %d\n", $2, $1
        total += $1
    }
END {
        printf "zulip zulip.session.total %d\n", total
    }
' > $tmpzbdata

zabbix_sender -z 10.130.118.72 -i $tmpzbdata
