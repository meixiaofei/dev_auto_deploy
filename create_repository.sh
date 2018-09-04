#!/usr/bin/env bash

repository_name=$1
if [ -z $1 ]; then
    echo "Usage: $(basename $0) repository_name"
    exit 1;
fi

if [ -d ${repository_name} ]; then
    echo "The same repository already exist, please check carefully."
    exit 1;
else
    git init ${repository_name} --bare
    hook_file="/home/git/${repository_name}/hooks/post-receive"
    cat > ${hook_file}<<-EOF
#!/bin/bash
export PROJECT_NAME=${repository_name}
export GIT_DIR=/home/git/\$PROJECT_NAME
/bin/bash /home/git/post-receive-auto-update /home/git-web/\$PROJECT_NAME
EOF
    chmod a+x ${hook_file}
    chown -R git.git /home/git/${repository_name}
    echo 
    echo "Congratulation, everything is ready"
    echo "Use git clone git@git.sunlands:${repository_name} to use this repository"
    echo "Have fun~"
fi

