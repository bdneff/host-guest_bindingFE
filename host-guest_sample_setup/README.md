# Alchemical binding free energy: sample setup

Worked example of the absolute binding free energy protocol for a phosphate-substituted molecular
tweezer (host, `DRG`) and a capped amino acid (guest, Ac-Lys-OMe), as described in Chapter 3 of
B. Neff, PhD thesis (Arizona State University, 2025). The top-level files are the **lysine** system;
the arginine guest topologies are in `arginine_guest/`.

## Protocol in brief (thesis §3.2)

| item | setting |
|---|---|
| engine | GROMACS 2022.5; PME, 10 Å cutoffs, 1.2 Å grid, 4th-order interpolation; LINCS on all bonds |
| force field | GAFF via AcPype for host and guest; TIP3P water; amber14sb ions |
| box | 80 × 40 × 40 Å: host with bound guest, plus a second guest copy 40 Å away along x |
| position restraints | centre-of-mass restraint on each guest, 1000 kJ mol⁻¹ nm⁻² |
| equilibration | steepest descent, then 100 ps NPT at 300 K, Berendsen thermostat and barostat (1 ps) |
| production | NPT, 300 K, Nosé–Hoover (1 ps), Parrinello–Rahman (2 ps), 2 fs step |
| orientational restraints | six Boresch-type restraints (1 distance, 2 angles, 3 dihedrals) between three host and three guest atoms |
| phosphate dihedrals | both C–C–O–P dihedrals restrained, 100 kJ mol⁻¹ rad⁻²; cost from 2D umbrella sampling (`sample_2D_us/`) |
| legs | electrostatics → Lennard-Jones (soft-core) → release of orientational restraints |
| λ windows | 16 (electrostatics), 21 (Lennard-Jones), 11 (restraint release), evenly spaced |
| estimator | Bennett acceptance ratio between neighbouring windows; four independent replicas |

In each alchemical leg the bound guest is switched off while the unbound copy is switched on, so
one simulation gives the bound-minus-unbound difference and the net charge of the box is constant.
The full pathway is

    ΔG_bind = ΔG_confine + ΔG_orient + ΔG*_bind + ΔG_non-int + ΔG_release        (thesis eq. 3.8)

where ΔG\*_bind is the sum of the electrostatics and Lennard-Jones legs with restraints on,
ΔG_orient comes from the restraint-release leg, ΔG_non-int is the analytic Boresch term (eq. 3.1),
and ΔG_confine + ΔG_release is the phosphate-dihedral correction from 2D umbrella sampling.

## Files

| file | role |
|---|---|
| `complex-trans.pdb` | host + bound guest + unbound guest copy |
| `host-phos.itp`, `guest.itp` | AcPype/GAFF topologies |
| `make_fade_itps.py` | builds the six A/B-state guest topologies below from `guest.itp` |
| `charge1-0.itp`, `charge0-1.itp` | bound guest charges on→off; unbound guest charges off→on |
| `lj0-1.itp`, `lj1-0.itp` | bound guest LJ on→off; unbound guest LJ off→on (charges zero) |
| `final1-0.itp`, `final0-1.itp` | guest topologies for the restraint-release leg (no B state) |
| `fade_charge.top`, `fade_lj.top`, `fade_final.top` | master topology for each leg |
| `ffnonbonded_mod.itp` | amber14sb nonbonded atom types plus GAFF types and the dummy types `M*` (σ = ε = 0) |
| `em.mdp`, `equi.mdp` | minimisation and equilibration |
| `charge-XXX.mdp`, `lj-XXX.mdp`, `final-XXX.mdp` | one-window production templates for each leg |
| `make_windows.sh`, `run_window.sh` | generate and run the per-window inputs |
| `bar.sh` | BAR over all windows of a leg |
| `sample_2D_us/` | 2D umbrella sampling of the two phosphate dihedrals |
| `arginine_guest/` | the same seven guest topologies for Ac-Arg-OMe |

