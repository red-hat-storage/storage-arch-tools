#!/bin/bash

# Passwordless ssh to all servers and clients is required

# iperf3 command setup
# Location of the iperf3 binary
iperf3="/usr/bin/iperf3"
# How often to report in seconds
ipreport=60
# How long to run the test in seconds
ipruntime=600
# How many client threads to run
ipthreads=10

# We automatically store our outputs in git repo branches. The repo should already exist at the below path.
repopath="/path/to/git/repo/for/results/output"

# We typically keep benchmark binaries in /root/bin
PATH="$PATH:/root/bin"

# How many times to run each test
iterations=1

# Whether to run the test in bidirectional mode. If your servers and clients lists overlap, then you might want to set this to false.
bidirectional=true

# Note: The "servers" will run the iperf3 server daemon, and the "clients" will run the iperf3 client commands to connect to those daemons. Think of the "servers" as destination and the "clients" as source.

# Starting host numeration for iperf servers (s) and clients (c)
s=0
c=0

# Hostname prefixes
sprefix="server"
cprefix="client"

# Total numbers of iperf servers and clients
numservers=12
numclients=6

# Calculation of last iperf server and client host numbers.
# This assumes integer enumeration of hosts (ie server{0..11}).
lastserver=$(echo "$s+$numservers-1" | bc)
lastclient=$(echo "$c+$numclients-1" | bc)


# For each client system
for client in $(seq ${c} ${lastclient}); do
  echo "Initiating tests from ${cprefix}${client}..."
  # Run one-to-one full mesh tests with servers
  for server in $(seq ${s} ${lastserver}); do
    # But we don't want to test against ourself
    if [ "${sprefix}${server}" != "${cprefix}${client}" ]; then
      echo "Beginning test from ${cprefix}${client} to ${sprefix}${server}..."
      # We use a test naming convention with "sections" broken by -- which we parse below into our git branches
      testname="iperf--bidirectional-n${server}-c${client}--1-10gbe-10-min-10-proc"
      tool=`echo ${testname} | awk -F-- '{print $1}'`
      test=`echo ${testname} | awk -F-- '{print $2}'`
      testconfig=`echo ${testname} | awk -F-- '{print $3}'`
      gitrepo="${tool}/${test}/${testconfig}"
      workload="${iperf3} -c ${sprefix}${server} -i ${ipreport} -t ${ipruntime} -P ${ipthreads}"

      echo "Changing to ${repopath} working directory..."
      cd ${repopath}
      echo "Checking out git repository ${gitrepo}..."
      git checkout ${gitrepo} 2>/dev/null || git checkout -b ${gitrepo} master

      i=1
      while [ $i -le ${iterations} ]; do
        # Ensure iperf3 server process is runnning
        echo "Starting iperf3 server daemon on ${sprefix}${server}..."
        ssh root@${sprefix}${server} "pkill -9 iperf; pkill -9 iperf3; /usr/bin/iperf3 -s -D"

        # Initiate workload
        cmd="${workload}"
        if [ "${bidirectional}" = true ]; then cmd="${cmd} && ${workload} -R"; fi
        echo "Client workload is '${cmd}'"
        echo "Initiating workload iteration ${i} of ${iterations}..."
        ssh -t root@${cprefix}${client} "${cmd}" | tee -a ${testname}-$(date +%F-%H-%M-%S).results >/dev/null 2>&1

        i=$[$i+1]
      done

      "Adding and committing results file to git repo..."
      git add *
      git commit -am "${testname} $(date)"
    else
      echo "Skipping test against self (${cprefix}${client} to ${sprefix}${server})..."
    fi
    echo "Test complete for ${cprefix}${client} to ${sprefix}${server}..."
    server=$[$server+1]
  done
  echo "All tests complete from ${cprefix}${client}..."
  client=$[$client+1]
done

echo "All iperf3 tests now complete! Cleaning up..."

# Stop all iperf server processes
for server in $(seq ${s} ${lastserver}); do
  echo "Stopping all iperf3 server processes..."
  ssh root@${sprefix}${server} "pkill -9 iperf; pkill -9 iperf3"
done
