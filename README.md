## dev_auto_deploy
this is an auto deploy shell script for local git develop

## 目的
* 方便本地测试版本开发迭代后在远程的测试

## 这个脚本实际发生作用
* 本地更新/新建分支 推到远程时会自动克隆形成一份"WC(work copy)"到对应目录 以便能直接进行web访问

## 用法
1. 首先安装node的chokidar包```npm install chokidar --save``` 用来监听git hook脚本产生的脚本 异步执行
2. 部署git仓库时直接执行```sh create_repository.sh project_name```
3. 然后正常在本地执行克隆使命就完成了整个流程
