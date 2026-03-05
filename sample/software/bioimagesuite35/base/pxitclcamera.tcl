#BIOIMAGESUITE_LICENSE  ---------------------------------------------------------------------------------
#BIOIMAGESUITE_LICENSE  This file is part of the BioImage Suite Software Package.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  X. Papademetris, M. Jackowski, N. Rajeevan, H. Okuda, R.T. Constable, and L.H
#BIOIMAGESUITE_LICENSE  Staib. BioImage Suite: An integrated medical image analysis suite, Section
#BIOIMAGESUITE_LICENSE  of Bioimaging Sciences, Dept. of Diagnostic Radiology, Yale School of
#BIOIMAGESUITE_LICENSE  Medicine, http:#www.bioimagesuite.org.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  This program is free software; you can redistribute it and/or
#BIOIMAGESUITE_LICENSE  modify it under the terms of the GNU General Public License version 2
#BIOIMAGESUITE_LICENSE  as published by the Free Software Foundation.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  This program is distributed in the hope that it will be useful,
#BIOIMAGESUITE_LICENSE  but WITHOUT ANY WARRANTY; without even the implied warranty of
#BIOIMAGESUITE_LICENSE  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#BIOIMAGESUITE_LICENSE  GNU General Public License for more details.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  You should have received a copy of the GNU General Public License
#BIOIMAGESUITE_LICENSE  along with this program; if not, write to the Free Software
#BIOIMAGESUITE_LICENSE  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#BIOIMAGESUITE_LICENSE  See also  http:#www.gnu.org/licenses/gpl.html
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  If this software is modified please retain this statement and add a notice
#BIOIMAGESUITE_LICENSE  that it had been modified (and by whom).  
#BIOIMAGESUITE_LICENSE 
#BIOIMAGESUITE_LICENSE  -----------------------------------------------------------------------------------

package provide pxitclcamera 1.0

# 	$Id: pxitclcamera.tcl,v 1.1 2002/07/19 22:17:02 papad Exp papad $	





package require pxitclobject 1.0
# -------------------------------------------------------------------
# Definition of pxitclcamera
#
#    a class that encapsulates a camera and its filename
# -------------------------------------------------------------------

itcl::class pxitclcamera {

    inherit pxitclobject

    public variable camera 0 
    public variable delay 1.0
    public variable volclipvalues { -1 -1 -1 -1 -1 -1 }
    public variable polyclipvalues { -1 -1 -1 -1 -1 -1 }
    constructor { } {
	pxitclobject::constructor 
    } {
	set camera [ vtkCamera [ pxvtable::vnewobj ]]
	$camera ParallelProjectionOn
	set filename "None"
    }

    destructor  { $camera Delete  }


    # --- begin method def -----


    
    public method GetObject { } { return $camera }
    public method GetType { } { return [ $camera GetClassName ]} 
    public method GetDescriptionPiece { lst fmt } 
    public method GetDescription { } 
    public method UpdateStatus { } 
    public method Copy    { obj }
    public method Clear   { }
    public method Load { args }
    public method LoadStream { fout { mode "new" } }
    public method Save { args }
    public method SaveStream { fout }

    # Methods additional to pxitclobject
    public method GetCamera { } { return $camera }
    public method CopyCamera { obj }
    # --- end method def -----
}

# ------------------- End of Header ---------------------------------
itcl::body pxitclcamera::Copy   { obj  } {

    if { [ $obj isa pxitclcamera ] == 0 } {
	return 0
    }
    
    CopyCamera  [ $obj GetCamera ]  
    set filename [ $obj cget -filename ] 
    set delay    [ $obj cget -delay ]
    set volclipvalues [ $obj cget -volclipvalues ]
    set polyclipvalues [ $obj cget -polyclipvalues ]
    return 1
}
# ----------------------------------------------------------
itcl::body pxitclcamera::CopyCamera { oldcamera  } {
    
    set thistype "[ $camera GetClassName ]"
    if { [ $oldcamera IsA $thistype ] == 0 } {
	return
    }

    set ren [ vtkpxGUIRenderer [ pxvtable::vnewobj ] ]
    $ren CopyCamera $camera $oldcamera
    $ren Delete
}
# ----------------------------------------------------------
itcl::body pxitclcamera::GetDescriptionPiece { lst fmt } {

    set a ""
    for { set i 0 } { $i < [ llength $lst ] } { incr i } {
	set a [ format "%s $fmt" $a [ lindex $lst $i ] ]
    }
    return $a
}


