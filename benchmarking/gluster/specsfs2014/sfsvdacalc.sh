#!/bin/bash

file=$1

listvals=()

function _calc() {
  declare -a i=("${!1}")
  # Calculate sum total of iterations
  total=$(echo ${i[@]} | sed s/\ /+/g | bc)
  # Count number of iterations
  count=${#i[@]}
  # Calculate average of iterations
  avg=$(echo "scale=2; $total / $count" | bc)
  # Calculate standard deviation of iterations
  sd=$(echo ${i[@]} | awk -v M=$avg -v C=$count '{for(n=1;n<=C;n++){sum+=($n-M)*($n-M)};print sqrt(sum/C)}')
  # Output label, average, and standard deviation
  echo "$2 = $avg (δ $sd)"
  if [ "$3" == "true" ]; then
    # Calculate coefficient of variance
    cv=$(echo "scale=4; $sd / $avg" | bc)
    # Convert coefficient to percentage
    cvpct="$(printf %.2f $(echo "scale=2; $cv*100" | bc))%"
    listvals+=("$cvpct")
  fi
  listvals+=("$avg")
}

busmetrics=($(cat $1 | awk '{print $1}' | egrep -v 'Business|Metric' | sort -un))

for metric in $(echo ${busmetrics[@]}); do

  echo "-------------------------"

  echo "BUSINESS METRIC = $metric"

  echo ""

  label="Avg Latency"
  iterations=($(cat $1 | awk -v metric="$metric" '$1 == metric' | awk '{print $4}'))
  _calc iterations[@] "$label" true


  label="Tot Throughput"
  iterations=($(cat $1 | awk -v metric="$metric" '$1 == metric' | awk '{print $5}'))
  _calc iterations[@] "$label" false

  echo ""

  label="Achieved Op Rate"
  iterations=($(cat $1 | awk -v metric="$metric" '$1 == metric' | awk '{print $3}'))
  _calc iterations[@] "$label" false
  achoprate=$avg

  label="Requested Op Rate"
  iterations=($(cat $1 | awk -v metric="$metric" '$1 == metric' | awk '{print $2}'))
  _calc iterations[@] "$label" false > /dev/null
  reqoprate=$avg
  # We are only using req op rate for calculateion of op efficiency,
  # so here we remove its element from the listvals array
  unset listvals[${#listvals[@]}-1]

  opefficiency=$(echo "scale=4; $achoprate / $reqoprate" | bc)
  opeffpct="$(printf %.2f $(echo "scale=2; $opefficiency*100" | bc))%"
  echo "Operation Rate Efficiency = $opeffpct"

  fails=($(cat $1 | awk -v metric="$metric" '$1 == metric' | awk '{print $17}'))
  echo "Number of Failures = ${#fails[@]}"

  echo ""

  echo -e "spreadsheet:
δ/µ\tavg_lat\ttot_through\tach_op\tfailures
${listvals[*]} ${#fails[@]}" | sed s/\ /"$(printf '\t')"/g
  listvals=()

done
