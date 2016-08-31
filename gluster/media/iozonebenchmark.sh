#!/bin/bash
PATH=$PATH:/root/bin

# Enable results output to git (boolean true/false)
gitenable=false

# Path to the local git repo to use
repopath=/root/git/benchmark-gluster-smci-standard

# iozone command path
iozone=/root/bin/iozone

# Passwordless ssh to all client nodes is required
clients=(rhclient{0..11})

# Number of clients to test from
# Our standards are 1, 6, and 12
numclients=6

# Number of worker threads per client
# Our standards are 1 and 4
numworkers=4
totalworkers=$(echo "${numworkers}*${numclients}" | bc)

# File size
# Our standard test file sizes are:
# 128m (medium), 4g (large), 128g (xlarge), 256g (jumbo1), 512g (jumbo2)
filesize="4g"

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

# Transaction record size
recordsize="4m"

# Number of test iterations to run
iterations=10

# The testname text should be modified as needed
testname="iozone--${sizeword}-file-rw--mag-raid6-rep2-2-node-${numclients}-client-${totalworkers}-worker"

tool=`echo ${testname} | awk -F-- '{print $1}'`
test=`echo ${testname} | awk -F-- '{print $2}'`
testconfig=`echo ${testname} | awk -F-- '{print $3}'`

# Path on the client nodes to which the I/O should be generated
# This should be under the mount point of the tested filesystem
iopath="/rhgs/client/rep2/iozone"

# Path to the clusterfile to be passed to iozone
clusterfile="/tmp/${testname}.$(date +%F-%H-%M-%S).iozone.conf"

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
  for worker in $(seq 1 ${numworkers}); do
    echo "$client $iopath $iozone" | tee -a $clusterfile
  done
done


# Command to drop disk caches
dropcaches='echo 3 > /proc/sys/vm/drop_caches'

# Base iozone command string and complete workload
iozonecmd="$iozone -t $totalworkers -s $filesize -r $recordsize -+m $clusterfile -c -e -w -+z -+n"
workload='eval $dropcaches && $iozonecmd -i 0 && eval $dropcaches && $iozonecmd -i 1' 
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
i=1
while [ $i -le ${iterations} ]; do
  resultsfile="${testname}-$(date +%F-%H-%M-%S).results"
  echo "Iteration $i running; Output to ${resultsfile}..."
  cmd="${workload}"
  eval ${cmd} | tee -a ${resultsfile}
  #echo ${cmd}
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
