#! /bin/bash

# Transforms facebook message JSONs into terminal-friendly files
# Output files can be easily read and searched through with standard terminal tools


# CONTINUE PROMPT
prompt() {
    echo -e "\n$1"
    read -p "Press [Y] to continue: " proceed
    if [ "$proceed" != "Y" ] ; then
        echo Aborting...
        exit 1
    fi
}

# UNZIP GIVEN ZIP AND CREATE DIRECTORY STRUCTURE
unzip_and_prepare () {
    prompt "Do you want to unzip facebook data in this directory?"
    
    unzip "$1"

    mkdir -p facebook/media  facebook/processed_chats

    mv messages/stickers_used facebook
    mv messages facebook

    (
        cd facebook/messages/inbox
        mv $( for folder in * ; do ls $folder | grep -qE 'photos|videos|gifs|audio|files' && echo $folder ; done ) ../../media/
    )
}

# FIND PATH TO DIRECTORY WITH JSONS
path_found=0
find_msgs_path() {
    if (( ! $path_found )) ; then
        read -p $'\nPlease enter a path to directory containing inbox/ and message_requests/:\n> ' -i "$HOME/Downloads/facebook/messages/" -e msg_dir
        path_found=1
    fi
}

# REPAIR JSON BAD ENCODING
repair_json() (
    script=$( realpath "$1" )

    cd "$msg_dir"/inbox
    for file in $(echo {1..35}) ; do
        "$script" $file
    done

    cd "$msg_dir"/message_requests
    for file in $(echo {1..5}) ; do
        "$script" $file
    done
)

# PROCESS CHAT
format_chat() {
    lc_time_tmp=$LC_TIME
    work_folder=$( mktemp -d )
    special_name='Patrik Drbal'
    index=0

    # put participant names in bash array - takes first file to find names
    participants1=$( jq -r '.participants[].name' "$1"/message_1.json | sort )
    while read name ; do
        names[$index]="$name"
        index=$(( $index + 1 ))
    done <<<$( echo "$participants1" )

    # put participant names in bash array - former participants
    participants2=$( cat "$1"/* | grep -Ei '(removed .* from the group)|(left the group)' | sed -E -e 's/.*removed (.*) from the group.*/\1/' -e 's/.*"(.*) left the group.*/\1/' | sort | uniq )
    while read name ; do
        if [[ $name = '' ]] ; then
            continue
        fi
        names[$index]="$name"
        index=$(( $index + 1 ))
    done <<<$( diff -u <( echo -e "$participants1" ) <( echo -e "$participants2" ) | grep -E '^\+' | sed -e 's/+//' -e 's/++.*//' | grep -v '^$' )

    # find longest name - used later in output formatting
    max_name_len=0
    for name in "${names[@]}" ; do 
        name_len=${#name}
        if [ $name_len -gt $max_name_len ] ; then
            max_name_len=$name_len
        fi
    done

    # concatenate everything into one file 
    cat $( ls "$1"/* | sort -V ) > "$work_folder/chat_tmp" # cat alone does not give correct order 

    LC_TIME=en_US.utf8 # for english date output

    sed -E 's:\\n: *NEW LINE* :g' "$work_folder/chat_tmp" | \
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
    > "$work_folder/chat"

    # names color
    for name in "${names[@]}" ; do 
        if [ "$name" = "$special_name" ] ; then
            sed -Ei "s/$name/$( echo -e '\033[31m&\033[0m' )/" "$work_folder/chat"
        else
            sed -Ei "s/$name/$( echo -e '\033[36m&\033[0m' )/" "$work_folder/chat"
        fi
    done

    # set *** string as separator
    for name in "${names[@]}" ; do 
        sed -Ei "s/$name/***&***/" "$work_folder/chat"
    done

    LC_TIME=cs_CZ.UTF-8 # for correct lenght of czech symbols

    # text alignment and final output
    awk -F'***' "{
        name_length = length(\$2)
        for (i = 0; i < $max_name_len - name_length; i++)
            \$2 = \$2\" \"

        printf ( \"%s %s %s\n\", \$1, \$2, \$3 )
    }" "$work_folder/chat"

    rm -rf "$work_folder"
    LC_TIME=$lc_time_tmp
}

# PROCCESS ALL CHATS AND SAVE THEM TO FILES
proccess_all_chats() {
    prompt "Do you want to generate message files in this directory?"

    number_of_chats=$(( $( ls -1q "$msg_dir"/inbox | wc -l ) + $( ls -1q "$msg_dir"/message_requests | wc -l ) ))
    counter=1

    for folder in "$msg_dir"/{inbox,message_requests}/* ; do
        echo "[$counter / $number_of_chats]:    $folder"
        counter=$(( $counter + 1 ))

        format_chat "$folder" > $( echo $folder | sed -E 's_.*/([^_]+).*$_\1_' )
    done

    echo -e '\033[33m\nDONE\033[0m'
}

# PROCESS FLAG OPTIONS
while getopts ":hu:r:af:" opt ; do
  case ${opt} in
    h )
        echo "-u <filename>                     Unzip archive with facebook messages.
                                  Prepare directory structure."
        echo
        echo "-r <filename>                     Use custom or packed script to repair json bad encoding.
                                  Path can be absolute or relative."
        echo
        echo "-a                                Process all chats and save them in current directory."
        echo
        echo "-f <chat_folder>                  Process and display chat.
                                  Output is not saved."
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
        echo "Invalid option '$OPTARG' requires a filename" >&2
        exit 2
    ;;
  esac
done
