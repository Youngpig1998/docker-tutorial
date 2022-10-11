# Dockerfile自动构建Docker镜像

## 自动构建镜像的步骤：

​	1、先手动构建一遍

​	2、编写Dockerfile，可以选择放在/opt下，创建一个名为dockerfile的目录，再在里面创建要创建镜像的目录，将dockerfile放在该文件夹下。

​	3、构建镜像

​		`docker build  -t centos6.9_ssh:v2   /opt/dockerfile/centos6.9_ssh`    

​		**-t 代表指定新镜像的名字**

​		**后面跟的可以是绝对也可以是相对路径。**

​	4、测试

------

​	**问题：在使用Dockerfile进行构建的时候，每一个RUN指令都会新启一个临时的容器并将上一个镜像放入，执行完命令后再重复该操作。所以有的时候一些加速指令会失效，就是因为改的文件会被下一个新的临时容器所覆盖，比如/etc/hosts等文件。**

​	**解决方法：Dockerfile允许将多个命令全写在一个RUN里，这样就可以了。**

​	**具体如下：**

```dockerfile
RUN	[command1] \
	&& [command2] \
	&& [command3]
```

**通用技巧：把这些Shell命令集中到一个脚本文件里，用COPY命令拷贝进去再用RUN来执行：**

```dockerfile
COPY   setup.sh    /tmp/

RUN cd /tmp  && chmod +x setup.sh   \
    &&  ./setup.sh   &&  rm setup.sh
```



------

## Dockerfile的常用指令：

​	1、	FORM

​	2、	LABLE    描述，标签    不重要

​	3、	RUN

​	4、	ADD    与COPY类似.不过如果src是归档文件,则会被自动解压到dest，不会自动解压zip  ;如果src是URL地址,则会下载内容至dest中

​	需要注意的是，`ADD` 指令会令镜像构建缓存失效，从而可能会令镜像构建变得比较缓慢。因此在 `COPY` 和 `ADD` 指令中选择的时候，可以遵循这样的原则，所有的文件复制均使用 `COPY` 指令，仅在需要自动解压缩的场合使用 `ADD`。

​	5、	COPY   **不会自动解压任何压缩包**

​		**拷贝的文件必须是“构建上下文”路径里的，不能随意指定文件。也就是说，如果要从本机向镜像拷贝文件，就必须把这些文件专门放到一个专门的目录，然后在 docker build里制定“构建上下文”到这个目录才行。**

```dockerfile
COPY ./a.txt  /tmp/a.txt 		#把构建上下文里的a.txt拷贝到镜像的/tmp目录
COPY /etc/hosts    /tmp		    #错误！不能使用构建上下文之外的文件
```

​	`COPY` 指令将从构建上下文目录中 `<源路径>` 的文件/目录复制到新的一层的镜像内的 `<目标路径>` 位置。比如：

```dockerfile
COPY package.json /usr/src/app/
```

