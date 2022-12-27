# Docker的数据卷管理

​	可以将自己写的代码放入容器镜像中，如放进nginx/tomcat中。

​	1、docker run -d -p 80:80 -v  /opt/xsa:/usr/share/nginx/html   nginx   前者为宿主机目录，后者为nginx放代码的目录。  如果宿主机的目录不存在会自己创建。代码可以直接在宿主机里面改

​	-v 等价于--volume      

​	**-v参数可以像-p参数一样重复使用。挂载目录时如果发现源路径不存在会自动创建，这时就会是一个“坑”，当主机目录被意外删除时会导致容器出现空目录，让应用无法按预想的流程工作。**

​	**-v挂载目录默认是可读可写的，但也可以加上“:ro”变成只读。可以防止容器意外修改文件，例如“-v /tmp:/tmp:ro”**

​	2、docker run -d -p 81:80 -v young:/usr/share/nginx/html nginx

​	当docker第一次见到young时，发现不存在，会创建一个卷。

​	**卷就相当于一个小型磁盘，用来持久化存储数据和代码的。**

## 容器数据卷的特性

​	Docker Volume数据卷说白了就是从容器到宿主机直接创建一个文件目录映射，宿主机创建的容器卷可以挂载到任何一个容器上，它有以下特点：

1. 绕过UFS系统，以达到本地磁盘IO的性能，比如运行一个容器，在容器中对数据卷修改内容，会直接改变宿主机上的数据卷中的内容，所以是本地磁盘IO的性能，而不是先在容器中写一份，最后还要将容器中的修改的内容拷贝出来进行同步
2. 绕过UFS系统，有些文件例如容器运行产生的数据文件不需要再通过docker commit打包进镜像文件
3. 数据卷可以在容器间共享和重用数据
4. 数据卷可以在宿主和容器间共享数据
5. 数据卷数据改变是直接修改且实时同步的
6. 数据卷是持续性的，直到没有容器使用它们。即便是初始的数据卷容器或中间层的数据卷容器删除了，只要还有其他的容器使用数据卷，那么里面的数据都不会丢失
7. 可以这么理解，宿主机的数据卷目录和容器里映射的目录在宿主机磁盘上是一个地址，容器里的目录类似快捷方式。
8. **是将宿主机的目录挂载到了容器内，容器内原来目录里的文件没有被删除。关系是：宿主机目录覆盖容器目录。而且，容器内目录中原来的文件并没有被删除。**





## 容器的挂载类型

1. bind：将宿主机的指定目录挂载到容器的指定目录，以覆盖的形式挂载（这也就意味着，容器指定目录下的内容也会随着消失）

2. volume：在宿主机的 Docker 存储目录下创建一个目录，并挂载到容器的指定目录（并不会覆盖容器指定目录下的内容）。Volumes是在宿主机文件系统的一个路径，**默认情况下统一的父路径是 `/var/lib/docker/volumes/`**，非 Docker 进程不能修改这个路径下面的文件，所以说 Volumes 是容器数据持久存储数据最安全的一种方式。
3. Tmpfs挂载：需要再次强调的是`tmpfs` 挂载是临时的，只存留在容器宿主机的内存中。当容器停止时，`tmpfs` 挂载文件路径将被删除，在那里写入的文件不会被持久化。

​	在有些时候，由于容器内的目录有着特殊作用，并不能以覆盖的形式进行挂载。但又想挂载到宿主机上，这时我们便可以使用 volume 类型的挂载方式。像我们所说的 --mount 和 --volume 命令都是支持以这两种类型的方式挂载，无非就是配置稍有不同。

​	两种命令使用 bind 类型挂载区别：当宿主机上指定的目录不存在时，我们使用 --volume 命令挂载时，便会自动的在宿主机上创建出相应目录，而我们要是使用 --mount 命令来挂载，便会输出 `` 报错信息。


## 将容器目录挂载到主机

1. 使用 --volume 命令实现 bind 类型的挂载

