#!/bin/bash

counter=1

while [ $counter -le 10 ]
do

	echo $counter
	((counter ++))
	echo "this is the new counter ${counter}"
done
