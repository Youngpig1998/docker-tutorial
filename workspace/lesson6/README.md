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





