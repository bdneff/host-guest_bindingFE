#!/bin/bash
#SBATCH -N 1
#SBATCH -n 4
#SBATCH -p parallel
#SBATCH -t 0-10:59                  # wall time (D-HH:MM)
#SBATCH -e slurm.%j.err

module load gromacs/2018.1
rm us_XXX.tpr
gmx grompp -f ../us_equi-NPT+ori.mdp -c us_equi_XXX.gro -n ../index.ndx -p ../complex.top -r ../em.gro -o us_XXX.tpr -maxwarn 1 >& grompp_XXX.out
gmx mdrun -v -nt 4 -deffnm us_equi_XXX -pin on -pinoffset XXX >& mdrun_equi_XXX.out
