#!/bin/bash

#
#       wfuzz, SecLists and john -based dirbusting script
#
#           Useful to perform quick forceful browsing/dirbusting
#           during penetration testing assignment
#
# Wrapper around `wfuzz` tool intended to launch quickly
# forceful browsing sweep against a target web application
# using `SecLists` provided dictonary files.
# Also, the script is able to launch `john` the ripper
# tool to generate a custom wordlist to be used out from
# user supplied words.
#
# Mariusz B., 2016
# v0.1
#

# ==============================================
#   SCRIPT CONFIGURATION

# HTTP Status codes to hide from results.
DEFAULT_HIDE_CODES="401,404,410"

# Directory where SecLists repository has been placed.
SECLISTS_PATH=/root/data/SecLists

# These are rules to be used in John The Ripper fed with custom words
# passed as -c parameter, ONLY IN FULL_MODE
# In order to use KoreLogic JTR rules - do the following:
#       1. $ wget http://contest-2010.korelogic.com/rules.txt
#       2. $ cat rules.txt > /etc/john/john.conf
#JOHN_THE_RIPPER_RULES_TO_USE="--rules:KoreLogicRulesAppendNumbers_and_Specials_Simple"

# Default rules setting:
JOHN_THE_RIPPER_RULES_TO_USE="--rules"

# ==============================================

FULL_MODE=0
NUM_OF_SCAN=0
USER_HIDE_CODES=""
REQUEST_DELAY=0.02
OUTPUT_FILE=""
CUSTOM_WORDS_LIST=""

function usage {
    echo
    echo "Usage: ./dirbuster [options] -u <url>"
    echo
    echo "Where:"
    echo -e "\t-u <url>, --url <url>\t\t\tSpecifies URL to be scanned."
    echo
    echo "Options:"
    echo -e "\t-f, --full\t\t\t\tScan the website in full mode, generating lot of traffic."
    echo -e "\t-o <file>, --output <file>\t\tSpecifies whether to store output of that command."
    echo -e "\t-w <wordlist>, --wordlist <wordlist>\tSpecifies additional wordlist to use"
    echo -e "\t-W <wordlist>, --onlywordlist <wordlist>\tSpecifies the only wordlist to use"
    echo -e "\t-c <word>, --custom <word>\t\tSpecifies custom words (comma separated) to generate new dictonary file from."
    echo -e "\t-H <codes>, --hidecode <codes>\t\tHides user-specified HTTP status codes from output."
    echo -e "\t-d <delay>, --delay <delay>\t\tDelay between consecutive requests in seconds. (default: $REQUEST_DELAY seconds.)"
    echo -e "\t-A <wfuzz>, --additional <wfuzz>\t\tAdditional 'wfuzz' custom options to use."
    echo
}

function scan {
    NUM_OF_SCAN=$(($NUM_OF_SCAN+1))
    local hide_codes=$DEFAULT_HIDE_CODES

    if [[ ! -z "$USER_HIDE_CODES" ]]; then
        hide_codes="$USER_HIDE_CODES"
    fi

    local wordlists=""
    local additional="-m chain"
    local secondwordlist=""
    local num_of_requests=0

    for w in $2
    do
        wordlists="$wordlists -w $w"
        num_of_requests=$(( $num_of_requests + $(wc -l "$w" | awk '{print $1}') ))
    done

    additional="$ADDITIONAL_WFUZZ_OPTIONS"
    if [[ ! -z "$3" ]]; then
        secondwordlist="-w $3"
        num_of_requests=$(( $(wc -l "$2" | awk '{print $1}') * $(wc -l "$3" | awk '{print $1}') ))
    fi

    if [ $FULL_MODE -eq 1 ]; then
        additional="$additional -R 5 --script=default"
    fi

    local cmd="wfuzz -I -t 64 -s $REQUEST_DELAY -Z -c $additional --hc $hide_codes $wordlists $secondwordlist $1"

    echo
    echo "== Running forceful browsing scan"
    echo -e "- Hide HTTP codes:\t$hide_codes"
    echo -e "- Start time:\t\t$(date)"
    echo -e "- Number:\t\t$NUM_OF_SCAN"
    echo -e "- URL pattern:\t\t$1"
    echo -e "- List(s):\t\t$2 $3"
    echo -e "- Requests to make:\t$num_of_requests"
    echo -e "- Command line:\t\t$cmd"
    echo "=="
    echo

    if [ $num_of_requests -eq 0 ]; then
        echo "[!] There is no request to make with that scan. Skipping..."
        return
    fi

    $cmd
}

