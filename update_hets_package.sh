#!/bin/bash

real_dirname() {
  pushd $(dirname $1) > /dev/null
    local SCRIPTPATH=$(pwd -P)
  popd > /dev/null
  echo $SCRIPTPATH
}
base_dir=$(real_dirname $0)

source "$base_dir/functions.sh"

retrieve_hets_repository
bottle_all_formulas
update_all_formulas
commit_formula_changes

push_formula_changes
remove_hets_repository
