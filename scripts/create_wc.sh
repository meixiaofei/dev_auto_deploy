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

GIT="/usr/bin/git"
REPOSITORY_DIR="/home/git/$1"
PROJECT_DIR="$4"

[ ! -d $PROJECT_DIR ] && mkdir -p $PROJECT_DIR
cd $PROJECT_DIR
[ ! -d $branch ] && $GIT clone $REPOSITORY_DIR -b $branch $branch
chown -R nginx.nginx $branch
cd $branch
[ -f "composer.json" ] && composer install
[ -f "package.json" ] && npm install && npm run build
[ -f "pm2.json" ] && npm run start:pm2 
[ -f "init" ] && php init --env=Development --overwrite=All

echo "Done"

