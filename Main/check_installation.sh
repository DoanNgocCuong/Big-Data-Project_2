#!/bin/bash

echo "Checking installations and configurations..."

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

# Function to check if directory exists
check_directory() {
    if [ -d "$1" ]; then
        echo "✅ $2 directory exists"
        return 0
    else
        echo "❌ $2 directory is missing"
        return 1
    fi
}

# Function to check environment variables
check_env_var() {
    if [ -n "${!1}" ]; then
        echo "✅ $1 is set to: ${!1}"
        return 0
    else
        echo "❌ $1 is NOT set"
        return 1
    fi
}

echo "1. Checking Environment Variables:"
check_env_var "JAVA_HOME"
check_env_var "KAFKA_HOME"
check_env_var "HADOOP_HOME"
check_env_var "HBASE_HOME"
check_env_var "SPARK_HOME"

echo -e "\n2. Checking Installations:"
check_command "java" "Java"
check_command "python3" "Python"
check_command "pip" "Pip"
check_command "docker" "Docker"
check_command "docker-compose" "Docker Compose"

echo -e "\n3. Checking Service Directories:"
check_directory "$KAFKA_HOME" "Kafka"
check_directory "$HADOOP_HOME" "Hadoop"
check_directory "$HBASE_HOME" "HBase"
check_directory "$SPARK_HOME" "Spark"

echo -e "\n4. Checking Python Packages:"
echo "Installed Python packages:"
pip list | grep -E "kafka-python|pyspark|requests|docker-compose"

echo -e "\n5. Checking Service Versions:"
echo "Java version:"
java -version
echo -e "\nPython version:"
python3 --version
echo -e "\nDocker version:"
docker --version
echo -e "\nDocker Compose version:"
docker-compose --version

echo -e "\n6. Checking Service Configurations:"
echo "Checking Kafka config:"
if [ -f "$KAFKA_HOME/config/server.properties" ]; then
    echo "✅ Kafka server.properties exists"
else
    echo "❌ Kafka server.properties is missing"
fi

echo "Checking Hadoop config:"
if [ -f "$HADOOP_HOME/etc/hadoop/core-site.xml" ]; then
    echo "✅ Hadoop core-site.xml exists"
else
    echo "❌ Hadoop core-site.xml is missing"
fi

echo -e "\n7. Testing Basic Service Commands:"
echo "Testing Kafka commands:"
$KAFKA_HOME/bin/kafka-topics.sh --version 2>/dev/null || echo "❌ Kafka commands not working"

echo "Testing Hadoop commands:"
hadoop version 2>/dev/null || echo "❌ Hadoop commands not working"

echo "Testing Spark commands:"
spark-submit --version 2>/dev/null || echo "❌ Spark commands not working"

echo -e "\nInstallation check completed!"