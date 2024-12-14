import csv
import random


import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from producer import send_message

def generate_real_time_data(file_path):
    with open(file_path, 'r') as csv_file:
        csv_reader = csv.reader(csv_file)
        data = list(csv_reader)


        random_index = random.randint(1, len(data) - 1)
        random_data = data[random_index]

        return random_data








