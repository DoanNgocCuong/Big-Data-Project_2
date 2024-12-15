from datetime import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator

# Định nghĩa hàm batch_layer trực tiếp trong file DAG
def batch_layer():
    try:
        # Import các module cần thiết
        from batch_layer import spark_tranform
        from save_data_postgresql import save_data
        
        # Thực hiện xử lý
        data = spark_tranform()
        save_data(data)
        return "Batch processing completed successfully"
    except Exception as e:
        print(f"Error in batch_layer: {e}")
        raise e

# DAG configuration
default_args = {
    'owner': 'airflow',
    'start_date': datetime(2024, 3, 29)
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