function prefilter_wordlists {
    f="/tmp/dirbust.wordlists.$RANDOM.$RANDOM.txt"
    cat ${*} | sort -u > $f
    echo $f
}

function directories_scan {
    local quick_scan_lists=(
        "$SECLISTS_PATH/Discovery/Web_Content/common.txt"
        "$SECLISTS_PATH/Discovery/Web_Content/SVNDigger/all-dirs.txt"
    )

    local full_scan_lists=(
        "$SECLISTS_PATH/Discovery/Web_Content/common.txt"
        "$SECLISTS_PATH/Discovery/Web_Content/SVNDigger/all-dirs.txt"
        "$SECLISTS_PATH/Discovery/Web_Content/raft-medium-directories.txt"
    )

    local wordlists=""

    if [ $FULL_MODE -eq 0 ]; then
        for list in "${quick_scan_lists[@]}"
        do
                wordlists="$wordlists $list"
        done
    else
        for list in "${full_scan_lists[@]}"
        do
                wordlists="$wordlists $list"
        done
    fi

    wordlists=$(prefilter_wordlists $wordlists)
    scan "$URL/FUZZ" "$wordlists"
    
    if [[ $wordlists == "/tmp/dirbust.wordlists."* ]]
    then
        echo "Removing temporary wordlist: $wordlists"
        rm $wordlists
    fi
}

function files_scan {
    local quick_scan_lists=(
        "$SECLISTS_PATH/Discovery/Web_Content/raft-small-files.txt"
    )

    local full_scan_lists=(
        "$SECLISTS_PATH/Discovery/Web_Content/raft-large-files.txt"
    )
    
    local short_extensions_list=/tmp/dirbust.extensions.small.$RANDOM.$RANDOM.txt
    cat<<EOF>$short_extensions_list

.asp
.aspx
.ashx
.asmx
.cgi
.htm
.html
.inc
.jsp
.jspx
.do
.action
.log
.tpl
.rb
.py
.php
.pl
.sh
.swf
.sql
.txt
.xml
.rar
.zip
.db
.sqlite
/
EOF

    if [[ ! -z "$1" ]]; then
        echo "Scanning with custom provided wordlist..."
        scan "$URL/FUZZ" "$1"
        scan "$URL/FUZZFUZ2Z" "$1" "$short_extensions_list"
        return
    fi

    if [ $FULL_MODE -eq 0 ]; then
        for list in "${quick_scan_lists[@]}"
        do
                local wordlists=$(prefilter_wordlists $list)
                scan "$URL/FUZZFUZ2Z" "$wordlists" "$short_extensions_list"
    
                if [[ $wordlists == "/tmp/dirbust.wordlists."* ]]
                then
                    rm $wordlists
                fi
        done

    else
        for list in "${full_scan_lists[@]}"
        do
                local wordlists=$(prefilter_wordlists $list)
                scan "$URL/FUZZFUZ2Z" "$wordlists" "$short_extensions_list"

                if [[ $wordlists == "/tmp/dirbust.wordlists."* ]]
                then
                    rm $wordlists
                fi
        done
    fi

    rm $short_extensions_list
}

function generate_custom_words {
    if [[ -z "$CUSTOM_WORDS" ]]; then
        return
    fi

    local words_file=/tmp/dirbust.words.$RANDOM.$RANDOM.txt
    local words_file2=/tmp/dirbust.words2.$RANDOM.$RANDOM.txt

    IFS=',' read -ra words <<< "$CUSTOM_WORDS"
    for i in "${words[@]}"; do
        echo $i >> $words_file
    done

    if [[ -n "$(which john)" ]]; then
        if [ $FULL_MODE -eq 0 ]; then
            john -w=$words_file --rules --stdout 2>/dev/null > $words_file2
        else
            john -w=$words_file $JOHN_THE_RIPPER_RULES_TO_USE --stdout 2>/dev/null > $words_file2
        fi
        cat $words_file2 | tr -d ',./<>?:;"[{]}\`~\|\!@#$%^&\*()+=|\\' | sort -u > $words_file
        echo "[?] Generated additional $(wc -l "$words_file" | awk '{print $1}') words"
        rm $words_file2
        CUSTOM_WORDS_LIST=$words_file

    else
        echo "[?] No john-the-ripper found in the system."
        echo "[?] Proceeding without further wordlists generation"
        rm $words_file2
        CUSTOM_WORDS_LIST=$words_file
    fi
}

