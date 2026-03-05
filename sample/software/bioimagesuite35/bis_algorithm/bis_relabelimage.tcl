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

package provide bis_relabelimage 1.0

#
# relabel image
#

itcl::class bis_relabelimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }

    public method GetGUIName    { } { return "Relabel Header" }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_relabelimage::Initialize { } {

    PrintDebug "bis_relabelimage::Initialize" 
    #name,description,type,object,filename(if applicable),priority (optional)
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ orientation "orientation of image axial,coronal,sagittal" "Orientation"  { listofvalues radiobuttons }  axial { axial coronal sagittal }  0 }
    }

    set defaultsuffix { "" }
    
    set scriptname bis_relabelimage
    set completionstatus "Done -- needs testing"

    #
    #document
    #
    
    set description "relabels an image to a given orientation. Output orientation is 0=axial, 1=coronal, or 2=sagittal."
    set description2 ""
    set backwardcompatibility "Reimplemented from pxmat_relabelimage.tcl"
    

    $this InitializeImageToImageAlgorithm

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_relabelimage::Execute {  } {

    PrintDebug "bis_relabelimage::Execute"

    set orientation_out   [ $OptionsArray(orientation) GetValue ]
    set image_in          [ $InputsArray(input_image) GetObject ]

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage [$image_in GetObject ]

    set header [ $image_in GetImageHeader ]

    if { $orientation_out == "coronal" } {
	$header  SetOrientation 20
    } elseif { $orientation_out == "sagittal" } {
	$header  SetOrientation 30
    } else {
	$header  SetOrientation 10
    }

    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader $header
    set comment [ format "BIS::bis_relabelimage.tcl"  ] 
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0


    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_relabelimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_relabelimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

