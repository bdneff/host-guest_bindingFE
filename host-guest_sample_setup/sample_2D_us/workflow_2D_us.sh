#!/bin/bash
# workflow_2D_us.sh — 2D umbrella sampling of the two C-C-O-P dihedrals (Phi1, Phi2).
#
# This is the original command listing, tidied so that every path points at a file that exists
# in this directory. It documents the sequence; it has not been re-run since the tidy-up, and on
# a cluster each block would normally be its own job. Read README.md first.
#
# Before starting, make the shared inputs visible here:
#   ln -s ../amber14sb-modified.ff .   &&   ln -s ../host-phos.itp .   &&   ln -s ../guest.itp .
set -euo pipefail
gmx=${GMX:-gmx}
MDP=mdp_files

# ---------------------------------------------------------------------------------------------
# 0. System preparation (skip if you start from the provided ions.gro)
#    NOTE: complex.pdb holds an uncapped lysine (25 atoms); the topology and ions.gro use the
#    capped Ac-Lys-OMe guest (33 atoms). Rebuild complex.pdb before using this block.
# ---------------------------------------------------------------------------------------------
# $gmx editconf -f complex.pdb -box 4 4 4 -o box.gro
# $gmx solvate  -cs -cp box.gro -p complex.top -o solv.gro
# $gmx grompp   -f $MDP/em.mdp -c solv.gro -p complex.top -o tmp.tpr -maxwarn 1
# $gmx genion   -s tmp.tpr -p complex.top -neutral -conc 0.01 -o ions.gro

# ---------------------------------------------------------------------------------------------
# 1. Energy minimisation and 100 ps NPT equilibration
# ---------------------------------------------------------------------------------------------
$gmx grompp -f $MDP/em.mdp -c ions.gro -p complex.top -o em.tpr -maxwarn 1
$gmx mdrun  -deffnm em
$gmx grompp -f $MDP/equi.mdp -c em.gro -r em.gro -p complex.top -o equi-NPT.tpr -maxwarn 1
$gmx mdrun  -v -nt 4 -deffnm equi-NPT

# ---------------------------------------------------------------------------------------------
# 2. Steered MD, stage A: bring Phi1 to the start of the scan (30 ps, -1.8 deg/ps)
# ---------------------------------------------------------------------------------------------
$gmx grompp -f $MDP/pre-dihe-NPT.mdp -c equi-NPT.gro -r em.gro -p complex.top -n index.ndx \
            -o pre-dihe-NPT.tpr -maxwarn 1
$gmx mdrun  -v -nt 4 -deffnm pre-dihe-NPT

# ---------------------------------------------------------------------------------------------
# 3. Steered MD, stage B: rotate Phi2 through 360 deg (200 ps at 1.8 deg/ps), Phi1 held
# ---------------------------------------------------------------------------------------------
$gmx grompp -f $MDP/dihe-NPT.mdp -c pre-dihe-NPT.gro -r em.gro -p complex.top -n index.ndx \
            -o dihe-NPT.tpr -maxwarn 1
$gmx mdrun  -v -nt 4 -deffnm dihe-NPT

# 8 snapshots along Phi2 (one frame per ps is saved; every 25th frame is kept)
echo 0 | $gmx trjconv -s dihe-NPT.tpr -f dihe-NPT.trr -sep -skip 25 -o st_.gro
for i in $(seq 0 7); do
    mkdir -p snapshot${i}
    mv st_${i}.gro snapshot${i}/
done

# ---------------------------------------------------------------------------------------------
# 4. Steered MD, stage C: from each snapshot rotate Phi1 through 360 deg, Phi2 held
#    -> 8 x 8 = 64 starting structures on the (Phi1, Phi2) grid
# ---------------------------------------------------------------------------------------------
for i in $(seq 0 7); do
    cd snapshot${i}
    $gmx grompp -f ../$MDP/rot_other-NPT.mdp -c st_${i}.gro -r ../em.gro -p ../complex.top \
                -n ../index.ndx -o rot_other-NPT.tpr -maxwarn 2
    $gmx mdrun  -v -nt 4 -deffnm rot_other-NPT
    echo 0 | $gmx trjconv -s rot_other-NPT.tpr -f rot_other-NPT.trr -sep -skip 25 -o us_.gro
    cd ..
done

# ---------------------------------------------------------------------------------------------
# 5. Umbrella sampling: 64 windows x 10 ns, k = 50 kJ mol^-1 rad^-2 on both dihedrals.
#    Each window is restrained at the dihedral values of its starting structure
#    (pull_coord*_start = yes). runXXX.sh is the per-window job template.
# ---------------------------------------------------------------------------------------------
for i in $(seq 0 7); do
    cd snapshot${i}
    for j in $(seq 0 7); do
        sed "s/XXX/${j}/g" ../runXXX.sh > run-${j}.sh
        sbatch run-${j}.sh
    done
    cd ..
done

# ---------------------------------------------------------------------------------------------
# 6. After the windows finish: collect the 64 pull-coordinate time series for WHAM-2D
# ---------------------------------------------------------------------------------------------
# mkdir -p wham_input
# count=0
# for i in $(seq 0 7); do
#     for j in $(seq 0 7); do
#         cp snapshot${i}/us_${j}_pullx.xvg wham_input/us_${count}_pullx.xvg
#         count=$((count + 1))
#     done
# done
# Then run Grossfield's wham-2d on wham_input/ (see README.md) to get outfile.out.
