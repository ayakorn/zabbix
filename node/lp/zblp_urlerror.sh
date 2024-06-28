#!/bin/bash

(
checkra=$(curl https://lesspaper2.affix.co.th/admin/app/index 2>/dev/null | grep "form action" | grep "/admin/app" | wc -l)
if [ "$checkra" == "0" ]
then
    echo "RA URL IS ERROR"
else
    echo "RA URL IS OK"
fi

#apps="nia siam mcu catc nrru"
#apps="nia siam mcu nrru"
apps="nia siam mcu"
for app in $apps
do
    checkra=$(curl https://lesspaper2.affix.co.th/$app/app/index 2>/dev/null | grep "form action" | grep "/$app/app" | wc -l)
    if [ "$checkra" == "0" ]
    then
        echo "$app URL IS ERROR"
    else
        echo "$app URL IS OK"
    fi
done 
) | grep ERROR | wc -l
