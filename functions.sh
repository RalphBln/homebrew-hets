#!/usr/bin/env bash

real_dirname() {
  pushd $(dirname $1) > /dev/null
    local SCRIPTPATH=$(pwd -P)
  popd > /dev/null
  echo $SCRIPTPATH
}
base_dir=$(real_dirname $0)

debug_level=""
debug() {
  if [ -n $debug_level ]
  then
    # awk " BEGIN { print \"$@\" > \"/dev/fd/2\" }"
    echo "DEBUG: $@" >&2
  fi
}

# Where the bottles are uploaded to
remote_homebrew_bottle_host="uni"
remote_homebrew_bottle_dir="/web/03_theo/sites/theo.iks.cs.ovgu.de/htdocs/downloads/hets/macOS"
remote_homebrew_bottle_root_url="http://hets.eu/downloads/hets/macOS"

# This file makes heavy use of passing associative arrays to functions.
#
# Usage in caller:
# my_function "$(declare -p my_associative_array)"
#
# Usage in function:
# eval "declare -A my_local_associative_array="${1#*=}
#
# See http://stackoverflow.com/a/8879444/2068056

# Declare associative arrays
declare -A hets_commons hets_desktop hets_server factplusplus

hets_commons[package_name]="hets-commons"
hets_commons[upstream_repository]="https://github.com/spechub/Hets.git"
hets_commons[ref]="${REF_HETS_COMMONS:-origin/master}"
hets_commons[revision]="${REVISION_HETS_COMMONS:-1}"
hets_commons[make_install_target]="install-common"

hets_desktop[package_name]="hets-desktop"
hets_desktop[upstream_repository]="https://github.com/spechub/Hets.git"
hets_desktop[ref]="${REF_HETS_DESKTOP:-origin/master}"
hets_desktop[revision]="${REVISION_HETS_DESKTOP:-1}"
hets_desktop[make_compile_target]="hets.bin"
hets_desktop[make_install_target]="install-hets"
hets_desktop[executable]="hets"
hets_desktop[binary]="hets.bin"

hets_server[package_name]="hets-server"
hets_server[upstream_repository]="https://github.com/spechub/Hets.git"
hets_server[ref]="${REF_HETS_SERVER:-origin/master}"
hets_server[revision]="${REVISION_HETS_SERVER:-1}"
hets_server[make_compile_target]="hets_server.bin"
hets_server[make_install_target]="install-hets_server"
hets_server[executable]="hets-server"
hets_server[binary]="hets_server.bin"

factplusplus[package_name]="factplusplus"
factplusplus[upstream_repository]="https://bitbucket.org/dtsarkov/factplusplus.git"
factplusplus[ref]="${REF_FACTPLUSPLUS:-origin/master}"
factplusplus[version]="${VERSION_FACTPLUSPLUS:-1}"
factplusplus[revision]="${REVISION_FACTPLUSPLUS:-1}"

OSes=('mavericks' 'yosemite' 'el_capitan' 'sierra')

ghc_prefix=`ghc --print-libdir | sed -e 's+/lib.*/.*++g'`
cabal_options="-p --global --prefix=$ghc_prefix"

local_upstream_repo_dir="$base_dir/build/upstream-repositories"
local_bottle_dir="$base_dir/build/bottles"


# ----- #
# Tools #
# ----- #

# Always use GNU sed
if hash gsed 2> /dev/null
then
	SED=gsed
else
	SED=sed
fi


# ------------ #
# Build System #
# ------------ #

compile_package() {
  eval "declare -A package_info="${1#*=}

  debug "compile_package ${package_info[package_name]}"
  # always update the version file
  case "${package_info[package_name]}" in
    "factplusplus")
      make
      ;;
    "hets-desktop"|"hets-server")
      stack setup
      make stack
      ;;
  esac
	if [[ -n "${package_info[make_compile_target]}" ]]
	then
    make ${package_info[make_compile_target]}
    strip ${package_info[binary]}
	fi
}

