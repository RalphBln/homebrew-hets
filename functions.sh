#!/usr/bin/env bash

real_dirname() {
  pushd $(dirname $1) > /dev/null
    local SCRIPTPATH=$(pwd -P)
  popd > /dev/null
  echo $SCRIPTPATH
}
base_dir=$(real_dirname $0)

hets_base_version="0.99"
dir="${base_dir}/build"

repo_local_dirname="git-repositories"

bottle_local_dirname="bottles"
bottle_local_dir="${dir}/${bottle_local_dirname}"
bottle_remote_destination_host="uni"
bottle_remote_destination_directory="/home/wwwuser/eugenk/homebrew-hets"
bottle_root_url="http://www.informatik.uni-bremen.de/~eugenk/homebrew-hets"

oses=('mavericks' 'yosemite' 'el_capitan')

formulas=('hets-server' 'hets' 'factplusplus')
hets_formulas=('hets-server' 'hets')

declare -A repo_remote_urls
repo_remote_urls[hets-server]='https://github.com/spechub/Hets.git'
repo_remote_urls[hets]='https://github.com/spechub/Hets.git'
repo_remote_urls[factplusplus]='https://bitbucket.org/dtsarkov/factplusplus.git'

declare -A refs
refs[hets-server]='origin/master'
refs[hets]='origin/master'
refs[factplusplus]="${FACT_REF-'origin/master'}"

declare -A versions
versions[hets-server]=false
versions[hets]=false
versions[factplusplus]="${FACT_VERSION:-1.6.4}"

declare -A use_cabal
use_cabal[hets-server]=true
use_cabal[hets]=true
use_cabal[factplusplus]=false

declare -A cabal_additional_flags
cabal_additional_flags[hets-server]='-f server -f -gtkglade -f -uniform'
cabal_additional_flags[hets]='-f -gtkglade'
cabal_additional_flags[factplusplus]=''

declare -A make_targets
make_targets[hets-server]='hets-server initialize_java'
make_targets[hets]='hets initialize_java'
make_targets[factplusplus]=''

repo_local_dir() {
  local formula="$1"
  echo "${dir}/${repo_local_dirname}/${formula}"
}

sync_formula_repositories() {
  for formula in "${formulas[@]}"
  do
    sync_formula_repository "$formula"
  done
}

sync_formula_repository() {
  local formula="$1"
  if [ ! -d "$(repo_local_dir "$formula")" ]
  then
    clone_formula_repository "$formula"
  else
    pull_formula_repository "$formula"
  fi
  checkout_ref "$formula"
}

clone_formula_repository() {
  local formula="$1"
  local repo_dir="$(repo_local_dir "$formula")"
  local parent_dir="$(dirname "$repo_dir")"
  if [ ! -d "$repo_dir" ]; then
    mkdir -p "$parent_dir"
    pushd "$parent_dir" > /dev/null
      git clone "${repo_remote_urls[$formula]}" "$repo_dir"
    popd > /dev/null
  fi
}

pull_formula_repository() {
  local formula="$1"
  local repo_dir="$(repo_local_dir "$formula")"
  pushd "$repo_dir" > /dev/null
    git fetch
  popd > /dev/null
}

checkout_ref() {
  local formula="$1"
  local repo_dir="$(repo_local_dir "$formula")"
  local ref="${refs[$formula]}"
  pushd "$repo_dir" > /dev/null
    git reset --hard $ref
  popd > /dev/null
}

version_commit() {
  local formula="$1"
  pushd $(repo_local_dir "$formula") > /dev/null
    echo $(git log -1 --format='%H')
  popd > /dev/null
}

version() {
  local formula="$1"
  if (array_contains hets_formulas $formula)
  then
    echo "${hets_base_version}-$(version_unix_timestamp "$formula")"
  else
    echo ${versions[$formula]}
  fi
}

version_unix_timestamp() {
  local formula="$1"
  pushd $(repo_local_dir "$formula") > /dev/null
    echo $(git log -1 --format='%ct')
  popd > /dev/null
}

bottle_subdir() {
  local formula="$1"
  echo "${bottle_local_dir}/${formula}"
}

bottle_all_formulas() {
  for formula in "${formulas[@]}"
  do
    bottle_formula $formula
  done
}

