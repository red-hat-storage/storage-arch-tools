#!/bin/bash

echo "*************** Starting Test-1 ***************"
./cbt.py -a radosbench/erasure-workload/4-2-run1/output/rb-write-seq_read-4m-4k-1-client radosbench/erasure-workload/4-2-run1/rb-write-seq_read-4m-4k-1-client.yml > radosbench/erasure-workload/4-2-run1/log/rb-write-seq_read-4m-4k-1-client.out 2>&1
echo "*************** Test-1 completed ***************"
sleep 120

echo "*************** Starting Test-2 ***************"
./cbt.py -a radosbench/erasure-workload/4-2-run1/output/rb-write-seq_read-4m-4k-4-clients radosbench/erasure-workload/4-2-run1/rb-write-seq_read-4m-4k-4-clients.yml > radosbench/erasure-workload/4-2-run1/log/rb-write-seq_read-4m-4k-4-clients.out 2>&1
echo "*************** Test-2 completed ***************"
sleep 120

echo "*************** Starting Test-3 ***************"
./cbt.py -a radosbench/erasure-workload/4-2-run1/output/rb-write-seq_read-4m-4k-8-clients radosbench/erasure-workload/4-2-run1/rb-write-seq_read-4m-4k-8-clients.yml > radosbench/erasure-workload/4-2-run1/log/rb-write-seq_read-4m-4k-8-clients.out 2>&1
echo "*************** Test-3 completed ***************"
sleep 120

echo "*************** Starting Test-4 ***************"
./cbt.py -a radosbench/erasure-workload/4-2-run1/output/rb-write-seq_read-4m-4k-12-clients radosbench/erasure-workload/4-2-run1/rb-write-seq_read-4m-4k-12-clients.yml > radosbench/erasure-workload/4-2-run1/log/rb-write-seq_read-4m-4k-12-clients.out 2>&1
echo "*************** Test-4 completed ***************"
sleep 120

