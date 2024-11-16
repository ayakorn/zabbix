@echo off
set PATH=c:\cygwin64\bin;%PATH%
cat "C:\Program Files\Apache Software Foundation\Tomcat 7.0\logs\zabbix.log" | gawk 'BEGIN { total=0 } { total+=$2} END { print total/NR/1000 }'