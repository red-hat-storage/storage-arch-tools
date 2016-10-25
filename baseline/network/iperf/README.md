# Network Baseline Testing with iperf3

## One-to-One

## Full Mesh
The `iperfbenchmark.mesh.sh` script is designed to saturate network interfaces and the full network fabric in order to both highlight anomalies and validate the throughput capabilities of the fabric. Script results can be output and committed automatically to a local git repository, but the data are best interpreted through a system monitoring interface such as Grafana. Individual node outgoing and incoming data rates may highlight anomalous behavior. Total throughput metrics should indicate the upper bound limits of the fabric.

The script should be edited to set variables appropriately before you attempt to run it.

```bash
# Location of the iperf3 binary
iperf3="/usr/bin/iperf3"

# How often to report in seconds
ipreport=0

# How long to run the test in seconds
ipruntime=600

# How many client threads to run
ipthreads=10

# We automatically store our outputs in git repo branches. The repo should already exist at the below path.
repopath="/root/git/benchmark-gluster-smci-standard"

# We typically keep benchmark binaries in /root/bin
PATH="$PATH:/root/bin"

# How many times to run each test
iterations=1

# Whether to run the test in bidirectional mode. If your servers and clients lists overlap, then you might want to set this to false.
bidirectional=true

# Note: The "servers" will run the iperf3 server daemon, and the "clients" will run the iperf3 client commands to connect to those daemons. Think of the "servers" as destination and the "clients" as source.

# Starting host numeration for iperf servers (s) and clients (c)
s=0
c=0

# Hostname prefixes
sprefix="server"
cprefix="client"

# Total numbers of iperf servers and clients
numservers=6
numclients=12
```

The script will enumerate the hostnames for testing based on the variables given. In the example above, all of our server hostnames begin with "server" and our clients with "client". The enumeration of hostnames will start with `server0` and `client0`, and there will be 6 total servers and 12 total clients. Therefore, the `iperf3` server processes will be started on nodes with hostnames server{0..5} and `iperf3` client processes will be started on nodes with hostnames `client{0..11}`

This example will perform a test where all clients make connections to all servers, but the clients will not connect to other clients and the servers will not connect to other servers.

For a full mesh test between all server nodes, we may set the variables instead as below:

```bash
# Whether to run the test in bidirectional mode. If your servers and clients lists overlap, then you might want to set this to false.
bidirectional=false

# Starting host numeration for iperf servers (s) and clients (c)
s=0
c=0

# Hostname prefixes
sprefix="server"
cprefix="server"

# Total numbers of iperf servers and clients
numservers=6
numclients=6
```

In this example, we have set `bidirectional=false` because our server and client lists are the same, and therefore the script will already be testing links in both directions. We have set both the `sprefix` and the `cprefix` to the same hostname prefix value, and the `numservers` and `numclients` to be the same. The resulting script will run a full mesh everyone-to-everyone simultaneous test.
