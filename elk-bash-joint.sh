#!/bin/bash


#First thing we wanted download and install java from oracle
#Here is the link http://java.com/en/download/manual.jsp
#We need to take the latest and greatest as default
#We will remove things first

#Tameika Added the following seems to work better now
#
systemctl stop logstash
systemctl stop elasticsearch
service stop kibana
systemctl disable logstash
systemctl disable elasticsearch
systemctl disable kibana


yum remove kibana elasticsearch jre1.8.* -y

elasticrepo="/etc/yum.repos.d/elasticsearch.repo"
kibanarepo="/etc/yum.repos.d/kibana.repo"
ip=127.0.0.1
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
systemctl daemon-reload
systemctl enable elasticsearch 
systemctl start elasticsearch
#service elasticsearch start
#chkconfig elasticsearch on

#Created by Ayotunde
#Create and edit a new yum repository file for Kibana.
#Also add the repository configuration to the file.
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

sed -i '/server.host/c\server.host: "localhost"' /opt/kibana/config/kibana.yml

#############
sleep 10 

#Start the Kibana service

echo "Starting and enabling Kibana Service"

#systemctl start kibana.service 
service kibana start

#Enable the Kibana service

systemctl enable kibana.service
#chkconfig kibana on
##!/usr/bin/env bash
#
#if [[ ${EUID} -ne 0 ]]; then
#  echo "Please run this script as root or with sudo. Exiting." >&2
#  exit 1
#fi
#
#if [[ $# -ne 1 ]]; then
#  echo "Usage: $0 <ip_address>" >&2
#  exit 1
#else
#  ip=$1
#fi
#
#
cat <<EOF > /etc/yum.repos.d/logstash.repo
[logstash-2.2]
name=logstash repository for 2.2 packages
baseurl=http://packages.elasticsearch.org/logstash/2.2/centos
gpgcheck=1
gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
enabled=1
EOF

yum install -y logstash

cat <<EOF > /etc/logstash/conf.d/02-beats-input.conf
input {
  beats {
    port => 5044
    ssl => true
    ssl_certificate => "/etc/pki/tls/certs/logstash-forwarder.crt"
    ssl_key => "/etc/pki/tls/private/logstash-forwarder.key"
  }
}
EOF

cat <<EOF > /etc/logstash/conf.d/10-syslog-filter.conf
filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
    add_field => [ "received_at", "%{@timestamp}" ]
    add_field => [ "received_from", "%{host}" ]
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
}
EOF

cat <<EOF > /etc/logstash/conf.d/30-elasticsearch-output.conf
output {
  elasticsearch {
    hosts => ["localhost:9200"]
    sniffing => true
    manage_template => false
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
    document_type => "%{[@metadata][type]}"
  }
}
EOF

cd /etc/pki/tls

if ! grep -q "subjectAltName = IP: ${ip}" /etc/pki/tls/openssl.cnf; then
  sed -i "/^\[ v3_ca \]/a subjectAltName = IP: ${ip}" /etc/pki/tls/openssl.cnf
fi

sudo openssl req -config /etc/pki/tls/openssl.cnf \
     -x509 -days 3650 -batch -nodes -newkey rsa:2048 \
     -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt

service logstash configtest \
 && systemctl restart logstash \
 && sudo chkconfig logstash on

