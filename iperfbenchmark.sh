#!/bin/bash

# Passwordless ssh to all servers and clients is required

# We automatically store our outputs in git repo branches. The repo should already exist at the below path.
repopath=/path/to/git/repo/for/results/output
# We typically keep benchmark binaries in /root/bin
PATH=$PATH:/root/bin
# How many times to run each test
iterations=1

# Starting numeration for clients (c) and servers (s)
c=0
s=0

cprefix="client"
numclients=12
lastclient=$(echo "$c+$numclients-1" | bc)

sprefix="server"
numservers=6
lastserver=$(echo "$s+$numservers-1" | bc)

# In this test, we have 12 client nodes named client0 through client11
for client in $(seq ${c} ${lastclient}); do
  #start iperf server processes
  ssh root@${cprefix}${client} "pkill -9 iperf; pkill -9 iperf3; /usr/bin/iperf3 -s -D"
done

# In this test, we have 6 server nodes named server0 through server5
for server in $(seq ${s} ${lastserver}); do
  # Run one-to-one full mesh tests
  for client in $(seq ${c} ${lastclient}); do
    # We use a naming convention with "sections" broken by -- which we parse below into our git branches
    testname=iperf--bidirectional-n${server}-c${client}--1-10gbe-to-1-1gbe-10-min-10-proc
    tool=`echo ${testname} | awk -F-- '{print $1}'`
    test=`echo ${testname} | awk -F-- '{print $2}'`
    testconfig=`echo ${testname} | awk -F-- '{print $3}'`
    workload="/usr/bin/iperf3 -c ${cprefix}${client} -i 60 -t 600 -P 10"
    #workload="/usr/bin/iperf3 -c ${cprefix}${client} -i 60 -t 10 -P 10"

    cd ${repopath}
    git checkout ${tool}/${test}/${testconfig} 2>/dev/null || git checkout -b ${tool}/${test}/${testconfig} master

    i=0
    while [ $i -lt ${iterations} ]; do
      #cmd="${workload} && ${workload} -R"
      cmd="${workload}"
      ssh root@rhosd${server} "$cmd" | tee -a ${testname}.results
      i=$[$i+1]
    done

    git add *
    git commit -am "${testname} `date`"
    client=$[$client+1]
  done
  server=$[$server+1]
done

for client in $(seq ${c} ${lastclient}); do
  #stop iperf server processes
  ssh root@${cprefix}${client} "pkill -9 iperf; pkill -9 iperf3"
  #ssh root@${cprefix}${client} "hostname; ps -ef | grep iperf"
done
