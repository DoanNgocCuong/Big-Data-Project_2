#!/bin/bash

# Source environment variables
source ~/.bashrc

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Debug function
debug_service() {
    local service=$1
    echo -e "\n${BLUE}🔍 Debugging $service...${NC}"
    
    case $service in
        "zookeeper")
            echo "1. Checking Zookeeper logs:"
            tail -n 50 $KAFKA_HOME/logs/zookeeper.out
            echo -e "\n2. Checking Zookeeper connection:"
            echo "ruok" | nc localhost 2181
            echo -e "\n3. Checking Zookeeper status:"
            $KAFKA_HOME/bin/zookeeper-shell.sh localhost:2181 stat
            ;;
            
        "kafka")
            echo "1. Checking Kafka logs:"
            tail -n 50 $KAFKA_HOME/logs/server.log
            echo -e "\n2. Listing Kafka topics:"
            $KAFKA_HOME/bin/kafka-topics.sh --list --bootstrap-server localhost:9092
            echo -e "\n3. Checking Kafka consumer groups:"
            $KAFKA_HOME/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
            echo -e "\n4. Checking topic details:"
            $KAFKA_HOME/bin/kafka-topics.sh --describe --topic smartphoneTopic --bootstrap-server localhost:9092
            ;;
            
        "hadoop")
            echo "1. Checking HDFS report:"
            hdfs dfsadmin -report
            echo -e "\n2. Checking HDFS directory status:"
            hdfs dfs -ls /
            echo -e "\n3. Checking Hadoop logs:"
            tail -n 50 $HADOOP_HOME/logs/hadoop-root-namenode-*.log
            echo -e "\n4. Checking YARN status:"
            yarn node -list -all
            ;;
            
        "hbase")
            echo "1. Checking HBase status:"
            echo "status" | hbase shell
            echo -e "\n2. Checking HBase logs:"
            tail -n 50 $HBASE_HOME/logs/hbase-root-master-*.log
            echo -e "\n3. Listing HBase tables:"
            echo "list" | hbase shell
            echo -e "\n4. Checking HBase Thrift server:"
            netstat -nlp | grep 9090
            ;;
            
        *)
            echo "Unknown service"
            ;;
    esac
}

# Function to check disk space
check_disk_space() {
    echo -e "\n${YELLOW}Checking disk space...${NC}"
    df -h /tmp
    df -h $KAFKA_HOME
    df -h $HADOOP_HOME
    df -h $HBASE_HOME
}

# Function to check memory usage
check_memory() {
    echo -e "\n${YELLOW}Checking memory usage...${NC}"
    free -h
    echo -e "\nTop memory processes:"
    ps aux --sort=-%mem | head -n 5
}

# Function to check network status
check_network() {
    echo -e "\n${YELLOW}Checking network status...${NC}"
    echo "1. Network interfaces:"
    ip addr show
    echo -e "\n2. Listening ports:"
    netstat -tulpn | grep -E ":(2181|9092|9000|16000|16010|9090)"
    echo -e "\n3. Network connections:"
    netstat -ant | grep -E ":(2181|9092|9000|16000|16010|9090)" | awk '{print $6}' | sort | uniq -c
}

# Add debug menu
show_debug_menu() {
    echo -e "\n${YELLOW}Debug Menu:${NC}"
    echo "1. Debug Zookeeper"
    echo "2. Debug Kafka"
    echo "3. Debug Hadoop"
    echo "4. Debug HBase"
    echo "5. Check Disk Space"
    echo "6. Check Memory Usage"
    echo "7. Check Network Status"
    echo "8. Show All Services Status"
    echo "9. Exit"
    
    read -p "Enter your choice (1-9): " choice
    
    case $choice in
        1) debug_service "zookeeper" ;;
        2) debug_service "kafka" ;;
        3) debug_service "hadoop" ;;
        4) debug_service "hbase" ;;
        5) check_disk_space ;;
        6) check_memory ;;
        7) check_network ;;
        8) show_running_services ;;
        9) exit 0 ;;
        *) echo "Invalid choice" ;;
    esac
}

# Modify show_running_services to include more details
show_running_services() {
    echo -e "\n${YELLOW}Currently Running Services:${NC}"
    echo "----------------------------------------"
    jps -l
    echo "----------------------------------------"
    echo -e "\n${YELLOW}Service Health Check:${NC}"
    echo "----------------------------------------"
    echo -n "Zookeeper: "
    if echo "ruok" | nc localhost 2181 &> /dev/null; then echo -e "${GREEN}OK${NC}"; else echo -e "${RED}NOT OK${NC}"; fi
    
    echo -n "Kafka: "
    if nc -z localhost 9092; then echo -e "${GREEN}OK${NC}"; else echo -e "${RED}NOT OK${NC}"; fi
    
    echo -n "HDFS: "
    if jps | grep -q "NameNode"; then echo -e "${GREEN}OK${NC}"; else echo -e "${RED}NOT OK${NC}"; fi
    
    echo -n "HBase: "
    if jps | grep -q "HMaster"; then echo -e "${GREEN}OK${NC}"; else echo -e "${RED}NOT OK${NC}"; fi
    
    echo "----------------------------------------"
    
    echo -e "\n${YELLOW}Resource Usage:${NC}"
    echo "----------------------------------------"
    echo "Memory Usage:"
    free -h | grep "Mem:"
    echo -e "\nDisk Usage:"
    df -h / | tail -n 1
    echo "----------------------------------------"
}

# [Previous code remains the same until main execution]

# Modify main execution to include debug option
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
echo "4. Debug Services:       Enter 'd' to access debug menu"

# Add debug menu option
read -p "Enter 'd' for debug menu or any other key to exit: " debug_choice
if [ "$debug_choice" = "d" ]; then
    show_debug_menu
fi