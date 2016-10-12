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
service stop nginx
systemctl disable nginx
systemctl disable logstash
systemctl disable elasticsearch
systemctl disable kibana


yum remove kibana elasticsearch  epel-release-latest-7.noarch.rpm jre1.8.* -y

elasticrepo="/etc/yum.repos.d/elasticsearch.repo"
kibanarepo="/etc/yum.repos.d/kibana.repo"
ip=104.196.186.130


#Uninstalling java
#yum remove jre1.8.0_101-1.8.0_101-fcs.x86_64


#We downloaded the rpm


echo "Installing the java rpm"
rpm -Uvh /opt/wil-elk-bash/jre-8u101-x64.rpm
##########################################

#Verifying our install of jre rpm

echo "Verfiying jre rpm install"

versionnew=`rpm -qa | grep jre1.8.0`

echo -n "$versionnew"

update-alternatives --config java <<< '2'

echo 2 | update-alternatives --config java 

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

sed -i '/network.host/c\ network.host: elk-client' /etc/elasticsearch/elasticsearch.yml
sed -i '/path.data/c\ path.data: /elk' /etc/elasticsearch/elasticsearch.yml

mkdir /elk
chown elasticsearch.elasticsearch /elk

#We will now enable and start this service

echo "We are enabled and starting elastic"
#systemctl daemon-reload
systemctl enable elasticsearch 
systemctl restart elasticsearch
#service elasticsearch start
#chkconfig elasticsearch on

break

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

sed -i '/server.host/c\server.host: $ip' /opt/kibana/config/kibana.yml

#############
sleep 10 

#Start the Kibana service

echo "Starting and enabling Kibana Service"

#systemctl start kibana.service 
service kibana start

#Enable the Kibana service

systemctl enable kibana.service

#Installing Nginx
echo "We are setting ourselves for a yum install of the epel"

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm 

echo "Installing httpd tools"

yum -y install httpd-tools

yum install http://nginx.org/packages/mainline/centos/7/x86_64/RPMS/nginx-1.11.0-1.el7.ngx.x86_64.rpm -y

htpasswd -b -c /etc/nginx/htpasswd.users kibanaadmin ltcuser

echo 'server {
     listen 80;
     server_name 104.196.186.130;
     auth_basic "Restricted Access";
     auth_basic_user_file /etc/nginx/htpasswd.users;

    location / {
        proxy_pass http://104.196.186.130:5601;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;        
    }
} ' | tee /etc/nginx/conf.d/kibana.conf > /dev/null &2>1



echo "We are starting and enable nginx"
echo "We will also ensure httpd is stopped because port conflict"

systemctl stop httpd
systemctl disable httpd
systemctl start nginx
systemctl enable nginx
#setsebool -P httpd_can_network_connect 1

#Installing logstash
echo '[logstash-2.2]
name=logstash repository for 2.2 packages
baseurl=http://packages.elasticsearch.org/logstash/2.2/centos
gpgcheck=1
gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
enabled=1 ' | tee /etc/yum.repos.d/logstash.repo

yum install -y logstash

echo 'input {
  beats {
    port => 5044
    ssl => true
    ssl_certificate => "/etc/pki/tls/certs/logstash-forwarder.crt"
    ssl_key => "/etc/pki/tls/private/logstash-forwarder.key"
  }
}' | tee /etc/logstash/conf.d/02-beats-input.conf 

#Logstash filters 

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
    hosts => ["${ip}:9200"]
    sniffing => true
    manage_template => false
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
    document_type => "%{[@metadata][type]}"
  }
}
EOF

cd /etc/pki/tls

if ! grep -q "subjectAltName = IP: ${ip}"  /etc/pki/tls/openssl.cnf; then
  sed -i "/^\[ v3_ca \]/a subjectAltName = IP: ${ip}" /etc/pki/tls/openssl.cnf
fi

sudo openssl req -config /etc/pki/tls/openssl.cnf \
     -x509 -days 3650 -batch -nodes -newkey rsa:2048 \
     -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt

service logstash configtest \
 && systemctl restart logstash \
 && sudo chkconfig logstash on
###########################################################
#Load Kibana Dashboards
rm -rf /opt/beats*

cd /opt

curl -L -O https://download.elastic.co/beats/dashboards/beats-dashboards-1.1.0.zip

yum -y install unzip

unzip beats-dashboards*.zip

cd beats-dashboards-*

chmod +x load.sh

sed -i '/localhost/c\http://104.196.186.130:9200/' load.sh

sh load.sh

cd /opt

curl -O https://gist.githubusercontent.com/thisismitch/3429023e8438cc25b86c/raw/d8c479e2a1adcea8b1fe86570e42abab0f10f364/filebeat-index-template.json


curl -XPUT 'http://104.196.186.130:9200/_template/filebeat?pretty' -d@filebeat-index-template.json

#You need to replace this with the appropriate client
#scp /etc/pki/tls/certs/logstash-forwarder.crt tameika@10.142.0.2:/tmp
