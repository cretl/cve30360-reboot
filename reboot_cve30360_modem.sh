#!/bin/bash

## ----------------------------
## INFO
## --
## reboot_cve30360_modem.sh
## v230319
## desc: reboot Hitron Technologies CVE-30360 modem
## ----------------------------

## ----------------------------
## SETTINGS
## --------
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

modemIp="192.168.100.1" #192.168.100.1 for bridge mode

loginUsername="admin" #changeme
loginPassword="password" #changeme

dryRunScript=false #dry run the script to test it (no reboot, just logout as final action)
debugMode=false #display debug messages
debugMessageSyslogMode=false #log debug messages to syslog

workDir="/tmp/"

cookie1Name="cookie1.txt"
cookie2Name="cookie2.txt"

## ----------------------------
## STATIC VARIABLES
## --------
bashPath=$(command -v bash)
curlPath=$(command -v curl)
jqPath=$(command -v jq)
loggerPath=$(command -v logger)

cookie1Name="${workDir}${cookie1Name}"
cookie2Name="${workDir}${cookie2Name}"

## ----------------------------
## FUNCTIONS
## --------

checkDependencies() {
  declare -a scriptDependencies=("bash" "curl" "jq" "logger")

  for dependency in "${scriptDependencies[@]}"; do
    if [[ ! $(command -v ${dependency}) ]]; then
      echo "Depedency ${dependency} not found! The script won't work."
      echo "Please check/install the dependencies: ${scriptDependencies[@]}."
      echo "Exiting ..."
      exit 1
    fi
  done
}

debugMessage() {
  if [ "${debugMode}" = true ]; then
    echo "$1"
  fi

  if [ "${debugMessageSyslogMode}" = true ]; then
    syslogMessage "$1"
  fi
}

syslogMessage() {
  $loggerPath -t "$0" "$1"
}

exitOnError() {
  syslogMessage "$1"
  echo "ERROR:"
  echo "$1"
  echo "Exiting ..."
  exit 1
}

cleanup() {
#cleanup
  rm -rf ${cookie1Name}
  rm -rf ${cookie2Name}
}

getPreSessionId() {
#getPreSessionId -> sessionID
  $curlPath -s 'http://'"${modemIp}"'' -L -H 'Connection: keep-alive' -c $cookie1Name >/dev/null 2>&1
  sessionID=$(cat $cookie1Name | grep preSession | awk '{print $7}')
  debugMessage "#sessionID=${sessionID}"
}

login() {
#login
  curlLoginResponse=$($curlPath -s 'http://'"${modemIp}"'/goform/login' \
  -X POST \
  -H 'Accept: */*' -H 'Accept-Encoding: gzip, deflate' \
  -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  -H 'X-Requested-With: XMLHttpRequest' -H 'Origin: http://'"${modemIp}"'' \
  -H 'Connection: keep-alive' \
  -H 'Referer: http://'"${modemIp}"'/login.html' \
  -H 'Cookie: preSession='"${sessionID}"'' \
  --data-raw 'usernamehaha='"${loginUsername}"'&passwordhaha='"${loginPassword}"'&preSession='"${sessionID}"'' \
  -b ${cookie1Name} \
  -L \
  -c ${cookie2Name})
  
  if [ "${curlLoginResponse}" = "success" ]; then
    debugMessage "#Login successful"
  elif [ "${curlLoginResponse}" = "Repeat Login" ]; then
    debugMessage "#Login failed due to another user being logged in."
    exitOnError "Login failed - another user is logged in. Error code: \"${curlLoginResponse}\""
  else
     debugMessage "#Login failed. Error code: \"${curlLoginResponse}\""
    exitOnError "Login failed. Error code: \"${curlLoginResponse}\""
  fi
}

getUserId() {
#getUserId
  userID=$(cat ${cookie2Name} | grep userid | awk '{print $7}')
  debugMessage "#userID=${userID}"
}

