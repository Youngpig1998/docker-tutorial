# 隔离 docker 容器中的用户

​	[理解 docker 容器中的 uid 和 gid](../p7)介绍了 docker 容器中的用户与宿主机上用户的关系，得出的结论是：docker 默认没有隔离宿主机用户和容器中的用户。如果你已经了解了 Linux 的 user namespace 技术(参考[Linux Namespace : User](https://github.com/Youngpig1998/learning-linux/tree/master/workspace/namespace/user-namespace))，那么自然会问：docker 为什么不利用 Linux user namespace 实现用户的隔离呢？事实上，docker 已经实现了相关的功能，只是默认没有启用而已。本文将介绍如何配置 docker 来隔离容器中的用户。
说明：本文的演示环境为 ubuntu 16.04。

## 了解 Linux user namespace

​	Linux user namespace 为正在运行的进程提供安全相关的隔离(其中包括 uid 和 gid)，限制它们对系统资源的访问，而这些进程却感觉不到这些限制的存在。关于 Linux User Namespace 的介绍请参考笔者的[Linux Namespace : User](https://github.com/Youngpig1998/learning-linux/tree/master/workspace/namespace/user-namespace)一文。

​	对于容器而言，阻止权限提升攻击(privilege-escalation attacks)的最好方法就是使用普通用户权限运行容器的应用程序。
​	然而有些应用必须在容器中以 root 用户来运行，这就是我们使用 user namespace 的最佳场景。我们通过 user namespace 技术，把宿主机中的一个普通用户(只有普通权限的用户)映射到容器中的 root 用户。在容器中，该用户在自己的 user namespace 中认为自己就是 root，也具有 root 的各种权限，但是对于宿主机上的资源，它只有很有限的访问权限(普通用户)。

## User namespace 的用户映射

​	在配置 docker daemon 启用 user namespace 前，我需要先来了解一些关于从属(subordinate)用户/组和映射(remapping)的概念。从属用户和组的映射由两个配置文件来控制，分别是 /etc/subuid 和 /etc/subgid。看下它们的默认内容：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909172434004-389303785.png)

​	对于 subuid，这一行记录的含义为：
​	**用户 nick，在当前的 user namespace 中具有 65536 个从属用户，用户 ID 为 100000-165535，在一个子 user namespace 中，这些从属用户被映射成 ID 为 0-65535 的用户。**subgid 的含义和 subuid 相同。

​	比如说用户 nick 在宿主机上只是一个具有普通权限的用户。我们可以把他的一个从属 ID(比如 100000 )分配给容器所属的 user namespace，并把 ID 100000 映射到该 user namespace 中的 uid 0。此时即便容器中的进程具有 root 权限，但也仅仅是在容器所在的 user namespace 中，一旦到了宿主机中，你顶多也就有 nick 用户的权限而已。

​	当开启 docker 对 user namespace 的支持时(docker 的 userns-remap 功能)，我们可以指定不同的用户映射到容器中。比如我们专门创建一个用户 dockeruser，然后手动设置其 subuid 和 subgid：

```
nick:100000:65536
dockeruser:165536:65536
```

​	并把它指定给 docker daemon：

```
{
  "userns-remap": "dockeruser"
}
```

​	请注意 subuid 的设置信息，我们为 dockeruser 设置的从属 ID 和 nick 用户是不重叠的，实际上任何用户的从属 ID 设置都是不能重叠的。

​	或者一切从简，让 docker 为我们包办这些繁琐的事情，直接把 docker daemon 的 userns-rempa 参数指定为 "default"：

```
{
  "userns-remap": "default"
}
```

​	这时，docker 会自动完成其它的配置。

## 配置 docker daemon 启用用户隔离

​	这里笔者采取简单的方式，让 docker 创建默认的用户用于 user namespace。我们需要先创建 /etc/docker/daemon.json 文件：

```shell
$ sudo touch /etc/docker/daemon.json
```

​	然后编辑其内容如下(如果该文件已经存在，仅添加下面的配置项即可)，并重启 docker 服务：

```shell
{
  "userns-remap": "default"
}
$ sudo systemctl restart docker.service
```

​	下面我们来验证几个关于用户隔离的几个点。

​	首先验证 docker 创建了一个名为 dockremap 的用户：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909172634828-2033153056.png)

​	然后查看 /etc/subuid 和 /etc/subgid 文件中是否添加了新用户 dockremap 相关的项：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909172706821-1965892050.png)

​	接下来我们发现在 /var/lib/docker 目录下新建了一个目录： 165536.165536，查看该目录的权限：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909172736061-2103663599.png)

​	165536 是由用户 dockremap 映射出来的一个 uid。查看 165536.165536 目录的内容：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909172807489-1312119693.png)

​	与 /var/lib/docker 目录下的内容基本一致，说明启用用户隔离后文件相关的内容都会放在新建的 165536.165536 目录下。

