#!/bin/bash

catalinapath=/opt/lesspaper/tomcat/mqueue

while getopts "f:" opt; do
    case "$opt" in
    f)  if [ "$OPTARG" != "__NO__" ]
        then
            export catalinapath=$OPTARG
        fi
        ;;
    esac
done

echo $(ls $catalinapath/*.zip 2>/dev/null | wc -l)

