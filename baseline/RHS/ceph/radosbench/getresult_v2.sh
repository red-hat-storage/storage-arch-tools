#!/bin/bash
write_size=`grep "^Write size" output.* | tr -s " " | cut -f3 -d" " | awk '{s=$1} END {print s}'`
echo "Bandwidth(MB/sec)"
grep "^Bandwidth" output.* | tr -s " " | cut -f3 -d" ";
echo "\n"
echo "IOPS"
grep "^Average IOPS" output.* | tr -s " " | cut -f3 -d" ";
echo "\n"
echo "Block_Size(bytes)"
echo $write_size
