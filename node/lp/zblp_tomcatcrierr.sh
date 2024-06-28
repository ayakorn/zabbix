#!/bin/bash

progname=$(basename $0)
catalinaout=/opt/lesspaper/tomcat/logs
logfile=catalina.out

while getopts "f:" opt; do
    case "$opt" in
    f)  if [ "$OPTARG" != "__NO__" ]
        then
            export catalinaout=$OPTARG
        fi
        ;;
    esac
done

appid=$(echo $catalinaout | cut -d'/' -f4)
appid2=""
if [ "$progname" == "zblp_lphubcrierr.sh" ]
then
    logfile=lphub.log
    appid2=".hub"
fi

tmpdat=/var/tmp/zblp_tomcatcrierr.${appid}${appid2}.$(date +"%d").dat

if [ ! -f $tmperr ]
then
    if [ -f $tmperr1 ]
    then
        cp $tmperr1 $tmperr
    else
        > $tmperr
    fi
fi

if [ -f $tmpdat ]
then
    cat $tmpdat
else
    echo 0
fi
