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

package provide bis_castimage 1.0

#
# cast image
#

itcl::class bis_castimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Cast Image" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_castimage::Initialize { } {

    PrintDebug "bis_castimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ type "output image type.Specify one of  Float , Double or Short" "Type"  listofvalues  Float { Float Double UnsignedChar Short }  0 }
    }

    set defaultsuffix { "_cast" }
    
    set scriptname bis_castimage

    set completionstatus "Done Needs testing, perhaps add more types"


    set description "cast (or convert) image data type."
    set description2 "type can be one of float, double, or short"
    set backwardcompatibility "N/A."
    set authors "hirohito.okuda@yale.edu"

    $this InitializeImageToImageAlgorithm

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_castimage::Execute {  } {

    PrintDebug "bis_castimage::Execute starts.."

    set type   [ $OptionsArray(type) GetValue ]

    set image_in    [ $InputsArray(input_image) GetObject ]

    #vtkImageCast
    set cast [vtkImageCast [pxvtable::vnewobj]]
    $cast SetInput [$image_in GetObject]
    switch $type {
	Float { 
	    $cast SetOutputScalarTypeToFloat
	}
	Double { 
	    $cast SetOutputScalarTypeToDouble
	}
	Short { 
	    $cast SetClampOverflow 32767
	    $cast SetOutputScalarTypeToShort
	}
	UnsignedChar {
	    $cast SetClampOverflow 255
	    $cast SetOutputScalarTypeToUnsignedChar
	}
	default {
	    $cast SetOutputScalarTypeToFloat
	}
    }
    $this SetFilterCallbacks $cast "Casting Image"
    $cast Update
    set image_out [ $cast GetOutput ]

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage  $image_out

    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]

    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0


    $cast Delete
    PrintDebug "bis_castimage::Execute ends.."
    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_castimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main functionsSaveOb

    

    set alg [bis_castimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

