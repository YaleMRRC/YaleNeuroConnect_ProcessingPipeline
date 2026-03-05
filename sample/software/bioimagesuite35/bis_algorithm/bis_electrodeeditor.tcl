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

package provide bis_electrodeeditor 1.0

# 	$Id: bis_electrodeeditor.tcl,v 1.4 2004/02/17 20:58:26 xenios Exp xenios $	

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
package require  labelframe 1.0
package require  pxitcllistselector  1.0
package require bis_viewer 1.0

itcl::class bis_electrodeeditor {

    inherit pxitclbasecontrol

    protected variable function_selector 0
    private variable vtk_viewer 0
    private variable bis_viewer 0
    protected variable polymanager 0
    private variable itclgrid 0
    private variable electrodemultigrid 0
    private variable back_electrodemultigrid 0
    private variable pick_sphere 0
    private variable pick_sphere_outline 0

    private variable pick_sphere_surface 0
    private variable pick_sphere_outline_surface 0
    private variable pick_sphere_outline_surface2 0



    private variable last_picked_electrode -1
    private variable grid_listbox 0
    private variable update_location_button 0
    private variable location_text 0

    protected variable nomouseinput 0
    private common   thisparam
    protected variable initialized 0
    protected variable fontname "{ fixed 8 }"
    protected variable last_filename "multigrid.mgrid"
    protected variable back_last_filename "none"

    public variable batch_selector 0

    private common functional_activations [ list "MotorFunction" "SensoryFunction" "VisualFunction" "LanguageFunction" "AuditoryFunction" "User1Function"  ]
    private common electrical_activations [ list "SeizureOnset" "SpikesPresent" ]
    private common other_attributes [ list "ElectrodePresent" ]
    private common electrode_attributes 0

    private variable last_radiobutton 0
    public  variable maxelectrodes 12


    private variable distance_array 0
    protected variable datatree 0
    protected variable xmlpointer 0
    protected variable filemenu 0
    
    constructor { par } {
	pxitclbasecontrol::constructor $par
    } {
	InitializeMultiGridControl
    }

    private method InitializeMultiGridControl { } 

    public method SetNoMouseInput { } { set nomouseinput 1 }
    public method Initialize { inpwidg viewer }
    public method DelayedInitialize { }
    protected method SetViewer  { viewer }
    protected method AddToViewer  {  }
    public method GetViewer  {  } { return $bis_viewer }


    # -------------------------------------

    # Create User Interface Stuff
    # -------------------------------------
    protected method CreateMenu { menubar }
    protected method CreateGridPropertySheet { par }
    protected method CreateElectrodePropertySheet { par }
    protected method CreatePatientPropertySheet { par }


    # --------------------------------------
    # Update Inteface Stuff
    # --------------------------------------
    public method UpdateInterface { }
    public method UpdateElectrodePropertySheet { }
    public method UpdateGridPropertySheet { }
    public method UpdatePatientPropertySheet { }
    public method UpdateVolumeTrace { }

    public method GetMultiGrid { } { [ return $electrodemultigrid ] }
    public method GetLastFilename { } { [ return $last_filename ] }
    # ----------------------------------------
    # Patient Callbacks
    # ----------------------------------------
    public method UpdatePatient { }
    public method UpdatePatientProperties { }
    public method SelectElectrodeGrid { index } 
    public method AddNewElectrodeGrid { }
    public method DeleteCurrentElectrodeGrid { }
    # ----------------------------------------
    # Grid Callbacks
    # ----------------------------------------
    public method UpdateElectrodeGridProperties { }
    public method SelectElectrode { } 
    public method ElectrodeShowValues { }
    public method CenterOnElectrode { mode } 
    public method GridColor { } 
    public method LabelsColor { } 
    public method ReorientGrid { mode } 
    public method PickFunction { }
    public method PickAndDisplayFunction { }
    public method ShowValues { }
    public method AutoWarp { mode }

    # ----------------------------------------
    # Electrode Callbacks
    # ----------------------------------------
    public method UpdateElectrodeProperties { }
    public method UpdateElectrodeLocationFromText { }

    # ----------------------------------------
    # Menu/Mouse Callbacks
    # ----------------------------------------
    public method HandleClickedPoint { vx pt mouse stat }
    public method PickElectrode { index args } 
    public method MovePickedElectrode { x y z} 
    public method ReleaseElectrodePick { args } 

    public method UndoMoveElectrode { }
    public method ShowGrids { mode }
    public method SelectGridsToDisplay { }
    public method ShowLabels { mode }
    public method DisableElectrodePropertySheet { }
    # -----------------------------------
    # Load and Save Stuff
    # -----------------------------------
    public method LoadElectrodeMultiGrid { fname }
    public method SaveElectrodeMultiGrid { fname }
    public method AutoSaveMultiGrid { mode }
    public method EnableAutoSave { }
    public method ExportAsSurface { fname }
    public method ExportPickedFunction { fname mode }
    public method ExportAsPixelImage { fname }
    
    # ---------------------------------------------
    # Tree Hooks
    # ---------------------------------------------
    public method TreeEditGrids { land dtree node }
    public method StoreInTree {  }

}
# -------------------------------------------------------------------------------------------    
::itcl::body bis_electrodeeditor::InitializeMultiGridControl { }  {

    global tcl_platform
    if { $tcl_platform(platform) == "windows" } {
	set fontname "{ fixed 5 }"
    } else {
	set fontname "{ fixed 8 }"
    }

    set itclgrid  [ [ pxitclelectrodemultigrid \#auto ] GetThisPointer ]
    set electrodemultigrid [ $itclgrid GetObject ]
    set back_electrodemultigrid [ vtkpxElectrodeMultiGridSource [ pxvtable::vnewobj ]]

    set distance_array [ vtkFloatArray [ pxvtable::vnewobj ]]
    $distance_array SetNumberOfTuples 4
    $distance_array FillComponent 0 -1.0
    $electrodemultigrid InitializeMultiGrid 1

    set thisparam($this,autosave) 1
    set thisparam($this,autosaveon) 0
    set thisparam($this,visible) "none"
    set thisparam($this,visiblelines) 1
    set thisparam($this,current_grid) 0 
    set thisparam($this,current_electrode) 0 
    set thisparam($this,current_electrode_index) 1
    set thisparam($this,current_position) "0.0 0.0 0.0"
    set thisparam($this,auto_pick)  0
    set thisparam($this,readonly) 2
    set thisparam($this,showlabels) 0
    set thisparam($this,showlabelsgap) 1
    set thisparam($this,pick_frame) 0
    set thisparam($this,electrodepropertylist) ""
    set thisparam($this,volume_voi_size) 10
    set thisparam($this,volume_weighted_voi) 0
    set thisparam($this,griduniformcolor) 1
    set electrode_attributes [ concat $functional_activations $electrical_activations $other_attributes ]
    set thisparam($this,current_electrode_radio) 0

}
  
   
# Sets the input
::itcl::body bis_electrodeeditor::SetViewer { bviewer } {

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

itcl::body bis_electrodeeditor::AddToViewer  {  } {

    $bis_viewer AddCursorNotifier "$this" "HandleClickedPoint"

    $vtk_viewer SetTraceVolumeVOI $thisparam($this,volume_voi_size)
    $vtk_viewer SetTraceVolumeWeightedMode $thisparam($this,volume_weighted_voi) 

    set pick_sphere [ vtkpxCrossHairSource [ pxvtable::vnewobj ]]
    set pick_sphere_outline [ vtkpxCrossHairSource [ pxvtable::vnewobj ]]

    set   pick_sphere_surface [ [ pxitclsurface \#auto ] GetThisPointer ]
    set   pick_sphere_outline_surface  [ [ pxitclsurface \#auto ] GetThisPointer ]
    set   pick_sphere_outline_surface2 [ [ pxitclsurface \#auto ] GetThisPointer ]

    $pick_sphere_surface ShallowCopySurface [ $pick_sphere GetOutput ]
    $pick_sphere_outline_surface ShallowCopySurface [ $pick_sphere GetOutput ]
    $pick_sphere_outline_surface2 ShallowCopySurface [ $pick_sphere GetOutput ]


    $bis_viewer AddPolygonalObject $itclgrid 1 { visible 1 gridfontsize 0 name "ElecEdit_1"}
    $bis_viewer AddPolygonalObject $pick_sphere_surface 1 { visible 0 color "1 0 0" name "ElecEdit_2" }
    $bis_viewer AddPolygonalObject $pick_sphere_outline_surface 1 { visible 0 color "1 1 0" name "ElecEdit_3" }
    $bis_viewer AddPolygonalObject $pick_sphere_outline_surface2 1 { visible 0 color "1 1 0" name "ElecEdit_4" }

    $polymanager UpdateObject $itclgrid
    $vtk_viewer UpdateDisplay
    return 1
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::Initialize { inpwidg bviewer } {

    global tcl_platform

    if { $initialized } { return $basewidget } 

    set basewidget [ toplevel $inpwidg ]
    wm withdraw $basewidget
    
    if { $tcl_platform(platform) == "windows" } {
	wm geometry $basewidget 680x730
    } else {
	wm geometry $basewidget 550x600
    }
    eval "wm protocol $basewidget WM_DELETE_WINDOW { wm withdraw $basewidget }"
    set initialized 1

    if { $bviewer !=0 } {
	SetViewer $bviewer
    }
    return $basewidget

}

::itcl::body bis_electrodeeditor::DelayedInitialize { } {
   
    if { $fullyinitialized == 1 } {
	return
    }

    set last_filename ""
    DisableElectrodePropertySheet


    set function_selector [ pxitcllistselector \#auto $basewidget.[ pxvtable::vnewobj ] ]
    $function_selector configure -singleoutput 1

    set menubar [ menu $basewidget.menubar ]; $basewidget configure -menu $menubar
    
    if { $bis_viewer == 0 } {
	set nt [ panedwindow $basewidget.nt -orient horizontal -showhandle 1 \
		     -borderwidth 10 -relief raised -sashwidth 4 -sashpad 4 \
		     -handlesize 5 -handlepad 50  ]
	pack $nt -side top -expand true -fill both
	set notebook [ iwidgets::tabnotebook $nt.notebook  -tabpos n   ]
	set vframe   [ frame $nt.right ]
	$nt add $notebook -minsize  500
	$nt add $vframe -minsize 500

	set viewer [ bis_viewer \#auto ]
	$viewer CreateGUI $vframe
	$this SetViewer [ $viewer GetThisPointer ]
    } else {
	set notebook $basewidget.notebook ; 
	iwidgets::tabnotebook $notebook  -tabpos n  
	pack $notebook -side top -expand true -fill both -pady 2 -padx 2
    }
    

    $this AddToViewer
    set bottom [ $notebook add -label  "Patient Info" ]
    set middle [ $notebook add -label  "Electrode Info" ]
    
    frame $middle.left -bg black ; frame $middle.right
    pack $middle.right -side right -expand false -fill y -padx 2 -pady 2
    pack $middle.left -side right -expand true -fill both -padx 2 -pady 2


    CreateMenu $menubar
    CreateGridPropertySheet $middle.left
    CreateElectrodePropertySheet $middle.right
    CreatePatientPropertySheet $bottom

    set grid [ $electrodemultigrid GetElectrodeGrid 0 ]
    $grid SetElectrodeSpacing 10.0 10.0
    $grid SetRadius  2.0

    UpdateInterface
    $notebook view "Patient Info"
    DisableElectrodePropertySheet

    set batch_selector [ pxitcllistselector \#auto $basewidget.[ pxvtable::vnewobj ] ]
    set fullyinitialized 1

    set canvas [ [ $notebook component tabset ] component canvas ];     set l [ AddLogoLabel $canvas ];     pack $l -side right -padx 1 
}

# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::CreateMenu { menubase } {

    #menubutton $menubase.file -text "File"  -menu $menubase.file.m -underline 0
    set mb [ menu $menubase.filem -tearoff 0 ]
    #pack $menubase.file  -side left
    $menubase add cascade -underline 0  -label File -menu $mb

    eval "$mb add command -label Load -command { $this LoadElectrodeMultiGrid \"\" }"
    eval "$mb add command -label Save -command { $this SaveElectrodeMultiGrid \"\" }"
    $mb add separator
    
    $mb add cascade -underline 0  -label "Export" -menu $mb.cascade1
    set casc1 [ menu $mb.cascade1 -tearoff 0  ]

    eval "$casc1 add command -label \"Export Values As Text\" -command { $this ExportPickedFunction \"\" 0 }"
    eval "$casc1 add command -label \"Export as Surface\" -command { $this ExportAsSurface \"\" }"
    eval "$casc1 add command -label \"Export as Image (One Pixel per electrode)\" -command { $this ExportAsPixelImage \"\"  }"
    eval "$casc1 add command -label \"Export Picked Function\" -command { $this ExportPickedFunction \"\" dopick }"
    $mb add separator
    eval "$mb add command -label Close -command { $this HideWindow }"
    set filemenu $mb

    #    menubutton $menubase.edit -text "Edit"  -menu $menubase.editm -underline 0
    #pack $menubase.edit  -side left
    set mb [ menu $menubase.editm -tearoff 0 ]
    $menubase add cascade -underline 0  -label Edit -menu $mb


    eval "$mb add checkbutton -label \"Auto Save\" -variable [ itcl::scope thisparam($this,autosave) ] -command { $this EnableAutoSave}"
    $mb add separator
    eval "$mb add radiobutton -label \"Display Only Mode\" -command { $this DisableElectrodePropertySheet } -value 2 -variable [ itcl::scope thisparam($this,readonly) ]"
    eval "$mb add radiobutton -label \"Only Edit Attributes\" -command { $this DisableElectrodePropertySheet } -value 1 -variable [ itcl::scope thisparam($this,readonly) ]"
    if { $nomouseinput == 0 } {
	eval "$mb add radiobutton -label \"Full Edit Mode\" -command { $this DisableElectrodePropertySheet } -value 0 -variable [ itcl::scope thisparam($this,readonly) ]"
	$mb add separator
	eval "$mb add command -label \"Undo Move Electrode\" -command { $this UndoMoveElectrode }"
    }

    #   menubutton $menubase.display -text "Display"  -menu $menubase.displaym -underline 0
    #    pack $menubase.display  -side left
    set mb [ menu $menubase.displaym -tearoff 0 ]
    $menubase add cascade -underline 0  -label Display -menu $mb


    set l [ list current all none some ]
    set l2 [ list Current All None Some ]
    for { set i 0 } { $i <=2 } { incr i } {
	eval "$mb add radiobutton -label \"Show [ lindex $l2 $i]\" -command { $this ShowGrids [ lindex $l $i ] } -value [ lindex $l $i ] -variable [ itcl::scope thisparam($this,visible) ]"
    }
    eval "$mb add radiobutton -label \"Show [ lindex $l2 3]\" -command { $this SelectGridsToDisplay } -value [ lindex $l 3 ] -variable [ itcl::scope thisparam($this,visible) ]"
    $mb add separator 
    eval "$mb add checkbutton -label \"Show Grid Lines\" -command { $this ShowGrids -1 } -variable [ itcl::scope thisparam($this,visiblelines) ]"
    eval "$mb add checkbutton -label \"Uniform Color Grids\" -command { $this ShowGrids -1 } -variable [ itcl::scope thisparam($this,griduniformcolor) ]"
    $mb add separator
    eval "$mb add command -label \"Pick and Display Image Function\" -command { $this PickAndDisplayFunction }"
    $mb add separator
    eval "$mb add command -label \"Show Attributes\" -command { $this ShowValues }"

    set mb [ menu $menubase.gridm -tearoff 0 ]
    $menubase add cascade -underline 0  -label Grid -menu $mb
    #    menubutton $menubase.grid -text "Grid"  -menu $menubase.gridm -underline 0
    #    set mb [ menu $menubase.gridm -tearoff 0 ]
    #    pack $menubase.grid  -side left

    eval "$mb add command -label \"Grid Color\" -command { $this GridColor }"
    $mb add separator
    eval "$mb add command -label \"Grid Flip X\" -command { $this ReorientGrid 1 }"
    eval "$mb add command -label \"Grid Flip Y\" -command { $this ReorientGrid 2 }"
    eval "$mb add command -label \"Grid Transpose\" -command { $this ReorientGrid 0 }"
    $mb add separator

    eval "$mb add command -label \"Auto Warp\" -command { $this AutoWarp 1 }"
    eval "$mb add command -label \"Undo Auto Warp\" -command { $this AutoWarp 0 }"

    #    menubutton $menubase.labels -text "Labels"  -menu $menubase.labelsm -underline 0
    #    set mb [ menu $menubase.labelsm -tearoff 0 ]
    #    pack $menubase.labels  -side left

    set mb [ menu $menubase.labelm -tearoff 0 ]
    $menubase add cascade -underline 0  -label Labels -menu $mb

    eval "$mb add radiobutton -label \"Label Font 0\" -command  { $this ShowLabels 0  } -variable [ itcl::scope thisparam($this,showlabels) ] -value 0"
    eval "$mb add radiobutton -label \"Label Font 6\" -command { $this ShowLabels 6  } -variable [ itcl::scope thisparam($this,showlabels) ] -value 6"
    eval "$mb add radiobutton -label \"Label Font 8\" -command { $this ShowLabels 8  } -variable [ itcl::scope thisparam($this,showlabels) ] -value 8"
    eval "$mb add radiobutton -label \"Label Font 10\" -command { $this ShowLabels 10 } -variable [ itcl::scope thisparam($this,showlabels) ] -value 10"
    eval "$mb add radiobutton -label \"Label Font 12\" -command { $this ShowLabels 12 } -variable [ itcl::scope thisparam($this,showlabels) ] -value 12"
    eval "$mb add radiobutton -label \"Label Font 16\" -command { $this ShowLabels 16 } -variable [ itcl::scope thisparam($this,showlabels) ] -value 16"
    eval "$mb add radiobutton -label \"Label Font 24\" -command { $this ShowLabels 24 } -variable [ itcl::scope thisparam($this,showlabels) ] -value 24"
    eval "$mb add radiobutton -label \"Label Font 32\" -command { $this ShowLabels 32 } -variable [ itcl::scope thisparam($this,showlabels) ] -value 32"
    $mb add separator 
    eval "$mb add radiobutton -label \"All Labels \" -command  { $this ShowLabels -1 } -variable [ itcl::scope thisparam($this,showlabelsgap) ] -value 0"
    eval "$mb add radiobutton -label \"Skip 1\" -command { $this ShowLabels -1  } -variable [ itcl::scope thisparam($this,showlabelsgap) ] -value 1"
    eval "$mb add radiobutton -label \"Skip 2\" -command { $this ShowLabels -1  } -variable [ itcl::scope thisparam($this,showlabelsgap) ] -value 2"
    eval "$mb add radiobutton -label \"Skip 3\" -command { $this ShowLabels -1 } -variable [ itcl::scope thisparam($this,showlabelsgap) ] -value 3"
    eval "$mb add radiobutton -label \"Skip 5\" -command { $this ShowLabels -1 } -variable [ itcl::scope thisparam($this,showlabelsgap) ] -value 5"
    eval "$mb add radiobutton -label \"Skip 10\" -command { $this ShowLabels -1 } -variable [ itcl::scope thisparam($this,showlabelsgap) ] -value 10"
    #    eval "$mb add checkbutton -label \"Label All Electrodes\" -command { $this ShowLabels -1 } -variable [ itcl::scope thisparam($this,showlabelsgap) ]"
    $mb add separator 
    eval "$mb add command -label \"Labels Color\" -command { $this LabelsColor }"

    if { $nomouseinput == 0 } {
	#menubutton $menubase.voltrace -text "Volume Trace"  -menu $menubase.voltracem -underline 0
	#set mb [ menu $menubase.voltracem -tearoff 0 ]
	#pack $menubase.voltrace  -side left
	set mb [ menu $menubase.voltrace -tearoff 0 ]
	$menubase add cascade -underline 0  -label "Volume Trace" -menu $mb


	eval "$mb add checkbutton -label \"Weighted Centroid\" -variable [ itcl::scope thisparam($this,volume_weighted_voi) ] -command { $this UpdateVolumeTrace} "
	$mb add separator
	eval "$mb add radiobutton -label \"VOI Size 0\" -command { $this UpdateVolumeTrace} -value  0 -variable [ itcl::scope thisparam($this,volume_voi_size)]"
	eval "$mb add radiobutton -label \"VOI Size 1\" -command { $this UpdateVolumeTrace} -value  1 -variable [ itcl::scope thisparam($this,volume_voi_size)]"
	eval "$mb add radiobutton -label \"VOI Size 5\" -command { $this UpdateVolumeTrace} -value  5 -variable [ itcl::scope thisparam($this,volume_voi_size)]"
	eval "$mb add radiobutton -label \"VOI Size 10\" -command { $this UpdateVolumeTrace} -value 10 -variable [ itcl::scope thisparam($this,volume_voi_size)]"
	eval "$mb add radiobutton -label \"VOI Size 15\" -command { $this UpdateVolumeTrace} -value 15 -variable [ itcl::scope thisparam($this,volume_voi_size)]"
	eval "$mb add radiobutton -label \"VOI Size 20\" -command { $this UpdateVolumeTrace} -value 20 -variable [ itcl::scope thisparam($this,volume_voi_size)]"
	eval "$mb add radiobutton -label \"VOI Size 25\" -command { $this UpdateVolumeTrace} -value 25 -variable [ itcl::scope thisparam($this,volume_voi_size)]"
    }

    
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::PickFunction { } {

    set img [ $vtk_viewer GetImage ]
    $electrodemultigrid PickFunction $img 

    $electrodemultigrid Modified
    $polymanager UpdateSameObject $itclgrid 
    UpdateGridPropertySheet
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::ShowValues { } {

    set l "None"
    set n [ $electrodemultigrid GetNumberOfValues ]
    for { set i 0 } { $i < $n } { incr i } {
	lappend l "Attribute_[expr $i+1]"
    }

    
    $batch_selector configure -singleoutput 1
    $batch_selector Activate $l "" "Select which value index to display (only the first one will be used)" "Select Value Component To Display"
    set sel [ $batch_selector GetSelectedIndices ]

    if { [ llength $sel ] > 0 } {
	set newv [ expr [ lindex $sel 0 ] -1 ]
#	puts stderr "Setting Current Value Index $newv ($sel)"
	$electrodemultigrid SetCurrentValueIndex $newv
    } else {
	$electrodemultigrid SetCurrentValueIndex -1
    }
    
    $electrodemultigrid Modified
    $electrodemultigrid Update
    $polymanager UpdateSameObject $itclgrid 
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::PickAndDisplayFunction { } {

    set img [ $vtk_viewer GetImage ]
    $electrodemultigrid PickFunction $img 
    $electrodemultigrid SetElectrodeColorsFromFunction [ $vtk_viewer GetLookupTable ]
    $electrodemultigrid Modified;
    $polymanager UpdateSameObject $itclgrid 
}
# -------------------------------------------------------------------------------------------
#
# Pick and Edit Stuff 
#
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::PickElectrode { index args } {

    if { $thisparam($this,visible) == "none"  } {
	return 0
    }

    set editing_mode 1
    if { $thisparam($this,readonly) > 0 } {
	if { $index >=0 } {
	    set electrode [ [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] GetElectrode $index ]
	    set thisparam($this,current_electrode) $index
	    set thisparam($this,current_electrode_index) [ [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] GetElectrodeRealIndex $index  ]
	    set editing_mode 0
	}
    } else {
	if { $last_picked_electrode != - 1 } {
	    # Some Other Electrode is picked already release this first 
	    return 0
	}
	
	if { $index == - 1 } {
	    set index $thisparam($this,current_electrode)
	}
    }

    if { $index == -1 } {
	puts stdout "Nothing to do!"
	return 0
    }

    set egrid [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ]
    scan  [ $egrid GetDimensions ] "%d %d" dimx dimy
    set dimt [ expr $dimx * $dimy ]

    if { $index >= $dimt } {
	return 0
    }


    set electrode [ [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] GetElectrode $index ]

    if { $editing_mode == 1 } {
	scan [ $electrode GetPosition ] "%f %f %f" px py pz
	
	if { [ llength $args ] == 3 } {
	    set x [ lindex $args 0 ]
	    set y [ lindex $args 1 ]
	    set z [ lindex $args 2 ]
	    set  r [ expr 2.0 * [ $electrode GetRadius ]]
	} else {
	    set x $px
	    set y $py
	    set z $pz
	    set  r [ expr 2.0 * [ $electrode GetRadius ]]
	}

	
	$pick_sphere SetPosition $x $y $z
	$pick_sphere SetLength $r
	$pick_sphere_outline SetPosition $x $y $z
	$pick_sphere_outline SetLength $r
	
	scan [ $electrode GetColor ] "%f %f %f" cx cy cz
	
	$pick_sphere Update
	$pick_sphere_outline Update

	$pick_sphere_surface ShallowCopySurface [ $pick_sphere GetOutput ]
	$pick_sphere_outline_surface ShallowCopySurface [ $pick_sphere GetOutput ]
	$pick_sphere_outline_surface2 ShallowCopySurface [ $pick_sphere GetOutput ]

	eval "$polymanager UpdateSameObject $pick_sphere_surface { visible 1 } 0"
	eval "$polymanager UpdateSameObject $pick_sphere_outline_surface { visible 1 color \"$cz $cy $cz\" } 0"
	eval "$polymanager UpdateSameObject $pick_sphere_outline_surface2 { visible 1 color \"$cz $cy $cz\" } 0"

	$polymanager UpdateSameObject $itclgrid 
	
	set last_picked_electrode $index
	set thisparam($this,current_electrode_index) [ [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] GetElectrodeRealIndex $index ]
	set thisparam($this,current_electrode) $last_picked_electrode
	$thisparam($this,pick_frame) configure -bg red
    }
    $electrode StoreColorInColorName 
    UpdateElectrodePropertySheet
    
    return 1
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::MovePickedElectrode { x y z }  {

    if { $last_picked_electrode == - 1 } {
	#	puts stderr "Nothing to move ...."
	return 0
    }

#    puts stderr "Moving to $x $y $z"

    $pick_sphere SetPosition $x $y $z
    $pick_sphere Update
    $pick_sphere_outline SetPosition $x $y $z
    $pick_sphere_outline Update

    $pick_sphere_surface ShallowCopySurface [ $pick_sphere GetOutput ]
    $pick_sphere_outline_surface ShallowCopySurface [ $pick_sphere GetOutput ]
    $pick_sphere_outline_surface2 ShallowCopySurface [ $pick_sphere GetOutput ]


    set thisparam($this,current_position) [ format "%.2f %.2f %.2f " $x $y $z ]

    [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] GetNeighborDistances $thisparam($this,current_electrode) $distance_array $x $y $z
    for { set i 0 } { $i <=3 } { incr i } {
	set thisparam($this,current_distance_$i) [ format "%.2f" [ $distance_array GetComponent $i 0 ]]
    }

    $polymanager UpdateSameObject $pick_sphere_surface "" 0
    $polymanager UpdateSameObject $pick_sphere_outline_surface "" 0
    $polymanager UpdateSameObject $pick_sphere_outline_surface2 "" 1
    
    return 1
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::ReleaseElectrodePick { args } {

    if { $last_picked_electrode == -1 } {
	return 0
    }
    
    # Hide Pick Actors
    # ----------------
    
    eval "$polymanager UpdateSameObject $pick_sphere_surface { visible 0 } 0"
    eval "$polymanager UpdateSameObject $pick_sphere_outline_surface { visible 0 opacity 1.0 dispmode Wireframe } 0"
    eval "$polymanager UpdateSameObject $pick_sphere_outline_surface2 { visible 0 opacity 0.5 dispmode Filled} 0"

    $thisparam($this,pick_frame) configure -bg gray

    if { [ llength $args  ] == 3 } {

	set x [ lindex $args 0 ]
	set y [ lindex $args 1 ]
	set z [ lindex $args 2 ]

	set egrid [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ]
	scan  [ $egrid GetDimensions ] "%d %d" dimx dimy
	set dimt [ expr $dimx * $dimy ]
	
	if { $last_picked_electrode < $dimt } {
	    
	    set electrode [ $egrid GetElectrode $last_picked_electrode ]
	    
	    # Do undo stuff and then set position
	    scan [ $electrode GetPosition ] "%f %f %f " ox oy oz ; $electrode SetPreviousPosition $ox $oy $oz
	    $electrode SetPosition $x $y $z
	    
	    $egrid Modified
	    $electrodemultigrid Modified;	
	}
    }
    
    $polymanager UpdateSameObject $itclgrid 
    UpdateElectrodePropertySheet
    set last_picked_electrode -1
    
    return 1
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::HandleClickedPoint { vx pt mode stat } {

    set a [ wm state $basewidget  ]
    if { $a != "normal" } {
	return 0
    }

    if { $thisparam($this,visible) == "none" } {
	return 0
    }

    if { [ llength $pt ] !=3 } { return 0 }
    scan $pt  "%f %f %f" x y z
    if { $x == -1.0 && $y == -1.0 && $z == -1.0 } { return 0 }
    set ok 0
    
#    puts stderr "x=$x, y=$y, z=$z, mode=$mode, stat=$stat"
    if { $mode == -1 && $stat == -1 } {
	return 0
    }

    if { $mode == 1 } {
	if { $stat == 0 } {
	    if { $last_picked_electrode == -1  } {
		set index [ [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] FindClosestElectrodeIndex $x $y $z ]

		if { $index >=0 } { 
		    set ok [ PickElectrode $index $x $y $z  ]
		}
	    }
	} 
    }

    if { $stat == 1 && $last_picked_electrode !=-1 } {
	
	set ok [ MovePickedElectrode $x $y $z ]
	
    } elseif { $stat == 2 && $last_picked_electrode !=-1 } {
	
	set ok [ ReleaseElectrodePick $x $y $z  ]
	
    }

#    puts stderr "Last=$last_picked_electrode"
    return $ok
}
# ---------------------------------------------------------------------------------------------
# Callback Stuff
# ---------------------------------------------------------------------------------------------
itcl::body bis_electrodeeditor::TreeEditGrids { land dtree node } {


    if { [ $land isa pxitclelectrodemultigrid  ] == 0 } {
	return 0
    }

    set old $datatree

    set datatree $dtree
    set xmlpointer $node

    $itclgrid Copy $land
    set electrodemultigrid [ $itclgrid GetObject ]

    set last_filename ""
    set f [ $node GetAttribute Title ]
    SetTitle "(DataTree) Electrode Editor node=$f"
    DisableElectrodePropertySheet
    UpdateInterface
    SelectElectrodeGrid 0

 #   if { $old == 0 } {
#	$filemenu add separator
#	eval "$filemenu add command -label \"Store in Tree\" -command { $this StoreInTree }"
#    }
}
# ------------------------------------------------------------------------
itcl::body bis_electrodeeditor::StoreInTree {  } {

    if { $datatree ==0 } {
	return
    }

#    $datatree UpdateEditedSurface $xmlpointer $itclgrid


}
# ------------------------------------------------------------------------------
itcl::body bis_electrodeeditor::LoadElectrodeMultiGrid { fname } {

    if { $electrodemultigrid == 0 } {
	return 0
    }

    if { $fname == "" } {
	set typelist { 
	    {"Electrode Grid Files" {".mgrid*" } }
	    {"All Files" {*}}
	}
	
	set f1 $last_filename
	set f1path [ file dirname $f1 ]
	set f1tail [ file tail    $f1 ]

	set fname [tk_getOpenFile -title "Load Electrode Multi Grid File" -filetypes $typelist -initialfile $f1tail -initialdir $f1path ]
    }
    
    if { [ string length $fname ] < 1 } {
	return 0
    }

    set ok [ $electrodemultigrid Load $fname ]
    if { $ok > 0 } {
	set last_filename $fname
	SetTitle "Electrode Editor [ file tail $last_filename]"
	DisableElectrodePropertySheet
	UpdateInterface
	SelectElectrodeGrid 0
    }

    return $ok
}

# -------------------------------------------------------------------------------------------
itcl::body bis_electrodeeditor::SaveElectrodeMultiGrid { fname } {

    if { $electrodemultigrid == 0 } {
	return 0
    }

    if { $fname == "" } {
	set typelist { 
	    {"Electrode Grid Files" {".mgrid*" } }
	    {"All Files" {*}}
	}
	
	set f1 $last_filename
	set f1path [ file dirname $f1 ]
	set f1tail [ file tail    $f1 ]
	set fname [tk_getSaveFile -title "Save Electrode Multi Grid File" -filetypes $typelist -initialfile $f1tail -initialdir $f1path ]
    }
    
    if { [ string length $fname ] < 1 } {
	return 0
    }

    UpdatePatient
 
    set ok [ $electrodemultigrid Save $fname ]

    if { $ok > 0 } {
	set last_filename $fname
	SetTitle "Electrode Control [ file tail $last_filename]"
    }
    
    return $ok
}


# -------------------------------------------------------------------------------------------
itcl::body bis_electrodeeditor::EnableAutoSave { } {

    if { $thisparam($this,autosave) == 0 } {
	set thisparam($this,autosaveon) 0
    } else {
	AutoSaveMultiGrid once
    }
}

itcl::body bis_electrodeeditor::AutoSaveMultiGrid { mode } {

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

    set l_filename "[ file root $last_filename]_autosave.mgrid"
    
    UpdatePatient

    if { $thisparam($this,readonly) != 2 } {
	set ok [ $electrodemultigrid Save $l_filename ]
    } else {
	set ok 1
    }

    if { $thisparam($this,autosaveon) == 0 } {
	set thisparam($this,autosaveon) 1
    }
    
    eval "after 30000  $this AutoSaveMultiGrid timer"

    return $ok
}
# -------------------------------------------------------------------------------------------
itcl::body bis_electrodeeditor::ExportAsSurface { fname } {

    if { $electrodemultigrid == 0 } {
	return 0
    }

    if { $fname == "" } {
	set typelist { 
	    {"VTK Surface Files" {".vtk" } }
	    {"All Files" {*}}
	}
	
	set l_filename "[ file root $last_filename].vtk"
	set f1 $l_filename
	set f1path [ file dirname $f1 ]
	set f1tail [ file tail    $f1 ]
	set fname [tk_getSaveFile -title "Save Electrode Multi-Grid As Surface" -filetypes $typelist -initialfile $f1tail -initialdir $f1path ]
    }
    
    if { [ string length $fname ] < 1 } {
	return 0
    }

    $electrodemultigrid Update; 
    #$thisparam($this,label_mapper) Modified
    set w [ vtkPolyDataWriter [ pxvtable::vnewobj ]]
    $w SetInput [ $electrodemultigrid GetOutput ]
    $w SetFileName $fname
    $w Write
    $w Delete
}
# -------------------------------------------------------------------------------------------
itcl::body bis_electrodeeditor::ExportPickedFunction { fname mode } {

    if { $electrodemultigrid == 0 } {
	return 0
    }

    if { $fname == "" } {
	set typelist { 
	    {"Text Files" {".txt" } }
	    {"All Files" {*}}
	}
	
	set l_filename "[ file root $last_filename].txt"
	set f1 $l_filename
	set f1path [ file dirname $f1 ]
	set f1tail [ file tail    $f1 ]
	set fname [tk_getSaveFile -title "Export picked function in text file" -filetypes $typelist -initialfile $f1tail -initialdir $f1path ]
    }
    
    if { [ string length $fname ] < 1 } {
	return 0
    }

    if { $mode == "dopick" } {
	$this PickFunction
    }

    set ok [ $electrodemultigrid ExportValues $fname " " " " " "  ]
    if { $ok == 0 } { 
	::pxtclutil::Warning "Failed to export picked function in $fname"
    }
}
# -------------------------------------------------------------------------------------------
# Export as Pixel Image
# -------------------------------------------------------------------------------------------
itcl::body bis_electrodeeditor::ExportAsPixelImage { fname  } {

    if { $electrodemultigrid == 0 } {
	return 0
    }

    set l [ list "Location" "Epilepsy" "Any Function" "Motor Function" "Sensory Function" "Visual Function" "Language Function" "Auditory Function" "User1 Function"  ]
    set n [ $electrodemultigrid GetNumberOfValues ]
    for { set i 0 } { $i < $n } { incr i } {
	lappend l "Attribute_[expr $i+1]"
    }
    
    $function_selector configure -singleoutput 0
    $function_selector Activate $l "Epilepsy" "The selected function will be used to generate the output label for the output pixel-image" "Select Output Label"
    
    set mode [ $function_selector GetSelectedIndices ]

    #    puts stderr "Mode = $mode"
    set numcomp [ llength $mode ]

    if { $numcomp == 0 } {
	return 0
    }
    
    set arr [ vtkShortArray [ pxvtable::vnewobj ]]
    $arr SetNumberOfTuples $numcomp
    $arr FillComponent 0 0
    
    for { set i 0 } { $i < $numcomp } { incr i } {

	set md [ lindex $mode $i ]
	if { $md > 8 } { 
	    set md [ expr $md + 11 ]
	}
	$arr SetComponent $i 0 $md
    }
    
    set typelist { 
	{"Analyze Image Files" {".hdr" } }
	{"All Files" {*}}
    }
    
    set l_filename "[ file root $last_filename].hdr"
    set f1 $l_filename
    set f1path [ file dirname $f1 ]
    set f1tail [ file tail    $f1 ]
    
    set fname [tk_getSaveFile -title "Save Electrode Multi-Grid As Labeled Image" -filetypes $typelist -initialfile $f1tail -initialdir $f1path ]
    
    if { [ string length $fname ] < 1 } {
	$arr Delete
	return 0
    }

    
    WatchOn
     update idletasks
    set img [ $electrodemultigrid CreateSinglePixelImage $arr [ $vtk_viewer GetImage ] ]
    set ana [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]
    $ana SetInput $img
    $ana SetOrientation [ $vtk_viewer GetOrientation ]
    $ana Save $fname
    $ana Delete
    $img Delete
    $arr Delete
    WatchOff
    
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::UpdateInterface { } {

    UpdatePatientPropertySheet
    UpdateGridPropertySheet
    UpdateElectrodePropertySheet
    AutoSaveMultiGrid once
}

::itcl::body bis_electrodeeditor::UpdatePatient { } {
    UpdateElectrodePropertySheet
    UpdateElectrodeGridProperties 
    UpdatePatientProperties
}


::itcl::body bis_electrodeeditor::UpdateVolumeTrace { } {

    catch { $vtk_viewer SetTraceVolumeVOI $thisparam($this,volume_voi_size) }
    catch { $vtk_viewer SetTraceVolumeWeightedMode $thisparam($this,volume_weighted_voi) }
    
}

# -------------------------------------------------------------------------------------------
#
#           Electrode Property Sheet
#
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::CreateElectrodePropertySheet { par } {
    
    label $par.0 -text "Electrode Properties" -bg black -fg white 
    pack $par.0 -side top -expand f -fill x -pady 2 -padx 2
    
    frame $par.1 ; pack $par.1 -side top
    label $par.1.l -text "Grid/Electrode:"
    entry $par.1.e -width 6 -textvariable [ itcl::scope thisparam($this,current_grid) ] -state disabled
    label $par.1.l2 -text "/"
    entry $par.1.e2 -width 6 -textvariable [ itcl::scope thisparam($this,current_electrode_index) ] -state disabled
    pack $par.1.l $par.1.e $par.1.l2 $par.1.e2 -side left -expand f -fill x -pady 1

    frame $par.11 ; pack $par.11 -side top
    label $par.11.l -text "Position:"
    entry $par.11.e -width 20 -textvariable [ itcl::scope thisparam($this,current_position) ] -state disabled
    eval "button $par.11.f -text Upd -command { $this UpdateElectrodeLocationFromText } -state disabled"
    set update_location_button $par.11.f
    set location_text $par.11.e
    pack $par.11.l $par.11.e $par.11.f -side left -expand f -fill x -pady 1

    set w [frame $par.12 -bg darkgray ] ; pack $par.12 -side top -padx 2 -pady 2
    set thisparam($this,pick_frame) $w


    label $w.lab -text "Distances"
    for { set i 0 } { $i <=3 } { incr i } {
	entry $w.$i -width 8 -textvariable [ itcl::scope thisparam($this,current_distance_$i) ] -state disabled
    }
    
    grid $w.lab -row 1 -column 1
    grid $w.0 -row 1 -column 0
    grid $w.1 -row 1 -column 2
    grid $w.2 -row 0 -column 1
    grid $w.3 -row 2 -column 1
       

    checkbutton $par.15 -text "Electrode Enabled" -variable [ itcl::scope thisparam($this,ElectrodePresent) ]  
    lappend thisparam($this,electrodepropertylist) $par.15
    eval "$par.15 configure -command  { $this UpdateElectrodeProperties }"
    pack  $par.15 -side top -expand f -fill x -ipadx 2 -ipady 2

    set thisparam(this,electrode_color) [ frame $par.17 -height 10 -bg white ]
    pack $par.17 -side top -expand f -fill x -pady 5 -padx 10

    set base  [ LabelFrame:create $par.center -text "Locate Viewer"]
    pack $par.center -side top -expand f -fill x -pady 2
    
    eval "button $base.1 -text \"Cross Hairs\" -command { $this CenterOnElectrode 0 }"
    eval "button $base.2 -text \"Clip Tight\" -command { $this CenterOnElectrode 1 }"
    eval "button $base.3 -text \"Clip Wide\" -command { $this CenterOnElectrode 2 }"
    pack $base.1 $base.2 $base.3 -side left -expand f -fill x -padx 2

    set base  [ LabelFrame:create $par.2 -text "Functional Attributes"]
    pack $par.2 -side top -expand f -fill x

    for { set i 0 } { $i < [ expr [ llength $functional_activations ]/2 ] } { incr i } {
	frame $base.$i ; pack $base.$i -side top -expand f -fill x -pady 0

	for { set j 0 } { $j <=1 } { incr j } {
	    set index [ expr $i * 2 + $j ]
	    set l [ lindex $functional_activations $index ]
	    set m [ string length $l ]
	    set n [ string range $l 0 [ expr $m - 9 ]]
	    eval "checkbutton $base.$i.m$n -text $n -variable [ itcl::scope thisparam($this,$l) ] -width 10"
	    eval "$base.$i.m$n configure -command  { $this UpdateElectrodeProperties }"
	    pack $base.$i.m$n -side left -expand f -fill x
	    lappend thisparam($this,electrodepropertylist) $base.$i.m$n
	}
    }
	
    set base  [ LabelFrame:create $par.3 -text "Electrical Attributes"]
    pack $par.3 -side top -expand f -fill x
    checkbutton $base.1 -text "Seizure Onset" -variable [ itcl::scope thisparam($this,SeizureOnset) ] -width 10
    checkbutton $base.2 -text "Spikes Present" -variable [ itcl::scope thisparam($this,SpikesPresent) ] -width 10
    eval "$base.1 configure -command  { $this UpdateElectrodeProperties }"
    eval "$base.2 configure -command  { $this UpdateElectrodeProperties }"
    pack $base.1 $base.2 -side top -expand f -fill x
    lappend thisparam($this,electrodepropertylist) $base.1
    lappend thisparam($this,electrodepropertylist) $base.2

    if { $nomouseinput == 0 } {
	set base  [ LabelFrame:create $par.4 -text "Editing"]
	pack $par.4 -side top -pady 2 -expand f -fill x
	eval "checkbutton $base.auto -text \"Button Pick\"  -variable [ itcl::scope thisparam($this,auto_pick) ] -command { $this ReleaseElectrodePick }"
	frame $base.p ; 
	pack $base.auto $base.p -side top -expand t -fill x -padx 2
	eval "button $base.p.set -text \"Pick Current\" -command { $this PickElectrode -1 }"
	eval "button $base.p.can -text \"Release\" -command { $this ReleaseElectrodePick }"
	pack $base.p.set $base.p.can  -side left -expand f -fill x -pady 2
    }

    eval "button $par.5 -text \"Show Values\" -command { $this ElectrodeShowValues }"
    
    pack $par.5  -side bottom -expand f -fill x -pady 2
   
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::ElectrodeShowValues { } {

    set electrode [ [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] GetElectrode $thisparam($this,current_electrode) ]
    set values [ $electrode GetValues ]
    set l "Electode $thisparam($this,current_electrode_index)\n"
    if { [ $values GetNumberOfTuples ] == 0 } {
	set l "Electrode has no values"
    } else {
	for { set i 0 } { $i < [ $values GetNumberOfTuples ] } { incr i } {
	    lappend l "Comp [ expr $i +1 ]: [ $values GetComponent $i 0 ]"
	}
    }

    ::pxtclutil::Info $l 


}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::CenterOnElectrode { mode } {

    set electrode [ [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] GetElectrode $thisparam($this,current_electrode) ]
    scan [ $electrode GetPosition ] "%f %f %f" p(0) p(1) p(2)
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
	$polymanager UpdateSameObject $itclgrid 
	    
    }

}

# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::UpdateElectrodeLocationFromText { } {
    
    if { $thisparam($this,readonly)  != 0 } {
	return
    }

    set img [ $vtk_viewer GetImage ]
    set dim [ $img GetDimensions ]
    set spa [ $img GetSpacing ]
    if { [ lindex $dim 0 ] < 2 } {
	return
    }

    set electrode [ [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] GetElectrode $thisparam($this,current_electrode) ]

    set lst $thisparam($this,current_position)
    if { [ llength $lst ] != 3  } {
	scan [ $electrode GetPosition ] "%f %f %f" px py pz
	set thisparam($this,current_position) [ format "%.2f %.2f %.2f " $px $py $pz ]
	return 
    }

    for { set i 0 } { $i <= 2 } { incr i } {
	set x($i) [ lindex $lst $i ]
	if { $x($i) < -1 } {
	    set x($i) -1.0
	} elseif { $x($i) > [ expr [ lindex $dim $i ]*[lindex $spa $i ] ] } {
	    set x($i) [ expr [ lindex $dim $i ]*[lindex $spa $i ] ]
	}
    }
    

    scan [ $electrode GetPosition ] "%f %f %f " ox oy oz ; 
    $electrode SetPreviousPosition $ox $oy $oz
    $electrode SetPosition $x(0) $x(1) $x(2)
    scan [ $electrode GetPosition ] "%f %f %f" px py pz
    set thisparam($this,current_position) [ format "%.2f %.2f %.2f " $px $py $pz ]


    [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] Modified
    $electrodemultigrid Modified;	
#$thisparam($this,label_mapper) Modified

    $this ReleaseElectrodePick
    $polymanager UpdateSameObject $itclgrid 
}

# -------------------------------------------------------------------------------------------

::itcl::body bis_electrodeeditor::UpdateElectrodeProperties { } {

    set electrode [ [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] GetElectrode $thisparam($this,current_electrode) ]

    for { set i 0 } { $i < [ llength $electrode_attributes ] } { incr i } {
	set nm [ lindex $electrode_attributes $i ]
	$electrode Set$nm $thisparam($this,$nm)
    }
    
    [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] Modified
    $electrodemultigrid Modified
    [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] Modified
    $electrodemultigrid Update; 
    #$thisparam($this,label_mapper) Modified

    $electrode StoreColorInColorName
    $thisparam(this,electrode_color) configure -bg [ $electrode GetColorName ]

    set width [ lindex [ [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] GetDimensions ] 0 ]
    set row [ expr round(floor($thisparam($this,current_electrode) / $width)) ]
    set col [ expr round($thisparam($this,current_electrode)  - $width * $row) ]
    set nm $thisparam($this,radio_${col}_${row})
    $nm configure -bg [ $electrode GetColorName ] 

    if { [ $electrode GetElectrodePresent ] == 0  } { 
	ReleaseElectrodePick
    }

    $polymanager UpdateSameObject $itclgrid 
    
}

# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::UpdateElectrodePropertySheet { } {


    set dim  [ [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] GetDimensions ]
    set numelect [ expr [ lindex $dim 0 ] * [ lindex $dim 1 ]]

    if { $thisparam($this,current_electrode) >= $numelect } {
	set thisparam($this,current_electrode) 0
    }


    set thisparam($this,current_electrode_radio) $thisparam($this,current_electrode)
    set electrode [ [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] GetElectrode $thisparam($this,current_electrode) ]
    set thisparam($this,current_electrode_index) [ [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] GetElectrodeRealIndex $thisparam($this,current_electrode) ]


    for { set i 0 } { $i < [ llength $electrode_attributes ] } { incr i } {
	set nm [ lindex $electrode_attributes $i ]
	set thisparam($this,$nm) [ $electrode Get$nm  ]
    }
   
    scan [ $electrode GetPosition ] "%f %f %f" px py pz
    set thisparam($this,current_position) [ format "%.2f %.2f %.2f " $px $py $pz ]

    [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] GetNeighborDistances $thisparam($this,current_electrode) $distance_array
    for { set i 0 } { $i <=3 } { incr i } {
	set thisparam($this,current_distance_$i) [ format "%.2f" [ $distance_array GetComponent $i 0 ]]
    }

    $electrode StoreColorInColorName
    $thisparam(this,electrode_color) configure -bg [ $electrode GetColorName ]

    set width [ lindex [ [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] GetDimensions ] 0 ]
    set row [ expr round(floor($thisparam($this,current_electrode) / $width)) ]
    set col [ expr round($thisparam($this,current_electrode)  - $width * $row) ]

    set nms $thisparam($this,radio_${col}_${row})
    $nms configure -relief ridge -highlightbackground black

    if { $last_radiobutton != 0  && $last_radiobutton != $nms } {
	$last_radiobutton configure -relief flat -highlightbackground gray
    }
    set last_radiobutton $nms
    
    
}


::itcl::body bis_electrodeeditor::UndoMoveElectrode { } {


    set electrode [ [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] GetElectrode $thisparam($this,current_electrode) ]
    scan [ $electrode GetPreviousPosition ] "%f %f %f " ox oy oz ; $electrode SetPreviousPosition $ox $oy $oz
    $electrode SetPosition $ox $oy $oz
    set thisparam($this,current_position) [ format "%.2f %.2f %.2f " $ox $oy $oz ]
    [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ] Modified
    $electrodemultigrid Modified
    $polymanager UpdateSameObject $itclgrid 
}


# -------------------------------------------------------------------------------------------
#
#    Grid Property Sheet
#
# -------------------------------------------------------------------------------------------

::itcl::body bis_electrodeeditor::CreateGridPropertySheet { basepar } {
    
    set wp  [ LabelFrame:create $basepar.1 -text "Grid Properties"]
    pack $basepar.1 -side top -expand true -fill x -pady 2 -padx 2


    checkbutton $wp.vis -text "Display Grid " -variable [ itcl::scope thisparam($this,current_grid_visible) ]  
    eval "$wp.vis configure -command  { $this UpdateElectrodeGridProperties  }"
    pack $wp.vis -side top -padx 5 -pady 2

    set i 0
    set w [ frame $wp.$i]  ; pack $w -anchor w; incr i
    label $w.l -text "Grid Name:"
    entry $w.e -width 35 -textvariable [ itcl::scope thisparam($this,current_grid_name) ] -relief sunken
    pack $w.l $w.e -side left -expand false -fill x -anchor w

    set w [ frame $wp.$i]  ; pack $w -anchor w; incr i
    label $w.l1 -text "Dimensions:"
    entry $w.e1 -width 3 -textvariable [ itcl::scope thisparam($this,current_grid_dimx) ] -relief sunken
    entry $w.e2 -width 3 -textvariable [ itcl::scope thisparam($this,current_grid_dimy) ] -relief sunken
    pack $w.l1 $w.e1 $w.e2 -side left -expand false -fill x -anchor w

    set w [ frame $wp.$i]  ; pack $w -anchor w; incr i
    label $w.l3 -text "Nominal Spacing (mm):"
    entry $w.e3 -width 3 -textvariable [ itcl::scope thisparam($this,current_grid_spx) ] -relief sunken
    entry $w.e4 -width 3 -textvariable [ itcl::scope thisparam($this,current_grid_spy) ] -relief sunken
    pack $w.l3 $w.e3 $w.e4 -side left -expand false -fill x -anchor w

    set w [ frame $wp.$i]  ; pack $w -anchor w; incr i
    label $w.l -text "Electrode Type:"
    tk_optionMenu $w.opt [ itcl::scope thisparam($this,current_grid_electrodetype) ] "Sphere" "Disc"
    pack $w.l $w.opt  -side left -expand false  -anchor ne 

    set w [ frame $wp.$i]  ; pack $w -anchor w; incr i
    label $w.l1 -text "Radius/Thick (mm):"
    entry $w.e1 -width 5 -textvariable [ itcl::scope thisparam($this,current_grid_radius) ] -relief sunken
    entry $w.e2 -width 5 -textvariable [ itcl::scope thisparam($this,current_grid_thickness) ] -relief sunken
    pack  $w.l1 $w.e1 $w.e2 -side left -expand false -fill x -anchor w -padx 0


    eval "button $wp.bot -text \"Update Grid \" -command { $this UpdateElectrodeGridProperties }"
    pack $wp.bot -side bottom -expand f -fill x -anchor ne -pady 4 -padx 4    


    set wp  [ LabelFrame:create $basepar.2 -text "Electrode Arrangment" ]
    pack $basepar.2 -side top -expand true -fill both -pady 2 -padx 2
    label $wp.lab -text "Electrode Leads Here!" -bg black -fg white
    pack $wp.lab -side top -expand f -fill x 



    set index 0

	    
    for { set j 0 } { $j < $maxelectrodes } { incr j } {
	set w [ frame $wp.$j ] ; pack $w -side top -expand f -fill x -padx 0 -pady 0
	for { set i 0 } { $i < $maxelectrodes } { incr i } {
	    set nm radio_${i}_${j}
	    eval "radiobutton $w.$index -value $index -variable [ itcl::scope thisparam($this,current_electrode_radio) ] -text \"\" -command { $this SelectElectrode } -width 0 -font $fontname -highlightbackground gray -highlightthickness 3"
	    set thisparam($this,$nm) $w.$index	    
	    pack  $thisparam($this,$nm) -side left -padx 0 -pady 0 -ipadx 0 -ipady 0 -expand f 
	    incr index
	}
    }


}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::UpdateElectrodeGridProperties { } {

    set elec_grid  [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ]

    $elec_grid SetGridName $thisparam($this,current_grid_name) 
    $elec_grid SetElectrodeSpacing $thisparam($this,current_grid_spx) $thisparam($this,current_grid_spy)
    $elec_grid SetElectrodeTypeTo$thisparam($this,current_grid_electrodetype)
    $elec_grid SetRadius $thisparam($this,current_grid_radius) 
    $elec_grid SetThickness $thisparam($this,current_grid_thickness) 
    $elec_grid SetVisible  $thisparam($this,current_grid_visible) 

    set dimensions [ $elec_grid GetDimensions ]
    set dimx [ lindex $dimensions 0 ]
    set dimy [ lindex $dimensions 1 ]

    if { $dimx != $thisparam($this,current_grid_dimx)  || $thisparam($this,current_grid_dimy)!=$dimy } {
	set ok [ ::pxtclutil::Question "Changing the Grid Dimensions will result in losing all information about the current grid. Are you sure?" ]
	if { $ok == 1 } {
	    $elec_grid SetGridName $thisparam($this,current_grid_name) 
	    #"grid_$thisparam($this,current_grid_dimx)_$thisparam($this,current_grid_dimy)"
	    $elec_grid InitializeGrid $thisparam($this,current_grid_dimx) $thisparam($this,current_grid_dimy)
	    $electrodemultigrid Modified
	    set thisparam($this,current_electrode) 0
	    UpdateInterface
	    $polymanager UpdateSameObject $itclgrid 
	    return
	}
    }

    set thisparam($this,current_grid_dimx) $dimx
    set thisparam($this,current_grid_dimy) $dimy
    

    $electrodemultigrid Modified
    UpdatePatientPropertySheet
    $polymanager UpdateSameObject $itclgrid 
}


# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::SelectElectrode { } {

    set thisparam($this,current_electrode) $thisparam($this,current_electrode_radio) 
    UpdateElectrodePropertySheet
    ReleaseElectrodePick
    if {  $thisparam($this,auto_pick) == 1 } {
	PickElectrode -1
    }
}
    
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::UpdateGridPropertySheet { } {
    
    set elec_grid [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ]
    set dimensions [ $elec_grid GetDimensions ]
    set dimx [ lindex $dimensions 0 ]
    set dimy [ lindex $dimensions 1 ]

    set thisparam($this,current_grid_name) [ $elec_grid GetGridName ]
    set thisparam($this,current_grid_dimx) $dimx
    set thisparam($this,current_grid_dimy) $dimy
    set thisparam($this,current_grid_spx)  [ lindex [ $elec_grid GetElectrodeSpacing ] 0 ]
    set thisparam($this,current_grid_spy)  [ lindex [ $elec_grid GetElectrodeSpacing ] 1 ]
    set thisparam($this,current_grid_visible) [ $elec_grid GetVisible ]

    set thisparam($this,current_grid_electrodetype) "Sphere"
    if { [ $elec_grid GetElectrodeType ] == 1 } {
	set thisparam($this,current_grid_electrodetype) "Disc"
    }

    set thisparam($this,current_grid_radius) [ $elec_grid GetRadius ]
    set thisparam($this,current_grid_thickness) [ $elec_grid GetThickness ]

    set index 0
    for { set j 0 } { $j < $maxelectrodes } { incr j } {
	for { set i 0 } { $i < $maxelectrodes } { incr i } {
	    #	    puts stderr "Updating Electrode $i $j"
	    set nm $thisparam($this,radio_${i}_${j})
	    if {$i >= $dimx || $j >= $dimy } {
		$nm configure -value -1
		$nm configure -state disabled -width 0 -bg darkgray -font { fixed 1 }
		$nm configure -relief sunken
	    } else {
		set electrode [ $elec_grid GetElectrode $i $j ]
		$electrode StoreColorInColorName 
		set cl [ $electrode GetColorName ]
		$nm configure -bg $cl
		#		puts stderr "$nm configure -bg $cl"
		$nm configure -state normal
		$nm configure -value $index
		#$nm configure -text $index
		$nm configure -state normal -width 0 -font $fontname
		$nm configure -relief flat -highlightbackground gray
		incr index
	    }
	}
    }

    if { [ $elec_grid GetShowLabelsGap ] != $thisparam($this,showlabelsgap) } {
	$elec_grid SetShowLabelsGap $thisparam($this,showlabelsgap)
	$elec_grid Modified
	$electrodemultigrid Modified
#	$thisparam($this,label_mapper) Modified
    }

    UpdateElectrodePropertySheet
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::CreatePatientPropertySheet { basepar } {

    set wp  [ LabelFrame:create $basepar.1 -text "Patient Information"]
    pack $basepar.1 -side top -expand true -fill x -pady 2 -padx 2

    
    set i 0
    set w [ frame $wp.$i]  ; pack $w -anchor w; incr i
    label $w.l -text "Description:"
    entry $w.e -width 45 -textvariable [ itcl::scope thisparam($this,current_patient_description) ] -relief sunken
    pack $w.l  -side left -expand false -fill x -anchor w
    pack $w.e -side left -expand true -fill x -anchor e

    set w [ frame $wp.$i]  ; pack $w -anchor w; incr i
    label $w.l -text "Comment:"
    entry $w.e -width 45 -textvariable [ itcl::scope thisparam($this,current_patient_comment) ] -relief sunken
    pack $w.l  -side left -expand false -fill x -anchor w
    pack $w.e -side left -expand true  -fill x -anchor e



    set wp  [ LabelFrame:create $basepar.2 -text "Grid Information"]
    pack $basepar.2 -side top -expand true -fill x -pady 2 -padx 2
    
    set grid_listbox [ iwidgets::scrolledlistbox $wp.left -vscrollmode dynamic -hscrollmode none -selectmode single -labelpos nw -visibleitems 10x40 ]
    eval "$grid_listbox configure -selectioncommand { $this SelectElectrodeGrid -1 }"
    $grid_listbox configure -selectmode single
    
    frame $wp.right

    eval "button $wp.right.add -text \"Add New Grid\" -command { $this AddNewElectrodeGrid }"
    eval "button $wp.right.del -text \"Delete  Grid\" -command { $this DeleteCurrentElectrodeGrid }"
    pack $wp.right.add $wp.right.del -side top -anchor se -padx 2 -pady 4

    pack $wp.right -side right -expand false -fill y
    pack $wp.left -side left -expand true -fill both -padx 2 -pady 2

}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::SelectElectrodeGrid { index } {
    
    set ng [ $electrodemultigrid GetNumberOfGrids ] 
    if { $index < 0 } {
	set index [ $grid_listbox curselection ]
    } else {
	if { $index >= $ng  } {
	    return 0
	}
	
	$grid_listbox selection clear 0 end
	$grid_listbox selection set $index $index
    }

    set thisparam($this,current_grid) $index
    UpdateGridPropertySheet
    set thisparam($this,current_electrode_radio)  0
    SelectElectrode

    if { $thisparam($this,visible) == "current" } {
	ShowGrids current
    }
}

# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::AddNewElectrodeGrid { } {

    set a [ $electrodemultigrid GetNumberOfGrids ] 
    $electrodemultigrid InsertNewGrid
    set grid [ $electrodemultigrid GetElectrodeGrid $a ]
    $grid SetElectrodeSpacing 10.0 10.0
    $grid SetRadius  2.0
    set nm [ $grid GetGridName ]
    set nq [ expr $a + 1 ]
    $grid_listbox insert end "${nq}.${nm}"
    SelectElectrodeGrid  $a
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::DeleteCurrentElectrodeGrid { } {

    set a [ $electrodemultigrid GetNumberOfGrids ] 
    if { $a == 1 } {
	::pxtclutil::Warning "Cannot delete grid as this is the only grid in the patient!"
	return
    }

    set ok [ ::pxtclutil::Question "This will delete all information about the current grid! Are you sure?" ]
    if { $ok == 1 } {
	$electrodemultigrid DeleteGrid $thisparam($this,current_grid) 
	UpdatePatientPropertySheet
	SelectElectrodeGrid 0
    }
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::UpdatePatientPropertySheet { } {

    set thisparam($this,current_patient_description) [ $electrodemultigrid GetDescription ]
    set thisparam($this,current_patient_comment)     [ $electrodemultigrid GetComment ]

    $grid_listbox clear 

    set ng [ $electrodemultigrid GetNumberOfGrids ] 
    for { set i 0 } { $i < $ng } { incr i } {
	
	set grid [ $electrodemultigrid GetElectrodeGrid $i ]
	set nm [ $grid GetGridName ]
	set nq [ expr $i + 1 ]
	$grid_listbox insert end "${nq}.${nm}"
    }

    $grid_listbox selection clear 0 end
    $grid_listbox selection set $thisparam($this,current_grid) $thisparam($this,current_grid)

}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::UpdatePatientProperties { } {

    $electrodemultigrid SetDescription $thisparam($this,current_patient_description) 
    $electrodemultigrid SetComment     $thisparam($this,current_patient_comment)     


}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::GridColor { } {

    set egrid [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ]
    set c [ $egrid GetColor ]
    set newcolor [ pxtclutil::ColorBox "Set Grid [ $egrid GetGridName ] display color" $c $basewidget ]
    $egrid SetColor [ lindex $newcolor 0 ] [ lindex $newcolor 1 ] [ lindex $newcolor 2 ]
    $egrid Modified
    $egrid Update
    $electrodemultigrid Modified
    UpdateGridPropertySheet
    $polymanager UpdateSameObject $itclgrid 
}

::itcl::body bis_electrodeeditor::LabelsColor { } {

    $polymanager SetCurrentObject $itclgrid
    $polymanager SetColor
}


::itcl::body bis_electrodeeditor::ReorientGrid { mode } {

    if { $mode == 0 }  {
	set ok [ ::pxtclutil::Question "This will transpose current grid! Are you sure?" ]
    } elseif { $mode == 1 } {
	set ok [ ::pxtclutil::Question "This will perform a row flip on your current grid! Are you sure?" ]
    } else {
	set ok [ ::pxtclutil::Question "This will perform a column flip on your current grid! Are you sure?" ]
    }

    if { $ok == 0 } {
	return 
    }

    set egrid [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ]
    if { $mode == 0 } {
	$egrid TransposeGrid
    } elseif { $mode == 1 } {
	puts stdout "Flipping X"
	$egrid GridFlipX
    } elseif { $mode == 2 } {
	puts stdout "Flipping Y"
	$egrid GridFlipY
    }

    $electrodemultigrid Modified;	
    $polymanager UpdateSameObject $itclgrid 
    SelectElectrodeGrid -1
    return
}


::itcl::body bis_electrodeeditor::DisableElectrodePropertySheet { } {

    set md ""

    if { $thisparam($this,readonly) == 2 } {
	SetTitle "<Read-Only> Electrode Editor [ file tail $last_filename]"
	set flag 0
	set bflag 0
    } elseif { $thisparam($this,readonly) == 1 } {
	SetTitle "<Attribute-Only> Electrode Editor [ file tail $last_filename]"
	set flag 1
	set bflag 0
    } else {
	SetTitle "Electrode Editor [ file tail $last_filename]"
	set flag 1
	set bflag 1
    }

    if { $flag == 1 } {
	EnableUI $thisparam($this,electrodepropertylist)
    } else {
	DisableUI $thisparam($this,electrodepropertylist)
    }

    if { $update_location_button !=0 } {
	if { $bflag == 0 } {
	    $update_location_button configure -state disabled
	    $location_text configure -state disabled
	} else {
	    $update_location_button configure -state normal
	    $location_text configure -state normal
	}
    }


}

::itcl::body bis_electrodeeditor::ShowLabels { mode } {

    if { $mode == -1 } {
	set mode $thisparam($this,showlabels)
    }
    set gap $thisparam($this,showlabelsgap)
#    puts stdout "\t\t\t Mode=$mode, Gap=$gap"
    eval "$polymanager UpdateSameObject $itclgrid { gridfontgap $gap gridfontsize $mode } 1"
}

::itcl::body bis_electrodeeditor::ShowGrids { mode } {


    if { $mode != -1 } {
	set thisparam($this,visible) $mode
    } else {
	set mode thisparam($this,visible)
    }

    set showlines $thisparam($this,visiblelines) 
    if { $mode == "none" } {
	$this ReleaseElectrodePick
	$polymanager UpdateSameObject $itclgrid { visible 0 dispgridlist "" } 1
	return
    }

    set flag 1
    if { $mode == "current" } {
	set flag 0
    } 
    
    set ng [ $electrodemultigrid GetNumberOfGrids ] 
    set vlist ""
    set nlist [ $itclgrid GetGridNamesList ]

#    puts stderr "Ng=$ng, nlist=$nlist"

    for { set i 0 } { $i < $ng } { incr i } {
	set grid [ $electrodemultigrid GetElectrodeGrid $i ]
	#$grid SetJustShowElectrodes $justelectrodes
	$grid SetColorMode [ expr 1-$thisparam($this,griduniformcolor) ]
	
	set nm  [ $grid GetGridName ]
	set nq  [ expr $i + 1 ]

	if { $i == $thisparam($this,current_grid) && $mode == "current" } {
	    lappend vlist [ lindex $nlist $i ]
	} elseif { $flag == 1 } {
	    lappend vlist [ lindex $nlist $i ]
	}
    }
    eval "$polymanager UpdateSameObject $itclgrid { visible 1 dispgridlist \"$vlist\"  gridshowlines $showlines } 1"
}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::SelectGridsToDisplay { } {

    set l ""
    set ng [ $electrodemultigrid GetNumberOfGrids ] 
    set nlist [ $itclgrid GetGridNamesList ]
#    puts stderr "nlist=$nlist"
    for { set i 0 } { $i < $ng } { incr i } {
	set grid [ $electrodemultigrid GetElectrodeGrid $i ]
	scan    [ $grid GetDimensions ] "%d %d" dimx dimy
	lappend l  "[ lindex $nlist $i ] , ($dimx x $dimy)"
    }

    $batch_selector Activate $l "" "Select which electrode grids to display" "Select Grids To Display"
    set indices [ $batch_selector GetSelectedIndices ]

    set showlines $thisparam($this,visiblelines) 
#    puts stdout "Indices = $indices"
    set vlist ""
    set ng [ $electrodemultigrid GetNumberOfGrids ] 
    set cv 0
    for { set i 0 } { $i < $ng } { incr i } {
	set grid [ $electrodemultigrid GetElectrodeGrid $i ]
	#	$grid SetJustShowElectrodes $justelectrodes
	
	if { [  lsearch -exact $indices  $i  ] != -1 } {
	    lappend vlist [ lindex $nlist $i ] 
	    if { $i == $thisparam($this,current_grid) } {
		set cv 1

	    }
	}
    }
    set thisparam($this,current_grid_visible) $cv
    ReleaseElectrodePick
    set thisparam($this,visible) "some"
    set mode $thisparam($this,showlabels)
    set gap $thisparam($this,showlabelsgap)
    eval "$polymanager UpdateSameObject $itclgrid { visible 1 dispgridlist \"$vlist\" gridshowlines $showlines gridfontgap $gap gridfontsize $mode} 1"

}
# -------------------------------------------------------------------------------------------
::itcl::body bis_electrodeeditor::AutoWarp { mode } {
    
    if { $mode == 1 } {
	set egrid [ $electrodemultigrid GetElectrodeGrid $thisparam($this,current_grid) ]
	$back_electrodemultigrid Copy $electrodemultigrid
	set back_last_filename $last_filename 
	set ok [ $egrid AutoWarp ]
	if { $ok == 1 } {
	    $egrid Modified
	    $electrodemultigrid Modified;	
	    $polymanager UpdateSameObject $itclgrid 
	    SelectElectrodeGrid -1
	} else {
	    ::pxtclutil::Warning "Cannot do autowarp as less than three electrodes have been modified. You need to manually position at least three electrodes before autowarp can work!\n"
	}
    } elseif { $back_last_filename != "none" } {
	$electrodemultigrid Copy $back_electrodemultigrid
	set last_filename $back_last_filename 
	SetTitle "Electrode Control [ file tail $last_filename]"
	UpdateInterface
	$polymanager UpdateSameObject $itclgrid 
    }
}

# -------------------------------------------------------------------------------------------
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {

    package require vtkpxcontrib
    wm withdraw .


    set tp .[ pxvtable::vnewobj ] 

    set electrode_editor [ [ bis_electrodeeditor \#auto 0 ]  GetThisPointer ]
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
	set ok [ $electrode_editor LoadElectrodeMultiGrid [ lindex $argv 1 ] ]
    }
    $electrode_editor ShowGrids "all"
}


    





