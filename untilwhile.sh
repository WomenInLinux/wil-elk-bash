#!/bin/bash

counter=1

until [ $counter -gt 10 ]
do

	echo $counter
	((counter ++))
	echo "this is the new counter ${counter}"
done
