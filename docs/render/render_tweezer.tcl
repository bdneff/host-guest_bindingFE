# render_tweezer.tcl — tweezer host + guest(s) -> Tachyon scene (headless VMD).
# Usage: vmd -dispdev text -e render_tweezer.tcl -args <classed.pdb> <out.dat> <mode> <rotx> <roty> <rotz>
#   mode = complex : host + bound guest
#   mode = box     : host + bound guest + unbound copy, with the 80 x 40 x 40 A box drawn
#   mode = dihedral: host only, the two C-C-O-P dihedrals highlighted (magenta = Phi1, cyan = Phi2)
# The input PDB is written by render_tweezer.sh: atom names are replaced by colour classes
#   C / S / Z = carbon of host / bound guest / unbound guest;  H O N P = other elements.
# (only names VMD already has in its Name colour category can be recoloured in text mode,
#  so the two guest-carbon classes borrow the S and Z slots)
# (complex-trans.pdb has no element column or CONECT records, so colours come from these
#  class names and bonds are drawn by distance with DynamicBonds.)
set pdb  [lindex $argv 0]
set out  [lindex $argv 1]
set mode [lindex $argv 2]
set rx [lindex $argv 3]; set ry [lindex $argv 4]; set rz [lindex $argv 5]

mol new $pdb type pdb autobonds off waitfor all
set mid [molinfo top get id]
mol delrep 0 $mid

# orient on the coordinates (then resetview refits, so nothing clips)
set all [atomselect $mid all]
$all moveby [vecscale -1.0 [measure center $all]]
set m [transmult [transaxis z $rz] [transaxis y $ry] [transaxis x $rx]]
$all move $m

color change rgb 2  0.50 0.52 0.56   ;# gray   -> host carbon
color change rgb 7  0.13 0.60 0.33   ;# green  -> bound guest carbon
color change rgb 3  0.95 0.52 0.08   ;# orange -> unbound guest carbon
color change rgb 5  0.80 0.62 0.10   ;# tan    -> phosphorus
foreach {t c} {C gray S green Z orange H white O red N blue P tan} {
    if {[catch {color Name $t $c} err]} { puts "COLOR-WARN $t: $err" }
}

proc addrep {mid rep sel} {
    mol representation $rep
    mol color Name
    mol selection $sel
    catch {mol material AOChalky}
    mol addrep $mid
}
set big [expr {$mode eq "box" ? 2.0 : 1.0}]
addrep $mid "DynamicBonds 1.75 [expr {0.16*$big}] 20.0" "all"
addrep $mid "VDW [expr {0.22*$big}] 24.0" "not name H"
addrep $mid "VDW [expr {0.13*$big}] 20.0" "name H"

if {$mode eq "dihedral"} {
    # the two C-C-O-P dihedrals restrained / sampled in the 2D umbrella sampling
    # (index.ndx groups com1-com4 = atoms 3 1 71 72, com5-com8 = atoms 5 2 76 77; 0-based below)
    foreach {sel cid} {"index 2 0 70 71" 27 "index 4 1 75 76" 10} {
        foreach rep {"DynamicBonds 1.75 0.30 20.0" "VDW 0.36 24.0"} {
            mol representation $rep
            mol color ColorID $cid
            mol selection $sel
            catch {mol material AOShiny}
            mol addrep $mid
        }
    }
}
if {$mode eq "box"} {
    # 80 x 40 x 40 A box centred on the system
    graphics $mid color black
    graphics $mid material AOChalky
    set hx 40.0; set hy 20.0; set hz 20.0
    proc P {m x y z} { return [coordtrans $m [list $x $y $z]] }
    foreach a {-1 1} { foreach b {-1 1} {
        graphics $mid cylinder [P $m -$hx [expr {$a*$hy}] [expr {$b*$hz}]] [P $m $hx [expr {$a*$hy}] [expr {$b*$hz}]] radius 0.12 resolution 12
        graphics $mid cylinder [P $m [expr {$a*$hx}] -$hy [expr {$b*$hz}]] [P $m [expr {$a*$hx}] $hy [expr {$b*$hz}]] radius 0.12 resolution 12
        graphics $mid cylinder [P $m [expr {$a*$hx}] [expr {$b*$hy}] -$hz] [P $m [expr {$a*$hx}] [expr {$b*$hy}] $hz] radius 0.12 resolution 12
    } }
    # resetview frames atoms only: add an invisible molecule with atoms on the box corners
    set cpdb [file join [file dirname $out] _corners.pdb]
    set fh [open $cpdb w]
    set n 0
    foreach sx {-1 1} { foreach sy {-1 1} { foreach sz {-1 1} {
        set c [P $m [expr {$sx*$hx}] [expr {$sy*$hy}] [expr {$sz*$hz}]]
        incr n
        puts $fh [format "ATOM  %5d  X   BOX X   1    %8.3f%8.3f%8.3f  1.00  0.00" $n [lindex $c 0] [lindex $c 1] [lindex $c 2]]
    } } }
    puts $fh "END"
    close $fh
    mol new $cpdb type pdb waitfor all
    mol delrep 0 [molinfo top get id]
}

catch {display projection Orthographic}
catch {display depthcue off}
catch {display ambientocclusion on}
catch {display shadows on}
catch {color Display Background white}
catch {axes location Off}
catch {display resetview}
render Tachyon $out
quit
