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
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] mjack ]

package provide bis_tensordistancemap 1.0
package require bis_imagetoimagealgorithm 1.0
package require vtkmpjcontrib 

itcl::class bis_tensordistancemap {

    inherit bis_imagetoimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Tensor DistanceMap" }
    public method UpdateInputsFromContainer { }
    protected method ConfigureOptionsGUICallbacks { } 
    public    method AutoSeed { args } 


    protected variable added_cursor_notifier 0
}


# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_tensordistancemap::Initialize { } {

    PrintDebug "bis_tensordistancemap::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ seedx   "X Coordinate of seed location in voxels" "Seed X"  { integer default   } 64 { 0 1999 }  0 }
	{ seedy   "Y Coordinate of seed location in voxels" "Seed Y"  { integer default   } 73 { 0 1999 }  1 }
	{ seedz   "Z Coordinate of seed location in voxels" "Seed Z"  { integer default   } 20 { 0 1999 }  2 }
	{ guiautoupdate  "Update seed from GUI Cross-Hairs" "Auto Seed"  { boolean } 0 { 0 1 }  3 }
	{ infinity "Max Value for Propagation Time" "Infinity" { integer default } 200 { 10 32767 } -10 }
	{ thr "Threshold for automatic mask generation (if one is not provided)" "Auto Threshold" { real default } 0.5 { 0.1 1000.0 } -11 }
	{ normalized   "Normalized FM distance by Euclidean distance" "Normalized" boolean 1    { 0 1 }      4 }
	{ usemask   "Use Mask Image (if not automatically generate one using threshold thr)"  "Use External Mask Image"  boolean   0  { 0 1  }  10  }
    }

    
    set inputs {
	{ maskimage  "Mask for Connectivity (Optional)"             pxitclimage  "" 500 }
    }

    set defaultsuffix { "_prop" }
    set scriptname bis_tensordistancemap
    set completionstatus "Done"

    #
    #document
    #
    set category "Diffusion Tensor"    
    set description "Create a distance map from a tensor image and a seed based on fast marching tractography"
    set description2 ""
    set backwardcompatibility "None"
    set authors "xenophon.papademetris@yale.edu based on some original code by Marcel Jackowski."

    $this InitializeImageToImageAlgorithm
    $this RenameInput 0 "Tensor Image" 0
    $this RenameOutput 0 "FM Solution" 0

}

# ---------------------------------------------------------------------------------------

itcl::body bis_tensordistancemap::UpdateInputsFromContainer { } {

    bis_imagetoimagealgorithm::UpdateInputsFromContainer 

    # This happens when image has changed 
    set currentimage  [ $InputsArray(input_image) GetObject ]


    scan [ [ $currentimage GetImage ] GetDimensions ] "%d %d %d" dim(0) dim(1) dim(2)
    for { set i 0 } { $i <=2 } { incr i } { 
	set dim($i) [ expr $dim($i) -1 ] 
    }

    $OptionsArray(seedx) SetValueRange [ list 0 $dim(0) ]
    $OptionsArray(seedy) SetValueRange [ list 0 $dim(1) ]
    $OptionsArray(seedz) SetValueRange [ list 0 $dim(2) ]

}

itcl::body bis_tensordistancemap::ConfigureOptionsGUICallbacks { } {

    eval "$OptionsArray(guiautoupdate) SetGUICallbackFunction { $this AutoSeed }"
}

itcl::body bis_tensordistancemap::AutoSeed {  args } {

    if { [ $OptionsArray(guiautoupdate) GetValue ] ==0 } {
	return
    }

    if { $added_cursor_notifier == 0 } {
	set bv [ $this GetBisViewer ]
	if { $bv !=0 } {
	    if { [ $bv isa bis_viewer ] } {
		set added_cursor_notifier 1
		$bv AddCursorNotifier $this AutoSeed 
	    }
	}
    }

    if { [ $this GetViewer ] != 0 } {
	set lv [ $vtk_viewer GetLastClickedPoint ] 
	set px [ lindex $lv 0 ]
	set py [ lindex $lv 1 ]
	set pz [ lindex $lv 2 ]
	if { $px>0 || $py>0 || $pz>0 } {
	    $OptionsArray(seedx) SetValue [ expr int($px+0.5) ]
	    $OptionsArray(seedy) SetValue [ expr int($py+0.5) ]
	    $OptionsArray(seedz) SetValue [ expr int($pz+0.5) ]
	}
    }
}

itcl::body bis_tensordistancemap::Execute {  } {

    PrintDebug "bis_tensordistancemap::Execute"

    $this AutoSeed

    set sx   [ expr int([$OptionsArray(seedx) GetValue ]+0.5) ]
    set sy   [ expr int([$OptionsArray(seedy) GetValue ]+0.5) ]
    set sz   [ expr int([$OptionsArray(seedz) GetValue ]+0.5) ]
    set nrm  [ expr int([ $OptionsArray(normalized) GetValue ]) > 0 ]
    set msk [ $OptionsArray(usemask) GetValue ]
    set thr [ $OptionsArray(thr) GetValue ]

    

    set image_in [ $this GetInput ]
    set img [ $image_in GetImage ]

    if { [ $img  GetNumberOfScalarComponents ] !=6 } {
	set errormessage "Error: Bad input image (not a tensor, nc!=6 )"
	return 0
    }
    
    set distancemap  [ vtkbisOptimizedFastMarchingConnectivity New ]
    $distancemap SetInfinity [ $OptionsArray(infinity) GetValue ]
    $distancemap SetAutoThreshold $thr
    $this SetFilterCallbacks $distancemap "Compute Tensor Distance"
    $distancemap SetNormalizedDistance $nrm

    if { $msk > 0 } {
	$distancemap SetMask [ [ $this GetInputObject maskimage ] GetObject ]
    }
    $distancemap RunSeed $img $sx $sy $sz


    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $distancemap GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $distancemap Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_tensordistancemap.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_tensordistancemap [pxvtable::vnewobj]]
    $alg MainFunction 
}