```shell
[root@k8s-master01 ~]# docker run -d -it --name zhangsan \
-v /zhangsan:/usr/share/nginx/html \
nginx:1.21.0
[root@k8s-master01 ~]# echo "Hello World" > /zhangsan/index.html
[root@k8s-master01 ~]# docker exec -it zhangsan /bin/bash
root@3cad299c93aa:/# cd /usr/share/nginx/html/
root@3cad299c93aa:/usr/share/nginx/html# ls
index.html
root@3cad299c93aa:/usr/share/nginx/html# curl 127.0.0.1 
Hello World
```


​	可以看到，当我们使用 bind 类型的挂载时，容器内指定的目录原有内容会被覆盖。

2. 使用 --mount 命令实现 bind 类型的挂载

```shell
[root@k8s-master01 ~]# docker run -d -it --name wangwu \
--mount type=bind,source=/zhangsan,destination=/usr/share/nginx/html \
nginx:1.21.0
[root@k8s-master01 ~]# docker exec -it wangwu /bin/bash
root@474cf5ddd29f:/# cd /usr/share/nginx/html/
root@474cf5ddd29f:/usr/share/nginx/html# ls
index.html
root@474cf5ddd29f:/usr/share/nginx/html# curl 127.0.0.1
Hello World
```

​	我们上面指定 type=bind 类型的原因是因为 --mount 命令默认挂载的类型就是 volume 类型，所以需要指定。

​	--mount 命令挂载格式：

​	bind 挂载类型：--mount [type=bind] source=/path/on/host,destination=/path/in/container[,...]

​	volume 挂载类型：--mount source=my-volume,destination=/path/in/container[,...]

3. 使用 --volume 命令实现 volume 类型的挂载

```shell
[root@k8s-master01 ~]# docker run -d -it --name volume \
-v zhangsan:/usr/share/nginx/html \
nginx:1.21.0
[root@k8s-master01 ~]# docker exec -it volume /bin/bash
root@dced26ccb8f0:/# cd /usr/share/nginx/html/
root@dced26ccb8f0:/usr/share/nginx/html# ls
50x.html  index.html
```

4. 使用 --mount 命令实现 volume 类型的挂载

```shell
[root@k8s-master01 ~]# docker run -d -it --name mount \
--mount source=mount,destination=/usr/share/nginx/html \
nginx:1.21.0
[root@k8s-master01 ~]# docker exec -it mount /bin/bash
root@7e63ca69f135:/# cd /usr/share/nginx/html/
root@7e63ca69f135:/usr/share/nginx/html# ls
50x.html  index.html
```


​	查看宿主机的挂载目录

​	其实，使用 bind 或是 mount 类型的挂载方式，区别主要就是在于有 / 和没 /，有 / 就会挂载到宿主机的指定目录，没有 / 则是会挂载到宿主机 Docker 所在的目录中。


## Bind mounts

​	其实Bind Mounts挂载数据卷的方式也是大家最常见的一种方式，比如使用-v参数绑定数据卷，其中/root/nginx/html是我们任意指定的一个宿主机磁盘文件目录，这种情况下就是Bind mounts方式挂载数据卷。

```
-v /root/nginx/html:/usr/share/nginx/html/ 
```


​	除了使用-v参数绑定的方式，还可以使用--mount参数绑定的方式实现Bind mounts数据卷挂载。在--mount参数绑定的方式之前，我们先创建一个宿主机文件路径mkdir -p /root/nginx/html用于做实验 。

```shell
docker run -d --name bind-mount-nginx 
  -p 80:80 
  --mount type=bind,source=/root/nginx/html,target=/usr/share/nginx/html/,readonly 
  nginx:latest
```

--mount 以键值对的方式传参，比 -v 提供了更多的选项

- type=bind表示以Bind mounts方式挂载数据卷
- source=/root/nginx/html表示宿主机的文件路径
- target=/usr/share/nginx/html/表示容器的文件路径，宿主机source文件路径挂载到容器的target路径
- readonly配置参数，表示文件路径采用只读的方式挂载



