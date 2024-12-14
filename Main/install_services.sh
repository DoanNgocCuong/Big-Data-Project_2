# install_services.sh
#!/bin/bash

echo "Installing required services..."

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

# Function to verify installation
verify_installation() {
    local dir=$1
    local name=$2
    if [ ! -d "$dir" ]; then
        echo "❌ $name directory not found at $dir"
        return 1
    fi
    echo "✅ $name found at $dir"
    return 0
}

# Cleanup function
cleanup_old_files() {
    echo "Cleaning up old files..."
    rm -f kafka_*.tgz*
    rm -f hadoop-*.tar.gz*
    rm -f hbase-*.tar.gz*
    rm -f spark-*.tgz*
    rm -rf $HOME/kafka $HOME/hadoop $HOME/hbase $HOME/spark  # Changed from /root to $HOME
}

# Download and verify function
download_and_verify() {
    local url=$1
    local filename=$2
    local max_retries=3
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        echo "Downloading $filename (attempt $((retry+1))/$max_retries)..."
        wget -c "$url" -O "$filename"
        if [ $? -eq 0 ]; then
            if gzip -t "$filename" 2>/dev/null; then
                echo "✅ File integrity check passed for $filename"
                return 0
            fi
        fi
        echo "⚠️ Retry downloading $filename..."
        rm -f "$filename"
        retry=$((retry+1))
        sleep 2
    done
    return 1
}

# Install basic requirements
echo "Installing basic requirements..."
sudo apt-get update
sudo apt-get install -y wget tar gzip lsof net-tools default-jdk python3-apt

# Install Python packages
echo "Installing Python packages..."
pip install --no-cache-dir requests docker-compose kafka-python

# Clean up first
cleanup_old_files

# Install Kafka
echo "Installing Kafka..."
KAFKA_VERSION="3.6.0"
if download_and_verify "https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_2.13-${KAFKA_VERSION}.tgz" "kafka.tgz"; then
    tar -xzf kafka.tgz -C $HOME
    mv $HOME/kafka_2.13-${KAFKA_VERSION} $HOME/kafka
    echo "✅ Kafka installation successful"
else
    echo "❌ Failed to download Kafka"
    exit 1
fi

# Install Hadoop
echo "Installing Hadoop..."
HADOOP_VERSION="3.3.6"
if download_and_verify "https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" "hadoop.tar.gz"; then
    tar -xzf hadoop.tar.gz -C $HOME
    mv $HOME/hadoop-${HADOOP_VERSION} $HOME/hadoop
    echo "✅ Hadoop installation successful"
else
    echo "❌ Failed to download Hadoop"
    exit 1
fi

# Install HBase
echo "Installing HBase..."
HBASE_VERSION="2.5.5"
if download_and_verify "https://archive.apache.org/dist/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz" "hbase.tar.gz"; then
    tar -xzf hbase.tar.gz -C $HOME
    mv $HOME/hbase-${HBASE_VERSION} $HOME/hbase
    echo "✅ HBase installation successful"
else
    echo "❌ Failed to download HBase"
    exit 1
fi

# Install Spark
echo "Installing Spark..."
SPARK_VERSION="3.5.0"
if download_and_verify "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" "spark.tgz"; then
    tar -xzf spark.tgz -C $HOME
    mv $HOME/spark-${SPARK_VERSION}-bin-hadoop3 $HOME/spark
    echo "✅ Spark installation successful"
else
    echo "❌ Failed to download Spark"
    exit 1
fi

# Set environment variables
echo "Setting up environment variables..."
cat > $HOME/.bashrc << EOF
# Java
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Kafka
export KAFKA_HOME=\$HOME/kafka

# Hadoop
export HADOOP_HOME=\$HOME/hadoop
export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop

# HBase
export HBASE_HOME=\$HOME/hbase

# Spark
export SPARK_HOME=\$HOME/spark

# Path
export PATH=\$PATH:\$JAVA_HOME/bin:\$KAFKA_HOME/bin:\$HADOOP_HOME/bin:\$HBASE_HOME/bin:\$SPARK_HOME/bin
EOF

# Clean up downloaded files
rm -f *.tgz *.tar.gz

# Source the new environment variables
source $HOME/.bashrc

# Verify installations
echo "Verifying installations..."
verify_installation "$HOME/kafka" "Kafka"
verify_installation "$HOME/hadoop" "Hadoop"
verify_installation "$HOME/hbase" "HBase"
verify_installation "$HOME/spark" "Spark"

# Fix permissions
chmod -R +x $HOME/kafka/bin/* $HOME/hadoop/bin/* $HOME/hbase/bin/* $HOME/spark/bin/*

# Test commands
echo -e "\nTesting installed versions:"
echo "Java version:"
java -version
echo -e "\nKafka version:"
$KAFKA_HOME/bin/kafka-topics.sh --version
echo -e "\nHadoop version:"
$HADOOP_HOME/bin/hadoop version
echo -e "\nHBase version:"
$HBASE_HOME/bin/hbase version
echo -e "\nSpark version:"
$SPARK_HOME/bin/spark-submit --version

echo -e "\n✅ Installation completed successfully!"
echo "Please run 'source ~/.bashrc' to apply environment variables"