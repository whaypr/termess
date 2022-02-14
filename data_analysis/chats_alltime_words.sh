#! /bin/bash

# run the script from directory containing processed chats

# Display number of words of all time per each chat.

for chat in * ; do
    /home/b4lldr/Dropbox/coding/bash/termess/example\ scripts/chat_daily_words.sh "$chat" |
    #grep "$1 $2" |
    awk '{sum += $4} END {print sum}' |
    sed -E "s/(.*)/\1 $chat/"
done |
sort -n