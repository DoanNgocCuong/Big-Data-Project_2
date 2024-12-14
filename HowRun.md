```bash
chmod +x commands.sh
```

```bash
./commands.sh
```

1. Sửa file commands.sh due to confict (we use python 3.10)



## Kiểm tra: 
Để kiểm tra trạng thái các services đang chạy, bạn có thể dùng các cách sau:

1. Kiểm tra các process đang chạy:
```bash
jps
```
Sẽ hiển thị danh sách các Java processes như:
- NameNode
- DataNode
- ResourceManager 
- NodeManager
- HMaster
- HRegionServer
- ThriftServer
- QuorumPeerMain (Zookeeper)

2. Kiểm tra các cổng đang mở:
```bash
netstat -tulpn | grep -E "2181|9092|9000|8088|16000|16010"
```
- 2181: Zookeeper
- 9092: Kafka
- 9000: HDFS
- 8088: YARN ResourceManager
- 16000: HBase Master
- 16010: HBase Master Web UI

3. Truy cập Web UI:
```
HDFS NameNode: http://localhost:9870
YARN ResourceManager: http://localhost:8088  
HBase Master: http://localhost:16010
```

4. Kiểm tra logs:
```bash
# HDFS logs
tail -f $HADOOP_HOME/logs/hadoop-root-namenode-*.log
tail -f $HADOOP_HOME/logs/hadoop-root-datanode-*.log

# HBase logs  
tail -f $HBASE_HOME/logs/hbase-root-master-*.log
tail -f $HBASE_HOME/logs/hbase-root-regionserver-*.log

# Kafka logs
tail -f $KAFKA_HOME/logs/server.log
tail -f $KAFKA_HOME/logs/zookeeper.out
```

5. Kiểm tra trạng thái cụ thể:
```bash
# HDFS status
hdfs dfsadmin -report

# YARN status  
yarn node -list

# HBase status
echo "status" | hbase shell

# Kafka topics
kafka-topics.sh --list --bootstrap-server localhost:9092
```

Các lệnh này sẽ giúp bạn xác định trạng thái hoạt động của từng service trong hệ thống.
