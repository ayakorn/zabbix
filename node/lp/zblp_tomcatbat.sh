#!/bin/bash

catalinapath=/opt/lesspaper/tomcat/logs

while getopts "f:" opt; do
    case "$opt" in
    f)  if [ "$OPTARG" != "__NO__" ]
        then
            export catalinapath=$OPTARG
        fi
        ;;
    esac
done

appid=$(echo $catalinapath | cut -d'/' -f4)
tmpbat=/var/tmp/zblp_tomcatbat.$appid.$(date +"%d").log
tmpbat1=/var/tmp/zblp_tomcatbat.$appid.tmp
tmpdat=/var/tmp/zblp_tomcatbat.$appid.$(date +"%d").dat

if [ ! -f $tmpbat ]
then
    if [ -f $tmpbat1 ]
    then
        cp $tmpbat1 $tmpbat
    else
        > $tmpbat
    fi
fi

cat $catalinapath/batch.log | grep 'ERROR' > $tmpbat1

num1=$(cat $tmpbat1 | wc -l)
num2=$(cat $tmpbat | wc -l)
diff=$(expr $num1 - $num2)

if [ ! -f $tmpdat ]
then
    echo 0 > $tmpdat
fi

diffprev=$(cat $tmpdat)

if [ $diff -lt 0 ]
then
    output=$(expr $diffprev + $num1)
    cp $tmpbat1 $tmpbattxt
else
    output=$(expr $diffprev + $diff)
fi

cp $tmpbat1 $tmpbat
echo $output > $tmpdat
cat $tmpdat
