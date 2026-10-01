# docs

Images used in the READMEs (`img/`) and the scripts that regenerate them (`render/`).

| image | script | needs |
|---|---|---|
| `img/tweezer_complex.png`, `img/alchemical_box.png`, `img/tweezer_dihedrals.png` | `render/render_tweezer.sh` (calls `render_tweezer.tcl`) | VMD with its bundled Tachyon, ImageMagick |
| `img/2D_free_energy_maps.png` | `render/plot_2d_free_energy_maps.py` | numpy, matplotlib |

The structure images are rendered from `host-guest_sample_setup/complex-trans.pdb`. Set `VMD`,
`TACHYON` and `VMDDIR` for your installation; the defaults are for VMD 2 on macOS.
