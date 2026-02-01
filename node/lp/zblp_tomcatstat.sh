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
    read S0C S1C S0U S1U EC EU OC OU MC MU CCSC CCSU YGC YGCT FGC FGCT GCT <<< $line

    # reset FGC FGCT GCT every day
    if [ ! -f $datfile ]
    then
        PFGC=$FGC
        PFGCT=$FGCT
        PGCT=$GCT
    else
        read PFGC PFGCT PGCT < "$datfile"
    fi
    echo "$FGC $FGCT $GCT" > $datfile

    DELTA_FGC=$(awk "BEGIN { if ($FGC > $PFGC) print $FGC - $PFGC; else print 0 }")
    DELTA_FGCT=$(awk "BEGIN { if ($FGCT > $PFGCT) print $FGCT - $PFGCT; else print 0 }")
    DELTA_GCT=$(awk "BEGIN { if ($GCT > $PGCT) print $GCT - $PGCT; else print 0 }")

    echo "{\"S0C\":$S0C,\"S1C\":$S1C,\"S0U\":$S0U,\"S1U\":$S1U,\"EC\":$EC,\"EU\":$EU,\"OC\":$OC,\"OU\":$OU,\"MC\":$MC,\"MU\":$MU,\"YGC\":$YGC,\"YGCT\":$YGCT,\"FGC\":$DELTA_FGC,\"FGCT\":$DELTA_FGCT,\"GCT\":$DELTA_GCT}"
else
    echo "{}"
fi
