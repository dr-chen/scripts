#!/usr/bin/env bash

# Detect certificates with nmap, determine time until expiry with openssl, print into JSON alert message if conditions are met. Ingest output and fire alerts/notifications if necessary

script_name=$(basename $0 | cut -f 1 -d '.')
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if ! [ $(command -v nmap) ] ; then
  echo "nmap does not exist, attempting install"
  sudo yum install nmap -y
  if ! [ $(command -v nmap) ] ; then
    echo "Attempted installing nmap, still does not exist, please manually review"
    exit 1
  fi
fi

printf '{'

nmap --script ssl-cert localhost | grep '[0-9]/' | awk '{ print $1 " " $3}' | sed -E -e 's/\/tcp|\/udp//g' | while read line; do

  nmap_port_number=$(echo ${line} | cut -d " " -f 1)
  nmap_port_description=$(echo ${line} | cut -d " " -f 2)

  if $(openssl s_client -showcerts -servername localhost -connect localhost:${nmap_port_number} > /dev/null 2>&1); then
    nmap_cert_date=$(openssl s_client -showcerts -servername localhost -connect localhost:${nmap_port_number} 2>/dev/null | openssl x509 -inform pem -noout -enddate | cut -d "=" -f 2 | cut -f1,2,3 -d' ')
    nmap_cert_date_unix_timestamp=$(date --date="$nmap_cert_date" +"%s")
    #nmap_cert_date_unix_timestamp=$(date --date="Jul 23 21:30:51" +"%s")
    current_date_unix_timestamp=$(date +%s)
    time_difference_unix_timestamp=$(($nmap_cert_date_unix_timestamp-$current_date_unix_timestamp))
    days_remaining=$(($time_difference_unix_timestamp/86400))

    printf '"%s_%s_service_port_number":"%s",' "${script_name}" "${nmap_port_description}" "${nmap_port_number}"
    printf '"%s_%s_service_cert_expire_date":"%s",' "${script_name}" "${nmap_port_description}" "${nmap_cert_date}"
    printf '"%s_%s_service_cert_days_remaining":"%s",' "${script_name}" "${nmap_port_description}" "${days_remaining}"

    if [ "$days_remaining" -le 90 ]; then
      if [ "$days_remaining" -le 30 ]; then
        printf '"%s_%s_status": [' "$script_name" "${nmap_port_description}"
        printf "Fatal" "2" "Fatal: Detected expiring ${nmap_port_description} certificate on port number: ${nmap_port_number}. ${days_remaining} day(s) remaining on certificate." "false"
        printf '],'
      else
        printf '"%s_status": [' "$script_name"
        printf "Warn" "1" "Warn: Detected expiring ${nmap_port_description} certificate on port number: ${nmap_port_number}. ${days_remaining} day(s) remaining on certificate." "false"
        printf '],'
      fi
    fi
  fi
done

printf '"%s_hostname":"%s"' "${script_name}" "$(hostname)"

printf '}'
