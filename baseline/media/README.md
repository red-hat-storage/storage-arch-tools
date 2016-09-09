# Standard Practices for running Media baseline tests
- Tool selection ( FIO / IOzone ) is upto you , In past we have used
	- FIO for the following projects
		- Ceph P&S SuperMicro
		- Ceph P&S QCT
		- Ceph P&S Dell (730xd , DSS7000 )
		- Gluster P&S QCT
	- IOzone for the following projects
		- Gluster HCI on SuperMicro
- After each test run, it's a good idea to drop system cache.
```
# echo 3 > /proc/sys/vm/drop_caches
```
- Make sure you are benchmarking ``Direct IO`` , use appropriate flags for direct IO [ FIO : ``--direct = 1`` ]
- Baselines are usually done on block devices, however you can also baseline filesystems based on your test case.

## FIO
Under FIO directory you will find different ways to trigger FIO
- **Single Disk Baseline** : Used for single disk baseline.
- **Multi Disk Baseline** : Used for multi disk parallel baseline.
-  **Call** ``stdfiobench`` **within CBT** :  Uses CBT as a wrapper for FIO, also comes with FIO parser script

## IOzone

