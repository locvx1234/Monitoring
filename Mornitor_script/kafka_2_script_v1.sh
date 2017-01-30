#!bin/bash

# Start Kafka server on Ubuntu 14.04
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


start_kafka()
{
	cd
	cd kafka_2.10-0.10.1.1	
	bin/kafka-server-start.sh config/server.properties	
}

main()
{
	check_permission
	check_distro
	start_kafka
}

main

