#!/bin/bash
INPUT=data2.csv
OLDIFS=$IFS
IFS=','
buffer_group=()
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
while read -r username password shell group
do
    echo "Username : $username"
    echo "Password : $password"
    echo "Shell : $shell"
    echo "Group : $group"
    buffer_group+=($group)
# skip the first line     
done <<< "$(tail -n +2 $INPUT)"
IFS=$OLDIFS

for i in "${buffer_group[@]}"
do
    echo $i
done