itcl::body pxitclcamera::GetDescription { } {
    
    set line ""
    set line "Position : [ $this GetDescriptionPiece [ $camera GetPosition ] "%.0f" ] , FP = [ $this GetDescriptionPiece [ $camera GetFocalPoint ] "%.0f" ]"
    set line "$line\nScale : [ $camera GetParallelScale ] (Parallel = [ $camera GetParallelProjection ])"
    set line "$line\nView Up : [ $this GetDescriptionPiece [ $camera GetViewUp ] "%.2f" ]"
    set line "$line ClipRange : [ $this GetDescriptionPiece [ $camera GetClippingRange ] "%.1f" ]\nDuration = $delay"
    set line "$line\nVolClip  : [ $this GetDescriptionPiece $volclipvalues  "%.0f" ]"
    set line "$line\nPolyClip : [ $this GetDescriptionPiece $polyclipvalues "%.0f" ]"
    return $line 
}
# ----------------------------------------------------------
itcl::body pxitclcamera::Load { args } {
    
    set len [ llength $args ]
    if { [ string length $filename ] == 0 && $len == 0 } { return    }


    if { $len > 0 } {
	set f [ lindex $args 0 ]
    }  else {
	set f $filename
    }

    if { $len > 1 } { 
	set desc [ lindex $args 1 ]
    } else {
	set desc "Camera"
    }

    if { [ string length $f ] < 1 } { 
	set typelist { 
	    {"Camera File" {.cmf}} 
	    {"All Files" {*}}}
	
	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set f [tk_getOpenFile -title "Load $desc" -initialfile $f2tail -filetypes $typelist -initialdir $f2path]
    }

    if { [string length $f ] < 2 || $f=="identity" } {
	return 0;
    }
    
    set filename  $f
    set fin [ open $filename r ]
    gets $fin line
    if { [ string trim $line  ] == "\#Camera File"  } {
	set ok [ LoadStream $fin old ]
    }
    close $fin
    return $ok

}
# ----------------------------------------------------------
itcl::body pxitclcamera::LoadStream { fin { mode "new" } } {

    if { $mode == "old" } {
	gets $fin line
	scan $line "%f %f %f %f %f %f %f %f %f %f %f %f %f %f " fx fy fz px py pz nx ny nz cf cb pp parscale dl
	set volclipvalues { -1 -1 -1 -1 -1 -1 }
	set polyclipvalues { -1 -1 -1 -1 -1 -1 }
	set dl 1.0
    } else {
	gets $fin line

        scan $line "%f %f %f %f %f %f %f %f %f %f %f %f %f %f" \
	    fx fy fz px py pz nx ny nz cf cb pp parscale dl

	gets $fin line

	scan $line " %f %f %f %f %f %f %f %f %f %f %f %f" \
	    c1 c2 c3 c4 c5 c6 p1 p2 p3 p4 p5 p6



	set volclipvalues  [ list $c1 $c2 $c3 $c4 $c5 $c6 ]
	set polyclipvalues [ list $p1 $p2 $p3 $p4 $p5 $p6 ]
    }
    $camera SetFocalPoint $fx $fy $fz
    $camera SetPosition   $px $py $pz
    $camera SetViewUp     $nx $ny $nz
    $camera ComputeViewPlaneNormal
    $camera SetClippingRange     $cf $cb
    $camera SetParallelProjection [ expr round($pp) ]
    $camera SetParallelScale $parscale
    set delay $dl
    return 1
}
# ----------------------------------------------------------
itcl::body pxitclcamera::Save { args } {

    set f     ""
    set desc "Camera"
    
    
    if { [ llength $args ] > 0 } {
	set f [ lindex $args 0 ]
    } 
    if { [ llength $args ] > 1 } { 
	set desc [ lindex $args 1 ]
    }

    if { [ string length $f ] < 1 } { 
	set f1 $filename  
	set f1path [ file dirname $f1 ]
	set f1tail [ file tail    $f1 ]
	set f  [tk_getSaveFile -title "Saving $desc" -initialfile $f1tail -initialdir $f1path -filetypes { {"Camera Files" {.cml}} } ]
    }

    if { [string length $f ] < 0 } {
	return 0
    }
    set filename  $f
    set fout [ open $filename $w ]
    puts $fout "\#Camera File"
    $this SaveStream $fout
    close $fout
    return 1
}

