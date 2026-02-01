#!/bin/bash

if [ "$JAVA_HOME" == "" ]
then
    export JAVA_HOME=/opt/lesspaper/jdk
    export PATH=$JAVA_HOME/jre/bin:$JAVA_HOME/bin:$PATH
fi

serverText=lesspaper/tomcat

while getopts "j:t:" opt; do
    case "$opt" in
    j)  if [ "$OPTARG" != "__NO__" ]
        then
            export JAVA_HOME=$OPTARG
            export PATH=$JAVA_HOME/jre/bin:$JAVA_HOME/bin:$PATH
        fi
        ;;
    t)  if [ "$OPTARG" != "__NO__" ]
        then
            export serverText=$OPTARG
        fi
        ;;
esac
done

datfile=/var/tmp/zblp_tomcatstat.$(echo $serverText | tr -d '/').$(date +"%d").dat
lastfile=/var/tmp/zblp_tomcatstat.$(echo $serverText | tr -d '/').$(date +"%d").last

pid=$(ps -ef | grep java | grep "$serverText" | grep -v grep | awk '{print $2}')
if [ "$pid" != "" ]
then
    line=$(jstat -gc $pid | tail -n 1)
    if [ "$line" != "" ]
    then
        read S0C S1C S0U S1U EC EU OC OU MC MU CCSC CCSU YGC YGCT FGC FGCT GCT <<< $line

        if [ ! -f $lastfile ]
        then
            echo "$FGC $FGCT $GCT" > $lastfile
        fi
        read LFGC LFGCT LGCT < "$lastfile"

        if [ ! -f $datfile ]
        then
            # reset sum FGC FGCT GCT every day
            echo "0 0 0" > $datfile
        fi
        read SFGC SFGCT SGCT < "$datfile"

        DELTA_FGC=$(awk "BEGIN { if ($FGC > $LFGC) print $FGC - $LFGC; else print 0 }")
        DELTA_FGCT=$(awk "BEGIN { if ($FGCT > $LFGCT) print $FGCT - $LFGCT; else print 0 }")
        DELTA_GCT=$(awk "BEGIN { if ($GCT > $LGCT) print $GCT - $LGCT; else print 0 }")

        SFGC=$(awk "BEGIN { print $SFGC + $DELTA_FGC }")
        SFGCT=$(awk "BEGIN { print $SFGCT + $DELTA_FGCT }")
        SGCT=$(awk "BEGIN { print $SGCT + $DELTA_GCT }")

        echo "$FGC $FGCT $GCT" > $lastfile
        echo "$SFGC $SFGCT $SGCT" > $datfile

        echo "{\"S0C\":$S0C,\"S1C\":$S1C,\"S0U\":$S0U,\"S1U\":$S1U,\"EC\":$EC,\"EU\":$EU,\"OC\":$OC,\"OU\":$OU,\"MC\":$MC,\"MU\":$MU,\"YGC\":$YGC,\"YGCT\":$YGCT,\"FGC\":$SFGC,\"FGCT\":$SFGCT,\"GCT\":$SGCT}"
    fi
else
    echo "{}"
fi
