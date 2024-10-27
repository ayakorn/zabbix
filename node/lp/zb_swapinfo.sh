#!/bin/bash

cat /proc/swaps | tail -n +2 | awk '{ u+=$4; t+=$3 } END { print u/t*100 }'
