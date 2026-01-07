#!/bin/bash

datfile=~/zabbix/zblp_site.dat
export zbhost=__NO__
export zbserver=__NO__
export zbhome=~/zabbix
export verbose=0
tmpinput=/var/tmp/zblp_sitetcmaxpool.$(whoami).dat

while getopts "f:t:r:z:h:s:v" opt; do
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

if [ ! -f $url ]
then
    exit 0
fi

> $tmpinput
for config in $(cat $datfile | grep -v '^#')
do
    site=$(echo $config | cut -f1 -d,)
    url=$(echo $config | cut -f2 -d,)
    url=${url%/}    # remove last /
    url="$url/$site/monitoring?part=jvm&format=xml"
    val=$(curl -s $url | grep -o '<maxConnectionCount>[0-9]*</maxConnectionCount>' | grep -o '[0-9]\+')
    if [ "$val" == "" ]
    then
        echo "$zbhost lesspaper.site.$site.tomcat.jdbcmaxpool 50" >> $tmpinput
    else
        echo "$zbhost lesspaper.site.$site.tomcat.jdbcmaxpool $val" >> $tmpinput
    fi
done

if [ $verbose ]
then
    cat $tmpinput
else
    $zbhome/bin/zabbix_sender -z $zbserver -i $tmpinput
fi
#rm $tmpinput

