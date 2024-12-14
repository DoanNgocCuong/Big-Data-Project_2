from flask import Flask, render_template
from get_Data_from_hbase import get_last_record_from_hbase
import logging
from datetime import datetime

# Cấu hình logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('flask_app.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

@app.route('/')
def index():
    try:
        # Log thời điểm bắt đầu request
        logger.debug(f"New request received at {datetime.now()}")
        
        # Log trước khi gọi HBase
        logger.debug("Attempting to fetch data from HBase...")
        
        last_record = get_last_record_from_hbase()
        
        # Log kết quả từ HBase
        logger.debug(f"Data received from HBase: {last_record}")
        
        # Log trước khi render template
        logger.debug("Rendering template with data...")
        
        return render_template('index.html', last_record=last_record)
        
    except Exception as e:
        # Log lỗi nếu có
        logger.error(f"Error occurred: {str(e)}", exc_info=True)
        return f"An error occurred: {str(e)}", 500

@app.before_request
def before_request():
    # Log thông tin request
    logger.debug("Request Headers: %s", request.headers)
    logger.debug("Request Method: %s", request.method)
    logger.debug("Request URL: %s", request.url)

@app.after_request
def after_request(response):
    # Log thông tin response
    logger.debug("Response Status: %s", response.status)
    logger.debug("Response Headers: %s", response.headers)
    return response

@app.errorhandler(404)
def not_found_error(error):
    logger.error(f"Page not found: {request.url}")
    return render_template('404.html'), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error("Internal server error: %s", error, exc_info=True)
    return render_template('500.html'), 500

if __name__ == '__main__':
    # Log khi server khởi động
    logger.info("Flask server starting...")
    
    try:
        # Test kết nối HBase
        logger.debug("Testing HBase connection...")
        test_record = get_last_record_from_hbase()
        logger.info("HBase connection successful")
    except Exception as e:
        logger.error("Failed to connect to HBase", exc_info=True)
    
    # Hiển thị thông tin cấu hình
    logger.info(f"Debug mode: {app.debug}")
    logger.info(f"Template folder: {app.template_folder}")
    logger.info(f"Static folder: {app.static_folder}")
    
    app.run(debug=True, host='0.0.0.0', port=5000)