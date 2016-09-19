Ceph slow request plugin
-----------------------------------
```
useradd collectd
chmod -R 775 /var/log/ceph
mkdir -p /etc/collectd/collectd-ceph-slow-requests
cd /etc/collectd/collectd-ceph-slow-requests
wget https://gist.githubusercontent.com/ksingh7/34fc814b9c1a54ec486d29d7ac8b2ea4/raw/0afe3cf3ccf1233d819f05762cf5260f44880698/ceph-slow-request.shh
chmod -R collectd:collectd /etc/collectd/collectd-ceph-slow-requests
```

```
echo "slow_rq    value:GAUGE:U:U" > /etc/collectd/collectd-ceph-slow-requests/slow-request_types.db
```

- Edit /etc/collectd.conf and add the following add
 - Beginning
 ```
 Types_DB "/etc/collectd/collectd-ceph-slow-requests/slow-request_types.db"
 
 ```
 - End
	```
<Plugin exec>
        Exec collectd "/etc/collectd/collectd-ceph-slow-requests/slow-request.sh"
</Plugin>
	```
- Restart collectd
```
systemctl restart collectd
```
- Check log file for any errors
```
tail -f /var/log/collectd
```
- Check graphite web for metric from slow request plugin
