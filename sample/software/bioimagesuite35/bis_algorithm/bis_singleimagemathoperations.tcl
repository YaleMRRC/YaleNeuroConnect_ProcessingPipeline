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
package require bis_resliceimage 1.0
package provide bis_singleimagemathoperations 1.0

#
# blend image
#

itcl::class bis_singleimagemathoperations {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Math Operations"}

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_singleimagemathoperations::Initialize { } {

    PrintDebug "bis_singleimagemathoperations::Initialize" 

    set options {
	{ mathoperation "Pick math operation" "Pick math operation"  listofvalues Invert { "Invert" "Absolute" "Exp" "Log" "Sin" "Cos" }  1 }
    }
	
	# { guiautoupdate  "Auto Update on changing scale values" "Auto-update"  { boolean } 0 { 0 1 }  2 }

    set defaultsuffix { "_singlemathop" }
    
    set scriptname bis_singleimagemathoperations
    set completionstatus "Done"
    #
    #document
    #

    set category "Image Processing Dual"
    set description "Image to Image algorithm that does more complex operations than bis_imagemathoperations"
    set description2 "Invert, Exp, Log, Sin, Cos of an image to give an output."
    set backwardcompatibility " "
    set authors "alark.joshi@yale.edu, xenophon.papademetris@yale.edu."

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_singleimagemathoperations::Execute {  } {

    PrintDebug "bis_singleimagemathoperations::Execute"


    set mathOpsResult [ vtkImageMathematics [  pxvtable::vnewobj ] ]
    set mathop        [ $OptionsArray(mathoperation) GetValue ]
    set image_in      [ $this GetInput ]
    
    if { $mathop == "Invert" } {
	$mathOpsResult SetOperationToInvert
    } elseif { $mathop == "Absolute" } {
	$mathOpsResult SetOperationToAbsoluteValue
    } elseif { $mathop == "Exp" } {
	$mathOpsResult SetOperationToExp
    } elseif { $mathop == "Log" } { 
	$mathOpsResult SetOperationToLog
    } elseif { $mathop == "Sin" } {
	$mathOpsResult SetOperationToSin
    } elseif { $mathop == "Cos" } {
	$mathOpsResult SetOperationToCos
    }
    
    $mathOpsResult SetInput1  [ $image_in GetImage ]
    $mathOpsResult Update

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage [ $mathOpsResult GetOutput ]

    # Output orientation etc. is same as input
    set outimage [ $this GetOutput ] 
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
   
    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $mathOpsResult Delete

    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_singleimagemathoperations.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function
 

    set alg [bis_singleimagemathoperations [pxvtable::vnewobj]]
    $alg MainFunction 
}

