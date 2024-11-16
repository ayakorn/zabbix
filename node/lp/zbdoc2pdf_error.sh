#!/bin/bash

catalinaout=/opt/lesspaper/tomkat/logs
logfile=conv.log

while getopts "f:" opt; do
    case "$opt" in
    f)  if [ "$OPTARG" != "__NO__" ]
        then
            export catalinaout=$OPTARG
        fi
        ;;
    esac
done

cat $catalinaout/$logfile | grep ERROR | wc -l 
