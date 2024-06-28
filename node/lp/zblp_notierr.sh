#!/bin/bash

catalinaout=/opt/lesspaper/tomcat/logs

while getopts "f:" opt; do
    case "$opt" in
    f)  if [ "$OPTARG" != "__NO__" ]
        then
            export catalinaout=$OPTARG
        fi
        ;;
    esac
done

#cat $catalinaout/notify.log | grep "^$(date +'%d %b %Y')" | grep ERROR | grep -iv gcm | wc -l
cat $catalinaout/notify.log | grep --text "^$(date +'%d %b %Y')" | grep ERROR | egrep -v 'Could not convert socket to TLS' | wc -l

