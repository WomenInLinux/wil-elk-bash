#!/usr/bin/env bash

if [[ ${EUID} -ne 0 ]]; then
  echo "Please run this script as root or with sudo. Exiting." >&2
  exit 1
fi

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <ip_address>" >&2
  exit 1
else
  ip=$1
fi


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

