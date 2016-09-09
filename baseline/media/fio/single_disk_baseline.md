
##Install fio

- Install FIO dependency
```
yum install -y libaio-devel
```
- Clone latest FIO
```
git clone https://github.com/axboe/fio.git
```
- By default FIO does not comes with libaio support. Manually turn on libaio and make install fio
```
# Enable libaio support by modifying libaio="yes"
$ sudo vi configure
```
- Compile and install FIO
```
# ./configure
# make
```

##FIO command line examples
- FIO commands to exercise 
	- Disk: ``/dev/sdb`` 
	- Patterns : Seq Read , Seq Write, Seq Read Write, Random Read Wrrite
	- Block size : Small block ( 4K )
	- Idle for : IOPS test

```
/root/fio/fio --filename=/dev/sdb --name=read-4k --rw=read --ioengine=libaio --bs=4k --numjobs=1 --direct=1 --randrepeat=0  --iodepth=1 --runtime=300 --ramp_time=5 --size=100G --group_reporting
```
```
/root/fio/fio --filename=/dev/sdb --name=write-4k --rw=write --ioengine=libaio --bs=4k --numjobs=1 --direct=1 --randrepeat=0  --iodepth=1 --runtime=300 --ramp_time=5 --size=100G --group_reporting
```
```
/root/fio/fio --filename=/dev/sdb --name=rw-4k --rw=rw --ioengine=libaio --bs=4k --numjobs=1 --direct=1 --randrepeat=0  --iodepth=1 --runtime=300 --ramp_time=5 --size=100G --group_reporting
```
```
/root/fio/fio --filename=/dev/sdb --name=randrw-4k --rw=randrw --ioengine=libaio --bs=4k --numjobs=1 --direct=1 --randrepeat=0  --iodepth=1 --runtime=300 --ramp_time=5 --size=100G --group_reporting
```

- FIO commands to exercise 
	- Disk :  ``/dev/sdb`` 
	- Patterns : Seq Read , Seq Write, Seq Read Write, Random Read Wrrite
	- Block size : Small block ( 4M )
	- Idle for : Bandwidth test
	
```
/root/fio/fio --filename=/dev/sdb --name=write-4M --rw=write --ioengine=libaio --bs=4M --numjobs=1 --direct=1 --randrepeat=0  --iodepth=1 --runtime=300 --ramp_time=5 --size=100G --group_reporting
```
```
/root/fio/fio --filename=/dev/sdb --name=read-4M --rw=read --ioengine=libaio --bs=4M --numjobs=1 --direct=1 --randrepeat=0  --iodepth=1 --runtime=300 --ramp_time=5 --size=100G --group_reporting
```
```
/root/fio/fio --filename=/dev/sdb --name=rw-4M --rw=rw --ioengine=libaio --bs=4M --numjobs=1 --direct=1 --randrepeat=0  --iodepth=1 --runtime=300 --ramp_time=5 --size=100G --group_reporting
```
```
/root/fio/fio --filename=/dev/sdb --name=randrw-4M --rw=randrw --ioengine=libaio --bs=4M --numjobs=1 --direct=1 --randrepeat=0  --iodepth=1 --runtime=300 --ramp_time=5 --size=100G --group_reporting
```

Similarly you can run the same commands for SSD or NVMe disks , just make sure to use correct device name in ``--filename`` flag.  Examples below
```
/root/fio/fio --filename=/dev/nvme0n1 --name=write-4k --rw=write --ioengine=libaio --bs=4k --numjobs=1 --direct=1 --randrepeat=0  --iodepth=1 --runtime=300 --ramp_time=5 --size=100G --group_reporting

/root/fio/fio --filename=/dev/nvme0n1 --name=read-4k --rw=read --ioengine=libaio --bs=4k --numjobs=1 --direct=1 --randrepeat=0  --iodepth=1 --runtime=300 --ramp_time=5 --size=100G --group_reporting

/root/fio/fio --filename=/dev/nvme0n1 --name=randrw-4k --rw=randrw --ioengine=libaio --bs=4k --numjobs=1 --direct=1 --randrepeat=0  --iodepth=1 --runtime=300 --ramp_time=5 --size=100G --group_reporting

/root/fio/fio --filename=/dev/nvme0n1 --name=rw-4k --rw=rw --ioengine=libaio --bs=4k --numjobs=1 --direct=1 --randrepeat=0  --iodepth=1 --runtime=300 --ramp_time=5 --size=100G --group_reporting

```
```
/root/fio/fio --filename=/dev/nvme0n1 --name=write-4M --rw=write --ioengine=libaio --bs=4M --numjobs=1 --direct=1 --randrepeat=0  --iodepth=1 --runtime=300 --ramp_time=5 --size=100G --group_reporting

/root/fio/fio --filename=/dev/nvme0n1 --name=read-4M --rw=read --ioengine=libaio --bs=4M --numjobs=1 --direct=1 --randrepeat=0  --iodepth=1 --runtime=300 --ramp_time=5 --size=100G --group_reporting

/root/fio/fio --filename=/dev/nvme0n1 --name=randrw-4M --rw=randrw --ioengine=libaio --bs=4M --numjobs=1 --direct=1 --randrepeat=0  --iodepth=1 --runtime=300 --ramp_time=5 --size=100G --group_reporting

/root/fio/fio --filename=/dev/nvme0n1 --name=rw-4M --rw=rw --ioengine=libaio --bs=4M --numjobs=1 --direct=1 --randrepeat=0  --iodepth=1 --runtime=300 --ramp_time=5 --size=100G --group_reporting

```
