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



set refimg  ""
set resolution -1.0
set blursize 0.0
set threshold 0.01
set raw 0

set argc [llength $argv]
if { $argc <3 } {
    set scriptname [ file tail $argv0 ]
    puts stderr "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stderr "$scriptname is a script that computes either the determinant of the jacobian or the full tensor for a transformation"
    puts stderr "Syntax: $scriptname refimage transformation output \[ resolution = -1.0 \] \[ blursize = 0.0 \] \[ threshold 0.0 \] \[ raw_values = 0 \]"
    exit
}


lappend auto_path [ file dirname [ info script ]]; package require pxappscommon

    
set imagename           [ lindex $argv 0 ]
set xformname           [ lindex $argv 1 ]
set outputname          [ lindex $argv 2 ]

if { $argc > 3 } { set resolution   [ ::pxappscommon::RestrictRange [ lindex $argv 3 ] -1 10.0 ] }
if { $argc > 4 } { set blursize     [ ::pxappscommon::RestrictRange [ lindex $argv 4 ] 0.0  10.0 ] }
if { $argc > 5 } { set threshold    [ ::pxappscommon::RestrictRange [ lindex $argv 5 ] 0.0 1.0 ] }
if { $argc > 6 } { set raw          [ ::pxappscommon::RestrictIntRange [ lindex $argv 6 ] 0 1 ] }


# ------------------------------------------------------------------------------------------------
proc J_ThresholdSmoothImage { img threshold sigma } {

    set r [ [ [ $img GetPointData ] GetScalars ] GetRange ]
    set cutoff [ expr [ lindex $r 0 ] + $threshold * ( [ lindex $r 1 ] - [ lindex $r 0 ] ) ]
    puts stderr "++++ Thresholding r=$r , thr=$threshold sigma=$sigma Cutoff for Thresholding = $cutoff"

    set threshold  [ vtkImageThreshold [ pxvtable::vnewobj ]  ]
    $threshold SetInput $img 
    $threshold SetInValue    1.0
    $threshold SetOutValue   0.0
    $threshold ReplaceInOn
    $threshold ReplaceOutOn
    $threshold ThresholdBetween $cutoff [ lindex $r 1 ]
    $threshold SetOutputScalarTypeToFloat
    $threshold Update

    set smooth2 [ vtkImageGaussianSmooth [ pxvtable::vnewobj ]]
    $smooth2 SetInput [ $threshold GetOutput ]
    $smooth2 SetStandardDeviations $sigma $sigma $sigma
    $smooth2 SetRadiusFactors 3.0 3.0 3.0
    $smooth2 Update



    set out  [ vtkImageData [ pxvtable::vnewobj ]]
    $out ShallowCopy [ $smooth2 GetOutput ]

    set out2 [ vtkImageData [ pxvtable::vnewobj ]]
    $out2 ShallowCopy [ $threshold GetOutput ]

    $threshold Delete
    $smooth2 Delete
    return [ list $out2 $out ]
}

proc J_MaskedSmoothImage { input smoothmask sigma } {


    set smooth [ vtkImageGaussianSmooth [ pxvtable::vnewobj ]]
    $smooth SetInput $input
    $smooth SetStandardDeviations $sigma $sigma $sigma
    $smooth Update

    set math [ vtkImageMathematics [ pxvtable::vnewobj ]]
    $math SetInput1 [ $smooth GetOutput ]
    $math SetInput2 $smoothmask
    $math SetOperationToDivide
    $math SetConstantC 0.0
    $math SetDivideByZeroToC 1
    $math Update

    set img [ vtkImageData [ pxvtable::vnewobj ]]
    $img ShallowCopy [ $math GetOutput ]
    $smooth Delete
    $math Delete
    return $img
}


proc J_ResampleImage { img sp } {

    set resl [ vtkImageResample [ pxvtable::vnewobj ] ]
    $resl SetAxisOutputSpacing 0 $sp
    $resl SetAxisOutputSpacing 1 $sp
    $resl SetAxisOutputSpacing 2 $sp
    $resl InterpolateOff
    $resl SetDimensionality 3
    $resl SetInput $img
    $resl Update
    
    set ref_image [ vtkImageData [ pxvtable::vnewobj ]]
    $ref_image ShallowCopy [ $resl GetOutput ]
    $resl Delete

    puts stdout "++++ Dimensions [ $ref_image GetDimensions ]"
    return $ref_image
}

