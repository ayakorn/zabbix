#!/bin/bash

cat /proc/meminfo | awk '
    {
        if ($1=="MemTotal:") memtotal = $2
        if ($1=="MemFree:") memfree = $2
        if ($1=="Cached:") memcache = $2
        if ($1=="Buffers:") membuff = $2
    }
END {
        memused = memtotal-memfree-memcache-membuff
        memusedp = memused*100/memtotal
        printf "%d", memusedp
    }
'