getSessionId() {
#getSessionId
  sessionID=$(cat ${cookie2Name} | grep preSession | awk '{print $7}')
  debugMessage "#sessionID=${sessionID}"
}

getCsrfToken() {
#getCsrfToken
  csrfToken=$($curlPath -s 'http://'"${modemIp}"'/data/getCsrf.asp' \
  -H 'Accept: application/json, text/javascript, */*; q=0.01' \
  -H 'Accept-Language: en-US,en;q=0.5' \
  -H 'Accept-Encoding: gzip, deflate' \
  -H 'Referer: http://'"${modemIp}"'/index.html' \
  -H 'Connection: keep-alive' \
  -H 'Cookie: preSession='"${sessionID}"'; userid='"${userID}"'' \
  -H 'X-Requested-With: XMLHttpRequest' \
  -H 'Pragma: no-cache' \
  -H 'Cache-Control: no-cache' | $jqPath -r '.Csrf_token')
}

rebootModem() {
#rebootModem
  $curlPath 'http://'"${modemIp}"'/goform/Reboot' \
  -H 'Accept: application/json, text/javascript, */*; q=0.01' \
  -H 'Accept-Language: en-US,en;q=0.5' \
  -H 'Accept-Encoding: gzip, deflate' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'X-Requested-With: XMLHttpRequest' \
  -H 'Origin: http://'"${modemIp}"'' \
  -H 'Connection: keep-alive' \
  -H 'Referer: http://'"${modemIp}"'/index.html' \
  -H 'Cookie: preSession='"${sessionID}"'; userid='"${userID}"'' \
  --data-raw 'model=%7B%22reboot%22%3A%221%22%7D&CsrfToken='"${csrfToken}"'&CsrfTokenFlag=1'
}

logout() {
#logout
  curlLogoutResponse=$($curlPath -s 'http://'"${modemIp}"'/goform/logout' \
  -X POST \
  -H 'Accept: */*' \
  -H 'Accept-Language: en-US,en;q=0.5' \
  -H 'Accept-Encoding: gzip, deflate' \
  -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  -H 'X-Requested-With: XMLHttpRequest' \
  -H 'Origin: http://'"${modemIp}"'' \
  -H 'Connection: keep-alive' \
  -H 'Referer: http://'"${modemIp}"'/index.html' \
  -H 'Cookie: preSession='"${sessionID}"'; userid='"${userID}"'' \
  --data-raw 'data=byebye&CsrfToken='"${csrfToken}"'')
}

## ----------------------------
## SCRIPT
## --------
debugMessage "Script $0 started"
if [ "${dryRunScript}" = true ]; then
  echo " "
  echo "--"
  echo "DRY RUN MODE"
  echo "--"
  echo " "
fi

if [ "${dryRunScript}" = false ]; then
     echo "no dry run"
fi

debugMessage "#list vars"
debugMessage "#cookie1Name=${cookie1Name}"
debugMessage "#cookie2Name=${cookie2Name}"
debugMessage "#... done."

debugMessage "#checkDependencies"
checkDependencies
debugMessage "#... done."

#script
mkdir -p ${workDir}

debugMessage "#cleanup"
cleanup
debugMessage "#... done."
  
debugMessage "#getPreSessionId"
getPreSessionId
debugMessage "#... done."

debugMessage "#login"
login
debugMessage "... done."

debugMessage "#getUserId"
getUserId
debugMessage "... done."

debugMessage "#getSessionId"
getSessionId
debugMessage "... done."

debugMessage "#getCsrfToken"
getCsrfToken
debugMessage "... done."

if [ "${dryRunScript}" = true ]; then
  debugMessage "#logout"
  logout
  debugMessage "... done."
elif [ "${dryRunScript}" = false ]; then
  debugMessage "#rebootModem"
  rebootModem
  syslogMessage "modem ${modemIp} reboot requested."
  debugMessage "... done."
fi

debugMessage "#cleanup"
cleanup
debugMessage "#... done."

exit 0
