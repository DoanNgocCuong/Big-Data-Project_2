import happybase

def decode_dict(d):
    return {k.decode('utf-8').split(':', 1)[1]: v.decode('utf-8') for k, v in d.items()}

def get_last_record_from_hbase():
    # Establish a connection to HBase
    # connection = happybase.Connection('localhost')  # Assuming HBase is running locally
    connection = happybase.Connection('hbase')  # Assuming HBase is running locally
    connection.open()
# PS D:\OneDrive - Hanoi University of Science and Technology\GIT\BigData-Project\Big-Data-Project_2\Main\Lambda> docker network ls
# NETWORK ID     NAME                    DRIVER    SCOPE
# bc2bf2a7361c   batch_layer_default     bridge    local
# 85613aaea658   bridge                  bridge    local
# 30149d731c72   host                    host      local
# e26a4cf556ce   lambda_stream-network   bridge    local
# dd052fff3f84   none                    null      local
# 28fd717c4091   src_default             bridge    local

    # Open the 'smartphone' table
    table = connection.table('smartphone')

    # Initialize the scanner
    scanner = table.scan(limit=1, reverse=True)

    # Get the last record
    last_record = {}
    try:
        for key, data in scanner:
            last_record = decode_dict(data)
            break  # Exit the loop after fetching the first (last) record
    finally:
        # Close the scanner
        scanner.close()

    # Close the connection
    connection.close()

    return last_record


