#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" "$@"

lappend auto_path [ file dirname [ info script ] ]
package require pxappscommon 
package require pxitcltransform

set argc [ llength $argv ]

if { $argc < 1 } { puts "$argv0 image"; exit 0 }

puts "Loading images"

set total 0

set ana1 [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ] ]
$ana1 Load [ lindex $argv 0 ]

set extr [ vtkImageExtractComponents [ pxvtable::vnewobj ] ]
$extr SetInput [ $ana1 GetOutput ]

$extr SetComponents 0
$extr Modified
$extr Update
set ref [ vtkImageData [ pxvtable::vnewobj ] ]
$ref DeepCopy [ $extr GetOutput ]

set numframes [ [ $ana1 GetOutput ] GetNumberOfScalarComponents ]

set f [ lindex $argv 0 ]
set ext [ file extension $f ]
if { $ext == ".gz" } {
    set outname "[ file root [ file root $f ] ]_mc"
} else { 
    set outname "[ file root $f ]_mc"
}

set numlevels 3
set numit 60
set numsteps 5 ; # seems every 8 step is 150 milli seconds
set step 1

set registration  [ vtkpxLinearRegistration new ]
$registration SetOptimizationMethodToSlowClimb 
$registration SetSimilarityMeasureToSumofSquaredDifferences 
$registration SetReferenceImage $ref
$registration SetTransformModeToRigid
$registration SetAutoNormalizeIntensities 1
$registration SetReferenceOrientation 0
$registration SetTransformOrientation 0
$registration SetOptimizationScaleFactor 1 ; #orig set to mean resolution
$registration SetStepSize $step ; #new 2 ; orig 0.1
$registration SetNumberOfIterations $numit ; #new 10 ; orig 1500
$registration SetNumberOfLevels $numlevels ; #new 1 ; orig 3
$registration SetNumberOfSteps  $numsteps ; #new 20 ; orig 64
$registration SetResolution 1.0

set resl [ vtkbisImageReslice New ]
$resl SetInformationInput $ref
$resl SetInterpolationMode 3 ; # 3 is for cubic

puts "Beginning Motion Correction"

for { set i 1 } { $i < $numframes } { incr i } {
   
    puts  -nonewline "-${i}-"
    flush stdout

    $extr SetComponents $i
    $extr Modified
    $extr Update

    set img($i) [ [ pxitclimage \#auto ] GetThisPointer ]

    $registration SetTransformImage [ $extr GetOutput ]
    $registration Run

    $resl SetInput [ $extr GetOutput ]
    $resl SetResliceTransform [ $registration GetTransformation ] 
    $resl Update

    $img($i) ShallowCopyImage [ $resl GetOutput ]
}

$registration Delete
$resl      Delete

set appnd [ vtkImageAppendComponents [ pxvtable::vnewobj ] ]

$appnd AddInput $ref 

for { set i 1 } { $i < $numframes } { incr i } {
    $appnd AddInput [ $img($i) GetImage ]
    itcl::delete object $img($i)
}

$appnd Update

puts "\nSaving output as $outname"

set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ] ]
$anaw SetImageHeader [ $ana1 GetImageHeader ]
$anaw SetInput [ $appnd GetOutput ]
$anaw SetForceOutputFileFormat 2
$anaw Save "${outname}.nii.gz"

$anaw Delete
$ana1 Delete
$ref Delete 

puts Done

exit

