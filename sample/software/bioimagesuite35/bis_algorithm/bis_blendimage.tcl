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

package require bis_dualimagereslicetransformationalgorithm 1.0
package provide bis_blendimage 1.0

#
# blend image
#

itcl::class bis_blendimage {

    inherit bis_dualimagereslicetransformationalgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Image Blend"}

    protected method ConfigureOptionsGUICallbacks { } 
    public    method AutoBlend { args } 

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_blendimage::Initialize { } {

    PrintDebug "bis_blendimage::Initialize" 

    set options {
	{ interp      "Interpolation Mode that is used when reslicing the image" "Interpolation Mode"  listofvalues Linear { "NearestNeighbor" "Linear" "Cubic" }  -10 }
	{ background  "Background Level used to fill voxels outside of mapped area" "Background Value"  real 0.0 { -100000 100000 }  -100 }
	{ blend       "Weight (between 0 and 100) of target image" "Blend"  { real scale } 50.0 { 0.0 100.0 }  1 }
	{ guiautoupdate  "Auto Update on changing scale values" "Auto-update"  { boolean } 0 { 0 1 }  2 }
	{ scale      "Image 1: Scale" "Scale Image 1"   real    1.0 { 0.0 10000.0 }  3 }
    }

    set defaultsuffix { "_blend" }
    
    set scriptname bis_blendimage
    set completionstatus "Done"
    #
    #document
    #

    set category "Image Processing Dual"
    set description "blends an image using one or more transformations."
    set description2 "a useful check of the quality of the transformations"
    set backwardcompatibility "Reimplemented from pxmat_blendimage.tcl."
    set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu."

    $this InitializeDualImageTransformationAlgorithm
    $this SetUseReslicedImageAsInput 1
}

# -----------------------------------------------------------------------------------------
itcl::body bis_blendimage::ConfigureOptionsGUICallbacks { } {

    eval "$OptionsArray(blend) SetGUICallbackFunction { $this AutoBlend }"
}

itcl::body bis_blendimage::AutoBlend {  args } {

    if { [ $OptionsArray(guiautoupdate) GetValue ] ==0 } {
	return
    }

    $OptionsArray(blend) SetGUICallbackFunction ""
    $this InvokeAlgorithmFromGUI 
    $this ConfigureOptionsGUICallbacks
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_blendimage::Execute {  } {

    PrintDebug "bis_blendimage::Execute"

    set lst [ $this ResliceImageIfNeeded ]
    set reslimage [ lindex $lst 0 ]

    set dt [ $reslimage  GetScalarType ]
    set num [ $reslimage  GetNumberOfScalarComponents ]
    set num2 [ [ [ $this GetInput ] GetImage ] GetNumberOfScalarComponents ]



    set blendCreator [ vtkImageBlend [ pxvtable::vnewobj ]]    

    # VTK_UNSIGNED_CHAR == 3
    if { $dt == 3 &&  $num == 3 && $num2 ==1 } {
#	puts stdout "Need 3 color image"
	set img [ vtkImageData New ]
	$img CopyStructure  [ [ $this GetInput ] GetImage ]
	$img SetNumberOfScalarComponents 3
	$img SetScalarType  [ [ [ $this GetInput ] GetImage ] GetScalarType ]
	$img AllocateScalars
	for { set i 0 } { $i <=2 } { incr i } {
	    [ [ $img GetPointData ] GetScalars ] CopyComponent $i [ [ [ [ $this GetInput ] GetImage ] GetPointData ] GetScalars ] 0 
	}

	set imcast2 [ vtkImageShiftScale [ pxvtable::vnewobj ]]
	$imcast2 SetInput $img
	$img Delete
	
	#	puts stdout "Appending to create color image"
	$imcast2 SetShift 0.0
	$imcast2 SetScale  [ $OptionsArray(scale) GetValue ]
	$imcast2 ClampOverflowOn
	$imcast2 SetOutputScalarType $dt
#	puts stdout "Scale  = [ $imcast2 GetScale ] dt=$dt"
	$imcast2 Update
#	puts stdout "Input1 [ [ $imcast2 GetOutput ] GetDimensions ], [ [ $imcast2 GetOutput ] GetScalarRange ]"
	$blendCreator AddInput [ $imcast2 GetOutput ]
	$blendCreator AddInput $reslimage 
	$imcast2 Delete 
    } else {
	#	puts stdout "Just casting"
	set imcast2 [ vtkImageCast [ pxvtable::vnewobj ]]
	$imcast2 SetInput $reslimage
	$imcast2 SetOutputScalarType [ [ [ $this GetInput ] GetImage ] GetScalarType ]
	$imcast2 Update
	$blendCreator AddInput [ [ $this GetInput ] GetImage ]
	$blendCreator AddInput [ $imcast2 GetOutput ]
	$imcast2 Delete 
    }

    set bl [ expr [ $OptionsArray(blend) GetValue ] /100.0 ]


    $blendCreator SetOpacity 1 $bl
    SetFilterCallbacks $blendCreator "Blending Images"
    $blendCreator Update
    
    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage [ $blendCreator GetOutput ]

    # Output orientation etc. is same as input
    set outimage [ $this GetOutput ] 
    set pimage   [ $this GetSecondInput ] 

    $outimage CopyImageHeader [ $pimage GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0


    $blendCreator Delete

    $this DeleteResliceAlgorithmIfNeeded $lst 
    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_blendimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

   

    set alg [bis_blendimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

