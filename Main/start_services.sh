#!/bin/bash

# Source environment variables
source ~/.bashrc

# Function to check if a command exists
check_command() {
    if command -v $1 &> /dev/null; then
        echo "✅ $2 is installed"
        return 0
    else
        echo "❌ $2 is NOT installed"
        return 1
    fi
}

# Function to check if service is running
check_service() {
    local service=$1
    local port=$2
    if lsof -i:$port > /dev/null; then
        echo "⚠️ $service is already running on port $port"
        return 1
    fi
    return 0
}

# Function to verify directory exists
verify_dir() {
    local dir=$1
    local name=$2
    if [ ! -d "$dir" ]; then
        echo "❌ $name directory not found at $dir"
        return 1
    fi
    echo "✅ $name directory found at $dir"
    return 0
}

# Function to kill process on port
kill_process_on_port() {
    local port=$1
    local pid=$(lsof -t -i:$port)
    if [ ! -z "$pid" ]; then
        echo "Killing process on port $port (PID: $pid)"
        kill -9 $pid
    fi
}

# Function to check Zookeeper status
check_zookeeper() {
    echo "ruok" | nc localhost 2181 &> /dev/null
    if [ $? -eq 0 ]; then
        echo "✅ Zookeeper is running"
        return 0
    else
        echo "❌ Zookeeper is not running"
        return 1
    fi
}

# Function to setup SSH (thêm function này sau các function check_command, check_service,...)
setup_ssh() {
    echo "Setting up SSH..."
    
    # Cài đặt SSH server nếu chưa có
    if ! command -v sshd &> /dev/null; then
        echo "Installing SSH server..."
        apt-get update
        apt-get install -y openssh-server
    fi

    # Tạo SSH key nếu chưa có
    if [ ! -f ~/.ssh/id_rsa ]; then
        echo "Generating SSH keys..."
        mkdir -p ~/.ssh
        ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
    fi

    # Thêm key vào authorized_keys
    if [ ! -f ~/.ssh/authorized_keys ]; then
        echo "Setting up authorized_keys..."
        cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
    fi

    # Cấu hình SSH cho phép root login
    if ! grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
        echo "Configuring SSH..."
        echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    fi

    # Khởi động lại SSH service
    echo "Restarting SSH service..."
    service ssh restart
    sleep 2

    # Thêm localhost vào known_hosts
    echo "Adding hosts to known_hosts..."
    ssh-keyscan -H localhost >> ~/.ssh/known_hosts 2>/dev/null
    ssh-keyscan -H 0.0.0.0 >> ~/.ssh/known_hosts 2>/dev/null
    ssh-keyscan -H $(hostname) >> ~/.ssh/known_hosts 2>/dev/null

    echo "✅ SSH setup completed"
}

# Sửa lại function setup_environment như sau:
setup_environment() {
    echo "Setting up environment..."
    
    # Setup SSH first
    setup_ssh
    
    # Export Hadoop user variables
    export HDFS_NAMENODE_USER=root
    export HDFS_DATANODE_USER=root
    export HDFS_SECONDARYNAMENODE_USER=root
    export YARN_RESOURCEMANAGER_USER=root
    export YARN_NODEMANAGER_USER=root
    
    # Export Hadoop specific variables
    export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
    
    # Export paths
    export PATH=$PATH:$JAVA_HOME/bin:$KAFKA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HBASE_HOME/bin
    
    # Clean Kafka data
    clean_kafka_data
}

