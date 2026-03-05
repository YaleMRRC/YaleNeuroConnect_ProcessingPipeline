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

package require bis_imagetoimagealgorithm 1.0

package provide bis_sliceinhomogeneity 1.0

#
# bias field correction
#

itcl::class bis_sliceinhomogeneity {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Slice Inhomogeneity" }

    #
    #protected
    #

    protected method RunSliceHomogeneity   { inputimage } 
    protected method RunTripleSliceHomogeneity   { inputimage } 
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_sliceinhomogeneity::Initialize { } {

    PrintDebug "bis_sliceinhomogeneity::Initialize" 
    #name,description,type,object,filename(if applicable),priority (optional)


    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ dotriple "if off do slice else tripleslice. When dotriple is off, the algorithm computes inhomogeneity along the slice direction, else this is computed for all three axis" "DoTriple" boolean 0 { 0 1 } 0 }
    }
    
    set defaultsuffix { "_inhom"  }
    
    set scriptname bis_sliceinhomogeneity

    #
    #document
    #

    set category "Image Processing Dual"
    set description "corrects  slice inhomogeneity correction for MRI acquisitions."
    set description2 "Single slice is default, triple slice is useful as a crude bias field correction for high field acquisitions."
    set backwardcompatibility "Reimplemented from pxmat_biasfieled.tcl. "
    set authors "hirohito.okuda@yale.edu,xenophon.papademetris.yale.edu"

    $this InitializeImageToImageAlgorithm

}
# ---------------------------------------------------------------------------------------------------------

itcl::body bis_sliceinhomogeneity::RunSliceHomogeneity   { inputimage } { 

    set fit [ vtkpxSliceBiasFieldCorrection  [ pxvtable::vnewobj ]]
    $this SetFilterCallbacks $fit "Slice Correction"
    $fit SetPureScaling 0
    $fit SetInput       $inputimage

	
    $fit Update

    set img [ vtkImageData [ pxvtable::vnewobj ]]
    $img ShallowCopy [ $fit GetOutput ]
    $fit Delete
    return  $img 
}
# ----------------------------------------------------------------------------------------------------
itcl::body bis_sliceinhomogeneity::RunTripleSliceHomogeneity   { inputimage } { 

    set axislist { x y z }

    set output [ vtkImageData [ pxvtable::vnewobj ]]
    $output ShallowCopy $inputimage
    
    for { set axis 0 } { $axis <=2 } { incr axis } {
	set nm [ lindex $axislist $axis ]
	puts stderr ".... Slice Inhomogeneity Correction orientation  axis= [ lindex $axislist $axis ]\n"
	set fit [ vtkpxSliceBiasFieldCorrection New ]
	$fit SetAxis $axis
	$this SetFilterCallbacks $fit "Axis $nm Correction"
	$fit SetPureScaling 0
	$fit SetInput       $output
	$fit Update
	$output ShallowCopy [ $fit GetOutput ]
	$fit Delete
    }
    return  $output
}
# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_sliceinhomogeneity::Execute {  } {

    DebugOn
    PrintDebug "bis_sliceinhomogeneity::Execute"

    set mode        [ $OptionsArray(dotriple)      GetValue ]
    set image_in    [ $InputsArray(input_image) GetObject ]
    

    if { $mode ==  0 } {
	puts stdout "Running Slice"
	set outimg [ RunSliceHomogeneity [$image_in GetObject]]
    } else {
	puts stderr "Running Triple Slice"
	set outimg [ RunTripleSliceHomogeneity [$image_in GetObject]]
    }
    
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage $outimg
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ $this GetCommandLine "full" ]
    [ $outimage GetImageHeader ] AddComment $comment 0

    $outimg Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_sliceinhomogeneity.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_sliceinhomogeneity [pxvtable::vnewobj]]
    $alg MainFunction 
}

