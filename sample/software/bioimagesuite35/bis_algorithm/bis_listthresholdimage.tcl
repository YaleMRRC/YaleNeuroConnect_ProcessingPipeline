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

package require bis_imagetoimagealgorithm 1.0

package provide bis_listthresholdimage 1.0

# -----------------------------------------------------------------------------------------
# threshold image
#

itcl::class bis_listthresholdimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Threshold By List" }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_listthresholdimage::Initialize { } {

    PrintDebug "bis_listthresholdimage::Initialize" 
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ list  "Threshold Image List (as opposed to thresholds)" "Threshold List"  string "" { "" }  3 }
	{ inverse "Inverse Threshold"  "Inverse" { listofvalues radiobuttons } Off  { On Off }  -10 }
	{ binary "Binary Output" "Binary Output Size"   { listofvalues radiobuttons } Off  { Off On x100 }  6 }
    }

    set defaultsuffix { "_lthr" }
    
    set scriptname bis_listlistthresholdimage
    set completionstatus "Implementation needs work, interface is OK" 
    #document
    #
    set description "thresholds an image to generate a binary output using a specific threshold."
    set description2 "The output is a binary image with value = 100 where the original image had values above the threshold and zero elsewhere."
    set backwardcompatibility "Reimplemented from pxmat_listthresholdimage.tcl"
    

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Threshold Algorithms
# -----------------------------------------------------------------------------------------

itcl::body bis_listthresholdimage::Execute {  } { 

    set bm          [ $OptionsArray(binary) GetValue ]
    set scalef 1
    set binarymask 1
    if { $bm == "Off" } {
	set binarymask 0
    } elseif { $bm == "x100" } {
	set scalef 100
    }

    set invalue $scalef
    set outvalue 0

    
    if { [ $OptionsArray(inverse) GetValue ] == "On"  } {
	set outvalue $invalue
	set invalue  0
    }

    set lst           [ $OptionsArray(list) GetValue ]
    # Remove quotes from string !
    regsub -all "\"" $lst " " lst

    set newlst ""
    for { set i 0 } { $i < [ llength $lst ] } { incr i } {
	catch { 
	    set v [ expr round([ lindex $lst $i ] ) ] 
	    lappend newlst $v
	}
    }
    set newlst [ lsort -integer -increasing -unique $newlst  ]
    $OptionsArray(list) SetValue $newlst

    set idlist [ vtkIdList New]
    for { set i 0 } { $i < [ llength $newlst ] } { incr i } {
	$idlist InsertNextId [ lindex $newlst $i ]
    }

    set outimage [ $this GetOutput ]
    
    set id [ vtkpxImageIDFilter New]
    $id SetInput [ [ $this GetInput ] GetImage ]
    $id SetIdList $idlist
    $id SetInValue  $invalue
    $id SetOutValue $outvalue
    $id SetOutputScalarType [ [ [ $this GetInput ] GetImage ] GetScalarType ]
    $id Update
 
    if { $binarymask == 1 } {
	$outimage ShallowCopyImage [ $id GetOutput ]
    } else {
	set sh  [ vtkImageMathematics New  ]
	$sh SetInput1 [ [ $this GetInput ] GetImage ]
	$sh SetInput2 [ $id GetOutput ]
	$sh SetOperationToMultiply
	$sh Update
	
	$outimage ShallowCopyImage [ $sh GetOutput ]
	$sh Delete
    }
    
    $id Delete
    $idlist Delete
    $outimage CopyImageHeader [ [ $this GetInput ] GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0
    

}

# --------------------------------------------------------------------------------------------




# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_listthresholdimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {

    set alg [bis_listthresholdimage [pxvtable::vnewobj]]
    $alg MainFunction 

}





