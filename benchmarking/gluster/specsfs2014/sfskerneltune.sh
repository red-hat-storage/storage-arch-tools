#!/bin/bash
#echo "300000" > /proc/sys/net/core/netdev_max_backlog
echo "128" > /proc/sys/sunrpc/tcp_slot_table_entries
echo "65535" > /proc/sys/net/core/somaxconn
echo "5" > /proc/sys/net/ipv4/tcp_fin_timeout

