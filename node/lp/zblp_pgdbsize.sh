#!/bin/bash

# crontab user postgres
# 5 */6 * * * /home/affix/zabbix/lp/zblp_pgdbsize.sh -z 10.0.1.41 -h affixtest -d /opt/PostgreSQL/9.4 -s /home/affix/zabbix -n dbname > /dev/null 2>&1

export pgpath=/opt/PostgreSQL/9.5
export zbhost=__NO__
export zbserver=__NO__
export zbhome=~/zabbix
export verbose=false
export prefix=lesspaper

tmpinput=/var/tmp/zblp_pgdbstat.$(whoami).dat

while getopts "p:d:h:z:s:n:v" opt; do
    case "$opt" in
    p)  export prefix=$OPTARG
        ;;
    z)  export zbserver=$OPTARG
        ;;
    h)  export zbhost=$OPTARG
        ;;
    s)  export zbhome=$OPTARG
        ;;
    d)  export pgpath=$OPTARG
        ;;
    n)  export dbname=$OPTARG
        ;;
    v)  export verbose=true
        ;;
    esac
done

. $pgpath/pg_env.sh
> $tmpinput

psql -A -F' ' -t -h 127.0.0.1 postgres <<! | awk 'BEGIN { zbhost = ENVIRON["zbhost"]; dbname = ENVIRON["dbname"]; prefix = ENVIRON["prefix"] } {printf "%s %s.db.size.%s %s\n", zbhost, prefix, dbname, $1}' >> $tmpinput
select pg_database_size(datname) from pg_database where datname = '${prefix}_$dbname';
\q
!

if [ $verbose == true ]
then
    cat $tmpinput
else
    $zbhome/bin/zabbix_sender -z $zbserver -i $tmpinput
fi
#rm $tmpinput