## volume相关命令

```
docker volume inspect [OPTIONS] VOLUME [VOLUME...]:展示一个或多个volume的详细信息

docker volume ls:列出volume

docker volume rm [OPTIONS] VOLUME [VOLUME...]:移除一个或多个volume

docker volume prune [OPTIONS]:移除所有不用的本地volume
```





## 使用 volume driver 把数据存储到其它地方

​	除了默认的把数据卷中的数据存储在宿主机，docker 还允许我们通过指定 volume driver 的方式把数据卷中的数据存储在其它的地方，比如 Azrue Storge 或 AWS 的 S3。
​	简单起见，我们接下来的 demo 演示如何通过 vieux/sshfs 驱动把数据卷的存储在其它的主机上。docker 默认是不安装 vieux/sshfs 插件的，我们可以通过下面的命令进行安装：

```shell
$ docker plugin install --grant-all-permissions vieux/sshfs
```

​	然后通过 vieux/sshfs 驱动创建数据卷，并指定远程主机的登录用户名、密码和数据存放目录：

```shell
$ docker volume create --driver vieux/sshfs \
    -o sshcmd=nick@10.32.2.134:/home/nick/sshvolume \
    -o password=yourpassword \
    mysshvolume
```

​	注意，请确保你指定的远程主机上的挂载点目录是存在的(demo 中是 /home/nick/sshvolume 目录)，否则在启动容器时会报错。最后在启动容器时指定挂载这个数据卷：

```shell
$ docker run -id \
    --name testcon \
    --mount type=volume,volume-driver=vieux/sshfs,source=mysshvolume,target=/world \
    ubuntu /bin/bash
```

​	这就搞定了，你在容器中 /world 目录下操作的文件都存储在远程主机的 /home/nick/sshvolume 目录中。进入容器 testcon 然后在 /world 目录中创建一个文件，然后打开远程主机的 /home/nick/sshvolume 目录进行查看，你新建的文件是不是已经出现在那里了！

## 数据卷原理

​	下图描述了 docker 容器挂载数据的三种方式：

