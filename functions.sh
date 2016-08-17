#!/usr/bin/env bash

real_dirname() {
  pushd $(dirname $1) > /dev/null
    local SCRIPTPATH=$(pwd -P)
  popd > /dev/null
  echo $SCRIPTPATH
}
base_dir=$(real_dirname $0)

# Where the bottles are uploaded to
remote_homebrew_bottle_host="uni"
remote_homebrew_bottle_dir="/home/wwwuser/eugenk/homebrew-hets"
remote_homebrew_bottle_root_url="http://www.informatik.uni-bremen.de/~eugenk/homebrew-hets"

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
declare -A hets_commons hets_desktop hets_server

factplusplus[package_name]="factplusplus"
factplusplus[upstream_repository]="https://bitbucket.org/dtsarkov/factplusplus.git"
factplusplus[ref]="${REF_FACTPLUSPLUS:-origin/master}"
factplusplus[revision]="${REVISION_FACTPLUSPLUS:-1}"

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
hets_desktop[cabal_flags]=""

hets_server[package_name]="hets-server"
hets_server[upstream_repository]="https://github.com/spechub/Hets.git"
hets_server[ref]="${REF_HETS_SERVER-origin/master}"
hets_server[revision]="${REVISION_HETS_SERVER:-1}"
hets_server[make_compile_target]="hets_server.bin"
hets_server[make_install_target]="install-hets_server"
hets_server[executable]="hets-server"
hets_server[binary]="hets_server.bin"
hets_server[cabal_flags]="-f server -f -gtkglade -f -uniform"

OSes=('mavericks' 'yosemite' 'el_capitan')

ghc_prefix=`ghc --print-libdir | sed -e 's+/lib.*/.*++g'`
cabal_options="-p --global --prefix=$ghc_prefix"

local_repository_dir="$base_dir/build/git-repositories"
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

