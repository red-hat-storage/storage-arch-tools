#!/bin/bash
export PATH=$PATH:/root/bin
export RSH="ssh"

function _usage {
  cat <<END

Smallfile benchmark script for Red Hat Software-Defined Storage Architecture Team
  Runs iterations of smallfile with a standardized set of options and configurable
  values to allow for running extensive loops of the script. Able to output 
  benchmark results to git repositories.

  Note: This thing makes a lot of assumptions. This help output doesn't cover
        everything, so take a look at the script itself before diving too
        deep into things.

Usage: $(basename "${0}") [-g] [-c <integer>] [-w <integer>] [-f <size>] [-n <size>] [-i <integer>]

  -g : Enable output to git (edit the script file to define the git repo)

  -c <integer> : Number of clients to run workloads

  -w <integer> : Number of workers each client will run

  -f <size> : Size (in KiB) of files for test

  -n <integer> : Number of files for test

  -i <integer> : Number of idendical test iterations to run

Primary Author/Maintainer: Dustin Black <dustin@redhat.com>

END
}


# Path to the local git repo to use
repopath=/root/git/benchmark-gluster-smci-standard

# smallfile command path
smallfile="python /root/bin/smallfile_cli.py"

# Gluster volume name we are testing
gvolname="rep2"

# Set this to true if we are testing the NFS client instead
# of the native client
testnfs=false

#!!FIXME
# This is a client-based script and doesn't generally require
# specific knowledge of the Gluster server-side layout. However,
# we need to drop caches on all server nodes between runs, so 
# we need to build a list of involved servers, preferably
# without having to manually enumerate them in this script.
servers=(rhosd{0..5})


# Passwordless ssh to all client nodes is required
clients=(rhclient{0..11})
# Set default options below. These can be overridden with command flags
# Enable results output to git (boolean true/false)
gitenable=false

# Number of clients to test from
# Our standards are 1, 6, and 12
numclients=12

# Number of worker threads per client
# Our standards are 1, 2, 4, and 8
numworkers=4

# File size (in KB)
# Our standard test file sizes are:
# 4096 (small), 32 (tiny)
filesize=4096

numfiles=2048

# Transaction record size
#recordsize="4m"

# Number of test iterations to run
iterations=10

# Capture and act on command flags
while getopts ":gc:w:f:n:r:i:h" opt; do
  case ${opt} in
    g)
      gitenable=true
      ;;
    c)
      numclients=${OPTARG}
      ;;
    w)
      numworkers=${OPTARG}
      ;;
    f)
      filesize="${OPTARG}"
      ;;
    n)
      numfiles="${OPTARG}"
      ;;
#    r)
#      recordsize="${OPTARG}"
#      ;;
    i)
      iterations=${OPTARG}
      ;;
    h)
      _usage
      exit 1
      ;;
    \?)
      echo "ERROR: Invalid option -${OPTARG}" >&2
      _usage
      exit 1
      ;;
    :)
      echo "ERROR: Option -${OPTARG} requires an argument." >&2
      _usage
      exit 1
      ;;
  esac
done


# Calculate total workers across all clients
totalworkers=$(echo "${numworkers}*${numclients}" | bc)

# Set filesize naming convention
if [ "$filesize" = "32" ]; then
  sizeword="tiny"
elif [ "$filesize" = "4096" ]; then
  sizeword="small"
else
  sizeword="${filesize}k"
fi

# If we are testing NFS, then this variable will be
# inserted in the $testname and $iopath below
if [ "$testnfs" = true ]; then
  nfs="nfs-"
fi

# The testname text should be modified as needed
testname="smallfile--${sizeword}-file-rw--mag-raid6-${gvolname}-2-node-${numclients}-client-${nfs}${totalworkers}-worker"

tool=`echo ${testname} | awk -F-- '{print $1}'`
test=`echo ${testname} | awk -F-- '{print $2}'`
testconfig=`echo ${testname} | awk -F-- '{print $3}'`

# Path on the client nodes to which the I/O should be generated
# This should be under the mount point of the tested filesystem
iopath="/rhgs/${nfs}client/${gvolname}/smallfile"

# Ensure iopath exists
echo "Creating client IO path $iopath..."
ssh root@${clients[0]} "mkdir -p $iopath"

# Set namedate variable
timestamp="$(date +%F-%H-%M-%S)"
namedate="${testname}-${timestamp}"


# Populate the client list
echo "Populating client list..."
i=0
while [ $i -lt $numclients ]; do
  clientlist[$i]=${clients[$i]}
  i=$[$i+1]
done

hostset="$(echo ${clientlist[@]} | sed s/\ /,/g)"


# Command to drop disk caches
dropcachescmd='sync ; echo 3 > /proc/sys/vm/drop_caches'

# Function to drop caches on all clients and servers
function _dropcaches {
  for client in $(echo ${clientlist[*]}); do
    ssh root@${client} "eval $dropcachescmd"
  done
  for server in $(echo ${servers[*]}); do
    ssh root@${server} "eval $dropcachescmd"
  done
}

# Base smallfile command string and complete workload
# NOTE: You can encounter problems testing NFS (and likely other protocols)
# when your network-sync-dir is on the NFS share. By default, without the flag,
# this share is in a subdirectory of the --top path. To work around this
# potential problem, we explicitly set in the command below the
# network-sync-dir to the Gluster native client mount point. This way, whether
# we are running our test against the native or NFS client, we don't have to
# worry about this behavior. This DOES in turn assume that the volume is
# mounted at the test master and all clients via the natvie mount point for
# all tests, native or NFS.
# See for more info:
# https://github.com/bengland2/smallfile#use-with-distributed-filesystems
smallfilecmd="$smallfile --threads $numworkers --file-size $filesize --files $numfiles --top $iopath --host-set $hostset --prefix $timestamp --stonewall Y --network-sync-dir /rhgs/client/${gvolname}/smf-shared"
workload='_dropcaches && $smallfilecmd --fsync Y --operation create && _dropcaches && $smallfilecmd --operation read' 

# Checkout the git branch for the results output
if [ "$gitenable" = true ]; then
  # Branch name for git commit
  gitbranch="${tool}/${test}"
  echo "Changing to ${repopath} working directory..."
  cd ${repopath}
  if [ $? -ne 0 ]; then
    gitenable=false
    echo "Error changing to ${repopath}; aborting git checkout but continuing with tests..."
    echo "Results files will be placed in $PWD..."
  else
    echo "Checking out git branch ${gitbranch}..."
    git checkout ${gitbranch} 2>/dev/null || git checkout -b ${gitbranch} master
  fi
else
  echo "Git disabled; Results files will be placed in $PWD..."
fi

##########
# Run the workload iterations
echo "Initiating $iterations test iterations..."
resultsfile="${namedate}.results"
i=1
while [ $i -le ${iterations} ]; do
  echo "Iteration $i running; Output to ${resultsfile}..."
  cmd="${workload}"
  eval ${cmd} | tee -a ${resultsfile}
  #echo ${cmd}
  # Clean up the files
  echo "Cleaning up the files..."
  smallfilecleanup="$smallfilecmd --operation cleanup"
  eval $smallfilecleanup >/dev/null 2>&1
  i=$[$i+1]
done
echo "All test iterations complete!"
##########


#Commit the changes to the git repo
if [ "${gitenable}" != false ]; then
  echo "Adding and committing results file to git repo..."
  git add *
  git commit -am "${testname} $(date)"
fi

echo "Benchmark run complete!"
