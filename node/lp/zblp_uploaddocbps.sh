#!/bin/bash

catalinaout=/opt/lesspaper/tomcat/logs

while getopts "f:" opt; do
    case "$opt" in
    f)  if [ "$OPTARG" != "__NO__" ]
        then
            export catalinaout=$OPTARG
        fi
        ;;
    esac
done

cat $catalinaout/upload.log | grep --text "^$(date +'%d %b %Y')" | grep "save doc-pdf ok" | /usr/bin/gawk '
BEGIN {
          totalTime=0
          totalSize=0
      }
      {
          for (i=1; i<NF; i++) {
	      if (index($i, "doc2PdfTime") > 0) {
                  split($i, item, "=")
                  totalTime += item[2];
              } else if (index($i, "docSize=") > 0) {
                  split($i, item, "=")
                  totalSize += item[2];
              }
          }
      }
END   {
          if (totalTime > 0) {
              printf("%d\n", totalSize*1000/totalTime);
          } else {
              printf("0\n");
          }
      }
'

