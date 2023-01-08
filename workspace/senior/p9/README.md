# Dockerfile 中的 CMD 与 ENTRYPOINT

​	CMD 和 ENTRYPOINT 指令都是用来指定容器启动时运行的命令。
​	单从功能上来看，这两个命令几乎是重复的。单独使用其中的一个就可以实现绝大多数的用例。但是既然 docker 同时提供了它们，为了在使用中不至于混淆，本文试图把它们的用法理清楚。

## exec 模式和 shell 模式 

​	CMD 和 ENTRYPOINT 指令都支持 exec 模式和 shell 模式的写法，所以要理解 CMD 和 ENTRYPOINT 指令的用法，就得先区分 exec 模式和 shell 模式。这两种模式主要用来指定容器中的不同进程为 1 号进程。了解 linux 的朋友应该清楚 1 号进程在系统中的重要地位。

### exec 模式

​	使用 exec 模式时，容器中的任务进程就是容器内的 1 号进程，看下面的例子：

```dockerfile
FROM ubuntu
CMD [ "top" ]
```

​	把上面的代码保存到 test1 目录的 Dockerfile 中，然后进入 test1 目录构建镜像并启动一个容器：

```shell
$ docker build -t test1 .
$ docker run -idt --name testcon test1
```

​	然后查看容器中的进程 ID：

```shell
$ docker exec testcon ps aux
```

