#!/bin/bash
#SBATCH -p general
#SBATCH -N 1
#SBATCH -c 16
#SBATCH -t 0-08:00
# run_window.sh — template for one lambda window; make_windows.sh fills in LEG and XXX.
# Runs from inside the leg directory (charge/, lj/ or final/).
gmx=${GMX:-gmx}        # use GMX=gmx_plumed for a PLUMED-patched build

# -c: equilibrated structure; -r: reference coordinates for the restraints.
# The original runs needed -maxwarn; read the warnings grompp prints before trusting a run.
${gmx} grompp -f LEG-XXX.mdp -c ../equi.gro -r ../ions.gro -p ../fade_LEG.top -n ../index.ndx \
              -o LEG-XXX.tpr -maxwarn 2
${gmx} mdrun -v -nt 4 -deffnm LEG-XXX >& mdrun_LEG-XXX.out
