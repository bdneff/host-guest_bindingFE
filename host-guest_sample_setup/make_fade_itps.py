#!/usr/bin/env python3
"""make_fade_itps.py — build the six A/B-state guest topologies from one acpype guest .itp.

Usage:  python3 make_fade_itps.py guest.itp [outdir]

Writes (guest1 = bound copy, guest2 = unbound copy in bulk):
  charge1-0.itp  guest1  charges on  -> off   (LJ on)          electrostatics leg
  charge0-1.itp  guest2  charges off -> on    (LJ on)          electrostatics leg
  lj0-1.itp      guest1  LJ on  -> off (type X -> dummy MX)    Lennard-Jones leg, charges zero
  lj1-0.itp      guest2  LJ off -> on  (dummy MX -> type X)    Lennard-Jones leg, charges zero
  final1-0.itp   guest1  fully interacting, no B state         restraint-release leg
  final0-1.itp   guest2  charges zero, no B state              restraint-release leg

Only the [ moleculetype ] name and the [ atoms ] block change; bonded terms and position
restraints are copied unchanged. Dummy types "M<type>" must exist in the force field with
sigma = epsilon = 0 (see ffnonbonded_mod.itp / the [ atomtypes ] block in fade_lj.top).
"""
import sys
from pathlib import Path

VARIANTS = {
    #  file            molname   kind
    "charge1-0.itp": ("guest1", "q_on_off"),
    "charge0-1.itp": ("guest2", "q_off_on"),
    "lj0-1.itp": ("guest1", "lj_on_off"),
    "lj1-0.itp": ("guest2", "lj_off_on"),
    "final1-0.itp": ("guest1", "full"),
    "final0-1.itp": ("guest2", "uncharged"),
}
AB_HEADER = ";   nr  type  resi  res  atom  cgnr     charge      mass        typeB   chargeB   massB\n"
A_HEADER = ";   nr  type  resi  res  atom  cgnr     charge      mass      \n"


def atom_row(fields, kind):
    nr, typ, resi, res, atom, cgnr, q, mass = fields
    q, mass = float(q), float(mass)
    left = "{:>6}{:>6}  {}   {}{:>6}{:>5}     {:.6f}      {:.5f}"
    if kind == "q_on_off":
        return left.format(nr, typ, resi, res, atom, cgnr, q, mass) + f"    {typ}   0.00000   {mass:.6f}\n"
    if kind == "q_off_on":
        return left.format(nr, typ, resi, res, atom, cgnr, 0.0, mass) + f"    {typ}   {q:.5f}   {mass:.6f}\n"
    if kind == "lj_on_off":
        return left.format(nr, typ, resi, res, atom, cgnr, 0.0, mass) + f"   M{typ}   0.00000   {mass:.6f}\n"
    if kind == "lj_off_on":
        return left.format(nr, "M" + typ, resi, res, atom, cgnr, 0.0, mass) + f"    {typ}   0.00000   {mass:.6f}\n"
    if kind == "full":
        return left.format(nr, typ, resi, res, atom, cgnr, q, mass) + "  \n"
    if kind == "uncharged":
        return left.format(nr, typ, resi, res, atom, cgnr, 0.0, mass) + "  \n"
    raise ValueError(kind)


def build(lines, molname, kind):
    out, section = [], None
    for line in lines:
        s = line.strip()
        if s.startswith("["):
            section = s.strip("[] ").lower()
            out.append(line)
            continue
        if section == "moleculetype" and s and not s.startswith(";"):
            out.append(f" {molname}         {s.split()[1]}\n")
            continue
        if section == "atoms":
            if s.startswith(";"):
                out.append(A_HEADER if kind in ("full", "uncharged") else AB_HEADER)
                continue
            if s:
                out.append(atom_row(s.split(";")[0].split()[:8], kind))
                continue
        out.append(line)
    return out


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    src = Path(sys.argv[1])
    outdir = Path(sys.argv[2]) if len(sys.argv) > 2 else src.parent
    outdir.mkdir(parents=True, exist_ok=True)
    lines = src.read_text().splitlines(keepends=True)
    for name, (molname, kind) in VARIANTS.items():
        (outdir / name).write_text("".join(build(lines, molname, kind)))
        print(f"wrote {outdir / name}  ({molname}, {kind})")


if __name__ == "__main__":
    main()
