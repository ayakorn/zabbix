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
#    /bin/ps -o nlwp $pid | tail -1 | /usr/bin/awk '{printf "%d", $1}'
    /bin/ps -o nlwp $pid | tail -1 
else
    echo 0
fi

