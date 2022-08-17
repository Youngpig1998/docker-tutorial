# Docker的镜像管理（镜像只可读）

1. docker search命令

   例如：

   ```shell
   docker search tomcat
   ```

   第一列是名字，一般名字短的都是官方的。

2. 获取镜像

   ```shell
   docker pull xxx         
   ```

   不带其他参数的话下载的就是最新版本的

   要下载其他版本的话就先去DockerHub上搜索，再点进去查看有哪些版本。

   下载其他版本： `docker pull xxx:3.6`

   也可以从私有仓库中下载

3. docker image 查看有哪些命令可以跟在它后面

   如docker image ls就是查看当前容器中有哪些镜像。`docker image ls`  等价于 `docker images`

4. 导出镜像

   `docker image save xxx -o docker_xxx.tar.gz`      文件名可以随便取     -o参数表示输出为  可以直接`docker save`

   还有一个export的版本，不过save版本会保存镜像的版本，而export不会。

5. 删除镜像

   ```shell
   docker image rm xxx
   #or
   docker rmi xxx
   ```

6. 导入镜像

   `docker image  load -i docker_xxx.tar.gz`    可以直接 `docker load`

   还有一个import的版本    最好使用load版本。

7. 构建镜像

   ```shell
   docker build  -t centos6.9_ssh:v2   /opt/dockerfile/centos6.9_ssh/ 
   ```

8. history

   `docker image history xxx` 查看在构建镜像的时候都是用过哪些命令。相当于展示了镜像的分层结构，有时对于镜像排错很有用。

9. inspect   查看镜像的属性

   `docker image inspect xxx`

10. prune 批量删除 （尽量不要使用）

11. tag  起个别名       **在上传到私有仓库时有用**

    docker image tag   xxxxxxx（id） xxx（别名）

    docker tag即可

12. 列出所有的 dangling images:

    ```shell
    docker images -f "dangling=true"
    ```

    **build 自己的 docker 镜像的时候，有时会遇到用一个甚至多个中间层镜像，这会一定程度上减少最终打包出来 docker 镜像的大小，但是会产生一些tag 为 none 的无用镜像，也称为悬挂镜像 (dangling images)**

13. 删除所有的 dangling images：

    ```shell
    docker rmi $(docker images -f "dangling=true" -q)
    ```

14. docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]:从一个改动的容器创建一个新的镜像

15. docker push [OPTIONS] NAME[:TAG]:把一个镜像或者仓库推送至registry上





