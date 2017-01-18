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
	
Sau đó restart lại rsyslog:

	$ service rsyslog restart 

Một số ứng dụng mặc định không đẩy log vào syslog, ta phải cấu hình riêng có các ứng dụng đó.	

#### Proxy
 
Mở file cấu hình proxy và tìm `syslog` 

	$ vi 
	
Để tìm kiếm trong vi ta dùng `/syslog` và `n` để tìm các từ tiếp theo.

Thêm dòng xác định nơi lưu log proxy :

	
<a name="rsyslog"></a>
## 3. Rsyslog server
Mặc định, rsyslog đã được cài sẵn trên linux.

Uncomment 2 dòng như sau để rsyslog lắng nghe trên cổng 514 theo giao thức UDP
	
	# provides UDP syslog reception
	$ModLoad imudp
	$UDPServerRun 514
	
Sau đó restart lại rsyslog:

	$ service rsyslog restart 

<a name="logstash_shipper"></a>
## 4. Logstash shipper
Logstash chạy trên nền java nên ta phải cài java:

	$ sudo add-apt-repository -y ppa:webupd8team/java
	$ sudo apt-get update
	$ sudo apt-get -y install oracle-java8-installer

Check version java
	
	$ java -version
	
Cài Logstash từ source 

	$ wget
	$ tar -xzf logstash-5.1.2.tar
	$ cd logstash-5.1.2.tar

	
	
	