#!/usr/bin/env bash

# Checks for version of application with a fallback way to get version, output to JSON

app_check="/path/to/application/version/"

script_name=$(basename $0 | cut -f 1 -d '.')
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if ! [[ $(whoami) =~ ^(root|otheruser)$ ]]; then
  printf '{"%s":"Error: Please run this script as root or otheruser"}' "$script_name"
  exit
fi

if [ -d ${app_check} ]; then
  cd ${app_check}
  app_version=$(sed -ne '/<version>/s#\s*<[^>]*>\s*##gp' AppName.product)
  printf '{'
  printf '"%s":"%s",' "${script_name}" "${app_version}"
  printf '"%s_server_tag":"%s",' "${script_name}" "AppName"
  printf '"%s_server_tag_verbose":"%s"' "${script_name}" "AppName Verbose"
  printf '}'
elif [ -d "/path/to/application/bin" ]; then
  cd /path/to/application/bin
  app_version=$(./version_info.sh | awk '/AppName and Version/{getline; print$2}')
  printf '{'
  printf '"%s":"%s",' "${script_name}" "${app_version}"
  printf '"%s_server_tag":"%s",' "${script_name}" "AppName"
  printf '"%s_server_tag_verbose":"%s"' "${script_name}" "AppName Verbose"
  printf '}'

else
  printf '{"%s":"Error: %s and /path/to/application/bin does NOT exist"}' "$script_name" "${app_check}"
fi
