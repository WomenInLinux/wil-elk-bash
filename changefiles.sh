#!/bin/bash

for value in $1/*.log
do
	echo $value
	mv ${value} ${value}.newlog
done
