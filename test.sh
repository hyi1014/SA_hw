#!/bin/bash
buffer_file=${@:2:2}
test=${buffer_file[@]}
array+=($test)
echo ${array[0]}