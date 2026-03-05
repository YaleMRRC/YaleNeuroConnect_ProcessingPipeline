#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" "$@"

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
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] mjack]

package require bis_imagetoimagealgorithm 1.0
package require vtkmpjcontrib 
package require mpjtensoranalysis
package require bis_basecontrolhelper

package provide bis_tensoranalysis 1.0

#
# tensor analysis
#

itcl::class bis_tensoranalysis {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }
    destructor { $this DeleteDTIControl }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Compute DTI Maps" }
    #
    #public
    #

    public method UpdateOutputFilenames { } 

    public method ConfigureOptionsGUICallbacks { } 

    public method ShowDTIControl {  args } 
    protected method DeleteDTIControl { }
    protected method CopyOutputObject { name index comment comment2 } 

    # variables
    protected variable tensoranalysis 0
    protected variable bishelper 0
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_tensoranalysis::Initialize { } {

    PrintDebug "bis_tensoranalysis::Initialize" 
    #name,description,type,object,filename(if applicable),priority (optional)
    
    #name,description,type,object,filename(if applicable),priority (optional)
    set outputs {
	{ out_ormap "Orientation Map" pxitclimage  "" 10 }
	{ out_ramap "Relative Anistropy map"    pxitclimage  "" 100 }
	{ out_meand "Mean Diffusivity map"        pxitclimage  "" 102 }
    }
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ cscheme  "Color Scheme for orientation map" "Col Scheme"  { listofvalues } Absolute { AbsoluteValue RotSymmetry NoSymmetry MirrorSymmetry } 1 }
	{ satfactor  "Saturation Factor" "Saturation"  real 0.5 { 0.1 5.0 } 2 }
	{ brightness  "Brightness" "Brightness"  real 2.0 { 0.1 5.0 } 3 }
	{ usemask     "Use Mask when creating orientation map" "Use Mask" boolean 1 { 0 1 } -10 }
    }
    lappend options [ list guishowcontrol  "Show Tensor Utility Control" "Show Control"  { boolean } 0 { 0 1 }  5 ]

    set defaultsuffix { _fractani _ormap }
    
    set scriptname bis_tensoranalysis

    #
    #document
    #

    set category "Diffusion Tensor"
    set description  "computes FA map, orientation map and optionally (RA, MD, VR, CI)." 
    set description2 "This tool takes as an input a calculated tensor map and computes useful maps such as the Fractional Anisotropy map, an orientation colormap and optionally Relative Anisotropy map, Volume Ratio map, Mean Diffusity map, Inter voxel  Coherence map"
    set backwardcompatibility "Reimplemented from pxmat_tensoranalysis.tcl"
    set authors "marcel.jackowski@yale.edu,xenophon.papademetris.yale.edu,hirohito.okuda@yale.edu"

    $this InitializeImageToImageAlgorithm

    $this RenameInput 0 "Tensor Image"
    $this RenameOutput 0 "Frac Anisotropy Map"
}

# -----------------------------------------------------------------------------------------

itcl::body bis_tensoranalysis::UpdateOutputFilenames { } {

    set fn [ $InputsArray(input_image) GetFileName ]
    set outlist [ $this CreateDefaultOutputFileList $fn ]

    set l [ ::bis_common::SplitFileNameGZ $fn ]
    set ext [ lindex $l 1 ]

    set force 0;    if { $guimode == "managed" } {	set force 1    }    

    set m [ lindex $outlist 0 ]
    $OutputsArray(output_image) SetFileName "${m}${ext}" $force
    set m [ lindex $outlist 1 ]
    $OutputsArray(out_ormap) SetFileName "${m}${ext}" $force
    return 1
}

itcl::body bis_tensoranalysis::CopyOutputObject { name index comment comment2 } {

    set f2 [ [ $this GetOutputObject $name ] GetFileName ]
    [ $this GetOutputObject $name ] ShallowCopy [ $tensoranalysis GetOutputImage $index ]
    [ $this GetOutputObject $name ] AddComment "$comment ($comment2)" 
    if { [ string length $f2 ] > 1 } {
	[ $this GetOutputObject $name ] SetFileName $f2
    }

}


