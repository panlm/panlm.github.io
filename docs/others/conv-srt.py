#!/usr/bin/env python3

import json
import datetime
import sys
import re

filename = sys.argv[1]
try:
  #f = open(filename)
  with open(filename) as f:
    data = json.load(f)
except FileNotFoundError:
  print("File not accessible")
  sys.exit(9)

#print("length: {}".format(len(data["results"]["items"])))

start_time = ""
word = []
num = 1
for i in data["results"]["items"]:
  #print(i)
  try:
    if start_time == "":
      start_time = i["start_time"]
    end_time = i["end_time"]
    word.append(i["alternatives"][0]["content"].encode('utf-8'))
  except KeyError:
    word.append(i["alternatives"][0]["content"].encode('utf-8'))
    print("{}".format(num))
    start_time_string = str(datetime.timedelta(seconds=float(start_time)))[:-3]
    start_time_string = re.sub("\.",",",start_time_string)
    end_time_string = str(datetime.timedelta(seconds=float(end_time)))[:-3]
    end_time_string = re.sub("\.",",",end_time_string)
    print("0{} --> 0{}".format(start_time_string, end_time_string))
    print(b" ".join(word).decode('utf-8'))
    print("")
    start_time = ""
    word = []
    num = num + 1
    
