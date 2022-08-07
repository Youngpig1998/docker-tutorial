# network相关命令

```
docker network connect [OPTIONS] NETWORK CONTAINER:将一个容器连接至一个网络

docker network create [OPTIONS] NETWORK:创建一个网络

  OPTIONS
    -d, --driver string:管理网络的驱动(默认是bridge)
    --subnet strings:指定网络的网段(x.x.x.x/x格式)
    --gateway strings:指定网络的网关
    -o, --opt map:视驱动而定的可选的选项,例如:parent=eth0,指定使用的网络接口为eth0

docker network inspect NETWORK [NETWORK...]:展示一个或多个网络的细节

docker network ls:列出网络
```





# 如何实现网络互通

​	Docker 提供了三种网络模式，分别是 null、host 和 bridge。

## null

​	它是最简单的模式，也就是没有网络，但允许其他的网络插件来自定义网络连接，这里就不多做介绍了。



## host 

​	host的意思是直接使用宿主机网络，相当于去掉了容器的网络隔离（其他隔离依然保留），所有的容器会共享宿主机的 IP 地址和网卡。这种模式没有中间层，自然通信效率高，但缺少了隔离，运行太多的容器也容易导致端口冲突。

​	host 模式需要在 docker run 时使用 --net=host 参数，下面我就用这个参数启动 Nginx：

```shell
docker run -d --rm --net=host nginx:alpine
```



## bridge

​	桥接模式，它有点类似现实世界里的交换机、路由器，只不过是由软件虚拟出来的，容器和宿主机再通过虚拟网卡接入这个网桥（图中的 docker0），那么它们之间也就可以正常的收发网络数据包了。不过和 host 模式相比，bridge 模式多了虚拟网桥和网卡，通信效率会低一些。

<img src="../img/Docker_bridge.jpg" style="zoom: 50%;" />

​	和 host 模式一样，我们也可以用 --net=bridge 来启用桥接模式，但其实并没有这个必要，因为 Docker 默认的网络模式就是 bridge，所以一般不需要显式指定。

​	**端口号映射需要使用 bridge 模式，并且在 docker run 启动容器时使用 -p 参数，形式和共享目录的 -v 参数很类似，用 : 分隔本机端口和容器端口。**


