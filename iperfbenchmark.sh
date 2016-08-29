#!/bin/bash

# Passwordless ssh to all servers and clients is required

# We automatically store our outputs in git repo branches. The repo should already exist at the below path.
repopath=/path/to/git/repo/for/results/output
# We typically keep benchmark binaries in /root/bin
PATH=$PATH:/root/bin
# How many times to run each test
iterations=1

# Starting host numeration for clients (c) and servers (s)
c=0
s=0

# Hostname prefixes
cprefix="client"
sprefix="server"

# Total numbers of clients and servers
numclients=12
numservers=6

# Calculation of last client and server host numbers. This assumes integer enumeration of hosts (ie client{0..11}).
lastclient=$(echo "$c+$numclients-1" | bc)
lastserver=$(echo "$s+$numservers-1" | bc)


# In this example, we have 6 server nodes named server0 through server5
# In this example, we have 12 client nodes named client0 through client11
for server in $(seq ${s} ${lastserver}); do
  # Run one-to-one full mesh tests
  for client in $(seq ${c} ${lastclient}); do
    # We use a test naming convention with "sections" broken by -- which we parse below into our git branches
    testname=iperf--bidirectional-n${server}-c${client}--1-10gbe-10-min-10-proc
    tool=`echo ${testname} | awk -F-- '{print $1}'`
    test=`echo ${testname} | awk -F-- '{print $2}'`
    testconfig=`echo ${testname} | awk -F-- '{print $3}'`
    workload="/usr/bin/iperf3 -c ${cprefix}${client} -i 60 -t 600 -P 10"

    cd ${repopath}
    git checkout ${tool}/${test}/${testconfig} 2>/dev/null || git checkout -b ${tool}/${test}/${testconfig} master

    i=0
    while [ $i -lt ${iterations} ]; do
      # Ensure iperf3 server process is runnning
      ssh root@${cprefix}${client} "pkill -9 iperf; pkill -9 iperf3; /usr/bin/iperf3 -s -D"

      # Initiate workload
      cmd="${workload} && ${workload} -R"
      ssh -t root@rhosd${server} "$cmd" | tee -a ${testname}.results

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
done
