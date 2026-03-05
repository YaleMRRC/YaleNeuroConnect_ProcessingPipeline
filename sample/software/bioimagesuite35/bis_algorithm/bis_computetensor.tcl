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
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] mjack]

package require bis_imagelisttoimagealgorithm 
package require vtkmpjcontrib 
package require mpjtensorutility 
package require bis_basecontrolhelper

package provide bis_computetensor 1.0


# -------------------------------
itcl::class bis_computetensor {

    inherit bis_imagelisttoimagealgorithm
    
    constructor { } {
	$this Initialize
    }

    destructor { $this DeleteDTIControl }
    
    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Compute Tensor" }
    public method UpdateOutputFilenames { } 
    public method ConfigureOptionsGUICallbacks { } 

    public method ShowDTIControl {  args } 
    protected method DeleteDTIControl { }
    protected method CopyOutputObject { name index comment comment2 } 

    # variables
    protected variable tensorutility 0
    protected variable bishelper 0



}
# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_computetensor::Initialize { } {

    PrintDebug "bis_computetensor::Initialize" 

    #name,description,type,object,filename(if applicable),priority (optional)
    set inputs { }


    set outputs {
	{ outadc "ADC"    pxitclimage  "" 100 }
	{ outbase "Baseline"          pxitclimage  "" 101 }
    }
    
    set gradientnamelist [ list ME6 ICO6 ICO10 ICO15 ICO21 ME24 ME32 VAR15 Custom ]

    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options ""

    lappend options [ eval "list directions  \"acquisition directions\" Directions  listofvalues [ lindex $gradientnamelist 0 ]  { $gradientnamelist }  1" ]
    lappend options [ eval "list ndw  \"Number of Baseline Images\" \"Num Baseline\"  integer 1 { 0 20 } 2 " ]
    lappend options [ eval "list bval  \"b-value (s/mm**2)\" \"b-value\"  real 1000 { 1 10000 } 3 " ]
    lappend options [ list dirfname   "specify the filname for custom directions" "Directions File Name" { filename readfile } "" { text { .txt } } 30 ]
    lappend options [ list flipx   "Flip the x-direction of the images" "Flip-X" listofvalues Auto  { On Off Auto } -30 ]
    lappend options [ list flipy   "Flip the y-direction of the images" "Flip-Y" listofvalues Auto  { On Off Auto } -31 ]
    lappend options [ list flipz   "Flip the z-direction of the images" "Flip-Z" listofvalues Auto  { On Off Auto } -32 ]
    lappend options [ list guishowcontrol  "Show Tensor Utility Control" "Show Control"  { boolean } 0 { 0 1 }  5 ]

    set defaultsuffix { _tensor }
    
    set scriptname bis_computetensor

    #
    #document
    #

    set category "Diffusion Tensor"
    set description  "Given Raw DWI images, it estimates the symmetric 6-component tensor"
    set description2 "BioImage Suite assumes(or forces on load in the case of NIFTI images) LPS Image Orientation hence flipx=flipy=1 by default"
    set backwardcompatibility "Reimplemented from pxmat_diffusionutility.tcl"
    set authors "marcel.jackowski@yale.edu,xenophon.papademetris.yale.edu"

    $this InitializeImageListToImageAlgorithm

    $this RenameOutput 0 "Tensor Image"
}

# ---------------------------------------------------------------

itcl::body bis_computetensor::DeleteDTIControl { } {

    if { $tensorutility == 0 } {
	return
    }

    $tensorutility ClearAllResults
    $tensorutility RemoveAllInputs

    itcl::delete obj $bishelper
    itcl::delete obj $tensorutility
}

# -----------------------------------------------------------------------------------------
itcl::body bis_computetensor::UpdateOutputFilenames { } {

    set inplist [ $InputsArray($directinputs) GetAllObjects ]
    set fn  [ [ lindex $inplist 0 ] GetFileName ]
    set outlist [ $this CreateDefaultOutputFileList $fn ]

    set l [ ::bis_common::SplitFileNameGZ $fn ]
    set ext [ lindex $l 1 ]

    set force 0;    if { $guimode == "managed" } {	set force 1    }    

    set m [ lindex $outlist 0 ]
    $OutputsArray(output_image) SetFileName "${m}${ext}" $force
    return 1
}
# -----------------------------------------------------------------------------------------
itcl::body bis_computetensor::CopyOutputObject { name index comment comment2 } {

    set f2 [ [ $this GetOutputObject $name ] GetFileName ]
    [ $this GetOutputObject $name ] ShallowCopy [ $tensorutility GetOutputImage $index ]
    [ $this GetOutputObject $name ] AddComment "$comment ($comment2)" 
    if { [ string length $f2 ] > 1 } {
	[ $this GetOutputObject $name ] SetFileName $f2
    }

}