​	通过上面的检查，我们可以确认 docker daemon 已经启用了用户隔离的功能。



## 宿主机中的 uid 与容器中 uid

​	在 docker daemon 启用了用户隔离的功能后，让我们看看宿主机中的 uid 与容器中 uid 的变化。

```shell
$ docker run -d --name sleepme ubuntu sleep infinity
```

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909172909818-1467866670.png)

​	uid 165536 是用户 dockremap 的一个从属 ID，在宿主机中并没有什么特殊权限。然而容器中的用户却是 root，这样的结果看上去很完美：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909172944985-1580146099.png)

## 新创建的容器会创建 user namespace

​	在 docker daemon 启用用户隔离的功能前，新创建的容器进程和宿主机上的进程在相同的 user namespace 中。也就是说 docker 并没有为容器创建新的 user namespace：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909173024874-1992789648.png)

​	上图中的容器进程 sleep 和宿主机上的进程在相同的 user namespace 中(没有开启用户隔离功能的场景)。

​	在 docker daemon 启用用户隔离的功能后，让我们查看容器中进程的 user namespace：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909173105417-603239198.png)

​	上图中的 4404 就是我们刚启动的容器中 sleep 进程的 PID。可以看出，docker 为容器创建了新的 user namespace。在这个 user namespace 中，容器中的用户 root 就是天神，拥有至高无上的权力！



## 访问数据卷中的文件

​	我们可以通过访问数据卷中的文件来证明容器中 root 用户究竟具有什么样的权限？创建四个文件，分别属于用户 root 、165536 和 nick。rootfile 只有 root 用户可以读写，用户 nick 具有 nickfile 的读写权限，uid 165536 具有文件 165536file 的读写权限，任何用户都可以读写 testfile 文件：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909173156961-1366963108.png)

​	下面把这几个文件以数据卷的方式挂载到容器中，并检查从容器中访问它们的权限：

```shell
$ docker run -it --name test -w=/testv -v $(pwd)/testv:/testv ubuntu
```

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909173250789-302788546.png)

​	容器中的 root 用户只能访问 165536file 和 testfile，说明这个用户在宿主机中只有非常有限的权限。



## 在容器中禁用 user namespace

​	一旦为 docker daemon 设置了 "userns-remap" 参数，所有的容器默认都会启用用户隔离的功能(默认创建一个新的 user namespace)。有些情况下我们可能需要回到没有开启用户隔离的场景，这时可以通过 --userns=host 参数为单个的容器禁用用户隔离功能。--userns=host 参数主要给下面三个命令使用：

```shell
docker container create
docker container run
docker container exec
```

​	比如执行下的命令：

```shell
$ docker run -d --userns=host --name sleepme ubuntu sleep infinity
```

​	查看进程信息：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909173448628-850305296.png)

​	进程的有效用户又成 root 了，并且也没有为进程创建新的 user namespace：

![img](https://images2018.cnblogs.com/blog/952033/201809/952033-20180909173516911-208165754.png)

## 已知问题

​	User namespace 属于比较高级的功能，目前 docker 对它的支持还算不上完美，下面是已知的几个和现有功能不兼容的问题：

- 共享主机的 PID 或 NET namespace(--pid=host or --network=host)
- 外部的存储、数据卷驱动可能不兼容、不支持 user namespace
- 使用 --privileged 而不指定 --userns=host



## CentOS7.4中配置docker user namespace

1. 安装docker

```shell
$ yum install docker
```

2. 以用户shannyn（uid：1000，gid：1000）为例配置docker user namespace，在/etc/docker/daemon.json中，输入下面内容：

```json
{
	"userns-remap": "shannyn"
}
```

3. 需要把host的uid和gid跟docker容器内的uid、gid做一个对应：

```shell
$ echo "shannyn:1000:65536" >> /etc/subuid
$ echo "shannyn:1000:65536" >> /etc/subuid
```

​	**意思是容器内id为0的用户，将会映射到host上id为1000的用户，后面65536个用户也会跟着做映射。**

4. 把shannyn用户加入到docker群组里：

```shell
$ sudo usermod -aG docker shannyn
```

5. CentOS7的kernel默认关闭了user namespace，需要重新打开

```shell
$ grubby --args="namespace.unpriv_enable=1 user_namespace.enable=1" --update-kernel="$(grubby --default-kernel)"

$ echo "user.max_user_namespaces=15076" >> /etc/sysctl.conf

$ reboot
```



6. 启动docker

```shell
$ systemctl restart docker
```



7. 检查容器用户是否映射成功



## 总结

​	Docker 是支持 user namespace 的，并且配置的方式也非常简便。在开启 user namespace 之后我们享受到了安全性的提升，但同时也会因为种种限制让其它的个别功能出现问题。这时我们需要作出选择，告别一刀切的决策，让合适的功能出现的合适的场景中。

