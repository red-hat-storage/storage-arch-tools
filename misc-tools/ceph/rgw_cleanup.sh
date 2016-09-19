#!/bin/bash

for i in {1..3}; do ssh ceph-rgw$i systemctl stop ceph-radosgw@rgw.ceph-rgw$i.service; done
for i in {1..6}; do ssh ceph-osd$i systemctl stop ceph-radosgw@rgw.ceph-osd$i.service; done
for i in {1..12}; do ssh client$i systemctl stop ceph-radosgw@rgw.client$i.service; done

for i in  .rgw.root default.rgw.control default.rgw.data.root default.rgw.gc default.rgw.log  default.rgw.users.uid  default.rgw.users.keys default.rgw.meta default.rgw.users.swift default.rgw.buckets.index default.rgw.buckets.data ; do ceph osd pool delete $i $i --yes-i-really-really-mean-it ; done
sleep 30

for i in {1..3}; do ssh ceph-rgw$i systemctl start ceph-radosgw@rgw.ceph-rgw$i.service; done
for i in {1..6}; do ssh ceph-osd$i systemctl start ceph-radosgw@rgw.ceph-osd$i.service; done
for i in {1..12}; do ssh client$i systemctl start ceph-radosgw@rgw.client$i.service; done
sleep 30 

ssh ceph-rgw1 -t "radosgw-admin user create --uid='user1' --display-name='First User' --access-key='S3user1' --secret-key='S3user1key' --max-buckets=99999"
ssh ceph-rgw1 -t "radosgw-admin subuser create --uid='user1' --subuser='user1:swift' --secret-key='Swiftuser1key' --access=full --max-buckets=99999"

ceph osd pool create  default.rgw.buckets.index 2048 2048

for i in .rgw.root default.rgw.data.root default.rgw.control ; do ceph osd pool set $i pg_num 128 ; done
for i in  default.rgw.meta ; do ceph osd pool set $i pg_num 256 ; done
sleep 15 

for i in .rgw.root default.rgw.data.root default.rgw.control ; do ceph osd pool set $i pgp_num 128 ; done
for i in default.rgw.meta ; do ceph osd pool set $i pgp_num 256 ; done
sleep 30 

ceph osd pool create default.rgw.buckets.data 16384 erasure ec-profile-4-2
sleep 15
