#!/bin/bash

#bw=`grep "^Bandwidth" output.* | tr -s " " | cut -f3 -d" " | awk '{s+=$1} END {print s}'`
#bw=`grep "^Bandwidth" output.* | tr -s " " | cut -f3 -d" "`


#total_writes=`grep "^Total writes" output.* | tr -s " " | cut -f4 -d" " | awk '{s+=$1} END {print s}'`
write_size=`grep "^Write size" output.* | tr -s " " | cut -f3 -d" " | awk '{s=$1} END {print s}'`
#total_data=$(echo "scale=3; $total_writes*$write_size/1024/1024/1024" | bc -l)


#iops=`grep "^Average IOPS" output.* | tr -s " " | cut -f3 -d" "| awk '{s+=$1} END {print s}'`
#iops=`grep "^Average IOPS" output.* | tr -s " " | cut -f3 -d" "`

#echo "bw: $bw, total_writes: $total_writes, write_size: $write_size"
#echo "bandwidth: " $bw "MB/s, Total Writes: " $total_data "GB"
echo "Bandwidth(MB/sec)"
grep "^Bandwidth" output.* | tr -s " " | cut -f3 -d" ";

echo -e "\nIOPS"
grep "^Average IOPS" output.* | tr -s " " | cut -f3 -d" ";

echo -e  "\nBlock_Size(bytes)"
echo $write_size
#echo $bw $iops $write_size
