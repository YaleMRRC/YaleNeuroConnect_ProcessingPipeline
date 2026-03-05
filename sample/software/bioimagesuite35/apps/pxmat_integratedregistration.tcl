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





# --------------------------------------------------------------------------------------------------------
# 	$Id: pxmat_integratedregistration.tcl,v 1.1 2004/01/15 15:10:03 xenios Exp xenios $	





# ----------------------------------------------------------------------------
set argc   [ llength $argv ]


set resolution 1.5
set iterations 25
set smoothness 0.0

set temperature 1.5
set numpoints 2000
set pointsweight 1.0
set preferentialsampling 0
set fixed_correspondences 0
set use_rpm 1
set threshold_low  -100.0
set threshold_high +100.0
set spacing 15.0
set numsteps 1

set argc [llength $argv]
if { $argc <6 } {
    set scriptname [ file tail $argv0 ]

    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "$scriptname is a script that computes non-linear intensity + point-based registrations"

    puts stdout "Syntax: $scriptname ref_image trg_image ref_surface trg_surface output_transformation input_transformation \[ spacing = 15 \] \[resolution=1.5\] \[iterations=15\] \[ smoothness=0.0\] \[ pts_weight=0.1 \] \[ numpoints 2000 \]  \[ temperature 1.5 \] \[ fixed_correspondences 0 \] \[ use_rpm 1 \] \[ numsteps =1 \] \[ surface_threshold_low -100 \] \[ surface_threshold_high 100.0 \] \[ autonormalize_intensities = 1 \]"
    puts stdout "\n"
    exit 1
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon

set refimg  [ lindex $argv 0 ]
set trnimg  [ lindex $argv 1 ]
set refsur  [ lindex $argv 2 ]
set trnsur  [ lindex $argv 3 ]
set output  [ lindex $argv 4 ] 
set initial [ lindex $argv 5 ]
set autonormalize 1


if { $argc > 6 }  {  set spacing  [ lindex $argv  6 ] }
if { $argc > 7 }  {  set resolution  [ lindex $argv  7 ] }
if { $argc > 8 }  {  set iterations  [ lindex $argv  8 ] }
if { $argc > 9 }  {  set smoothness  [ lindex $argv  9 ] }
if { $argc > 10 }  {  set pointsweight  [ lindex $argv  10 ] }
if { $argc > 11 } {  set numpoints   [ lindex $argv 11 ] }
if { $argc > 12 } {  set temperature [ lindex $argv 12 ] }
if { $argc > 13 } {  set fixed_correspondences [ lindex $argv 13 ] }
if { $argc > 14 } {  set use_rpm [ lindex $argv 14 ] }
if { $argc > 15 } {  set numsteps    [ lindex $argv 15 ] }
if { $argc > 16 } {  set threshold_low   [ lindex $argv 16 ] }
if { $argc > 17 } {  set threshold_high  [ lindex $argv 17 ] }
if { $argc > 18 } {  set autonormalize  [ expr  [ lindex $argv 18 ] > 0 ] }



set comment "Beginning ref=$refimg ($refsur) -> tar=$trnimg ($trnsur) output=$output initial=$initial\n\t"
set comment "${comment} spacing=$spacing resolution=$resolution, iterations=$iterations (x steps=$numsteps) smoothness=$smoothness pointsweight=$pointsweight numpoints=$numpoints surface_thresholds=$threshold_low : $threshold_high temperature=$temperature fixed_correspondences=$fixed_correspondences use_rpm=$use_rpm"

puts stdout $comment

set fout [ open ${output}.log w ]
puts $fout $comment
puts -nonewline $fout "commandline : \n\npxmat_intergratedregistration.tcl "
for { set i 0 } { $i < [ llength $argv ] } { incr i } {
    puts -nonewline $fout "[ lindex $argv $i] "
}
puts $fout " "
close $fout

puts stdout "\n----------------- Loading Images ---------------------------\n"
set ana [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
$ana Load $refimg
set img_ref [ $ana GetOutput ]
puts stdout "Reference Image Read from $refimg dimensions = [ $img_ref GetDimensions ]"

set ana2 [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
$ana2 Load $trnimg
set img_trn [ $ana2 GetOutput ]
puts stdout "Target Image Read from $trnimg dimensions = [ $img_trn GetDimensions ]"

puts stdout "\n----------------- Loading Surfaces ---------------------------\n"

set pana [ vtkPolyDataReader [ pxvtable::vnewobj ]]
$pana SetFileName $refsur; $pana Update
if { $threshold_low != $threshold_high } {
    set filt1 [ vtkThresholdPoints [ pxvtable::vnewobj ]]
    $filt1 SetInput [ $pana GetOutput ]
    $filt1 ThresholdBetween $threshold_low $threshold_high
    $filt1 Update
    set sur_ref [ $filt1 GetOutput ]
} else {
    set sur_ref [ $pana GetOutput ]
}

puts stdout "Reference Surface Read from $refsur thresholded points = [ $sur_ref GetNumberOfPoints ], bbox = [ $sur_ref GetBounds ] (orig = [ [ $pana GetOutput ] GetNumberOfPoints ])"
    
set pana2 [ vtkPolyDataReader [ pxvtable::vnewobj ]]
$pana2 SetFileName $trnsur; $pana2 Update
if { $threshold_low != $threshold_high } {
    set filt2 [ vtkThresholdPoints [ pxvtable::vnewobj ]]
    $filt2 SetInput [ $pana2 GetOutput ]
    $filt2 ThresholdBetween $threshold_low $threshold_high
    $filt2 Update
    set sur_trn [ $filt2 GetOutput ]
} else {
    set sur_trn [ $pana2 GetOutput ]
}
puts stdout "Target Surface Read from $trnsur thresholded points = [ $sur_trn GetNumberOfPoints ], bbox = [ $sur_trn GetBounds ] (orig = [ [ $pana2 GetOutput ] GetNumberOfPoints ])"

puts stdout "\n----------------- Load Initial  Registration  ---------------------------\n"

set xform 0
set ut [ vtkpxTransformationUtil [ pxvtable::vnewobj ]]
set xform [ $ut LoadAbstractTransform $initial ]
puts stdout "Initial Transform Loaded from $initial"

puts stdout "\n----------------- Non-linear Integrated Registration ---------------------------\n"

set nreg [ vtkpxNonLinearIntegratedRegistration [ pxvtable::vnewobj ]]
$nreg SetAutoNormalizeIntensities $autonormalize
$nreg SetSimilarityMeasure 5
$nreg SetInitialTransform $xform 
$nreg SetReferenceImage $img_ref
$nreg SetTransformImage $img_trn
$nreg SetNumberOfSteps  $numsteps
$nreg SetNumberOfLevels 1
$nreg SetStepSize       1.0
$nreg SetFixedCorrespondences $fixed_correspondences
$nreg SetLambda [ expr 0.01 * $smoothness ]
$nreg SetPointsWeight [ expr 0.01 * $pointsweight ]
$nreg SetResolution     $resolution
$nreg SetNumberOfIterations [ expr round($iterations) ]
$nreg SetControlPointSpacing $spacing
$nreg SetControlPointSpacingRate 2.0
$nreg SetOptimizationMethodToDefault


set rpm [ $nreg GetRPMEstimator ]
$rpm SetSource $sur_ref
$rpm SetTarget $sur_trn
$rpm SetMaximumNumberOfLandmarks $numpoints
$rpm SetExtraDebug 0
$rpm SetMatchModeToRPMFast
if { $use_rpm == 0 } {
    $rpm SetMatchModeToICP
}
$rpm SetUseLabels 1
$rpm SetFastThreshold 3.0
$rpm SetEnableFeedback 1
$rpm SetTemperature $temperature

eval "$nreg AddObserver ProgressEvent { puts stdout \[ $nreg GetOutputStatus \] }"
$nreg Run

set fname $output
set ok [ [ $nreg GetTransformation ] Save $fname  ]
puts stdout "Non Linear Transformation saved in $fname ($ok) [ file size $fname ]"
$nreg Delete
	
puts stdout "\n----------------- Done  ---------------------------\n"

$ana Delete
$ana2 Delete
$pana Delete
$pana2 Delete

exit 0

# --------------------------------------------------------------------------------------------------------




