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
pid=$(ps -ef | grep java | grep "$serverText" | grep -v grep | awk '{print $2}')
if [ "$pid" != "" ]
then
    line=$(jstat -gc $pid | tail -n 1)
    if [ "$line" != "" ]
    then
        read S0C S1C S0U S1U EC EU OC OU MC MU CCSC CCSU YGC YGCT FGC FGCT GCT <<< $line

        if [ ! -f $datfile ]
        then
            # reset FGC FGCT GCT every day
            echo "$FGC $FGCT $GCT" > $datfile
        fi
        read PFGC PFGCT PGCT < "$datfile"

        if awk "BEGIN {exit !($GCT < $PGCT)}"
        then
            # reset if restart tomcat
            echo "$FGC $FGCT $GCT" > $datfile
        fi

        DELTA_FGC=$(awk "BEGIN { if ($FGC > $PFGC) print $FGC - $PFGC; else print 0 }")
        DELTA_FGCT=$(awk "BEGIN { if ($FGCT > $PFGCT) print $FGCT - $PFGCT; else print 0 }")
        DELTA_GCT=$(awk "BEGIN { if ($GCT > $PGCT) print $GCT - $PGCT; else print 0 }")

        echo "{\"S0C\":$S0C,\"S1C\":$S1C,\"S0U\":$S0U,\"S1U\":$S1U,\"EC\":$EC,\"EU\":$EU,\"OC\":$OC,\"OU\":$OU,\"MC\":$MC,\"MU\":$MU,\"YGC\":$YGC,\"YGCT\":$YGCT,\"FGC\":$DELTA_FGC,\"FGCT\":$DELTA_FGCT,\"GCT\":$DELTA_GCT}"
    fi
else
    echo "{}"
fi
