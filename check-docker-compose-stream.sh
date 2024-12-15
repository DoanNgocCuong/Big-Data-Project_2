#!/bin/bash

# check-docker-compose-stream.sh
echo "=== Checking Docker Stream Services ==="

# Màu sắc cho output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function kiểm tra service
check_service() {
    local service=$1
    if docker ps | grep -q $service; then
        echo -e "${GREEN}✓ $service is running${NC}"
        return 0
    else
        echo -e "${RED}✗ $service is not running${NC}"
        return 1
    fi
}

# Function kiểm tra port
check_port() {
    local port=$1
    local service=$2
    if nc -z localhost $port; then
        echo -e "${GREEN}✓ Port $port ($service) is accessible${NC}"
        return 0
    else
        echo -e "${RED}✗ Port $port ($service) is not accessible${NC}"
        return 1
    fi
}

echo -e "\n${YELLOW}1. Checking Basic Services...${NC}"
services=("zookeeper" "kafka" "hadoop-namenode" "hadoop-datanode" "yarn-resourcemanager" "yarn-nodemanager" "hbase" "stream-pipeline" "flask-webapp")
for service in "${services[@]}"; do
    check_service $service
done

echo -e "\n${YELLOW}2. Checking Ports...${NC}"
echo "--- Zookeeper & Kafka ---"
check_port 2181 "Zookeeper"
check_port 9092 "Kafka"

echo -e "\n--- Hadoop ---"
check_port 9870 "Hadoop NameNode UI"
check_port 9000 "Hadoop NameNode"
check_port 8088 "YARN ResourceManager"

echo -e "\n--- HBase ---"
check_port 16010 "HBase Master UI"
check_port 9090 "HBase Thrift"

echo -e "\n--- Web App ---"
check_port 5000 "Flask Web App"

echo -e "\n${YELLOW}3. Checking Kafka Topic...${NC}"
echo "Listing Kafka topics:"
docker exec kafka kafka-topics.sh --list --bootstrap-server kafka:9092

echo -e "\n${YELLOW}4. Checking HBase Tables...${NC}"
echo "Listing HBase tables:"
docker exec hbase bash -c "echo 'list' | hbase shell"

echo -e "\n${YELLOW}5. Checking Logs...${NC}"
echo "--- Last 5 lines of each service log ---"
for service in "${services[@]}"; do
    echo -e "\n${GREEN}$service logs:${NC}"
    docker logs $service --tail 5
done

echo -e "\n${YELLOW}6. Checking Network...${NC}"
echo "Network details for stream-network:"
docker network inspect stream-network

echo -e "\n${YELLOW}7. Checking Volumes...${NC}"
echo "Listing volumes:"
docker volume ls | grep -E 'hadoop|hbase'

echo -e "\n${YELLOW}8. Testing Stream Pipeline...${NC}"
echo "Checking Kafka consumer (will show last 5 messages):"
docker exec kafka kafka-console-consumer.sh \
    --bootstrap-server kafka:9092 \
    --topic smartphoneTopic \
    --from-beginning \
    --max-messages 5

echo -e "\n${GREEN}=== Check Complete ===${NC}"

# Kiểm tra lỗi cuối cùng
echo -e "\n${YELLOW}9. Checking for Errors in Logs...${NC}"
for service in "${services[@]}"; do
    echo -e "\n${GREEN}Checking $service for errors:${NC}"
    docker logs $service 2>&1 | grep -i "error\|exception" | tail -5
done