#!bin/bash

# Install Elasticsearch on Ubuntu 14.04
# Date : 23/01/2017

check_permission()
{
	[ $(id -u) -eq 0 ] || { echo "$0: Only root may run this script."; echo "ERROR: Permission deny" > /var/log/elk.log; exit 1; }
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
install_elasticsearch()
{
	clear
	echo "Installing Elasticsearch ..."
	ip_add=$(ip addr show $1| grep -w "scope global" | awk {'print $2'} | awk -F"/" {'print $1'})
	dpkg -i elasticsearch-5.1.1.deb 2>&1 | tee -a /var/log/elk.log
	elasticsearch=/etc/elasticsearch/elasticsearch.yml

	test -f $elasticsearch.bak || cp $elasticsearch $elasticsearch.bak
	# Make log dir
	mkdir -p /data
	cd /data/
	mkdir -p logs elasticsearch
	chown elasticsearch.elasticsearch logs
	chown elasticsearch.elasticsearch elasticsearch


	# Edit configuaration
	sed -i 's/#cluster.name: my\-application/cluster.name: cluster-1/g' $elasticsearch
	sed -i 's/#path.data: \/path\/to\/data/path.data: \/data\/elasticsearch/g' $elasticsearch
	sed -i 's/#path.logs: \/path\/to\/logs/path.logs: \/data\/logs/g' $elasticsearch
	sed -i 's/#network.host: 192.168.0.1/network.host: '"$ip_add"'/g' $elasticsearch
	sed -i 's/#http.port: 9200/http.port: 9200/g' $elasticsearch

	service elasticsearch start
	
	# Check install
	curl -s $ip_add:9200 > /dev/null
    sleep 3
    [ $? -eq 0 ] && echo "Successfully installed!!!" || { echo "Failed to install. Check log in /var/log/elk.log"; exit 1;}

}
main()
{
	check_permission
	check_distro
	install_java
	install_elasticsearch	
}

main

