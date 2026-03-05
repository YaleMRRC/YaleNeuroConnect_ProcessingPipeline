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

package provide bis_flipimage 1.0

#
# flip image
#

itcl::class bis_flipimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Flip Image" }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_flipimage::Initialize { } {

    PrintDebug "bis_flipimage::Initialize" 

    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ direction "flip direction X,Y,Z" "Direction To Flip"  { listofvalues radiobuttons } Z { X Y Z }  0 }
    }

    set defaultsuffix { "_flip" }
    
    set scriptname bis_flipimage
    set completionstatus "Done  --  needs testing, perhaps add transpose, flip transpose options"

    set description "flips image about one of the coordinate axes."
    set description2 ""
    set backwardcompatibility "Reimplemented from pxmat_flip.tcl. Multiple image processing eliminated,which will be recovered upon request. "
    

    $this InitializeImageToImageAlgorithm

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_flipimage::Execute {  } {

    PrintDebug "bis_flipimage::Execute"

    set direction   [ $OptionsArray(direction) GetValue ]
    set image_in    [ $InputsArray(input_image) GetObject ]
    set flip [ vtkImageFlip [ pxvtable::vnewobj ]]

    if { $direction == "X" } {
	$flip SetFilteredAxis 0
    } elseif { $direction == "Y" } {
	$flip SetFilteredAxis 1
    } else {
	$flip SetFilteredAxis 2
    }
    $flip SetInput [ $image_in GetObject ]
    $flip PreserveImageExtentOn
    $this SetFilterCallbacks $flip "Flipping Image"
    $flip Update

    set image_out [ $flip GetOutput ]

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage $image_out 

    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format "BIS::bis_flipimage.tcl "  ] 

    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0


    $flip Delete
    return 1
}



# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_flipimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_flipimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

