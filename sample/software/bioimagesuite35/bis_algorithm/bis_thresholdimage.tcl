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

package require bis_basethresholdimage 1.0

package provide bis_thresholdimage 1.0

# -----------------------------------------------------------------------------------------
# threshold image
#

itcl::class bis_thresholdimage {

    inherit bis_basethresholdimage

     constructor { } {
	 $this InitializeThresholdImage
     }

    public method InitializeThresholdImage { }
    public method Execute { }
    public method GetGUIName    { } { return "Threshold Image" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_thresholdimage::InitializeThresholdImage { } {

    PrintDebug "bis_thresholdimage::Initialize" 
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    lappend  options [ list setmintozero "Set Minimum Value to Zero" "Min Value to Zero"   { listofvalues radiobuttons } Off  { On Off }  7 ]

    set scriptname bis_thresholdimage
    set completionstatus "Implementation needs work, interface is OK" 
    #document
    #
    set description "thresholds an image to generate a binary output using a specific threshold."
    set description2 "The output is a binary image with value = 100 where the original image had values above the threshold and zero elsewhere."
    set backwardcompatibility "Reimplemented from pxmat_thresholdimage.tcl"
    

    $this InitializeBaseThresholdImage
}


itcl::body bis_thresholdimage::Execute {  } {
    
    set lst [ $this ParseArgs ]
    set invalue  [ lindex $lst 0 ]
    set outvalue [ lindex $lst 1 ]
    set replin   [ lindex $lst 2 ] 
    set replout  [ lindex $lst 3 ]
    set dobinary [ lindex $lst 4 ]
    set dosub    [ $OptionsArray(setmintozero) GetValue ]

    set dosubtraction 0
    if { $dosub == "On" && $dobinary ==0 } {
	set dosubtraction 1
    } 

    set minth         [ $OptionsArray(minth) GetValue ]
    set maxth         [ $OptionsArray(maxth) GetValue ]
    
    puts stderr "Dosub=$dosubtraction ($dosub), binm=$dobinary $minth:$maxth inout=$invalue:$outvalue"

    set outimage [ $this GetOutput ]

    
    if { $dosubtraction == 0 } {
	set thresholdF  [  vtkImageThreshold New ]
	$thresholdF ThresholdBetween  $minth $maxth
	$thresholdF SetInValue    $invalue
	$thresholdF SetOutValue   $outvalue
	$thresholdF SetReplaceOut $replout
	$thresholdF SetReplaceIn  $replin
	$thresholdF SetInput [ [ $this GetInput ] GetImage ]
	
	if { $dobinary == 1 } {
	    $thresholdF SetOutputScalarTypeToShort
	}
	SetFilterCallbacks $thresholdF "Thresholding image"
	$thresholdF Update
	
	$outimage ShallowCopyImage  [ $thresholdF GetOutput ]
	$thresholdF Delete 
    } else {
        set sh [ vtkImageShiftScale New]
	set lower   $minth
	set upper   $maxth
	set range   [ expr $upper - $lower ]
	
	$sh SetInput [ [ $this GetInput ] GetImage ]
	$sh SetShift [expr -1.0*$lower ]
	$sh SetScale 1.0
	SetFilterCallbacks $sh "Shifting offset"
	
	set thresholdF  [  vtkImageThreshold New ]
	$thresholdF SetInput [ $sh GetOutput ]	
	$thresholdF ThresholdBetween -0.001 [expr $range + 0.001 ]
	$thresholdF ReplaceOutOn
	$thresholdF SetInValue    $invalue
	$thresholdF SetOutValue   $outvalue
	$thresholdF SetReplaceOut $replout
	$thresholdF SetReplaceIn  $replin
	
	SetFilterCallbacks $thresholdF "Thresholding image"
	$thresholdF Update
	$outimage ShallowCopyImage  [ $thresholdF GetOutput ]
	$thresholdF Delete 
	$sh Delete
    }


    $outimage CopyImageHeader  [ [ $this GetInput ] GetImageHeader ]
    [ $outimage GetImageHeader ] AddComment "[ $this GetCommandLine full ]" 0

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_thresholdimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {

    set alg [bis_thresholdimage [pxvtable::vnewobj]]
    $alg MainFunction 

}





