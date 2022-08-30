# 理解 docker 容器中的 uid 和 gid

​	默认情况下，容器中的进程以 root 用户权限运行，并且这个 root 用户和宿主机中的 root 是同一个用户。听起来是不是很可怕，因为这就意味着一旦容器中的进程有了适当的机会，它就可以控制宿主机上的一切！本文我们将尝试了解用户名、组名、用户 id(uid)和组 id(gid)如何在容器内的进程和主机系统之间映射，这对于系统的安全来说是非常重要的。说明：本文的演示环境为 ubuntu 16.04(下图来自互联网)。

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909165237993-1211128179.png)

## 先来了解下 uid 和 gid

​	uid 和 gid 由 Linux 内核负责管理，并通过内核级别的系统调用来决定是否应该为某个请求授予特权。比如当进程试图写入文件时，内核会检查创建进程的 uid 和 gid，以确定它是否有足够的权限修改文件。注意，**内核使用的是 uid 和 gid，而不是用户名和组名**。简单起见，本文中剩下的部分只拿 uid 进行举例，系统对待 gid 的方式和 uid 基本相同。

​	很多同学简单地把 docker 容器理解为轻量的虚拟机，虽然这简化了理解容器技术的难度但是也容易带来很多的误解。事实上，与虚拟机技术不同：同一主机上运行的所有容器共享同一个内核(主机的内核)。容器化带来的巨大价值在于所有这些独立的容器(其实是进程)可以共享一个内核。这意味着即使由成百上千的容器运行在 docker 宿主机上，但**内核控制的 uid 和 gid 则仍然只有一套**。所以同一个 uid 在宿主机和容器中代表的是同一个用户(即便在不同的地方显示了不同的用户名)。
​	注意，由于普通的用来显示用户名的 Linux 工具并不属于内核(比如 id 等命令)，所以我们可能会看到同一个 uid 在不同的容器中显示为不同的用户名。但是对于相同的 uid 不能有不同的特权，即使在不同的容器中也是如此。

​	如果你已经了解了 Linux 的 user namespace 技术，参考[Linux Namespace : User](https://github.com/Youngpig1998/learning-linux/tree/master/workspace/namespace/user-namespace)，你需要注意的是到目前为止，docker 默认并没有启用 user namesapce，这也是本文讨论的情况。笔者会在接下来的文章中介绍如何配置 docker 启用 user namespace。

## 容器中默认使用 root 用户

​	如果不做相关的设置，容器中的进程默认以 root 用户权限启动，下面的 demo 使用 ubuntu 镜像运行 sleep 程序：

```shell
$ docker run -d  --name sleepme ubuntu sleep infinity
```

​	注意上面的命令中并没有使用 sudo。笔者在宿主机中的登录用户是 nick，uid 为 1000：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909165415859-180873456.png)

​	在宿主机中查看 sleep 进程的信息：

```shell
$ ps aux | grep sleep
```

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909165448848-1919383427.png)

​	sleep 进程的有效用户名称是 root，也就是说 sleep 进程具有 root 权限。
​	然后进入容器内部看看，看到的情况和刚才一样，sleep 进程也具有 root 权限：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909165523038-1426098151.png)

​	那么，**容器内的 root 用户和宿主机上的 root 用户是同一个吗？**
​	答案是：是的，它们对应的是同一个 uid。原因我们在前面已经解释过了：整个系统共享同一个内核，而内核只管理一套 uid 和 gid。

​	其实我们可以通过数据卷来简单的验证上面的结论。在宿主机上创建一个只有 root 用户可以读写的文件：

 ![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909170054020-215204880.png)

​	然后挂载到容器中：

```shell
$ docker run --rm -it -w=/testv -v $(pwd)/testv:/testv ubuntu
```

​	在容器中可以读写该文件：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909170136226-2009923481.png)

​	我们可以通过 Dockerfile 中的 USER 命令或者是 docker run 命令的 --user 参数指定容器中进程的用户身份。下面我们分别来探究这两种情况。

## 在 Dockerfile 中指定用户身份

​	我们可以在 Dockerfile 中添加一个用户 appuser，并使用 USER 命令指定以该用户的身份运行程序，Dockerfile 的内容如下：

