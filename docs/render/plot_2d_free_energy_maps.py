#!/usr/bin/env python3
"""plot_2d_free_energy_maps.py — 2D free energy maps of the two C-C-O-P dihedrals (README figure).

Reads the WHAM-2D output in figures/data/2D_umbrella_results/<system>/<salt>/outfile.out
(columns: Phi1 [rad], Phi2 [rad], free energy [kJ/mol], probability; 40 x 40 bins) and writes
docs/img/2D_free_energy_maps.png. Same data and colour scale as the notebook figure
figures/2D_umbrella_plots/2D_umbrella_sampling_dataset.png, with panel titles and a full legend.

Run from anywhere:  python3 docs/render/plot_2d_free_energy_maps.py   (needs numpy, matplotlib)
"""
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Patch

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "figures/data/2D_umbrella_results"
COLS = [("DRG", "apo tweezer"), ("DRG+LYS", "tweezer + Ac-Lys-OMe"), ("DRG+ARG", "tweezer + Ac-Arg-OMe")]
ROWS = [("10mM", "10 mM NaCl"), ("200mM", "200 mM NaCl")]
VMAX = 30.0          # kJ/mol; everything above is drawn in the top colour
UNSAMPLED = 1.0e6    # WHAM writes 9999999 for bins with no data

cmap = plt.get_cmap("jet").copy()
cmap.set_bad("darkgray")

fig, axs = plt.subplots(2, 3, figsize=(11, 7.4), sharex=True, sharey=True)
for j, (sysdir, title) in enumerate(COLS):
    for i, (salt, salt_label) in enumerate(ROWS):
        d = np.loadtxt(DATA / sysdir / salt / "outfile.out")
        n = int(round(np.sqrt(len(d))))
        phi1 = np.degrees(d[:, 0]).reshape(n, n)
        phi2 = np.degrees(d[:, 1]).reshape(n, n)
        fe = np.ma.masked_greater(d[:, 2].reshape(n, n), UNSAMPLED)
        fe = fe - fe.min()
        ax = axs[i, j]
        im = ax.pcolormesh(phi1, phi2, fe, cmap=cmap, vmin=0, vmax=VMAX, shading="nearest", rasterized=True)
        ax.set_aspect("equal")
        ax.set_xticks([-90, 0, 90])
        ax.set_yticks([-90, 0, 90])
        if i == 0:
            ax.set_title(title, fontsize=13)
        if i == 1:
            ax.set_xlabel(r"$\Phi_1$ (degrees)", fontsize=12)
        if j == 0:
            ax.set_ylabel(f"{salt_label}\n" + r"$\Phi_2$ (degrees)", fontsize=12)

fig.subplots_adjust(left=0.09, right=0.86, top=0.93, bottom=0.14, wspace=0.08, hspace=0.10)
cax = fig.add_axes([0.885, 0.20, 0.02, 0.66])
cbar = fig.colorbar(im, cax=cax, extend="max")
cbar.set_ticks([0, 10, 20, 30])
cbar.set_ticklabels(["0", "10", "20", ">30"])
cbar.set_label(r"$\Delta G$ (kJ/mol)", fontsize=12)
fig.legend(handles=[Patch(facecolor="darkgray", edgecolor="black", label="unsampled")],
           loc="lower center", frameon=False, fontsize=11)
out = ROOT / "docs/img/2D_free_energy_maps.png"
fig.savefig(out, dpi=200)
print("wrote", out)
