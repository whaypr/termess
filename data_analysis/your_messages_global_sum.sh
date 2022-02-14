#! /bin/bash

# run the script from directory containing processed chats

## ARGS ##
# 1: "Your Messenger Name"
##########
# example call: ./your_messages_global_sum.sh "Patrik Drbal"

# Print total number of your messages accross all your chats.

for chat in *;
    do grep -cv "$1" $chat
done | awk '{sum += $1} END {print sum}'
