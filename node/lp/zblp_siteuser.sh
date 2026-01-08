#!/bin/bash

# add cron to remove tmp file after 5 days
# 2 1 * * * find /var/tmp -type f -name zblp_* -mtime +5 -print0 2>/dev/null | xargs -r -0 rm

datfile=~/zabbix/zblp_site.dat
serverText=""
scpRemoteHost=""
verbose=false
tmpinput=/var/tmp/zblp_siteuser.$(whoami).dat
export verbose=0
export zbhost=__NO__
export zbserver=__NO__
export zbhome=~/zabbix

while getopts "f:t:r:z:h:s:v" opt; do
    case "$opt" in
    f)  export datfile=$OPTARG
        ;;
    t)  if [ "$OPTARG" != "__NO__" ]
        then
            # case load balance, id in xml = "E328984EFA37D8484A48912B76ACFF69.server1"
            export serverText=$OPTARG
        fi
        ;;
    z)  export zbserver=$OPTARG
        ;;
    h)  export zbhost=$OPTARG
        ;;
    s)  export zbhome=$OPTARG
        ;;
    r)  if [ "$OPTARG" != "__NO__" ]
        then
            export scpRemoteHost=$OPTARG
        fi
        ;;
    v)  export verbose=1
        ;;
    esac
done

if [ ! -f $datfile ]
then
    exit 0
fi

> $tmpinput

for config in $(cat $datfile | grep -v '^#')
do
    site=$(echo $config | cut -f1 -d,)
    url=$(echo $config | cut -f2 -d,)
    url=${url%/}    # remove last /

    path=$(echo $config | cut -f3 -d,)
    site2=$site
    if [ "$path" != "" ]; then site2=$path; fi

#    tmpuser=/tmp/zblp_actuser.$(hostname).$site.$(whoami).dat
#    tmpsumuser=/tmp/zblp_sumuser.$(hostname).$site.$(whoami).$(date +"%d").dat
#    tmpuser1=/tmp/zblp_actuser.$site.$(whoami).tmp
#    tmpsumuser1=/tmp/zblp_actuser.$site.$(whoami).tmp

    tmpuser=/var/tmp/zblp_actuser.$(hostname).$site.$(whoami).dat
    tmpsumuser=/var/tmp/zblp_sumuser.$(hostname).$site.$(whoami).$(date +"%d").dat
    tmpuser1=/var/tmp/zblp_actuser.$site.$(whoami).tmp
    tmpsumuser1=/var/tmp/zblp_actuser.$site.$(whoami).tmp

    rdom () { local IFS=\> ; read -d \< E C ;}

    if [ ! -f $tmpuser ]
    then
        touch $tmpuser
    fi

    if [ "$site2" == "ROOT" ]
    then
        fullurl="$url/monitoring?part=sessions&format=xml"
    else
        fullurl="$url/$site2/monitoring?part=sessions&format=xml"
    fi
    curl "$fullurl" 2>/dev/null | while rdom; do
        if [[ $E = "id" ]]; then
            if [[ $C = *"$serverText"* ]]; then
                enable=1
            fi
        fi
        if [[ $E = "remoteUser" ]]; then
            if [ "$enable" == "1" ]; then
                echo $C
            fi
            enable=0
        fi
    done | sort | uniq > $tmpuser1
    mv $tmpuser1 $tmpuser
    echo "$zbhost lesspaper.site.$site.activeuser $(cat $tmpuser | wc -l)" >> $tmpinput

    if [ ! -f $tmpsumuser ]
    then
        touch $tmpsumuser
    fi
    cat $tmpuser $tmpsumuser | sort | uniq > $tmpsumuser1
    mv $tmpsumuser1 $tmpsumuser
    echo "$zbhost lesspaper.site.$site.sumuser $(cat $tmpsumuser | wc -l)" >> $tmpinput

    if [ "$scpRemoteHost" != "" ]
    then
        scp $tmpuser $scpRemoteHost:$tmpuser > /dev/null 2>/dev/null
        scp $tmpsumuser $scpRemoteHost:$tmpsumuser > /dev/null 2>/dev/null
    fi
done

if [ $verbose -eq 1 ]
then
    cat $tmpinput
else
    $zbhome/bin/zabbix_sender -z $zbserver -i $tmpinput
fi
#rm $tmpinput
