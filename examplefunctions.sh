#!/bin/bash

#lets make a function that takes parameters and then add the numbers together
#function adding() {
#	
#	echo "hello"	
#
#}
#
#adding



function adding()
{
for a in $*
do
	a=$(( a + 1 ))
	#echo $1 
	echo $a
done
}
adding 2  
