#!/bin/bash
PATH=$PATH:/root/bin
testname="iozone--large-file-rw--mag-raid6-local-1-node-1-client-12-worker"
tool=`echo ${testname} | awk -F-- '{print $1}'`
test=`echo ${testname} | awk -F-- '{print $2}'`
testconfig=`echo ${testname} | awk -F-- '{print $3}'`
gitrepo="${tool}/${test}"
repopath=/root/git/benchmark-gluster-smci-standard
dropcaches='echo 3 > /proc/sys/vm/drop_caches'
workload='eval $dropcaches && iozone -t 12 -i 0 -+n -s 4G -r 4m -c -e -+z -w -F /rhgs/bricks/iozone01.dat /rhgs/bricks/iozone02.dat /rhgs/bricks/iozone03.dat /rhgs/bricks/iozone04.dat /rhgs/bricks/iozone05.dat /rhgs/bricks/iozone06.dat /rhgs/bricks/iozone07.dat /rhgs/bricks/iozone08.dat /rhgs/bricks/iozone09.dat /rhgs/bricks/iozone10.dat /rhgs/bricks/iozone11.dat /rhgs/bricks/iozone12.dat /rhgs/bricks/iozone13.dat /rhgs/bricks/iozone14.dat /rhgs/bricks/iozone15.dat /rhgs/bricks/iozone16.dat /rhgs/bricks/iozone17.dat /rhgs/bricks/iozone18.dat /rhgs/bricks/iozone19.dat /rhgs/bricks/iozone20.dat /rhgs/bricks/iozone21.dat /rhgs/bricks/iozone22.dat /rhgs/bricks/iozone23.dat /rhgs/bricks/iozone24.dat /rhgs/bricks/iozone25.dat /rhgs/bricks/iozone26.dat /rhgs/bricks/iozone27.dat /rhgs/bricks/iozone28.dat /rhgs/bricks/iozone29.dat /rhgs/bricks/iozone30.dat /rhgs/bricks/iozone31.dat /rhgs/bricks/iozone32.dat /rhgs/bricks/iozone33.dat /rhgs/bricks/iozone34.dat /rhgs/bricks/iozone35.dat /rhgs/bricks/iozone36.dat /rhgs/bricks/iozone37.dat /rhgs/bricks/iozone38.dat /rhgs/bricks/iozone39.dat /rhgs/bricks/iozone40.dat /rhgs/bricks/iozone41.dat /rhgs/bricks/iozone42.dat /rhgs/bricks/iozone43.dat /rhgs/bricks/iozone44.dat /rhgs/bricks/iozone45.dat /rhgs/bricks/iozone46.dat /rhgs/bricks/iozone47.dat /rhgs/bricks/iozone48.dat && eval $dropcaches && iozone -t 12 -i 1 -+n -s 4G -r 4m -c -e -+z -F /rhgs/bricks/iozone01.dat /rhgs/bricks/iozone02.dat /rhgs/bricks/iozone03.dat /rhgs/bricks/iozone04.dat /rhgs/bricks/iozone05.dat /rhgs/bricks/iozone06.dat /rhgs/bricks/iozone07.dat /rhgs/bricks/iozone08.dat /rhgs/bricks/iozone09.dat /rhgs/bricks/iozone10.dat /rhgs/bricks/iozone11.dat /rhgs/bricks/iozone12.dat /rhgs/bricks/iozone13.dat /rhgs/bricks/iozone14.dat /rhgs/bricks/iozone15.dat /rhgs/bricks/iozone16.dat /rhgs/bricks/iozone17.dat /rhgs/bricks/iozone18.dat /rhgs/bricks/iozone19.dat /rhgs/bricks/iozone20.dat /rhgs/bricks/iozone21.dat /rhgs/bricks/iozone22.dat /rhgs/bricks/iozone23.dat /rhgs/bricks/iozone24.dat /rhgs/bricks/iozone25.dat /rhgs/bricks/iozone26.dat /rhgs/bricks/iozone27.dat /rhgs/bricks/iozone28.dat /rhgs/bricks/iozone29.dat /rhgs/bricks/iozone30.dat /rhgs/bricks/iozone31.dat /rhgs/bricks/iozone32.dat /rhgs/bricks/iozone33.dat /rhgs/bricks/iozone34.dat /rhgs/bricks/iozone35.dat /rhgs/bricks/iozone36.dat /rhgs/bricks/iozone37.dat /rhgs/bricks/iozone38.dat /rhgs/bricks/iozone39.dat /rhgs/bricks/iozone40.dat /rhgs/bricks/iozone41.dat /rhgs/bricks/iozone42.dat /rhgs/bricks/iozone43.dat /rhgs/bricks/iozone44.dat /rhgs/bricks/iozone45.dat /rhgs/bricks/iozone46.dat /rhgs/bricks/iozone47.dat /rhgs/bricks/iozone48.dat && rm -f /rhgs/bricks/iozone*.dat'
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
