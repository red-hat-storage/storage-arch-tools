# Using iozone for local filesytem baseline

## Prerequisites
All lower-level block configuration should be complete (RAID, LVM, etc), and the filesytem should be formatted and mounted on the local host. The intention here is to understand the capabilities of the fundamental IO stack upon which the distributed storage infrastructure will be built.

Ensure that the machine has passwordless ssh to itself (localhost).

## The iozonebenchmark.sh script
Local tests should be done with the `iozonebenchmark.sh` script, located under `/benchmarking/gluster/iozone` from the root of the git repo.

### Editing the script
- Set the `repopath` variable as appropraite to the local clone of your git repo
- Set the `gvolname` variable to `local`
- Set the `servers` variable to `localhost`
- Set the `clients` variable to `localhost`
- Edit the `testname` variable as appropriate
- Set the `iopath` variable to the local filesystem mount point with `/iozone` appended


### Running the script
To run a local test, set the `-c 1` flag, as you will only be testing from a local client to a local mountpoint. We generally test locally with a 4GB file size and a 4MB transaction size. The number of workers should be increased exponentially through around a half-dozen test cycles to find the maximum throughput capabilites of the filesystem for both reads and writes. Each individual test should be run several times (we usually do 5) in order to calculate averages and standard deviations.

Example run loop:
```
for w in 1 2 4 8 16 32; do iozonebenchmark.sh -g -c 1 -w $w -f 4g -r 4m -i 5; done
```

## Interpreting the output with iozonecalc.sh
The above example loop will output a set of `.results` files named based on the `testname` variable and a time stamp. There will be a `.results` file for each cycle of the `for` loop; all iterations within that cycle (the same test run multiple times, according to the `-i` flag) will dump output to a single `.results` file.

The `iozonecalc.sh` script will calculate the average throughput values and standard deviations across all iterations of a test. It will additionally output a spreadsheet-friendly columnized set of data for copy-paste, which will include the throughput values and coefficient of variance (of total throughput), separately for each of write and read cycles.

Example:
```
iozonecalc.sh iozone--large-file-rw--mag-jbod12-local-1-node-1-client-12-worker-2016-11-11-07-33-12.results

Tot Write Throughput = 207832.78 (δ 1114.34)
Min Write Throughput = 15948.20 (δ 253.358)
Max Write Throughput = 20093.02 (δ 562.631)
Avg Write Throughput = 17319.40 (δ 92.8617)
spreadsheet:
δ/µ	tot_write	min_write	max_write	avg_write
0.53%	207832.78	15948.20	20093.02	17319.40

Tot Read Throughput = 178347.98 (δ 552.062)
Min Read Throughput = 13857.35 (δ 141.841)
Max Read Throughput = 15922.26 (δ 150.205)
Avg Read Throughput = 14862.33 (δ 46.0031)
spreadsheet:
δ/µ	tot_read	min_read	max_read	avg_read
0.30%	178347.98	13857.35	15922.26	14862.33
```
