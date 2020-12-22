#!/usr/bin/env python3
import bs4
import configparser
import datetime
import json
import os
import pathlib
import re
import requests
import sys
import yaml

#Use beautifulsoup4 to parse Confluence page, grab table, organize/preprocess data and output to JSON for automation purposes
#This is a hardcoded version specific for a particular Confluence page, if Confluence pages are very similar, we can parameterize the URL value by accepting script arguments

#Prereqs:
# pip3 install configparser
# pip3 install PyYAML
# pip3 install beautifulsoup4
# pip3 install urllib3

def get_config(config,section,key):
    try:
        value = config.get(section,key)
    except NoSectionError as e:
        print("%s: Please review README to create a %s section" % (e, section))
        sys.exit(1)
    except NoOptionError as e:
        print("%s: Please review README to create a %s key" % (e, key))
        sys.exit(1)
    return value

def config_parser(cfile):
    config = configparser.ConfigParser()
    try:
        with open(cfile) as f: # catch IOError, file not exist
            print(cfile)
            config.read(cfile)
    except IOError as e:
        if "credentials" in str(e):
            print(cfile)
            print("Please first create credentials file per README")
            sys.exit(1)
        sys.exit(e)
    return config

def filter_environments(confluence_headers):
    for idx, item in enumerate(confluence_headers):
        if re.findall('[A-Z][A-Z].*(?=</th>)', str(item)):
            discovered_hosts = re.findall('[A-Z][A-Z].*(?=</th>)', str(item))
            match = re.match(".*AppName.*", str(discovered_hosts))
            if match:
                continue
            else:
                print(discovered_hosts)
                environment_list.append(discovered_hosts)

def filter_hosts(confluence_rows):
    target_cell = int(5)
    for idx, item in enumerate(confluence_rows):
        if (idx+1) % target_cell == 0:
            re.findall('>x.*\.example.com', str(item))
            discovered_hosts = re.findall('>x.*\.example.com', str(item))
            if discovered_hosts:
                clean_all_hosts = ((discovered_hosts[0][1:]).replace('<br/>', ',').replace('</p><p>', ','))
                print(clean_all_hosts)
                hosts_list.append(clean_all_hosts)
            else:
                print(discovered_hosts)
                hosts_list.append(discovered_hosts)
            target_cell = target_cell + int(8)

def write_to_json_file(dictionary, output_name):
    # Once all data has been collected, output based on environment name
    export_file_name = output_name + ".json"
    export_file_path = sys.path[0] + "/output/" + export_file_name
    print(export_file_path)

    # Create output directory if not exist
    (pathlib.Path(__file__).parent.absolute() / "output").mkdir(parents=True, exist_ok=True)

    # Write file
    with open(export_file_path, 'w+') as outfile:
        json.dump(dictionary, outfile) 
        print("Created " + export_file_path)

def get_page_content(confluence_auth, content_url):
    response = requests.get(content_url + '?expand=body.storage,version', headers=HEADERS, auth=confluence_auth)
    if response.status_code != 200:
        print ("HTTP Status: " + str(response.status_code))
        print ("Cannot get Confluence Page.")
        exit(9)
    print(response.text)
    bs_html = bs4.BeautifulSoup(response.text, "html.parser")
    
    confluence_headers = bs_html.select('.confluenceTh')

    confluence_rows = bs_html.select('.confluenceTd')

    filter_environments(confluence_headers)

    filter_hosts(confluence_rows)

environment_list = []
hosts_list = []

confluence_env_list = []
confluence_hosts_list = []

confluence_api_env_list = []
confluence_api_hosts_list = []

# The split between 1st table and 2nd table

# Constants
HEADERS = { 'Accept' : 'application/json',
            'Content-Type' : 'application/json'}

# Set path to this directory
basepath = os.path.dirname(os.path.realpath(__file__))

creds = config_parser(basepath+'/creds/credentials')
confluence_auth = (get_config(creds,'confluence','user'), get_config(creds,'confluence','password'))

target_confluence_url = "https://confluenceexample.com/path/to/confluence/page"

get_page_content(confluence_auth, target_confluence_url)


# Input the last row's environment of the first table to choose location to split
splitting_env = 'Environment'
splitting_env_index = environment_list.index([splitting_env])+1

confluence_env_hosts = {}
confluence_api_env_hosts = {}

for index_env, (env, hosts) in enumerate(zip(environment_list, hosts_list), start=1):
    #print(index_env, env, hosts)
    print(env)
    print(hosts)
    env_name = str(env[0])
    if index_env > splitting_env_index:        
        confluence_api_env_hosts.update({env_name: hosts})
        print("API {}: {} {}".format(index_env, env, hosts))
    else:
        confluence_env_hosts.update({env_name: hosts})
        print("{}: {} {}".format(index_env, env, hosts))

print(confluence_env_hosts)
print(confluence_api_env_hosts)

confluence_env_hosts.update({'json_description_tag':'AppName1'}) 
confluence_env_hosts.update({'refresh_time': datetime.datetime.now().strftime("%c")}) 
confluence_api_env_hosts.update({'json_description_tag':'AppName2'}) 
confluence_api_env_hosts.update({'refresh_time': datetime.datetime.now().strftime("%c")}) 

write_to_json_file(confluence_env_hosts, "confluence_env_and_hosts")
write_to_json_file(confluence_api_env_hosts, "confluence_api_env_and_hosts")