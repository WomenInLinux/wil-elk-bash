#!/bin/bash
# $# gives you the total of the arguments 
# you have to echo out each position 
# echo $1 echo $2

# $* gives the exact inputs
# $@ gives the in puts with newline character

# This happens because "$*" combines all arguments into a single string
# "$@" requotes the individual arguments.

for args in "$@"
do
	#echo $args
	echo ${args[0]}
done
