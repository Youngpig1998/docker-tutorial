# 基于Docker部署Go项目

## 环境准备

1. Docker安装：参考我的上一篇文章[Docker安装以及服务相关命令](../lesson1)。

2. 配置docker镜像加速     ps:有不同的镜像加速地址，如阿里云加速器等等。

   ```shell
   vim  /etc/docker/daemon.json
   ```

    只要安装了docker服务的最好都配置一下

   ​	json文件内容如下：

   ```json
   {
     "registry-mirrors": ["https://tzksttqp.mirror.aliyuncs.com"]
   }
   ```

   ```shell
   #加载配置文件并重启Docker服务
   systemctl daemon-reload
   systemctl restart docker
   ```

3. Go项目代码准备

​	基于golang最流行的Web框架Gin，搭建一个最简单的Web服务，大家可以下载[zip包](https://github.com/jincheng9/disributed-system-notes/archive/refs/heads/main.zip)，或者使用git下载源码：

```bash
$ git clone git@github.com:jincheng9/disributed-system-notes.git
```

​	下载后，用Goland或其它IDE打开`./go-docker-demo`目录。

​	在该目录下执行如下2条命令，服务正常启动后，会监听8080端口

```bash
$ go build main.go
$ ./main
```

​	在浏览器上输入[http://localhost:8080/hello](http://localhost:8080/hello)，如果有输出如下结果，就表示一切准备就绪了。

```markdown
{
	"msg": "world"
}
```



## 创建Dockerfile

在`go-docker-demo`目录下，创建文件`Dockerfile`，文件名全称就叫`Dockerfile`，没有后缀。

`Dockerfile`文件内容为：

```dockerfile
FROM golang:latest

WORKDIR /app/demo
COPY . .

RUN go build main.go

EXPOSE 8080
ENTRYPOINT ["./main"]
```

`FROM`: 指定基础镜像。我们的项目需要用到Go，所以指定golang的最新版本为基础镜像

`WORKDIR`：指定本项目在容器里的工作目录或者说存储位置。设置了`WORKDIR`后，`Dockerfile`里后续的指令如果要使用容器里的路径，就可以根据`WORKDIR`来使用相对路径了。

`COPY`：把执行`docker build`指定的目录下的某些文件或目录拷贝到容器的指定路径下。例子里的第一个`.`表示`docker build`指定的当前目录，第二个`.`表示容器的当前工作目录`WORKDIR`，该指令表示把`docker build`指定的目录下的所有内容(包括子目录下的文件)全部拷贝到容器的`/app/demo`目录下。

`RUN`：在指定的容器工作目录执行命令。例子表示在`WORKDIR`下执行`go build main.go`，会生成`main`二进制文件。

`EXPOSE`：声明容器要使用的端口。

`ENTRYPOINT`：指定容器的启动程序和参数。

Dockerfile文件语法指引：https://docs.docker.com/engine/reference/builder/



## 构建镜像

在`go-docker-demo`目录下，执行如下命令来构建镜像：

```bash
$ docker build -t go-docker-demo .
```

执行完成后，使用`docker image ls`可以查看到`REPOSITORY`为`go-docker-demo`的镜像文件。



## 运行容器

执行如下命令，启动容器：

```bash
$ docker run -d -p 8080:8080 go-docker-demo
```

成功执行后，该命令会返回类似`2b7a47d1e24265e638a2b931561a303f97463fac9d9f5fa5a9f9b77b2212fa24`这样的字符串，这个是运行的容器的ID，也叫container id。

在浏览器上输入[http://localhost:8080/hello](http://localhost:8080/hello)，如果有输出如下结果，就表示大功告成了。

```markdown
{
	"msg": "world"
}
```

​	-p 端口映射           **-P是随机端口映射（限于DOCKERFILE中有EXPOSE命令的）**

  （1）前面是宿主机的端口，后面是容器的端口    

  （2）还可以在宿主机端口前面加上IP地址，如：docker run -d -p 192.168.184.8:80:80  这个的用法就是可以在宿主机上配多个公网ip，每个ip都开发80端口给外网客户。

  （3）-p ip::80  这里省略了宿主机端口号。端口号会随机分配

​			**sysctl -a | grep net.ipv4 |grep 'range' 查看端口号分配范围。**

  （4）-p 80:80:udp   如：-p 192.268.184.8::53:udp  将该ip地址上的一个随机端口映射到容器的53端口，走的是udp协议

  **（5）-p 81:80 -p 443:443  可以指定多个-p**



## 容器长啥样

通过`docker exec -it go-docker-demo /bin/bash` 命令进入容器`go-docker-demo`。

分别执行`pwd`, `ls`命令，就能以容器的视角看到当前容器里的文件目录结构。

```bash
# pwd
/app/demo
# ls
Dockerfile  go.mod  go.sum  main  main.go
# curl http://127.0.0.1:8080/hello            
{"msg":"world"}
# ls /
app  boot  etc	home  lib64  mnt  proc	run   srv  tmp	var
bin  dev   go	lib   media  opt  root	sbin  sys  usr
```

容器是被隔离的进程，有自己的文件系统、网络和进程树。



## References

*  https://docs.docker.com/engine/reference/builder/ 
*  https://eddycjy.com/posts/go/gin/2018-03-24-golang-docker/





