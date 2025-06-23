#!/usr/bin/bash

out=$(./check_send_receive_time.py --site=https://test1.chat.affix.co.th | grep -o "check_send_receive_state [a-z]* " | cut -f2 -d' ')
if [ "$out" == "ok" ]
then
    echo 0
else
    echo 1
fi
