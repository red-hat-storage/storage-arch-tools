# Standard Practices for running Media baseline tests
- Tool selection ( FIO / IOzone ) is upto you , In past we have used
	- FIO for the following projects
		- Ceph P&S SuperMicro
		- Ceph P&S QCT
		- Ceph P&S Dell (730xd , DSS7000 )
		- Gluster P&S QCT
	- IOzone for the following projects
		- Gluster P&S SuperMicro
- After each test run, it's a good idea to drop system cache.
```
# sync; echo 3 > /proc/sys/vm/drop_caches
```
- Make sure you are benchmarking ``Direct IO`` , use appropriate flags for direct IO [ FIO : ``--direct = 1`` ]
- Baselines are usually done on block devices, however you can also baseline filesystems based on your test case.

## FIO
Under FIO directory you will find different ways to trigger FIO
- **Single Disk Baseline** : 
       - Used for single disk baseline
       - Classic FIO command line with necessary options
       - Manual result collection
- **CBT** ``stdfiobench`` **Module** :  
       - Used for single disk baseline, multi disk support yet to be added
       - Uses CBT as a wrapper for FIO
       - Can automate test runs for different block devices and patterns
       - Comes with FIO output parser script for easy results collection
       - Drops cache after every run
       - Creates filesystem and mount disk before running test. Does not support raw block device currently (but not hard to do)
       - Lot of configurable options 
- **Multi Disk Baseline** : 
       - Used for multi disk parallel baseline
       - Requres ``genfio`` to generate miltiple FIO job files and then execute them in parallel
       - Manual result collection


## IOzone
IOzone will allow you baseline the complete local IO stack, from disk to RAID to LVM to filesystem. This is an important metric as it is a fundamental stack from the perspective of the distributed storage system and it allows a point of comparison for distributed test runs.

Under the `iozone` directory is a set of instructions for how to use our `iozonebenchmark.sh` distributed test script to test a local filesystem mount point. This is a *single filesystem* test, which may underneath be represented by either a single physical disk or a virtual disk built on top of layers of block abstraction.
