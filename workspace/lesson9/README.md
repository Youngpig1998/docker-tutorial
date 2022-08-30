# Dockerfile 中的 multi-stage(多阶段构建)

​	在应用了容器技术的软件开发过程中，控制容器镜像的大小可是一件费时费力的事情。如果我们构建的镜像既是编译软件的环境，又是软件最终的运行环境，这是很难控制镜像大小的。所以常见的配置模式为：**分别为软件的编译环境和运行环境提供不同的容器镜像**。比如为编译环境提供一个 Dockerfile.build，用它构建的镜像包含了编译软件需要的所有内容，比如代码、SDK、工具等等。同时为软件的运行环境提供另外一个单独的 Dockerfile，它从 Dockerfile.build 中获得编译好的软件，用它构建的镜像只包含运行软件所必须的内容。这种情况被称为**构造者模式(builder pattern)**，本文将介绍如何通过 Dockerfile 中的 multi-stage 来解决构造者模式带来的问题。

## 常见的容器镜像构建过程

​	比如我们编写了一个GO语言应用。下面我们通过容器来构建它，并把它部署到生产型的容器镜像中。首先构建编译应用程序的镜像：

```dockerfile
FROM golang:1.17.7 as builder

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN export GOPROXY=https://goproxy.cn  \
&&  go mod download

# Copy the go source
COPY main.go main.go
COPY api/ api/
COPY controllers/ controllers/
COPY iaw-shared-helpers/ iaw-shared-helpers/
COPY internal/ internal/

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o manager main.go
```

把上面的内容保存到 Dockerfile.build 文件中。

接着把构建好的应用程序部署到生产环境用的镜像中：

```dockerfile
# Use distroless as minimal base image to package the manager binary
FROM docker.io/redhat/ubi8-minimal:latest
COPY --from=builder /workspace/manager /manager

RUN microdnf install -y shadow-utils \
    && adduser manager  -u 10001 -g 0 \
    && chown manager:root /manager \
    && chmod +x /manager

USER 10001

ENTRYPOINT ["/manager"]
```

​	把上面的内容保存到 Dockerfile 文件中。

​	最后需要使用一个脚本把整个构建过程整合起来：

```sh
#!/bin/sh
echo Building youngpig/audit-operator:build
# 构建编译应用程序的镜像
docker build --no-cache -t youngpig/audit-operator:build . -f Dockerfile.build
# 创建应用程序
docker create --name extract youngpig/audit-operator:build# 拷贝编译好的应用程序
docker cp extract:/go/src/github.com/youngpig/audit-operator/app ./app
docker rm -f extract

echo Building youngpig/audit-operator:latest
# 构建运行应用程序的镜像
docker build --no-cache -t youngpig/audit-operator:latest .
```

​	把上面的内容保存到 build.sh 文件中。这个脚本会先创建出一个容器来构建应用程序，然后再创建最终运行应用程序的镜像。把 go代码、Dockerfile.build、Dockerfile 和 build.sh 放在同一个目录下，然后进入这个目录执行 build.sh 脚本进行构建。构建后的容器镜像大小：

​	根据观察，用于编译应用程序的容器镜像大小接近 2G，而**用于生产环境的容器镜像只有 10.3 M**，这样的大小在网络间传输的效率是很高的。

​	**采用上面的构建过程，我们需要维护两个 Dockerfile 文件和一个脚本文件 build.sh**。能不能简化一些呢？ 下面我们看看 docker 针对这种情况提供的解决方案：multi-stage。



## 在 Dockerfile 中使用 multi-stage

​	multi-stage 允许我们在 Dockerfile 中完成类似前面 build.sh 脚本中的功能，每个 stage 可以理解为构建一个容器镜像，后面的 stage 可以引用前面 stage 中创建的镜像。所以我们可以使用下面单个的 Dockerfile 文件实现前面的需求：

```dockerfile
# Build the manager binary
FROM golang:1.17.7 as builder

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN export GOPROXY=https://goproxy.cn  \
&&  go mod download

# Copy the go source
COPY main.go main.go
COPY api/ api/
COPY controllers/ controllers/
COPY iaw-shared-helpers/ iaw-shared-helpers/
COPY internal/ internal/

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o manager main.go

# Use distroless as minimal base image to package the manager binary
FROM docker.io/redhat/ubi8-minimal:latest
COPY --from=builder /workspace/manager /manager

RUN microdnf install -y shadow-utils \
    && adduser manager  -u 10001 -g 0 \
    && chown manager:root /manager \
    && chmod +x /manager

USER 10001

ENTRYPOINT ["/manager"]

```

​	把上面的内容保存到文件 Dockerfile 中。这个 Dockerfile 文件的特点是同时存在多个 FROM 指令，每个 FROM 指令代表一个 stage 的开始部分。我们可以把一个 stage 的产物拷贝到另一个 stage 中。本例中的第一个 stage 完成了应用程序的构建，内容和前面的 Dockerfile.build 是一样的。第二个 stage 中的 COPY 指令通过 --from=builder 引用了第一个 stage ，并把应用程序拷贝到了当前 stage 中。接下来让我们编译新的镜像：

```shell
$ docker build --no-cache -t youngpig/audit-operator:latest . 
```

## 总结

​	Dockerfile 中的 multi-stage 虽然只是些语法糖，但它确实为我们带来了很多便利。尤其是减轻了 Dockerfile 维护者的负担(要知道实际生产中的 Dockerfile 可不像 demo 中的这么简单)。需要注意的是旧版本的 docker 是不支持 multi-stage 的，只有 17.05 以及之后的版本才开始支持。

