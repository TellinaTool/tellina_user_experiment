#!/usr/bin/env python

import sys
import json

task_json_filepath = sys.argv[1]
task_num = sys.argv[2]

try:
    task_json = json.load(open(task_json_filepath))
    print('--------------------------')
    print('You are working on task ' + task_num)
    print(task_json['description'])
except (OSError, IOError):
    pass
