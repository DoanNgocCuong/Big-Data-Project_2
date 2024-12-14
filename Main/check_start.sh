#!/bin/bash

# Source environment variables
source ~/.bashrc

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check and start Zookeeper
check_start_zookeeper() {
    echo -e "${YELLOW}Checking Zookeeper...${NC}"
    if echo "ruok" | nc localhost 2181 &> /dev/null; then
        echo -e "${GREEN}✅ Zookeeper is already running${NC}"
    else
        echo -e "${RED}❌ Zookeeper is not running. Starting Zookeeper...${NC}"
        $KAFKA_HOME/bin/zookeeper-server-start.sh -daemon $KAFKA_HOME/config/zookeeper.properties
        sleep 10
        if echo "ruok" | nc localhost 2181 &> /dev/null; then
            echo -e "${GREEN}✅ Zookeeper started successfully${NC}"
        else
            echo -e "${RED}❌ Failed to start Zookeeper${NC}"
            return 1
        fi
    fi
}

# Function to check and start Kafka
check_start_kafka() {
    echo -e "${YELLOW}Checking Kafka...${NC}"
    if lsof -i:9092 > /dev/null; then
        echo -e "${GREEN}✅ Kafka is already running${NC}"
    else
        echo -e "${RED}❌ Kafka is not running. Starting Kafka...${NC}"
        $KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties
        sleep 15
        if lsof -i:9092 > /dev/null; then
            echo -e "${GREEN}✅ Kafka started successfully${NC}"
            # Check/Create topic
            if ! $KAFKA_HOME/bin/kafka-topics.sh --list --bootstrap-server localhost:9092 | grep -q "smartphoneTopic"; then
                echo "Creating smartphoneTopic..."
                $KAFKA_HOME/bin/kafka-topics.sh --create --topic smartphoneTopic \
                    --bootstrap-server localhost:9092 --if-not-exists \
                    --partitions 1 --replication-factor 1
            fi
        else
            echo -e "${RED}❌ Failed to start Kafka${NC}"
            return 1
        fi
    fi
}

# Function to check and start Hadoop
check_start_hadoop() {
    echo -e "${YELLOW}Checking Hadoop services...${NC}"
    
    # Check HDFS NameNode
    if ! jps | grep -q "NameNode"; then
        echo -e "${RED}❌ HDFS NameNode is not running. Starting Hadoop...${NC}"
        start-all.sh
        sleep 15
        if jps | grep -q "NameNode"; then
            echo -e "${GREEN}✅ Hadoop services started successfully${NC}"
        else
            echo -e "${RED}❌ Failed to start Hadoop services${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✅ Hadoop services are running${NC}"
    fi
}

# Function to check and start HBase
check_start_hbase() {
    echo -e "${YELLOW}Checking HBase services...${NC}"
    
    # Check HBase Master
    if ! jps | grep -q "HMaster"; then
        echo -e "${RED}❌ HBase is not running. Starting HBase...${NC}"
        $HBASE_HOME/bin/start-hbase.sh
        sleep 30
        if jps | grep -q "HMaster"; then
            echo -e "${GREEN}✅ HBase started successfully${NC}"
            
            # Start Thrift Server if not running
            if ! jps | grep -q "ThriftServer"; then
                echo "Starting HBase Thrift Server..."
                $HBASE_HOME/bin/hbase-daemon.sh start thrift
                sleep 10
                if jps | grep -q "ThriftServer"; then
                    echo -e "${GREEN}✅ HBase Thrift Server started successfully${NC}"
                else
                    echo -e "${RED}❌ Failed to start HBase Thrift Server${NC}"
                fi
            fi
        else
            echo -e "${RED}❌ Failed to start HBase${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✅ HBase is running${NC}"
        # Check Thrift Server
        if ! jps | grep -q "ThriftServer"; then
            echo "Starting HBase Thrift Server..."
            $HBASE_HOME/bin/hbase-daemon.sh start thrift
            sleep 10
        fi
    fi
}

# Function to display all running services
show_running_services() {
    echo -e "\n${YELLOW}Currently Running Services:${NC}"
    echo "----------------------------------------"
    jps
    echo "----------------------------------------"
    echo -e "\n${YELLOW}Listening Ports:${NC}"
    echo "----------------------------------------"
    netstat -tulpn | grep -E ":(2181|9092|9000|16000|16010)"
    echo "----------------------------------------"
}

# Main execution
echo -e "${YELLOW}Checking and starting all services...${NC}"

# Check and start services in order
check_start_zookeeper || exit 1
check_start_kafka || exit 1
check_start_hadoop || exit 1
check_start_hbase || exit 1

# Show final status
show_running_services

echo -e "\n${GREEN}🎉 Service check and start completed!${NC}"
echo -e "You can now:"
echo "1. Run Kafka Producer:   $KAFKA_HOME/bin/kafka-console-producer.sh --topic smartphoneTopic --bootstrap-server localhost:9092"
echo "2. Run Kafka Consumer:   $KAFKA_HOME/bin/kafka-console-consumer.sh --topic smartphoneTopic --from-beginning --bootstrap-server localhost:9092"
echo "3. Access HBase Shell:   $HBASE_HOME/bin/hbase shell"