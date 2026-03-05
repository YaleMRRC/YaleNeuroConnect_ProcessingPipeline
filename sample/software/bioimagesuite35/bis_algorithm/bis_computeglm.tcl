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

package provide bis_computeglm 1.0
package require bis_dualimagealgorithm 1.0


itcl::class bis_computeglm {

    inherit bis_imagetoimagealgorithm

    constructor { } {	 $this Initialize  }
    
    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Compute GLM Regression" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_computeglm::Initialize { } {

    PrintDebug "bis_computeglm::Initialize" 
    
	#commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ matrix "GLM matrix file name, either in Matlab .mat format or BioImage Suite .matr format" "GLM Matrix File:" { filename default } "" { MAT-File  { .mat,.matr } } 1 }
	{ matrixname "Name of Matrix in matlab file e.g. Q_set ..." "Matrix Name" string "" { } 2 }
	{ residual "Generate residual image" "Generate Residual Image" boolean 0 { 0 1 } 3 }
    }

    set outputs { 
	{ resimage "Residual Image" pxitclimage  ""  120 }   
    }



    set defaultsuffix { "_glm" }
    set scriptname bis_computeglm
    set completionstatus "Needs testing!"

    #
    #document
    #
    
    set description "Compute GLM Fit using Matrix to define regressors. Optionally save the residual image."
    set description2 ""
    set backwardcompatibility ""
    set authors "xenophon.papademetris@yale.edu"
    set category "Functional Imaging"

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_computeglm::Execute {  } {

    PrintDebug "bis_computeglm::Execute"


    set matrixfname   [ $OptionsArray(matrix) GetValue ]
    set mname         [ $OptionsArray(matrixname) GetValue ]
    set image_in      [ $this GetInput ]
    set res         [ $OptionsArray(residual) GetValue ]
	
    set matrix [ vtkpxMatrix New ]
    set ok [ $matrix Load $matrixfname ]
    if { $ok == 0 } {
	set ok [  $matrix ImportFromMatlab $matrixfname $mname ]
	if { $ok == 0 } {
	    $matrix Delete
	    set errormessage "Failed to read matrix from $matrixfname (name=$mname)"
	    return 0
	}
    }
	
    set numrows [ lindex [ $matrix GetSize ] 0 ]
    puts stdout "Matrix = [ $matrix GetSize ], comp = [ [ $image_in GetImage ] GetNumberOfScalarComponents ] "
    if { $numrows != [ [ $image_in GetImage ] GetNumberOfScalarComponents ] } {
	set errormessage "Matrix size (rows) is not equal to number of frames in input image"
	$matrix Delete
	return 0
    }

    set glm [ vtkbisComputeGLM  [ pxvtable::vnewobj ]]
    set outimg [ $glm ComputeSimpleGLM [ $image_in GetImage ]  $matrix ]
    $glm Delete

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage $outimg
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0


    if { $res > 0 } {
	set glm [ vtkbisComputeGLM  [ pxvtable::vnewobj ]]
	set outimg2 [ $glm MatrixImageMultiply $outimg  $matrix ]
	$glm Delete

	set cast [ vtkImageCast New ]
	$cast SetInput [ $image_in GetImage ]
	$cast SetOutputScalarType [ $outimg2 GetScalarType ]
	$cast Update

	set math [ vtkImageMathematics New ]
	$math SetInput1 [ $cast GetOutput ]
	$math SetInput2 $outimg2
	$math SetOperationToSubtract
	$math Update

	set second [ $this GetOutputObject resimage ]
	$second CopyImageHeader [ $image_in GetImageHeader ]
	$second ShallowCopyImage [ $math GetOutput ]
	$math Delete
	$cast Delete
	$outimg2 Delete
    }

    $matrix Delete
    $outimg Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_computeglm.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
	# this is essentially the main function

	set alg [bis_computeglm [pxvtable::vnewobj]]
	$alg MainFunction 
}





