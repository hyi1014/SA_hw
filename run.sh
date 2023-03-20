#!/bin/bash
#./sahw2.sh --md5 6e080bc4430d7078e7531ed66ab1d024 6e080bc4430d7078e7531ed66ab1d024 -i data2.csv data2.csv 
#./sahw2.sh --md5 6e080bc4430d7078e7531ed66ab1d024 365d087f5499e2e7aff992832d2f0500 -i data2.csv data1.json 


./sahw2.sh --md5  "$(md5sum ${1} | awk '{print $1}')" "$(md5sum ${2} | awk '{print $1}')" -i $1 $2








#sudo userdel admin_cat && sudo userdel meow_2 && sudo userdel meow_3
