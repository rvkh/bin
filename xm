#!/usr/bin/env bash
#
# processing queue

function main {
  [[ $# = 0 ]] && exit
  threads=$(sysctl -a | grep ncpu | cut -d: -f2)

  mapfile -t
  inputs="${#MAPFILE[@]}"
  queues="$((threads > inputs ? inputs : threads))"

  declare -a q
  for i in ${!MAPFILE[*]}; do
    let n+=1
    q[$n]+="${@//\{\}/\"${MAPFILE[$i]}\"}; "
    [[ $n -eq $queues ]] && n=0
  done

  declare -a a
  for ((n=1; n<=queues; n++)); do
    a+="{ "${q[$n]}" } & "
  done

  (eval "${a[@]}" && wait)
}

main "${@}"
