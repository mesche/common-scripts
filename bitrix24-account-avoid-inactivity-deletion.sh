#!/bin/bash

#===================================================================
# Use this script to avoid deletion of the account due to inactivity.
# It creates a directory with a random name on Bitrix24.Drive and deletes it immediately.
#
# VERSION: 01.02.00
#
# BACKGROUND:
# If an instance of Bitrix24 on a free plan (either converted to a free plan or originally on a free plan) is completely inactive over the course of 30 days, 
# it is 'archived', and it can be retrieved only by an administrator account (yourself or a user in the instance with administrator rights). 
# To retrieve the account, an administrator simply needs to log in. If no administrator logs in for another 15 days after the instance has been 'archived', 
# the Bitrix24 instance will be deleted. Please note – this does not affect Bitrix24 paid plans subscribers.
#
# REQUIREMENTS:
# curl / base64 / uuidgen
#
# RUN:
# chmod +x ./bitrix24-account-avoid-inactivity-deletion.sh
# ./bitrix24-account-avoid-inactivity-deletion.sh
#
#
#    ::::::::::::::: www.blogging-it.com :::::::::::::::
#    
# Copyright (C) 2020 Markus Eschenbach. All rights reserved.
# 
# 
# This software is provided on an "as-is" basis, without any express or implied warranty.
# In no event shall the author be held liable for any damages arising from the
# use of this software.
# 
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter and redistribute it,
# provided that the following conditions are met:
# 
# 1. All redistributions of source code files must retain all copyright
#    notices that are currently in place, and this list of conditions without
#    modification.
# 
# 2. All redistributions in binary form must retain all occurrences of the
#    above copyright notice and web site addresses that are currently in
#    place (for example, in the About boxes).
# 
# 3. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software to
#    distribute a product, an acknowledgment in the product documentation
#    would be appreciated but is not required.
# 
# 4. Modified versions in source or binary form must be plainly marked as
#    such, and must not be misrepresented as being the original software.
#    
#    ::::::::::::::: www.blogging-it.com :::::::::::::::
#
#===================================================================


#===================================================================
# SETTINGS
#===================================================================
users='somebody@example.com;somebody2@example.com'   # Bitrix24 account - user/email with administrator rights - separated by semicolon (s1@ex.com;s2@ex.com;.....)
passwords='1234567;987654' # Bitrix24 account - password - separated by semicolon (1234567;987654;.....)
accounts='b24-1xxxxx;b24-2xxxxx' # default names or custom bitrix24 - separated by semicolon (b24-xxxxxx;b24-xxxxxx;.....)
domain='bitrix24.de' # domain with zone
dirName="tmp_webdav-check-$(uuidgen)" # name of the directory


#===================================================================
# PREPARE
#===================================================================
exitCode=0 # the default exit code, if no error occurs
#basicAuth=$(echo -ne "${user}:${password}" | base64) # convert auth string to base64 string
declare -a accountsArr= # define variable
declare -a usersArr= # define variable
declare -a passwordsArr= # define variable
IFS=';' read -ra accountsArr <<< "${accounts}" # parse string to array
IFS=';' read -ra usersArr <<< "${users}" # parse string to array
IFS=';' read -ra passwordsArr <<< "${passwords}" # parse string to array


#===================================================================
# EXECUTE CURL
#===================================================================
function execCurl() {
  echo "Run request: ${1} - ${2}"
  local statusCode=$(curl -k --write-out '%{http_code}' --silent --output /dev/null --header "Authorization: Basic ${3}" -X "${1}" "${2}")
  echo "Response - Status-Code: ${statusCode}"
  if [[ "${statusCode}" -ne "${4}" ]] ; then
     echo "ERROR: Wrong Status-Code - Expected: ${4}"
     exitCode=1
  fi
}

function processBitrix() {
  local idx=${1}
  local account=${accountsArr[idx]}
  local user=${usersArr[idx]}
  local pass=${passwordsArr[idx]}

  if [[ "${idx}" -ge "${#usersArr[@]}" ]] ; then
     user=${usersArr[0]}
  fi

  if [[ "${idx}" -ge "${#passwordsArr[@]}" ]] ; then
    pass=${passwordsArr[0]}
  fi

  local basicAuth=$(echo -ne "${user}:${pass}" | base64) # convert auth string to base64 string
  local webDavURL="https://${account}.${domain}/company/personal/user/1/disk/path/${dirName}"

  echo "Process Bitrix24 - ${idx} - ${account} - ${user}"

  echo "Step 1/2: create folder - ${dirName}"
  execCurl "MKCOL" "${webDavURL}" "${basicAuth}" 201

  echo "Step 2/2: delete folder - ${dirName}"
  execCurl "DELETE" "${webDavURL}" "${basicAuth}" 204
}


#===================================================================
# MAIN
#===================================================================
for i in "${!accountsArr[@]}"; do
    processBitrix "${i}"
done

exit ${exitCode}
