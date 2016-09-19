Ceph RGW Bucket Stats
====================
is used to count total number of RGW containers/buckets and RGW objects living in those buckets

- Get the scrip and store it on your Ceph cluster node
- Install python boto
```
yum install -y python-boto
```
- Edit script and add your RGW user credentials along with RGW node and port details
- Execute script
```
python /root/rgw_bucket_stats.py
```
- Output should look like below. The first value is total number of containers/buckets and second value is total number of objects living in those buckets
```
[root@ceph-rgw1 ~]# python /root/rgw_bucket_stats.py
5760,1198708
```
- If you like, you can add the following crontab entry for this script that executes in every 20 minutes
```
*/20 * * * * echo ----------------------------------- >> /root/rgw_bucket_stats.out ; date >> /root/rgw_bucket_stats.out ; python /root/rgw_bucket_stats.py >> /root/rgw_bucket_stats.out
```

Ceph RGW pool cleanup
=====================
Often there are situations where you want to destroy all RGW pools and recreate them. Use the following script to do this
- Get the script and store it on  your Ceph node which can run admin commands
- Edit script and update hostnames of all the RGW nodes. If you have only one, then remove extra RGW hosts
- Execute script
