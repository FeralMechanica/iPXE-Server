#!/bin/bash

function _repeat() {
  printf "%0.s$1" $(seq 1 $2)
}

function _prepend() {
  sed "s/^/$1/g"
}

function _append() {
  sed "s/$/$1/g"
}

function _indent_spaces() {
  local num="$1:-4"
  _prepend $(_repeat ' ' $num)
}

function _vars_to_yaml() {
  local var arg
  for var in $*; do
    IFS== read -r var arg<<<$var
    arg="${arg:-$(eval echo \$$var)}"
    [ ! -z "$arg" ] && echo "$var: $arg"
  done
}

function __wrap_calls_in_pipes() {
  local -r flush_stdin='; cat'
  while read call; do
    [ "${call:2}" != __ ] && call+="$flush_stdin"
    echo -e ">( $call ) "
  done
}
