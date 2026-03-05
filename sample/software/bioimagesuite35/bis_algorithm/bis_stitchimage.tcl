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
package require bis_resliceimage 1.0
package provide bis_stitchimage 1.0

#
# blend image
#

itcl::class bis_stitchimage {

    inherit bis_dualimagetransformationalgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Stitch images"}


}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_stitchimage::Initialize { } {

    PrintDebug "bis_stitchimage::Initialize" 

    set options {
	{ interp        "Interpolation Mode that is used when reslicing the image" "Interpolation Mode"  listofvalues Linear { "NearestNeighbor" "Linear" "Cubic" }  0 }
	{ axis      "Stitching Axis" "Stitching Axis" { listofvalues radiobuttons }  X { X Y Z }   1}
	{ seam    "Seam" "Seam" real -1 { -1 256 }  1 }
	{ flip  "Flip" "Flip"  { boolean } 0 { 0 1 }  1 }
	{ pad   "Pad" "Pad"  real 0 { 0 10 } 2 }
    }
	
    set defaultsuffix { "_stitched" }
    
    set scriptname bis_stitchimage
    set completionstatus "Done"
    #
    #document
    #

    set category "Image Processing Dual"
    set description "Stitches images"
    set description2 ""
    set backwardcompatibility "Reimplemented from pxmat_blendimage.tcl."
    set authors "alark.joshi@yale.edu, xenophon.papademetris@yale.edu."

    $this InitializeDualImageTransformationAlgorithm
}


# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_stitchimage::Execute {  } {

    PrintDebug "bis_stitchimage::Execute"

    set reslice_alg [bis_resliceimage [pxvtable::vnewobj]]
    $reslice_alg InitializeFromContainer $this
    $reslice_alg SetInput [ $this GetInput ] 
    $reslice_alg SetSecondInput [ $this GetSecondInput ] 
    $reslice_alg SetTransformation [ $this GetTransformation ] 
    $reslice_alg SetOptionValue interp [ $OptionsArray(interp) GetValue ]
    $reslice_alg Execute

    # set reslimage [  [ $reslice_alg GetOutput ] GetImage ]
    set reslimage  [ [ $this GetInput ] GetImage ]
    
    set imcast2 [ vtkImageCast [ pxvtable::vnewobj ]]
    $imcast2 SetInput $reslimage
    $imcast2 SetOutputScalarType [ [ [ $this GetInput ] GetImage ] GetScalarType ]
    $imcast2 Update

    set pad [ $OptionsArray(pad) GetValue ]
    set flip [ $OptionsArray(flip) GetValue ]
    set seam [ $OptionsArray(seam) GetValue ] 
    set interpolate [ $OptionsArray(interp) GetValue ] 
    set axis [ $OptionsArray(axis) GetValue ] 
    
    set stitchimage [  vtkpxImageStitch [ pxvtable::vnewobj ]]
    
    if { $pad == "0" } {
	
	if { [ $OptionsArray(axis) GetValue ] == "X" } { 
	    $stitchimage SetAxis  0
	} elseif  { [ $OptionsArray(axis) GetValue ] == "Y" } {
	    $stitchimage SetAxis  1			
	} else {
	    $stitchimage SetAxis  2			
	}
	$stitchimage SetInput  [ [ $this GetInput ] GetImage ] 
	$stitchimage SetInput2 [ [ $this GetSecondInput ] GetImage ] 
	$stitchimage SetSeamCoordinate $seam 
	$stitchimage SetFlipOrientation  [ $OptionsArray(flip) GetValue ]
	$stitchimage Update
	
#	puts "getting here" 
	
    } else { 
	
	set resl [ vtkbisImageReslice [ pxvtable::vnewobj ] ]
	$resl OptimizationOff 
	
	set trans  [  vtkIdentityTransform [ pxvtable::vnewobj ] ]	
	
	set spa  [  $reslimage  GetSpacing ]
	set ori  [  $reslimage  GetOrigin ]
	set dim  [  $reslimage  GetDimensions ]
	set voi0 [ list   0 0 0 ]
	set voi1 [ list   [ expr [ lindex $dim 0 ] -1 ]  [ expr [ lindex $dim 1 ] -1 ]  [ expr [ lindex $dim 2 ] -1 ]  ]
	
	set seampoint $seam 
	
	for { set i 0 } { $i <=2 } { incr i } {
	    set x0 [ expr round([ lindex $voi0 $i ]) ]
	    set x1 [ expr round([ lindex $voi1 $i ]) ]
	    
	    if { $axis == $i } {
		set dpad $pad 
		if {  $flip == 0 } {
		    set x1 [ expr $x1 + $dpad ]
		} else {
		    set x0 [ expr $x0 - $dpad ]
		    if { $seampoint > 0 } {
			set seampoint [ expr $seampoint + $dpad ]
		    }
		}
	    }
	    
	    if { $x1 < $x0 } { set x1 [ expr $x0 ] }
	    
	    set origin($i)  [ expr [lindex $ori $i ] + $x0 * [ lindex $spa $i ]]
	    set spacing($i) [lindex $spa $i ]
	    set ext($i)     [ expr ($x1-$x0) ]
	}
	
	$resl SetInput $reslimage
	$resl SetResliceTransform $trans
	$resl SetOutputSpacing $spacing(0) $spacing(1) $spacing(2)
	$resl SetOutputOrigin  $origin(0)  $origin(1)  $origin(2)
	$resl SetOutputExtent  0 $ext(0) 0 $ext(1) 0 $ext(2)
	$resl SetInterpolationMode 0 
	SetFilterCallbacks $resl "Padding Reference Image"
	$resl Update
	
	set resl2 [ vtkbisImageReslice [ pxvtable::vnewobj ]]
	$resl2 OptimizationOff
	set current_transform [ $this GetTransformation ]
	# set image_trn [  $imcast2 GetImage ]
	set image_trn [ [ $this GetSecondInput ] GetImage ] 
	
	$resl2 SetInformationInput [ $resl GetOutput ]
	$resl2 SetInput $image_trn
	$resl2 SetInterpolationModeTo$interpolate
	$resl2 SetBackgroundLevel 0.0
	$resl2 SetResliceTransform [ $current_transform GetObject ] 
	SetFilterCallbacks $resl "Reslicing Target Image"
	$resl2 Update
	
	if { [ $OptionsArray(axis) GetValue ] == "X" } { 
	    $stitchimage SetAxis  0
	} elseif  { [ $OptionsArray(axis) GetValue ] == "Y" } {
	    $stitchimage SetAxis  1
	} else {
	    $stitchimage SetAxis  2
	}
	
	$stitchimage SetInput           [ $resl GetOutput ] 
	$stitchimage SetInput2          [ $resl2 GetOutput ]
	$stitchimage SetSeamCoordinate  $seampoint 
	$stitchimage SetFlipOrientation $flip
	SetFilterCallbacks $stitchimage "Stitching Images"
	$stitchimage Update
    }
    
	 $imcast2 Delete 
    
    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage [ $stitchimage GetOutput ]
    
    # Output orientation etc. is same as input
    set outimage [ $this GetOutput ] 
    set pimage   [ $this GetSecondInput ] 

    $outimage CopyImageHeader [ $pimage GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $stitchimage Delete
    itcl::delete object $reslice_alg

    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_stitchimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

   

    set alg [bis_stitchimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

