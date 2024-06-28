#!/bin/bash

# add cron to remove tmp file after 5 days
# 2 1 * * * find /var/tmp -type f -name zblp_* -mtime +5 -print0 2>/dev/null | xargs -r -0 rm

serverText=""
scpRemoteHost=""
site="default"

while getopts "f:t:r:s:" opt; do
    case "$opt" in
    f)  export url=$OPTARG
        ;;
    t)  if [ "$OPTARG" != "__NO__" ]
        then
            # case load balance, id in xml = "E328984EFA37D8484A48912B76ACFF69.server1"
            export serverText=$OPTARG
        fi
        ;;
    r)  if [ "$OPTARG" != "__NO__" ]
        then
            export scpRemoteHost=$OPTARG
        fi
        ;;
    s)  if [ "$OPTARG" != "__NO__" ]
        then
            export site=$OPTARG
        fi
        ;;
    esac
done

if [ "$url" == "" ]
then
    echo "-f http://localhost:7080/lesspaper -t serverIdText -r remoteSsh" >&2
    echo ZBX_NOTSUPPORTED
    exit
fi

url=${url%/}    # remove last /

tmpuser=/var/tmp/zblp_actuser.$(hostname).$site.$(whoami).dat
tmpsumuser=/var/tmp/zblp_sumuser.$(hostname).$site.$(whoami).$(date +"%d").dat
tmpuser1=/var/tmp/zblp_actuser.$site.$(whoami).tmp
tmpsumuser1=/var/tmp/zblp_actuser.$site.$(whoami).tmp

rdom () { local IFS=\> ; read -d \< E C ;}

if [ ! -f $tmpuser ]
then
    touch $tmpuser
fi

curl "$url/monitoring?part=sessions&format=xml" 2>/dev/null | while rdom; do
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
cat $tmpuser1 | wc -l
#out=$(cat $tmpuser1 | wc -l)
#echo $out
#echo "$(date) $url $out" >> /tmp/my.log
mv $tmpuser1 $tmpuser

if [ ! -f $tmpsumuser ]
then
    touch $tmpsumuser
fi
cat $tmpuser $tmpsumuser | sort | uniq > $tmpsumuser1
mv $tmpsumuser1 $tmpsumuser

if [ "$scpRemoteHost" != "" ]
then
    scp $tmpuser $scpRemoteHost:$tmpuser > /dev/null 2>/dev/null
    scp $tmpsumuser $scpRemoteHost:$tmpsumuser > /dev/null 2>/dev/null
fi


