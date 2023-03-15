#!/bin/bash

#help function
function usage() 
{
    echo -n -e "\nUsage: sahw2.sh {--sha256 hashes ... | --md5 hashes ...} -i files ...
    \n--sha256: SHA256 hashes to validate input files.\n--md5:MD5 hashes to validate input files.\n-i: Input files.\n"
    exit 0
}
#error args
function err_args() 
{
    echo -n -e "Error: Invalid arguments.\n" 1>&2
    usage
    exit 1
}
#error values
function err_vals() 
{
    echo -n -e "Error: Invalid values.\n" 1>&2
    exit 1
}
function err_csum()
{
    echo -n -e "Error: Invalid checksum.\n" 1>&2
    exit 1
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
        [[ "${!i}" = "--md5" || "${!i}" = "--sha256" ]] && pos_h=${i}
    done
    #check len_1 = len_2
    (( "${pos_i}" >= "${pos_h}" )) &&  len_1=$((${pos_i}-${pos_h}-1))
    (( "${pos_i}" < "${pos_h}" )) &&  len_1=$((${pos_h}-${pos_i}-1))
    len_2=$((${#@}-$len_1-2))
    # echo "pos_i: ${pos_i}"
    # echo "pos_h: ${pos_h}"
    # echo "len_1: ${len_1}"
    # echo "len_2: ${len_2}"
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
    exit 0
}

check_hash $@

# if [ "$1" = "-h" ]
# then
#     usage
# fi

