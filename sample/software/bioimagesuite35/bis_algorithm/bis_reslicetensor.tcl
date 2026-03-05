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

package require bis_dualimagetransformationalgorithm 1.0
package provide bis_reslicetensor 1.0

#
# reslice image
#

itcl::class bis_reslicetensor {

    inherit bis_dualimagetransformationalgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }

    # Fix caching issues
    public method SetTransformation { tr }
    public method UpdateInputsFromContainer { } 

    public method GetGUIName { } { return "Tensor Reslice"}
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_reslicetensor::Initialize { } {

    PrintDebug "bis_reslicetensor::Initialize" 
    #name,description,type,object,filename(if applicable),priority (optional)
    set inputs {
	{ xform2   "Transformation 2"    pxitcltransform  "" 300 }
	{ xform3   "Transformation 3"    pxitcltransform  "" 400 }
    }
    
    #od descriptions of xfrom2, xform3
    #Transformation 2: (e.g. 3D->Conventional Transform)
    #Transformation 3: (e.g. Conventional->Echoplanar Transform)

    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ interp    "Interpolation Mode that is used when reslicing the image" "Interpolation Mode"  listofvalues Linear { "NearestNeighbor" "Linear" "Cubic" }  0 }
	{ background  "Background Level used to fill voxels outside of mapped area" "Background Value"  real 0.0 { -100000 100000 }  -100 }
	
    }

    lappend options [ list flipx   "Flip the x-direction of the images" "Flip-X" boolean 0  { 0 1 } -30 ]
    lappend options [ list flipy   "Flip the y-direction of the images" "Flip-Y" boolean 0  { 0 1 } -31 ]
    lappend options [ list flipz   "Flip the z-direction of the images" "Flip-Z" boolean 0  { 0 1 } -32 ]
    lappend options [ list quick   "If one use 6 neighboring voxels to estimate the local rotation, else use 26 neighbors" "QuickMode" boolean 1  { 0 1 } 2 ]
	

    set defaultsuffix { "_reslt" }
    
    set scriptname bis_reslicetensor
    set completionstatus "Done"
    #
    #document
    #

    set category "Diffusion Tensor"
    set description "Reslices an tensor/vector image using one or more transformations."
    set description2 "This modifies the tensor with a local rigid transformation estimated at each voxel"
    set backwardcompatibility "Reimplemented from pxmat_reslicetensor.tcl."
    set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu."

    $this InitializeDualImageTransformationAlgorithm

    $this RenameInput 0 "Reference Image"
    $this RenameInput 1 "Tensor or Vector Image"
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_reslicetensor::Execute {  } {

    PrintDebug "bis_reslicetensor::Execute"

    set mode       [ $OptionsArray(interp) GetValue ]
    set interp 1
    switch -exact $mode {
	"NearestNeighbor" { set interp 0 }  
	"Cubic" { set interp 3 }
    }

    #vtkobject
    set image_ref    [ [ $this GetInput ] GetObject ]
    set image_trg    [ [ $this GetSecondInput ]  GetObject ]
    set xform1       [ [ $this GetTransformation ]  GetObject ]

    set xform2 0
    set xform3 0
    if { [ $InputsArray(xform2) IsFileNameTheDefault ] != 1 } { 
	set xform2  [[ $InputsArray(xform2)    GetObject ] GetObject ] 
    }

    if { [ $InputsArray(xform3) IsFileNameTheDefault ] != 1 } { 
	set xform3  [[ $InputsArray(xform3)    GetObject ] GetObject ] 
    }

    set trans [ vtkGeneralTransform [ pxvtable::vnewobj ]]
    $trans Identity
    $trans PostMultiply
    $trans Concatenate $xform1
    if { $xform2 !=0 } {
	$trans Concatenate $xform2
    }
    if { $xform3 !=0 } {
	$trans Concatenate $xform3
    }

    set resl [ vtkbisImageReslice [ pxvtable::vnewobj ]]
    $resl SetInput             $image_trg
    $resl SetInformationInput  $image_ref
    $resl SetInterpolationMode $interp
    $resl SetBackgroundLevel   [ $OptionsArray(background) GetValue ]
    $resl OptimizationOff
    $resl SetResliceTransform $trans
    $this SetFilterCallbacks $resl "Reslicing Image"
    $resl Update
    
    set reor [  vtkpxImageReorientTensorOrVector [ pxvtable::vnewobj ]]
    $reor SetInput [ $resl GetOutput ]
    $reor SetTransformation $trans
    if { [ $OptionsArray(flipx) GetValue ] > 0 } { $reor FlipXOn }
    if { [ $OptionsArray(flipy) GetValue ] > 0 } { $reor FlipYOn }
    if { [ $OptionsArray(flipz) GetValue ] > 0 } { $reor FlipZOn }
    if { [ $OptionsArray(quick) GetValue ] > 0 } { $reor  Use7PointsOn }
    $this SetFilterCallbacks $resl "Reorienting Vector/Tensor"
    $reor Update

    set image_out [$reor GetOutput ]
    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage $image_out 

    # Output orientation etc. is same as input
    set outimage [ $this GetOutput ] 
    set pimage   [ $this GetSecondInput ] 
    $outimage CopyImageHeader [ $pimage GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment" 0

    $trans Delete
    $resl Delete
    $reor Delete

    return 1
}


itcl::body bis_reslicetensor::SetTransformation { tr } {

    set ok [ bis_dualimagetransformationalgorithm::SetTransformation $tr ]
    # puts stdout "Image Reslice Clearing Output"
    [ $this GetOutput ]  CreateNewImage
    return $ok
}

itcl::body bis_reslicetensor::UpdateInputsFromContainer { } {
    set ok [ bis_dualimagetransformationalgorithm::UpdateInputsFromContainer ]

    # clear output
    # puts stdout "Image Reslice Clearing Output"
    [ $this GetOutput ]  CreateNewImage
    return $ok

}
# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_reslicetensor.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_reslicetensor [pxvtable::vnewobj]]
    $alg MainFunction 
}

