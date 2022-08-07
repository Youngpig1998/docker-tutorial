# 启动第一个容器

## 直接开启nginx服务

​	配置docker镜像加速     ps:有不同的镜像加速地址，如阿里云加速器等等。

​	**ps：最好使用阿里的，不过缺点是要不定时更新地址。**

​	`vim  /etc/docker/daemon.json`         只要安装了docker服务的最好都配置一下

​	json文件内容如下：

```json
{
  "registry-mirrors": ["https://tzksttqp.mirror.aliyuncs.com"]
}
```

​	systemctl daemon-reload

​	systemctl restart docker

运行命令：`doker run -d -p 80:80 nginx`

​	run(创建并运行一个容器)

​	-d 放在后台运行                 

​	nginx是docker镜像的名字

------

​	-p 端口映射           **-P是随机端口映射（限于DOCKERFILE中有EXPOSE命令的）**

  （1）前面是宿主机的端口，后面是容器的端口    

  （2）还可以在宿主机端口前面加上IP地址，如：docker run -d -p 192.168.184.8:80:80  这个的用法就是可以在宿主机上配多个公网ip，每个ip都开发80端口给外网客户。

  （3）-p ip::80  这里省略了宿主机端口号。端口号会随机分配

​			**sysctl -a | grep net.ipv4 |grep 'range' 查看端口号分配范围。**

  （4）-p 80:80:udp   如：-p 192.268.184.8::53:udp  将该ip地址上的一个随机端口映射到容器的53端口，走的是udp协议

  **（5）-p 81:80 -p 443:443  可以指定多个-p**