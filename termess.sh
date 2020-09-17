#! /bin/bash

# CONTINUE PROMPT
prompt() {
    echo -e "\n$1"
    read -p "Press [Y] to continue: " proceed
    if [ "$proceed" != "Y" ] ; then
        echo Aborting...
        exit 1
    fi
}


# UNZIP ARCHIVE AND PREPARE DIRECTORY STRUCTURE
unzip_and_prepare () {
    prompt "Facebook data will be unzipped in current directory. Do you wish to continue?"
    
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
    repair_script=$( realpath "$1" )
    while [ ! -f "$repair_script" ] ; do
        read -p $'\nRepair script not found. Please enter path to it (absolute or relative):\n> ' -e repair_script
        repair_script=$( realpath "$repair_script" 2>/dev/null )
    done

    find_msgs_path

    cd "$msg_dir"/inbox && {
        for file in $(echo {1..35}) ; do
            "$repair_script" $file
        done
    }

    cd "$msg_dir"/message_requests && {
        for file in $(echo {1..5}) ; do
            "$repair_script" $file
        done
    }
)


# PROCESS CHAT
format_chat() {
    # NAMES
    {
        index=0
        unset names

        # put participant's names in bash array - take first file to find them
        participants1=$( jq -r '.participants[].name' "$1"/message_1.json | sort )
        while read name ; do
            names[$index]="$name"
            index=$(( $index + 1 ))
        done <<<$( echo "$participants1" )

        # add former participants to the array
        participants2=$( cat "$1"/* | grep -Ei '(removed .* from the group)|(left the group)' | sed -E -e 's/.*removed (.*) from the group.*/\1/' -e 's/.*"(.*) left the group.*/\1/' | sort | uniq )
        while read name ; do
            if [[ $name = '' ]] ; then
                continue
            fi
            names[$index]="$name"
            index=$(( $index + 1 ))
        done <<<$( diff -u <( echo -e "$participants1" ) <( echo -e "$participants2" ) | grep -E '^\+' | sed -e 's/+//' -e 's/++.*//' | grep -v '^$' )

        # find longest name - used later in messages alignment
        max_name_len=0
        for name in "${names[@]}" ; do 
            name_len=${#name}
            if [ $name_len -gt $max_name_len ] ; then
                max_name_len=$name_len
            fi
        done
    }
    
    # FORMATTING
    {
        special_name='Patrik Drbal' # this name has different color
        LC_TIME=en_US.utf8 # for english date output

        # concatenate everything into one file - cat alone concats files in wrong order
        cat $( ls "$1"/* | sort -V ) |

        # newlines handling - not further processed yet
        sed -E 's:\\n: NEWLINEFLAG :g' |

        # display data in one row and reverse order
        jq -r '.messages[] | "\(.timestamp_ms) NAMEFLAG\(.sender_name)NAMEFLAG \(.content)"' | tac |
        
        # from timestamp to proper date
        awk '{
            $1 = strftime("%a %d %b %Y, %T", ( $1 + 500 ) / 1000 )
            print $0
        }' |
        
        # messages alignment
        awk -F'NAMEFLAG' "{
            name_length = length(\$2)
            \$2 = \"NAMEFLAG\"\$2\"NAMEFLAG\"

            for (i = 0; i < $max_name_len - name_length; i++)
                \$2 = \$2\" \"
            
            printf ( \"%s %s %s\n\", \$1, \$2, \$3 )
        }" |
        
        # colors
        awk -F'NAMEFLAG' "BEGIN { OFS=\"\" } {
            \$1 = \"\033[32m\"substr(\$1, 1, length(\$1)-1)\"\033[0m \"

            if (\$2 == \"$special_name\")
                \$2 = \"\033[31m\"\$2\"\033[0m\"
            else
                \$2 = \"\033[34m\"\$2\"\033[0m\"

            print \$0
        }"
    }
}


# PROCCESS ALL CHATS AND SAVE THEM TO FILES
proccess_all_chats() {
    output_dir=$( realpath "$1" )
    while [ ! -d "$output_dir" ] ; do
        read -p $'\nDirectory not found. Please enter path to it (absolute or relative):\n> ' -e output_dir
        output_dir=$( realpath "$output_dir" 2>/dev/null )
    done

    find_msgs_path

    number_of_chats=$(( $( ls -1q "$msg_dir"/inbox | wc -l ) + $( ls -1q "$msg_dir"/message_requests | wc -l ) ))
    counter=1

    for folder in "$msg_dir"/{inbox,message_requests}/* ; do
        [ -d "$folder" ] || continue

        echo "[$counter / $number_of_chats]:    $folder"
        counter=$(( $counter + 1 ))

        format_chat "$folder" > "$output_dir/$( echo $folder | sed -E 's_.*/([^_]+).*$_\1_' )"
    done

    echo -e '\033[33m\nDONE\033[0m'
}


# PROCESS FLAG OPTIONS
while getopts ":hp:r:a:f:" opt ; do
  case ${opt} in
    h)
        echo "-p <archive>                      Unzip archive with facebook data and prepare it for following use."
        echo
        echo "-r [<script>]                     Use packed or custom script to repair json bad encoding in inbox/ and message_requests/.
                                    * Prompt user to provide path to folder with chats.
                                    * If called without argument, use packed script located in the same directory main script is.
                                    * If called with argument, use passed script.
                                    * If script is not found, prompt user to provide it."
        echo
        echo "-a [<dest_directory>]             Process all chats in inbox/ and message_requests/.
                                    * Prompt user to provide path to folder with chats.
                                    * If called without argument, prompt user to confirm and use current directory.
                                    * If called with argument, use passed directory.
                                    * If directory is not found, prompt user to provide it."
        echo
        echo "-f <chat_folder>                  Process and display chat.
                                    * Output is not saved."
    ;;

    p) unzip_and_prepare "$OPTARG";;

    r) repair_json "$OPTARG";;

    a) proccess_all_chats "$OPTARG";;
    
    f) format_chat "$OPTARG";;

    \?)
        echo 'Error: Invalid option'
        echo 'Usage: termess [ -h ]  [ -p <archive> ]  [ -r [<script>] ]  [ -a [<dest_folder>] ]  [ -f <chat_folder> ]' >&2
        exit 1
    ;;

    :)
        # options with mandatory but missing arguments are processed here
        if [ "$OPTARG" = 'r' ] ; then
            scriptdir="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )" 
            repair_script="$scriptdir/fix_bad_unicode.rb"

            repair_json "$repair_script"
        elif [ "$OPTARG" = 'a' ] ; then
            prompt "Files will be generated in current directory. Do you wish to continue?"
            proccess_all_chats "$(pwd)"
        else
            echo "Error: Option '-$OPTARG' requires an argument" >&2
            exit 2
        fi
    ;;
  esac
done
