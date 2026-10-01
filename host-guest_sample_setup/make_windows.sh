#!/bin/bash
# make_windows.sh — set up one alchemical leg: one .mdp and one job script per lambda window.
# Usage:  bash make_windows.sh <charge|lj|final>
# Reads the window count from the fep-lambdas line of <leg>-XXX.mdp, so the template is the
# single place where the lambda schedule is defined.
set -euo pipefail
leg=${1:?usage: make_windows.sh <charge|lj|final>}
tmpl=${leg}-XXX.mdp
top=fade_${leg}.top
[ -f "$tmpl" ] || { echo "missing template $tmpl"; exit 1; }
[ -f "$top" ]  || { echo "missing topology $top"; exit 1; }
n=$(( $(grep -E "^fep-lambdas" "$tmpl" | cut -d= -f2 | wc -w) ))
mkdir -p "$leg"
for ((i=0; i<n; i++)); do
    sed "s/XXX/${i}/g" "$tmpl" > "${leg}/${leg}-${i}.mdp"
    sed -e "s/XXX/${i}/g" -e "s/LEG/${leg}/g" run_window.sh > "${leg}/run-${i}.sh"
done
echo "${leg}: wrote ${n} windows (${leg}/${leg}-0.mdp ... ${leg}/${leg}-$((n-1)).mdp)"
echo "submit with:  cd ${leg} && for f in run-*.sh; do sbatch \$f; done"
