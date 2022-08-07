# Docker的数据卷管理

​	可以将自己写的代码放入容器镜像中，如放进nginx/tomcat中。

​	1、docker run -d -p 80:80 -v  /opt/xsa:/usr/share/nginx/html   nginx   前者为宿主机目录，后者为nginx放代码的目录。  如果宿主机的目录不存在会自己创建。代码可以直接在宿主机里面改

​	-v 等价于--volume      

​	**-v参数可以像-p参数一样重复使用。挂载目录时如果发现源路径不存在会自动创建，这时就会是一个“坑”，当主机目录被意外删除时会导致容器出现空目录，让应用无法按预想的流程工作。**

​	**-v挂载目录默认是可读可写的，但也可以加上“:ro”变成只读。可以防止容器意外修改文件，例如“-v /tmp:/tmp:ro”**

​	2、docker run -d -p 81:80 -v young:/usr/share/nginx/html nginx

​	当docker第一次见到young时，发现不存在，会创建一个卷。

​	**卷就相当于一个小型磁盘，用来持久化存储数据和代码的。**



## volume相关

```
docker volume inspect [OPTIONS] VOLUME [VOLUME...]:展示一个或多个volume的详细信息

docker volume ls:列出volume

docker volume rm [OPTIONS] VOLUME [VOLUME...]:移除一个或多个volume

docker volume prune [OPTIONS]:移除所有不用的本地volume
```



## 