​	`<源路径>` 可以是多个，甚至可以是通配符，其通配符规则要满足 Go 的 [`filepath.Match`](https://golang.org/pkg/path/filepath/#Match) 规则，如：

```dockerfile
COPY hom* /mydir/
COPY hom?.txt /mydir/
```

​	`<目标路径>` 可以是容器内的绝对路径，也可以是相对于工作目录的相对路径（工作目录可以用 `WORKDIR` 指令来指定）。目标路径不需要事先创建，如果目录不存在会在复制文件前先行创建缺失目录。

​	此外，还需要注意一点，使用 `COPY` 指令，源文件的各种元数据都会保留。比如读、写、执行权限、文件变更时间等。这个特性对于镜像定制很有用。特别是构建相关文件都在使用 Git 进行管理的时候。

​	在使用该指令的时候还可以加上 `--chown=<user>:<group>` 选项来改变文件的所属用户及所属组。

```dockerfile
COPY --chown=55:mygroup files* /mydir/
COPY --chown=bin files* /mydir/
COPY --chown=1 files* /mydir/
COPY --chown=10:11 files* /mydir/
```

​	**如果源路径为文件夹，复制的时候不是直接复制该文件夹，而是将文件夹中的内容复制到目标路径。**

​	6、	WORKDIR   用于指定容器的一个目录， 容器启动时执行的命令会在该目录下执行。为后面的RUN,CMD,ENTRYPOINT,ADD或COPY指令设置镜像中的当前工作目录

​		如果你的 `WORKDIR` 指令使用的相对路径，那么所切换的路径与之前的 `WORKDIR` 有关：

```dockerfile
WORKDIR /a
WORKDIR b
WORKDIR c

RUN pwd
```

​		`RUN pwd` 的工作目录为 `/a/b/c`。

​	7、	VOLUME   设置卷，将指定目录中的文件保存到宿主机的卷中。每启动一个新的容器都会开一个新的卷，名字随机。

​	8、	EXPOSE  用来指定容器中的进程会监听某个端口

​		格式为 `EXPOSE <端口1> [<端口2>...]`。

​		`EXPOSE` 指令是声明容器运行时提供服务的端口，这只是一个声明，在容器运行时并不会因为这个声明应用就会开启这个端口的服务。在 Dockerfile 中写入这样的声明有两个好处，一个是帮助镜像使用者理解这个镜像服务的守护端口，以方便配置映射；另一个用处则是在运行时使用随机端口映射时，也就是 `docker run -P` 时，会自动随机映射 `EXPOSE` 的端口。

​		要将 `EXPOSE` 和在运行时使用 `-p <宿主端口>:<容器端口>` 区分开来。`-p`，是映射宿主端口和容器端口，换句话说，就是将容器的对应端口服务公开给外界访问，而 `EXPOSE` 仅仅是声明容器打算使用什么端口而已，并不会自动在宿主进行端口映射。

​	**9、	CMD      在容器启动时运行指定的命令(多个CMD指令只有最后一个生效,如果docker run之后有参数则会被替换)**

​	**10、	ENTRYPOINT  容器启动后执行的命令（不能被替换），多个ENTRYPOINT指令只有最后一个生效。如果使用了ENTRYPOINT，在镜像后面还是跟了命令，则会变成默认命令的参数。相当于docker run xxx ENTRYPOINT CMD**

​	**11、	ENV   定义环境变量，可被后面的指令使用    具体语法：ENV SSH_PWD 123456 可以设置多个环境变量**

​			它创建的环境变量不仅能够在构建镜像的过程中使用，在容器运行时也能够以环境变量的形式被应用程序使用。

​	12、	HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD /bin/bash /opt/test.sh  健康检查

​			--interval 代表间隔，每隔10秒执行一次脚本

​			--timeout 脚本执行超时时间

​			--retries 脚本失败次数，3次失败，即30秒之后，标记容器为unhealthy

​	13、	ARG   创建变量，不过该变量只能在镜像构建过程中可见，即Dockerfile中，容器运行时不可见。

​		灵活的使用 `ARG` 指令，能够在不修改 Dockerfile 的情况下，构建出不同的镜像。

​		ARG 指令有生效范围，如果在 `FROM` 指令之前指定，那么只能用于 `FROM` 指令中。

```dockerfile
ARG DOCKER_USERNAME=library

FROM ${DOCKER_USERNAME}/alpine
RUN set -x ; echo ${DOCKER_USERNAME}
```

​	使用上述 Dockerfile 会发现无法输出 `${DOCKER_USERNAME}` 变量的值，要想正常输出，你必须在 `FROM` 之后再次指定 `ARG`

```dockerfile
# 只在 FROM 中生效

ARG DOCKER_USERNAME=library


FROM ${DOCKER_USERNAME}/alpine

# 要想在 FROM 之后使用，必须再次指定
ARG DOCKER_USERNAME=library

RUN set -x ; echo ${DOCKER_USERNAME}
```

​	对于多阶段构建，尤其要注意这个问题

```dockerfile
# 这个变量在每个 FROM 中都生效
ARG DOCKER_USERNAME=library

FROM ${DOCKER_USERNAME}/alpine

RUN set -x ; echo 1

FROM ${DOCKER_USERNAME}/alpine

RUN set -x ; echo 2
```

​	14、	USER 	指定运行容器时的用户名或 UID，后续的RUN等指令也会使用指定的用户身份

```dockerfile
USER <user>[:<group>] 
		或
USER <UID>[:<GID>]
```

​	重点

- 使用 USER 指定用户时，可以使用用户名、UID 或 GID，或是两者的组合
- 使用 USER 指定用户后，Dockerfile 中后续的命令 RUN、CMD、ENTRYPOINT 都将使用该用户
- 其中用户名或`ID`是指可以在容器基础镜像中找到的用户。 如果在容器基础镜像中没有创建特定用户，则在`USER`指令之前添加`useradd`命令以添加特定用户。例如，在`Dockerfile`中创建用户：

```dockerfile
RUN useradd -d /home/username -m -s /bin/bash username 
USER username
```

​		如果使用docker run指令时设置了-u uname参数,则将覆盖USER指令设置的用户

​		**注意:** 如果镜像中有容器不需要的用户，请考虑删除它们。
 		删除这些用户后，提交镜像，然后生成新的容器实例以供使用。

​		**Docker容器中推荐以Non root身份启动，这样更安全。当容器中运行的服务不需要管理员权限时，可以先建立一个特定的用户和用户组，为它分配必要的权限，使用 USER 切换到这个用户**

​	15、MAINTAINER author:设置镜像的作者,可以使任意字符串



------



# docker build是如何工作的

​	Dockerfile 必须要经过 docker build 才能生效，所以我们再来看看 docker build 的详细用法。你是否对“构建上下文”这个词感到有些困惑呢？它到底是什么含义呢？我觉得用 Docker 的官方架构图来理解会比较清楚（注意图中与“docker build”关联的虚线）。因为命令行“docker”是一个简单的客户端，真正的镜像构建工作是由服务器端的“Docker daemon”来完成的，所以“docker”客户端就只能把“构建上下文”目录打包上传（显示信息 Sending build context to Docker daemon ），这样服务器才能够获取本地的这些文件。

​	<img src="../img/docker_arch.svg" style="zoom:80%;" />

​	明白了这一点，你就会知道，“构建上下文”其实与 Dockerfile 并没有直接的关系，它其实指定了要打包进镜像的一些依赖文件。而 COPY 命令也只能使用基于“构建上下文”的相对路径，因为“Docker daemon”看不到本地环境，只能看到打包上传的那些文件。

​	但这个机制也会导致一些麻烦，如果目录里有的文件（例如 readme/.git/.svn 等）不需要拷贝进镜像，docker 也会一股脑地打包上传，效率很低。

​	为了避免这种问题，你可以在“构建上下文”目录里再建立一个 .dockerignore 文件，语法与 .gitignore 类似，排除那些不需要的文件。下面是一个简单的示例，表示不打包上传后缀是“swp”“sh”的文件：

```
# docker ignore
*.swp
*.sh
```





# 镜像的分层（复用，节约磁盘空间和内存空间）

​	假设一开始只有一个centos:6.9的基础镜像，在此基础上新提交了一个包含ssh-server服务的镜像（名为centos6.9_ssh），之后又在第二个镜像的基础上新提交了一个包含nginx服务的镜像（名为centos6.9_ssh_nginx)。所以后面一个镜像是依赖于前一个镜像的，而且在后两个镜像中，其实只是包含了一个centos:6.9的id，说白了就是三个镜像在磁盘和内存中都共用一个centos:6.9镜像。

