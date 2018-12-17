#!/bin/bash

typeset _src_dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd| sed -rne 's~^(.*/webstorage).*$~\1~p')
typeset _lib_dir=$_src_dir/lib/deploy
typeset -gA _loaded_modules=([main]=true)

function _safe_source() {
  local module="$1"
  local filename=$(_module_filename "$module")
  source <( echo 'set -en'; cat "$filename"; echo 'set +en'; ) || >&2 echo "module $module failes precheck"
  source $filename
}

function _module_filename() {
  echo "$_lib_dir/${1//::/\/}.sh"
}

function _load_module() {
  local module="$1"
  local -n lm=_loaded_modules
  lm[$module]=requested
  local filename=$(_module_filename "$module")

  # TODO: timestamp mtime
  if [ -z "$module" ]; then
    >&2 echo "empty module: \"$module\""
    false
  elif [ ! -r "$filename" ]; then
    >&2 echo "failed to load module: \"$module\", can't open file \"$filename\"."
    false
  elif [ "${lm[$module]}" = loaded ]; then
    true
  else
    lm[$module]=loading
    _safe_source "$filename"
    lm[$module]=exporting
    _export_module_functions $module
    lm[$module]=loaded
    true
  fi || return $?
  typeset -F| cut -d' ' -f3-
}

function _export_module_functions() {
  
}
