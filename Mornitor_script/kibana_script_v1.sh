#!bin/bash

# Install Kibana on Ubuntu 14.04
# Date : 23/01/2017

ip_add=$(ip addr show $1| grep -w "scope global" | awk {'print $2'} | awk -F"/" {'print $1'})

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

install_kibana(){
	clear
	echo "Installing Kibana ..."
	dpkg -i kibana-5.1.1-amd64.deb
	sleep 1
	
	echo "Configuaration ..."
	kibana=/etc/kibana/kibana.yml
#	ip_add=$(ip addr show $1| grep -w "scope global" | awk {'print $2'} | awk -F"/" {'print $1'})
	
	test -f $kibana.bka || cp $kibana $kibana.bka
	
	sed -i 's/#server.host: "localhost"/server.host: "'"$ip_add"'"/g' /etc/kibana/kibana.yml
	sed -i 's/#server.name: "your-hostname"/server.name: "Kibana"/g' /etc/kibana/kibana.yml
	sed -i 's/#kibana.index: ".kibana"/kibana.index: ".kibana"/g' /etc/kibana/kibana.yml
	sed -i 's/#elasticsearch.url:/elasticsearch.url:/g' /etc/kibana/kibana.yml
	
	echo -n "IP elasticsearch: "
	read ip_elasticsearch
	sed -i 's/localhost:9200/'"$ip_elasticsearch"':9200/g' /etc/kibana/kibana.yml
	update-rc.d kibana defaults 96 9
	service kibana restart
}
install_nginx()
{
	echo "Install Nginx ..."
    apt-get install nginx apache2-utils -y
    echo -n "Set username Nginx: "
    read USERNAME
    htpasswd -c /etc/nginx/htpasswd.users $USERNAME
	nginx=/etc/nginx/sites-available/default
    test -f $nginx.bka || cp $nginx $nginx.bka

    cat << EOF > /etc/nginx/sites-available/default
    server {
    listen 80;

    server_name Kibana;

    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/htpasswd.users;

    location / {
        proxy_pass http://$ip_add:5601;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;        
	    }
	}			
EOF
service nginx restart 
echo "DONE!"
}

main()
{
	check_permission
	check_distro
	install_kibana
	install_nginx	
}

main

