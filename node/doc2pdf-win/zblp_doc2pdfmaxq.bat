@echo off
set PATH=c:\cygwin64\bin;%PATH%
c:\cygwin64\bin\sort.exe -k3 -rn < "C:\Program Files\Apache Software Foundation\Tomcat 7.0\logs\zabbix.log" > c:\zblp2-1.dat
head -1 < c:\zblp2-1.dat > c:\zblp2-2.dat
cut -f3 -d' ' < c:\zblp2-2.dat
rm c:\zblp2-1.dat
rm c:\zblp2-2.dat