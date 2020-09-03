#!/usr/bin/env bash
# Simple port check listen / connect. Ports and port types are hardcoded as an example, script can be easily adapted to accept arguments by setting variables $1, $2 etc. 

function check_port_listen {
  netstat -an | grep "$1" | grep LISTEN > /dev/null ;
  if [ $? -eq 0 ]
  then
    echo "Port $1 is listening"
  else
    echo "Port $1 is not listening"
  fi
}

function check_port_connect {
  timeout 3 bash -c "cat < /dev/null > /dev/tcp/$running_server/$1" 2> /dev/null
  if [ $? -eq 0 ]
  then
    echo "Connection to Port $1 successful"
  else
    echo "Connection to Port $1 is not successful"
  fi
}

running_server=$(hostname)
port_array=(12345 23456 34567)
port_type_array=(Application1 Application2 Application3)

echo TABLE CheckWebServerPort

n=${#port_array[@]}
  for ((i=0;i<$n;i++));
  do
    echo START_SAMPLE_PERIOD
    echo PortNumber.String.id="${port_array[$i]}"
    echo PortType.StringObservation.obs=$( echo ${port_type_array[$i]} )
    echo CheckPortListen.StringObservation.obs=$( check_port_listen ${port_array[$i]} )
    echo CheckPortConnect.StringObservation.obs=$( check_port_connect ${port_array[$i]} )
    echo END_SAMPLE_PERIOD
  done

echo END_TABLE