Ceph Erasure Coding Setup
==============
- Commands to create EC (8,3) Pool
```
ceph osd erasure-code-profile set ec-profile ruleset-failure-domain=osd k=8 m=3
ceph osd erasure-code-profile ls
ceph osd erasure-code-profile get ec-profile
ceph osd pool create ec-pool-8-3 4096 4096 erasure ec-profile
ceph df
```
- Commands to create EC (4,2) Pool
```
ceph osd erasure-code-profile set ec-profile-4-2 ruleset-failure-domain=host k=4 m=2
ceph osd erasure-code-profile ls
ceph osd erasure-code-profile get ec-profile-4-2
ceph osd pool create rados-bench-cbt-ec 16384 16384 erasure ec-profile-4-2
```
If you already have EC profile created, you can create Ceph pool based on your EC profile as shown below
```
ceph osd pool create default.rgw.buckets.data 8192 erasure ec-profile-4-2
```
