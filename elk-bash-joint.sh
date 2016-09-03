#!/bin/bash


#First thing we wanted download and install java from oracle
#Here is the link http://java.com/en/download/manual.jsp
#We need to take the latest and greatest as default
#We will remove things first

yum remove kibana elasticsearch jre1.8.* -y



elasticrepo="/etc/yum.repos.d/elasticsearch.repo"
kibanarepo="/etc/yum.repos.d/kibana.repo"

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

#Created by Ayotunde
#Create and edit a new yum repository file for Kibana.
#Also add the repository configuration to the file.

#Import the Elasticsearch public GPG key into RPM.

echo "Importing the key for elasticsearch"

rpm --import http://packages.elastic.co/GPG-KEY-elasticsearch


############
echo '[kibana-4.6]' >> $kibanarepo
echo "name=Kibana repository for 4.6.x packages" >> $kibanarepo
echo "baseurl=http://packages.elastic.co/kibana/4.6/centos" >> $kibanarepo
echo "gpgcheck=1" >> $kibanarepo
echo "gpgkey=http://packages.elastic.co/GPG-KEY-elasticsearch" >> $kibanarepo
echo "enabled=1" >> $kibanarepo 

#############
 
#Install Kibana

echo "Installing Kibana"

yum -y install kibana



#############

#Open Kibana configuration file for editing
#vi /opt/kibana/config/kibana.yml
#Replace the IP address on the server.host line in the Kibana config file

sed -i '/server.host/c\server.host: localhost' /opt/kibana/config/kibana.yml

#############
sleep 10 

#Start the Kibana service

echo "Starting and enabling Kibana Service"

systemctl start kibana 


#Enable the Kibana service

systemctl enable kibana