bottle_formula() {
  local formula="$1"
  local formula_file="${formula}.rb"

  bottle_formula_make $formula
  bottle_formula_copy_files_to_bottle_dir $formula
  bottle_formula_create_tarball $formula
  bottle_formula_upload_tarball $formula
}

bottle_formula_make() {
  local formula="$1"

  pushd $(repo_local_dir "$formula") > /dev/null
    if (${use_cabal[$formula]})
    then
      local ghc_prefix=`ghc --print-libdir | sed -e 's+/lib.*/.*++g'`
      cabal update
      cabal install --only-dependencies ${cabal_additional_flags[$formula]} --force-reinstalls -p --global --prefix="${ghc_prefix}"
    fi
    make ${make_targets[$formula]}
  popd > /dev/null
}

bottle_formula_copy_files_to_bottle_dir() {
  local formula="$1"
  local HOMEBREW_PREFIX="/usr/local"

  mkdir -p "$(bottle_subdir $formula)/"
  pushd $(bottle_subdir $formula) > /dev/null
    rm -rf *
    mkdir "$(version "$formula")"
    pushd "$(version "$formula")" > /dev/null
      if (array_contains hets_formulas $formula)
      then
        bottle_formula_copy_files_to_bottle_dir_hets $formula $HOMEBREW_PREFIX
      elif [ "$formula" = 'factplusplus' ]
      then
        bottle_formula_copy_files_to_bottle_dir_factplusplus $formula $HOMEBREW_PREFIX
      fi
    popd > /dev/null
  popd > /dev/null
}

bottle_formula_copy_files_to_bottle_dir_hets() {
  local formula="$1"
  local HOMEBREW_PREFIX="$2"
  echo "{\"used_options\":[],\"unused_options\":[],\"built_as_bottle\":true,\"poured_from_bottle\":false,\"time\":null,\"source_modified_time\":$(version_unix_timestamp "$formula"),\"HEAD\":null,\"stdlib\":null,\"compiler\":\"ghc\",\"source\":{\"path\":\"@@HOMEBREW_PREFIX@@/Library/Formula/$formula\",\"tap\":\"spechub/hets\",\"spec\":\"stable\"}}" > INSTALL_RECEIPT.json

  mkdir "bin"
  pushd "bin" > /dev/null
    echo "#!/bin/bash
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export HETS_LIB="\${HETS_LIB:-${HOMEBREW_PREFIX}/opt/hets-lib}"
export HETS_MAGIC="\${HETS_MAGIC:-${HOMEBREW_PREFIX}/opt/${formula}/lib/hets.magic}"
export HETS_OWL_TOOLS="\${HETS_OWL_TOOLS:-${HOMEBREW_PREFIX}/opt/${formula}/lib/hets-owl-tools}"
export HETS_APROVE="\${HETS_APROVE:-\$HETS_OWL_TOOLS/AProVE.jar}"
export HETS_ONTODMU="\${HETS_ONTODMU:-\$HETS_OWL_TOOLS/OntoDMU.jar}"
export HETS_JNI_LIBS="\${HETS_JNI_LIBS:-${HOMEBREW_PREFIX}/opt/factplusplus}"
export PELLET_PATH="\${PELLET_PATH:-${HOMEBREW_PREFIX}/opt/pellet}"
exec \"${HOMEBREW_PREFIX}/opt/${formula}/bin/${formula}-bin\" \"\$@\"" > $formula
    cp "$(repo_local_dir "$formula")/${formula}" "./${formula}-bin"
    chmod +x $formula
    chmod +x "${formula}-bin"
  popd > /dev/null

  mkdir "lib"
  pushd "lib" > /dev/null
    cp "$(repo_local_dir "$formula")/magic/hets.magic" "./${formula}.magic"

    mkdir "${formula}-owl-tools"
    pushd "${formula}-owl-tools" > /dev/null
      cp "$(repo_local_dir "$formula")/OWL2/OWL2Parser.jar" .
      cp "$(repo_local_dir "$formula")/OWL2/OWLLocality.jar" .
      cp "$(repo_local_dir "$formula")/DMU/OntoDMU.jar" .
      cp "$(repo_local_dir "$formula")/CASL/Termination/AProVE.jar" .

      mkdir "lib"
      pushd "lib" > /dev/null
        cp "$(repo_local_dir "$formula")/OWL2/lib/owlapi-osgidistribution-3.5.2.jar" .
        cp "$(repo_local_dir "$formula")/OWL2/lib/guava-18.0.jar" .
        cp "$(repo_local_dir "$formula")/OWL2/lib/trove4j-3.0.3.jar" .
      popd > /dev/null
    popd > /dev/null
  popd > /dev/null
}

