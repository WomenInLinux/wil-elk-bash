#!/bin/bash


#we are playing with arrays and for loops

firstarray=(six seven nine)

# Print everything
echo ${firstarray[*]}

#Brackets gone
echo "------"
echo $firstarray[*]


#Print second position of array
echo "------"
echo ${firstarray[1]}
