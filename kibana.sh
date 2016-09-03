#!/bin/bash

filek="/etc/nginx/conf.d/kibana.conf"

echo 'server { '  > $filek
echo -e  ' \t listen 80;'  >> $filek
echo -e  ' \t \t listen 90;'  >> $filek
echo -e  ' \t \t listen 100;'  >> $filek
