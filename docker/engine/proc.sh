#!/bin/bash

_load_module bash::strings

function __run_parallel() {
  eval tee $(__wrap_calls_in_pipes)
}

function _test_run() {
  local -i delay=${1:-$(shuf -e {1..10}| head -n 1)}
  echo "running test $$, sleeping for $delay"
  sleep $delay
  echo "running test $$, waking up"
}

function _parallel_test_run() {
  cat<<EOF |
_test_run 1
_test_run 2
_test_run 3
_test_run 
_test_run 
EOF
  __run_parallel
}
