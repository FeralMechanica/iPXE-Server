#!/bin/bash

_load_module bash::proc

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

function _http_server() {
  local -r callback=$1
  local -A headers
  read method url proto
  while read header value; [ ! -z "${value// /}" ]; do
    header=${header//:/}
    value=$(echo "$value"| tr -d '\b\n\r')
    headers[$header]="$value"
  done
  eval "function _get_url() { echo $url; }; $callback"
}

_http_server
