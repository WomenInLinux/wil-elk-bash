#!/bin/bash

#Read a pdf line by line

file="/opt/sfocto.txt"
#
#while IFS= read line
#do
#	echo "$line"
#
#done <"$file"



cat $file | while read line
do
	echo "$line"

done
