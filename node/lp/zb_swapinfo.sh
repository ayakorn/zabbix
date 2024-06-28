#!/bin/bash

cat /proc/swaps | tail -1 | awk '{ print $4/$3*100 }'
