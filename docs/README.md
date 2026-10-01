# docs

Images used in the READMEs.

## `img/thesis/`

Figures from Chapter 3 of the thesis (B. Neff, Arizona State University, 2025).

| file | thesis figure | shows |
|---|---|---|
| `end_states.png` | 3.2 | end states of the unbinding process, phosphate tweezer + Ac-Lys-OMe |
| `physical_pathway.png` | 3.4 | physical pathway: the amino acid pulled out of the cavity, umbrella windows along the path |
| `alchemical_protocol.png` | 3.5 | electrostatics and Lennard-Jones legs with the two guest copies |
| `dihedral_confine_release.png` | 3.6 | imposing the dihedral restraints in the bound state, removing them in the unbound state |
| `phosphate_dihedrals.png` | 3.7 | the two C–C–O–P dihedrals, phosphates pointing away from the cavity |
| `phosphate_dihedrals_100ns.png` | 3.12 | the two dihedrals over a 100 ns unbiased simulation |
| `free_energy_profiles_2D.png` | 3.13 | 2D free energy profiles of the dihedrals, apo and complexes, 10 and 200 mM |
| `results_all_restraints.png` | 3.14 | binding free energy vs. sampling time with all restraints |

## `img/tweezer_complex.png`

Rendered from `host-guest_sample_setup/complex-trans.pdb` with `render/render_tweezer.sh` (calls
`render_tweezer.tcl`). Needs VMD with its bundled Tachyon and ImageMagick; set `VMD`, `TACHYON` and
`VMDDIR` for your installation (the defaults are for VMD 2 on macOS).
