#! /bin/bash

# run the script from directory containing processed chats

## ARGS ##
# 1: chat_name
##########
# example call: ./chat_daily_words.sh dorotababuljakova

# Per day, count all words in the chat in that day.

 cat "$1" |
 awk '{ print $2,$3,$4,NF-7 }' | # print date and summed words from line
 awk '{ seen[$1$2$3] += $4 } END { for (i in seen) print i, seen[i] }' | # sum words for each day
 sed -E 's:^([0-9]{2})([a-zA-Z]{3}):\1 \2 :' | # create spaces in date
 sort -k3n -k2M -k1n # sort by date
