#!/bin/bash
# bar.sh — Bennett acceptance ratio over all windows of one leg.
# Usage:  bash bar.sh <charge|lj|final> [begin_ps] [end_ps]
# begin_ps discards equilibration at the start of every window (default 1000 ps).
set -euo pipefail
leg=${1:?usage: bar.sh <charge|lj|final> [begin_ps] [end_ps]}
b=${2:-1000}
e=${3:-10000}
gmx=${GMX:-gmx}
n=$(( $(ls ${leg}/${leg}-*.xvg | wc -l) ))
files=$(for ((i=0; i<n; i++)); do printf '%s ' "${leg}/${leg}-${i}.xvg"; done)
${gmx} bar -f ${files} -b ${b} -e ${e} -o ${leg}/bar_${b}-${e}.xvg >& ${leg}/bar_${b}-${e}.out
tail -n 4 ${leg}/bar_${b}-${e}.out
