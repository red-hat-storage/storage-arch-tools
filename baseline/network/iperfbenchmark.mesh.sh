#!/bin/bash

# Passwordless ssh to all servers and clients is required

# iperf3 command setup
# Location of the iperf3 binary
iperf3="/usr/bin/iperf3"
# How often to report in seconds
ipreport=0
# How long to run the test in seconds
ipruntime=600
# How many client threads to run
ipthreads=10

# We automatically store our outputs in git repo branches. The repo should already exist at the below path.
repopath="/root/git/benchmark-gluster-smci-standard"

# We typically keep benchmark binaries in /root/bin
PATH="$PATH:/root/bin"

# How many times to run each test
iterations=1

# Whether to run the test in bidirectional mode. If your servers and clients lists overlap, then you might want to set this to false.
bidirectional=false

# Note: The "servers" will run the iperf3 server daemon, and the "clients" will run the iperf3 client commands to connect to those daemons. Think of the "servers" as destination and the "clients" as source.

# Starting host numeration for iperf servers (s) and clients (c)
s=0
c=0

# Hostname prefixes
sprefix="n"
cprefix="c"

# Total numbers of iperf servers and clients
numservers=6
numclients=12

# Calculation of last iperf server and client host numbers.
# This assumes integer enumeration of hosts (ie server{0..11}).
lastserver=$(echo "$s+$numservers-1" | bc)
lastclient=$(echo "$c+$numclients-1" | bc)

for server in $(seq $s $lastserver); do
  nodelist[$server]="${sprefix}${server}"
done

for client in $(seq $c $lastclient); do
  nodelist[$lastserver+1+$client]="${cprefix}${client}"
done


echo "Killing any existing iperf processes..."
for node in ${nodelist[*]}; do
  ssh root@${node} "pkill -x -9 iperf; pkill -x -9 iperf3"
done


echo "Starting all iperf3 server daemons..."
for node in ${nodelist[*]}; do
  for port in $(seq 0 $(echo "${#nodelist[@]}-1" | bc)); do
    if [ "${node}" != "${sprefix}${port}" ] && [ "${node}" != "${cprefix}$(echo "${port}-1-${lastserver}" | bc)" ]; then
      port=$(printf "%02d" ${port})
      ssh root@${node} "${iperf3} -s -D -p 52${port}"
    fi
  done
done


portbase=0
for from in ${nodelist[*]}; do
  port="52$(printf "%02d" ${portbase})"
  echo "Initiating sequences from ${from}..."
  for to in ${nodelist[*]}; do
    #if [ "${from}" != "${sprefix}${port}" ] && [ "${from}" != "${cprefix}$(echo "${port}-1-${lastserver}" | bc)" ]; then
      echo "Starting test from ${from} to ${to}..."
      workload="${iperf3} -c ${to} -i ${ipreport} -t ${ipruntime} -P ${ipthreads} -p ${port}"
      cmd="${workload}"
      if [ "${bidirectional}" = true ]; then cmd="${cmd} && ${workload} -R"; fi
      echo "Command is $cmd"
      #ssh -t root@${cprefix}${from} "${cmd}" | tee -a ${resultsfile} >/dev/null 2>&1
      ssh -f root@${from} "nohup ${cmd} &"
    #else
    #  echo "Skipping test to self..."
    #fi
  done
  portbase=$[$portbase+1]
done

sleep $ipruntime

echo "Killing any existing iperf processes..."
for node in ${nodelist[*]}; do
  ssh root@${node} "pkill -x -9 iperf; pkill -x -9 iperf3"
done
