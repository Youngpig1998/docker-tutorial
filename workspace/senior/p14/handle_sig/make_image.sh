docker stop sig-proc;docker rm sig-proc
docker rmi youngpig/sig-proc:v1
docker build -t youngpig/sig-proc:v1 .
