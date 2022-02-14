#! /bin/bash

# run the script from directory containing processed chats

## ARGS ##
# 1: start_year
# 2: end_year
##########
# example call: ./chats_monthly_range.sh 2015 2020

# Per each month in range, display chat with the most messages that month.

for year in $( eval echo {"$1".."$2"} ) ; do
    for month in Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ; do
        echo -n "$month $year:      "
        ~/Dropbox/coding/bash/termess/example\ scripts/chats_monthly.sh "$month" "$year" | tail -1
    done
done