```dockerfile
FROM ubuntu
RUN useradd -r -u 1000 -g appuser
USER appuser
ENTRYPOINT ["sleep", "infinity"]
```

​	编译成名称为 test 的镜像：

```shell
$ docker build -t test .
```

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909170232757-204151191.png)

​	用 test 镜像启动一个容器：

```shell
$ docker run -d --name sleepme test
```

​	在宿主机中查看 sleep 进程的信息：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909170302676-537876370.png)

​	这次显示的有效用户是 nick，这是因为在宿主机中，uid 为 1000 的用户的名称为 nick。再进入到容器中看看：

```shell
$ docker exec -it sleepme bash
```

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909170330419-2118356053.png)

​	容器中的当前用户就是我们设置的 appuser，如果查看容器中的 /etc/passwd 文件，你会发现 appuser 的 uid 就是 1000，这和宿主机中用户 nick 的 uid 是一样的。

​	让我们再创建一个只有用户 nick 可以读写的文件：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909170410957-537487670.png)

​	同样以数据卷的方式把它挂载到容器中：

```shell
$ docker run -d --name sleepme -w=/testv -v $(pwd)/testv:/testv test
```

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909170439586-187279477.png)

​	**在容器中 testfile 的所有者居然变成了 appuser**，当然 appuser 也就有权限读写该文件。

​	**这里到底发生了什么？而这些又这说明了什么？**
​	首先，宿主机系统中存在一个 uid 为 1000 的用户 nick。其次容器中的程序是以 appuser 的身份运行的，这是由我们通过 USER appuser 命令在 Dockerfile 程序中指定的。
​	事实上，系统内核管理的 uid 1000 只有一个，在宿主机中它被认为是用户 nick，而在容器中，它则被认为是用户 appuser。
​	所以有一点我们需要清楚：在容器内部，用户 appuser 能够获取容器外部用户 nick 的权利和特权。在宿主机上授予用户 nick 或 uid 1000 的特权也将授予容器内的 appuser。



## 从命令行参数中指定用户身份

​	我们还可以通过 docker run 命令的 --user 参数指定容器中进程的用户身份。比如执行下面的命令：

```shell
$ docker run -d --user 1000 --name sleepme ubuntu sleep infinity
```

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909170544518-440505334.png)

​	因为我们在命令行上指令了参数 --user 1000，所以这里 sleep 进程的有效用户显示为 nick。进入到容器内部看一下：

```shell
$ docker exec -it sleepme bash
```

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909170613560-27843544.png)

​	这是个什么情况？用户名称居然显示为 "I have no name!"！去查看 /etc/passwd 文件，里面果然没有 uid 为 1000 的用户。即便没有用户名称，也丝毫不影响该用户身份的权限，它依然可以读写只有 nick 用户才能读写的文件，并且用户信息也由 uid 代替了用户名：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909170645221-1651017494.png)

​	需要注意的是，在创建容器时通过 docker run --user 指定的用户身份会覆盖掉 Dockerfile 中指定的值。
​	我们重新通过 test 镜像来运行两个容器：

```shell
$ docker run -d test
```

​	查看 sleep 进程信息：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909170718742-891860372.png)

```shell
$ docker run --user 0 -d test
```

再次查看 sleep 进程信息：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909170758965-2026523005.png)

​	指定了 --urser 0 参数的进程显示有效用户为 root，说明命令行参数 --user 0 覆盖掉了 Dockerfile 中 USER 命令的设置。

## 总结

​	从本文中的示例我们可以了解到，容器中运行的进程同样具有访问主机资源的权限(docker 默认并没有对用户进行隔离)，当然一般情况下容器技术会把容器中进程的可见资源封锁在容器中。但是通过我们演示的对数据卷中文件的操作可以看出，一旦容器中的进程有机会访问到宿主机的资源，它的权限和宿主机上用户的权限是一样的。所以比较安全的做法是为容器中的进程指定一个具有合适权限的用户，而不要使用默认的 root 用户。当然还有更好的方案，就是应用 Linux 的 user namespace 技术隔离用户，笔者会在接下来的文章中介绍如何配置 docker 开启 user namespace 的支持。