bottle_formula_copy_files_to_bottle_dir_factplusplus() {
  local formula="$1"
  local HOMEBREW_PREFIX="$2"
  echo "{\"used_options\":[],\"unused_options\":[],\"built_as_bottle\":true,\"poured_from_bottle\":false,\"time\":null,\"source_modified_time\":$(version_unix_timestamp "$formula"),\"HEAD\":null,\"stdlib\":\"libstdcxx\",\"compiler\":\"clang\",\"source\":{\"path\":\"@@HOMEBREW_PREFIX@@/Library/Formula/$formula\",\"tap\":\"spechub/hets\",\"spec\":\"stable\"}}" > INSTALL_RECEIPT.json
  cp "$(repo_local_dir "$formula")/FaCT++.C/obj/libfact.jnilib" .
  cp "$(repo_local_dir "$formula")/FaCT++.JNI/obj/libFaCTPlusPlusJNI.jnilib" .
}

bottle_base_tarball() {
  local formula="$1"
  echo "${formula}-$(version "$formula").tar.gz"
}

bottle_base_tarball_absolute() {
  local formula="$1"
  echo "${bottle_local_dir}/$(bottle_base_tarball $formula)"
}

bottle_tarball() {
  local formula="$1"
  local os="$2"
  local release="${3:-1}"
  echo "${formula}-$(version "$formula").${os}.bottle.${release}.tar.gz"
}

bottle_formula_create_tarball() {
  local formula="$1"
  local base_tarball="$(bottle_base_tarball_absolute $formula)"

  pushd "$bottle_local_dir" > /dev/null
    tar czf "$base_tarball" $formula
  popd > /dev/null

  local shasum=$(shasum -a 256 "$base_tarball" | cut -d ' ' -f1)
  echo -n "$shasum" > "${base_tarball}.shasum"
}

bottle_shasum() {
  local formula="$1"
  cat "$(bottle_base_tarball_absolute $formula).shasum"
}

bottle_formula_upload_tarball() {
  local formula="$1"
  scp "$(bottle_base_tarball_absolute $formula)" "${bottle_remote_destination_host}:${bottle_remote_destination_directory}"
  pushd "$bottle_local_dir" > /dev/null
    for os in "${oses[@]}"
    do
      ssh "$bottle_remote_destination_host" ln -f -s "${bottle_remote_destination_directory}/$(bottle_base_tarball $formula)" "${bottle_remote_destination_directory}/$(bottle_tarball $formula $os)"
    done
  popd > /dev/null
}

update_all_formulas() {
  for formula in "${formulas[@]}"
  do
    update_formula $formula
  done
}

update_formula() {
  local formula="$1"
  local formula_file="${formula}.rb"

  if hash gsed 2>/dev/null
  then
    local sed=gsed
  else
    local sed=sed
  fi

  pushd $base_dir > /dev/null
    $sed -i "s/@@version_commit = '.*/@@version_commit = '$(version_commit "$formula")'/g" $formula_file
    $sed -i "s/@@version_unix_timestamp = '.*/@@version_unix_timestamp = '$(version_unix_timestamp "$formula")'/g" $formula_file
    $sed -i "s/sha256 '[^']*'/sha256 '$(bottle_shasum $formula)'/g" $formula_file
    git add $formula_file
    git commit -m "Update $formula to $(version "$formula")"
  popd > /dev/null
}

push_formula_changes() {
  pushd $base_dir > /dev/null
    git push
  popd > /dev/null
}

# The **name** of the array needs to be passed as first argument
# The search value needs to be passed as second argument
array_contains() {
  local array="$1[@]"
  local seeking=$2
  local in=1
  for element in "${!array}"
  do
    if [[ $element == $seeking ]]
    then
      in=0
      break
    fi
  done
  return $in
}