## Workflow

```bash
gmx=gmx    # or gmx_plumed

# 1. box, water, ions, minimisation
$gmx editconf -f complex-trans.pdb -box 8 4 4 -o box.gro
$gmx solvate  -cs -cp box.gro -p fade_charge.top -o solv.gro
$gmx grompp   -f em.mdp -c solv.gro -p fade_charge.top -o tmp.tpr
$gmx genion   -s tmp.tpr -p fade_charge.top -neutral -conc 0.01 -o ions.gro     # 0.2 for 200 mM
$gmx grompp   -f em.mdp -c ions.gro -p fade_charge.top -o em.tpr
$gmx mdrun    -deffnm em

# 2. copy the final [ molecules ] block of fade_charge.top into fade_lj.top and fade_final.top
#    (solvate and genion only update the topology they were given)

# 3. index.ndx (see below), then equilibration
$gmx grompp -f equi.mdp -c em.gro -r ions.gro -p fade_charge.top -n index.ndx -o equi.tpr
$gmx mdrun  -deffnm equi

# 4. each leg
bash make_windows.sh charge      # 16 windows
bash make_windows.sh lj          # 21 windows
bash make_windows.sh final       # 11 windows
(cd charge && for f in run-*.sh; do sbatch $f; done)     # likewise lj/, final/

# 5. analysis: discard the first 1 ns of every window
bash bar.sh charge 1000 10000
bash bar.sh lj     1000 10000
bash bar.sh final  1000 10000
```

For replicas, repeat steps 3–5 in separate directories (the thesis used four, each with its own
equilibration).

## Things you must supply

- **`amber14sb-modified.ff/`.** The topologies include `forcefield.itp`, `tip3p.itp` and `ions.itp`
  from this directory, which was not archived. The surviving piece is `ffnonbonded_mod.itp`. To
  rebuild: copy an `amber14sb.ff` directory to `amber14sb-modified.ff` and use `ffnonbonded_mod.itp`
  as its `ffnonbonded.itp`. The `[ atomtypes ]` blocks at the top of the three `fade_*.top` files
  repeat some of these types and were written against the original directory; if `grompp`
  reports a duplicate atom type, comment out the repeated line in the `.top`.
- **`index.ndx`.** Built by hand. The templates need: `Complex`, `Lone-Protein`, `Water_and_ions`
  (temperature-coupling groups); `Bind-Protein`, `Lone-Protein` (centre-of-mass restraints);
  `com1`–`com8` (the atoms defining the two C–C–O–P dihedrals); and `Lanc1`–`Lanc3`, `Panc1`–`Panc3`
  (orientational restraints). `sample_2D_us/index.ndx` contains `com1`–`com8` and `Complex`.
  Anchor atoms per the thesis (§3.2.3): on the tweezer, the two carbons adjacent to the C–C–O–P
  groups and a third carbon five positions away on the arm; on the guest, the acetyl methyl
  carbon, the ester methyl carbon and Cγ. Check the atom order of every angle and dihedral.
- **Soft-core values.** The thesis states soft-core potentials were used in the Lennard-Jones leg,
  but the production `.mdp` files were not archived. `lj-XXX.mdp` carries the commonly used
  GROMACS values (`sc-alpha 0.5`, `sc-power 1`, `sc-sigma 0.3`); these are not confirmed originals.

## Notes

- Window length in the templates is 10 ns. The λ-resolution benchmarking in the thesis used 40 ns
  windows with 11, 16, 21 and 81 windows per leg.
- `lj0-1.itp`, `lj1-0.itp`, `final1-0.itp` and `final0-1.itp` for lysine were regenerated with
  `make_fade_itps.py`; an earlier version of this directory had the arginine files in their place.
  The script reproduces the original arginine files and the lysine charge files exactly.
- `sample_2D_us/` has its own README.
