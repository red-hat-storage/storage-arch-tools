#!/bin/bash

file=$1

listvals=()

function _calc() {
  declare -a i=("${!1}")
  total=$(echo ${i[@]} | sed s/\ /+/g | bc)
  count=${#i[@]}
  avg=$(echo "scale=2; $total / $count" | bc)
  sd=$(echo ${i[@]} | awk -v M=$avg -v C=$count '{for(n=1;n<=C;n++){sum+=($n-M)*($n-M)};print sqrt(sum/C)}')
  echo "$2 = $avg (δ $sd)"
  if [ "$3" == "true" ]; then
    cv=$(echo "scale=4; $sd / $avg" | bc)
    cvpct="$(printf %.2f $(echo "scale=2; $cv*100" | bc))%"
    listvals+=("$cvpct")
  fi
  listvals+=("$avg")
}

busmetrics=($(cat $1 | awk '{print $1}' | egrep -v 'Business|Metric' | sort -un))

for metric in $(echo ${busmetrics[@]}); do

echo "-------------------------"

echo "Business Metric = $metric"

echo ""

label="Achieved Op Rate"
iterations=($(cat $1 | awk -v metric="$metric" '$1 == metric' | awk '{print $3}'))
_calc iterations[@] "$label" false > /dev/null
achoprate=$avg

label="Requested Op Rate"
iterations=($(cat $1 | awk -v metric="$metric" '$1 == metric' | awk '{print $2}'))
_calc iterations[@] "$label" false > /dev/null
reqoprate=$avg

opefficiency=$(echo "scale=4; $achoprate / $reqoprate" | bc)
opeffpct="$(printf %.2f $(echo "scale=2; $opefficiency*100" | bc))%"
echo "Operation Rate Efficiency = $opeffpct"

listvals=()

echo ""

label="Tot Write Throughput"
iterations=($(cat $1 | awk -v metric="$metric" '$1 == metric' | awk '{print $7}'))
_calc iterations[@] "$label" true

echo -e "spreadsheet:
δ/µ\ttot_write
${listvals[*]}" | sed s/\ /"$(printf '\t')"/g
listvals=()

echo ""

label="Tot Read Throughput"
iterations=($(cat $1 | awk -v metric="$metric" '$1 == metric' | awk '{print $6}'))
_calc iterations[@] "$label" true

echo -e "spreadsheet:
δ/µ\ttot_read
${listvals[*]}" | sed s/\ /"$(printf '\t')"/g
listvals=()

done
