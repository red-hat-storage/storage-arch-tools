#!/bin/bash
PATH=$PATH:/root/bin

# Passwordless ssh to all client nodes is required
clients=(rhclient{0..11})

# Number of clients to test from
# Our standards are 1, 6, and 12
numclients=1

# Number of worker threads per client
# Our standards are 1 and 4
numworkers=1
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

# The testname text should be modified as needed
testname="iozone--${sizeword}-file-rw--mag-raid6-rep2-2-node-${numclients}-client-${totalworkers}-worker"

tool=`echo ${testname} | awk -F-- '{print $1}'`
test=`echo ${testname} | awk -F-- '{print $2}'`
testconfig=`echo ${testname} | awk -F-- '{print $3}'`
gitrepo="${tool}/${test}"
repopath=/root/git/benchmark-gluster-smci-standard

dropcaches='echo 3 > /proc/sys/vm/drop_caches'

clusterfile="/tmp/${testname}.$(date +%F-%H-%M-%S).iozone.conf"
#!! insert code to generate $clusterfile

iozonecmd="iozone -t $totalworkers -s $filesize -r $recordsize -+m $clusterfile -c -e -w -+z -+n"

workload='eval $dropcaches && $iozonecmd -i 0 && eval $dropcaches && $iozonecmd -i 1' 
iterations=10

cd ${repopath}
git checkout ${gitrepo} 2>/dev/null || git checkout -b ${gitrepo} master

i=1
while [ $i -le ${iterations} ]; do
  resultsfile="${testname}-$(date +%F-%H-%M-%S).results"
  cmd="${workload}"
  eval ${cmd} | tee -a ${resultsfile}
  i=$[$i+1]
done

git add *
git commit -am "${testname} $(date)"
