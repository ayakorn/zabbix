#!/bin/bash

# crontab user postgres
# */5 * * * * /home/affix/zabbix/lp/zb_pgstat.sh -z 10.0.1.41 -d /opt/PostgreSQL/9.5 -h affixtest -s /home/affix/zabbix > /dev/null 2>&1

export pgpath=/opt/PostgreSQL/9.5
export zbhost=__NO__
export zbserver=__NO__
export zbhome=~/zabbix
export verbose=false

export tmpinput=/var/tmp/pgstat.$(whoami).dat
export phour=/var/tmp/pgstat.phour.$(whoami).dat
export pday=/var/tmp/pgstat.pday.$(whoami).dat

while getopts "d:h:z:s:1:2:v" opt; do
    case "$opt" in
    z)  export zbserver=$OPTARG
        ;;
    h)  export zbhost=$OPTARG
        ;;
    s)  export zbhome=$OPTARG
        ;;
    d)  export pgpath=$OPTARG
        ;;
    v)  export verbose=true
        ;;
    esac
done

if [ ! -f $pday ]; then touch $pday; fi
if [ ! -f $phour ]; then touch $phour; fi

doHour=false
doDay=false
date1=$(date '+%H')
if [ "$date1" != "$(cat $phour)" ]
then
    doHour=true
fi
echo $date1 > $phour

date2=$(date '+%d')
if [ "$date2" != "$(cat $pday)" ]
then
    doDay=true
fi
echo $date2 > $pday

. $pgpath/pg_env.sh

genInput() {
    while read line
    do
        echo "$line"
    done | psql -tAX -F'|' postgres 2>/dev/null | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk -F'|' '{ if ($2~/^[0-9]+(\.[0-9]+){0,1}$/) { printf "%s %s\n", $1, $2 } else { printf "%s \"%s\"\n", $1, $2 } }' >> $tmpinput
}

> $tmpinput

if [ $doHour == true ]
then
cat <<! | genInput
SELECT 'pgsql.cache.hit', ROUND(SUM(blks_hit)*100/SUM(blks_hit+blks_read), 2) FROM pg_stat_database;
!
fi

if [ $doDay == true ]
then
cat <<! | genInput
SELECT 'pgsql.config', json_build_object('extensions',(SELECT array_agg(extname) FROM (SELECT extname FROM pg_extension ORDER BY extname) as e),'settings', (SELECT json_object(array_agg(name),array_agg(setting)) FROM (SELECT name,setting FROM pg_settings WHERE name != 'application_name' ORDER BY name) as s));
!
fi

# do every 5min
cat <<! | genInput
SELECT 'pgsql.buffercache', row_to_json(j)
FROM (
    SELECT current_setting('block_size')::INT*COUNT(*) AS total,
           current_setting('block_size')::INT*SUM(CASE WHEN isdirty THEN 1 ELSE 0 END) AS dirty,
           current_setting('block_size')::INT*SUM(CASE WHEN isdirty THEN 0 ELSE 1 END) AS clear,
           current_setting('block_size')::INT*SUM(CASE WHEN reldatabase IS NOT NULL THEN 1 ELSE 0 END) AS used,
           current_setting('block_size')::INT*SUM(CASE WHEN usagecount>=3 THEN 1 ELSE 0 END) AS popular
    FROM pg_buffercache
    ) AS j;

SELECT 'pgsql.bgwriter', row_to_json(j)
FROM (
    SELECT checkpoints_timed, checkpoints_req, checkpoint_write_time, checkpoint_sync_time,
           current_setting('block_size')::INT*buffers_checkpoint AS buffers_checkpoint,
           current_setting('block_size')::INT*buffers_clean AS buffers_clean,
           MAXwritten_clean, current_setting('block_size')::INT*buffers_backend AS buffers_backend,
           buffers_backend_fsync, current_setting('block_size')::INT*buffers_alloc AS buffers_alloc
    FROM pg_stat_bgwriter
    ) AS j;

SELECT 'pgsql.uptime', (DATE_PART('EPOCH', NOW() - pg_postmaster_start_time())::INT);

SELECT 'pgsql.connections', row_to_json(j)
FROM (
    SELECT SUM(CASE WHEN state = 'active' THEN 1 ELSE 0 END) AS active,
           SUM(CASE WHEN state = 'idle' THEN 1 ELSE 0 END) AS idle,
           SUM(CASE WHEN state = 'idle in transaction' THEN 1 ELSE 0 END) AS idle_in_transaction,
           COUNT(*) AS total,
           COUNT(*)*100/(SELECT current_setting('max_connections')::INT) AS total_pct,
           SUM(CASE WHEN wait_event_type IN ('Lock','LWLock') THEN 1 ELSE 0 END) AS waiting
    FROM pg_stat_activity WHERE datid IS NOT NULL
    ) AS j;

SELECT 'pgsql.connections.prepared', COUNT(*) FROM pg_prepared_xacts;

SELECT 'pgsql.dbstat.sum', row_to_json(j)
FROM (
    SELECT SUM(numbackends) AS numbackends,
           SUM(xact_commit) AS xact_commit,
           SUM(xact_rollback) AS xact_rollback,
           SUM(blks_read) AS blks_read, SUM(blks_hit) AS blks_hit,
           SUM(tup_returned) AS tup_returned, SUM(tup_fetched) AS tup_fetched,
           SUM(tup_inserted) AS tup_inserted, SUM(tup_updated) AS tup_updated,
           SUM(tup_deleted) AS tup_deleted, SUM(conflicts) AS conflicts,
           SUM(temp_files) AS temp_files, SUM(temp_bytes) AS temp_bytes,
           SUM(deadlocks) AS deadlocks FROM pg_stat_database
    ) AS j;

SELECT 'pgsql.transactions.idle', coalesce(EXTRACT(epoch FROM MAX(AGE(now(), query_start))), 0)
FROM pg_stat_activity
WHERE state='idle in transaction';

SELECT 'pgsql.transactions.active', coalesce(EXTRACT(epoch FROM MAX(AGE(now(), query_start))), 0)
FROM pg_stat_activity
WHERE state <> 'idle in transaction' AND state <> 'idle';

SELECT 'pgsql.transactions.waiting', coalesce(EXTRACT(epoch FROM MAX(AGE(now(), query_start))), 0)
FROM pg_stat_activity WHERE wait_event_type IN ('Lock','LWLock');

SELECT 'pgsql.transactions.prepared', coalesce(EXTRACT(epoch FROM MAX(AGE(now(), prepared))), 0) FROM pg_prepared_xacts;

SELECT 'pgsql.pgstatstatements.avg_query_time', ROUND((SUM(total_time) / SUM(calls))::numeric,2) FROM pg_stat_statements;

SELECT 'pgsql.invalidindex', coalesce((array_agg(row_to_json(j)))[1], '{}'::json) FROM (SELECT relname FROM pg_class, pg_index WHERE pg_index.indisvalid = false AND pg_index.indexrelid = pg_class.oid) j;
!

sed -e "s/^/$zbhost /" $tmpinput > $tmpinput.$$
mv $tmpinput.$$ $tmpinput

if [ $verbose == true ]
then
    cat $tmpinput
else
    $zbhome/bin/zabbix_sender -z $zbserver -i $tmpinput
fi

#rm $tmpinput
