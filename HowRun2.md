
## 6. How to Run
To set up and run the project locally, follow these steps:

  - Clone the repository:
   ```bash
   git clone https://github.com/aymane-maghouti/Big-Data-Project
   ```


#### **1. Stream Layer**
   - Start Apache zookeeper

   ```batch 
zookeeper-server-start.bat C:/kafka_2.13_2.6.0/config/zookeeper.properties
```
   - Start Kafka server

   ```batch 
kafka-server-start.bat C:/kafka_2.13_2.6.0/config/server.properties
```
   - Create Kafka topic

   ```batch 
kafka-topics.bat --create --topic smartphoneTopic --bootstrap-server localhost:9092
```

  - Run the kafka producer

   ```batch 
kafka-console-producer.bat --topic smartphoneTopic --bootstrap-server localhost:9092
```

  - Run the kafka consumer

   ```batch 
kafka-console-consumer.bat --topic smartphoneTopic --from-beginning --bootstrap-server localhost:9092
```

  - Start HDFS and yarn (start-all or start-dfs and start-yarn)

   ```batch 
start-all  
```
   - Start Hbase
   ```batch 
start-hbase  
```
   - Run thrift server (for Hbase)
   ```batch 
hbase thrift start
```

after all this run `stream_pipeline.py` script.

and then open the spring boot appliation in your idea and run  it (you can access to the web app locally on  `localhost:8081/`)

---

![spring_boot](images/run_web_app.png)


note that there is another version of the web app developed using Flask micro-framework(watch the demo video for mor details)


---

Thay bằng: 
1. thay bằng `docker-compose -f docker-compose-stream.yml up -d`

```bash

PS D:\OneDrive - Hanoi University of Science and Technology\GIT\BigData-Project\Big-Data-Project_2\Main\Lambda> docker network ls
NETWORK ID     NAME                    DRIVER    SCOPE
bc2bf2a7361c   batch_layer_default     bridge    local
85613aaea658   bridge                  bridge    local
30149d731c72   host                    host      local
e26a4cf556ce   lambda_stream-network   bridge    local
dd052fff3f84   none                    null      local
28fd717c4091   src_default             bridge    local
```

### 2. Chỉnh các file trong `Stream_layer` để kết nối đúng với hbase và kafka. Đến 1 lúc kết quả sẽ đúng. 



Từ log, tôi thấy hệ thống đang hoạt động như sau:

1. **Producer hoạt động tốt:**
```
17:14:52 Produced: ['349', 'Realme', 'C21Y ',...] to Kafka topic: smartphoneTopic
17:14:52 Message sent to Kafka topic
```

2. **ML Pipeline hoạt động:**
```
17:15:02 before ml operation
17:15:02 ['43', 'Samsung', 'Galaxy A03 Core ',...]
17:15:02 [8, 6.5, 2.0, 32.0, 1, 5000.0]
17:15:02 ['Samsung', 6.5, 2.0, 32.0, 'Dual', 5000.0]
17:15:02 ['Samsung', 6.5, 2.0, 32.0, 'Dual', 5000.0, 981.75995]
```
- Nhận dữ liệu
- Xử lý features
- Dự đoán giá: 981.75995

3. **Warning từ XGBoost:**
```
17:15:02 WARNING: /workspace/src/common/error_msg.h:80: If you are loading a serialized model...
```
- Cảnh báo về việc sử dụng serialized model
- Không ảnh hưởng đến kết quả dự đoán

4. **Vấn đề:**
- Không thấy log về việc lưu dữ liệu vào HBase
- Không thấy error log về kết nối HBase như trước

Cần kiểm tra:

- Đảm bảo các services khởi động theo đúng thứ tự (Zookeeper → HBase → Kafka → Stream Pipeline → Web App)



#### **2. Batch Layer**

```
1. Start the Apache Airflow instance:
docker-compose up -d
Access the Apache Airflow web UI (localhost:8080) and run the DAG

@docker-compose.yaml 


2. Start Apache Spark
spark-shell

3. Start Apache zookeeper
zookeeper-server-start.bat C:/kafka_2.13_2.6.0/config/zookeeper.properties

4. Start Kafka server
kafka-server-start.bat C:/kafka_2.13_2.6.0/config/server.properties
Run the kafka producer
kafka-console-producer.bat --topic smartphoneTopic --bootstrap-server localhost:9092
Run the kafka consumer
kafka-console-consumer.bat --topic smartphoneTopic --from-beginning --bootstrap-server localhost:9092

5. Run HDFS and yarn (start-all or start-dfs and start-yarn)
start-all  

======

Viết thành @docker-compose-batch.yml 
```


```
Dựa vào cấu trúc thư mục mới của bạn, tôi thấy file `batch_layer.py` nằm trực tiếp trong thư mục `Batch_layer`. Hãy sửa lại file `syc_with_Airflow.py` như sau:

```python:Main/Lambda/Batch_layer/dags/syc_with_Airflow.py
from pathlib import Path
import sys
import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator

# Thêm đường dẫn tới thư mục cha của dags
SCRIPTS_FOLDER = Path(__file__).parent.parent
sys.path.append(str(SCRIPTS_FOLDER))

# Import trực tiếp từ file batch_layer.py
from batch_layer import batch_layer

default_args = {
    'owner': 'airflow',
    'start_date': datetime.datetime(2024, 3, 29)
}

with DAG(
    dag_id="daily_data_sync",
    default_args=default_args,
    schedule_interval="*/1 * * * *",
    catchup=False
) as dag:
    batch_task = PythonOperator(
        task_id="batch_layer",
        python_callable=batch_layer
    )
```

Và trong docker-compose-batch.yml, sửa phần volumes:

```yaml:Main/Lambda/Batch_layer/docker-compose-batch.yml
volumes:
  - .:/opt/airflow/batch_layer  # Mount toàn bộ thư mục Batch_layer
  - ./dags:/opt/airflow/dags
```

Cấu trúc thư mục hiện tại của bạn:
```
Batch_layer/
├── dags/
│   ├── __init__.py
│   └── syc_with_Airflow.py
├── __init__.py
├── batch_layer.py
├── batch_pipeline.py
├── HDFS_consumer.py
├── put_data_hdfs.py
├── save_data_postgresql.py
├── spark_tranformation.py
└── docker-compose-batch.yml
```

Sau khi sửa:
1. Đảm bảo có `__init__.py` trong thư mục `Batch_layer`
2. Restart containers:
```bash
docker-compose -f docker-compose-batch.yml down
docker-compose -f docker-compose-batch.yml up -d
```

3. Kiểm tra logs:
```bash
docker logs airflow-webserver
docker logs airflow-scheduler
```

Nếu vẫn gặp lỗi, có thể thử debug bằng cách:
1. Thêm logging để xem đường dẫn:
```python
import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

logger.info(f"SCRIPTS_FOLDER: {SCRIPTS_FOLDER}")
logger.info(f"sys.path: {sys.path}")
```

2. Kiểm tra nội dung container:
```bash
docker exec -it airflow-webserver bash
ls -la /opt/airflow/
python3 -c "import sys; print(sys.path)"
```
```