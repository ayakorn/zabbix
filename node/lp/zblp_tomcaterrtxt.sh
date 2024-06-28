#!/bin/bash

progname=$(basename $0)
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

appid=$(echo $catalinaout | cut -d'/' -f4)
tmperrtxt=/var/tmp/zblp_tomcaterrtxt.$appid.$(date +"%d").log

if [ -s $tmperrtxt ]
then
    cat $tmperrtxt
else
    echo ZBX_NOTSUPPORTED
fi

