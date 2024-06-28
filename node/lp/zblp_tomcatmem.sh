#!/bin/bash

if [ "$JAVA_HOME" == "" ]
then
    export JAVA_HOME=/opt/lesspaper/jdk
    export PATH=$JAVA_HOME/jre/bin:$JAVA_HOME/bin:$PATH
fi

serverText=lesspaper/tomcat

while getopts "j:g:t:" opt; do
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
    g)  export argget=$OPTARG
        ;;
esac
done

if [ "$argget" == "" ]
then
    echo ZBX_NOTSUPPORTED
    exit 1
fi

pid=$(ps -ef | grep java | grep "$serverText" | grep -v grep | awk '{print $2}')
if [ "$pid" != "" ]
then
    (jstat -gc $pid; jstat -gccapacity $pid) | awk '
  BEGIN {
            param = ENVIRON["argget"]
        }
        {
            if (NR == 1 || NR == 3) {
                for (i = 1; i <= NF; i++) {
                    var[$i] = 0
                    name[i] = $i
                }
            } else if (NR == 2 || NR == 4) {
                for (i = 1; i <= NF; i++) {
                    var[name[i]] = $i
                }
            }
        }
END     {
            if ("MU" in var) {
                perm_used = var["MU"]
            } else {
                perm_used = var["PU"]
            }
            if ("MC" in var) {
                perm_max = var["MC"]
            } else {
                perm_max = var["PGCMX"]
            }

            heap_used = var["EU"] + var["OU"]
            heap_max = var["NGCMX"] + var["OGCMX"]

            if (param == "heap") {
                printf "%d", heap_used*100/heap_max
            } else if (param == "perm") {
                printf "%d", perm_used*100/perm_max
            }
        }'
else
    echo 0
fi

