#!/usr/bin/env bash

real_dirname() {
  pushd $(dirname $1) > /dev/null
    local SCRIPTPATH=$(pwd -P)
  popd > /dev/null
  echo $SCRIPTPATH
}
base_dir=$(real_dirname $0)

source "$base_dir/functions.sh"

set -x

sync_upstream_repository "$(declare -p factplusplus)"
bottle_formula "$(declare -p factplusplus)"

echo ""
echo "Done."
echo ""
echo "Remember to update the factplusplus.rb"
