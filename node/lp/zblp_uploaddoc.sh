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

if [ "$progname" == "zblp_uploaddoc.sh" ]
then
    txt="save ms word"
else
    txt="save pdf"
fi

cat $catalinaout/upload.log | grep --text "^$(date +'%d %b %Y')" | grep "$txt" | wc -l

