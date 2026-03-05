#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" -- "$@"

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

package provide bis_landmarkeditor 1.0

# 	$Id: bis_landmarkeditor.tcl,v 1.4 2004/02/17 20:58:26 xenios Exp xenios $	

if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    lappend auto_path [ file dirname [ info script ]]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] main]
}





# Added some capability

package require pxvtable 1.0
package require Itcl
package require Iwidgets 
package require pxitclbasecontrol 1.0
package require bis_viewer 1.0

itcl::class bis_landmarkeditor {

    inherit pxitclbasecontrol

    private variable vtk_viewer 0
    private variable bis_viewer 0

    protected variable polymanager 0
    private variable itcllandmarks 0
    private variable landmarks 0
    private variable back_landmarks 0

    private variable highlight_sphere 0
    private variable highlight_surface 0

    private variable last_picked_point -1

    protected variable nomouseinput 0
    private common   thisparam
    protected variable initialized 0
    protected variable fontname "{ fixed 8 }"
    public variable selectionbox 0
    protected variable last_filename ""


    protected variable datatree 0
    protected variable xmlpointer 0
    protected variable filemenu 0


    
    constructor { par } {
	pxitclbasecontrol::constructor $par
    } {
	InitializeLandmarkControl
    }

    # Fixed
    private method InitializeLandmarkControl { } 

    # Viewer Interface
    protected method SetViewer  { viewer }
    protected method AddToViewer  {  }
    public method GetViewer  {  } { return $bis_viewer }

    public method SetNoMouseInput { } { set nomouseinput 1 }
    public method Initialize { inpwidg viewer }
    public method DelayedInitialize { }


    # -------------------------------------

    # Create User Interface Stuff
    # -------------------------------------
    protected method CreateMenu { menubar }
    public method UpdateInterface { }
    public method UpdateStatus { }
    public method SelectedLandmark { } 
    public method DisplayAttributes { }
    public method CenterOnLandmark { mode } 
    public method SetColor { }

    # ----------------------------------------
    # Menu/Mouse Callbacks
    # ----------------------------------------
    public method HandleClickedPoint { vx pt mouse stat }
    public method PickLandmark { x y z } 
    public method MovePickedLandmark { x y z} 
    public method ReleaseLandmarkPick { args } 
    public method UndoLast { }
    public method DeleteLandmark { }
    public method DeleteAllLandmark { }

    # -----------------------------------
    # Load and Save Stuff
    # -----------------------------------
    public method TreeEditLandmarks { land datatree node }
    public method LoadLandmarks { fname }
    public method StoreInTree { }
    public method SaveLandmarks { fname }
    public method AutoSaveLandmarks { mode }
    public method EnableAutoSave { }

    

}
# -------------------------------------------------------------------------------------------    
::itcl::body bis_landmarkeditor::InitializeLandmarkControl { }  {

    global tcl_platform
    if { $tcl_platform(platform) == "windows" } {
	set fontname "{ fixed 5 }"
    } else {
	set fontname "{ fixed 8 }"
    }

    set itcllandmarks  [ [ pxitcllandmarks \#auto ] GetThisPointer ]
    set landmarks [ $itcllandmarks GetObject ]
    set back_landmarks [ vtkpxBaseCurve [ pxvtable::vnewobj ]]


    set thisparam($this,autosave) 1
    set thisparam($this,autosaveon) 0
    set thisparam($this,current_landmark) 0 
    set thisparam($this,readonly) 2
    set thisparam($this,status) ""
    set thisparam($this,mousemode) 0
}
  
   
# Sets the input
::itcl::body bis_landmarkeditor::SetViewer { bviewer } {

    if { $bis_viewer != 0 } {
	return 0
    }

    if { [ $bviewer isa bis_viewer ] == 0 } {
	return 0
    }


    set bis_viewer $bviewer
    set vtk_viewer [ $bviewer GetViewer ]
    set polymanager [ $bis_viewer GetPolygonalDisplayManager ]
}


::itcl::body bis_landmarkeditor::AddToViewer { } {

    $bis_viewer AddCursorNotifier "$this" "HandleClickedPoint"

 
    set highlight_sphere [ vtkpxCrossHairSource New ]
    set highlight_surface [ [ pxitclsurface \#auto ] GetThisPointer ]
    $highlight_surface ShallowCopySurface [ $highlight_sphere GetOutput ]

    $bis_viewer AddPolygonalObject $itcllandmarks 1 { visible 1 name "LndmrkEdit_1" } 
    $bis_viewer AddPolygonalObject $highlight_surface 1 { visible 0 name "LndmrkEdit_2" } 
    $polymanager UpdateObject $itcllandmarks
    return 1
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_landmarkeditor::Initialize { inpwidg bviewer } {

    global tcl_platform

    if { $initialized } { return $basewidget } 

    set basewidget [ toplevel $inpwidg ]
    wm withdraw $basewidget
    wm title $basewidget "Landmark Editor"
    wm geometry $basewidget 300x300
    eval "wm protocol $basewidget WM_DELETE_WINDOW { wm withdraw $basewidget }"
    set initialized 1

    if { $bviewer !=0 } {
	SetViewer $bviewer
    }
    return $basewidget

}

::itcl::body bis_landmarkeditor::DelayedInitialize { } {
   
    if { $fullyinitialized == 1 } {
	return
    }

    set last_filename ""


    set menubar [ menu $basewidget.menubar ]; $basewidget configure -menu $menubar


    
    if { $bis_viewer == 0 } {
	set nt [ panedwindow $basewidget.nt -orient horizontal -showhandle 1 \
		     -borderwidth 10 -relief raised -sashwidth 4 -sashpad 4 \
		     -handlesize 5 -handlepad 50  ]
	pack $nt -side top -expand true -fill both
	set mainframe [frame $nt.left ]
	set vframe   [ frame $nt.right ]
	$nt add $mainframe -minsize  500
	$nt add $vframe -minsize 500
	set viewer [ bis_viewer \#auto ]
	$viewer CreateGUI $vframe
	$this SetViewer [ $viewer GetThisPointer ]
    } else {
	set mainframe [ frame $basewidget.notebook ]
	pack $mainframe -side top -expand true -fill both -pady 2 -padx 2
    }
    
    $this AddToViewer    
    set ttop [ frame $mainframe.0  ]
    set top [ [ iwidgets::labeledframe $mainframe.1  -labeltext "Info"  ] childsite ]
    set bot [ [ iwidgets::labeledframe $mainframe.2  -labeltext "Points"  ] childsite ]
    set bbar [ frame $mainframe.3 ]

    pack $bbar -side bottom -expand false -fill x -pady 2

    pack $mainframe.0 $mainframe.1 -side top -expand false -fill x
    pack $mainframe.2 -side top -expand true -fill both


    set thisparam($this,mousemode) 0
    if { $nomouseinput == 0 } {    
	eval "radiobutton $ttop.1 -text \"Disabled\" -value 0 -variable [ itcl::scope thisparam($this,mousemode) ]"
	eval "radiobutton $ttop.2 -text \"Pick Mode\"     -value 1 -variable [ itcl::scope thisparam($this,mousemode) ]"
	eval "radiobutton $ttop.3 -text \"Add Mode\"      -value 2 -variable [ itcl::scope thisparam($this,mousemode) ]"
	pack $ttop.1 $ttop.2 $ttop.3 -side left -padx 0
    }

    CreateMenu $menubar

    # ------------------------------------------------------------------------------------------
    #  info box
    # ------------------------------------------------------------------------------------------
    set ent1 [ ::iwidgets::entryfield $top.ent -width 40 -state normal -labeltext "" -foreground black -textbackground white -textvariable [ itcl::scope thisparam($this,status) ]]
    pack $ent1 -side top -expand true -fill x


    set selectionbox $bot.a
    eval "iwidgets::scrolledlistbox $bot.a -selectmode single -labelpos nw -vscrollmode dynamic -hscrollmode dynamic -selectioncommand { $this SelectedLandmark } -exportselection 1"
    

    eval "button $bbar.0 -text \"Undo Last Deletion\" -command { $this UndoLast } -padx 5"
    eval "button $bbar.1 -text \"Delete Current\" -command { $this DeleteLandmark } -padx 5"
    eval "button $bbar.2 -text \"Display Attributes\" -command { $this DisplayAttributes } -padx 5"
    pack $bbar.0 $bbar.1 $bbar.2 -side top -expand true -fill x
    pack $bot.a -side top -expand true -fill both -padx 2 -pady 2
    set fullyinitialized 1
    set l [ AddLogoLabel $bbar ];     pack $l -side bottom -padx 1 
}

# -----------------------------------------------------------------------------------------------------------
itcl::body bis_landmarkeditor::UndoLast  { } {

    $landmarks Copy $back_landmarks
    $this UpdateInterface
    $polymanager UpdateObject $itcllandmarks
}

itcl::body bis_landmarkeditor::DeleteLandmark { } {

    set ind $thisparam($this,current_landmark) 
    set n [ $landmarks GetNumPoints ]
    if { $ind <0 || $ind>=$n } {
	return ""
    }
    
    $back_landmarks Copy $landmarks

    $landmarks DeletePoint $ind

    set sel [ expr $ind -1 ]
    if { $sel < 0 } {
	set sel 0
    }
    $this UpdateInterface
    $selectionbox selection clear 0 end
    if { $n > 1 } {
	$selectionbox selection set $sel $sel
	$this SelectedLandmark
    }


    $polymanager UpdateObject $itcllandmarks
}

itcl::body bis_landmarkeditor::DeleteAllLandmark { } {

    set ok [ tk_messageBox -type yesno -default no -title "Think again ..." -message "Do you want to delete all points?" -icon question  ]
    if { $ok == "no" } {
	return 0
    }
    $back_landmarks Copy $landmarks
    $landmarks DeleteAllPoints
    $this UpdateInterface
    $polymanager UpdateObject $itcllandmarks
}

itcl::body bis_landmarkeditor::SelectedLandmark { }  {

    set ind [ [ $selectionbox component listbox ] curselection ]
    if { $ind == "" || $ind < 0 } {
	$polymanager UpdateSameObject $highlight_surface { visible 0 } 1
	return 
    }
    set thisparam($this,current_landmark) $ind

    set r [ expr [ $landmarks GetPointScale ] * 2.5 ]
    scan [ [  $landmarks GetPoints ] GetPoint $ind ] "%f %f %f" x y z
    scan  [  $landmarks GetOrigin ]  "%f %f %f"  ox oy oz
    scan  [  $landmarks GetSpacing ]  "%f %f %f" sx sy sz

    $highlight_sphere SetPosition [ expr $x*$sx +$ox ] [ expr  $y*$sy +$oy ] [ expr $z * $sz + $oz ]
    $highlight_sphere SetLength $r
    $highlight_sphere Update
    $highlight_surface ShallowCopySurface [ $highlight_sphere GetOutput ]
    eval "$polymanager UpdateSameObject $highlight_surface { visible 1 } 1"
}

itcl::body bis_landmarkeditor::DisplayAttributes { } {

    $polymanager SetCurrentObject $itcllandmarks
    $polymanager ShowWindow
}
# -----------------------------------------------------------------------------------------------------------
# Menu stuff
# -------------------------------------------------------------------------------------------
::itcl::body bis_landmarkeditor::CreateMenu { menubase } {

    set mb [ menu $menubase.filem -tearoff 0 ]
    $menubase add cascade -underline 0  -label File -menu $mb

    eval "$mb add command -label Load -command { $this LoadLandmarks \"\" }"
    eval "$mb add command -label Save -command { $this SaveLandmarks \"\" }"
    $mb add separator
    eval "$mb add command -label Close -command { $this HideWindow }"

    set filemenu  $mb

    set mb [ menu $menubase.editm -tearoff 0 ]
    $menubase add cascade -underline 0  -label Edit -menu $mb
    eval "$mb add checkbutton -label \"Auto Save\" -variable [ itcl::scope thisparam($this,autosave) ] -command { $this EnableAutoSave}"
    $mb add separator
    set thisparam($this,mousemode) 0
	eval "$mb add radiobutton -label \"Disabled Mode\"  -value 0 -variable [ itcl::scope thisparam($this,mousemode) ]"
	eval "$mb add radiobutton -label \"Pick Mode\"  -value 1 -variable [ itcl::scope thisparam($this,mousemode) ]"
	eval "$mb add radiobutton -label \"Add Mode\"  -value 2 -variable [ itcl::scope thisparam($this,mousemode) ]"
	$mb add separator
    if { $nomouseinput == 0 } {
	eval "$mb add command -label \"Delete Landmark\" -command { $this DeleteLandmark }"
	eval "$mb add command -label \"Delete All Landmarks\" -command { $this DeleteAllLandmark }"
    }
}
# -------------------------------------------------------------------------------------------
#
# Pick and Edit Stuff 
#
# -------------------------------------------------------------------------------------------
::itcl::body bis_landmarkeditor::PickLandmark { x y z } {

    if { $last_picked_point !=-1 } {
	return 0
    }

    set pt [ [  $landmarks GetPoints ] GetPoint $last_picked_point ]
    scan $pt "%f %f %f" px py pz
	
    set r [ expr [ $landmarks GetPointScale ] * 2.5 ]
    $highlight_sphere SetPosition $x $y $z
    $highlight_sphere SetRadius $r
    $highlight_sphere Update

    $highlight_surface ShallowCopySurface [ $highlight_sphere GetOutput ]
    eval "$polymanager UpdateSameObject $highlight_surface { visible 1 } 0"
    $polymanager UpdateSameObject $itcllandmarks 
    return 1
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_landmarkeditor::MovePickedLandmark { x y z }  {

    if { $last_picked_point == - 1 } {
	return 0
    }

    $landmarks SetPoint $last_picked_point $x $y $z 1

    $selectionbox delete $last_picked_point $last_picked_point
    set pt  [ [ $landmarks GetPoints ] GetPoint $last_picked_point ]
    scan $pt "%f %f %f" px py pz
    set line [ format "Point: %.3f %.3f %.3f"  $px $py $pz ]
    $selectionbox insert $last_picked_point $line
    $selectionbox selection clear 0 end
    $selectionbox selection set $last_picked_point $last_picked_point


    $highlight_sphere SetPosition $x $y $z
    $highlight_sphere Update
    
    $highlight_surface ShallowCopySurface [ $highlight_sphere GetOutput ]
    $polymanager UpdateSameObject $highlight_surface { visible 1 } 0
    $polymanager UpdateSameObject $itcllandmarks { visible 1 }
    return 1
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_landmarkeditor::ReleaseLandmarkPick { args } {

    if { $last_picked_point == -1 } {
	return 0
    }
    
    $polymanager UpdateSameObject $highlight_surface { visible 1 } 0
    $polymanager UpdateSameObject $itcllandmarks 
    set last_picked_point -1
    
    return 1
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_landmarkeditor::HandleClickedPoint { vx pt mode stat } {

    if { $thisparam($this,mousemode) == 0 } {  return 0 }

    set a [ wm state $basewidget  ]
    if { $a != "normal" } {
	return 0
    }
    

    if { [ llength $pt ] !=3 } { return 0 }

    scan $pt  "%f %f %f" x y z
    if { $x == -1.0 && $y == -1.0 && $z == -1.0 } {  return 0 }
    set ok 0
    
    if { $mode == -1 && $stat == -1 } {
	return 0
    }

    if { $mode == 1 &&  $stat == 0 &&  $last_picked_point == -1 } { 
	set r [ expr [ $landmarks GetPointScale ] * 2.5 ]
	set index [  $landmarks FindClosestPoint $x $y $z $r 1 ]
	if { $index >=0 } { 
	    set last_picked_point $index
	    set ok [ PickLandmark  $x $y $z  ]
	}
    } 

    if { $last_picked_point == -1 && $mode==1 && $stat == 0 &&  $thisparam($this,mousemode) == 2 } {
	puts stderr "Adding points here .............."
	$landmarks AddPoint $x $y $z 1 
	$this UpdateInterface
	set n [ $landmarks GetNumPoints ]
	$selectionbox selection clear 0 end
	$selectionbox selection set end end
	$this  SelectedLandmark
	set last_picked_point [ expr $n -1 ]
	$this PickLandmark $x $y $z
#	$this UpdateStatus
    }


    if { $stat == 1 && $last_picked_point !=-1 } {
	
	set ok [ MovePickedLandmark $x $y $z ]
	
    } elseif { $stat == 2 && $last_picked_point !=-1 } {
	
	set ok [ ReleaseLandmarkPick $x $y $z  ]
	
    }

    return $ok
}
# ---------------------------------------------------------------------------------------------
# Callback Stuff
# ---------------------------------------------------------------------------------------------
itcl::body bis_landmarkeditor::TreeEditLandmarks { land dtree node } {


    if { [ $land isa pxitcllandmarks  ] == 0 } {
	return 0
    }

    set old $datatree

    set datatree $dtree
    set xmlpointer $node



    $itcllandmarks Copy $land
    set landmarks [ $itcllandmarks GetObject ]

    set last_filename ""
    set f [ $node GetAttribute Title ]
    SetTitle "(DataTree) Landmark Editor node=$f"
    UpdateInterface
    $polymanager SetCurrentObject $itcllandmarks
    $polymanager UpdateSameObject $itcllandmarks { visible 1 } 
    puts stderr "Done ..."

#    if { $old == 0 } {
#	$filemenu add separator
#	eval "$filemenu add command -label \"Update Tree\" -command { $this StoreInTree }"
#    }
}
# ------------------------------------------------------------------------
itcl::body bis_landmarkeditor::StoreInTree {  } {

    if { $datatree == 0 } {
	return
    }

    $datatree UpdateEditedSurface $xmlpointer $itcllandmarks

}
# ------------------------------------------------------------------------

itcl::body bis_landmarkeditor::LoadLandmarks { fname } {

    if { $landmarks == 0 } {
	return 0
    }

    if { $fname == "" } {
	set typelist { 
	    {"Landmark Grid Files" {".mgrid*" } }
	    {"All Files" {*}}
	}
	
	set f1 $last_filename
	set f1path [ file dirname $f1 ]
	set f1tail [ file tail    $f1 ]

	set fname [tk_getOpenFile -title "Load Landmark Multi Grid File" -filetypes $typelist -initialfile $f1tail -initialdir $f1path ]
    }
    
    if { [ string length $fname ] < 1 } {
	return 0
    }

    set ok [ $itcllandmarks Load $fname ]
    if { $ok > 0 } {
	set last_filename $fname
	SetTitle "Landmark Editor [ file tail $last_filename]"
	UpdateInterface
	$polymanager SetCurrentObject $itcllandmarks
	$polymanager UpdateSameObject $itcllandmarks { visible 1 } 

	set datatree 0
	set xmlpointer 0
    }



    return $ok
}

# -------------------------------------------------------------------------------------------
itcl::body bis_landmarkeditor::SaveLandmarks { fname } {

    if { $landmarks == 0 } {
	return 0
    }

    if { $fname == "" } {
	set typelist { 
	    {"Landmark Grid Files" {".mgrid*" } }
	    {"All Files" {*}}
	}
	
	set f1 $last_filename
	set f1path [ file dirname $f1 ]
	set f1tail [ file tail    $f1 ]
	set fname [tk_getSaveFile -title "Save Landmark Multi Grid File" -filetypes $typelist -initialfile $f1tail -initialdir $f1path ]
    }
    
    if { [ string length $fname ] < 1 } {
	return 0
    }

    set ok [ $itcllandmarks Save $fname ]

    if { $ok > 0 } {
	set last_filename $fname
	SetTitle "Landmark Editor [ file tail $last_filename]"
    }
    
    return $ok
}


# -------------------------------------------------------------------------------------------
itcl::body bis_landmarkeditor::EnableAutoSave { } {

    if { $thisparam($this,autosave) == 0 } {
	set thisparam($this,autosaveon) 0
    } else {
	AutoSaveLandmarks once
    }
}

itcl::body bis_landmarkeditor::AutoSaveLandmarks { mode } {

    if { $thisparam($this,autosaveon) == 1 && $mode =="once" } {
	return 0
    }

    if { $thisparam($this,autosave) == 0 } {
	set thisparam($this,autosaveon) 0
	return 0
    }

    if { $last_filename == "" } {
	set last_filename "autosave"
    }

    set l_filename "[ file root $last_filename]_autosave.land"
    
    if { $thisparam($this,readonly) != 2 } {
	set ok [ $landmarks Save $l_filename ]
    } else {
	set ok 1
    }
    
    if { $thisparam($this,autosaveon) == 0 } {
	set thisparam($this,autosaveon) 1
    }
    
    eval "after 30000  $this AutoSaveLandmarks timer"

    return $ok
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_landmarkeditor::UpdateStatus { } {

    set fn [ file tail [ $itcllandmarks cget -filename ]]
    set thisparam($this,status) "[$itcllandmarks GetShortDescription] $fn"
}
# ------------------------------------------------------------------------------------------

::itcl::body bis_landmarkeditor::UpdateInterface { } {

    $this UpdateStatus
    $selectionbox delete 0 end
    set n [ $landmarks GetNumPoints ]
    
    for { set i 0 } { $i < $n } { incr i } {
	set pt  [ [ $landmarks GetPoints ] GetPoint $i ]
	scan $pt "%f %f %f" px py pz

	set line [ format "Point: %.3f %.3f %.3f"  $px $py $pz ]
	$selectionbox insert end $line
    }
    $selectionbox selection clear 0 end
    $selectionbox selection set end end
}

# -------------------------------------------------------------------------------------------
::itcl::body bis_landmarkeditor::CenterOnLandmark { mode } {

    set point [ [ $landmarks  GetPoints ] GetPoint $thisparam($this,current_landmark) ]
    scan [ $point GetPosition ] "%f %f %f" p(0) p(1) p(2)
    set img [ $vtk_viewer GetImage ]
    

    $vtk_viewer SetScaledCoordinates $p(0) $p(1) $p(2)

    if { $mode > 0  } {
	# Clip Stuff Also

	set camera [ [ [ $vtk_viewer GetRenderer 3 ] GetRenderer ] GetActiveCamera ]

	scan [ $camera GetPosition ]  "%f %f %f" c(0) c(1) c(2)
	scan [ $camera GetFocalPoint ] "%f %f %f" f(0) f(1) f(2)


	for { set i 0 } { $i<=2} { incr i } {
	    set d($i) [ expr $f($i) - $c($i) ]
	    set p($i) [ expr $p($i) - $c($i) ]
	}
	set magn [ expr sqrt($d(0)*$d(0) + $d(1)*$d(1) + $d(2)*$d(2)) ]
	
	set dist 0.0
	for { set i 0 } { $i<=2} { incr i } {
	    set d($i) [ expr $d($i) / $magn ]
	    set dist [ expr $dist +  $p($i)*$d($i) ]
	}

	set sp 5.0
	if { $mode == 2 } {
	    set sp 20.0
	}

	$camera SetClippingRange [ expr $dist - $sp ] [ expr $dist+$sp]
	$polymanager UpdateSameObject $itcllandmarks 
    }
}

# -------------------------------------------------------------------------------------------
::itcl::body bis_landmarkeditor::SetColor { } {

    $polymanager SetCurrentObject $itcllandmarks
    $polymanager SetColor
}
# -------------------------------------------------------------------------------------------

if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {

    package require vtkpxcontrib
    wm withdraw .


    set tp .[ pxvtable::vnewobj ] 

    set electrode_editor [ [ bis_landmarkeditor \#auto 0 ]  GetThisPointer ]
    $electrode_editor Initialize $tp 0
    wm geometry $tp 1024x800
    $electrode_editor DelayedInitialize

    if { [ llength $argv ] > 0 } {
	set img [ pxitclimage \#auto ]
	$img Load [ lindex $argv 0 ]
	[ $electrode_editor GetViewer ]  SetImage $img
	[ $electrode_editor GetViewer ]  SetImageColormapMode 0
	itcl::delete object $img
    }


    if { [ llength $argv ] > 1 } {
	set ok [ $electrode_editor LoadLandmarks [ lindex $argv 1 ] ]
    }
}

