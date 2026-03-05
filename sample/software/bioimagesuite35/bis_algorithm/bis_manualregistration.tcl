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


lappend auto_path [ file dirname [ info script ]]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]

package provide bis_manualregistration 1.0
package require bis_dualimagealgorithm 1.0
package require bis_resliceimage 1.0
package require bis_colorblendimage 1.0

#
# smooth image
#

itcl::class bis_manualregistration {

    inherit bis_dualimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Manual Registration" }

    # Override these methods
    protected method PackOptionsGUIInterface { lst }
    public method  UpdateOutputFilenames { } 
    public method GetOutputTransformation { }
    public method UpdateContainerWithOutput { } 
    public method UpdateInputsFromContainer { } 
    public method CheckInputObjects { } 
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_manualregistration::Initialize { } {

    PrintDebug "bis_manualregistration::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ shiftx   "X-Translation (in voxels)" "Shift X"  { real default 4  } 0 { -500 500 }  0 }
	{ shifty   "Y-Translation (in voxels)" "Shift Y"  { real default 4  } 0 { -500 500 }  1 }
	{ shiftz   "Z-Translation (in voxels)" "Shift Z"  { real default 4  } 0 { -500 500 }  2 }
	{ anglex   "X-Rotation in degrees" "Angle X"    { real default 4  } 0 { -359 359 }  3 }
	{ angley   "Y-Rotation in degrees" "Angle Y"    { real default 4  } 0 { -359 359 }  4 }
	{ anglez   "Z-Rotation in degrees" "Angle Z"    { real default 4  } 0 { -359 359 }  5 }
	{ scalex   "X-Scale Factor (percentage 100=identity)" "Scale X"          { real default 4 } 100 { 20 500 }  6 }
	{ scaley   "Y-Scale Factor (percentage 100=identity)" "Scale Y"          { real default 4 } 100 { 20 500 }  7 }
	{ scalez   "Z-Scale Factor (percentage 100=identity)" "Scale Z"          { real default 4 } 100 { 20 500 }  8 }
	{ usepoints   "If 0 -- set transformation manually, otherwise use point sets (which must have the same number of points)" "Use Landmarks"  boolean 0  { 0 1 }  10 }
	{ mode   "Type of transformation (if using points)" "Transformation Mode" { listofvalues } affine { rigid affine similarity tps } 11 }
	{ reslimage   "Output a resliced image, or  a red-green blend image, or no  resliced image" "Resliced Image"  listofvalues Resliced  { Resliced ColorBlend }  9 }
    }

    set outputs { 
	{ output_transform "Output Transformation"  pxitcltransform  "" 20 }
    }

    set inputs { 
	{ refpoints    "Reference Points" pxitcllandmarks  ""  102 }   
	{ targpoints   "Target Points" pxitcllandmarks  ""  103 }   
    }


    set defaultsuffix  "_mreg" 
    
    set scriptname bis_manualregistration
    set completionstatus "Done"
    #
    #document
    
    set description "Computes a manual registration of an image"
    set description2 ""
    set category "Registration"
    set backwardcompatibility "Reimplemented from GUI code in pxitcloverlaytool.tcl.  "
    set authors "xenophon.papademetris@yale.edu."

    $this InitializeDualImageAlgorithm
    $this RenameInput 0 "Reference Image"
    $this RenameInput 1 "Transform Image" 
    $this RenameOutput 0 "Resliced Image" 101
}

# --------------------------------------------------------------------------

