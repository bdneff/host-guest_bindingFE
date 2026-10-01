#!/usr/bin/env bash
# render_tweezer.sh — regenerate the README structure images (headless VMD -> Tachyon -> PNG).
#   docs/img/tweezer_complex.png : tweezer + bound Ac-Lys-OMe, two views
#   docs/img/alchemical_box.png  : the two-copy simulation box used in the alchemical legs
#   docs/img/tweezer_dihedrals.png : apo tweezer with the two C-C-O-P dihedrals highlighted
# Requires VMD (with its bundled tachyon) and ImageMagick. Set VMD / TACHYON / VMDDIR for your install.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/../.." && pwd)"
VMD="${VMD:-/Applications/VMD.app/Contents/vmd2/lib/vmd_MACOSXARM64}"
TACHYON="${TACHYON:-/Applications/VMD.app/Contents/vmd2/lib/tachyon_MACOSXARM64}"
export VMDDIR="${VMDDIR:-/Applications/VMD.app/Contents/vmd2/lib}"
FONT="${FONT:-/System/Library/Fonts/Supplemental/Arial.ttf}"
PDB="$ROOT/host-guest_sample_setup/complex-trans.pdb"; IMG="$ROOT/docs/img"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Rewrite atom names as colour classes (see render_tweezer.tcl). Atom order in complex-trans.pdb:
# 1-80 host, 81-113 bound guest, 114-146 unbound guest copy.
classed () {  # last_atom outfile
    awk -v last="$1" '/^(ATOM|HETATM)/ { n++; if (n > last) next
        e = substr($0,13,4); gsub(/ /,"",e); e = substr(e,1,1)
        if (e == "C") cls = (n <= 80 ? "C" : (n <= 113 ? "S" : "Z")); else cls = e
        printf "%s%-4s%s\n", substr($0,1,12), " " cls, substr($0,17) }
        END { print "END" }' "$PDB" > "$2"
}
classed 113 "$TMP/complex.pdb"
classed 146 "$TMP/box.pdb"
classed 80  "$TMP/dihedral.pdb"

shot () {  # name mode rx ry rz res
    "$VMD" -dispdev text -e "$HERE/render_tweezer.tcl" -args "$TMP/$2.pdb" "$TMP/$1.dat" "$2" "$3" "$4" "$5" </dev/null 2>&1 | grep -E "COLOR-WARN" || true
    "$TACHYON" "$TMP/$1.dat" -res "$6" "$6" -aasamples 12 -format TARGA -o "$TMP/$1.tga" >/dev/null
    magick "$TMP/$1.tga" -trim +repage -bordercolor white -border 4% "$TMP/$1.png"
}
shot front complex ${FRONT:-0 0 0} 1600
shot side  complex ${SIDE:-0 90 0} 1600
magick "$TMP/front.png" "$TMP/side.png" -resize x900 -background white -gravity center +append "$IMG/tweezer_complex.png"
shot box box ${BOX:-18 -28 0} 2400
magick "$TMP/box.png" -resize 1600x "$IMG/alchemical_box.png"
shot dihe dihedral ${DIHE:-0 90 0} 1600
magick "$TMP/dihe.png" -resize x900 "$IMG/tweezer_dihedrals.png"
echo "wrote $IMG/tweezer_complex.png $IMG/alchemical_box.png $IMG/tweezer_dihedrals.png"
