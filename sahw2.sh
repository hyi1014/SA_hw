#!/bin/bash

buffer_file=()
buffer_hash=()

buffer_username=()
buffer_password=()
buffer_shell=()
buffer_group=()

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
    buffer_file+=(${@:$((pos_i+1)):${len_1}})
    buffer_hash+=(${@:$((pos_h+1)):${len_1}})
    if [ "${!pos_h}" = "--md5" ]
    then
        for ((i=0 ; i<${len_1} ; i++))
        do
            #echo ${buffer_hash[i]}
            #echo $(md5sum ${buffer_file[i]} | awk '{print $1}')
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
#parse csv file
function parse_csv()
{
    while IFS=',' read -r username password shell groups
    do
        #echo $username
        buffer_username+=($username)
        buffer_password+=($password)
        buffer_shell+=($shell)
        tmp=()
        IFS=' ' read -r -a tmp <<< "$group"
        buffer_group+=$(join ',' ${tmp[@]})
    # skip the first line     
    done <<< "$(tail -n +2 $1)"
}
#parse json file
function parse_json()
{
    len=`jq length $1`
    for ((i=0; i<$len; i++))
    do
        buffer_username+=($(jq -r ".[$i].username" $1))
        buffer_password+=($(jq -r ".[$i].password" $1))
        buffer_shell+=($(jq -r ".[$i].shell" $1))
        tmp=($(jq -r ".[$i].groups[]" $1))
        buffer_group+=$(join ',' ${tmp[@]})
    done
}
#parsing files
function parsing()
{
    #check files
    for ((i=0 ; i<${#buffer_file[@]} ; i++))
    do
        file ${buffer_file[i]} | grep -q "JSON" && parse_json ${buffer_file[i]} && continue
        file ${buffer_file[i]} | grep -q "CSV" && parse_csv ${buffer_file[i]} && continue
        #file ${buffer_file[i]} | grep -q "ASCII" && parse_json ${buffer_file[i]} && continue

        #not json or csv
        err_format
    done
}
#add user
function user_add()
{
    user_groups=IFS=',' read -r -a tmp <<< "$4"
    #add group
    for group in "${user_groups[@]}"
    do
        if [ cat /etc/group | grep -q $group ]
        then
            continue
        else
            sudo groupadd $group
        fi
    done
    
    #add user
    if [ $(cat /etc/passwd | grep -q $1) ]
    then
        echo "Warning: user $1 already exists."
    else
        sudo useradd -p $2 -s $3 $1
    fi
    #add user to group
    [[ "${4}" != "" ]] && sudo usermod -a -G $4 $1
}
#add users
function users_add()
{
    for ((i=0 ; i<${#buffer_username[@]} ; i++))
    do
        user_add ${buffer_username[i]} ${buffer_password[i]} ${buffer_shell[i]} ${buffer_group[i]}
    done
}
#main
if [ "$1" = "-h" ]
then
    usage
elif [ "$1" = "--md5" ] || [ "$1" = "--sha256" ] || [ "$1" = "-i" ]
then
    check_hash $@
    #echo "Checksums are valid."
    parsing
    #echo "Parsing files."
    while true
    do read -p "This script will create the following user(s): $(join ' ' ${buffer_username[@]}) Do you want to continue? [y/n]:"
        case $REPLY in
            #y|Y) users_add;exit 0;;
            y|Y) exit 0;;
            n|N) exit 0;;
            *) exit 0;;
        esac
    done
else
    err_args 
fi