install_package_to_prefix() {
  eval "declare -A package_info="${1#*=}
	local bottle_dir=$(versioned_bottle_dir "$(declare -p package_info)")
  debug "install_package_to_prefix ${package_info[package_name]}"
  debug "install_package_to_prefix.local_bottle_dir: $local_bottle_dir"
  debug "install_package_to_prefix.bottle_dir: $bottle_dir"

  mkdir -p "$local_bottle_dir/$bottle_dir"
  rm -rf "$local_bottle_dir/$bottle_dir/*"
  rm -rf "$local_bottle_dir/$bottle_dir/.*"
  case "${package_info[package_name]}" in
    "factplusplus")
      install_factplusplus "$bottle_dir"
      ;;
    *)
      make ${package_info[make_install_target]} PREFIX="$local_bottle_dir/$bottle_dir"
      ;;
  esac
}

install_factplusplus() {
  local bottle_dir="$1"
  debug "install_factplusplus $local_bottle_dir/$bottle_dir"
  cp "FaCT++.C/obj/libfact.jnilib" "$local_bottle_dir/$bottle_dir"
  cp "FaCT++.JNI/obj/libFaCTPlusPlusJNI.jnilib" "$local_bottle_dir/$bottle_dir"
}

post_process_installation() {
  eval "declare -A package_info="${1#*=}
	local bottle_dir=$(versioned_bottle_dir "$(declare -p package_info)")
  debug "post_process_installation ${package_info[package_name]}"
  debug "post_process_installation.full_bottle_dir: $local_bottle_dir/$bottle_dir"

  case "${package_info[package_name]}" in
    "hets-commons")
      local brew_prefix="$(brew --prefix)"
      pushd "$local_bottle_dir/$bottle_dir" > /dev/null
        ln -sf "$brew_prefix/opt/hets-lib" "lib/hets/hets-lib"
      popd > /dev/null
			;;
    "hets-desktop"|"hets-server")
			post_process_hets "$(declare -p package_info)" "$bottle_dir"
			;;
  esac
  write_install_receipt "$(declare -p package_info)" "$bottle_dir"
}