install_hets_dependencies() {
  eval "declare -A package_info="${1#*=}
  cabal update
  export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:
  cabal install alex happy $cabal_options
  cabal install gtk2hs-buildtools $cabal_options
  cabal install glib $cabal_options
  cabal install gtk -f have-quartz-gtk $cabal_options
  cabal install --only-dependencies "${elment[cabal_flags]}" $cabal_options
}

compile_package() {
  eval "declare -A package_info="${1#*=}

	if [[ -n "${package_info[make_compile_target]}" ]]
	then
    make ${package_info[make_compile_target]}
    strip ${package_info[binary]}
	fi
}

install_package_to_prefix() {
  eval "declare -A package_info="${1#*=}
	local bottle_dir=$(versioned_bottle_dir "$(declare -p package_info)")

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
  cp "FaCT++.C/obj/libfact.jnilib" "$local_bottle_dir/$bottle_dir"
  cp "FaCT++.JNI/obj/libFaCTPlusPlusJNI.jnilib" "$local_bottle_dir/$bottle_dir"
}

post_process_installation() {
  eval "declare -A package_info="${1#*=}
	local bottle_dir=$(versioned_bottle_dir "$(declare -p package_info)")

  case "${package_info[package_name]}" in
    "hets-commons")
      local brew_prefix="$(brew --prefix)"
      pushd "$local_bottle_dir/$bottle_dir" > /dev/null
        ln -sf "$brew_prefix/opt/hets-lib" "lib/hets/hets-lib"
        ln -sf "$brew_prefix/opt/pellet/bin" "share/pellet"
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
		$SED -i "s/^\s*exec\s*\"\${COMMONSDIR/exec \"\${PROGDIR/g" "$wrapper_script"
		$SED -i "s/^\s*exec\s*'\${COMMONSDIR/exec '\${PROGDIR/g" "$wrapper_script"
  popd > /dev/null
}

write_install_receipt() {
  eval "declare -A package_info="${1#*=}
  local bottle_dir="$2"

  pushd "$local_bottle_dir/$bottle_dir" > /dev/null
    echo "{\"used_options\":[],\"unused_options\":[],\"built_as_bottle\":true,\"poured_from_bottle\":false,\"time\":null,\"source_modified_time\":$(hets_version_unix_timestamp "$(declare -p package_info)"),\"HEAD\":null,\"stdlib\":null,\"compiler\":\"ghc\",\"source\":{\"path\":\"@@HOMEBREW_PREFIX@@/Library/Formula/${package_info[package_name]}\",\"tap\":\"spechub/hets\",\"spec\":\"stable\"}}" > INSTALL_RECEIPT.json
  popd > /dev/null
}

# ---------------------- #
# Version Control System #
# ---------------------- #

sync_upstream_repository() {
  eval "declare -A package_info="${1#*=}
  if [ ! -d "$local_repository_dir/${package_info[package_name]}" ]
  then
    clone_upstream_repository "$(declare -p package_info)"
  else
    pull_upstream_repository "$(declare -p package_info)"
  fi
  checkout_ref "$(declare -p package_info)"
}

clone_upstream_repository() {
  eval "declare -A package_info="${1#*=}
  local repo_dir="$local_repository_dir/${package_info[package_name]}"
  if [ ! -d "$repo_dir" ]; then
    mkdir -p "$local_repository_dir"
    pushd "$local_repository_dir" > /dev/null
      git clone "${package_info[upstream_repository]}" "$repo_dir"
    popd > /dev/null
  fi
}

pull_upstream_repository() {
  eval "declare -A package_info="${1#*=}
  local repo_dir="$local_repository_dir/${package_info[package_name]}"
  pushd "$repo_dir" > /dev/null
    git fetch
  popd > /dev/null
}

checkout_ref() {
  eval "declare -A package_info="${1#*=}
  local repo_dir="$local_repository_dir/${package_info[package_name]}"
  pushd "$repo_dir" > /dev/null
    git reset --hard ${package_info[ref]}
  popd > /dev/null
}


# --------------- #
# Version Numbers #
# --------------- #

hets_version_commit_oid() {
  eval "declare -A package_info="${1#*=}
  local repo_dir="$local_repository_dir/${package_info[package_name]}"
  pushd "$repo_dir" > /dev/null
    echo $(git log -1 --format='%H')
  popd > /dev/null
}

# execute AFTER compiling
hets_version_no() {
  eval "declare -A package_info="${1#*=}
  local repo_dir="$local_repository_dir/${package_info[package_name]}"
  pushd "$repo_dir" > /dev/null
    cat version_nr
  popd > /dev/null
}

# execute AFTER compiling
hets_version_unix_timestamp() {
  eval "declare -A package_info="${1#*=}
  local repo_dir="$local_repository_dir/${package_info[package_name]}"
  pushd "$repo_dir" > /dev/null
		echo $(git log -1 --format='%ct')
  popd > /dev/null
}

hets_version() {
  eval "declare -A package_info="${1#*=}
  local version="$(hets_version_no "$(declare -p package_info)")"
  local timestamp="$(hets_version_unix_timestamp "$(declare -p package_info)")"
	echo "${version}-${timestamp}"
}


# -------- #
# Bottling #
# -------- #

bottle_subdir() {
  eval "declare -A package_info="${1#*=}
  echo "${local_bottle_dir}/${package_info[package_name]}"
}

versioned_bottle_dir() {
  eval "declare -A package_info="${1#*=}
  local version="$(hets_version "$(declare -p package_info)")"
  local revision="${package_info[revision]}"
	echo "${package_info[package_name]}/${version}_$revision"
}

bottle_formula() {
  eval "declare -A package_info="${1#*=}
  local repo_dir="$local_repository_dir/${package_info[package_name]}"

  pushd "$repo_dir" > /dev/null
    case "${package_info[package_name]}" in
      "hets-desktop"|"hets-server")
        install_hets_dependencies "$(declare -p package_info)"
        ;;
      *)
        ;;
    esac
		compile_package "$(declare -p package_info)"
		install_package_to_prefix "$(declare -p package_info)"
		post_process_installation "$(declare -p package_info)"
    create_tarball "$(declare -p package_info)"
    upload_tarball "$(declare -p package_info)"
  popd > /dev/null
}

tarball_name() {
  eval "declare -A package_info="${1#*=}
  local version="$(hets_version "$(declare -p package_info)")"
  local revision="${package_info[revision]}"
  echo "${package_info[package_name]}-${version}_$revision.tar.gz"
}

tarball_name_with_os_and_revision() {
  eval "declare -A package_info="${1#*=}
  local OS="$2"
  local version="$(hets_version "$(declare -p package_info)")"
  local revision="${package_info[revision]}"
  echo "${package_info[package_name]}-${version}_$revision.$OS.bottle.$revision.tar.gz"
}

create_tarball() {
  eval "declare -A package_info="${1#*=}
	local bottle_dir="$(versioned_bottle_dir "$(declare -p package_info)")"
  local tarball="$(tarball_name "$(declare -p package_info)")"

  pushd "$local_bottle_dir" > /dev/null
    tar czf "$tarball" "$bottle_dir"

    local shasum=$(shasum -a 256 "$tarball" | cut -d ' ' -f1)
    echo -n "$shasum" > "${tarball}.sha256sum"
  popd > /dev/null
}

upload_tarball() {
  eval "declare -A package_info="${1#*=}
	local bottle_dir="$(versioned_bottle_dir "$(declare -p package_info)")"
  local tarball="$(tarball_name "$(declare -p package_info)")"

  pushd "$local_bottle_dir" > /dev/null
    ssh "$remote_homebrew_bottle_host" mkdir -p "$remote_homebrew_bottle_dir"
    scp "$tarball" \
      "${remote_homebrew_bottle_host}:${remote_homebrew_bottle_dir}"
    for OS in "${OSes[@]}"
    do
			local bottle_filename="$(tarball_name_with_os_and_revision "$(declare -p package_info)" "$OS")"
			ssh "$remote_homebrew_bottle_host" ln -sf \
				"$remote_homebrew_bottle_dir/$tarball" \
				"$remote_homebrew_bottle_dir/$bottle_filename"
    done
  popd > /dev/null
}

bottle_shasum() {
  eval "declare -A package_info="${1#*=}
  local tarball="$(tarball_name "$(declare -p package_info)")"

  pushd "$local_bottle_dir" > /dev/null
    cat "${tarball}.sha256sum"
  popd > /dev/null
}



# ------------------- #
# Update formula file #
# ------------------- #

patch_formula() {
  eval "declare -A package_info="${1#*=}
  local formula_file="${package_info[package_name]}.rb"
  pushd "$base_dir" > /dev/null
    $SED -i "s/@@version_commit = '.*/@@version_commit = '$(hets_version_commit_oid "$(declare -p package_info)")'/" $formula_file
    $SED -i "s/@@version_no = '.*/@@version_no = '$(hets_version_no "$(declare -p package_info)")'/" $formula_file
    $SED -i "s/@@version_unix_timestamp = '.*/@@version_unix_timestamp = '$(hets_version_unix_timestamp "$(declare -p package_info)")'/" $formula_file
    $SED -i "s/  revision .*/  revision ${package_info[revision]}/" $formula_file
    $SED -i "s/root_url '.*/root_url '$remote_homebrew_bottle_root_url'/" $formula_file
    $SED -i "s/sha256 '[^']*'/sha256 '$(bottle_shasum "$(declare -p package_info)")'/g" $formula_file
  popd > /dev/null
}

commit_formula() {
  eval "declare -A package_info="${1#*=}
  local formula_file="${package_info[package_name]}.rb"
  pushd "$base_dir" > /dev/null
    git add $formula_file
    git commit -m "Update ${package_info[package_name]} to $(hets_version "$(declare -p package_info)")_${package_info[revision]}"
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
