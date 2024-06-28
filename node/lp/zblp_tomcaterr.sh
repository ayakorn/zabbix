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
if [ "$progname" == "zblp_lphuberr.sh" ]
then
    logfile=lphub.log
    appid2=".hub"
fi

tmperr=/var/tmp/zblp_tomcaterr.${appid}${appid2}.$(date +"%d").log
tmperr1=/var/tmp/zblp_tomcaterr.${appid}${appid2}.tmp
tmpdat=/var/tmp/zblp_tomcaterr.${appid}${appid2}.$(date +"%d").dat
tmpdat2=/var/tmp/zblp_tomcatcrierr.${appid}${appid2}.$(date +"%d").dat
tmperrtxt=/var/tmp/zblp_tomcaterrtxt.${appid}${appid2}.$(date +"%d").log

if [ ! -f $tmperr ]
then
    if [ -f $tmperr1 ]
    then
        cp $tmperr1 $tmperr
    else
        > $tmperr
    fi
fi

cat $catalinaout/$logfile | egrep 'Exception:|ERROR' | egrep -v 'notlogin|BadCredentialsException|Cannot cast object|ต้องอยู่ที่สถานะรอดำเนินการ|ยังไม่ได้กำหนด PIN|LesspaperLoginException: User not found|รหัสลงนามไม่ถูกต้อง|authfail|not found user|hbm2ddl.SchemaUpdate|IssueByEmail CONFIG ERROR|status code = 408|Connection timed out|Connection reset|ไม่มีบทบาท|status code = 401' > $tmperr1

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
    cp $tmperr1 $tmperrtxt
else
    output=$(expr $diffprev + $diff)
    diff $tmperr $tmperr1 | grep '^>' | cut -c3- > $tmperrtxt
fi

cat $tmperrtxt | egrep 'StackOverflowError|OutOfMemoryError|PSQLException: FATAL|PoolExhaustedException' | wc -l > $tmpdat2

cp $tmperr1 $tmperr
echo $output > $tmpdat
cat $tmpdat
