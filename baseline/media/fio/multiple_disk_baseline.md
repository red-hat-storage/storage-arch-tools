## Initial Source
"Content of this file has been taken from [Karan's Blog](http://www.ksingh.co.in/blog/2016/05/27/fio-tip-use-genfio-to-quickly-generate-fio-job-files/) "

## Instruction for multi disk benchmarking

FIO provides a utility called as ``genfio`` . As the name suggest it a tool that generates FIO job file based on arguments you provides to it. 

Recently i have been try to benchmarking my server containing 35 disks such that each operation should run in parallel on all disk's and i should get aggregated results for IOPS and Bandwidth. So i used genfio to generate FIO job file and then run fio command line  using the job file 

 - Verify the disk's on which you want to run your benchmark. In my case all disks except ``sda`` 
```
ls /dev/sd{b..z} /dev/sda{a..i}
```
 - Use variable to make your ``genfio`` command short 
```
disk_list=/dev/sdaa,/dev/sdac,/dev/sdae,/dev/sdag,/dev/sdai,/dev/sdc,/dev/sde,/dev/sdg,/dev/sdi,/dev/sdk,/dev/sdm,/dev/sdo,/dev/sdq,/dev/sds,/dev/sdu,/dev/sdw,/dev/sdy,/dev/sdab,/dev/sdad,/dev/sdaf,/dev/sdah,/dev/sdb,/dev/sdd,/dev/sdf,/dev/sdh,/dev/sdj,/dev/sdl,/dev/sdn,/dev/sdp,/dev/sdr,/dev/sdt,/dev/sdv,/dev/sdx,/dev/sdz
```
- So here is ``genfio`` command for exercising 35 disks in parallel with 4K write workload.  Execution of this command will generate  ``.fio`` job file
```
 genfio -d $disk_list -b 4k -r 180 -p -m write
```
- To get aggregated results ( useful in case of multiple drives ) add ``group_reporting=1`` to the ``[global]`` section of ``.fio`` file that is generated in last step.
- Finally start your benchmark by supplying ``.fio`` job file to fio command line.
```
fio node1-4k-parallel-write-sdaa,sdac,sdae,sdag,sdai,sdc,sde,sdg,sdi,sdk,sdm,sdo,sdq,sds,sdu,sdw,sdy,sdab,sdad,sdaf,sdah,sdb,sdd,sdf,sdh,sdj,sdl,sdn,sdp,sdr,sdt,sdv,sdx,sdz.fio
```
Once this command completes look for ``iops``  and ``aggrbw``  which are your aggregate results from multiple disks exercised in parallel. 

> genfio is pretty handy tool for quickly generating FIO job files , without looking up fio command help :)

