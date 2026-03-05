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

package require bis_dualimagetransformationalgorithm 1.0
package provide bis_computedisplacementfield 1.0

#
# computedisplacementfield
#

itcl::class bis_computedisplacementfield {

    inherit bis_dualimagetransformationalgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Compute Displacement Field" }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_computedisplacementfield::Initialize { } {


    set defaultsuffix "dispfield"

    set inputs {
	{ xform2   "Transformation 2"    pxitcltransform  "" 100 }
	{ xform3   "Transformation 3"    pxitcltransform  "" 101 }
    }

    set options {
	{ guicmt     "Description of the filter"  "Note"  comment "Compute a displacement field given transformations" "Compute disp field"  400 }
    }
    set scriptname bis_computedisplacementfield

    #
    #document
    #
    set category "Registration"
    set description  "computes the displacement field for a transformation given an image to define the space."
    set description2 ""
    set backwardcompatibility "Reimplemented from pxmat_displacementfield.tcl"
    set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu."

    $this InitializeDualImageTransformationAlgorithm

    $this RenameInput 1 "Unused Second Image" 200
    $this RenameInput 2 "Transformation 1" 10
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_computedisplacementfield::Execute {  } {


    PrintDebug "bis_computedisplacementfield::Execute"

    set ref_image    [ $InputsArray(input_image) GetObject ] 

    set trans [ vtkGeneralTransform [ pxvtable::vnewobj ]]
    $trans Identity
    $trans PostMultiply
    $trans Concatenate [ [ $this GetInputObject transformation ] GetTransformation ]
    $trans Concatenate [ [ $this GetInputObject xform2 ] GetTransformation ]
    $trans Concatenate [ [ $this GetInputObject xform3 ] GetTransformation ]



    set dim [[ $ref_image GetObject ] GetDimensions ]
    set spa [[ $ref_image GetObject ] GetSpacing ]

    set tgrid [ vtkTransformToGrid [ pxvtable::vnewobj ]]
    $tgrid SetGridExtent 0 [ expr [ lindex $dim  0 ] -1 ] 0 [ expr [ lindex $dim  1 ] -1 ] 0 [ expr [ lindex $dim  2 ] -1 ]
    $tgrid SetGridOrigin  0 0 0
    $tgrid SetGridSpacing [ lindex $spa 0 ] [ lindex $spa 1 ] [ lindex $spa 2 ] 
    $tgrid SetInput $trans
    $tgrid Update

    set image_out [ $tgrid GetOutput ]

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage $image_out 

    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $ref_image GetImageHeader ]

    [ $outimage GetImageHeader ] AddComment [ $this GetCommandLine full ] 

    $tgrid Delete
    $trans Delete
    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_displacementfield.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

#    DebugOn

    set alg [bis_computedisplacementfield [pxvtable::vnewobj]]
    $alg MainFunction 
}

