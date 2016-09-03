#!/bin/bash

echo "$0"
echo "Total number of arguments: $#"
echo "Argument 1: $1"
if [ $1 = "hello" ]; then
	echo "yes"
else
	echo "they did not match"
fi

echo "Argument 2: $2"
if [ -d "/opt" ]; then
	echo `pwd`
fi
#
#
#echo "Argument 3: $3"
#echo "Argument 4: $4"
#echo "Argument 5: $5"
