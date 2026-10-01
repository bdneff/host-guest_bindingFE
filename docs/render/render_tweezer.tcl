# render_tweezer.tcl — tweezer host + guest(s) -> Tachyon scene (headless VMD).
# Usage: vmd -dispdev text -e render_tweezer.tcl -args <classed.pdb> <out.dat> <rotx> <roty> <rotz>
# The input PDB is written by render_tweezer.sh: atom names are replaced by colour classes
#   C / S = carbon of host / bound guest;  H O N P = other elements.
# (only names VMD already has in its Name colour category can be recoloured in text mode,
#  so the guest-carbon class borrows the S slot)
# (complex-trans.pdb has no element column or CONECT records, so colours come from these
#  class names and bonds are drawn by distance with DynamicBonds.)
set pdb  [lindex $argv 0]
set out  [lindex $argv 1]
set rx [lindex $argv 2]; set ry [lindex $argv 3]; set rz [lindex $argv 4]

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
color change rgb 5  0.80 0.62 0.10   ;# tan    -> phosphorus
foreach {t c} {C gray S green H white O red N blue P tan} {
    if {[catch {color Name $t $c} err]} { puts "COLOR-WARN $t: $err" }
}

proc addrep {mid rep sel} {
    mol representation $rep
    mol color Name
    mol selection $sel
    catch {mol material AOChalky}
    mol addrep $mid
}
set big 1.0
addrep $mid "DynamicBonds 1.75 [expr {0.16*$big}] 20.0" "all"
addrep $mid "VDW [expr {0.22*$big}] 24.0" "not name H"
addrep $mid "VDW [expr {0.13*$big}] 20.0" "name H"

catch {display projection Orthographic}
catch {display depthcue off}
catch {display ambientocclusion on}
catch {display shadows on}
catch {color Display Background white}
catch {axes location Off}
catch {display resetview}
render Tachyon $out
quit
