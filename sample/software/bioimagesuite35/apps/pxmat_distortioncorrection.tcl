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
# 	$Id: pxmat_distortioncorrection.tcl,v 1.1 2004/01/15 15:10:50 xenios Exp xenios $	




set argc [llength $argv]
if { $argc < 2 } {
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "$scriptname is a script that computes non-linear distortion corrections for echoplanar images"

    puts stdout "Syntax: $scriptname ref_image trg_image output_transformation \[phaseencodedirection=1\] \[resolution=2.0\] \[spacing=15\] \[iterations=12\] \[ step_size=3.0\] \[ smoothness=0.0005\]"
    puts stdout "\n"
    exit 0
}
   
lappend auto_path [ file dirname [ info script ]]; package require pxappscommon
set filenametype 0

# --------------------------------------------------------------------------------------------------------
proc DoNMIDistortion { image1 image2 output_xform xform_mode initialxform { resolution 1.5 } { spacing 15.0 } { iterations 15 } { stepsize 1 } { smoothness 0 } {phaseencode 1 } } {

    if { $xform_mode == "linear" } {
	set areg [ vtkpxLinearRegistration [ pxvtable::vnewobj ]]
	$areg SetTransformModeToRigid
	$areg SetSimilarityMeasure 5
	$areg SetReferenceImage $image1
	$areg SetTransformImage $image2
	$areg SetReferenceOrientation 0
	$areg SetTransformOrientation 0
	$areg SetResolution $resolution
	$areg SetNumberOfLevels 2
	$areg SetNumberOfSteps  1
	$areg SetStepSize       1.0
	$areg SetOptimizationMethodToConjugateGradient
	$areg SetNumberOfIterations $iterations 
	eval "$areg AddObserver ProgressEvent { puts stdout  \[ $areg GetOutputStatus \] }"
	$areg Run
	
	$output_xform DeepCopy  [ $areg GetTransformation ]
	$areg Delete
    } else {
	set nreg [ vtkpxDistortionCorrection [ pxvtable::vnewobj ]]
	$nreg SetSimilarityMeasure 5
	
	if { $initialxform !=0 } { 
	    $nreg SetInitialTransform $initialxform 
	    puts stdout "Using Initial Transformation"
	}
    
	$nreg SetUseJacobian 0
	$nreg SetUseSignalLossCorrection 0
	$nreg SetReferenceImage $image1
	$nreg SetTransformImage $image2 
	$nreg SetNumberOfSteps  1
	$nreg SetNumberOfLevels 3
	$nreg SetStepSize       $stepsize 
	$nreg SetLambda [ expr 0.01 * $smoothness ]
	$nreg SetResolution     $resolution 
	$nreg SetControlPointSpacing $spacing
	$nreg SetControlPointSpacingRate 2.0
	$nreg SetOptimizationMethodToDefault
	$nreg SetNumberOfIterations $iterations
	$nreg SetPhaseEncodeAxis $phaseencode
	
	eval "$nreg AddObserver ProgressEvent { puts stdout  \[ $nreg GetOutputStatus \] }"
	$nreg Run
	$output_xform DeepCopy  [ $nreg GetTransformation ]
	$nreg Delete
    }

}
# --------------------------------------------------------------------------------------------------------
#   Main Program 
# ----------------------------------------------------------------------------------------------------

proc DoNMIDistortionAll { refimagename trnimagename output phaseencode resolution spacing iterations stepsize smoothness } {
    
    set ut [ vtkpxTransformationUtil [ pxvtable::vnewobj ]]
    
    puts stdout "\n----------------- Loading Reference Image ---------------------------\n"
    set ana [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
    $ana Load $refimagename
    set img_ref [ $ana GetOutput ]
    puts stdout "Reference Image Read from $refimagename dimensions = [ $img_ref GetDimensions ]"
    
    set ana2 [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
    $ana2 Load $trnimagename
    set img_trn [ $ana2 GetOutput ]
    puts stdout "Target Image Read from $trnimagename dimensions = [ $img_trn GetDimensions ]"
    
    		  
    puts stdout "\n----------------- Running Linear  ---------------------------\n"

    set xform [ vtkTransform [ pxvtable::vnewobj ]]
    $xform Identity 
    DoNMIDistortion  $img_ref $img_trn $xform linear 0 $resolution $spacing $iterations 1 0

    puts stdout "\n----------------- Running Non-Linear  ---------------------------\n"
    set xform2 [ vtkpxComboTransform [ pxvtable::vnewobj ] ]
    DoNMIDistortion $img_ref $img_trn $xform2 nonlinear  $xform $resolution $spacing $iterations $stepsize $smoothness $phaseencode
    set fname "${output}.grd"
    set ok [ $xform2 Save $fname  ]
    puts stdout "Non Linear Transformation saved in $fname ($ok) [ file size $fname ]"
    $xform2 Delete

    puts stdout "\n----------------- Done  ---------------------------\n"
    
    $ana Delete
    $ana2 Delete
    $xform Delete
    $ut Delete
    return 1
}

# --------------------------------------------------------------------------------------------------------


set argc [ llength $argv ]
set refimg [ lindex $argv 0 ]
set tarimg [ lindex $argv 1 ]

if { $argc > 2 } {
    set output [ file root [ lindex $argv 2 ] ]
} else {
    set output "[ file root [ lindex $argv 0 ] ]_[ file root [ file tail [ lindex $argv 1 ]]]_distortion"
    puts stderr "Output set to $output"
}

set phaseencodedirection 1
if { $argc > 3 } {
    if {  [ lindex $argv 3 ] < 1 } {
	set phaseencodedirection 0
    } else {
	if {  [ lindex $argv 3 ] < 1 } {
	    set phaseencodedirection 2
	}
    } 
}

# 1 2.0 15.0 12.1 3.0 0.0005

if { $argc > 4 } {
    set resolution [ lindex $argv 4 ]
} else {
    set resolution 2.0
}

if { $argc > 5 } {
    set spacing [ lindex $argv 5 ]
} else {
    set spacing 15.0
}

if { $argc > 6 } {
    set iterations [ expr round([ lindex $argv 6 ]) ]
} else {
    set iterations 12
}


if { $argc > 7 } {
    set stepsize [ lindex $argv 7 ]
} else {
    set stepsize 3.0
}


if { $argc > 8 } {
    set smoothness [ lindex $argv 8 ]
} else {
    set smoothness 0.0005
}



puts stdout "Beginning ref=$refimg -> tar=$tarimg output=$output phase encode direction (0=X,1=Y,2=Z)=$phaseencodedirection res=$resolution spa=$spacing it=$iterations stepsize=$stepsize smoothness=$smoothness numargs=[ llength $argv ]"

DoNMIDistortionAll $refimg $tarimg  $output  $phaseencodedirection $resolution $spacing $iterations $stepsize $smoothness

exit 0