# The wrapper script needs to use a shell that is certainly installed.
# It needs to point to the correct executable.
# Hets needs to have additional locale settings.
# It also needs to use the hets-commons package which is located in a
# different directory.
post_process_hets() {
  eval "declare -A package_info="${1#*=}
  local bottle_dir="$2"
  local version_dir="$(basename "$bottle_dir")"
	local wrapper_script="bin/${package_info[executable]}"
  local brew_cellar="$(brew --cellar)"
  debug "post_process_hets ${package_info[package_name]}"
  debug "post_process_hets.full_bottle_dir: $local_bottle_dir/$bottle_dir"
  debug "post_process_hets.version_dir: $version_dir"
  debug "post_process_hets.wrapper_script: $wrapper_script"
  debug "post_process_hets.brew_cellar: $brew_cellar"

  pushd "$local_bottle_dir/$bottle_dir" > /dev/null
    rm -f "share/man/man1/hets.1e"
    rm -f "share/man/man1/hets.1-e"

		read -r -d '' wrapper_script_header <<WRAPPER_SCRIPT_HEADER
#!/bin/bash

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

brew_prefix="\$(brew --prefix)"

COMMONSDIR="\$brew_prefix/opt/hets-commons"
PROGDIR="$brew_cellar/${package_info[package_name]}/$version_dir"
PROG="${package_info[executable]}"

[[ -z \${HETS_JNI_LIBS} ]] && \\
            HETS_JNI_LIBS="\$brew_prefix/opt/factplusplus"
WRAPPER_SCRIPT_HEADER

    # replace the script header with the above one
		$SED -ie "/\/bin\/ksh93/,/PROG=/ d" "$wrapper_script"
    echo "$wrapper_script_header" > "$wrapper_script.tmp"
		cat "$wrapper_script" >> "$wrapper_script.tmp"
		mv -f "$wrapper_script.tmp" "$wrapper_script"
    chmod 555 "$wrapper_script"
    rm -f "${wrapper_script}e"
    rm -f "${wrapper_script}-e"

    # search and replace
		$SED -i "s/BASEDIR/COMMONSDIR/g" "$wrapper_script"
		$SED -i "s#PELLET_PATH=.*#PELLET_PATH=$brew_prefix/opt/pellet/bin#"
		$SED -i "s/^\s*exec\s*\"\${COMMONSDIR/exec \"\${PROGDIR/" "$wrapper_script"
		$SED -i "s/^\s*exec\s*'\${COMMONSDIR/exec '\${PROGDIR/" "$wrapper_script"
  popd > /dev/null
}

write_install_receipt() {
  eval "declare -A package_info="${1#*=}
  local bottle_dir="$2"
  debug "post_process_hets ${package_info[package_name]}"
  debug "post_process_hets.full_bottle_dir: $local_bottle_dir/$bottle_dir"
  debug "post_process_hets.get_version_unix_timestamp: $(get_version_unix_timestamp "$(declare -p package_info)")"

  pushd "$local_bottle_dir/$bottle_dir" > /dev/null
    echo "{\"used_options\":[],\"unused_options\":[],\"built_as_bottle\":true,\"poured_from_bottle\":false,\"time\":null,\"source_modified_time\":$(get_version_unix_timestamp "$(declare -p package_info)"),\"HEAD\":null,\"stdlib\":null,\"compiler\":\"ghc\",\"source\":{\"path\":\"@@HOMEBREW_PREFIX@@/Library/Formula/${package_info[package_name]}\",\"tap\":\"spechub/hets\",\"spec\":\"stable\"}}" > INSTALL_RECEIPT.json
  popd > /dev/null
}

# ---------------------- #
# Version Control System #
# ---------------------- #

sync_upstream_repository() {
  eval "declare -A package_info="${1#*=}
  if [ ! -d "$local_upstream_repo_dir/${package_info[package_name]}" ]
  then
    clone_upstream_repository "$(declare -p package_info)"
  else
    pull_upstream_repository "$(declare -p package_info)"
  fi
  checkout_ref "$(declare -p package_info)"
}

clone_upstream_repository() {
  eval "declare -A package_info="${1#*=}
  local repo_dir="$local_upstream_repo_dir/${package_info[package_name]}"
  if [ ! -d "$repo_dir" ]; then
    mkdir -p "$local_upstream_repo_dir"
    pushd "$local_upstream_repo_dir" > /dev/null
      git clone "${package_info[upstream_repository]}" "$repo_dir"
      git submodule update --init --recursive
    popd > /dev/null
  fi
}

pull_upstream_repository() {
  eval "declare -A package_info="${1#*=}
  local repo_dir="$local_upstream_repo_dir/${package_info[package_name]}"
  pushd "$repo_dir" > /dev/null
    git fetch
    git submodule update --recursive
  popd > /dev/null
}

checkout_ref() {
  eval "declare -A package_info="${1#*=}
  local repo_dir="$local_upstream_repo_dir/${package_info[package_name]}"
  debug "checkout_ref ${package_info[package_name]}"
  debug "checkout_ref.ref: ${package_info[ref]}"
  debug "checkout_ref.repo_dir: $repo_dir"
  pushd "$repo_dir" > /dev/null
    git reset --hard ${package_info[ref]}
  popd > /dev/null
}


# --------------- #
# Version Numbers #
# --------------- #

# execute AFTER compiling
get_version_commit_oid() {
  eval "declare -A package_info="${1#*=}
  local repo_dir="$local_upstream_repo_dir/${package_info[package_name]}"
  pushd "$repo_dir" > /dev/null
    local result=$(git log -1 --format='%H')
    debug "get_version_commit_oid ${package_info[package_name]}"
    debug "get_version_commit_oid.result: $result"
    echo $result
  popd > /dev/null
}

# execute AFTER compiling
get_version_unix_timestamp() {
  eval "declare -A package_info="${1#*=}
  local repo_dir="$local_upstream_repo_dir/${package_info[package_name]}"
  pushd "$repo_dir" > /dev/null
		local result="$(git log -1 --format='%ct')"
    debug "get_version_unix_timestamp ${package_info[package_name]}"
    debug "get_version_unix_timestamp.result: $result"
    echo $result
  popd > /dev/null
}

# execute AFTER compiling
get_version() {
  eval "declare -A package_info="${1#*=}
  local repo_dir="$local_upstream_repo_dir/${package_info[package_name]}"
  local result
  pushd "$repo_dir" > /dev/null
    case "${package_info[package_name]}" in
      "hets-commons"|"hets-desktop"|"hets-server")
        result="$($SED -n -e '/^hetsVersionNumeric =/ { s/.*"\([^"]*\)".*/\1/; p; q; }' Driver/Version.hs)"
        ;;
      *)
        result="${package_info[version]}"
        ;;
    esac
    debug "get_version ${package_info[package_name]}"
    debug "get_version.result: $result"
    echo $result
  popd > /dev/null
}


# -------- #
# Bottling #
# -------- #

bottle_formula() {
  eval "declare -A package_info="${1#*=}
  local repo_dir="$local_upstream_repo_dir/${package_info[package_name]}"
  debug "bottle_formula ${package_info[package_name]}"

  pushd "$repo_dir" > /dev/null
		compile_package "$(declare -p package_info)"
		install_package_to_prefix "$(declare -p package_info)"
		post_process_installation "$(declare -p package_info)"
    create_tarball "$(declare -p package_info)"
    upload_tarball "$(declare -p package_info)"
  popd > /dev/null
}

versioned_bottle_dir() {
  eval "declare -A package_info="${1#*=}
  local version="${package_info[version]}"
  case "${package_info[package_name]}" in
    "hets-commons"|"hets-desktop"|"hets-server")
      version="$(get_version "$(declare -p package_info)")"
      ;;
  esac
  local revision="${package_info[revision]}"
	local result="${package_info[package_name]}/${version}_$revision"
  debug "versioned_bottle_dir ${package_info[package_name]}"
  debug "versioned_bottle_dir.result: $result"
  echo $result
}

tarball_name() {
  eval "declare -A package_info="${1#*=}
  local version="$(get_version "$(declare -p package_info)")"
  local revision="${package_info[revision]}"
  result="${package_info[package_name]}-${version}_$revision.tar.gz"
  debug "tarball_name ${package_info[package_name]}"
  debug "tarball_name.result: $result"
  echo $result
}

tarball_name_with_os_and_revision() {
  eval "declare -A package_info="${1#*=}
  local OS="$2"
  local version="$(get_version "$(declare -p package_info)")"
  local revision="${package_info[revision]}"
  # echo "${package_info[package_name]}-${version}_$revision.$OS.bottle.$revision.tar.gz"
  result="${package_info[package_name]}-${version}_$revision.$OS.bottle.tar.gz"
  debug "tarball_name_with_os_and_revision ${package_info[package_name]}"
  debug "tarball_name_with_os_and_revision.result: $result"
  echo $result
}

create_tarball() {
  eval "declare -A package_info="${1#*=}
	local bottle_dir="$(versioned_bottle_dir "$(declare -p package_info)")"
  local tarball="$(tarball_name "$(declare -p package_info)")"

  pushd "$local_bottle_dir" > /dev/null
    tar czf "$tarball" "$bottle_dir"

    local shasum=$(shasum -a 256 "$tarball" | cut -d ' ' -f1)
    debug "create_tarball ${package_info[package_name]}"
    debug "create_tarball.shasum: $shasum"
    echo -n "$shasum" > "${tarball}.sha256sum"
  popd > /dev/null
}

upload_tarball() {
  eval "declare -A package_info="${1#*=}
	local bottle_dir="$(versioned_bottle_dir "$(declare -p package_info)")"
  local tarball="$(tarball_name "$(declare -p package_info)")"
  debug "upload_tarball ${package_info[package_name]}"

  pushd "$local_bottle_dir" > /dev/null
    debug "upload_tarball: ssh $remote_homebrew_bottle_host mkdir -p $remote_homebrew_bottle_dir"
    ssh "$remote_homebrew_bottle_host" mkdir -p "$remote_homebrew_bottle_dir"
    debug "upload_tarball: scp $tarball ${remote_homebrew_bottle_host}:${remote_homebrew_bottle_dir}"
    scp "$tarball" "${remote_homebrew_bottle_host}:${remote_homebrew_bottle_dir}"
    for OS in "${OSes[@]}"
    do
			local bottle_filename="$(tarball_name_with_os_and_revision "$(declare -p package_info)" "$OS")"
      debug "upload_tarball: ssh $remote_homebrew_bottle_host ln -f $remote_homebrew_bottle_dir/$tarball $remote_homebrew_bottle_dir/$bottle_filename"
			ssh "$remote_homebrew_bottle_host" ln -f \
				"$remote_homebrew_bottle_dir/$tarball" \
				"$remote_homebrew_bottle_dir/$bottle_filename"
    done
  popd > /dev/null
}

bottle_shasum() {
  eval "declare -A package_info="${1#*=}
  local tarball="$(tarball_name "$(declare -p package_info)")"
  debug "bottle_shasum ${package_info[package_name]}"
  debug "bottle_shasum.tarball: $tarball"

  pushd "$local_bottle_dir" > /dev/null
    local result="$(cat "${tarball}.sha256sum")"
    debug "bottle_shasum.shasum: $result"
    echo $result
  popd > /dev/null
}



# ------------------- #
# Update formula file #
# ------------------- #

patch_formula() {
  eval "declare -A package_info="${1#*=}
  local formula_file="${package_info[package_name]}.rb"
  local version_commit="$(get_version_commit_oid "$(declare -p package_info)")"
  local sha256="$(bottle_shasum "$(declare -p package_info)")"
  local the_version
  case "${package_info[package_name]}" in
    "hets-commons"|"hets-desktop"|"hets-server")
      the_version="$(get_version "$(declare -p package_info)")"
      ;;
    *)
      the_version="${package_info[version]}"
      ;;
  esac
  debug "patch_formula.the_version: $the_version"
  debug "patch_formula ${package_info[package_name]}"
  debug "patch_formula.version_commit: $version_commit"
  debug "patch_formula.sha256: $sha256"
  pushd "$base_dir" > /dev/null
    $SED -i "s/@@version_commit = '.*/@@version_commit = '$version_commit'/" $formula_file
    $SED -i "s/  revision .*/  revision ${package_info[revision]}/" $formula_file
    $SED -i "s|root_url '.*|root_url '$remote_homebrew_bottle_root_url'|" $formula_file
    $SED -i "s/sha256 '[^']*'/sha256 '$sha256'/g" $formula_file
    $SED -i "s/@@version = .*/@@version = '$the_version'/" $formula_file
  popd > /dev/null
}

commit_formula() {
  eval "declare -A package_info="${1#*=}
  local formula_file="${package_info[package_name]}.rb"
  local version="$(get_version "$(declare -p package_info)")"
  local revision="${package_info[revision]}"
  debug "commit_formula ${package_info[package_name]}"
  debug "commit_formula.version: $version"
  debug "commit_formula.revision: $revision"
  pushd "$base_dir" > /dev/null
    git add $formula_file
    git commit -m "Update ${package_info[package_name]} to $version_${package_info[revision]}"
  popd > /dev/null
}



# ---------- #
# Publishing #
# ---------- #

push_formula_changes() {
  pushd $base_dir > /dev/null
    git push
  popd > /dev/null
}
