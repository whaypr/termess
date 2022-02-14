#! /bin/bash

# run the script from directory containing processed chats

## ARGS ##
# 1: month
# 2: year
##########
# example call: ./chats_monthly.sh Sep 2020

# Show all active chats in given month and display number of messages sent in that month.

for chat in * ; do
    echo $( grep "$1 $2" $chat | awk '{print $3,$4}' | wc -l ): $chat
done |
sort -n |
awk -F: '$1 != 0 {print $0}'
