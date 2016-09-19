HAproxy Collectd Plugin
======================
- Make sure HAproxy is installed, configured and running

- Install and configure plugin
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
- Check graphite web for metric data