itcl::body bis_tensoranalysis::DeleteDTIControl { } {

    if { $tensoranalysis == 0 } {
	return
    }

    $tensoranalysis ClearAllResults
    #    $tensoranalysis RemoveAllInputs

    itcl::delete obj $bishelper
    itcl::delete obj $tensoranalysis
}

# -----------------------------------------------------------------------------------------
itcl::body bis_tensoranalysis::ConfigureOptionsGUICallbacks { } {

    eval "$OptionsArray(guishowcontrol) SetGUICallbackFunction { $this ShowDTIControl }"
}

itcl::body bis_tensoranalysis::ShowDTIControl {  args } {


    if { $tensoranalysis != 0 } {
	if { [ $OptionsArray(guishowcontrol) GetValue ] ==0 } {
	    $tensoranalysis HideWindow
	} else  {
	    $tensoranalysis ShowWindow Tensor
	}
    }
}
# ---------------------------------------------------------------

itcl::body bis_tensoranalysis::DeleteDTIControl { } {

    if { $tensoranalysis == 0 } {
	return
    }

    $tensoranalysis ClearAllResults
    #    $tensoranalysis RemoveAllInputs

    itcl::delete obj $bishelper
    itcl::delete obj $tensoranalysis
}

# -----------------------------------------------------------------------------------------
itcl::body bis_tensoranalysis::ConfigureOptionsGUICallbacks { } {

    eval "$OptionsArray(guishowcontrol) SetGUICallbackFunction { $this ShowDTIControl }"
}

itcl::body bis_tensoranalysis::ShowDTIControl {  args } {


    if { $tensoranalysis != 0 } {
	if { [ $OptionsArray(guishowcontrol) GetValue ] ==0 } {
	    $tensoranalysis HideWindow
	} else  {
	    $tensoranalysis ShowWindow Tensor
	}
    }
}


# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_tensoranalysis::Execute {  } {

    set image_in    [ $this GetInput ]  
    set cscheme     [ $OptionsArray(cscheme) GetValue ]
    set satfactor   [ $OptionsArray(satfactor) GetValue ]
    set brightness  [ $OptionsArray(brightness) GetValue ]
    set usemask     [ $OptionsArray(usemask) GetValue ]


    if { $tensoranalysis == 0 } {

	set bishelper [ [ bis_basecontrolhelper #auto $this ] GetThisPointer ]

	if { $basewidget!=0 } {
	    set b $basewidget.[pxvtable::vnewobj ]
	} else {
	    set b .[pxvtable::vnewobj ]
	}
	set  tensoranalysis [ [  mpjtensoranalysis \#auto $bishelper  ] GetThisPointer ]
	$tensoranalysis Initialize $b
	$tensoranalysis ShowWindow Tensor
	$tensoranalysis HideWindow
    }

    if { [ $OptionsArray(guishowcontrol) GetValue ] == 1 } {
	$tensoranalysis ShowWindow Tensor
    } else {
	$tensoranalysis HideWindow
    }
    

    $tensoranalysis LoadTensor [ [ $this GetInput ] GetFileName ]
    $tensoranalysis SetParametersFromBisAlgorithmAndCompute $cscheme $satfactor $brightness $usemask

    set comment [ format " [ $this GetCommandLine full ]" ]
    
    $this CopyOutputObject output_image 5 $comment "fa map"
    $this CopyOutputObject out_ramap 6 $comment "relative anisotropy map"
    $this CopyOutputObject out_meand 7 $comment "mean diff map"

    $tensoranalysis BisComputeDirectionMaps
    
    set f2 [ [ $this GetOutputObject out_ormap ] GetFileName ]
    [ $this GetOutputObject out_ormap ] ShallowCopy [ $tensoranalysis GetBisDirectionImage ]
    [ $this GetOutputObject out_ormap ] AddComment "$comment (orientation map)" 
    if { [ string length $f2 ] > 1 } {
	[ $this GetOutputObject out_ormap ] SetFileName $f2
    }

    return 1

}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_tensoranalysis.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_tensoranalysis [pxvtable::vnewobj]]
    $alg MainFunction 
}


