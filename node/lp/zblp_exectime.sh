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

cat $catalinaout/exectime.log | grep "^$(date +'%d %b %Y')" | wc -l

