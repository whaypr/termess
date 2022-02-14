#! /bin/bash

# run the script from directory containing processed chats

# Display number of messages of all time per each chat.

for file in * ; do
    wc -l "$file" 
done | sort -n
