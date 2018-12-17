#!/bin/bash

typeset -r __bash_env_orig=$(set +o)
alias __bash_env_restore='eval $__bash_env_orig'

set -eu
trap __bash_env_restore EXIT
