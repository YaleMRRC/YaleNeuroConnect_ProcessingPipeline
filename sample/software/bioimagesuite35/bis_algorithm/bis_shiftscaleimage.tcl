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
package require bis_castimage 1.0

package provide bis_shiftscaleimage 1.0

#
# shift sccale image
#

itcl::class bis_shiftscaleimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Shift/Scale Image" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_shiftscaleimage::Initialize { } {

    PrintDebug "bis_shiftscaleimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ shift "Shift factor" "Shift"  float  0.0 { -100000000.0 100000000.0 }  0 }
	{ scale "Scale factor " "Scale" float  1.0 { -100000000.0 100000000.0 }  1 }
	{ abs "Do Absolute Value First" "Do Absolute Value"  { boolean checkbutton } 0 { 0 1 }  -2 }
	{ type "output image type.Specify one of  Same (same as input), Float , Double or Short" "Ouput Image Type"  listofvalues  Same { Same Short Float Double }  2 }
    }

    set defaultsuffix { "_ss" }
    
    set scriptname bis_shiftscaleimage
    set completionstatus "Done, needs checking"


    set description  "computes linear intensity transformation"
    set description2 "Output intensity = scale *(Input intensity + shift).Data is thresholded so that the outpu value does not exceed the max or min of the data type."
    set backwardcompatibility "N/A."

    $this InitializeImageToImageAlgorithm

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_shiftscaleimage::Execute {  } {

    PrintDebug "bis_shiftscaleimage::Execute"

    set scale   [ $OptionsArray(scale) GetValue ]
    set shift   [ $OptionsArray(shift) GetValue ]
    set type    [ $OptionsArray(type)  GetValue ]
    set abs    [ $OptionsArray(abs)  GetValue ]

    set image_in [ $InputsArray(input_image) GetObject ]


    #vtkImageShiftScale
    set ft [vtkImageShiftScale [pxvtable::vnewobj]]
    
    if { $abs > 0 } {
	set math [ vtkImageMathematics New ]
	$math SetInput [ $image_in GetObject ]
	$math SetOperationToAbsoluteValue
	$math Update
	$ft SetInput [ $math GetOutput ]
	$math Delete
    } else {
	$ft SetInput [ $image_in GetObject ]
	$ft SetShift $shift
	$ft SetScale $scale
    }
	
    switch $type {
	Float { 
	    $ft SetOutputScalarTypeToFloat
	}
	Double { 
	    $ft SetOutputScalarTypeToDouble
	}
	Short { 
	    $ft SetOutputScalarTypeToShort
	}
	Same {
	}
    }
    $ft ClampOverflowOn
    $this SetFilterCallbacks $ft "Shift and Scaling Image"
    $ft Update
    set image_out [ $ft GetOutput ]

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage $image_out 

    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]

    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0


    $ft Delete
    return 1
}



# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_shiftscaleimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_shiftscaleimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

