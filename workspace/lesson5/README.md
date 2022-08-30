# 容器的端口映射机制

​	`docker run -d centos:6.9 tail -f /etc/hosts`    后面一行命令可以让centos一直在后台运行，所以容器不会挂掉。

​	只要一启动docker服务，宿主机的网卡上就会多出一个docker0网卡。

​	在docker容器内开启的服务器服务，通过外网是无法直接访问的，只有宿主机可以访问，所以需要做一个端口映射。  iptables命令可以手动映射（在宿主机中设置）。

​	最好是在docker run的时候加入-p参数指定端口

​	`sysctl -a | grep ipv4 | grep forward` 	  **查看内核转发参数值**

​	`systemctl status docker` 							**查看docker服务状态**

​	**重点：在每次启动docker服务时，内核转发参数会被设为1，然而当虚拟机被挂起后再开机，该值会自动变为0，然而docker仍在运行中，但是容器已经上不了网了。**

​	`sysctl net.ipv4.ip_forward=1`  将内核转发参数设为1

​	**`netstat -lntup` 查看端口监听状况**