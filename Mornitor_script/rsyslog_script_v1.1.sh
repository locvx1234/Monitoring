#!bin/bash

# Install Rsyslog and Logstash on Ubuntu 14.04
# Date : 23/01/2017

check_permission()
{
	if [ $(id -u) -ne 0 ]
	then 
		echo "Permission denied! You need login as root ^^"
		exit $1
	fi
}

check_distro()
{
	os=$(lsb_release -is)
	if [ $os != 'Ubuntu' ]
	then
		echo "Script available to Ubuntu !"
	exit $1	
	fi
}

config_rsyslog()
{
	echo "Configuration rsyslog ..."
	rsyslog=/etc/rsyslog.conf
	
	test -f $rsyslog.bak || cp $rsyslog $rsyslog.bak

	sed -i 's/#\$ModLoad imudp/\$ModLoad imudp/g' /etc/rsyslog.conf
	sed -i 's/#\$UDPServerRun 514/\$UDPServerRun 514/g' /etc/rsyslog.conf

	cat << EOF >> /etc/rsyslog.conf
\$template TmplAuth,"/data/log/%HOSTNAME%/%PROGRAMNAME%.log"
Auth.*  ?TmplAuth
*.*    ?TmplAuth
	
EOF
	# Make log folder
	mkdir -p /data
	mkdir -p /data/log
	chown syslog.syslog /data/log


	service rsyslog restart 
}
install_java()
{
	echo "Installing Java 8 ..."
	add-apt-repository -y ppa:webupd8team/java
	apt-get update
	apt-get -y install oracle-java8-installer
}
install_logstash()
{
	echo "Install Logstash ..."
	cd
	wget https://artifacts.elastic.co/downloads/logstash/logstash-5.1.2.tar.gz
	tar -xzvf logstash-5.1.2.tar.gz
	cd logstash-5.1.2
	
	sed -i 's/LS_HOME\=\/usr\/share\/logstash/LS_HOME\=\/root\/logstash-5.1.2/g' config/startup.options
	echo -n "IP kafka server: "
	read ip_kafka
	
	cat << EOF > config_logstash.conf
input {
        file {
                path => "/data/log/**/*"
                type => "test-filter"
                start_position => "beginning"
        }

}
input {
	file {
		path => "/data/log/**/nginx-access.log"
		type => "apache-access"
		start_position => "beginning"
	}
}
input {
    file {
    path => "/data/log/**/ovpn*.log"
    type => "ovpn-server"
    start_position => "beginning"
    #codec => "json"
    }
}
input {
    file {
        path => "/data/log/**/audispd.log"
        type => "audispd"
        start_position => "beginning"
    }
}

input {
    file {
    path => "/data/log/**/mysql*"
    type => "mysql"
    start_position => "beginning"
    #codec => "json"
    }
}
input {
    file {
    path => "/data/log/**/*apache*"
    type => "apache-access"
    start_position => "beginning"
    #codec => "json"
    }
}
input {
    file {
    path => "/data/log/**/squid3.log"
    type => "proxy"
    start_position => "beginning"
    }
}
output {
    if [type] == "test-filter" {
        kafka {

        topic_id => "test-filter"
        bootstrap_servers => ["$ip_kafka:9092"]
        }
        stdout { codec => rubydebug }
    }
}

output { 
    if [type] == "audispd" {
        stdout { codec => rubydebug }
        kafka {

            topic_id => "syslog"
            bootstrap_servers => ["$ip_kafka:9092"]
            }
    }
}
output {
    if [type] == "apache-access" {
        kafka {
        
        topic_id => "apache-access"
        bootstrap_servers => ["$ip_kafka:9092"]
	client_id => "apache"
        }
#	stdout { codec => rubydebug }
    }
}
output {
    if [type] == "mysql" {
        kafka {

        topic_id => "mysql"
        bootstrap_servers => ["$ip_kafka:9092"]
		client_id => "mysql"
        }
#	stdout { codec => rubydebug }
    }
}

output {
    if [type] == "ovpn-server" {
        kafka {

        topic_id => "ovpn-server"
        bootstrap_servers => ["$ip_kafka:9092"]
        }
#       stdout { codec => rubydebug }
    }
}

output {
    if [type] == "proxy" {
        kafka {

        topic_id => "proxy"
        bootstrap_servers => ["$ip_kafka:9092"]
        #client_id => "logstash"
        #codec => "json"
        }
#       stdout { codec => rubydebug }
    }
}
EOF

	echo " Initializing ..."
	bin/logstash -f config_logstash.conf
}

main()
{
	check_permission
	check_distro
	config_rsyslog
	install_java
	install_logstash
}

main

