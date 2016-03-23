#!/bin/bash

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
repo_remote_url="https://github.com/spechub/Hets.git"

bottle_local_dirname="bottles"
bottle_local_dir="${dir}/${bottle_local_dirname}"
bottle_remote_destination_host="uni"
bottle_remote_destination_directory="/home/wwwuser/eugenk/homebrew-hets"
bottle_root_url="http://www.informatik.uni-bremen.de/~eugenk/homebrew-hets"

formulas=('hets-server' 'hets')
oses=('mavericks' 'yosemite' 'el_capitan')

repo_local_dir() {
  local formula="$1"
  echo "${dir}/${repo_local_dirname}/${formula}"
}

sync_hets_repositories() {
  for formula in "${formulas[@]}"
  do
    sync_hets_repository "$formula"
  done
}

sync_hets_repository() {
  local formula="$1"
  if [ ! -d "$(repo_local_dir "$formula")" ]
  then
    clone_hets_repository "$formula"
  else
    pull_hets_repository "$formula"
  fi
}

clone_hets_repository() {
  local formula="$1"
  local repo_dir="$(repo_local_dir "$formula")"
  local parent_dir="$(dirname "$repo_dir")"
  if [ ! -d "$repo_dir" ]; then
    mkdir -p "$parent_dir"
    pushd "$parent_dir" > /dev/null
      git clone "$repo_remote_url" "$repo_dir"
    popd > /dev/null
  fi
}

pull_hets_repository() {
  local formula="$1"
  local repo_dir="$(repo_local_dir "$formula")"
  pushd "$repo_dir" > /dev/null
    git fetch
    git reset --hard origin/master
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
  echo "${hets_base_version}-$(version_unix_timestamp "$formula")"
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

  local ghc_prefix=`ghc --print-libdir | sed -e 's+/lib.*/.*++g'`

  bottle_formula_make $formula
  bottle_formula_copy_files_to_bottle_dir $formula
  bottle_formula_create_tarball $formula
  bottle_formula_upload_tarball $formula
}

bottle_formula_make() {
  local formula="$1"

  pushd $(repo_local_dir "$formula") > /dev/null
    cabal update
    if [ "$formula" = "hets" ]
    then
      cabal install --only-dependencies -f -gtkglade --force-reinstalls -p --global --prefix="${ghc_prefix}"
    else
      cabal install --only-dependencies -f server -f -gtkglade -f -uniform --force-reinstalls -p --global --prefix="${ghc_prefix}"
    fi
    make $formula
    make initialize_java
  popd > /dev/null
}

bottle_formula_copy_files_to_bottle_dir() {
  local formula="$1"

  mkdir -p "$(bottle_subdir $formula)/"

  pushd $(bottle_subdir $formula) > /dev/null
    rm -rf *
    mkdir "$(version "$formula")"

    pushd "$(version "$formula")" > /dev/null
      echo "{\"used_options\":[],\"unused_options\":[],\"built_as_bottle\":true,\"poured_from_bottle\":false,\"time\":null,\"source_modified_time\":$(version_unix_timestamp "$formula"),\"HEAD\":null,\"stdlib\":null,\"compiler\":\"ghc\",\"source\":{\"path\":\"@@HOMEBREW_PREFIX@@/Library/Formula/$formula\",\"tap\":\"spechub/hets\",\"spec\":\"stable\"}}" > INSTALL_RECEIPT.json

      mkdir "bin"
      pushd "bin" > /dev/null
        local HOMEBREW_PREFIX="/usr/local"
        echo "#!/bin/bash
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export HETS_LIB="\${HETS_LIB:-${HOMEBREW_PREFIX}/opt/hets-lib}"
export HETS_MAGIC="\${HETS_MAGIC:-${HOMEBREW_PREFIX}/opt/${formula}/lib/hets.magic}"
export HETS_OWL_TOOLS="\${HETS_OWL_TOOLS:-${HOMEBREW_PREFIX}/opt/${formula}/lib/hets-owl-tools}"
export HETS_APROVE="\${HETS_APROVE:-\$HETS_OWL_TOOLS/AProVE.jar}"
export HETS_ONTODMU="\${HETS_ONTODMU:-\$HETS_OWL_TOOLS/OntoDMU.jar}"
export PELLET_PATH="\${PELLET_PATH:-${HOMEBREW_PREFIX}/opt/pellet/bin}"
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
    popd > /dev/null
  popd > /dev/null
}

bottle_base_tarball() {
  local formula="$1"
  echo "${formula}-0.99-$(version_unix_timestamp "$formula").tar.gz"
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
  popd > /dev/null
}

commit_formula_changes() {
  local formula="$formulas[1]"
  pushd $base_dir > /dev/null
    git commit -m "Update hets formulas to $(version_unix_timestamp "$formula")"
  popd > /dev/null
}

push_formula_changes() {
  pushd $base_dir > /dev/null
    git push
  popd > /dev/null
}
