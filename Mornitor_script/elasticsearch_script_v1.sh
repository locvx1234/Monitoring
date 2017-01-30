#!bin/bash

# Install Elasticsearch on Ubuntu 14.04
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
install_elasticsearch()
{
	clear
	echo "Installing Elasticsearch ..."
	ip_add=$(ip addr show $1| grep -w "scope global" | awk {'print $2'} | awk -F"/" {'print $1'})
	dpkg -i elasticsearch-5.1.1.deb
	elasticsearch=/etc/elasticsearch/elasticsearch.yml

	test -f $elasticsearch.bak || cp $elasticsearch $elasticsearch.bak
	# Make log dir
	mkdir -p /data
	cd /data/
	mkdir -p logs elasticsearch
	chown elasticsearch.elasticsearch logs
	chown elasticsearch.elasticsearch elasticsearch


	#Edit configuaration
	sed -i 's/#cluster.name: my\-application/cluster.name: cluster-1/g' /etc/elasticsearch/elasticsearch.yml
	sed -i 's/#path.data: \/path\/to\/data/path.data: \/data\/elasticsearch/g' /etc/elasticsearch/elasticsearch.yml
	sed -i 's/#path.logs: \/path\/to\/logs/path.logs: \/data\/logs/g' /etc/elasticsearch/elasticsearch.yml
	sed -i 's/#network.host: 192.168.0.1/network.host: '"$ip_add"'/g' /etc/elasticsearch/elasticsearch.yml
	sed -i 's/#http.port: 9200/http.port: 9200/g' /etc/elasticsearch/elasticsearch.yml	

	service elasticsearch start
}
main()
{
	check_permission
	check_distro
	install_java
	install_elasticsearch	
}

main

