#!/bin/bash
# grep Children iozone--large-file-rw--mag-raid6-local-1-node-1-client-1-worker.results | grep write | awk -F= '{print $2}' | awk '{print $1}'

file=$1

function calc() {
  declare -a i=("${!1}")
  total=$(echo ${i[@]} | sed s/\ /+/g | bc)
  avg=$(echo "scale=2; $total / ${#i[@]}" | bc)
  echo "$2 = $avg"
}

label="Tot Write Throughput"
iterations=($(grep Children $1 | grep writers | awk -F= '{print $2}' | awk '{print $1}'))
calc iterations[@] "$label"

label="Min Write Throughput"
iterations=($(grep -A4 Children $1 | grep -A4 writers | grep 'Min throughput' | awk -F= '{print $2}' | awk '{print $1}'))
calc iterations[@] "$label"

label="Max Write Throughput"
iterations=($(grep -A4 Children $1 | grep -A4 writers | grep 'Max throughput' | awk -F= '{print $2}' | awk '{print $1}'))
calc iterations[@] "$label"

label="Avg Write Throughput"
iterations=($(grep -A4 Children $1 | grep -A4 writers | grep 'Avg throughput' | awk -F= '{print $2}' | awk '{print $1}'))
calc iterations[@] "$label"

label="Tot Read Throughput"
iterations=($(grep Children $1 | grep readers | awk -F= '{print $2}' | awk '{print $1}'))
calc iterations[@] "$label"

label="Min Read Throughput"
iterations=($(grep -A4 Children $1 | grep -A4 readers | grep 'Min throughput' | awk -F= '{print $2}' | awk '{print $1}'))
calc iterations[@] "$label"

label="Max Read Throughput"
iterations=($(grep -A4 Children $1 | grep -A4 readers | grep 'Max throughput' | awk -F= '{print $2}' | awk '{print $1}'))
calc iterations[@] "$label"

label="Avg Read Throughput"
iterations=($(grep -A4 Children $1 | grep -A4 readers | grep 'Avg throughput' | awk -F= '{print $2}' | awk '{print $1}'))
calc iterations[@] "$label"
