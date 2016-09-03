#!/bin/bash

IFS=$'\n'

#we want to print the files and directories in etc

cd /var

for i in $#;
do
	echo  item: $i   
	echo $0
	echo $1
#	echo $2
#	echo $3
#	echo $4
#	echo $5
#	echo $6
#	echo $7
#	echo $8
#	echo $9
#	echo $10


done


