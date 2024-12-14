from pathlib import Path
import time
import threading

# Thêm parent directory (Lambda) vào path
import sys
LAMBDA_DIR = Path(__file__).parent.parent
sys.path.append(str(LAMBDA_DIR))

# Import các module
try:
    from producer import send_message
    from Stream_data.stream_data import generate_real_time_data
    from Stream_layer.ML_consumer import consum
except ImportError as e:
    print(f"Import error: {e}")
    print(f"Lambda directory: {LAMBDA_DIR}")
    print(f"Python path: {sys.path}")
    sys.exit(1)

def producer_thread():
    while True:
        try:
            # Sử dụng Path để xử lý đường dẫn file
            file_path = LAMBDA_DIR / 'Stream_data' / 'stream_data.csv'
            message = generate_real_time_data(str(file_path))
            
            send_message(message)
            print("Message sent to Kafka topic")
            time.sleep(5)
            
        except Exception as e:
            print(f"Error in producer_thread: {str(e)}")

def consumer_thread():
    while True:
        try:
            consum()
            time.sleep(3)
        except Exception as e:
            print(f"Error in consumer_thread: {str(e)}")

if __name__ == "__main__":
    producer_thread = threading.Thread(target=producer_thread)
    consumer_thread = threading.Thread(target=consumer_thread)

    producer_thread.start() 
    consumer_thread.start()

    producer_thread.join()
    consumer_thread.join()