itcl::body pxitclcamera::SaveStream { fout } {

    scan  "[ $camera GetFocalPoint ]" "%f %f %f" fx fy fz
    scan  "[ $camera GetPosition   ]" "%f %f %f" px py pz
    scan  "[ $camera GetViewUp ]"     "%f %f %f" nx ny nz
    scan  "[ $camera GetClippingRange ]" "%f %f" cf cb
    scan  "[ $camera GetParallelProjection ]" "%f" pp
    scan  "[ $camera GetParallelScale ]" "%f" parscale
    set a [ format "%.1f %.1f %.1f %.1f %.1f %.1f" [ lindex $volclipvalues 0 ] \
		[ lindex $volclipvalues 1 ] [ lindex $volclipvalues 2 ] \
		[ lindex $volclipvalues 3 ] [ lindex $volclipvalues 4 ] [ lindex $volclipvalues 5 ] ]

    set b [ format "%.1f %.1f %.1f %.1f %.1f %.1f" [ lindex $polyclipvalues 0 ] \
		[ lindex $polyclipvalues 1 ] [ lindex $polyclipvalues 2 ] \
		[ lindex $polyclipvalues 3 ] [ lindex $polyclipvalues 4 ] [ lindex $polyclipvalues 5 ] ]

    
    puts $fout [ format "%.1f %.1f %.1f \t %.1f %.1f %.1f \t %.3f %.3f %.3f \t %.1f %.1f \t %.0f %.1f \t %.1f\n\t $a\t $b" \
		     $fx $fy $fz $px $py $pz $nx $ny $nz $cf $cb $pp $parscale $delay ]

#    puts -nonewline $fout "[ $camera GetFocalPoint ]"
#    puts -nonewline $fout "\t[ $camera GetPosition   ]"
#    puts -nonewline $fout "\t[ $camera GetViewUp ]"
#    puts -nonewline $fout "\t[ $camera GetClippingRange ]"
#    puts -nonewline $fout "\t[ $camera GetParallelProjection ]"
#    puts -nonewline $fout "\t[ $camera GetParallelScale ]"
#    puts $fout "\t$delay"
}
# ----------------------------------------------------------
itcl::body pxitclcamera::Clear { } {

    $camera SetFocalPoint 0 0 0 
    $camera SetPosition  0 0 0 
    $camera SetViewUp   0 1 0
    $camera ComputeViewPlaneNormal
    $camera SetParallelProjection 1
    $camera SetParallelScale 1.0
    $camera SetClippingRange 0 1
    set     volclipvalues { -1 -1 -1 -1 -1 -1 }
    set     polyclipvalues { -1 -1 -1 -1 -1 -1 }
    set filename "identity"
}

# ----------------------------------------------------------
#  GUI for pxitclcamera
# ----------------------------------------------------------

