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
  #echo "$(echo ${i[@]} | sed s/\ /\\t/g)"
  if [ "$3" == "true" ]; then
    cv=$(echo "scale=4; $sd / $avg" | bc)
    cvpct="$(printf %.2f $(echo "scale=2; $cv*100" | bc))%"
    listvals+=("$cvpct")
  fi
  listvals+=("$avg")
}


echo ""

failcheck=`grep not\ enough $file | wc -l`
if [ $failcheck -gt 0 ]; then
  echo "!! AT LEAST ONE ITERATION FAILED -- CHECK RESULTS !!"
  echo ""
fi

label="Tot Write Throughput"
iterations=($(cat $1 | sed -n '/operation : create/,/operation : read/p' | grep 'files/sec' | awk '{print $1}'))
_calc iterations[@] "$label" true

echo -e "spreadsheet:
δ/µ\ttot_write
${listvals[*]}" | sed s/\ /"$(printf '\t')"/g
listvals=()

echo ""

label="Tot Read Throughput"
iterations=($(cat $1 | sed -n '/operation : read/,/operation : create/p' | grep 'files/sec' | awk '{print $1}'))
_calc iterations[@] "$label" true

echo -e "spreadsheet:
δ/µ\ttot_read
${listvals[*]}" | sed s/\ /"$(printf '\t')"/g