![img](https://images2018.cnblogs.com/blog/952033/201802/952033-20180223130211589-1153779778.png)

​	从图中我们看到运行 top 命令的进程 ID 为 1。
​	**exec 模式是建议的使用模式，因为当运行任务的进程作为容器中的 1 号进程时，我们可以通过 docker 的 stop 命令优雅的结束容器**。

​	**exec 模式的特点是不会通过 shell 执行相关的命令，所以像 $HOME 这样的环境变量是取不到的**：

```dockerfile
FROM ubuntu
CMD [ "echo", "$HOME" ]
```

​	把上面的代码保存到 test1 目录的 Dockerfile 中，然后进入 test1 目录构建镜像并启动一个容器：

```shell
$ docker build --no-cache -t test1 .
$ docker run --rm test1
```

![img](https://images2018.cnblogs.com/blog/952033/201802/952033-20180223130421899-425658453.png)

​	通过 exec 模式执行 shell 可以获得环境变量：

```dockerfile
FROM ubuntu
CMD [ "sh", "-c", "echo $HOME" ]
```

​	把上面的代码保存到 test1 目录的 Dockerfile 中，然后进入 test1 目录构建镜像并启动一个容器：

```shell
$ docker build --no-cache -t test1 .
$ docker run --rm test1
```

![img](https://images2018.cnblogs.com/blog/952033/201802/952033-20180223130529482-988600776.png)

​	这次正确取到了 $HOME 环境变量的值。

### shell 模式

​	使用 shell 模式时，docker 会以 /bin/sh -c "task command" 的方式执行任务命令。也就是说容器中的 1 号进程不是任务进程而是 bash 进程，看下面的例子：

```dockerfile
FROM ubuntu
CMD top
```

​	把上面的代码保存到 test2 目录的 Dockerfile 中，然后进入 test2 目录构建镜像并启动一个容器：

```shell
$ docker build -t test2 .
$ docker run -itd --name testcon2 test2
```

​	然后查看容器中的进程 ID：

```shell
$ docker exec testcon2 ps aux
```

![img](https://images2018.cnblogs.com/blog/952033/201802/952033-20180223130735006-594451977.png)

​	1 号进程执行的命令居然是 /bin/sh -c top。而我们指定的 top 命令的进程 ID 为 7。这是由 docker 内部决定的，目的是让我们执行的命令或者脚本可以取到环境变量。

## CMD 指令

​	CMD 指令的目的是：为容器提供默认的执行命令。
​	CMD 指令有三种使用方式，其中的一种是为 ENTRYPOINT 提供默认的参数：
​	**CMD ["param1","param2"]**
​	另外两种使用方式分别是 exec 模式和 shell 模式：
​	**CMD ["executable","param1","param2"]**  // 这是 exec 模式的写法，注意需要使用双引号。
​	**CMD command param1 param2**         // 这是 shell 模式的写法。
​	注意命令行参数可以覆盖 CMD 指令的设置，但是只能是重写，却不能给 CMD 中的命令通过命令行传递参数。
​	一般的镜像都会提供容器启动时的默认命令，但是有些场景中用户并不想执行默认的命令。用户可以通过命令行参数的方式覆盖 CMD 指令提供的默认命令。比如通过下面命令创建的镜像：

```dockerfile
FROM ubuntu
CMD [ "top" ]
```

​	在启动容器时我们通过命令行指定参数 ps aux 覆盖默认的 top 命令：

![img](https://images2018.cnblogs.com/blog/952033/201802/952033-20180223130944593-1511091543.png)

​	从上图可以看到，命令行上指定的 ps aux 命令覆盖了 Dockerfile 中的 CMD [ "top" ]。实际上，命令行上的命令同样会覆盖 shell 模式的 CMD 指令。

​	在指令格式上，一般推荐使用 `exec` 格式，这类格式在解析时会被解析为 JSON 数组，因此一定要使用双引号 `"`，而不要使用单引号。

​	如果使用 `shell` 格式的话，实际的命令会被包装为 `sh -c` 的参数的形式进行执行。比如：

```dockerfile
CMD echo $HOME
```

​	在实际执行中，会将其变更为：

```dockerfile
CMD [ "sh", "-c", "echo $HOME" ]
```

​	这就是为什么我们可以使用环境变量的原因，因为这些环境变量会被 shell 进行解析处理。

​	提到 `CMD` 就不得不提容器中应用在前台执行和后台执行的问题。这是初学者常出现的一个混淆。Docker 不是虚拟机，容器中的应用都应该以前台执行，而不是像虚拟机、物理机里面那样，用 `systemd` 去启动后台服务，容器内没有后台服务的概念。一些初学者将 `CMD` 写为：

```dockerfile
CMD service nginx start
```

​	然后发现容器执行后就立即退出了。甚至在容器内去使用 `systemctl` 命令结果却发现根本执行不了。这就是因为没有搞明白前台、后台的概念，没有区分容器和虚拟机的差异，依旧在以传统虚拟机的角度去理解容器。对于容器而言，其启动程序就是容器应用进程，容器就是为了主进程而存在的，主进程退出，容器就失去了存在的意义，从而退出，其它辅助进程不是它需要关心的东西。

​	而使用 `service nginx start` 命令，则是希望 upstart 来以后台守护进程形式启动 `nginx` 服务。而刚才说了 `CMD service nginx start` 会被理解为 `CMD [ "sh", "-c", "service nginx start"]`，因此主进程实际上是 `sh`。那么当 `service nginx start` 命令结束后，`sh` 也就结束了，`sh` 作为主进程退出了，自然就会令容器退出。正确的做法是直接执行 `nginx` 可执行文件，并且要求以前台形式运行。比如：

```dockerfile
CMD ["nginx", "-g", "daemon off;"]
```

## ENTRYPOINT 指令

​	ENTRYPOINT 指令的目的也是为容器指定默认执行的任务。
​	ENTRYPOINT 指令有两种使用方式，就是我们前面介绍的 exec 模式和 shell 模式：
​	**ENTRYPOINT ["executable", "param1", "param2"]**  // 这是 exec 模式的写法，注意需要使用双引号。
​	**ENTRYPOINT command param1 param2**          // 这是 shell 模式的写法。
​	exec 模式和 shell 模式的基本用法和 CMD 指令是一样的，下面我们介绍一些比较特殊的用法。

​	**指定 ENTRYPOINT 指令为 exec 模式时，命令行上指定的参数会作为参数添加到 ENTRYPOINT 指定命令的参数列表中。**用下面的代码构建镜像 test1：

```do
FROM ubuntu
ENTRYPOINT [ "top", "-b" ]
```

​	运行下面的命令：

```shell
$ docker run --rm test1 -c
```

![img](https://images2018.cnblogs.com/blog/952033/201802/952033-20180223131125462-1226384921.png)

​	我们在命令行上添加的参数被追加到了 top 命令的参数列表中。

​	**由 CMD 指令指定默认的可选参数：**

```dockerfile
FROM ubuntu
ENTRYPOINT [ "top", "-b" ]
CMD [ "-c" ]
```

​	使用这段代码构建镜像 test2 并不带命令行参数启动容器：

```shell
$ docker run --rm test2
```

​	这时容器中运行的命令为：top -b -c。
​	如果我们指定命令行参数：

```shell
$ docker run --rm test2 -n 1
```

​	-n 1 会覆盖 通过 CMD [ "-c" ] 指定的参数，容器执行的命令为：top -b -n 1

![img](https://images2018.cnblogs.com/blog/952033/201802/952033-20180223131251202-140384117.png)

​	注意上图的输出显示 -c 参数被覆盖了。

​	**指定 ENTRYPOINT 指令为 shell 模式时，会完全忽略命令行参数：**

```dockerfile
FROM ubuntu
ENTRYPOINT echo $HOME 
```

​	把上面的代码编译成镜像 test2，分别不带命令行参数和使用命令行参数 ls 执行命令：

![img](https://images2018.cnblogs.com/blog/952033/201802/952033-20180223131407554-1561884995.png)

​	我们看到 ls 命令没有被执行，这说明命令行参数被 ENTRYPOINT 指令的 shell 模式忽略了。

​	**覆盖默认的 ENTRYPOINT 指令：**
​	ENTRYPOINT 指令也是可以被命令行覆盖的，只不过不是默认的命令行参数，而是需要显式的指定 --entrypoint 参数。比如我们通过下面的方式覆盖上面镜像中的 echo $HOME 命令：

```shell
$ docker run --rm --entrypoint hostname test2
```

![img](https://images2018.cnblogs.com/blog/952033/201802/952033-20180223131500161-1384881659.png)

​	这里我们使用 hostname 命令覆盖了默认的 echo $HOME 命令。

### 场景：应用运行前的准备工作

​	启动容器就是启动主进程，但有些时候，启动主进程前，需要一些准备工作。比如 `mysql` 类的数据库，可能需要一些数据库配置、初始化的工作，这些工作要在最终的 mysql 服务器运行之前解决。此外，可能希望避免使用 `root` 用户去启动服务，从而提高安全性，而在启动服务前还需要以 `root` 身份执行一些必要的准备工作，最后切换到服务用户身份启动服务。或者除了服务外，其它命令依旧可以使用 `root` 身份执行，方便调试等。

​	这些准备工作是和容器 `CMD` 无关的，无论 `CMD` 为什么，都需要事先进行一个预处理的工作。这种情况下，可以写一个脚本，然后放入 `ENTRYPOINT` 中去执行，而这个脚本会将接到的参数（也就是 `<CMD>`）作为命令，在脚本最后执行。比如官方镜像 `redis` 中就是这么做的：

```dockerfile
FROM alpine:3.4
...
RUN addgroup -S redis && adduser -S -G redis redis
...
ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 6379
CMD [ "redis-server" ]
```

​	可以看到其中为了 redis 服务创建了 redis 用户，并在最后指定了 `ENTRYPOINT` 为 `docker-entrypoint.sh` 脚本。

```shell
#!/bin/sh

...

\# allow the container to be started with `--user`

if [ "$1" = 'redis-server' -a "$(id -u)" = '0' ]; then
	find . \! -user redis -exec chown redis '{}' +
	exec gosu redis "$0" "$@"
fi

exec "$@"
```

​	该脚本的内容就是根据 `CMD` 的内容来判断，如果是 `redis-server` 的话，则切换到 `redis` 用户身份启动服务器，否则依旧使用 `root` 身份执行。比如：

```shell
$ docker run -it redis id
uid=0(root) gid=0(root) groups=0(root)
```



## Dockerfile 中至少要有一个

​	如果镜像中既没有指定 CMD 也没有指定 ENTRYPOINT 那么在启动容器时会报错。这不算是什么问题，因为现在能见到的绝大多数镜像都默认添加了 CMD 或 ENTRYPOINT 指令。

## 指定任意一个，效果差不多

​	从结果上看，CMD 和 ENTRYPOINT 是一样的，我们可以通过它们实现相同的目的。下面我们分别用 CMD 和 ENTRYPOINT 设置 top -b 命令，然后观察容器运行时的 metadata 信息：

![img](https://images2018.cnblogs.com/blog/952033/201802/952033-20180223131618500-870134564.png)

或者：

![img](https://images2018.cnblogs.com/blog/952033/201802/952033-20180223131645158-1706317623.png)

​	虽然实现方式不同，但最终容器运行的命令是一样的。

## 同时使用 CMD 和 ENTRYPOINT 的情况

​	对于 CMD 和 ENTRYPOINT 的设计而言，多数情况下它们应该是单独使用的。当然，有一个例外是 CMD 为 ENTRYPOINT 提供默认的可选参数。
​	我们大概可以总结出下面几条规律：
  	 • 如果 ENTRYPOINT 使用了 shell 模式，CMD 指令会被忽略。
​	   • 如果 ENTRYPOINT 使用了 exec 模式，CMD 指定的内容被追加为 ENTRYPOINT 指定命令的参数。
​	   • 如果 ENTRYPOINT 使用了 exec 模式，CMD 也应该使用 exec 模式。
​	真实的情况要远比这三条规律复杂，好在 docker 给出了官方的解释，如下图所示：

![img](https://images2018.cnblogs.com/blog/952033/201802/952033-20180223131745112-1674454515.png)

​	当我们无法理解容器中运行命令的行为时，说不定通过这个表格可以解开疑惑！

## 总结

​	对于 Dockerfile 来说，CMD 和 ENTRYPOINT 是非常重要的指令。它们不是在构建镜像的过程中执行，而是在启动容器时执行，所以主要用来指定容器默认执行的命令。但是提供两个功能类似的指令，必然会给用户带来理解上的困惑和使用中的混淆。希望本文能够帮助大家理解二者的区别与联系，并更好的使用二者。