itcl::class pxitclcameraGUI {

    inherit pxitclobjectGUI


    constructor { } {
	pxitclobjectGUI::constructor
    } { 
	set thisparam($this,status) "vtkCamera"
	set thisparam($this,shortfilename) None
	set thisparam($this,delaytime) 0
	set  description "Camera"
	set  filename "identity.cml"
	set  numlines 8
	Reset
    }

    destructor { }

    public    method Initialize { basewidg } 
    public    method GetCamera { } { return $itclobject  }
    public    method SetCamera { tr } 
    public    method Update { }
    public    method UpdateDelay { }
    protected method CreateNewObject { } 
    public method SetObject { tr } { return [ $this SetCamera $tr ] }

}
# ----------------------------------------------------------
itcl::body pxitclcameraGUI::CreateNewObject { } {

    set itclobject  [ [  pxitclcamera \#auto ] GetThisPointer ]
}



itcl::body pxitclcameraGUI::SetCamera { trn } {
    
    set continue 0
    
    catch { 
	if { [ $trn isa pxitclcamera ] == 1 } {
	set  continue 1
	}
    }

    if { $continue == 0 } {
	return 0 
    }
	
	
    if { $owns_object == 1} {
	catch { itcl::delete object $itclobject }
    }

    set itclobject $trn
    
    set owns_object 0
    Update
}

itcl::body pxitclcameraGUI::Initialize { basewidg } {

    if { $initialized == 1 } { return $basewidget }
    
    pxitclobjectGUI::Initialize $basewidg
    set thisparam($this,delaytime) 2.0
    iwidgets::entryfield $buttonbar.del -labeltext Duration:  -width 7 -validate real -textvariable [ itcl::scope thisparam($this,delaytime) ] -relief sunken
    eval "button $buttonbar.in -text \"Update\" -command {  $this UpdateDelay }"
    pack $buttonbar.del  $buttonbar.in  -side left -fill x -expand f
    pack forget $statusbar
    $thisparam($this,descriptionbox) configure -width 45
    Update
    return $basewidget
}

itcl::body pxitclcameraGUI::UpdateDelay {  } {

    set d $thisparam($this,delaytime)
    if { $d < 0.1 } { set d 0.1 } 
    if { $d > 20.0 } { set d 20.0 }
    set thisparam($this,delaytime) $d

    $itclobject configure -delay $thisparam($this,delaytime)
    $this Update
}

itcl::body pxitclcameraGUI::Update { } {
    set thisparam($this,delaytime) [ $itclobject cget -delay ]
    pxitclobjectGUI::Update
}
# ----------------------------------------------------------
#  GUI for multiple camera object
# ----------------------------------------------------------
itcl::class pxitclmultiCameraGUI {

    inherit pxitclmultiObjectGUI

    constructor { } {
	pxitclmultiObjectGUI::constructor
    } {
	set description "Camera Control"
	set enableupdown 1
    }
    
    destructor { }
    
    public    method Initialize { basewidg } 

    public    method AddCamera { descr }
    public    method SetCamera { index } 
    public    method GetCamera { index } { return [ GetObject $index ] }
    public    method DeleteCamera { index } { DeleteObject $index }

    protected method CreateNewObject { }
    protected method CreateNewObjectGUI { widget }

}

# ----------------------------------------------------------
itcl::body pxitclmultiCameraGUI::CreateNewObject { } {
    
    return [ [  pxitclcamera \#auto ] GetThisPointer ]
}

itcl::body pxitclmultiCameraGUI::CreateNewObjectGUI { widget } {
    set itclcameraGUI [ [ pxitclcameraGUI \#auto ] GetThisPointer ]
    pack [ $itclcameraGUI Initialize $widget.[ pxvtable::vnewobj ] ] -side left -fill x
    return $itclcameraGUI
}

itcl::body pxitclmultiCameraGUI::AddCamera { descr } {
    
    set newobj [ $this AddObject $descr ]
    set index [ expr [ llength $itclobjectlist ] -1 ]
    $this SetCamera $index
    return $newobj
}

itcl::body pxitclmultiCameraGUI::SetCamera { index } {

    $this SetObject $index
    $objectGUI Update
}

itcl::body pxitclmultiCameraGUI::Initialize { basewidg } {
    
    if { $initialized == 1 } { 
	return $basewidget 
    }
    
    pxitclmultiObjectGUI::Initialize $basewidg

    $listbox configure -selectmode single -exportselection 0
    set initialized 1
    
    return $basewidget
}
 

