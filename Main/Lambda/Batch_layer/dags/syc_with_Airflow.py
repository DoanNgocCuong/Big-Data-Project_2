from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from sqlalchemy import create_engine

# Thêm connection info
POSTGRES_CONN = {
    'host': 'postgres',
    'database': 'airflow',
    'user': 'airflow',
    'password': 'airflow',
    'port': '5432'
}

def batch_layer_func(**context):
    try:
        # Tạo connection string
        conn_string = f"postgresql://{POSTGRES_CONN['user']}:{POSTGRES_CONN['password']}@{POSTGRES_CONN['host']}:{POSTGRES_CONN['port']}/{POSTGRES_CONN['database']}"
        engine = create_engine(conn_string)
        
        print("Starting batch_layer task")
        # Code xử lý của bạn ở đây
        
        print("Completed batch_layer task")
        
    except Exception as e:
        print(f"Error in batch_layer: {e}")
        raise

default_args = {
    'owner': 'airflow',
    'retries': 3,
    'retry_delay': timedelta(minutes=1)
}

with DAG(
    'daily_data_sync',
    default_args=default_args,
    schedule_interval='* * * * *',
    start_date=datetime(2024, 12, 15),
    catchup=False
) as dag:
    
    batch_layer = PythonOperator(
        task_id='batch_layer',
        python_callable=batch_layer_func,
        provide_context=True
    )