# ====================================

echo
echo -e "\t.:: wfuzz and SecLists based dirbusting script ::."
echo -e "\t    To be used for quick dir busting pentest task"
echo -e "\t    Mariusz B. / 16', v0.1"
echo

while [[ $# -ge 1 ]]
do
    key="$1"

    case $key in
            -u|--url)
                URL="$2"
                shift
            ;;

            -W|--onlywordlist)
                WORDLIST="$2"
                shift
            ;;

            -W|--wordlist)
                ADDITIONAL_WORDLIST="$2"
                shift
            ;;

            -c|--custom)
                CUSTOM_WORDS="$2"
                shift
            ;;

            -d|--delay)
                REQUEST_DELAY="$2"
                shift
            ;;

            -o|--output)
                OUTPUT_FILE="$2"
                # Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
                exec > >(tee -i -a $OUTPUT_FILE)

                # Also redirect stderr
                exec 2>&1
                shift
            ;;

            -A|--additional)
                ADDITIONAL_WFUZZ_OPTIONS="$2"
                shift
            ;;

            -f|--full)
                FULL_MODE=1
                echo "[?] Scanning in FULL-MODE"
            ;;

            -h|--help)
                usage
                exit
            ;;

            -H|--hidecode)
                USER_HIDE_CODES="$2"
                shift
            ;;

            *)
                regex1='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
                regex2='www\.[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
                string="$1"
                if [[ $string =~ $regex1 ]] || [[ $string =~ $regex2 ]] ; then
                    URL="$1"
                    shift
                else
                    echo "[!] Unknown option has been specified."
                    usage
                    exit
                fi
            ;;
    esac
    shift
done

if [ ! -d "$SECLISTS_PATH" ]; then
    echo "[!] SecLists directory does not exists."
    echo "[?] You can get SecLists repository by doing:"
    echo "[?]     $ git clone https://github.com/danielmiessler/SecLists.git \$PWD/"
    echo "[?] and then modifying this script to set variable \$SECLISTS_PATH='\$PWD/'"
    exit
fi

if [[ -z "$URL" ]]; then
    echo "[!] You did not specify a URL to scan."
    usage
    exit
fi

out=$(curl -sD- $URL -o /dev/null)
if [ $? -ne 0 ]; then
    echo "[!] Could not fetch website from specified URL. Check your internet connection."
    echo -e "[!] curl's output:\n\t$out"
fi

if [[ ! -z "$WORDLIST" ]]; then
    echo "** Stage 0: Scan using custom wordlist"

    if [ ! -e $WORDLIST ]; then
        findres=$(find "$SECLISTS_PATH/Discovery/Web_Content/" -name $WORDLIST)
        if [[ -n "$findres" ]]; then
            echo "[?] Could not find specified wordlist, but found that one: $findres"
            WORDLIST="$findres"
        else
            echo "[!] Specified custom wordlist file does not exist."
            exit 1
        fi
    fi

    scan "$URL/FUZZ" $WORDLIST
    
else
    generate_custom_words

    if [[ ! -z "$CUSTOM_WORDS_LIST" ]]; then
        echo
        echo "** Stage 0: Custom wordlist scan."
        files_scan "$CUSTOM_WORDS_LIST"
    fi

    if [[ ! -z "$ADDITIONAL_WORDLIST" ]] ; then
        echo
        echo "** Stage 0: Custom wordlist scan."
        files_scan "$ADDITIONAL_WORDLIST"
    fi

    echo
    echo "** Stage 1: Directories scan"
    directories_scan

    echo
    echo
    echo "** Stage 2: Files scan"
    files_scan

    if [[ -n "$CUSTOM_WORDS_LIST" ]]; then
        rm $CUSTOM_WORDS_LIST
    fi
fi

echo "Script has finished scanning."

