#!/bin/bash

catalinaout=/opt/lesspaper/tomcat/logs
verbose=false
export zbhost=__NO__
export zbserver=__NO__
export zbhome=~/zabbix

while getopts "f:z:h:s:v" opt; do
    case "$opt" in
    f)  if [ "$OPTARG" != "__NO__" ]
        then
            export catalinaout=$OPTARG
        fi
        ;;
    z)  export zbserver=$OPTARG
        ;;
    h)  export zbhost=$OPTARG
        ;;
    s)  export zbhome=$OPTARG
        ;;
    v)  export verbose=true
        ;;
    esac
done

appid=$(echo $catalinaout | cut -d'/' -f4)
tmpinput=/var/tmp/zblp_mailcount.$appid.dat

cat $catalinaout/notify.log | grep --text "^$(date +'%d %b %Y')" | egrep 'mail to|\[@\].*mailRequired=true' | grep DEBUG | awk '
BEGIN {   
    zbhost = ENVIRON["zbhost"]
}
{
    site = $6;
    if (cnt[site]) {
        cnt[site] = cnt[site]+1;
    } else {
        cnt[site] = 1;
    }
}
END {
    for (s in cnt) {
        printf "%s lesspaper.site.%s.mailcount %d\n", zbhost, s, cnt[s]
    }
}' > $tmpinput

if [ $verbose == true ]
then
    cat $tmpinput
else
    $zbhome/bin/zabbix_sender -z $zbserver -i $tmpinput
fi
#rm $tmpinput
