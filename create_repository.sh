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
    git init /home/git/${repository_name} --bare

    # post-receive hook
    post_receive="/home/git/${repository_name}/hooks/post-receive"
    cat > ${post_receive}<<-EOF
#!/usr/bin/env bash
sh /home/git/hooks/post-receive \$repository_name
EOF
    chmod a+x ${post_receive}

    # pre-receive hook
    pre_receive="/home/git/${repository_name}/hooks/pre-receive"
    cat > ${pre_receive}<<-EOF
#!/usr/bin/env bash
sh /home/git/hooks/pre-receive \$repository_name
EOF
    chmod a+x ${pre_receive}

    chown -R git.git /home/git/${repository_name}
    echo 
    echo "Congratulation, everything is ready"
    echo "Use git clone git@git.sunlands:${repository_name} to use this repository"
    echo "Have fun~"
fi