proc J_ComputeSimpleJacobian { ref_imgmask tr  } {

    set jac [ vtkImageData [ pxvtable::vnewobj ]]
    set jac2 [ vtkImageData [ pxvtable::vnewobj ]]
    set reg [ vtkpxRegistration [ pxvtable::vnewobj ]]
    set affine [ $reg ComputeAverageJacobian $ref_imgmask $tr ]
    $reg ComputeSimpleJacobianImage $ref_imgmask $jac  $tr 100.0 $affine 0.01
    $reg ComputeSimpleJacobianImage $ref_imgmask $jac2 $tr 100.0 1.0     0.01
    $reg Delete

    return [ list $jac2 $jac ]
}

proc J_ComputeCompleteJacobian { ref_imgmask tr } {

    set jac [ vtkImageData [ pxvtable::vnewobj ]]
    set reg [ vtkpxRegistration [ pxvtable::vnewobj ]]
    $reg ComputeJacobianImage $ref_imgmask $jac  $tr 1 1.0 0
    $reg Delete
    return $jac
}

# --------------------------------------------------------------------------------------------------------

#set ut [ vtkpxUtil [ pxvtable::vnewobj ]]

set ana [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ] ]
$ana Load $imagename

set imageheader [ $ana GetImageHeader ]
puts stderr "\n++++ Image $imagename [ [ $ana GetOutput ] GetDimensions ]"

set util [ vtkpxTransformationUtil [ pxvtable::vnewobj ]]	
set tr [ $util LoadAbstractTransform  $xformname ]
$util Delete
puts stdout "++++ Transform [ file tail $xformname ], [ file size $xformname ]\n++++ Transform Type = [ $tr GetClassName ]"


set spa  [ lindex [ [ $ana GetOutput ] GetSpacing ] 0 ]
set sigma [ expr $blursize/ $spa ]

puts stderr "++++ Using blur = $blursize mm or $sigma (voxels) and threshold=$threshold \%"

# Step 0 -- resample image
if { $resolution > 0.5 } {
    set ref [ J_ResampleImage [ $ana GetOutput ] $resolution ]
} else {
    set ref [ vtkImageData [ pxvtable::vnewobj ]]
    $ref ShallowCopy [ $ana GetOutput ]
}


#$ut SaveAnalyze jacobians/0_ref $ref  0
puts stderr "++++ Using ref image resolution [ $ref GetSpacing ]"

# Step 1 -- create mask
set tmp [ J_ThresholdSmoothImage $ref $threshold $sigma ]
set regimgmask [ lindex $tmp 0 ]
set sregimgmask [ lindex $tmp 1 ]

#$ut SaveAnalyze jacobians/1_smask  $sregimgmask  0

# Step 2 -- Compute Jacobian
if { $raw == 0 } {
    set jaclist [ J_ComputeSimpleJacobian $regimgmask $tr ]
} else {
    set jaclist [ J_ComputeCompleteJacobian $regimgmask $tr ]
}

#$ut SaveAnalyze jacobians/2_jac [ lindex $jaclist 0 ] 0

# Step 3 -- Smooth Jacobians
set outlist ""
for { set i 0 } { $i < [ llength $jaclist ] } { incr i } {
    lappend outlist [ J_MaskedSmoothImage [ lindex $jaclist $i ] $sregimgmask $sigma ]
}

#$ut SaveAnalyze jacobians/3_sjac [ lindex $outlist 0 ] 0

# Step 4 -- Save

if { $raw ==0 } {
    set suffixlist [ list "_combined" "_nonlinear" ]
} else {
    set suffixlist "_raw"
}

set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]
$anaw SetImageHeader $imageheader
$anaw SetCompression 9

for { set i 0 } { $i < [ llength $outlist ] } { incr i } {
    $anaw SetInput [ lindex $outlist $i ]
    set name "[file root $outputname ][ lindex $suffixlist $i ].hdr"
    $anaw Save $name
    puts stderr "Output $i saved in $name"
}
    
# Step 5 -- Cleanup
for { set i 0 } { $i < [ llength $outlist ] } { incr i } {
    [ lindex $outlist $i ] Delete
    [ lindex $jaclist $i ] Delete
}

puts stderr "\n"

$regimgmask Delete
$sregimgmask Delete
$ref Delete
$tr  Delete
$ana Delete
exit