![img](https://images2018.cnblogs.com/blog/952033/201803/952033-20180304104439300-70506106.png)

​	数据卷是完全被 docker 管理的，就像上图中的黄色区域描述的一样，docker 在宿主机的文件系统中找了个文件管理数据卷相关的数据。因此你可能根本不需要知道数据卷文件在宿主机上的存储位置(事实上抱着刨根问底的精神我们还是很想搞清楚它背后的工作原理！)。

​	docker 数据卷的本质是容器中的一个特殊目录。在容器创建的过程中，docker 会将宿主机上的指定目录(一个以数据卷 ID 为名称的目录)挂载到容器中指定的目录上。这里使用的挂载方式为绑定挂载(bind mount)，所以挂载完成后的宿主机目录和容器内的目标目录表现一致。
​	比如我们执行下面的命令创建数据卷 hello，并挂载到容器 testcon 的 /world 目录：

```shell
$ docker volume create hello
$ docker run -id --name testcon --mount type=volume,source=hello,target=/world ubuntu /bin/bash
```

​	实际上在容器的创建过程中，类似于在容器中执行了下面的代码：

```c
// 将数据卷 hello 在宿主机上的目录绑定挂载到 rootfs 中指定的挂载点 /world 上
mount("/var/lib/docker/volumes/hello/_data", "rootfs/world", "none", MS_BIND, NULL)
```

​	在处理完所有的 mount 操作之后(真正需要 docker 容器挂载的除了数据卷目录还包括 rootfs，init-layer 里的内容，/proc 设备等)，docker 只需要通过 chdir 和 pivot_root 切换进程的根目录到 rootfs 中，这样容器内部进程就只能看见以 rootfs 为根的文件系统以及被 mount 到 rootfs 之下的各项目录了。例如我们启动的 testcon 中的文件系统为：

![img](https://images2018.cnblogs.com/blog/952033/201803/952033-20180304104618819-2047061877.png)

​	下面我们介绍几个数据卷在使用中比较常见的问题。

## 数据的覆盖问题

- 如果挂载一个空的数据卷到容器中的一个非空目录中，那么这个目录下的文件会被复制到数据卷中。**(然而bind模式会覆盖掉容器目录下的原始数据，即容器中的非空目录会变空！)**
- 如果挂载一个非空的数据卷到容器中的一个目录中，那么容器中的目录中会显示数据卷中的数据。如果原来容器中的目录中有数据，那么这些原始数据会被隐藏掉。**(bind模式或者volume模式都会隐藏掉容器中的原始数据！)**

​	这两个规则都非常重要，灵活利用第一个规则可以帮助我们初始化数据卷中的内容。掌握第二个规则可以保证挂载数据卷后的数据总是你期望的结果。



## 在 Dockerfile 中添加数据卷

​	在 Dockerfile 中我们可以使用 VOLUME 指令向容器添加数据卷：

```dockerfile
VOLUME /data
```

​	在使用 docker build 命令生成镜像并且以该镜像启动容器时会挂载一个**匿名数据卷**到 /data 目录。根据我们已知的数据覆盖规则，如果镜像中存在 /data 目录，这个目录中的内容将全部被复制到宿主机中对应的目录中，并且根据容器中的文件设置合适的权限和所有者。
​	注意，**VOLUME 指令不能挂载主机中指定的目录。这是为了保证 Dockerfile 的可一致性，因为不能保证所有的宿主机都有对应的目录**。
​	在实际的使用中，这里还有一个陷阱需要大家注意：**在 Dockerfile 中使用 VOLUME 指令之后的代码，如果尝试对这个数据卷进行修改，这些修改都不会生效**！下面是一个这样的例子：

```dockerfile
FROM ubuntu
RUN useradd nick
VOLUME /data
RUN touch /data/test.txt
RUN chown -R nick:nick /data
```

​	通过这个 Dockerfile 创建镜像并启动容器后，该容器中存在用户 nick，并且能够看到 /data 目录挂载的数据卷。但是 /data 目录内并没有文件 test.txt，更别说 test.txt 文件的所有者属性了。要解释这个现象需要我们了解通过 Dockerfile 创建镜像的过程：
​	Dockerfile 中除了 FROM 指令的每一行都是基于上一行生成的临时镜像运行一个容器，执行一条类似 `docker commit` 的命令得到一个新的镜像。这条类似 `docker commit` 的命令不会对挂载的数据卷进行保存。
​	所以上面的 Dockerfile 最后两行执行时，都会在一个临时的容器上挂载 /data，并对这个临时的数据卷进行操作，但是这一行指令执行并提交后，这个临时的数据卷并没有被保存。因而我们最终通过镜像创建的容器所挂载的数据卷是没有被最后两条指令操作过的。我们姑且叫它 "Dockerfile 中数据卷的初始化问题"。

​	下面的写法可以解决 Dockerfile 中数据卷的初始化问题：

```dockerfile
FROM ubuntu
RUN useradd nick
RUN mkdir /data && touch /data/test.txt
RUN chown -R nick:nick /data
VOLUME /data
```

​	通过这个 Dockerfile 创建镜像并启动容器后，数据卷的初始化是符合预期的。这是由于在挂载数据卷时，/data 已经存在，/data 中的文件以及它们的权限和所有者设置会被复制到数据卷中。
​	还有另外一种方法可以解决 Dockerfile 中数据卷的初始化问题。就是利用 CMD 指令和 ENTRYPOINT 指令的执行特点：与 RUN 指令在镜像构建过程中执行不同，CMD 指令和 ENTRYPOINT 指令是在容器启动时执行。因此使用下面的 Dockerfile 也可以达到对数据卷的初始化目的：

```dockerfile
FROM ubuntu
RUN useradd nick
VOLUME /data
CMD touch /data/test.txt && chown -R nick:nick /data && /bin/bash
```