itcl::body bis_manualregistration::PackOptionsGUIInterface { lst } { 


    set n [ llength $lst ]
    
    for { set tab 0 } { $tab <= 1 } { incr tab } {
	set wlist ""
	for { set i 0 } { $i < $n } { incr i } {
	    
		set pair [ lindex $lst $i ]
		set ind  [ lindex $pair 1 ]
		if { $ind == $tab } {
		    lappend wlist $pair
		}
	    }

	set wlist [ lsort -integer  -index 0 $wlist ]

	if { $tab == 1 } {
	    for { set j 0 } { $j < [ llength $wlist ] } { incr j } {
		set pair [ lindex $wlist $j ]
		set name [ lindex $pair 2 ]
		set widg [ lindex $pair 3 ]
		pack $widg -side top -expand false -fill x -padx 1
	    }
	} else {
	    # Custom Pack
	    if { $guimode != "managed" } {
		grid  [ $OptionsArray(usepoints) GetBaseWidget ]  -row 0 -column 0 -padx 0 -columnspan 2
		grid  [ $OptionsArray(mode) GetBaseWidget ]       -row 1 -column 0 -columnspan 3 
	    }

	    grid  [ $OptionsArray(shiftx) GetBaseWidget ]  -row 2 -column 0 
	    grid  [ $OptionsArray(anglex) GetBaseWidget ]  -row 2 -column 1 
	    grid  [ $OptionsArray(scalex) GetBaseWidget ]  -row 2 -column 2 

	    grid  [ $OptionsArray(shifty) GetBaseWidget ]  -row 3 -column 0 
	    grid  [ $OptionsArray(angley) GetBaseWidget ]   -row 3 -column 1
	    grid  [ $OptionsArray(scaley) GetBaseWidget ]   -row 3 -column 2

	    grid  [ $OptionsArray(shiftz) GetBaseWidget ]  -row 4 -column 0 
	    grid  [ $OptionsArray(anglez) GetBaseWidget ]   -row 4 -column 1
	    grid  [ $OptionsArray(scalez) GetBaseWidget ]   -row 4 -column 2

	    grid  [ $OptionsArray(reslimage) GetBaseWidget ]   -row 5 -column 0

	    set v [ file rootname  [ $OptionsArray(reslimage) GetBaseWidget ]]
	    grid rowconfigure $v 6 -weight 100
	    grid columnconfigure $v 3 -weight 100
	}
    }
    update idletasks


}
# -----------------------------------------------------------------------------------------
itcl::body bis_manualregistration::GetOutputTransformation  { } {
    return [ $this GetOutputObject output_transform ]
}

itcl::body bis_manualregistration::UpdateOutputFilenames { } {

    set f(0) [ $InputsArray(input_image) GetFileName ]
    set f(1) [ $InputsArray(second_image) GetFileName ]
    
    for { set i 0 } { $i <= 1 } { incr i } {
	set l($i) [ ::bis_common::SplitFileNameGZ $f($i) ]
	set f($i) [ file tail [ lindex $l($i) 0 ] ]
	set ext($i) [ lindex $l($i) 1 ]
    }
    
    set fname [ file join [ file dirname $f(0) ] "$f(0)_$f(1)" ]

    set force 0;    if { $guimode == "managed" } {	set force 1    }    

    $OutputsArray(output_image) SetFileName "${fname}_${defaultsuffix}$ext(0)" $force
    if {  [ $OptionsArray(usepoints)  GetValue ] > 0 && [ $OptionsArray(mode) GetValue ] == "tps" } {
	$OutputsArray(output_transform) SetFileName "${fname}_${defaultsuffix}.tps"  $force
    } else {
	$OutputsArray(output_transform) SetFileName "${fname}_${defaultsuffix}.matr" $force
    }
    return 1
}

# -----------------------------------------------------------------------------------------
itcl::body bis_manualregistration::UpdateInputsFromContainer { } {

    if { $containerobject == 0 } {    
	return
    }


    $this SetSecondInput [ $containerobject GetTargetImage ] 
    $this SetInput       [ $containerobject GetReferenceImage ] 
    [ $this GetOutputTransformation ] configure -filename ""
    [ $this GetOutput ] configure -filename ""
    $this UpdateOutputFilenames
    return

}
# ------------------------------------------------------------------------------------------
itcl::body bis_manualregistration::UpdateContainerWithOutput { } {

    set img [ $this GetOutput ]
    if { [ $img GetImageSize ] < 2 } {
	return ""
    }
    if { $containerobject == 0 } {
	if { $bis_viewer !=0 } {
	    $bis_viewer SetImage $img
	}  elseif { $vtk_viewer !=0 } {
	    $vtk_viewer SetImage [ $img GetImage ] [ $img GetOrientation ]
	} 
    } else {
	$containerobject SetResultsFromObject $img $this
	$containerobject SetTransformationFromObject [ $this GetOutputTransformation ] $this
    }
}

