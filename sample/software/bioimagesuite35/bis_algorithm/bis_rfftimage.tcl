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
package require bis_cropimage 1.0

package provide bis_rfftimage 1.0

#
# inverse fourier transform image
#

itcl::class bis_rfftimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Inv Fourier Xform" }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_rfftimage::Initialize { } {

    PrintDebug "bis_rfftimage::Initialize" 
    #name,description,type,object,filename(if applicable),priority (optional)
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ dimension "dimension of fourier transform operation. The default value is 3. " "Dimension"  { listofvalues radiobuttons }   3 { 2 3 }  0 }
	{ fftoperation "if true, the algorithm will look for the zeroth frequency at the center of the image" "operations"  { boolean checkbutton } 0 { 0 1 } 1 }
	{ magnitude "if true, the algorithm will compute the magnitude of the final image" "Magnitude"  { boolean checkbutton } 0 { 0 1 } 2 }
    }

    set defaultsuffix { "_rfft"}
    
    set scriptname bis_rfftimage
    set completionstatus "Done, needs checking"


    set description "computes inverse fourier transform."
    set description2 "take in a transformed image or a shifted transform image"
    set backwardcompatibility "N/A."
    set authors "hirohito.okuda@yale.edu."

    $this InitializeImageToImageAlgorithm

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_rfftimage::Execute {  } {

    PrintDebug "bis_rfftimage::Execute"

    set dimension   [ $OptionsArray(dimension) GetValue ]
    set image_in    [ $InputsArray(input_image) GetObject ]

    set rfft [vtkImageRFFT [pxvtable::vnewobj]]
    $rfft SetInput [ $image_in GetObject ]
    $rfft SetDimensionality $dimension
    $this SetFilterCallbacks $rfft "RFFT Transforming Image"
    $rfft Update

    set mag [ vtkImageMagnitude [ pxvtable::vnewobj ] ]
    if { [ $OptionsArray(magnitude) GetValue  ] > 0 } {
	#keep only the magnitude
	$mag SetInput [ $rfft GetOutput ]
	$mag Update
	set image_out [ $mag GetOutput ]
    } else {
 	set image_out [ $rfft GetOutput ]
    }

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage $image_out 

    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format "BIS::bis_rfftimage.tcl"  ] 

    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $mag Delete
    $rfft Delete
    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_rfftimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_rfftimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

