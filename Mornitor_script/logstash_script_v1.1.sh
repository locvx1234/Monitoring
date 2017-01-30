#!bin/bash

# Install Logstash index on Ubuntu 14.04
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
	echo -n "IP elasticsearch: "
	read ip_elasticsearch
	
	cat << EOF > config_logstash.conf
input {
    kafka {
        
    bootstrap_servers => "$ip_kafka:9092"
    topics => ["apache-access"]
    client_id => "apache"
    #group_id => "logstash"
    #codec => json
    #auto_commit_interval_ms => 5000
    consumer_threads => 1
    type => "apache-access"  
    }
}

input {
    kafka {
    bootstrap_servers => "$ip_kafka:9092"
    topics => ["syslog"]
    client_id => "syslog"
    #codec => json
    #auto_commit_interval_ms => 5000
    consumer_threads => 1
    type => "syslog"
    }
}

input {
    kafka {
    bootstrap_servers => "$ip_kafka:9092"
    topics => ["mysql"]
    client_id => "mysql"
    #group_id => "logstash"
    #codec => json
    #auto_commit_interval_ms => 5000
    consumer_threads => 1
    type => "mysql"
    }
}

input {
    kafka {

    bootstrap_servers => "$ip_kafka:9092"
    topics => ["ovpn-server"]
    client_id => "ovpn-server"
    #group_id => "logstash"
    #codec => json
    #auto_commit_interval_ms => 5000
    consumer_threads => 1
    type => "ovpn-server"
    }
}
input {
    kafka {
    bootstrap_servers => "$ip_kafka:9092"
    topics => ["proxy"]
    client_id => "proxy"
    #group_id => "logstash"
    #codec => json
    #auto_commit_interval_ms => 5000
    consumer_threads => 1
    type => "proxy"
    }
}

filter {
    grok {
        match => { "message" => "%{TIMESTAMP_ISO8601:timesend_shipper} %{IPORHOST:logsend} %{SYSLOGTIMESTAMP:timesend_client} %{IPORHOST:logsource} %{GREEDYDATA:message}"
        }
        overwrite => "message"
    }
}
filter {
    if [type] == "apache-access" {
        grok {
                match => { "message" => "%{PROG:logprogram} %{COMBINEDAPACHELOG}" }
                #overwrite => [ "message" ]
        }
    }
}

filter {
    if [type] == "syslog" {
        grok {
            patterns_dir => [ "/root/logstash-5.1.2/extra_patterns" ]
            match => { "message" => [ "%{PROG:logprogram} %{AUDIS_BASE} %{GREEDYDATA:message}" ] }
            overwrite => "message"
            add_tag => [ "audis_base_ok" ]
        }
    }
}
filter{ 
   if [type] == "ovpn-server" {
        grok {
           match => { "message" => "%{IPORHOST:server}\[%{INT:srv_port}]+[: ] %{GREEDYDATA:message}"  }
	   overwrite => "message"
           # add_tag => [ "audis_base_ok" ]
    	
	 }
   }
}

filter{
    if [type] == "ovpn-server" {
       grok {
           match => { "message" => "%{HOSTPORT:ip-client} %{GREEDYDATA:status}\: %{GREEDYDATA:message}"  }
           overwrite => "message"
           # add_tag => [ "audis_base_ok" ]

       }
   }
}

filter{
   if [type] == "ovpn-server" {
       grok {
           match => { "message" => "(?:%{WORD:status}|%{GREEDYDATA:status})\: (?:%{WORD:action}\: %{IP:ip_clientnew} \-\> %{GREEDYDATA:ip_clientold}|%{GREEDYDATA:message})"  }
           overwrite => "message"
           # add_tag => [ "audis_base_ok" ]

       }
   }
}
filter {
    if [type] == "proxy" {
        grok {
	    patterns_dir => [ "/root/logstash-5.1.2/extra_patterns" ]
            match => { "message" => "%{PROG:logprogram} %{SQUID3}" }
            #overwrite => [ "message" ]
        }
	date {
            match => [ "timestamp", "UNIX" ]
            remove_field => [ "timestamp" ]
        }
    }
}

output {
    if [type] == "apache-access" {
	elasticsearch {
	hosts => [ "$ip_elasticsearch:9200" ]
	user => logstash_writer
	password => "logstash"
	index => "apache-access-%{+YYYY.MM.dd}"
	}
#	stdout { codec => rubydebug }		
    }

    if [type] == "syslog" {
	elasticsearch { 
	hosts => [ "$ip_elasticsearch:9200" ]
	user => logstash_writer
        password => "logstash"
	index => "syslog-%{+YYYY.MM.dd}"
	}
	stdout { codec => rubydebug }
    }

#    if [type] == "mysql" {
#        elasticsearch {
#        hosts => [ "$ip_elasticsearch:9200" ]
#	user => elastic
#       password => "12345678"
#        index => "mysql-%{+YYYY.MM.dd}"
#        }
#        stdout { codec => rubydebug }
#    }
    
#    if [type] == "switch" {
#        elasticsearch {
#        hosts => [ "$ip_elasticsearch:9200" ]
#        user => logstash_writer
#        password => logstash
#     	 index => "switch-%{+YYYY.MM.dd}"
#        }
#        stdout { codec => rubydebug }
#    }

     if [type] == "ovpn-server" {
        elasticsearch {
        hosts => [ "$ip_elasticsearch:9200" ]
	user => logstash_writer
        password => logstash
        index => "ovpn-server-%{+YYYY.MM.dd}"
        }
        stdout { codec => rubydebug }
    }

    if [type] == "proxy" {
        elasticsearch {
        hosts => [ "$ip_elasticsearch:9200" ]
        user => logstash_writer
        password => logstash
        index => "proxy-%{+YYYY.MM.dd}"
        }
        stdout { codec => rubydebug }
    }

}

