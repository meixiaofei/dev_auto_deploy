#!/usr/bin/env bash

HELP="Usage: $(basename $0) project_name branch_name git_user wcs_dir"

if [ "$#" != "4" ]; then
    echo "${HELP}"
    exit 1
elif [ "$1" = "--help" -o "$1" = "-h" ]; then
    echo "${HELP}"
    exit 0
fi

branch="$2"
git_user="$3"
WCS_DIR="$4"

echo "Removing working copy of branch '"${branch}"'..."
sudo rm -rf "${WCS_DIR}/${branch}"

