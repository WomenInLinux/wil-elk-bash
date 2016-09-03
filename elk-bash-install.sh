#!/bin/bash


#First thing we wanted download and install java from oracle
#Here is the link http://java.com/en/download/manual.jsp
#We need to take the latest and greatest as default

elasticrepo="/etc/yum.repos.d/elasticsearch.repo"
kiabnarepo="/etc/yum.repos.d/kiabna.repo"

#We downloaded the rpm

echo "Installing the java rpm"
rpm -Uvh /opt/jre-8u101-x64.rpm
##########################################

#Verifying our install of jre rpm

echo "Verfiying jre rpm install"

versionnew=`rpm -qa | grep jre1.8.0`

echo -n "$versionnew"

update-alternatives --config java <<< '3'

echo 3 | update-alternatives --config java 

itsjava=`java -version`

echo "$itsjava\n"

##########################################

#Setup elasticsearch repo

echo "Setting up repo"

#Here we are importing the key for elasticsearch
rpm --import http://packages.elastic.co/GPG-KEY-elasticsearch


#We naming the elasticsearch.repo which found in /etc/yum.repos.d/

echo '[elasticsearch-2.x]' >> $elasticrepo 
echo "name=Elasticsearch repository for 2.x packages" >> $elasticrepo 
echo "baseurl=http://packages.elastic.co/elasticsearch/2.x/centos" >> $elasticrepo 
echo "gpgcheck=1" >> $elasticrepo
echo "gpgkey=http://packages.elastic.co/GPG-KEY-elasticsearch" >> $elasticrepo 
echo "enabled=1" >> $elasticrepo

##########################################

#now the repo has been setup we will install elastic via yum


echo "we are installing elastic"

yum -y install elasticsearch

esearch=`rpm -qa | grep elastic`

echo -n "$esearch"

sed -i '/network.host/c\network.host: localhost' /etc/elasticsearch/elasticsearch.yml

#We will now enable and start this service

echo "We are enabled and starting elastic"
systemctl enable elasticsearch && systemctl start elasticsearch
