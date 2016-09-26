Ceph Rados Gateway Setup
=======================
- Ceph RGW tunable configuration parameters. 
```
# Number of RGW/Civetweb threads (increased parallellism)
rgw frontends = civetweb port=10.5.13.118:8080 num_threads=2048 request_timeout_ms=99999
# Bucket sharding
rgw_override_bucket_index_max_shards = 128
rgw_bucket_index_max_aio = 128
rgw num rados handles = 64
rgw cache lru size = 30000

# RGW strip size, size in bytes , use it only if COSBench jobs from default strip size is failing
rgw_obj_stripe_size = 33554432 

# Enable logging
debug rgw = 10
debug civetweb = 10
debug ms =1
```
- Create Ceph RGW user with S3 and Swift access
```
radosgw-admin user create --uid='user1' --display-name='First User' --access-key='S3user1' --secret-key='S3user1key' --max-buckets=99999
```

```
radosgw-admin subuser create --uid='user1' --subuser='user1:swift' --secret-key='Swiftuser1key' --access=full --max-buckets=99999
```
- Verify user
```
radosgw-admin user info --uid="user1"
```
- One liner to delete all objects
```
ssh ceph-rgw1 -t "for i in (swift -A http://10.5.13.140:8080/auth/1.0 -U user1:swift -K 'Swiftuser1key' list) ; do swift -A http://10.5.13.140:8080/auth/1.0 -U user1:swift -K 'Swiftuser1key' delete $i ; done"
```

HAProxy Setup
=============
- HAproxy installation
```
yum install -y haproxy
mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bkp
vim /etc/haproxy/haproxy.cfg
```
- HAproxy configuration file ( make sure to update RGW IP )
```
 global
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     8000
    user        haproxy
    group       haproxy
    daemon
    stats socket /var/lib/haproxy/stats

defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    option httpchk HEAD /
    retries                 3
    timeout http-request        6m
    timeout queue               6m
    timeout connect             6m
    timeout client              6m
    timeout server              6m
    timeout http-keep-alive     6m
    timeout check               6m
    maxconn                     8000
    option accept-invalid-http-request

frontend  rgwhttp
    default_backend             rgw
    bind			10.5.13.135:80
    option 			forwardfor
    reqidel 		^X­Forwarded­For:.*

backend rgw
  balance leastconn
  server  ceph-osd3 10.5.13.135:8080 check inter 2000 rise 2 fall 5
```
- Restart HAproxy services
```
systemctl restart haproxy 
systemctl enable haproxy
systemctl status haproxy -l
sleep 5;netstat -plunt | egrep "rados|haproxy"
```
- (optional) HAproxy collectd plugin
```
easy_install collectd-haproxy ;  vim /etc/collectd.conf ; 
```
```
<Plugin python>
    Import "collectd_haproxy"
    <Module haproxy>
      Socket "/var/lib/haproxy/stats"
    </Module>
</Plugin>
```
```
systemctl restart collectd ; systemctl status collectd
```

DNS Wildcard entry (optional)
=============================
To use Ceph with S3-style subdomains (e.g., bucket-name.domain-name.com), you need to add a wildcard to the DNS record of the DNS server you use with the ceph-radosgw daemon.
The address of the DNS must also be specified in the Ceph configuration file with the ``rgw dns name = {hostname}`` setting.

Do this on your RGW host where you want 
```
yum install -y dnsmasq
echo "address=/.$(hostname -f)/<IP of RGW>" | tee --append /etc/dnsmasq.conf

Edit /etc/resolv.conf and add 
nameserver 127.0.0.1

systemctl restart dnsmasq ; systemctl enable dnsmasq ; systemctl status dnsmasq
ping dummy.<rgw hostname>
```

Useful commands
====================

```
 swift  -A http://ceph-osd1:80/auth/1.0 -U user1:swift -K 'Swiftuser1key' list
```

- Delete containers ... wait for it ... start COSbench test

```
for i in {1..2000}; do swift -A http://10.5.13.140:80/auth/1.0 -U user1:swift -K 'Swiftuser1key' delete mycontainers$i ; done ; sleep 20 ; sh /root/cosbench/0.4.2.c3/cli.sh submit /root/cosbench/0.4.2.c3/workload/s3/test-s3.xml

```
