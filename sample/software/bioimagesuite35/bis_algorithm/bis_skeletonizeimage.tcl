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

package provide bis_skeletonizeimage 1.0
package require bis_imagetoimagealgorithm 1.0
package require bis_distancemapimage 1.0


itcl::class bis_skeletonizeimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Skeletonize Image" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_skeletonizeimage::Initialize { } {

    PrintDebug "bis_skeletonizeimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
 	{ dodistance     "Compute Distance Map as Output"  "Do Distance Map"    boolean  0 { 0 1}        4 }
    }

    set defaultsuffix { "_skel" }
    
    set scriptname bis_skeletonizeimage
    set completionstatus "Done"

    #
    #document
    #
    
    set description "Create a skeleton and/or a distance map from a binarized image. if dodistance is 1 multiples by inverse distance map"
    set description2 "Skeletonization code comes from Homann H., ``Implementation of a 3D thinning algorithm''. Oxford University, Wolfson Medical Vision Lab. Insight Journal Dec 2007"
    set backwardcompatibility "None"

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_skeletonizeimage::Execute {  } {

    PrintDebug "bis_skeletonizeimage::Execute"
    set dodistance   [ $OptionsArray(dodistance) GetValue ]
    set image_in [ $this GetInput ]

    set outimage [ $OutputsArray(output_image) GetObject ]

    set skeletonize  [ vtkbisBinaryThinningFilter New ]
    $skeletonize SetInput [ $image_in GetImage ]
    $this SetFilterCallbacks $skeletonize "Skeletonizing Image"
    $skeletonize Update

    if { $dodistance > 0 } {
	set dist_alg [bis_distancemapimage [pxvtable::vnewobj]]
	$dist_alg InitializeFromContainer $this
	$dist_alg SetInput $image_in
	$dist_alg SetOptionValue minth -1.0
	$dist_alg SetOptionValue maxth  0.5
	$dist_alg SetOptionValue radius 1
	$dist_alg Execute

	set cst [ vtkImageCast New ]
	$cst SetInput [ [ $dist_alg GetOutput ] GetImage ] 
	$cst SetOutputScalarType [ [ $skeletonize GetOutput ] GetScalarType ]
	$cst Update

	puts stdout "Computing Distance map"
	set mth [ vtkImageMathematics New ]
	$mth SetInput1 [ $skeletonize GetOutput ]
	$mth SetInput2 [ $cst GetOutput ]
	$mth SetOperationToMultiply
	$this SetFilterCallbacks $mth "Multiplying Distance map with Skeleton Image"
	$mth Update
	
	$outimage ShallowCopyImage [ $mth GetOutput ]
	$mth Delete
	$cst Delete
	itcl::delete obj $dist_alg
    } else {
	$outimage ShallowCopyImage [ $skeletonize GetOutput ]
    }

    $outimage CopyImageHeader [ $image_in GetImageHeader ]
    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $skeletonize Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_skeletonizeimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_skeletonizeimage [pxvtable::vnewobj]]
    $alg MainFunction 
}





