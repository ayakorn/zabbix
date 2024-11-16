@echo off
set PATH=c:\cygwin64\bin;%PATH%
c:\cygwin64\bin\sort.exe -k2 -rn < "C:\Program Files\Apache Software Foundation\Tomcat 7.0\logs\zabbix.log" > c:\zblp1-1.dat
head -10 < c:\zblp1-1.dat > c:\zblp1-2.dat
gawk 'BEGIN { total=0 } { total+=$2} END { print total/NR/1000 }' < c:\zblp1-2.dat
rm c:\zblp1-1.dat
rm c:\zblp1-2.dat