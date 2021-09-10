#!/bin/bash
## installer/files/recuse_listable_permission.sh
## Set every dir in the current path as listable

# Use given path if one is passed as the argument.
if [[ -z ${1} ]]; then
  cd -v "${1}"
fi

## Set dir listable by all until we reach the root dir
while [ "$PWD" != "/" ];
  chmod -v a+X $PWD
  cd ..