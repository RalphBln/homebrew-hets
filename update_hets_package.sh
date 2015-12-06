#!/bin/bash

SCRIPT_DIR="$(realpath $(dirname $0))"
DIR="${TMPDIR:-/tmp}"
REPO_DIR="$DIR/Homebrew-Hets-Git"
REPO_URL="https://github.com/spechub/Hets.git"

FORMULA_FILE="hets.rb"

# retrieve git repository
cd $DIR
git clone --depth=1 $REPO_URL $REPO_DIR
cd $REPO_DIR

# get version info
version_commit=`git log -1 --format='%H'`
version_unix_timestamp=`git log -1 --format='%ct'`

# remove git repository
cd $DIR
rm -rf $REPO_DIR

# update version info
cd $SCRIPT_DIR
if hash gsed 2>/dev/null
then
  gsed -i "s/@@version_commit = '.*/@@version_commit = '$version_commit'/g" $FORMULA_FILE
  gsed -i "s/@@version_unix_timestamp = '.*/@@version_unix_timestamp = '$version_unix_timestamp'/g" $FORMULA_FILE
else
  sed -i "s/@@version_commit = '.*/@@version_commit = '$version_commit'/g" $FORMULA_FILE
  sed -i "s/@@version_unix_timestamp = '.*/@@version_unix_timestamp = '$version_unix_timestamp'/g" $FORMULA_FILE
fi

git add hets.rb
git commit -m "Update hets to $version_unix_timestamp."
git push
