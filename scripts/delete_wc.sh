#!/usr/bin/env bash

HELP="Usage: $(basename $0) project_name branch_name git_user wcs_dir"

if [ "$#" != "4" ]; then
    echo "${HELP}"
    exit 1
elif [ "$1" = "--help" -o "$1" = "-h" ]; then
    echo "${HELP}"
    exit 0
fi

project_name="$1"
branch="$2"
git_user="$3"
WCS_DIR="$4"
services_discovery_ini="/home/git/services_discovery.ini"

if [ -f "${WCS_DIR}/${branch}/pom.xml" ]; then
    sh /home/git/scripts/sbm stop $project_name $branch
    crudini --del $services_discovery_ini $project_name $branch 2>&1
fi

echo "Removing working copy of branch '"${branch}"'..."
sudo rm -rf "${WCS_DIR}/${branch}"

