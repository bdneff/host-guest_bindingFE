# Figures and analysis

Notebooks and processed data behind the figures in Chapter 3 of the thesis. Each subdirectory holds
one notebook and the images it wrote; all input data is under `data/`. The simulations that produced
the data are set up as described in [`../host-guest_sample_setup/`](../host-guest_sample_setup/).

| directory | what it shows | input data |
|---|---|---|
| `FEP_plots/` | predicted ΔG<sub>bind</sub> versus sampling time per window, four replicas plus mean, against experiment. One figure per restraint scheme: none (`FEP_results_no_rests.png`), orientational only (`FEP_results_only_o_rests.png`), orientational + phosphate dihedrals (`FEP_results_all_rests.png`) | `data/FE_Results/` |
| `2D_umbrella_plots/` | 2D free energy maps of the phosphate dihedrals Φ₁, Φ₂, and the confine/release correction computed from them | `data/2D_umbrella_results/` |
| `100ns_observation_plots/` | the slow degrees of freedom seen in 100 ns unbiased runs: phosphate dihedrals and guest orientation against time | `data/phosphate_dihedrals/`, `data/lig_orientational_dihedral/` |
| `benchmarking/` | deviation from the final estimate against GPU hours; choice of λ resolution and window length | `data/benchmarking/`, `data/FE_Results/` |

## Data layout

```
data/FE_Results/<system>/<salt>/[<variant>/]<N>ns-equil_<leg><replica>.txt
```

- `<system>`: `DRG+LYS` or `DRG+ARG` (`DRG` is the tweezer).
- `<salt>`: `ten` = 10 mM NaCl, `twenty` = 200 mM NaCl.
- `<variant>`: `no_rests` (centre-of-mass restraints only), `no_dihe` (orientational restraints
  only), `def_protocol` or the bare directory (orientational + dihedral restraints).
- Other variants under `DRG+LYS/twenty/`: `opt_lambdas*` and `gold_stand_same_struct` are the
  λ-resolution and window-length tests used in `benchmarking/`.
- `<leg>`: `charge`, `lj`, or `CL` (release of the orientational restraints); `<replica>` is 1–4.
- `<N>ns-equil`: N ns discarded from the start of every window before BAR.

Each file has two columns: sampling time per window (ps) and the cumulative BAR estimate for that
leg (kJ/mol).

```
data/2D_umbrella_results/<system>/<salt>/outfile.out
```

WHAM-2D output on a 40 × 40 grid: Φ₁ (rad), Φ₂ (rad), free energy (kJ/mol), probability. Unsampled
bins carry 9999999. `<system>` is `DRG` (apo), `DRG+LYS` or `DRG+ARG`; `<salt>` is `10mM` or `200mM`.

## Running the notebooks

`environment.yml` is a full export of the conda environment used at the time. The notebooks need
only `numpy`, `scipy`, `pandas` and `matplotlib`. Paths inside them are relative (`../data/...`), so
start Jupyter from the notebook's own directory. Some cells still contain commented-out absolute
paths from the original machine; they are not used.

The finished thesis versions of the main figures are in [`../docs/img/thesis/`](../docs/img/thesis/).
