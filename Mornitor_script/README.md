Đây là bộ script để cài đặt và cấu hình các server với mục đích mornitor hệ thống theo mô hình ELK stack kết hợp Kafka, Zookeeper và rsyslog

## Server 1:
File `rsyslog_script` cấu hình cho rsyslog server nhận log theo UDP ở port 514, đồng thời log được Logstash đẩy sang Kafka server theo file.


## Server 2:
File 1: `kafka_script` download Kafka và khởi động Zookeeper server

File 2: `kafka_2_script` khởi động Kafka server 

Sau khi khởi động Zookeeper ở file 1, tạo một session khác và chạy file 2.

## Server 3: 
File `logstash_script` để cài đặt và cấu hình cho Logstash nhận input từ Kafka, đẩy log cho Elasticsearch.

## Server 4: 
File `elasticsearch_script` cài đặt và cấu hình elasticsearch.

Cần chuẩn bị thêm bộ cài `elasticsearch-5.1.1.deb`

## Server 5:
File `kibana_script` cài đặt và cấu hình Kibana

Cần chuẩn bị thêm bộ cài `kibana-5.1.1-amd64.deb`