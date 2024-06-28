#!/bin/bash

value1=1
value2=1
if [ -f /tmp/instcert.log ]
then
    insterr=$(cat /tmp/instcert.log | grep -i error | wc -l)
    if [ "$insterr" -gt 0 ]
    then
        value1=0
    fi
fi

zimbrarun=$(/etc/init.d/zimbra status | grep " Running" | wc -l)
if [ "$zimbrarun" -ne 9 ]
then
    value2=0
fi

#echo "http://www.microx.co.th/zabbixSend2?p1=zimbra%20zimbra.instcet%20$value1&p2=zimbra%20zimbra.running%20$value2"
#curl -F"data=@/tmp/zbdata.txt" http://www.microx.co.th/zabbixSend > /tmp/zbdata.out 2>&1
wget -q "http://www.microx.co.th/zabbixSend2?p1=zimbra%20zimbra.instcet%20$value1&p2=zimbra%20zimbra.running%20$value2" -O - > /tmp/zb_zimbra.log
