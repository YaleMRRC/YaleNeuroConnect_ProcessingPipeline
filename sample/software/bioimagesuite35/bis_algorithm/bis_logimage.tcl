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

package provide bis_logimage 1.0

#
# shift sccale image
#

itcl::class bis_logimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Log Image" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_logimage::Initialize { } {

    PrintDebug "bis_logimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ scale "Scale Output to be 0:255" "Scale 256" boolean 0 { 0 1 } 1 }
    }

    set defaultsuffix { "_log" }
    
    set scriptname bis_logimage
    set completionstatus "Done, needs checking"


    set description  "computes linear intensity transformation"
    set description2 "Output intensity = scale *(Input intensity + shift).Data is thresholded so that the outpu value does not exceed the max or min of the data type."
    set backwardcompatibility "N/A."

    $this InitializeImageToImageAlgorithm

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_logimage::Execute {  } {

    PrintDebug "bis_logimage::Execute"

    set scalef   [ $OptionsArray(scale) GetValue ]
    set image_in [ $InputsArray(input_image) GetObject ]

    set range [ [ [ [ $image_in GetImage ] GetPointData] GetScalars] GetRange ]
    set low  [ lindex $range 0 ]

    #   pxtkprint "\nBeginning logarithm range = $range "

    set sh  [ vtkImageShiftScale [ pxvtable::vnewobj ]  ]
    $sh SetInput [ $image_in GetImage ]
    $sh SetShift [ expr -$low+1.0 ]
    $sh SetScale 1.0
    $sh SetOutputScalarTypeToFloat
    SetFilterCallbacks $sh "Scaling Intensities of image pass 1"
    $sh Update
    
    #puts stdout "After Scale 1 range [ [ [ [ $sh GetOutput ] GetPointData ] GetScalars ] GetRange ]\n"

    set mt  [ vtkImageMathematics [ pxvtable::vnewobj ]  ]
    $mt SetInput1 [ $sh GetOutput ]
    $mt SetOperationToLog
    SetFilterCallbacks $mt "Performing logarithm"
    $mt Update

    if { $scalef > 0 } {
	set maxv 255.0
	set r [  [ [  [ $mt GetOutput ] GetPointData ] GetScalars ] GetRange ]
	set scale [ expr $maxv/ [ lindex $r 1 ] ]
    } else {
	set scale 1.0
    }

    # puts stdout "After log 1 range [ [ [ [ $mt GetOutput ] GetPointData ] GetScalars ] GetRange ] scale=$scale\n"


    set sh2  [ vtkImageShiftScale [ pxvtable::vnewobj ]  ]
    $sh2 SetInput [ $mt GetOutput ]
    $sh2 SetShift 0.0
    $sh2 SetScale $scale 
    if { $scale > 1.0 } {
	$sh2 SetOutputScalarType [ [ $image_in GetImage ] GetScalarType ]
    } 
	
    SetFilterCallbacks $sh2 "Scaling Intensities of image pass 2"
    
    $sh2 Update
    puts stdout "Log: Output range [ [ [ [ $sh2 GetOutput ] GetPointData ] GetScalars ] GetRange ]"

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage [ $sh2 GetOutput ]
    

    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]

    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0


    $sh2 Delete 
    $sh Delete 
    $mt Delete 

    return 1
}



# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_logimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_logimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