​	而且每个之间都有一个父子的关系，除了最底层的没有父亲，其余的层都有父层

​	上述的现象就会造成在使用Dockerfile构建镜像的时候，有的会走缓存（using cache），有的不会走缓存。所以在dockerfile文件中添加行时，尽量在最后一行加，放越后面越好

​	**Docker镜像分层使用了一种特殊的文件系统，名为overlay2**

​	通过docker iamge inspect 查看镜像的属性，会发现Data中有许多分层的目录。

​	基于该镜像开启一个容器之后，使用inspect查看容器的属性，也会发现Data中也有许多分层的目录。进入Workdir的文件夹下，会发现多出一个merged和diff的文件夹，merged文件夹是将该镜像中许多杂碎的文件（因为该镜像可能有是基于一个镜像构建的）合并在一起，呈现给使用容器的用户（在用户进入容器ls查看到的内容就是merged文件夹下的内容）。如果用户在容器中添加了文件，都会被添加到diff文件夹中。







# 构建Docker 镜像应该遵循哪些原则？

整体原则上，尽量保持镜像功能的明确和内容的精简，要点包括：

1. 尽量选取满足需求但较小的基础系统镜像，建议选择alpine、ubi-minimal等镜像。
2. 清理编译生成文件、安装包的缓存等临时文件。
3. 安装各个软件时候要指定准确的版本号，并避免引入不需要的依赖。
4. 从安全的角度考虑，应用尽量使用系统的库和依赖。
5. 使用Dockerfile创建镜像时候要添加.dockerignore 文件或使用干净的工作目录