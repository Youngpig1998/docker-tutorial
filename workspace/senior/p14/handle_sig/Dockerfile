FROM centos:8.1.1911

COPY ./bin/go-init /
COPY ./bin/c-init-sig /
COPY ./bin/c-init-nosig /
COPY ./init.sh /

RUN chmod +x /init.sh \ 
 && chmod +x /go-init \ 
 && chmod +x /c-init-sig \ 
 && chmod +x /c-init-nosig
