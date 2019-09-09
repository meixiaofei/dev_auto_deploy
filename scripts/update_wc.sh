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

#sudo chown -R git.git ${WCS_DIR}/${branch} 
cd ${WCS_DIR}/${branch} 
git fetch --all && git reset --hard origin/${branch}
chown -R nginx.nginx ${WCS_DIR}/${branch}
[ -f "composer.json" ] && composer install
[ -f "package.json" ] && npm install && npm run build
if [ -f "pm2.json" ]; then
    pm2_name=$(awk '/name/{print}' pm2.json|cut -d ":" -f2|cut -d '"' -f2)
    pm2 restart ${pm2_name}
fi
[ -f "init" ] && php init --env=Development --overwrite=All
if [ -f "pom.xml" ]; then
    sh /home/git/scripts/sbm stop $project_name $branch
    mvn package -Ptest
    service_port=$(crudini --get "$services_discovery_ini" "$project_name" "$branch" 2>&1)
    sh /home/git/scripts/sbm start $project_name $branch $service_port
fi

echo "Done"

