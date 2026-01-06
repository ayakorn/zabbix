#!/bin/bash

# crontab user root
# */5 * * * * /home/lesspaper/zabbix/lp/zblp_http.sh -z 10.0.1.41 -h affixtest -s /home/lesspaper/zabbix > /dev/null 2>&1

export zbhost=__NO__
export zbserver=__NO__
export zbhome=~/zabbix
export verbose=0

export tmpinput=/var/tmp/apstat.$(whoami).dat

while getopts "h:z:s:1:2:v" opt; do
    case "$opt" in
    z)  export zbserver=$OPTARG
        ;;
    h)  export zbhost=$OPTARG
        ;;
    s)  export zbhome=$OPTARG
        ;;
    v)  export verbose=1
        ;;
    esac
done

> $tmpinput

today=$(date +"%d/%b/%Y")
grep lesspaper /var/log/apache2/access.log | grep -v speedtest | grep "\[$today:" | awk '
$NF ~ /^[0-9]+$/ {
                     if ($NF > 2000000) {
                         c++ 
                         total1 += $NF
                         total2 += $(NF-1)
                     }
                 }
             END {
                     printf "lesspaper.http.exectime %d\nlesspaper.http.exectimesum %d\nlesspaper.http.exectimesum2 %d\n", c, total1/1000000, total2/1000000
                 }' >> $tmpinput



sed -e "s/^/$zbhost /" $tmpinput > $tmpinput.$$
mv $tmpinput.$$ $tmpinput

if [ $verbose ]
then
    cat $tmpinput
else
    $zbhome/bin/zabbix_sender -z $zbserver -i $tmpinput
fi

#rm $tmpinput