# Function to clean Kafka data
clean_kafka_data() {
    echo "Cleaning Kafka data..."
    
    # Stop any running instances
    $KAFKA_HOME/bin/kafka-server-stop.sh
    $KAFKA_HOME/bin/zookeeper-server-stop.sh
    sleep 5
    
    # Clean Zookeeper data
    rm -rf /tmp/zookeeper
    mkdir -p /tmp/zookeeper
    
    # Clean Kafka logs and data
    rm -rf $KAFKA_HOME/logs/*
    rm -rf /tmp/kafka-logs/*
    rm -f $KAFKA_HOME/config/meta.properties
    
    echo "✅ Kafka data cleaned"
}

# Function to start Kafka services
start_kafka() {
    echo "Starting Kafka services..."
    
    # Start Zookeeper
    echo "Starting Zookeeper..."
    $KAFKA_HOME/bin/zookeeper-server-start.sh -daemon $KAFKA_HOME/config/zookeeper.properties
    sleep 10
    
    if ! check_zookeeper; then
        echo "❌ Failed to start Zookeeper"
        return 1
    fi

    # Start Kafka
    echo "Starting Kafka Server..."
    $KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties
    sleep 15
    
    # Check Kafka
    if ! lsof -i:9092 > /dev/null; then
        echo "❌ Failed to start Kafka"
        return 1
    fi
    echo "✅ Kafka started successfully"

    # Create topic
    echo "Creating Kafka topic..."
    $KAFKA_HOME/bin/kafka-topics.sh --create --topic smartphoneTopic \
        --bootstrap-server localhost:9092 --if-not-exists \
        --partitions 1 --replication-factor 1

    return 0
}

# Function to setup Hadoop (thêm function này trước function start_hadoop)
# Function to setup Hadoop
setup_hadoop() {
    echo "Setting up Hadoop..."
    
    # Create Hadoop directories if they don't exist
    mkdir -p /root/hadoopdata/namenode
    mkdir -p /root/hadoopdata/datanode
    
    # Configure core-site.xml
    cat > $HADOOP_HOME/etc/hadoop/core-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOF

    # Configure hdfs-site.xml
    cat > $HADOOP_HOME/etc/hadoop/hdfs-site.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/root/hadoopdata/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/root/hadoopdata/datanode</value>
    </property>
</configuration>
EOF

    # Format namenode if it hasn't been formatted
    if [ ! -d "/root/hadoopdata/namenode/current" ]; then
        echo "Formatting Namenode..."
        $HADOOP_HOME/bin/hdfs namenode -format
    fi
    
    # Set correct permissions
    chown -R root:root /root/hadoopdata
}

# Sửa lại function start_hadoop
start_hadoop() {
    echo "Starting Hadoop services..."
    
    # Setup Hadoop first
    setup_hadoop
    
    # Stop existing Hadoop services
    stop-all.sh
    sleep 5
    
    # Start Hadoop
    start-all.sh
    sleep 15  # Tăng thời gian chờ lên

    # Verify Hadoop services
    if ! jps | grep -q "NameNode"; then
        echo "❌ Failed to start HDFS NameNode"
        echo "Checking logs..."
        tail -n 50 $HADOOP_HOME/logs/hadoop-root-namenode-*.log
        return 1
    fi
    if ! jps | grep -q "ResourceManager"; then
        echo "❌ Failed to start YARN ResourceManager"
        return 1
    fi
    echo "✅ Hadoop services started successfully"
    
    # Create HDFS directories if needed
    echo "Setting up HDFS directories..."
    $HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/root
    $HADOOP_HOME/bin/hdfs dfs -chmod 755 /user/root
    
    return 0
}

# Function to setup HBase (thêm function này trước start_hbase)
setup_hbase() {
    echo "Setting up HBase..."
    
    # Configure hbase-site.xml
    cat > $HBASE_HOME/conf/hbase-site.xml << EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>hbase.rootdir</name>
        <value>hdfs://localhost:9000/hbase</value>
    </property>
    <property>
        <name>hbase.cluster.distributed</name>
        <value>true</value>
    </property>
    <property>
        <name>hbase.zookeeper.quorum</name>
        <value>localhost</value>
    </property>
    <property>
        <name>hbase.zookeeper.property.dataDir</name>
        <value>/tmp/zookeeper</value>
    </property>
    <property>
        <name>hbase.unsafe.stream.capability.enforce</name>
        <value>false</value>
    </property>
</configuration>
EOF

    # Create HBase directory in HDFS
    $HADOOP_HOME/bin/hdfs dfs -mkdir -p /hbase
    $HADOOP_HOME/bin/hdfs dfs -chmod 777 /hbase
}

# Sửa lại function start_hbase
start_hbase() {
    echo "Starting HBase services..."
    
    # Setup HBase first
    setup_hbase
    
    # Stop existing HBase services
    $HBASE_HOME/bin/stop-hbase.sh
    sleep 5
    
    # Start HBase
    $HBASE_HOME/bin/start-hbase.sh
    sleep 30  # Tăng thời gian chờ lên 30s
    
    # Verify HBase Master
    if ! jps | grep -q "HMaster"; then
        echo "❌ Failed to start HBase Master"
        echo "Checking logs..."
        tail -n 50 $HBASE_HOME/logs/hbase-root-master-*.log
        return 1
    fi
    
    # Start HBase Thrift Server
    echo "Starting HBase Thrift Server..."
    $HBASE_HOME/bin/hbase-daemon.sh start thrift
    sleep 10
    
    # Verify Thrift Server
    if ! jps | grep -q "ThriftServer"; then
        echo "❌ Failed to start HBase Thrift Server"
        echo "Checking logs..."
        tail -n 50 $HBASE_HOME/logs/hbase-root-thrift-*.log
        return 1
    fi
    
    echo "✅ HBase services started successfully"
    return 0
}

# Cleanup function
cleanup() {
    echo "Stopping all services..."
    
    # Stop Kafka services
    $KAFKA_HOME/bin/kafka-server-stop.sh
    $KAFKA_HOME/bin/zookeeper-server-stop.sh
    
    # Stop Hadoop services
    stop-all.sh
    
    # Stop HBase services
    $HBASE_HOME/bin/stop-hbase.sh
    
    # Stop Docker services if running
    if [ -f docker-compose.yml ]; then
        docker-compose down
    fi
    
    # Kill any remaining processes
    kill_process_on_port 2181
    kill_process_on_port 9092
    
    echo "All services stopped"
    exit 0
}

# Trap SIGINT and SIGTERM signals
trap cleanup SIGINT SIGTERM

# Main execution
echo "Starting Big Data Pipeline..."
setup_environment

# Start services in order
if ! start_kafka; then
    echo "❌ Failed to start Kafka services"
    cleanup
    exit 1
fi

if ! start_hadoop; then
    echo "❌ Failed to start Hadoop services"
    cleanup
    exit 1
fi

if ! start_hbase; then
    echo "❌ Failed to start HBase services"
    cleanup
    exit 1
fi

# Start Airflow if docker-compose.yml exists
if [ -f docker-compose.yml ]; then
    echo "Starting Airflow..."
    if ! docker-compose up -d; then
        echo "❌ Failed to start Airflow"
        cleanup
        exit 1
    fi
    echo "✅ Airflow started successfully"
fi

echo -e "\n🎉 All services have been started successfully! You can now:"
echo "1. Run Kafka Producer:   $KAFKA_HOME/bin/kafka-console-producer.sh --topic smartphoneTopic --bootstrap-server localhost:9092"
echo "2. Run Kafka Consumer:   $KAFKA_HOME/bin/kafka-console-consumer.sh --topic smartphoneTopic --from-beginning --bootstrap-server localhost:9092"
echo "3. Access HBase Shell:   $HBASE_HOME/bin/hbase shell"
echo "4. Access Airflow UI:    http://localhost:8080 (if running)"
echo -e "\nTo stop all services, press Ctrl+C"

# Keep script running and monitor services
while true; do
    if ! check_zookeeper || ! lsof -i:9092 > /dev/null; then
        echo "❌ Critical service (Kafka/Zookeeper) has stopped"
        cleanup
        exit 1
    fi
    sleep 30
done