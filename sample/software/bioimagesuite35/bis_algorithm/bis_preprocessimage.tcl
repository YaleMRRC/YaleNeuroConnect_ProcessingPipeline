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

package provide bis_preprocessimage 1.0
package require bis_dualimagealgorithm 1.0
package require bis_temporalsmoothimage 1.0
package require bis_removetemporaldrift 1.0
package require bis_removeslicemean 1.0


itcl::class bis_preprocessimage {

    inherit bis_dualimagealgorithm
    
    constructor { } {	 $this Initialize  }
    
    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "4D Preprocess Image" }
    #override parent function
    public method CheckInputObjects { }

    # Some GUI Callbacks
    protected method ConfigureOptionsGUICallbacks { } 
    public    method HandleCallbacks { args } 

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_preprocessimage::Initialize { } {

    PrintDebug "bis_preprocessimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{  blursigma "kernel sigma (gaussian) in frames" "Temporal Sigma" { real triplescale 100 } 0 { 0 5 } 10 }
	{  order  "Order of Drift Polynomial" "Drift Polynomial Order"  integer 3 { -1 6 }  0 }
	{  rmslicemean "Remove Slice Mean "  "Remove Slice Mean"  boolean   0  { 0 1  }  30  } 
	{  rmvolumemean "Remove Volumn Mean "  "Remove Volume Mean"  boolean   0  { 0 1  }  35  }
	{  usemask   "Use Mask Image"  "Use Mask"  boolean   0  { 0 1  }  -2  }
    }
    
    set defaultsuffix { "_pre" }
    set scriptname bis_preprocessimage
    set completionstatus "Done"
    
    #
    #document
    #
    
    set description "Preprocess an image."
    set description2 "Preprocess an image with temporal smoothing and/or remove temporal drift and/or remove slice mean or remove volumn mean ."
	set backwardcompatibility ""
    set authors "isabella.murphy@yale.edu, xilin.shen@yale.edu."
    set category "Image Processing-4D"    
    $this InitializeDualImageAlgorithm
    
    $this RenameInput 0 "Functional Image"
    #set priority to 102 to make it optional
    $this RenameInput 1 "Mask Image" 102
}
# -----------------------------------------------------------------------------------------

itcl::body bis_preprocessimage::ConfigureOptionsGUICallbacks { } {

    eval "$OptionsArray(rmslicemean) SetGUICallbackFunction { $this HandleCallbacks slice }"
    eval "$OptionsArray(rmvolumemean) SetGUICallbackFunction { $this HandleCallbacks volume }"
}

itcl::body bis_preprocessimage::HandleCallbacks {  args } {

    set md [ lindex $args 0 ]
    if { $md == "slice" && ( [ $OptionsArray(rmslicemean) GetValue ] == 1 ) } {
	$OptionsArray(rmvolumemean) SetValue 0
    } elseif { $md == "volume" && ( [ $OptionsArray(rmvolumemean) GetValue ]  == 1 ) } {
	$OptionsArray(rmslicemean) SetValue 0
    }

}


# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_preprocessimage::Execute {  } {
	
    PrintDebug "bis_preprocessimage::Execute"
    
    set currentinput [ $this GetInput ]
    set tempsmooth_alg [ bis_temporalsmoothimage \#auto ] 
    set tempdrift_alg  [ bis_removetemporaldrift  \#auto ]
    set tempremove_alg [ bis_removeslicemean \#auto ]
    
    set blursigma     [ $OptionsArray(blursigma) GetValue ]
    set order         [ $OptionsArray(order) GetValue ]
    set rmslicemean   [ $OptionsArray(rmslicemean) GetValue ]
    set rmvolumemean  [ $OptionsArray(rmvolumemean) GetValue ]
    set image_in      [ $this GetInput ]
    set msk [ $OptionsArray(usemask) GetValue ]
    set mask [  [ pxitclimage \#auto ] GetThisPointer ]
    
    if { $msk == "1" } {
	puts stdout "Using Mask ..."
    set mask [ $this GetInputObject second_image ]
    } 
    
    # temporal smooth
    if { $blursigma > 0 } {
	puts stdout "executing temporal smooth"
	$tempsmooth_alg InitializeFromContainer 0 $this
	$tempsmooth_alg SetInput $currentinput
	$tempsmooth_alg SetSecondInput $mask
	$tempsmooth_alg SetOptionValue blursigma $blursigma
	$tempsmooth_alg SetOptionValue usemask $msk
	$tempsmooth_alg Execute
	set currentinput [ $tempsmooth_alg GetOutput ]
    }

    # temporal drift removal
    if { $order > -0.1 } {
	puts stdout "executing drift removal"
	$tempdrift_alg InitializeFromContainer 0 $this
	$tempdrift_alg SetInput $currentinput
	$tempdrift_alg SetSecondInput $mask
	$tempdrift_alg SetOptionValue order $order
	$tempdrift_alg SetOptionValue usemask $msk
	$tempdrift_alg SetOptionValue legendre 1
	$tempdrift_alg Execute
	set currentinput [ $tempdrift_alg GetOutput ]
    }
    
    # remove slice mean
    if { $rmslicemean > 0 || $rmvolumemean > 0 } {
	$tempremove_alg InitializeFromContainer 0 $this
	$tempremove_alg SetInput $currentinput
	$tempremove_alg SetSecondInput $mask
	$tempremove_alg SetOptionValue usemask $msk
	if { $rmslicemean > 0 } {
	    $tempremove_alg SetOptionValue globalmean 0
	    puts stdout "executing remove slice mean"
	} else {
	    $tempremove_alg SetOptionValue globalmean 1
	    puts stdout "executing remove volume mean"
	}
	$tempremove_alg Execute
	set currentinput [ $tempremove_alg GetOutput ]
    }
    
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopy $currentinput 
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
    
    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0
    
    # Clean up objects
    itcl::delete obj $tempsmooth_alg
    itcl::delete obj $tempdrift_alg
    itcl::delete obj $tempremove_alg
    
    return 1
}
# -------------------------------------------------------------------------
itcl::body bis_preprocessimage::CheckInputObjects { } {

    set image_in    [ $this GetInput ]
    set d [ $image_in GetImageSize ]
    if { $d < 2 } {
	return 0
    }
    
    set msk [ $OptionsArray(usemask) GetValue ]

    if { $msk == "1" } {
	set image_in    [ $this GetSecondInput ]
	set d [ $image_in GetImageSize ]
	if { $d < 2 } {
	    return 0
	}
    }
    return 1
    
}
# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_preprocessimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function
    
    set alg [bis_preprocessimage [pxvtable::vnewobj]]
    $alg MainFunction 
}


