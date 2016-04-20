#!/usr/bin/env bash

real_dirname() {
  pushd $(dirname $1) > /dev/null
    local SCRIPTPATH=$(pwd -P)
  popd > /dev/null
  echo $SCRIPTPATH
}
base_dir=$(real_dirname $0)

source "$base_dir/functions.sh"

# overwrite formulas array - only these are going to be updated.
formulas=('factplusplus')

sync_formula_repositories
bottle_all_formulas
update_all_formulas
push_formula_changes
