#!/usr/bin/env bash

real_dirname() {
  pushd $(dirname $1) > /dev/null
    local SCRIPTPATH=$(pwd -P)
  popd > /dev/null
  echo $SCRIPTPATH
}
base_dir=$(real_dirname $0)

source "$base_dir/functions.sh"

debug_level=""

sync_upstream_repository "$(declare -p hets_desktop)"
bottle_formula "$(declare -p hets_desktop)"
patch_formula "$(declare -p hets_desktop)"
# commit_formula "$(declare -p hets_desktop)"

sync_upstream_repository "$(declare -p hets_server)"
bottle_formula "$(declare -p hets_server)"
patch_formula "$(declare -p hets_server)"
# commit_formula "$(declare -p hets_server)"

sync_upstream_repository "$(declare -p hets_commons)"
bottle_formula "$(declare -p hets_commons)"
patch_formula "$(declare -p hets_commons)"
# commit_formula "$(declare -p hets_commons)"
