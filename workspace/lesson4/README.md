# Docker容器的相关命令（容器是可读可写的）

1. docker run -it --name [container_name]   [image_name]   [command]   

   -it 分配交互式的终端，这样我们就能进入到容器的子系统中

   -t  分配一个终端

   --name  指定容器的名字，名字跟在--name后面

   -it:以交互模式进入容器,并打开终端

   -d:使容器在后台运行,并打印容器ID

   **--rm 告诉Docker不保存容器，只要运行完毕就自动清除，省去我们手动管理容器的麻烦**

   -h 指定容器的hostname

   --link container_id:tag:定义连接其他容器的hostname为tag,一般用于多容器间方便通信

   --network string（docker的network名字） 或者 container:ID（如container:4ddf）   可以让你启动一个容器并“加入”到另一个容器的 Network 

   --net=host，就意味着这个容器不会为进程启用 Network Namespace。这就意味着，这个容器拆除了 Network Namespace 的“隔离墙”，所以，它会和宿主机上的其他普通进程一样，直接共享宿主机的网络栈。这就为容器直接操作和使用宿主机网络提供了一个渠道。

   --ip string:指定分配一个ip(默认随机)

   -p, --publish list:将一个容器的端口映射至host.例如80:80

   -v, --volume list:绑定挂载一个volume.格式为[host path:]container path[:OPTIONS].如果没有host path,docker会自动创建;OPTIONS可选ro只读

   -m bytes:限制容器的内存使用量.如果不指定

   --memory-swap则默认使用相同容量的交换内存

   --memory-swap bytes:限制容器的内存和交换内存总共的使用量(-1指不限制)

   -c int:设置CPU shares(是一个相对的权重值,默认1024)

   --cpus decimal:设置可使用CPU的数量

   --blkio-weight uint16:设置容器block IO的权重,数值在10至1000之间,0为不允许(默认是0)

   --device-read-bps list:限制从一个设备读取的速率(字节每秒),默认为[].例如:/dev/sda:30MB

   --device-read-iops list:限制从一个设备读取的次数(次数每秒)

   --device-write-bps list:限制从一个设备写入的速率

   --device-write-iops list:限制从一个设备写入的次数

   --restart string:当一个容器退出时,重启的策略(默认是no)

   --no:不自动重启

   --on-failure[:max-retries]:容器进程退出代码非0则重启容器.可选一个最大重启次数的限制

   --always:始终重启容器

   --unless-stopped:始终重启容器,除非该容器被手动关闭

   

2. docker container ls   查看容器列表，默认只查看运行以及暂停的容器。  等价于  docker ps  

   -a查看所有容器

3. docker container stop  id名

   删除一个正在运行的容器

   也可以直接使用docker stop
       **-t int:等待容器停止的秒数,若超过这个时间,则强制停止它(默认10秒)**

   一条命令实现停用并删除容器

   ```shell
   docker stop $(docker ps -q) & docker rm $(docker ps -aq)
   ```

4. docker kill  强制关闭一个或多个正在运行的容器
       -s string:向容器发送的信号(默认是SIGKILL)

5. docker container start id名/名字   前提是必须得有一个存在的容器

6. docker restart  重启一个或多个容器,相当于一次执行stop和start
       -t int:等待容器停止的秒数,若超过这个时间,则强制停止它(默认10秒)

7. docker rm   移除一个或多个容器
       -f:强制移除一个正在使用的容器(使用SIGKILL)
       -v:移除与容器相关联的volume     **（实测删不掉卷）**

   强制删除所有的容器

   ```shell
   docker rm -f $(docker ps -aq)
   ```

8. docker cp    在一个容器和本地文件系统间拷贝文件或文件夹
   如：
   	docker cp a.txt 062:/tmp
   	docker cp 062:/tmp/a.txt ./b.txt

9. docker logs   得到一个容器的日志
       -f:跟踪日志输出

10. docker stats

    实时查看正在运行的docker容器信息

11. docker top  查看container中正在运行的进程。
    如查看所有容器的进程信息：

    ```shell
    for i in  `docker ps |grep Up|awk '{print $1}'`;do echo \ && docker top $i; done
    ```

    

12.  docker ps

    -q 只输出容器的id号

    -l 查看最近一次启动的容器  latest

    --no-trunc 显示详细信息







# 进入容器（目的：调试，排错）

1. docker exec (会分配一个新的终端tty)     进入一个容器

   ​	docker exec [OPTIONS] CONTAINERS COMMAND [ARG...]

   docker exec -it  [容器id或容器名字]    /bin/bash （/bin/sh）

   使用该命令可以满足多用户同时使用一个容器子系统

2. docker attach （使用同一个终端）    进入一个容器

   ​	docker attach [OPTIONS] CONTAINER

   ​	docker attach用的比较少

   **ps：ctrl p + ctrl q 即可直接返回到宿主机,需要注意此时容器仍然在运行，要与ctrl d区别。**

   ​		**ctrl d 是直接退回宿主机并且关闭容器。**

   ​		**使用前者返回宿主机后，可以使用 docker attach命令再返回容器，此时可以上下浏览历史命令记录。**

   

