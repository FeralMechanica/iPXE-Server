#!/bin/bash

tee <(
echo x
echo y
) <(
echo m
}

function  _handle_call() {
  local method="$1"
  while shift; do declare -x "$1"; done

  while read line; do
    echo $line
  done
}
