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

INPUT=data2.csv
OLDIFS=$IFS
buffer_group=()
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
while IFS=',' read -r username password shell group
do
    echo "Username : $username"
    echo "Password : $password"
    echo "Shell : $shell"
    echo "Group : $group"
    tmp=()
    IFS=' ' read -r -a tmp <<< "$group"
    buffer_group+=$(join ',' ${tmp[@]})
# skip the first line     
done <<< "$(tail -n +2 $INPUT)"
IFS=$OLDIFS

for i in "${buffer_group[@]}"
do
    echo $i
done