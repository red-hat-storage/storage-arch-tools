#!/bin/bash
export PATH=$PATH:/root/bin
export RSH="ssh"

function _usage {
  cat <<END

SPEC SFS 2014 benchmark script for Red Hat Software-Defined Storage Architecture Team
  Runs iterations of SfsManager with a standardized set of options and configurable
  values to allow for running extensive loops of the script. Able to output 
  benchmark results to git repositories.

  Note: This thing makes a lot of assumptions. This help output doesn't cover
        everything, so take a look at the script itself before diving too
        deep into things.

Usage: $(basename "${0}") [-g] [-b <SWBUILD | VDA>] [-c <integer>] [-l <integer>] [-e <integer>] [-n <integer>] [-i <integer>]

  -g : Enable output to git (edit the script file to define the git repo)

  -b <SWBUILD | VDA> : Which SPEC SFS 2014 benchmark to run (we only use SWBUILD and VDA)

  -c <integer> : Number of clients to test with

  -l <integer> : Initial load (business metric) applied to the first run 

  -e <integer> : Increase ([e]nlarge) load by this amount each run

  -n <integer> : Number of incremental runs, increasing load for each by -g above

  -i <integer> : Number of idendical test iterations to run

Primary Author/Maintainer: Dustin Black <dustin@redhat.com>

END
}


# Path to the local git repo to use
repopath=/root/git/benchmark-gluster-smci-standard

# SfsManager command path
sfsmanager="python /root/bin/SfsManager"

netmistpath="/root/bin/netmist"

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
servers=(n{0..5})


# Passwordless ssh to all client nodes is required
clients=(c{0..11})
# Set default options below. These can be overridden with command flags
# Enable results output to git (boolean true/false)
gitenable=false

# Which SFS benchmark workload to run
benchmark="VDA"

# Number of clients to test from
# Our standards are 1, 6, and 12
numclients=12

# Number of test iterations to run
iterations=10

# Starting load (business metric) for SFS
load=20

# Increase load by this amount with each run
incrload=20

# Number of runs, increasing load by $incrload for each
numruns=10

# Capture and act on command flags
while getopts ":gb:c:w:l:e:n:i:h" opt; do
  case ${opt} in
    g)
      gitenable=true
      ;;
    b)
      benchmark="${OPTARG}"
      ;;
    c)
      numclients=${OPTARG}
      ;;
    l)
      load=${OPTARG}
      ;;
    e)
      incrload=${OPTARG}
      ;;
    n)
      numruns=${OPTARG}
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


# If we are testing NFS, then this variable will be
# inserted in the $testname and $iopath below
if [ "$testnfs" = true ]; then
  nfs="nfs-"
fi

# The testname text should be modified as needed
testname="sfs2014--$(echo "$benchmark" | tr '[:upper:]' '[:lower:]')-rw--mag-raid6-${gvolname}-tuned1-6-node-2x10gbe-${numclients}-client-${nfs}${load}-${incrload}-${numruns}"

tool=`echo ${testname} | awk -F-- '{print $1}'`
test=`echo ${testname} | awk -F-- '{print $2}'`
testconfig=`echo ${testname} | awk -F-- '{print $3}'`

# Path on the client nodes to which the I/O should be generated
# This should be under the mount point of the tested filesystem
iopath="/rhgs/${nfs}client/${gvolname}/specsfs"

# Ensure iopath exists
echo "Creating client IO path $iopath..."
ssh root@${clients[0]} "mkdir -p $iopath"

# Set namedate variable
timestamp="$(date +%F-%H-%M-%S)"
namedate="${testname}-${timestamp}"

# Path to the rcfile to be passed to SfsManager
rcfile="/tmp/${namedate}.sfs.rc"

# Creating the client list
echo "Creating the client list..."
i=0
while [ $i -lt $numclients ]; do
  clientlist[$i]="${clients[$i]}"
  clientpath[$i]="${clients[$i]}:${iopath}"
  i=$[$i+1]
done

clientmounts="$(echo ${clientpath[@]})"

# Initialize the rcfile
echo "Initializing rc file $rcfile..."
> $rcfile

# Populate the rcfile
echo "Populating rc file $rcfile..."
cat << EOF > $rcfile
BENCHMARK=$benchmark
LOAD=$load
INCR_LOAD=$incrload
NUM_RUNS=$numruns
CLIENT_MOUNTPOINTS=$clientmounts
EXEC_PATH=$netmistpath
USER=root
WARMUP_TIME=300
IPV6_ENABLE=0
PRIME_MON_SCRIPT=
PRIME_MON_ARGS=
NETMIST_LOGS=
PASSWORD=
RUNTIME=300
WORKLOAD_FILE=
OPRATE_MULTIPLIER=
CLIENT_MEM=1g
AGGR_CAP=1g
FILE_SIZE=
DIR_COUNT=10
FILES_PER_DIR=100
UNLINK_FILES=0
LATENCY_GRAPH=1
HEARTBEAT_NOTIFICATIONS=1
DISABLE_FSYNCS=0
USE_RSHRCP=0
BYTE_OFFSET=0
MAX_FD=
PIT_SERVER=
PIT_PORT=
LOCAL_ONLY=0
FILE_ACCESS_LIST=0
SHARING_MODE=0
SOCK_DEBUG=0
TRACEDEBUG=0
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

# Base SfsManager command string and complete workload
sfscmd="$sfsmanager -r $rcfile -s $namedate -b /root/bin/benchmarks.xml -d ./"
workload='_dropcaches && $sfscmd'

# Checkout the git branch for the results output
if [ "$gitenable" = true ]; then
  # Branch name for git commit
  gitbranch="${tool}/${test}"
  echo "Changing to ${repopath} working directory..."
  cd ${repopath}
  if [ $? -ne 0 ]; then
    gitenable=false
    echo "Error changing to ${repopath}; aborting git checkout but continuing with tests..."
    echo "Results files will be placed in ${PWD}..."
  else
    echo "Checking out git branch ${gitbranch}..."
    git checkout ${gitbranch} 2>/dev/null || git checkout -b ${gitbranch} master
  fi
else
  echo "Git disabled; Results files will be placed in ${PWD}..."
fi

##########
# Run the workload iterations
echo "Initiating $iterations test iterations..."
i=1
while [ $i -le ${iterations} ]; do
  echo "Iteration $i running; Output to ${PWD}..."
  cmd="${workload}"
  eval ${cmd}
  #echo ${cmd}
  i=$[$i+1]
done
echo "All test iterations complete!"
##########


#Commit the changes to the git repo
if [ "${gitenable}" != false ]; then
  echo "Adding and committing results files to git repo..."
  git add *
  git commit -am "${testname} $(date)"
fi

echo "Benchmark run complete!"
