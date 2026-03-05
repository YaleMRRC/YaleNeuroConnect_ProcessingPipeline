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
package provide bis_reorientimage 1.0

#
# reorient image
#

itcl::class bis_reorientimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Reorient Image" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_reorientimage::Initialize { } {

    PrintDebug "bis_reorientimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ orientation "orientation of image axial,coronal,sagittal" "Orientation"  { listofvalues radiobuttons }  axial { axial coronal sagittal }  0 }
    }

    set defaultsuffix { "" }
    
    set scriptname bis_reorientimage
    set completionstatus "Done -- needs testing"
    #
    #document
    #
    
    set description "reorients an image to a given orientation."
    set description2 " Output orientation is 0=axial, 1=coronal, or 2=sagittal. The input orientation is detected automatically."
    set backwardcompatibility "Reimplemented from pxmat_reorientimage.tcl"
    

    $this InitializeImageToImageAlgorithm

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_reorientimage::Execute {  } {

    PrintDebug "bis_reorientimage::Execute"

    set out   [ $OptionsArray(orientation) GetValue ]
    set image_in          [ $InputsArray(input_image) GetObject ]
    set orientation_in    [ $image_in GetOrientation ]


    if { $out == "coronal" } {
	set orientation_out 1
    } elseif { $out == "sagittal" } {
	set orientation_out 2
    } else {
	set orientation_out 0
    }


    puts stderr "\n\n\n Reorienting $orientation_in --> $orientation_out "

    #vtk object
    set vtk_image_in [ $image_in GetObject ]
    set header [ $image_in GetImageHeader ]
    set outimage [ $OutputsArray(output_image) GetObject ]

    if { $orientation_in != $orientation_out } {
	set image_out [ vtkImageData [ pxvtable::vnewobj ]]
	set ut [ vtkpxUtil [ pxvtable::vnewobj ]]
	$ut ReOrientImage $image_out $vtk_image_in $orientation_in  $orientation_out

	if { $orientation_out==0 } {
	    $header  SetOrientation 10
	} elseif { $orientation_out==1 } {
	    $header  SetOrientation 20
	} elseif { $orientation_out==2 } {
	    $header  SetOrientation 30
	} else {
	    $header  SetOrientation $orientation_out
	}
	# Output orientation etc. is same as input
	$outimage CopyImageHeader $header
	$outimage ShallowCopyImage $image_out 
	set comment [ format "BIS::bis_reorientimage.tcl to $out"  ] 
	[ $outimage GetImageHeader ] AddComment "$comment $Log" 0
	$image_out Delete
	$ut Delete

    } else {
	# Nothing to do
	$outimage CopyImageHeader $header
	$outimage ShallowCopyImage $vtk_image_in 

    }

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_reorientimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_reorientimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

