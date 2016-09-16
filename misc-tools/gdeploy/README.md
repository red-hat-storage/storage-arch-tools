# Gluster Deployment and Cleanup Automation
The `gdeploy` tool utilizes ansible to automate the configuration of servers and Gluster volumes, as well as connectivity of client systems. It can also be used to reset the environment for a rebuild, a great benefit to the high degree of changes during a benchmark cycle.

## Build config files
The naming convention attempts to be clear as to what type of volume is being created. The .conf file should be edited as appropriate for server and client hardware specifics and hostnames.

## Reset config files
A set of two config files can be used in sequence to reset an environment to a clean state. Run `volume_reset.conf` followed by `backend_reset.conf`.

## Usage
```bash
gdeploy -c 3x2.tuned.conf
```

## Documentation
[Official Red Hat documentation - RHGS 3.1](https://access.redhat.com/documentation/en-US/Red_Hat_Storage/3.1/html/Administration_Guide/chap-Red_Hat_Storage_Volumes.html#chap-Red_Hat_Storage_Volumes-gdeploy)
