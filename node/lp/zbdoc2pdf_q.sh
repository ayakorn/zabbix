#!/bin/bash

catalinaout=/opt/lesspaper/tomkat/logs
logfile=zabbix.log

while getopts "f:" opt; do
    case "$opt" in
    f)  if [ "$OPTARG" != "__NO__" ]
        then
            export catalinaout=$OPTARG
        fi
        ;;
    esac
done

tmpdat=/var/tmp/zblp_doc2pdf_queue.$(date +"%d").dat

if [ -f $tmpdat ]
then
    if [ $(stat -c%s $tmpdat) == $(stat -c%s $catalinaout/$logfile) ]
    then
        echo 0
    else
        comm -13 $tmpdat $catalinaout/$logfile | head -1 | cut -f3 -d' '
    fi
else
    echo 0
fi

cp $catalinaout/$logfile $tmpdat
