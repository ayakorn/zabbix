@echo off
set PATH=c:\cygwin64\bin;%PATH%

comm -13 c:\zabbix1.log "C:\Program Files\Apache Software Foundation\Tomcat 7.0\logs\zabbix.log" > zbq1.log
c:\cygwin64\bin\sort.exe -rn -k3 < zbq1.log > zbq2.log
head -1 < zbq2.log > zbq3.log
cut -f3 -d' ' < zbq3.log 
cp "C:\Program Files\Apache Software Foundation\Tomcat 7.0\logs\zabbix.log" c:\zabbix1.log
rm zbq*.log
