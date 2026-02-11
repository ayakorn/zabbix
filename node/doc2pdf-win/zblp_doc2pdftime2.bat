@echo off
set PATH=c:\cygwin64\bin;%PATH%
comm -13 "C:\Program Files\Apache Software Foundation\Tomcat 8.5\logs\zabbix.last" "C:\Program Files\Apache Software Foundation\Tomcat 8.5\logs\zabbix.log" > "C:\Program Files\Apache Software Foundation\Tomcat 8.5\logs\zabbix.tmp"
cat "C:\Program Files\Apache Software Foundation\Tomcat 8.5\logs\zabbix.tmp" | gawk 'BEGIN { total=0 } { total+=$2} END { print total/NR/1000 }'
cp -p "C:\Program Files\Apache Software Foundation\Tomcat 8.5\logs\zabbix.log" "C:\Program Files\Apache Software Foundation\Tomcat 8.5\logs\zabbix.last"
