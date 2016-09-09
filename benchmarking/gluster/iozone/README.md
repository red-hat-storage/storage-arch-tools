# Medium-to-Large File Benchmarking

## Filesystem throughput with iozone
Test I/O throughput for complete Gluster storage stack -- disk > RAID > LVM > filesystem > Gluster volume. Compare against manufacturers’ specs for disk hardware and against like tests from different hardware and benchmark cycles.


### Iozone command flags:
* `-t <threads>` -- Run `iozone` in throughput mode with `<threads>` number of discrete threads. Note that the -F flag will need at least this many paths passed to it.
* `-i [0,1]` -- `iozone` test to run. Test 0 is sequential write and must be run first to create files for later read tests. Test 1 is sequential read.
* `-+n` -- Do not perform any retests; simply write once or read once
* `-s <file size>` -- Size of files to test
* `-r <record size>` -- Record size to test
* `-c` -- Include `close()` in the timing calculations.
* `-e` -- Include `flush` (fsync,fflush) in the timing calculations
* `-+z` -- Enable latency histogram logging
* `-w` -- Retain written files on the filesystem for later read tests
* `-+m <path>` -- Path to the cluster configuration file

### Typical dimensions tested
* Throughput threads (workers per client): 1, 2, 4
* File sizes: 128m, 4g, 128g, 256g, 512g
* 4m record size
* RAID 6 and JBOD (single-disk)
* System defaults vs. tuned (data alignment, tuned profile, etc.)
* Healthy vs. rebalance/self-heal
* Single vs. dual network fabric
* Single site vs. Geo-rep

Always drop disk caches before every test.
```bash
sync ; echo 3 > /proc/sys/vm/drop_caches
```

Run the sequential write test in throughput mode. Adjust thread count, file size, block size, and list of files as appropriate for the test. 
```bash
iozone -t 1 -i 0 -+n -s 4g -r 4m -c -e -+z -w -+m /path/to/clusterfile
```

Drop caches…
```bash
sync ; echo 3 > /proc/sys/vm/drop_caches
```

Run the sequential read test in throughput mode, again adjusting flag options as appropriate.
```bash
iozone -t 1 -i 1 -+n -s 4g -r 4m -c -e -+z -+m /path/to/clusterfile
```

## Automation with the `iozonebenchmark.sh` script
This script aids the test process by providing a simple one-command interface.

Several variables need to be edited directly in the script based on the particulars of the test environment and the specifics of the tests being run. In order to aid in running  a series of scripts with changes to test parameters, several of the core variables can be passed as script command flags.

Additionally, the script has the capability to check out a git repository and automatically commit the results output files.

### Variables:
* `repopath` -- Local filesystem path to the git repo to use. This should already exist and be configured as a git repo.
* `iozone` -- Local filesytsem path to the `iozone` command. This should be consistent across all test systems
* `servers` -- Array variable holding the hostnames or IPs of all server nodes
* `clients` -- Array variable holding the hostnames or IPs of all client nodes
* `testname` -- Name of the test, following a given convention and incorporating test-specific variables
* `iopath` -- Path on the client nodes to which the I/O should be generated (should be under the mount point of the tested filesystem)
* `iozonecmd` -- Fully-formed `iozone` command minus the workload (-i) flag. Edit this if you need to modify the `iozone` command structure at all.

### Flag-adjustable Variables:
* `gitenable` -- Boolean true/false to enable/disable the git commits (flag: `-g` ; default: false)
* `numclients` -- Number of clients from the $clients variable to use in the test (flag: `-c <integer>` ; default: 12)
* `numworkers` -- Number of worker threads per client (flag: `-w <integer>` ; default: 4)
* `filesize` -- Size of files for the test, formatted for the -s flag of the `iozone` command (flag: `-f <string>` ; default: 4g)
* `recordsize` -- Size for individual record transactions, formatted for the -r flag of the `iozone` command (flag: `-r <string>` ; default: 4m)
* `iterations` -- Number of times to repeat the test (flag: `-i <integer>` ; default: 10)

### Example
Nested for loops allow many dimensions to be tested in sequence with one command string.
```bash
for f in 128m 4g ; do for c in 6 12; do for w in 1 2 4; do iozonebenchmark.sh -g -c $c -w $w -f $f -r 4m -i 10; done; done; done
```

## Parsing results with the `iozonecalc.sh` script
This script can be used to quickly average and display the iteration results. The script searches the results file for all write and read results, and then displays the averages for each result as well as the standard deviation. For simplicity of import into a spreadsheet, it also provides tab-separated output of the average results as well as the coefficient of variance from the total througput values.

### Example
```bash
iozonecalc.sh iozone--large-file-rw--mag-raid6-rep2-2-node-12-client-nfs-12-worker-2016-09-06-11-17-30.results

Tot Write Throughput = 1060309.77 (δ 13199.9)
Min Write Throughput = 84981.70 (δ 4279.67)
Max Write Throughput = 89577.96 (δ 2102.08)
Avg Write Throughput = 88359.14 (δ 1099.99)
spreadsheet:
δ/µ	tot_write	min_write	max_write	avg_write
1.24%	1060309.77	84981.70	89577.96	88359.14

Tot Read Throughput = 1122065.83 (δ 5527.24)
Min Read Throughput = 75668.29 (δ 3972.3)
Max Read Throughput = 111405.01 (δ 5121.52)
Avg Read Throughput = 93505.48 (δ 460.606)
spreadsheet:
δ/µ	tot_read	min_read	max_read	avg_read
0.49%	1122065.83	75668.29	111405.01	93505.48
```
