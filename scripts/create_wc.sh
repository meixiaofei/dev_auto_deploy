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
services_discovery_ini="/home/git/services_discovery.ini"
port_range="20000-25000"

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

if [ -f "pom.xml" ]; then
    mvn package -Ptest
    service_port=$(crudini --get $services_discovery_ini $project_name $branch 2>&1)
    re='^[0-9]+$'
    if ! [[ $service_port =~ $re ]]; then
        service_port=$(shuf -i $port_range -n 1)
        if [[ $(nmap -sT -vv -p $port_range 127.0.0.1|grep $service_port|wc -l) > 0 ]]; then
            service_port=$(shuf -i $port_range -n 1)
        fi
        echo "Service port is: $service_port"
        crudini --set $services_discovery_ini $project_name $branch $service_port
    fi
    sh /home/git/scripts/sbm start $project_name $branch $service_port
fi

echo "Done"

