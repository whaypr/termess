#! /bin/bash

## ARGS ##
# 1: chats directory
# 2: option (1 = messages | 2 = words)
##########
# example call: ./GRAPHS.sh "$HOME/Documents/facebook/PROCESSED/" 1

# Wrapper for python script for generating message graphs.

messages() {
    awk '{print $2, $3, $4}' |
    uniq -c | sed 's/,//' |
    awk '{printf "%s, %s %s %s\n", $1,$2,$3,$4 }'
}

words() {
    awk '{ print $2,$3,$4,NF-7 }' |
    awk '{ seen[$1$2$3] += $4 } END { for (i in seen) print i, seen[i] }' |
    sed -E 's:^([0-9]{2})([a-zA-Z]{3}):\1 \2 :' |
    sort -k3n -k2M -k1n | sed 's/,//' |
    awk '{ printf "%s, %s %s %s\n",$4,$1,$2,$3 }'
}

#----------------------------------------------------------
CHATS="$1"
OPTION="$2"

RAW="raw/raw-"
if [ $OPTION = 1 ]; then
    RAW="${RAW}messages"
elif [ $OPTION = 2 ]; then
    RAW="${RAW}word"
else
    echo "Invalid option!" >&2
    exit 1
fi

#----------------------------------------------------------
for file in "$CHATS"/* ; do
    filename=$( echo $file | sed -E 's:.*/([^/]*)$:\1:' )

    echo 'pocet,datum' > "$RAW/$filename"

    cat "$file" | {
        if [ $OPTION = 1 ]; then
            messages
        else
            words
        fi    
    } >> "$RAW/$filename"

    ./generate.py "$filename" "$RAW" "$OPTION"
done
