## Requirements
- Working Ceph cluster
- CBT

## Erasure Coded Pools
- Follow the below commands to create EC 4+2 profile and pool
```
ceph osd erasure-code-profile set ec-profile-4-2 ruleset-failure-domain=host k=4 m=2
ceph osd erasure-code-profile ls
ceph osd erasure-code-profile get ec-profile-4-2
ceph osd pool create ec-pool-4-2 4096 4096 erasure ec-profile
ceph df
ceph -s
```
- Modify CBT yml files present in EC-pool directory as per your needs

## Replicated Pools
- Modify CBT yml files present in replicated-pool directory as per your needs

## Running tests
```
./cbt.py -a output/rb-write-seq_read-4m-4k-8-clients EC-pool/rb-write-seq_read-4m-4k-8-clients.yml
```

## Results parsing
- The current parsing scrip is not very flexible
- To parse results you should change directory to the path which contains output.*.out files
```
# cd output/rb-write-seq_read-4m-4k-8-clients/00000000/Radosbench/osd_ra-00131072/op_size-00004096/concurrent_ops-00000128/write
# ls -l output*
-rw-r--r-- 1 root root 26672 Jun 23 21:11 output.0.client1
-rw-r--r-- 1 root root 26675 Jun 23 21:11 output.0.client2
-rw-r--r-- 1 root root 26671 Jun 23 21:11 output.0.client3
-rw-r--r-- 1 root root 26670 Jun 23 21:11 output.0.client4
-rw-r--r-- 1 root root 26672 Jun 23 21:11 output.0.client5
-rw-r--r-- 1 root root 26674 Jun 23 21:11 output.0.client6
-rw-r--r-- 1 root root 26674 Jun 23 21:11 output.0.client7
-rw-r--r-- 1 root root 26661 Jun 23 21:11 output.0.client8
#
```
- From this directory execute ``getresult.sh``
```
# sh $Absolute_Path_to_Parser_Script/getresult.sh
Bandwidth(MB/sec)
4.24599
4.28269
4.20439
4.18851
4.20632
4.25576
4.24147
4.27321

IOPS
1086
1096
1076
1072
1076
1089
1085
1093


Block_Size(bytes)
4096
#
```
## Additional Information
If you have created multiple YML files say for 1 , 4 , 8 and 12 client hosts , you can automate the process by using a wrapper script such as ``start_ec_4_2_test.sh``. You should modify this script as per your needs.
