@echo off
set PATH=c:\cygwin64\bin;%PATH%
grep ERROR < "C:\Program Files\Apache Software Foundation\Tomcat 7.0\logs\conv.log" | wc -l