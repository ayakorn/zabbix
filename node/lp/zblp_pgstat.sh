#!/bin/bash

# crontab user postgres
# */5 * * * * /home/affix/zabbix/lp/zblp_pgstat.sh -z 10.0.1.41 -h affixtest -d /opt/PostgreSQL/9.4 -s /home/affix/zabbix -1 dbname1 -2 dbname2 > /dev/null 2>&1

export pgpath=/opt/PostgreSQL/9.5
export zbhost=__NO__
export zbserver=__NO__
export zbhome=~/zabbix
export verbose=false

tmplog=/var/tmp/zblp_pg.$(whoami).$(date +"%d").log
tmplogtxt=/var/tmp/zblp_pgtxt.$(whoami).$(date +"%d").log
tmplog1=/var/tmp/zblp_pg.$(whoami).tmp
tmpinput=/var/tmp/zblp_pgstat.$(whoami).dat
tmpsize=/var/tmp/zblp_pgsize.$(whoami).dat

export db1=""
export db2=""

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
    1)  export db1=$OPTARG
        ;;
    2)  export db2=$OPTARG
        ;;
    v)  export verbose=true
        ;;
    esac
done

export today=$(date +"%Y-%m-%d")
cat $pgpath/data/pg_log/postgresql.log | cut -c1-10000 | grep -v 'pg_stop_backup' | awk '
    BEGIN {   
              zbhost = ENVIRON["zbhost"]
              today = ENVIRON["today"]
              dflag = 0
              pflag = 0
          }
          {   
              if ($1 == today) {
                  if (index($0, " COPY ")>0 || index($0, " vacuum ")>0) {
                      dflag = 0
                      pflag = 0
                  } else {
                      if (pflag == 1) {
                          printf "\n"
                      }
                      dflag = 1
                      pflag = 0
                  }
              }
              if (dflag == 1) {   
                  if ($7 == "duration:") {
                      if ($8 > 1000) {
                          pflag = 1
                      } else {
                          pflag = 0
                      }
                  }

                  if (pflag == 1) {
                      print $0
                  }
              }
          }
' > $tmplog1

cat $tmplog1 | grep 'duration:' | awk '
    BEGIN {
              zbhost = ENVIRON["zbhost"]
              count = 0
              sqlsum = 0
          }
          {
              count++ 
              sqlsum += $8
          }
    END   { 
              printf "%s lesspaper.db.sqlCount %d\n", zbhost, count
              printf "%s lesspaper.db.sqlTime %d\n", zbhost, sqlsum/1000
          }
' > $tmpinput

if [ ! -f $tmplog ]
then
    touch $tmplog
fi

#diff $tmplog $tmplog2 | grep '^>' | tail -n +1 | cut -c3- > $tmplogtxt
diff $tmplog $tmplog1 | grep '^>' | cut -c3- > $tmplogtxt
mv $tmplog1 $tmplog

if [ -s $tmplogtxt ]
then
#    echo "$zbhost lesspaper.db.sqlText \"$(cat $tmplogtxt | sed ':a;N;$!ba;s/\n/\\n\\n/g')\"" >> $tmpinput
    echo "$zbhost lesspaper.db.sqlText \"$(cat $tmplogtxt | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')\"" >> $tmpinput
fi



if [ -s $tmpsize ]
then
    ptoday=$(cat $tmpsize)
else
    ptoday=""
fi

. $pgpath/pg_env.sh
if [ "$ptoday" != "$today" ]
then
    if [ "$db1" != "" ]
    then
        psql -A -F' ' -t -h 127.0.0.1 postgres <<! | awk 'BEGIN { zbhost = ENVIRON["zbhost"] } {printf "%s lesspaper.db.size.db1 %s\n", zbhost, $1}' >> $tmpinput
select pg_database_size(datname) from pg_database where datname = '$db1';
\q
!
    fi

    if [ "$db2" != "" ]
    then
        psql -A -F' ' -t -h 127.0.0.1 postgres <<! | awk 'BEGIN { zbhost = ENVIRON["zbhost"] } {printf "%s lesspaper.db.size.db2 %s\n", zbhost, $1}' >> $tmpinput
select pg_database_size(datname) from pg_database where datname = '$db2';
\q
!
    fi
fi

echo $today > $tmpsize

if [ $verbose == true ]
then
    cat $tmpinput
else
    $zbhome/bin/zabbix_sender -z $zbserver -i $tmpinput
fi
#rm $tmpinput
