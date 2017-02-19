#!bin/bash

# Install Rsyslog and Logstash on Ubuntu 14.04
# Date : 23/01/2017

check_permission()
{
	[ $(id -u) -eq 0 ] || { echo "$0: Only root may run this script."; echo "ERROR: Permission deny" >> /var/log/elk.log; exit 1; }
}

check_distro()
{
	os=$(lsb_release -is)
	release=$(lsb_release -rs)
    if [ $os != 'Ubuntu' ] && [ $release != '14.04' ] 
	then
		echo "Script available to Ubuntu 14.04!"
		echo "ERROR: This OS is not compatible" >> /var/log/elk.log
	exit 1	
	fi
}

config_rsyslog()
{
	echo "Configuration rsyslog ..."
	rsyslog=/etc/rsyslog.conf
	
	test -f $rsyslog.bak || cp $rsyslog $rsyslog.bak

	sed -i 's/#\$ModLoad imudp/\$ModLoad imudp/g' $rsyslog
	sed -i 's/#\$UDPServerRun 514/\$UDPServerRun 514/g' $rsyslog

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
	
	# Check rsyslog
	rsyslogd -N1 
    [ $? -eq 0 ] || { echo "Rsyslog config invalidate."; exit 1;}
}

install_java()
{
	java -version &> /dev/null
    if test $? -ne 0
    then
        echo "Installing Java 8 ..." 
        add-apt-repository -y ppa:webupd8team/java
        apt-get update
        apt-get -y install oracle-java8-installer
    fi
}
install_logstash()
{
	echo "Install Logstash ..."
	cd
	wget https://artifacts.elastic.co/downloads/logstash/logstash-5.1.2.tar.gz 2>&1 | tee -a /var/log/elk.log
	tar -xzvf logstash-5.1.2.tar.gz
	cd logstash-5.1.2
	
	sed -i 's/LS_HOME\=\/usr\/share\/logstash/LS_HOME\=\/root\/logstash-5.1.2/g' config/startup.options
	echo -n "IP kafka server: "
	read ip_kafka
	
	#  Missing configuration file
	touch config_logstash.conf
	
	echo "Install complete !"
	echo "Edit 'config_logstash.conf' then run 'bin/logstash -f config_logstash.conf' to start"
	#echo " Initializing ..."
	#bin/logstash -f config_logstash.conf
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

