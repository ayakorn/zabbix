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

tmperr=/var/tmp/zblp_tomcatcrierr.${appid}${appid2}.$(date +"%d").log
tmperr1=/var/tmp/zblp_tomcatcrierr.${appid}${appid2}.tmp
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

cat $catalinaout/$logfile | egrep 'StackOverflowError|OutOfMemoryError' > $tmperr1

num1=$(cat $tmperr1 | wc -l)
num2=$(cat $tmperr | wc -l)
diff=$(expr $num1 - $num2)

if [ ! -f $tmpdat ]
then
    echo 0 > $tmpdat
fi

diffprev=$(cat $tmpdat)

if [ $diff -lt 0 ]
then
    output=$(expr $diffprev + $num1)
else
    output=$(expr $diffprev + $diff)
fi

cp $tmperr1 $tmperr
echo $output > $tmpdat
cat $tmpdat
