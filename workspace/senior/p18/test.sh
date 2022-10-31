#!/bin/bash
#在容器中运行
cpuinfo1=$(cat /sys/fs/cgroup/cpu,cpuacct/cpuacct.stat)
utime1=$(echo $cpuinfo1|awk '{print $2}')
stime1=$(echo $cpuinfo1|awk '{print $4}')
sleep 1
cpuinfo2=$(cat /sys/fs/cgroup/cpu,cpuacct/cpuacct.stat)
utime2=$(echo $cpuinfo2|awk '{print $2}')
stime2=$(echo $cpuinfo2|awk '{print $4}')
cpus=$((utime2+stime2-utime1-stime1))
echo "${cpus}%"