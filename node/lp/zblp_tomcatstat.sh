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

pid=$(ps -ef | grep java | grep "$serverText" | grep -v grep | awk '{print $2}')
if [ "$pid" != "" ]
then
    line=$(jstat -gc $pid | tail -n 1)
    read S0C S1C S0U S1U EC EU OC OU MC MU CCSC CCSU YGC YGCT FGC FGCT GCT <<< $line
    echo "{\"S0C\":$S0C,\"S1C\":$S1C,\"S0U\":$S0U,\"S1U\":$S1U,\"EC\":$EC,\"EU\":$EU,\"OC\":$OC,\"OU\":$OU,\"MC\":$MC,\"MU\":$MU,\"YGC\":$YGC,\"YGCT\":$YGCT,\"FGC\":$FGC,\"FGCT\":$FGCT,\"GCT\":$GCT}"
else
    echo "{}"
fi
