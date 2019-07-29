## dev_auto_deploy
this is an auto deploy shell script for local git develop

## 目的
* 方便本地测试版本开发迭代后在远程的测试

## 这个脚本实际发生作用
* 本地更新/新建分支 推到远程时会自动克隆形成一份"WC(work copy)"到对应目录 以便能直接进行web访问

## 用法
1. 首先安装node的chokidar包 ```npm install chokidar --save``` 接着执行 ```pm2 start hook-update.js``` 用来监听git hook脚本产生的脚本 异步执行
2. 部署git仓库时直接执行```sh create_repository.sh project_name```
3. 然后正常在本地执行克隆使命就完成了整个流程

## 更新说明
# WEB中从代码开发到访问测试那些事儿

  不知从何说起 辣就以「从前书信很慢 车马很远 一生只够爱一个人」开始吧~<br />    --《从前慢》
<a name="gaoj1"></a>
# 前言:
  在很久很久以前([1983年](https://baike.baidu.com/item/dns/427444?wtp=tt#2)) 之前由于网络不发达，上网对于普通人来说是很遥远的，当时可没有可视化的操作系统，各目标之前都是通过IP直接交流的。到近现代，[DNS](https://baike.baidu.com/item/dns/427444) 系统的出现，作为萌新小白的我们，只用记住这些具有意义的域名就行了，在这看不见的背后，操作系统/应用软件为我们做了许多。

<a name="uJAef"></a>
#### 1. 先讲讲从浏览器键入URL 敲下回车:

- 浏览器默认补全协议(http/https)
- 将域名解析出对应指向的IP(先查 [内存缓存]()，既而 hosts 文件，最终远程 DNS, 再找不到就 unresolve了)
- [TCP三次握手](https://baike.baidu.com/item/%E4%B8%89%E6%AC%A1%E6%8F%A1%E6%89%8B/5111559?fr=aladdin)
- 服务端软件处理( [cgi](https://baike.baidu.com/item/CGI/607810?fromtitle=%EF%BC%A3%EF%BC%A7%EF%BC%A9&fromid=6717913) /前后端应用)
- 浏览器接受响应输出
<a name="oht35"></a>
#### 2. 再讲讲开发中影响最终响应结果的两个大头

- 其一：控制对用户提供服务的指向

  通过自定义的 [DNS服务](https://www.jianshu.com/p/e519f46425c4), 将用户的请求指向特定服务器。就拿我们自己的来说，就是：将 `*(any).sunlands` 指向 `测试服务器S15`。<br />  当所有请求引导至目标节点服务器的时候， 再通过 [Nginx](https://baike.baidu.com/item/nginx/3817705?fr=aladdin)，一款高性能web服务器，通过一些自定义的配置， 将所以访问的域名 映射绑定到对应的目录(前端打包后的 `index.html` ，后端统一入口文件 `index.php` )，以此将所提供的服务暴露出去。<br />eg: http://分支名.项目名.子目录.sunlands 的配置方法

```nginx
server {
    listen 80;
    # 这样就通过正则 将所有引导过来的请求 指向对应绑定的目录
    server_name ~^(?<branch>[^\.]*)\.(?<project>[^\.]*)\.(?<subdir>[^\.]*)\.sunlands$;
    root /private/var/www/$project/$branch/$subdir;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    location ~ \.php$ {
        try_files $uri =404;

        include fastcgi.conf;
        # 将请求转交给PHP 的cgi(php-fpm)
        fastcgi_pass 127.0.0.1:9000;
    }
}
```


- 基二：更新应用的硬编码

上面已将用户所有约定的请求指向了对应服务所在的目录，我们开发人员需要做的就是将本地开发好的程序变动，应用到远程所提供的服务中。
<a name="0uvFg"></a>
#### 3. 最终流程实现
至于具体部署流程细节没太抠，这里主要先讲讲大体流程，能凑合用。。

- a. 新建 `git` 用户 作为Git的工作内容空间
- b. 维护 `~/.ssh/authorized_keys` 来实现用户与服务器的免密钥交互
- c. 服务端部署裸仓 `sh create_repository.sh project_name`

这个脚本主要有两个作用： 1. 挂载git的 [post-receive](https://git-scm.com/book/zh/v2/%E8%87%AA%E5%AE%9A%E4%B9%89-Git-Git-%E9%92%A9%E5%AD%90) 事件 2. 事件中将执行一个脚本 [post-receive-auto-update](https://github.com/meixiaofei/dev_auto_deploy/blob/master/post-receive-auto-update)<br />post-receive:
```shell
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

```

post-receive-auto-update:<br />核心思想: 通过判断 oval nval ref 这仨值来判断当前动作，生成执行脚本(创建/更新/删除分支)异步执行(避免如前端npm打包等耗时操作的同步等待)，脚本中再根据文件特征，进行一系列命令。

- 比如当有 `package.json` 时，直接跑 `npm install && npm run build`
- 当有 `composer.json` 时，直接跑 `composer install`
- 当有 `init` 时，直接跑 `php init --env=Development --overwrite=All`

这样就简单的进行了针对性的处理。<br />发邮件: [git-commit-notifier](https://github.com/git-commit-notifier/git-commit-notifier)
```shell
#!/bin/bash
#
# This script is invoked each time data has been accepted by the repository.
# It then updates, creates or deletes the working copy of the respective
#
export PATH="/opt/ruby/bin:$PATH"

SCRIPTS_DIR="/home/git/scripts"
CREATE_WC_CMD="create_wc.sh"
UPDATE_WC_CMD="update_wc.sh"
DELETE_WC_CMD="delete_wc.sh"

WCS_DIR="$1"
#
# *_wc
#
# All three functions update, create or delete the working copy of the
# specified branch. They all expect the name of the branch as their first
# parameter.
#
# @param    $1  name of the directory on hg.bingzhe.intra
# @param    $2  project name
#
function generate_script() {
    script=/home/git/tmp/${RANDOM}.sh
    echo "${1}" > $script
    chmod 777 $script
}

function update_wc() {
    echo "Updating branch $2 for $1"
    generate_script "${SCRIPTS_DIR}/${UPDATE_WC_CMD} ${1} ${2} ${USER} ${WCS_DIR}"
}
function create_wc() {
    echo "Creating branch $2 for $1"
    generate_script "${SCRIPTS_DIR}/${CREATE_WC_CMD} ${1} ${2} ${USER} ${WCS_DIR}"
}
function delete_wc() {
    echo "Deleting branch $2 for $1"
    generate_script "${SCRIPTS_DIR}/${DELETE_WC_CMD} ${1} ${2} ${USER} ${WCS_DIR}"
}

while read oval nval ref; do
    branch=$(basename "${ref}")
    # 下面这行是来发邮件的
    echo "${oval} ${nval} ${ref}" | git-commit-notifier "/home/git/git-notifier-config.yml"
    
    # 生成异步执行的脚本
    if expr "${oval}" : "0*$" >/dev/null; then
        create_wc "${PROJECT_NAME}" "${branch}"
    elif expr "${nval}" : "0*$" > /dev/null; then
        delete_wc "${PROJECT_NAME}" "${branch}"
    else
        update_wc "${PROJECT_NAME}" "${branch}"
    fi
done
```
 <br />具体的 oval nval ref<br />![1.png](https://cdn.nlark.com/yuque/0/2019/png/100826/1564327738739-dcd9dd29-dfaa-4c57-86d8-65961a1cfb60.png#align=left&display=inline&height=1462&name=1.png&originHeight=1462&originWidth=1794&size=907030&status=done&width=1794)<br />安利: [zsh-git-alias](https://github.com/meixiaofei/notes/blob/master/git.plugin.zsh) 如上图中的一些git简写别名

- d. 异步执行生成的脚本

主要通过 `node `的 chokidar 包来完成。监听特定文件夹的新生成的文件，并予以执行。<br />通过 `pm2` 来挂起这个服务

```shell
var fs = require('fs');
var chokidar = require('chokidar');
var exec = require('child_process').exec;
var filePath = 'default';

// One-liner for current directory, ignores .dotfiles
chokidar.watch('tmp', {ignored: /(^|[\/\\])\../}).on('all', function (event, path) {
    console.log(event, path);
    if (event == 'add') {
        filePath = __dirname + '/' + path;
        fs.exists(filePath, function (exists) {
            if (exists) {
                var cmdStr = 'sh ' + filePath;
                exec(cmdStr, function(err, stdout, stderr) {
                    if (err) {
                        console.log(err);
                    } else {
                        fs.unlink(filePath, function (err) {
                            if (err) {
                                return console.log(err);
                            }
                            console.log('delete success ' + filePath + ' Output: ' + stdout);
                        });
                    }
                });
            }
        });
    }
});

```


- e. 本地进行 `git clone git@git.sunlands:${repository_name}` 将远端的仓库，拉取至本地。

当本地代码变更完成后 push 到远端的时候会触发裸仓中一系列 hook 事件，这里我们使用的是 `post-receive` 事件，通过此 hook 完成一系列脚本，至此就完成本地开发+远端自动部署+访问的整个流程。
<a name="g9JaS"></a>
#### 4. 结束语
大概……应该……是写得比较详细了吧(捂脸)，and [戳这里](https://github.com/meixiaofei/dev_auto_deploy)，所有代码礼包大放送。<br />![2.png](https://cdn.nlark.com/yuque/0/2019/png/100826/1564330120345-d7ff19c6-dcf4-4896-95ae-0a6efe61959f.png#align=left&display=inline&height=124&name=2.png&originHeight=124&originWidth=132&size=2370&status=done&width=132)

