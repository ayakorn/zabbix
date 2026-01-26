#!/bin/bash

if [ "$JAVA_HOME" == "" ]
then
    export JAVA_HOME=/opt/lesspaper/jdk
    export PATH=$JAVA_HOME/jre/bin:$JAVA_HOME/bin:$PATH
fi

progname=$(basename $0)
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

modemax=0
if [ "$progname" == "zblp_tomcatmaxmem.sh" ]
then
    modemax=1
fi
export modemax

pid=$(ps -ef | grep java | grep "$serverText" | grep -v grep | awk '{print $2}')
if [ "$pid" != "" ]
then
    jstat -gc $pid | tail -n 1 | awk '
  BEGIN {
            param = ENVIRON["argget"]
            modemax = ENVIRON["modemax"]
        }
        {
            # --- Heap Calculation ---
            # Usage = S0U + S1U + EU + OU
            heap_u_kb = $3 + $4 + $6 + $8
            # Capacity = S0C + S1C + EC + OC
            heap_c_kb = $1 + $2 + $5 + $7
 
            heap_u_bytes = heap_u_kb * 1024;
            heap_p = (heap_u_kb / heap_c_kb) * 100

            # --- Metaspace Calculation ---
            meta_u_kb = $10
            meta_c_kb = $9
 
            meta_u_bytes = meta_u_kb * 1024
            meta_p = (meta_u_kb / meta_c_kb) * 100
        }
  END   {
            if (modemax == 1) {
                if (param == "heap") {
                    printf "%d", heap_c_kb * 1024
                } else if (param == "perm") {
                    printf "%d", meta_c_kb * 1024
                }
            } else {
                if (param == "heap") {
                    printf "%d", heap_p
                } else if (param == "perm") {
                    printf "%d", meta_p
                }
            }
        }'
else
    echo 0
fi

