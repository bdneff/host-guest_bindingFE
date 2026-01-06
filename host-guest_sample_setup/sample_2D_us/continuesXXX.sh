#!/bin/bash
#SBATCH -N 1
#SBATCH -n 4
#SBATCH -p parallel
#SBATCH -t 0-04:00                  # wall time (D-HH:MM)
#SBATCH -e slurm.%j.err

module load gromacs/2018.1

gmx mdrun -v -nt 4 -deffnm us_XXX -px us_XXX_pullx.xvg -pf us_XXX_pullf.xvg -cpi us_XXX_prev.cpt -append