# -----------------------------------------------------------------------------------------
itcl::body bis_manualregistration::CheckInputObjects { } {


    set imglist [ list    [ $this GetInput ]   [ $this GetSecondInput ] ]
    
    foreach image_in $imglist {
	set d [ $image_in GetImageSize ]
	if { $d < 2 } {
	return 0
	}
    }
    return 1
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------



itcl::body bis_manualregistration::Execute {  } {

    #    $this UpdateInputsFromContainer


    PrintDebug "bis_manualregistration::Execute"
 #   puts stderr "Shifting [ $this GetCommandLine full ]"


    if {  [ $OptionsArray(usepoints)  GetValue ] > 0 } {
	set land1 [ [ $this GetInputObject refpoints ] GetLandmarks ]
	set land2 [ [ $this GetInputObject targpoints ] GetLandmarks ]
	
	if { [ $land1 GetNumPoints ] != [ $land2 GetNumPoints ]  } {
	    set errormessage "Point sets do not have equal numbers of points"
	    return 0
	}

	set b1 [ vtkpxBaseCurve New ]
	$b1 Copy $land1
	$b1 Compact
	
	set b2 [ vtkpxBaseCurve New ]
	$b2 Copy $land2
	$b2 Compact

	set mode [ $OptionsArray(mode) GetValue ]
	if { $mode != "tps" } {
	    set tr [  vtkLandmarkTransform New ] 
	    if { $mode == "rigid" } { 
		$tr SetModeToRigidBody
	    } elseif { $mode == "similarity" } {
		$tr SetModeToSimilarity
	    } else {
		$tr SetModeToAffine
	    }
	} else {
	    set tr [ vtkThinPlateSplineTransform New ]
	    $tr SetBasisToR
	}
	
	$tr SetSourceLandmarks [ $b1 GetPoints ]
	$tr SetTargetLandmarks [ $b2 GetPoints ]
	$tr Modified
	$tr Update
	[ $this GetOutputTransformation ] CopyTransformation $tr
	$tr Delete
	$b1 Delete
	$b2 Delete
    } else {
	set dshift(x)   [ $OptionsArray(shiftx) GetValue ]
	set drotate(x)  [ $OptionsArray(anglex) GetValue ]
	set scale(x)    [ $OptionsArray(scalex) GetValue ]
	set dshift(y)   [ $OptionsArray(shifty) GetValue ]
	set drotate(y) [ $OptionsArray(angley) GetValue ]
	set scale(y)    [ $OptionsArray(scaley) GetValue ]
	set dshift(z)  [ $OptionsArray(shiftz) GetValue ]
	set drotate(z) [ $OptionsArray(anglez) GetValue ]
	set scale(z)   [ $OptionsArray(scalez) GetValue ]

	set image_ref  [ $InputsArray(input_image) GetObject ]
	set image_trn  [ $InputsArray(second_image) GetObject ]
	
	set sp(x) [ lindex [ [  $image_ref GetImage ] GetSpacing  ] 0 ]
	set sp(y) [ lindex [ [  $image_ref GetImage ] GetSpacing  ] 1 ]
	set sp(z) [ lindex [ [  $image_ref GetImage ] GetSpacing  ] 2 ]
	
	
	set tr2 [ vtkTransform [ pxvtable::vnewobj ]]
	set xform [ vtkpxLinearTransform [ pxvtable::vnewobj ]]
	$xform ManualSetParameters [expr $dshift(x)*$sp(x) ] [ expr $dshift(y) * $sp(y) ] [ expr $dshift(z)*$sp(z) ] $drotate(x) $drotate(y) $drotate(z) $scale(x) $scale(y) $scale(z)  [ $image_ref GetImage ] [ $image_ref GetOrientation ] [  $image_trn GetImage ] [ $image_trn GetOrientation ] $tr2
	
	[ $this GetOutputTransformation ] CopyTransformation $tr2
	$xform Delete
	$tr2 Delete
    }

    if { [ $OptionsArray(reslimage) GetValue ] == "Resliced" } {
	set reslice_alg [bis_resliceimage [pxvtable::vnewobj]]
    } else {
	set reslice_alg [bis_colorblendimage [pxvtable::vnewobj]]
    }
    
    $reslice_alg InitializeFromContainer $this
    $reslice_alg SetInput [ $this GetInput ] 
    $reslice_alg SetSecondInput [ $this GetSecondInput ] 
    $reslice_alg SetTransformation [ $this GetOutputTransformation ] 
    $reslice_alg Execute
    
#    [ $this GetOutput ] ShallowCopy [ $reslice_alg GetOutput ]
    #changed this because output name was getting messed up
    #we always got the default output from reslice_alg 
    #and not what was via -out2
    [ $this GetOutput ] ShallowCopyImage  [ [ $reslice_alg GetOutput ] GetImage ]
    itcl::delete obj $reslice_alg
    [ [ $this GetOutput ] GetImageHeader ] AddComment [ $this GetCommandLine full ] 

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_manualregistration.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_manualregistration [pxvtable::vnewobj]]
    $alg MainFunction 
}





