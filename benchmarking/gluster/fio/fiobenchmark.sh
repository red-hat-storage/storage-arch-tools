#!/bin/bash
export PATH=$PATH:/root/bin
export RSH="ssh"

function _usage {
  cat <<END

FIO benchmark script for Red Hat Software-Defined Storage Architecture Team
  Runs iterations of fio with a standardized set of options and configurable
  values to allow for running extensive loops of the script. Able to output 
  benchmark results to git repositories.

  Note: This thing makes a lot of assumptions. This help output doesn't cover
        everything, so take a look at the script itself before diving too
        deep into things.

Usage: $(basename "${0}") [-g] [-c <integer>] [-w <integer>] [-f <size>] [-r <size>] [-i <integer>]

  -g : Enable output to git (edit the script file to define the git repo)

  -c <integer> : Number of clients to run workloads

  -w <integer> : Number of workers each client will run

  -f <size> : Size (with k, m, g suffix) of files for test

  -r <size> : Size (with k, m, g suffix) of transaction records

  -i <integer> : Number of idendical test iterations to run

Primary Author/Maintainer: Dustin Black <dustin@redhat.com>

END
}


# Path to the local git repo to use
repopath=/root/git/benchmark-gluster-rhs1

# fio command path
fio=/usr/bin/fio

# Gluster volume name we are testing
gvolname="gluster1"

# Set this to true if we are testing the NFS client instead
# of the native client
testnfs=false

#!!FIXME
# This is a client-based script and doesn't generally require
# specific knowledge of the Gluster server-side layout. However,
# we need to drop caches on all server nodes between runs, so 
# we need to build a list of involved servers, preferably
# without having to manually enumerate them in this script.
servers=(n{1..4})


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

# File size
# Our standard test file sizes are:
# 128m (medium), 4g (large), 128g (xlarge), 256g (jumbo1), 512g (jumbo2)
filesize="4g"

# Transaction record size
recordsize="4m"

# Number of test iterations to run
iterations=10

# Capture and act on command flags
while getopts ":gc:w:f:r:i:h" opt; do
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
    r)
      recordsize="${OPTARG}"
      ;;
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
if [ "$filesize" = "128m" ]; then
  sizeword="medium"
elif [ "$filesize" = "4g" ]; then
  sizeword="large"
elif [ "$filesize" = "128g" ]; then
  sizeword="xlarge"
elif [ "$filesize" = "256g" ]; then
  sizeword="jumbo1"
elif [ "$filesize" = "512" ]; then
  sizeword="jumbo2"
else
  sizeword="$filesize"
fi

# If we are testing NFS, then this variable will be
# inserted in the $testname and $iopath below
if [ "$testnfs" = true ]; then
  nfs="nfs-"
fi

# The testname text should be modified as needed
testname="fio--${sizeword}-file-rw--mag-raid6-wb-${gvolname}-tuned1-4-node-2x10gbe-${numclients}-client-${nfs}${totalworkers}-worker"

tool=`echo ${testname} | awk -F-- '{print $1}'`
test=`echo ${testname} | awk -F-- '{print $2}'`
testconfig=`echo ${testname} | awk -F-- '{print $3}'`

# Path on the client nodes to which the I/O should be generated
# This should be under the mount point of the tested filesystem
#iopath="/rhgs/${nfs}client/${gvolname}/fio"
iopath="/mnt/fio"

# Ensure iopath exists
echo "Creating client IO path $iopath..."
ssh root@${clients[0]} "mkdir -p $iopath"

# Path to the cluster file to be passed to fio 
namedate="${testname}-$(date +%F-%H-%M-%S)"
clusterfile="/tmp/${namedate}.fio.list"

# Initialize the clusterfile
echo "Initializing cluster file $clusterfile..."
> $clusterfile

# Populate the clusterfile
echo "Populating cluster file $clusterfile..."
i=0
while [ $i -lt $numclients ]; do
  clientlist[$i]=${clients[$i]}
  i=$[$i+1]
done

for client in $(echo ${clientlist[*]}); do
  echo "$client" | tee -a $clusterfile
done

writejobfile="/tmp/${namedate}.write.jobfile.fio"
readjobfile="/tmp/${namedate}.read.jobfile.fio"

# Initialize job files
echo "Initializing job files..."
> $writejobfile
> $readjobfile
for jobfile in $writejobfile $readjobfile; do
  cat << EOF >> $jobfile
[global]
directory=$iopath
ioengine=sync
#unlink=1
nrfiles=1
iodepth=1
openfiles=1
fsync_on_close=1
group_reporting
startdelay=0
blocksize=$recordsize
filesize=$filesize
numjobs=$numworkers

EOF
done

echo "Creating write job file $writejobfile..."
cat << EOF >> $writejobfile
[seqwrite]
readwrite=write
create_on_open=1
EOF

echo "Creating read job file $readjobfile..."
cat << EOF >> $readjobfile
[seqread]
readwrite=read
EOF

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

# Base fio command string and complete workload
#fiocmd="$fio -t $totalworkers -s $filesize -r $recordsize -+m $clusterfile -c -e -w -+z -+n"
fiocmd="$fio --client=$clusterfile"
workload='_dropcaches && $fiocmd $writejobfile && _dropcaches && $fiocmd $readjobfile' 

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
  eval ${cmd} | tee -a ${resultsfile}.temp
  #echo ${cmd}
  echo "" | tee -a ${resultsfile}.temp
  # Get iteration total throughput
  writeiterations=($(grep WRITE ${resultsfile}.temp | awk '{print $3}' | awk -F= '{print $2}' | awk -FK '{print $1}'))
  writetotal=$(echo ${writeiterations[@]} | sed s/\ /+/g | bc)
  echo "Iteration $i write total throughtput = ${writetotal}" | tee -a ${resultsfile}.temp
  readiterations=($(grep READ ${resultsfile}.temp | awk '{print $3}' | awk -F= '{print $2}' | awk -FK '{print $1}'))
  readtotal=$(echo ${readiterations[@]} | sed s/\ /+/g | bc)
  echo "Iteration $i read total throughtput = ${readtotal}" | tee -a ${resultsfile}.temp
  echo "" | tee -a ${resultsfile}.temp
  cat ${resultsfile}.temp >> ${resultsfile}
  rm -f ${resultsfile}.temp
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
