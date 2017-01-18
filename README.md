# Mornitoring
Infrastructure Monitoring with Rsyslog, Kafka, Zookeeper and the ELK Stack

## Content

[1. Overview](#overview)
[2. Client](#)
[3. Rsyslog server](#)
[4. Logstash shipper](#)
[5. Kafka - Zookeeper](#)
[6. Logstash indexer](#)
[7. Elasticsearch](#)
[8. Kibana](#)


<a name="overview"></a>
## 1. Overview


Mô hình lab: 
<img src="">

<a name="client"></a>
## 2. Client

Để monitor hệ thống, ta phải cấu hình để các Client server đẩy log về Rsyslog server. Trên mỗi Client server, ta sử dụng Rsyslog để đẩy syslog về Rsyslog Server.


Sửa file 50-default.conf hoặc tạo một file mới với đuôi .conf trong /etc/rsyslog.d và đặt dòng xác định ip và port rsyslog server :
	
	$ vi /etc/rsyslog.d/50-default.conf
	
	*.*   @ip-rsyslog-server:514
	
Dấu `@` là quy ước sử dụng UDP

Sau đó restart lại rsyslog:

	$ service rsyslog restart 

Một số ứng dụng mặc định không đẩy log vào syslog, ta phải cấu hình riêng có các ứng dụng đó.	

#### Proxy
 
Mở file cấu hình proxy và tìm `syslog` 

	$ vi 
	
Để tìm kiếm trong vi ta dùng `/syslog` và `n` để tìm các từ tiếp theo.

Thêm dòng xác định nơi lưu log proxy :

	
<a name="rsyslog"></a>
## 3. Rsyslog server (192.168.169.200)
Mặc định, rsyslog đã được cài sẵn trên linux.

Uncomment 2 dòng như sau để rsyslog lắng nghe trên cổng 514 theo giao thức UDP
	
	# provides UDP syslog reception
	$ModLoad imudp
	$UDPServerRun 514

Thêm các dòng sau vào cuối để xác định vị trí lưu log 

	$template TmplAuth,"/data/log/%HOSTNAME%/%PROGRAMNAME%.log"
	Auth.*  ?TmplAuth
	*.*    ?TmplAuth

Tạo folder chứa log

	$ mkdir /data
	$ mkdir /data/log
	$ chown syslog.syslog /data/log
	
Sau đó restart lại rsyslog:

	$ service rsyslog restart 

<a name="logstash_shipper"></a>
## 4. Logstash shipper (192.168.169.200)
Logstash chạy trên nền java nên ta phải cài java:

	$ add-apt-repository -y ppa:webupd8team/java
	$ apt-get update
	$ apt-get -y install oracle-java8-installer

Check version java
	
	$ java -version
	
Cài Logstash từ source 

	$ wget https://artifacts.elastic.co/downloads/logstash/logstash-5.1.2.tar.gz
	$ tar -xzvf logstash-5.1.2.tar.gz
	$ cd logstash-5.1.2
	
Mở file startup 

	$ vi config/startup.options 
	
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

	$ bin/logstash -f logstash_basic.conf 
	
## 5. Kafka - Zookeeper (192.168.169.201)
Cài đặt Java  - như đã cài trên rsyslog-server

Cài Kafka từ source 

	$ wget http://www-eu.apache.org/dist/kafka/0.10.1.1/kafka_2.10-0.10.1.1.tgz
	
Link mirror http://www-us.apache.org/dist/kafka/0.10.1.1/kafka_2.10-0.10.1.1.tgz

Giải nén

	$ tar -xzvf kafka_2.10-0.10.1.1.tgz 

Cấu hình cho Kafka server

	$ cd kafka_2.10-0.10.1.1
	$ vi config/server.properties
	
Uncomment 
	
	...
	listeners=PLAINTEXT://:9092
	...
	advertised.listeners=PLAINTEXT://192.168.169.201:9092


Khởi động Zookeeper server:

	$ bin/zookeeper-server-start.sh config/zookeeper.properties

Khởi động Kafka server: 

	$ bin/kafka-server-start.sh config/server.properties
	
Tạo topic :

	$ bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic test
	
Để xem các topic đã có :

	$ bin/kafka-topics.sh --list --zookeeper localhost:2181
	
Test producer 

	$ bin/kafka-console-producer.sh --broker-list localhost:9092 --topic

Test consumer 

	$ bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic test --from-beginning
	
[See more ...](https://github.com/locvx1234/Zookeeper-kafka/blob/master/Kafka.md)

## 6. Logstash indexer (192.168.169.202)

Cài đặt Java và Logstash như đã cài trên rsyslog-server


## 7. Elasticsearch (192.168.169.203)

	$ dpkg -i elasticsearch-5.1.1.deb
	

	


	
	
	