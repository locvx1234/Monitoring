#!bin/bash

# Install Kafka and Zookeeper on Ubuntu 14.04
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
	if test ! -f /usr/bin/java 2> /dev/null
    then
        echo "Installing Java 8 ..." 
        add-apt-repository -y ppa:webupd8team/java
        apt-get update
        apt-get -y install oracle-java8-installer
    fi

}
install_kafka()
{
	echo "Install Logstash ..."
	cd
	wget http://www-eu.apache.org/dist/kafka/0.10.1.1/kafka_2.10-0.10.1.1.tgz
	tar -xzvf kafka_2.10-0.10.1.1.tgz 
	cd kafka_2.10-0.10.1.1	

	ip_add=$(ip addr show $1| grep -w "scope global" | awk {'print $2'} | awk -F"/" {'print $1'})

	sed -i 's/#listeners=PLAINTEXT:\/\/:9092/listeners=PLAINTEXT:\/\/:9092/g' config/server.properties
	sed -i 's/#advertised.listeners=PLAINTEXT:\/\/your.host.name:9092/advertised.listeners=PLAINTEXT:\/\/'"$ip_add"':9092/g' config/server.properties

	bin/zookeeper-server-start.sh config/zookeeper.properties &
	bin/kafka-server-start.sh config/server.properties &
}

main()
{
	check_permission
	check_distro
	install_java
	install_kafka
}

main

