#!/bin/bash

_load_module bash::bs-httpd

function _serve_api() {
  local -n _url=$(_get_url)
  local segment
  read segment url<<<$(_pop_url)
  [ -z "$segment" ] && _error 400 "URL must start with api version."

  >&2 echo $segment
  local -n version=segment
  >&2 echo $version
  [ $version = $api_ver ] || _error 501 "Only supported api version is v1."
  while read segment url<<<$(_pop_url); [ ! -z "$segment" ]; do
    _load_module $api::${api_ver}_$segment
  done
}

_http_server _serve_api
