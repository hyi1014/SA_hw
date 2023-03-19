#!/bin/bash
function join()
{
  local d=$1 f=$2
  if shift 2
  then
  joined_res=$(printf %s "$f" "${@/#/$d}")
  fi
  echo $joined_res
}

function user_add()
{
    # #add user
    !(cat /etc/passwd | grep -q $1) && sudo useradd -p $2 -s $3 $1
    #add user to group
    [[ "${4}" != "" ]] && sudo usermod -a -G $4 $1
}

len=`jq length data1.json`
for ((i=0; i<$len; i++))
do
    #add group

    groups=($(jq -r ".[$i].groups[]" data1.json))
    for group in "${groups[@]}"
    do
        !(cat /etc/group | grep -q $group) && sudo groupadd $group
    done

    #add user

    username=$(jq -r ".[$i].username" data1.json)
    password=$(jq -r ".[$i].password" data1.json)
    shell=$(jq -r ".[$i].shell" data1.json)
    groups_joined=`join ',' ${groups[@]}`
    user_add $username $password $shell $groups_joined
done