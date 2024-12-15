```bash
chmod +x commands.sh
```

```bash
cd Main
./install_services.sh
./check_installation.sh
./start_services.sh
chmod +x check_start.sh
./check_start.sh
```





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
kafka-topics.sh --list --bootstrap-server localhost:9092


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

---
```bash
/root/GIT/Big-Data-Project_2/Main/Lambda/
├── Batch_layer/
├── Stream_layer/
│   ├── init.py
│   ├── stream_pipeline.py
│   ├── ML_consumer.py
│   ├── insert_data_hbase.py
├── ML_operations/
├── Stream_data/
│   ├── stream_data.py
├── producer.py
└── transform.py
```


### Run stream_pipeline.py

Khi run stream_pipeline.py, sẽ có thông báo như này: 

```
.hbase.thirdparty.io.netty.channel.DefaultChannelPipeline$HeadContext.channelRead(DefaultChannelPipeline.java:1410)\n\tat org.apache.hbase.thirdparty.io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:440)\n\tat org.apache.hbase.thirdparty.io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:420)\n\tat org.apache.hbase.thirdparty.io.netty.channel.DefaultChannelPipeline.fireChannelRead(DefaultChannelPipeline.java:919)\n\tat org.apache.hbase.thirdparty.io.netty.channel.nio.AbstractNioByteChannel$NioByteUnsafe.read(AbstractNioByteChannel.java:166)\n\tat org.apache.hbase.thirdparty.io.netty.channel.nio.NioEventLoop.processSelectedKey(NioEventLoop.java:788)\n\tat org.apache.hbase.thirdparty.io.netty.channel.nio.NioEventLoop.processSelectedKeysOptimized(NioEventLoop.java:724)\n\tat org.apache.hbase.thirdparty.io.netty.channel.nio.NioEventLoop.processSelectedKeys(NioEventLoop.java:650)\n\tat org.apache.hbase.thirdparty.io.netty.channel.nio.NioEventLoop.run(NioEventLoop.java:562)\n\tat org.apache.hbase.thirdparty.io.netty.util.concurrent.SingleThreadEventExecutor$4.run(SingleThreadEventExecutor.java:997)\n\tat org.apache.hbase.thirdparty.io.netty.util.internal.ThreadExecutorMap$2.run(ThreadExecutorMap.java:74)\n\tat org.apache.hbase.thirdparty.io.netty.util.concurrent.FastThreadLocalRunnable.run(FastThreadLocalRunnable.java:30)\n\t... 1 more\n')
Produced: ['242', 'Infinix', 'HOT 12 Display ', '6.82', '4.0', '128.0', '13MP + 8MP', 'Dual', '5000.0', '20%', '3.5', 'Kingsly', '74%', '287', 'No reviews'] to Kafka topic: smartphoneTopic
Message sent to Kafka topic
Produced: ['113', 'Samsung', 'Galaxy S21 5G ', '6.2', '8.0', '128.0', '64MP + 12MP + 12MP + 10MP', 'Single', '0.0', '20%', '0.0', 'The Sleek Gadgets', '66%', '27', 'No reviews'] to Kafka topic: smartphoneTopic
Message sent to Kafka topic
Produced: ['8', 'Infinix', 'Smart 7 HD ', '6.6', '2.0', '64.0', '8MP + 5MP', 'Dual', '5000.0', '24%', '4.5', 'Tech Traders', '86%', '722', '[ (5 out of 5) camera ], [ (3 out of 5) Like it ], [ (5 out of 5) i love it ], [ (4 out of 5) I like it ], [ (4 out of 5) nice ], [ (5 out of 5) Excellent ], [ (5 out of 5) got what i ordered ], [ (4 out of 5) i liked it ], [ (5 out of 5) ???????? ], [ (5 out of 5) CONVINIENCY ]'] to Kafka topic: smartphoneTopic
Message sent to Kafka topic
Produced: ['158', 'Sowhat', 'Find 40 ', '6.6', '2.0', '32.0', '5MP + 13MP', 'Dual', 
```

Bật app Flask để xem dữ liệu được gửi đến Kafka: 
```python
# venv/bin/activate
source venv/bin/activate
cd "Main/Lambda/real_time_web_app(Flask)"
python3 app.py
```
