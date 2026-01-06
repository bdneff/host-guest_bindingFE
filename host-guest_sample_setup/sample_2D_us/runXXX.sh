#!/bin/bash
#SBATCH -N 1
#SBATCH -n 4
#SBATCH -t 0-16:00                  # wall time (D-HH:MM)
#SBATCH -e slurm.%j.err

#module load gromacs/2018.1
rm us_XXX.tpr
gmx grompp -f ../us-NPT+ori.mdp -c us_XXX.gro -n ../index.ndx -p ../complex.top -r ../em.gro -o us_XXX.tpr -maxwarn 1 >& grompp_XXX.out
gmx mdrun -v -nt 1 -deffnm us_XXX >& mdrun_XXX.out
