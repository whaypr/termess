#! /bin/bash

# Pasrse Facebook messages in json and store them into terminal-friendly files
# Allows easy reading and searching from terminal and using terminal tools

# CONTINUE PROMPT
prompt () {
    echo
    echo "$1"
    read -p "Press [Y] to continue: " PROCEED
    if [ "$PROCEED" != "Y" ] ; then
        echo Aborting...
        exit 1
    fi
}

# FIND PATH TO DIRECTORY WITH MESSAGES IN JSON
PATH_FOUND=0
find_msgs_path () {
    if [ $PATH_FOUND -eq 0 ] ; then
        echo
        read -p $'Please enter a path to directory containing inbox/ and message_requests/:\n> ' -i "$HOME/Downloads/facebook/messages/" -e MSG_DIR
        PATH_FOUND=1
    fi
}

# UNZIP GIVEN ZIP AND CREATE DIRECTORY STRUCTURE
unzip_and_prepare () {
    prompt "Do you want to unzip messages in this directory?"
    
    unzip "$1"

    mkdir -p facebook/media
    mkdir -p facebook/_CUSTOM/processed\ chats
    mkdir -p facebook/_CUSTOM/interesting\ data

    mv messages facebook
    mv facebook/messages/stickers_used facebook/

    cd facebook/messages/inbox
    mv $( for folder in * ; do ls $folder | grep -qE 'photos|videos|gifs|audio|files' && echo $folder ; done ) ../../media/
    cd -
}

# REPAIR JSON BAD ENCODING
repair_json () {
    range=$(echo {1..32}) # max num of message files
    CURRENT_DIR="$(pwd)"

    # inbox
    cd "$MSG_DIR"/inbox

    for file in $range ; do
        "$1" $file
    done

    # message_reguests
    cd "$MSG_DIR"/message_requests

    for file in $range ; do
        "$1" $file
    done

    cd "$CURRENT_DIR"
}

# PROCCESS CHAT
format_chat () {
    # put participant names in bash array - takes first file to find names
    jq -r '.participants[].name' "$1"/message_1.json | sort > fbjson_participants1
    index=0
    while read name ; do
        names[$index]="$name"
        index=$(( $index + 1 ))
    done <<<"$( cat fbjson_participants1 )"

    # put participant names in bash array - former participants
    cat "$1"/* | grep -Ei '(removed .* from the group)|(left the group)' | sed -E -e 's/.*removed (.*) from the group.*/\1/' -e 's/.*"(.*) left the group.*/\1/' | sort | uniq > fbjson_participants2
    while read name ; do
        if [[ $name = '' ]] ; then
            continue
        fi
        names[$index]="$name"
        index=$(( $index + 1 ))
    done <<<"$( diff -u fbjson_participants1 fbjson_participants2 | grep -E '^\+' | sed -e 's/+//' -e 's/++.*//' | grep -v '^$' )"

    # find longest name - used later in output formatting
    MAX_NAME_LEN=0
    for name in "${names[@]}" ; do 
        NAME_LEN=${#name}
        if [ $NAME_LEN -gt $MAX_NAME_LEN ] ; then
            MAX_NAME_LEN=$NAME_LEN
        fi
    done

    # concatenate everything into one file 
    cat $( ls "$1"/* | sort -V ) > fbjson # cat alone does not give correct order 

    LC_TIME=en_US.utf8 # for english date output

    sed -E 's:\\n: *NEW LINE* :g' fbjson | \
    # display data in one row
    jq -r '.messages[] | "\(.timestamp_ms) \(.sender_name) \(.content)"' | \
    # reverse message order
    tac | \
    # from timestamp milliseconds to proper date
    awk '{
        $1 = strftime("%a %d %b %Y, %T", ( $1 + 500 ) / 1000 )
        print $0
    }' | \
    # date and time color
    sed -E \
    "s/[[:alpha:]]{3} [[:digit:]]{2} [[:alpha:]]{3} [[:digit:]]{4}, [[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}/$( echo -e '\033[32m&\033[0m' )/" \
    > fbjson2

    # set *** string as separator
    for name in "${names[@]}" ; do 
        sed -Ei "s/$name/***&***/" fbjson2
    done

    LC_TIME=cs_CZ.UTF-8 # for correct lenght of czech symbols

    # text alignment
    awk -F'***' "{
        name_length = length(\$2)
        for (i = 0; i < $MAX_NAME_LEN - name_length; i++)
            \$2 = \$2\" \"

        printf ( \"%s %s %s\n\", \$1, \$2, \$3 )
    }" fbjson2 > fbjson

    # names color
    for name in "${names[@]}" ; do 
        if [ "$name" = "Patrik Drbal" ] ; then
            sed -Ei "s/$name/$( echo -e '\033[31m&\033[0m' )/" fbjson
        else
            sed -Ei "s/$name/$( echo -e '\033[36m&\033[0m' )/" fbjson
        fi
    done

    cat fbjson

    rm fbjson*
}

# PROCCESS ALL CHATS AND SAVE THEM TO FILES
proccess_all_chats () {
    prompt "Do you want to generate message files in this directory?"

    find_msgs_path

    NUMBER_OF_CHATS=$(( $( ls -1q "$MSG_DIR"/inbox | wc -l ) + $( ls -1q "$MSG_DIR"/message_requests | wc -l ) ))
    COUNTER=1

    for folder in "$MSG_DIR"/{inbox,message_requests}/* ; do
        echo "[$COUNTER / $NUMBER_OF_CHATS]:    $folder"
        COUNTER=$(( $COUNTER + 1 ))

        format_chat "$folder" > $( echo $folder | sed -E 's/.*\/([^_]+).*$/\1/' ) # old: awk -F'/' '{ print $NF }'
    done

    echo -e '\033[33m\nDONE\033[0m'
}



# PROCCESS FLAG OPTIONS
while getopts ":hu:r:af:" opt ; do
  case ${opt} in
    h )
        echo "-u <filename>                     Unzips given zip with facebook messages.
                                  Prepares directory structure."
        echo
        echo "-r <filename>                     Uses custom or packed script to repair json bad encoding.
                                  Script is called inside given inbox folder and modifies it.
                                  You must enter absolute path to the script "
        echo
        echo "-a                                Proccess all chats and saves them in current directory."
        echo
        echo "-f <chat_folder>                  Proccesses and displays given chat.
                                  Does not save it."
    ;;

    u )
        unzip_and_prepare "$OPTARG"
    ;;

    r )
        find_msgs_path

        repair_json "$OPTARG"        
    ;;

    a )
        find_msgs_path

        proccess_all_chats
    ;;

    f )
        format_chat "$OPTARG"
        exit 0
    ;;

    \? )
        echo 'Usage: facebook_json [-h] [-u <filename>] [-r <filename>] [-f <filename>]' >&2
        exit 1
    ;;

    : )
        echo "Invalid option: $OPTARG requires a filename" >&2
        exit 2
    ;;
  esac
done
