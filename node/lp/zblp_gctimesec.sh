#!/bin/bash

catalinaout=/opt/lesspaper/tomcat/logs

full=false
while getopts "f:F" opt; do
    case "$opt" in
    f)  if [ "$OPTARG" != "__NO__" ]
        then
            catalinaout=$OPTARG
        fi
        ;;
    F)  full=true
        ;;
    esac
done

if [ "$full" == "false" ]
then
    option=-v
fi

cd $catalinaout
export today=$(date +%Y-%m-%d)
cat $(ls -r gc*.txt | awk '
BEGIN {
          today=ENVIRON["today"]
          flag = "true"
      }
      {
          if (NR == 1) {
              print $0
          } else if (flag == "true") {
              print $0
          }
          if (index($0, today) == 0) {
              flag = "false"
          }
      }
') | /bin/grep "^$(date +'%Y-%m-%d')" | /bin/grep $option Full | /bin/grep -o 'real=.* secs' | /usr/bin/awk -F'[= ]' 'BEGIN { exectime = 0.0 } { exectime = exectime+$2 } END { printf "%.2f\n", exectime }' 

