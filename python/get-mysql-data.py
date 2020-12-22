#!/usr/bin/env python

#import git
from collections import OrderedDict 
import glob
import json
import mysql.connector
from mysql.connector import errorcode
import os
from os import path
import re
import requests
import subprocess
import sys

# This script pulls information from MySQL Database and appends to an existing JSON file

# Get base path, set variable
base_path = path.dirname(__file__)

# Get all dynamic JSONs in environments dir
environment_dynamic_env_path = path.abspath(path.join(base_path, "environments/dynamic-*.json"))
all_environment_dynamic_env_paths = glob.glob(environment_dynamic_env_path)
print all_environment_dynamic_env_paths

#Prereq: Make sure to Install Python MySQL Connector
#python -m pip install mysql-connector-python 
#python3 -m pip install mysql-connector-python

# Initialize MySQL dictionary
mysql_dictionary = OrderedDict()

# Initiate connection to SystemPulse MySQL - Managed by John A. Creek <John.A.Creek@kp.org>
try:
  spdb = mysql.connector.connect(host="mysqldatabase.example.com",
                                user='readonly', 
                                password="",
                                database="summary")
except mysql.connector.Error as err:
  if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
    print("Database Connection: Access Denied")
  elif err.errno == errorcode.ER_BAD_DB_ERROR:
    print("Database Connection: Database does not exist")
  else:
    print(err)
else:
  print(spdb)
  spdb_cursor = spdb.cursor()

  # SQL command to create a table in the database 
  sql_command = """SELECT s.id as s_id,s.name as s_name, i.id as i_id, i.name as i_name, i.cache_ver, i.status as i_status"""

  print sql_command

  # Execute the sql statement 
  spdb_cursor.execute(sql_command)
  
  spdb_output = spdb_cursor.fetchall()
 
  print(spdb_output)

  for record in spdb_output:
    print(record)
    # Put example output here for reference
    map_db_to_var1 = record[1]
    map_db_to_var2 = record[3]
    map_db_to_var3 = record[4]
    map_db_to_var4 = record[5]
    map_db_to_var5 = record[7]
    map_db_to_var6 = record[8]
    map_db_to_var7 = record[9]

    # Initialize record's dictionary    
    record_dictionary = OrderedDict()

    # Add relevant values to dictionary
    record_dictionary.update({'map_db_to_var1': map_db_to_var1})
    record_dictionary.update({'map_db_to_var2': map_db_to_var2})
    record_dictionary.update({'map_db_to_var3': map_db_to_var3})
    record_dictionary.update({'map_db_to_var4': map_db_to_var4})
    record_dictionary.update({'map_db_to_var5': map_db_to_var5})
    record_dictionary.update({'map_db_to_var6': map_db_to_var6})
    record_dictionary.update({'map_db_to_var7': map_db_to_var7})

    # Nest dictionary into Systempulse dictionary
    mysql_dictionary.update({map_db_to_var1 : record_dictionary})

    print(map_db_to_var1)
  
  spdb.close()

print(mysql_dictionary)

# Look through all dynamic JSONs in environments
for path in all_environment_dynamic_env_paths:
  # Open each JSON
  with open(path) as f:
    dynamic_json = json.load(f)
    #DEBUG: print path
    # Initialize list to store Systempulse dictionaries
    key_list = []
    for special_env in dynamic_json['special_env_url_list']:
      for key in mysql_dictionary:
        # Determine if key in special_env_url_list matches what we have in the MySQL Dictionary
        if key == special_env:
          #DEBUG: print(key)
          #DEBUG: print(mysql_dictionary[key])
          key_list.append(mysql_dictionary[key])

    # Add MySQL dictionary list into special_env_info key
    dynamic_json.update({'special_env_info' : key_list})
    print(dynamic_json)
    with open(path, 'w+') as outfile:
      json.dump(dynamic_json, outfile)