EOF
	cat << EOF > extra_patterns
TIME_ERROR_APACHE %{DAY} %{MONTH} %{MONTHDAY} %{TIME} %{YEAR}
AUDIS_BASE node=%{IPORHOST} type=%{WORD:audit_type} msg=audit\(%{NUMBER:audit_epoch}:%{NUMBER:audit_counter}\):
AUDIS_SYSCALL arch=%{BASE16NUM:syscal_arch} syscall=%{INT:audit_syscall} success=%{WORD:audit_success} exit=%{INT:syscall_exitcode} a0=%{BASE16NUM:syscall_a0} a1=%{BASE16NUM:syscall_a1} a2=%{BASE16NUM:syscall_a2} a3=%{BASE16NUM:syscall_a3} items=%{INT:audit_items} ppid=%{INT:audit_ppid} pid=%{NUMBER:audit_pid} auid=%{NUMBER:audit_audid} uid=%{NUMBER:audit_uid} gid=%{NUMBER:audit_gid} euid=%{NUMBER:audit_euid} suid=%{NUMBER:audit_suid} fsuid=%{NUMBER:audit_fsuid} egid=%{NUMBER:audit_egid} sgid=%{NUMBER:audit_sgid} fsgid=%{NUMBER:audit_fsgid} ses=%{NUMBER:audit_ses} tty=%{GREEDYDATA:audit_tty} comm=\"%{DATA:audit_comm}\" exe=\"%{PATH:audit_exe}\" key=%{GREEDYDATA:audit_key}
AUDIS_CWD %{AUDIS_BASE} %{WORD:audit_type2}=%{GREEDYDATA:audit_locate}
AUDIS_EXECVE %{AUDIS_BASE} argc=%{INT:audit_argc} %{GREEDYDATA:audit_execve_rest}

#VPN
#VPN_ESTABLISH %{HOSTPORT:ip-client} %{GREEDYDATA:message}
#VPN_VERIFY %{HOSTPORT:ip-client} %{WORD:Auth} %{WORD:status}: depth=%{NUMBER:vnp-depth}\, %{GREEDYDATA:message}
#VPN_CHANNEL %{HOSTPORT:ip-client} %{GREEDYDATA:status}\: %{GREEDYDATA:message}
#VPN_CONNECTION %{HOSTPORT:ip-client} \[%{GREEDYDATA:status}\] %{GREEDYDATA:message}
#VPN_IP  %{WORD:client-name}\/%{HOSTPORT:ip-client} MULTI: %{WORD:action}: %{IP:ip-clientnew} \-\> %{WORD:client-name}\/%{HOSTPORT:ip-client}
#VPN_SEND %{WORD:client-name}\/%{HOSTPORT:ip-client} %{GREEDYDATA:status}\: %{GREEDYDATA:message}
#VPN_send %{WORD:client-name}\/%{HOSTPORT:ip-client} SENT CONTROL \[client1\]: %{GREEDYDATA:message}

#LEARN %{WORD:action}\: %{IP:ip_clientnew} \-\> %{GREEDYDATA:message}
#VPN_SEND (?:%{WORD:status}|%{GREEDYDATA:status})\: (?:%{WORD:action}\: %{IP:ip_clientnew} \-\> %{GREEDYDATA:message}|%{GREEDYDATA:message})
#%{USER:client-name}\/%{HOSTPORT:ip-client} (?:%{WORD:status}|%{GREEDYDATA})\: (?:%{LEARN}|%{GREEDYDATA:message})
#VPN_CONNECTION %{HOSTPORT:ip-client} %{GREEDYDATA:message}

#PROXY
SQUID3 %{NUMBER:timestamp}%{SPACE}%{NUMBER:request_msec:float} %{IPORHOST:src_ip} %{WORD}/%{NUMBER:response_status:int} %{NUMBER:response_size} %{WORD:http_method} (%{URIPROTO:http_proto}://)?%{IPORHOST:dst_host}(?::%{POSINT:port})?(?:%{NOTSPACE:uri_param})? %{USERNAME:user} %{WORD}/(%{IPORHOST:dst_ip}|-)%{GREEDYDATA:content_type}

EOF

	echo " Initializing ..."
	bin/logstash -f config_logstash.conf
}

main()
{
	check_permission
	check_distro
	install_java
	install_logstash
}

main

