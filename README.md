# Mornitoring
Infrastructure Monitoring with Rsyslog, Kafka, Zookeeper and the ELK Stack

## Content

[1. Overview](#overview)

[2. Client](#client)

[3. Rsyslog server](#rsyslog)

[4. Logstash shipper](#logstash_shipper)

[5. Kafka - Zookeeper](#kafka_zookeeper)

[6. Logstash indexer](#logstash_indexer)

[7. Elasticsearch](#elasticsearch)

[8. Kibana](#kibana)


<a name="overview"></a>
## 1. Overview


Mô hình lab: 

<img src="https://github.com/locvx1234/Mornitoring/blob/master/image/topo.png?raw=true">

OS : Ubuntu 14.04 

RAM : 2GB (riêng Elasticsearch 4GB)


<a name="client"></a>
## 2. Client

Để monitor hệ thống, ta phải cấu hình để các Client server đẩy log về Rsyslog server. Trên mỗi Client server, ta sử dụng Rsyslog để đẩy syslog về Rsyslog Server.


Sửa file `50-default.conf` hoặc tạo một file mới với đuôi `.conf` trong `/etc/rsyslog.d` và đặt dòng xác định ip và port Rsyslog server :
	
	# vi /etc/rsyslog.d/50-default.conf
	
	*.*   @ip-rsyslog-server:514
	
Dấu `@` là quy ước sử dụng UDP

Sau đó restart lại rsyslog:

	# service rsyslog restart 

Một số ứng dụng mặc định không đẩy log vào syslog, ta phải cấu hình riêng có các ứng dụng đó.	

// TODO : Bổ sung thêm từng service 
	
<a name="rsyslog"></a>
## 3. Rsyslog server (192.168.169.200)
Mặc định, rsyslog đã được cài sẵn trên linux.

Uncomment 2 dòng như sau để rsyslog lắng nghe trên port 514 theo giao thức UDP
	
	# provides UDP syslog reception
	$ModLoad imudp
	$UDPServerRun 514

Thêm các dòng sau vào cuối để xác định vị trí lưu log 

	$template TmplAuth,"/data/log/%HOSTNAME%/%PROGRAMNAME%.log"
	Auth.*  ?TmplAuth
	*.*    ?TmplAuth

Tạo folder chứa log

	# mkdir /data
	# mkdir /data/log
	# chown syslog.syslog /data/log
	
Sau đó restart lại rsyslog:

	# service rsyslog restart 

Nếu cấu hình đúng, trong `/data/log` sẽ có log của các Client server đẩy về.

<a name="logstash_shipper"></a>
## 4. Logstash shipper (192.168.169.200)

<a name="java"></a>
Logstash chạy trên nền java nên phải cài đặt java:

	# add-apt-repository -y ppa:webupd8team/java
	# apt-get update
	# apt-get -y install oracle-java8-installer

Check version java
	
	# java -version
	
Cài Logstash từ source 

	# wget https://artifacts.elastic.co/downloads/logstash/logstash-5.1.2.tar.gz
	# tar -xzvf logstash-5.1.2.tar.gz
	# cd logstash-5.1.2
	
Mở file startup 

	# vi config/startup.options 
	
Đặt đường dẫn cho LOGSTASH_HOME, ví dụ
	
	LS_HOME= /root/logstash-5.1.2

Tạo file cấu hình :

Cấu hình sẽ sử dụng 2 plugin là input và output. 

Ví dụ tạo 1 file tên là `logstash_basic.conf`

	input {
		file {
			path => "/data/log/ubuntu/audispd.log"
			type => "syslog"
			start_position => "beginning"
		}
	}

	output { 
		if [type] == "audispd" {
			stdout { codec => rubydebug }
			kafka {

				topic_id => "syslog"
				bootstrap_servers => ["192.168.169.201:9092"]
				}
		}
	}

	
Input xác định địa chỉ file log và gắn type. Output sử dụng 2 plugin: `stout` để hiện thị ngay trên console, `kafka` để xác định topic và server kafka cần đẩy log đến.

Thông tin thêm về các plugin xem [tại đây](https://www.elastic.co/guide/en/logstash/current/index.html)

Chạy logstash sử dụng cấu hình vừa tạo

	# bin/logstash -f logstash_basic.conf 
	
<a name="kafka_zookeeper"></a>
## 5. Kafka - Zookeeper (192.168.169.201)
Cài đặt [Java](#java) - như đã cài trên rsyslog-server

Cài Kafka từ source 

	# wget http://www-eu.apache.org/dist/kafka/0.10.1.1/kafka_2.10-0.10.1.1.tgz
	
Link mirror http://www-us.apache.org/dist/kafka/0.10.1.1/kafka_2.10-0.10.1.1.tgz

Giải nén

	# tar -xzvf kafka_2.10-0.10.1.1.tgz 

Cấu hình cho Kafka server

	# cd kafka_2.10-0.10.1.1
	# vi config/server.properties
	
Uncomment 
	
	...
	listeners=PLAINTEXT://:9092
	...
	advertised.listeners=PLAINTEXT://192.168.169.201:9092


Khởi động Zookeeper server:

	# bin/zookeeper-server-start.sh config/zookeeper.properties

Khởi động Kafka server: 

	# bin/kafka-server-start.sh config/server.properties
	
Tạo topic :

	# bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic test
	
Để xem các topic đã có :

	# bin/kafka-topics.sh --list --zookeeper localhost:2181
	
Test producer 

	# bin/kafka-console-producer.sh --broker-list localhost:9092 --topic

Test consumer 

	# bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic test --from-beginning
	
[See more ...](https://github.com/locvx1234/Zookeeper-kafka)

<a name="logstash_indexer"></a>
## 6. Logstash indexer (192.168.169.202)

Cài đặt [Java](#java) và Logstash như đã cài trên rsyslog-server

File cấu hình của Logstash indexer, ta sẽ sử dụng 3 plugin : input, filter và output

Ví dụ file `logstash_basic.conf`: 

	input {
		kafka {

		bootstrap_servers => "192.168.169.201:9092"
		topics => ["syslog"]
		client_id => "syslog"
		consumer_threads => 1
		type => "syslog"
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
		if [type] == "syslog" {
			grok {
				patterns_dir => [ "/root/logstash-5.1.2/extra_patterns" ]
				match => { "message" => [ "%{PROG:logprogram} %{AUDIS_BASE} %{GREEDYDATA:message}" ] }
				overwrite => "message"
				add_tag => [ "audis_base_ok" ]
			}
		}
	}

	output {
		if [type] == "syslog" {
			elasticsearch {
			hosts => [ "192.168.169.203:9200" ]
			index => "syslog-%{+YYYY.MM.dd}"
			}
			stdout { codec => rubydebug }
		}
	}
	
Plugin input sẽ lấy log từ kafka qua filter (grok) để định dạng lại log và đưa ra output (elasticsearch)
	
`patterns_dir` gán vào địa chỉ file `extra_patterns` 

// TO DO link giải thích cách viết pattern 	

Chạy logstash sử dụng cấu hình vừa tạo

	# bin/logstash -f logstash_basic.conf 

<a name="elasticsearch"></a>
## 7. Elasticsearch (192.168.169.203)

Elasticsearch cũng cần cài đặt [Java](#java) như Logstash.

Cài đặt Elasticsearch từ gói deb:

	# dpkg -i elasticsearch-5.1.1.deb

Cấu hình cho Elasticsearch:

	# vi /etc/elasticsearch/elasticsearch.yml
	
Xác định một vài tham số: 

	...
	cluster.name: cluster-1
	...
	node.name: node-1
	...
	path.data: /data/elasticsearch
	...
	path.logs: /data/logs
	...
	network.host: 192.168.169.203
	...
	http.port: 9200

Sau đó tạo các thư mục theo cấu hình vừa tạo:
	
	# mkdir /data
	# cd /data/
	# mkdir logs
	# mkdir elasticsearch
	# chown elasticsearch.elasticsearch logs
	# chown elasticsearch.elasticsearch elasticsearch/

Start service:

	# service elasticsearch start

<a name="kibana"></a>
## 8. Kibana (192.168.169.204)
	
Sử dụng gói `kibana-5.1.1-amd64.deb` để cài đặt. 

	# dpkg -i path/to/file/kibana-5.1.1-amd64.deb

Sửa file cấu hình 

	# vi /etc/kibana/kibana.yml
	
Thiết lập một số tham số như sau: 

	...
	server.port: 5601
	...
	server.host: "192.168.169.204"
	...
	server.name: "Kibana"
	...
	elasticsearch.url: "http://192.168.169.203:9200"
	...
	kibana.index: ".kibana"

Bật Kibana và start:

	# update-rc.d kibana defaults 96 9
	# service kibana start
	
Trước khi sử dụng Kibana, ta phải cài đặt một reverse proxy, Nginx
	
Cài đặt Nginx và Apache2-utils

	# apt-get install nginx apache2-utils
	
Sử dụng htpasswd để tạo admin user, trong trường hợp này là "lockibana"

	# htpasswd -c /etc/nginx/htpasswd.users lockibana

Tài khoản này để đăng nhập trên giao diện web của Kibana

Cấu hình Nginx default server block

	$ sudo vi /etc/nginx/sites-available/default
	
Xóa nội dung file và thay thế bởi


	server {
        listen 80;

        server_name Kibana;

        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/htpasswd.users;

        location / {
            proxy_pass http://192.168.169.204:5601;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;        
        }
    }

`server_name` phải đúng servername ở cấu hình Kibana 

Save và exit.

Với cấu hình này, Nginx sẽ kết nối trực tiếp tới Kibana, lắng nghe trên `192.168.169.204:5601`. Ngoài ra Nginx sử dụng file `htpasswd.users` mà chúng ta tạo ra trước đó để xác thực cơ bản.

Restart Nginx:

	# service nginx restart	
	
	
Sử dụng trình duyệt truy cập vào địa chỉ Kibana server để theo dõi log:

Giao diện Kibana:

<img src="https://github.com/locvx1234/Mornitoring/blob/master/image/kibana.png?raw=true">
	
	
	
	