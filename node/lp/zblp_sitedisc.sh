#!/bin/bash

catalinahome=/opt/lesspaper/tomcat

while getopts "f:" opt; do
    case "$opt" in
    f)  if [ "$OPTARG" != "__NO__" ]
        then
            export catalinahome=$OPTARG
        fi
        ;;
    esac
done

if [ ! -f $catalinahome/zblp_site.dat ]
then
    exit 0
fi

echo '{ "data":['
first=1
for config in $(cat $catalinahome/zblp_site.dat | grep -v '^#')
do
    site=$(echo $config | cut -f1 -d,)
    url=$(echo $config | cut -f2 -d,)
    if [ "$first" == "0" ]
    then
        echo ","
    fi
    echo "{ \"{#SITENAME}\":\"$site\", \"{#SITEURL}\":\"$url/$site\" }"
    first=0
done
echo '] }'

