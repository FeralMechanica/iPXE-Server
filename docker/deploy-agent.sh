#!/bin/bash

declare -gr api=/srv/api
declare -gr api_ver=v1

#tee <(
#echo x
#echo y
#) <(
#echo m
#}

function  _handle_call() {
  local method="$1"
  #while shift; do declare -x "$1"; done

  echo args: $*
  while read line; do
    echo $line
  done
}

function _pop_url() {
  echo $url| sed -e 's/\b\// \//' -e 's/^\///'
}

function _http_error_desc() {
  local -i error=$1
  grep $error /srv/http_codes
}

function _http_send_data() {
  local data="$1"
  echo "$data"
}

function _http_send_headers() {
  local -i lenght=$1
  cat<<EOF
Date: $(date)
Content-Length: $length
Content-Type: text/plain; charset=UTF-8
Via: 1.1 $(hostname -f) (Shellzilla v.1.1)
Connection: close

EOF
}

function _http_response() {
  local -i error=$1
  local message="$2"
  local -i length=${#message}
  echo "HTTP/1.1 $error $(_http_error_desc $error)"
  _http_send_headers $length
  _http_send_data "$message"
}

function _error() {
  local -i code="${1:-500}" exit_code; shift
  let exit_code=$code-300  # fit into 256, everything under 300 is not error anyway.
  _http_response $code "$*"
  exit $exit_code
}

function _serve_api() {
  local -n _url=url
  local segment
  read segment url<<<$(_pop_url)
  [ -z "$segment" ] && _error 400 "URL must start with api version."

  >&2 echo $segment
  local -n version=segment
  >&2 echo $version
  [ $version = $api_ver ] || _error 501 "Only supported api version is v1."
  while read segment url<<<$(_pop_url); [ ! -z "$segment" ]; do
    source $api/$api_ver/$segment.sh
  done
}

function _http_server() {
  local -A headers
  read method url proto
  echo method: $method, url: $url, proto: $proto
  while read header value; [ ! -z "${value// /}" ]; do
    header=${header//:/}
    value=$(echo "$value"| tr -d '\b\n\r')
    headers[$header]="$value"
  done
  _serve_api
}

_http_server
#_handle_call "$*"
