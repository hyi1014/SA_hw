#!/bin/bash

buffer_file=()
buffer_hash=()

buffer_username=()
buffer_password=()
buffer_shell=()
buffer_group=()

#-1: no file type
#1: JSON
#2: CSV
file_type=-1

#help function
function usage() 
{ 
    echo -n -e "\nUsage: sahw2.sh {--sha256 hashes ... | --md5 hashes ...} -i files ...\n\n--sha256: SHA256 hashes to validate input files.\n--md5: MD5 hashes to validate input files.\n-i: Input files.\n"
}
#error
function err_args() 
{
    echo -n -e "Error: Invalid arguments." 1>&2
    usage
    exit 1
}
function err_vals() 
{
    echo -n -e "Error: Invalid values." 1>&2
    exit 1
}
function err_csum()
{
    echo -n -e "Error: Invalid checksum." 1>&2
    exit 1
}
function err_type()
{
    echo -n -e "Error: Only one type of hash function is allowed." 1>&2
    exit 1
}
function err_format()
{
    echo -n -e "Error: Invalid file format." 1>&2
    exit 1
}

#join array

function join()
{
  local d=$1 f=$2
  if shift 2
  then
  joined_res=$(printf %s "$f" "${@/#/$d}")
  fi
  echo $joined_res
}

#add user

function user_add()
{
    # #add user
    !(cat /etc/passwd | grep -q $1) && sudo useradd -p $2 -s $3 $1
    #add user to group
    [[ "${4}" != "" ]] && sudo usermod -a -G $4 $1
}

#parse csv file
function parse_csv()
{
    OLDIFS=$IFS
    IFS=','
    while read -r username password shell group
    do
        buffer_username+=($username)
        buffer_password+=($password)
        buffer_shell+=($shell)
        buffer_group+=($group)
    done <<< "$(tail -n +2 $file)"
    IFS=$OLDIFS
}

#parse json file

function parse_json()
{
    len=`jq length $1`
    
}

#check hash value 

function check_hash()
{
    pos_i=0
    pos_h=0
   #get the position of -i and -hash
    for ((i=1 ; i<$# ; i++))
    do
        [[ "${!i}" = "-i" ]] && pos_i=${i}
        if [[ "${!i}" = "--md5" || "${!i}" = "--sha256" ]]
        then
            [ $pos_h != 0 ] && err_type
            pos_h=${i}
        fi
    done
    #check len_1 = len_2
    (( "${pos_i}" >= "${pos_h}" )) &&  len_1=$((${pos_i}-${pos_h}-1))
    (( "${pos_i}" < "${pos_h}" )) &&  len_1=$((${pos_h}-${pos_i}-1))
    len_2=$((${#@}-$len_1-2))

    if [ $len_1 != $len_2 ]
    then
        err_vals
    fi

    #check hash value
    buffer_file=${@:$((pos_i+1)):${len_1}}
    buffer_hash=${@:$((pos_h+1)):${len_1}}
    if [ "${!pos_h}" = "--md5" ]
    then
        for ((i=0 ; i<${len_1} ; i++))
        do
            if [ "${buffer_hash[i]}" != "$(md5sum ${buffer_file[i]} | awk '{print $1}')" ]
            then
                err_csum
            fi
        done
    elif [ "${!pos_h}" = "--sha256" ]
    then
        for ((i=0 ; i<${len_1} ; i++))
        do
            if [ "${buffer_hash[i]}" != "$(sha256sum ${buffer_file[i]} | awk '{print $1}')" ]
            then
                err_csum
            fi
        done
    else
        err_vals
    fi
}

#parsing file
function parsing()
{
    #check file
    for ((i=0 ; i<${#buffer_file[@]} ; i++))
    do
        file ${buffer_file[i]} | grep -q "JSON" && file_type=1 && return 0
        file ${buffer_file[i]} | grep -q "CSV" && file_type=2 && return 0
        #not json or csv
        file_type=-1 && err_format
    done    
}
#main
if [ "$1" = "-h" ]
then
    usage
elif [ "$1" = "--md5" ] || [ "$1" = "--sha256" ] || [ "$1" = "-i" ]
then
    check_hash $@
    parsing
    while true
    do read -p "This script will create the following user(s): ${buffer_user[@]} Do you want to continue? [y/n]:"
        case $REPLY in
            y|Y) echo yes; exit 0;;
            n|N) echo no; exit 0;;
            *) err_format;;
        esac
    done
else
    err_args 
fi

