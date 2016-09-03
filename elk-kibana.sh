#!/bin/bash
#Created by Ayotunde
#Create and edit a new yum repository file for Kibana.
#Also add the repository configuration to the file.

#Import the Elasticsearch public GPG key into RPM.

echo "Importing the key for elasticsearch"

rpm --import http://packages.elastic.co/GPG-KEY-elasticsearch


############
kibanarepo="/etc/yum.repos.d/kibana.repo"

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

#Start the Kibana service

echo "Starting and enabling Kibana Service"

systemctl start kibana


#Enable the Kibana service

chkconfig kibana on


