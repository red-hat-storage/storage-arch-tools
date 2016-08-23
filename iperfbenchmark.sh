#!/bin/bash

# Passwordless ssh to all servers and clients is required

repopath=/path/to/git/repo/for/results/output
# We typically keep benchmark binaries in /root/bin
PATH=$PATH:/root/bin
# How many times to run each test
iterations=1

# Starting numeration for servers (n) and clients (c)
n=0
c=0

cprefix="client"
numclients=12
lastclient=$(($c+$numcclients-1))

sprefix="server"
numservers=6
lastserver=$(($n+$numservers-1))

# In this test, we have 12 client nodes named client0 through client11
for i in {${c}..${lastclient}}; do
  #start iperf server processes
  ssh root@${cprefix}${i} "pkill -9 iperf; pkill -9 iperf3; /usr/bin/iperf3 -s -D"
done

# In this test, we have 6 server nodes named server0 through server5
for server in {${n}..${lastserver}}; do
#for server in 0; do
  #one-to-one full mesh tests
  for client in {${c}..${lastclient}}; do
  #for clients in 0; do
    testname=iperf--bidirectional-n${server}-c${client}--1-10gbe-to-1-1gbe-10-min-10-proc
    tool=`echo ${testname} | awk -F-- '{print $1}'`
    test=`echo ${testname} | awk -F-- '{print $2}'`
    testconfig=`echo ${testname} | awk -F-- '{print $3}'`
    workload="/usr/bin/iperf3 -c rhclient${client} -i 60 -t 600 -P 10"
    #workload="/usr/bin/iperf3 -c rhclient${client} -i 60 -t 10 -P 10"

    cd ${repopath}
    git checkout ${tool}/${test}/${testconfig} 2>/dev/null || git checkout -b ${tool}/${test}/${testconfig} master

    i=0
    while [ $i -lt ${iterations} ]; do
      cmd="${workload} && ${workload} -R"
      ssh root@rhosd${server} "$cmd" | tee -a ${testname}.results
      i=$[$i+1]
    done

    git add *
    git commit -am "${testname} `date`"
    client=$[$client+1]
  done
  server=$[$server+1]
done

for i in {${c}..${lastclient}}; do
  #stop iperf server processes
  ssh root@rhclient${i} "pkill -9 iperf; pkill -9 iperf3"
  #ssh root@rhclient${i} "hostname; ps -ef | grep iperf"
done