# -----------------------------------------------------------------------------------------
itcl::body bis_computetensor::ConfigureOptionsGUICallbacks { } {

    eval "$OptionsArray(guishowcontrol) SetGUICallbackFunction { $this ShowDTIControl }"
}

itcl::body bis_computetensor::ShowDTIControl {  args } {


    if { $tensorutility != 0 } {
	if { [ $OptionsArray(guishowcontrol) GetValue ] ==0 } {
	    $tensorutility HideWindow
	} else  {
	    $tensorutility ShowWindow Diffusion
	}
    }
}
# -----------------------------------------------------------------------------------------

itcl::body bis_computetensor::Execute {  } {



    set inplist [ $InputsArray($directinputs) GetAllObjects ]
    set numfiles [ llength $inplist ]
    set directions  [ $OptionsArray(directions) GetValue ]
    set ndw         [ $OptionsArray(ndw) GetValue ]
    set bval        [ $OptionsArray(bval) GetValue ]
    set dirfname    [ $OptionsArray(dirfname) GetValue ]
    set flip(1)       [ $OptionsArray(flipx) GetValue ]
    set flip(2)     [ $OptionsArray(flipy) GetValue ]
    set flip(3)     [ $OptionsArray(flipz) GetValue ]

    if { $numfiles == 0 } {
	set errormessage "No Inputs specified"
	return 0
    }


    if { $tensorutility == 0 } {

	set bishelper [ [ bis_basecontrolhelper #auto $this ] GetThisPointer ]

	if { $basewidget!=0 } {
	    set b $basewidget.[pxvtable::vnewobj ]
	} else {
	    set b .[pxvtable::vnewobj ]
	}
	set  tensorutility [ [  mpjtensorutility \#auto $bishelper  ] GetThisPointer ]
	$tensorutility Initialize $b
	$tensorutility ShowWindow Diffusion
	$tensorutility HideWindow
    }

    if { [ $OptionsArray(guishowcontrol) GetValue ] == 1 } {
	$tensorutility ShowWindow Diffusion
    } else {
	$tensorutility HideWindow
    }
    

    $tensorutility RemoveAllInputs
    for { set i 0 } { $i < $numfiles } { incr i } {
	set ok [ $tensorutility AddInput [ [ lindex $inplist $i ] GetFileName ] 0 ]
	if { [ lindex $ok 0 ] == 0 } {
	    set errormessage [ lindex $ok 1 ]
	    return 0
	}
    }

    set hdr [ [ lindex $inplist 0 ] GetImageHeader ]
    for { set i 1 } { $i <=3 } { incr i } {
	if { $flip($i) == "On" } {
	    set flip($i) 1
	} elseif { $flip($i) == "Off" } {
	    set flip($i) 0
	} else {
	    set orient [ $hdr GetOrientation ]
	    puts stdout "Orientation = $orient"
	    set flip($i) 0
	    if { [ $hdr GetMode ] > 0  } {
		
	    } elseif { $orient == 0 } {
		if { $i < 3 } {
		    set flip($i) 1
		} else {
		    set flip($i) 0
		}
	    } 
	}
    }


    $tensorutility SetParametersFromBisAlgorithm $ndw $bval $directions $dirfname $flip(1) $flip(2) $flip(3)
    $tensorutility ComputeResults

    set comment [ format " [ $this GetCommandLine full ]" ]
    $this CopyOutputObject output_image 2 $comment "tensor"
    $this CopyOutputObject outadc 4 $comment "adc"
    $this CopyOutputObject outbase 0 $comment "baseline"
    
    return 1

}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_computetensor.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_computetensor [pxvtable::vnewobj]]
    $alg MainFunction 
}

