#!/bin/bash
# grep Children iozone--large-file-rw--mag-raid6-local-1-node-1-client-1-worker.results | grep write | awk -F= '{print $2}' | awk '{print $1}'

file=$1

listvals=()

function _calc() {
  declare -a i=("${!1}")
  total=$(echo ${i[@]} | sed s/\ /+/g | bc)
  count=${#i[@]}
  avg=$(echo "scale=2; $total / $count" | bc)
  sd=$(echo ${i[@]} | awk -v M=$avg -v C=$count '{for(n=1;n<=C;n++){sum+=($n-M)*($n-M)};print sqrt(sum/C)}')
  echo "$2 = $avg (δ $sd)"
  #echo "$(echo ${i[@]} | sed s/\ /\\t/g)"
  if [ "$3" == "true" ]; then
    cv=$(echo "scale=4; $sd / $avg" | bc)
    cvpct="$(printf %.2f $(echo "scale=2; $cv*100" | bc))%"
    listvals+=("$cvpct")
  fi
  listvals+=("$avg")
}


echo ""

label="Tot Write Throughput"
iterations=($(grep Children $1 | grep writers | awk -F= '{print $2}' | awk '{print $1}'))
_calc iterations[@] "$label" true

label="Min Write Throughput"
iterations=($(grep -A4 Children $1 | grep -A4 writers | grep 'Min throughput' | awk -F= '{print $2}' | awk '{print $1}'))
_calc iterations[@] "$label"

label="Max Write Throughput"
iterations=($(grep -A4 Children $1 | grep -A4 writers | grep 'Max throughput' | awk -F= '{print $2}' | awk '{print $1}'))
_calc iterations[@] "$label"

label="Avg Write Throughput"
iterations=($(grep -A4 Children $1 | grep -A4 writers | grep 'Avg throughput' | awk -F= '{print $2}' | awk '{print $1}'))
_calc iterations[@] "$label"

echo -e "spreadsheet:
δ/µ\ttot_write\tmin_write\tmax_write\tavg_write
${listvals[*]}" | sed s/\ /"$(printf '\t')"/g
listvals=()

echo ""

label="Tot Read Throughput"
iterations=($(grep Children $1 | grep readers | awk -F= '{print $2}' | awk '{print $1}'))
_calc iterations[@] "$label" true

label="Min Read Throughput"
iterations=($(grep -A4 Children $1 | grep -A4 readers | grep 'Min throughput' | awk -F= '{print $2}' | awk '{print $1}'))
_calc iterations[@] "$label"

label="Max Read Throughput"
iterations=($(grep -A4 Children $1 | grep -A4 readers | grep 'Max throughput' | awk -F= '{print $2}' | awk '{print $1}'))
_calc iterations[@] "$label"

label="Avg Read Throughput"
iterations=($(grep -A4 Children $1 | grep -A4 readers | grep 'Avg throughput' | awk -F= '{print $2}' | awk '{print $1}'))
_calc iterations[@] "$label"

echo -e "spreadsheet:
δ/µ\ttot_read\tmin_read\tmax_read\tavg_read
${listvals[*]}" | sed s/\ /"$(printf '\t')"/g
