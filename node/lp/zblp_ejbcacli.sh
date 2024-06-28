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

#cat $catalinaout/ejbcacli.log | grep "^$(date +'%d %b %Y')" | grep ERROR | grep -v "java.net.ConnectException: Connection timed out" | wc -l
#cat $catalinaout/ejbcacli.log | grep "^$(date +'%d %b %Y')" | grep ERROR | wc -l
cat $catalinaout/ejbcacli.log | grep "^$(date +'%d %b %Y')" | grep ERROR | grep -Ev 'test.affix.*Service\ Unavailable' | wc -l

