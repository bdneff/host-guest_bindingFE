#!/bin/bash
#SBATCH -p general
#SBATCH -N 1
#SBATCH -c 16
#SBATCH -t 0-02:00


gmx=gmx_plumed

rm alchemical-XXX.tpr
${gmx} grompp -f alchemical-XXX.mdp -c alchemical-0.gro -p ../fade_final.top -n ../index.ndx -r ../ions.gro -o alchemical-XXX.tpr -maxwarn 2
${gmx} mdrun -v -nt 4 -deffnm alchemical-XXX >& mdrun_alchemical-XXX.out
