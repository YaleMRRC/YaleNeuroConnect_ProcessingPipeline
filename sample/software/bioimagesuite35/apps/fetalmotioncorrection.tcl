#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" "$@"

proc ComputeFrameToFrameDisp { disparray old  } {

    set diffmag 0
    for {set j 0 } { $j < 3 } { incr j } {
	set diff [ expr [ $disparray GetComponent 0 $j ] - [ lindex $old $j ] ]
	set diffmag [ expr $diffmag + $diff * $diff ]
    }

    #return -1 diffmag, so larger equals better
    set diffmag [ expr -1 * sqrt($diffmag) ]
    return $diffmag
}

proc ComputeFrameToRefDisp { disparray } {
    
    set mag 0
    for {set j 0 } { $j < 3 } { incr j } {
	set val [ $disparray GetComponent 0 $j ]
	set mag [ expr $mag + $val * $val ]
    }

    #return -1 mag, so larger equals better
    set mag [ expr -1 * sqrt($mag) ]
    return $mag
}

proc ComputeMean { inlist } {

    set sum 0
    set N [ llength $inlist ] 
    foreach val $inlist {
	set sum [ expr $sum+$val ]
    }
    if { $N > 0 } { 
	set out [ expr $sum/$N ]
    } else { 
	set out $sum
    }
    return $out
}

proc ComputeSTD { mean inlist } {

    set sum 0
    set N [ expr [ llength $inlist ] -1 ]
    foreach val $inlist {
	set sum [ expr $sum+pow($val-$mean,2) ]
    }
    if { $N > 0 } { 
	set out [ expr sqrt($sum/$N) ]
    } else { 
	set out 0
    }
    return $out
}

proc CreateSkipList { vallist oldlist meanval stdval {factor 1} {includeneighbors 0} } {
    
#    set meanval [ ComputeMean $vallist ]         
#    set stdval  [ ComputeSTD  $meanval $vallist ]
    set valthr [ expr $meanval - $factor * $stdval ]       

    set N [ llength $vallist ] 

    for { set i 0 } { $i < $N } { incr i } {
	set val [ lindex $vallist $i ]
	if { $val <= $valthr } {
	    lappend oldlist [ expr $i ]
	    #lappend oldlist [ expr $i + 1 ]
	}
    }
    return [ lsort -integer -unique $oldlist ]
}

proc ConvertListToString { skiplist numframes } {

    set N [ llength $skiplist ] 
    set skipstring ""

    for { set i 0 } { $i < $N } { incr i } {
	set val [ lindex $skiplist $i ]
	if { ($val>=0) && ($val<$numframes ) } {
	    set skipstring "${skipstring} ${val} ${val},"
	}
    }
    return $skipstring
}

proc CalculateAndSaveSNR { outname img mask } {

    set outf [ open $outname w+ ]
    set snrlsit [list]

    set ident [ vtkIdentityTransform [pxvtable::vnewobj ]]
    set thr   [ vtkpxMergeFmriConventional [ pxvtable::vnewobj ]]
    set arr   [ vtkFloatArray [ pxvtable::vnewobj ]]
    
    set nt [  $thr ComputeROIStatistics $img $mask  $ident $arr ]
    
    #nt is going to be 2*numframes (1st is background; 2nd is the ROI)
    #start at 1 and incr by 2
    for { set i 1 } { $i < $nt } { incr i 2 } {    
	set meanval [ $arr GetComponent $i 3 ] 
	set stdval  [ $arr GetComponent $i 4 ] 
	set snr 0
	if { $stdval>0 && $meanval>0 } { 
	    set snr [ expr $meanval / $stdval ]
	}
	lappend snrlist $snr
	puts $outf "${meanval}\t${stdval}\t${snr}"
    }

    $thr Delete
    $ident Delete

    close $outf
    return $snrlist
}

proc CalculateFinalMask { eigimage } {

    set ss_alg [ bis_shiftscaleimage [pxvtable::vnewobj]]
    $ss_alg InitializeFromContainer 0 
    $ss_alg SetOptionValue type Float
    $ss_alg SetOptionValue shift -100
    $ss_alg SetOptionValue scale -1
    $ss_alg SetInput $eigimage
    $ss_alg Execute

    set strip_alg [bis_stripskull [pxvtable::vnewobj]]
    $strip_alg InitializeFromContainer 0 
    $strip_alg SetInput [ $ss_alg GetOutput ]
    $strip_alg Execute

    set thr_alg  [bis_thresholdimage [pxvtable::vnewobj]]
    $thr_alg InitializeFromContainer 0 
    $thr_alg SetInput [ $strip_alg GetOutput ]
    $thr_alg SetOptionValue minth 0.5
    $thr_alg SetOptionValue binary On
    $thr_alg Execute

    set outimg [ vtkImageData [ pxvtable::vnewobj ]]    
    $outimg DeepCopy [ [ $thr_alg GetOutput ] GetObject ]

    itcl::delete object $ss_alg
    itcl::delete object $strip_alg
    itcl::delete object $thr_alg
    
    return $outimg
}

proc DoSkullStrip { eigimage originalimage blursigma } {

    set useold 0

    if { $useold ==1 } {
	set ss_alg [ bis_shiftscaleimage [pxvtable::vnewobj]]
	$ss_alg InitializeFromContainer 0 
	$ss_alg SetOptionValue type Float
	$ss_alg SetOptionValue shift -100
	$ss_alg SetOptionValue scale -1
	$ss_alg SetInput $eigimage
	$ss_alg Execute
	
	set strip_alg [bis_stripskull [pxvtable::vnewobj]]
	$strip_alg InitializeFromContainer 0 
	$strip_alg SetInput [ $ss_alg GetOutput ]
	$strip_alg Execute
	
	set mask_alg  [bis_maskimage [pxvtable::vnewobj]]
	$mask_alg InitializeFromContainer 0 
	$mask_alg SetInput $originalimage
	$mask_alg SetSecondInput [ $strip_alg GetOutput ]
	$mask_alg Execute
	
	set range [ [ [ [ [ $mask_alg GetOutput ] GetObject ] GetPointData ] GetScalars ] GetRange ]
	set thr 0.20
	
	set thr_alg  [bis_thresholdimage [pxvtable::vnewobj]]
	$thr_alg InitializeFromContainer 0 
	$thr_alg SetInput [ $mask_alg GetOutput ]
	$thr_alg SetOptionValue minth [ expr [ lindex $range 1 ] * $thr ]
	$thr_alg Execute
	
	set smooth_alg  [bis_smoothimage [pxvtable::vnewobj]]
	$smooth_alg InitializeFromContainer 0 
	$smooth_alg SetInput  [ $thr_alg GetOutput ]
	$smooth_alg SetOptionValue blursigma $blursigma
	$smooth_alg Execute
	
	set output [ vtkImageData [ pxvtable::vnewobj ]]    
	$output DeepCopy [ [ $smooth_alg GetOutput ] GetObject ]
    
	itcl::delete object $ss_alg
	itcl::delete object $strip_alg
	itcl::delete object $mask_alg 
	itcl::delete object $thr_alg
	itcl::delete object $smooth_alg
    } else { 
	set ss_alg [ bis_shiftscaleimage [pxvtable::vnewobj]]
	$ss_alg InitializeFromContainer 0 
	$ss_alg SetOptionValue type Float
	$ss_alg SetOptionValue shift -100
	$ss_alg SetOptionValue scale -1
	$ss_alg SetInput $eigimage
	$ss_alg Execute
	
	set strip_alg [bis_stripskull [pxvtable::vnewobj]]
	$strip_alg InitializeFromContainer 0 
	$strip_alg SetInput [ $ss_alg GetOutput ]
	$strip_alg Execute
	
	set thr_alg  [bis_thresholdimage [pxvtable::vnewobj]]
	$thr_alg InitializeFromContainer 0 
	$thr_alg SetInput [ $strip_alg GetOutput ]
	$thr_alg SetOptionValue minth 0.5
	$thr_alg SetOptionValue binary x100
	$thr_alg Execute
	
	set smooth_alg  [bis_smoothimage [pxvtable::vnewobj]]
	$smooth_alg InitializeFromContainer 0 
	$smooth_alg SetInput  [ $thr_alg GetOutput ]
	$smooth_alg SetOptionValue blursigma $blursigma
	$smooth_alg Execute
	
	set output [ vtkImageData [ pxvtable::vnewobj ]]    
	$output DeepCopy [ [ $smooth_alg GetOutput ] GetObject ]
	
	itcl::delete object $ss_alg
	itcl::delete object $strip_alg
	itcl::delete object $smooth_alg
	itcl::delete object $thr_alg
    }

    return $output
}

proc MakeWeightImage { weightimg dilate blursigma  } {

    set output [ vtkImageData [ pxvtable::vnewobj ]]    

    #1st cast to float
    set cast [vtkImageCast [pxvtable::vnewobj]]
    $cast SetInput $weightimg
    $cast SetOutputScalarTypeToFloat
    $cast Update
    set tmp  [ $cast GetOutput ]
    
    #2nd dilate
    set r [ expr 2*$dilate + 1 ]
    set dilatealg  [  vtkImageContinuousDilate3D [ pxvtable::vnewobj ] ]
    if { $dilate > 0 } {
	$dilatealg SetInput $tmp
	$dilatealg SetKernelSize $r $r $r
	$dilatealg Update
	set tmp  [ $dilatealg GetOutput ]
    }
    
    #3rd smooth
    set spa [ $weightimg GetSpacing ]
    set sigma(0) [ expr $blursigma * 0.4247 / [ lindex $spa 0 ]]
    set sigma(1) [ expr $blursigma * 0.4247 / [ lindex $spa 1 ]]
    set sigma(2) [ expr $blursigma * 0.4247 / [ lindex $spa 2 ]]
    set smooth  [ vtkImageGaussianSmooth [ pxvtable::vnewobj ]  ]

    $smooth SetStandardDeviations $sigma(0) $sigma(1) $sigma(2)
    $smooth SetRadiusFactors 1.5 1.5 1.5
    $smooth SetInput $tmp
    $smooth Update

    $output ShallowCopy  [ $smooth GetOutput ]

    $cast Delete    
    $dilatealg Delete
    $smooth  Delete
    
    return $output
}

proc GetEdge { currentimage } {

    set output [ vtkImageData [ pxvtable::vnewobj ]]

    set spa [ $currentimage GetSpacing ]
    set sigma(0) [ expr 6 * 0.4247 / [ lindex $spa 0 ]]
    set sigma(1) [ expr 6 * 0.4247 / [ lindex $spa 1 ]]
    set sigma(2) [ expr 6 * 0.4247 / [ lindex $spa 2 ]]
    set smooth  [ vtkImageGaussianSmooth [ pxvtable::vnewobj ]  ]

    $smooth SetStandardDeviations $sigma(0) $sigma(1) $sigma(2)
    $smooth SetRadiusFactors 1.5 1.5 1.5
    $smooth SetInput $currentimage
    $smooth Update

    set grad [ vtkImageGradient [ pxvtable::vnewobj ]]
    $grad HandleBoundariesOn
    $grad SetInput [ $smooth GetOutput ]
    $grad Update

    set magn [ vtkImageMagnitude [ pxvtable::vnewobj ]]
    $magn SetInput [ $grad GetOutput ]
    $magn Update

    set sup [ vtkImageNonMaximumSuppression [ pxvtable::vnewobj ]]
    $sup SetVectorInput [ $grad GetOutput ]
    $sup SetMagnitudeInput [ $magn GetOutput ]
    $sup HandleBoundariesOn
    $sup Update
    $output ShallowCopy [ $sup GetOutput ]

    $magn Delete
    $grad Delete    
    $smooth Delete
    $sup  Delete

    return $output
}

proc GetEigenValue { currentimage whicheigen} {

    set doedge 0

    if { $doedge > 0 } {
	
	return [ GetEdge $currentimage ]
    }

    set output [ vtkImageData [ pxvtable::vnewobj ]]

    set hess [ vtkxqImageHessian [ pxvtable::vnewobj ] ]
    $hess SetInput $currentimage
    $hess SetSigma 1
    $hess SetForceCPU 1 
    $hess Update
    
    set vess [ vtkmpjImageVesselEnhancement [ pxvtable::vnewobj ] ]
    $vess SetInput [ $hess GetOutput ]
    $vess SetStructureType 3
    
    set extr [ vtkImageExtractComponents [ pxvtable::vnewobj ] ]
    $extr SetInput [ $vess GetOutput ]
    $extr SetComponents [ expr $whicheigen -1 ]
    $extr Update

    set thr  [  vtkImageThreshold New ]
    $thr ThresholdBetween  0 1000000000
    $thr SetInValue    1
    $thr SetOutValue   0
    $thr SetReplaceOut 1
    $thr SetReplaceIn  0
    $thr SetInput  [ $extr GetOutput ]
    $thr Update

    $output ShallowCopy [ $thr GetOutput ]
#    $output ShallowCopy [ $extr GetOutput ]

    $hess Delete
    $vess Delete    
    $extr Delete
    $thr  Delete

    return $output
}

proc RunTripleSliceHomogeneity { currentimage dobiasfield } { 

    set output [ vtkImageData [ pxvtable::vnewobj ]]

    set axislist { x y z }
    for { set axis 0 } { $axis <=2 } { incr axis } {
	set fit [ vtkpxSliceBiasFieldCorrection  [ pxvtable::vnewobj ]]
	$fit SetAxis $axis
	$fit SetRobustMode 1
	$fit SetPureScaling 0
	$fit SetInput $currentimage
	$fit SetFrame 0
	$fit Update
	$output ShallowCopy [ $fit GetOutput ]
	$fit Delete
    }

    return $output
}

proc ExtractLinearTransform { in_xform image_ref image_trn 6 } {

    set xform [ vtkpxLinearTransform [ pxvtable::vnewobj ] ]
    $xform ExtractParameters $in_xform 6 $image_ref 0 $image_trn 0

    for { set k 6 } { $k < 15 } { incr k } {
	$xform Put $k 0
    }

    return $xform
}

proc CreateOutname { argc argv } {
    if { $argc < 4 } {
	set f [ lindex $argv 0 ]
	set ext [ file extension $f ]
	
	if { $ext == ".gz" } {
	    set outname "[ file root [ file root $f ] ]_mc"
	} else { 
	    set outname "[ file root $f ]_mc"
	}
    } else {
	set outname [ lindex $argv 3 ]
    }
    return $outname
}

proc MotionDescription { xform  } {
    
    set or [ list [ $xform  Get 3 ] [ $xform  Get 4 ] [ $xform  Get 5 ] ]
    set sc [ list [ $xform  Get 6 ] [ $xform  Get 7 ] [ $xform  Get 8 ] ]
    set tr [ list [ $xform  Get 0 ] [ $xform  Get 1 ] [ $xform  Get 2 ] ]

    set line ""
    
    #set factor 0.01745329251 ; # pi/180
    #set factor2 [ expr $factor * -1 ]
    set factor 1 ; set factor2 1;
    
    #for spm parameters x=x y=-y z=-z, xrot=pitch*180/pi, yrot=-roll*pitch*180/pi, zrot=-yaw*pitch*180/pi
	
    set line "${line}[ expr [ lindex $tr 0 ]      ]\t"
    set line "${line}[ expr [ lindex $tr 1 ] * -1 ]\t"
    set line "${line}[ expr [ lindex $tr 2 ] * -1 ]\t"
    set line "${line}[ expr [ lindex $or 0 ] * $factor  ]\t"
    set line "${line}[ expr [ lindex $or 1 ] * $factor  ]\t"
    set line "${line}[ expr [ lindex $or 2 ] * $factor2 ]"
    
    return $line
}

lappend auto_path [ file dirname [ info script ] ]
package require pxappscommon 
package require pxitcltransform
package require bis_stripskull
package require bis_shiftscaleimage
package require bis_maskimage
package require bis_smoothimage
package require bis_thresholdimage
package require bis_imageremoveframes

set argc [ llength $argv ]

#basic options
set debug 1
set whicheigen 3
set dobiasfield 0
#wgt options
set blursigma 16
set dilate 2
#reg params
set numlevels 2 
set numit 512
set numsteps 64
set step 5
set resolution 1.05
#reg options
set useinitial 1
set useweight 1
set useskullstrip 1
set usebetter 0

set factorlist [ list 1 0 -0.5 ]

if { $useweight < 1 } { set useskullstrip 0 }

if { $argc < 4 } { puts "$argv0 ref wgt outname tr"; exit 0 }
puts "Loading images"
puts $argv
#-----------------create outname-----------------
set outname [ lindex $argv 2 ] 
set outinfo [ open "${outname}.info" w+ ]
puts $outinfo "useinitial:${useinitial},useweight:${useweight},useskullstrip:${useskullstrip},usebetter:${usebetter}"
close $outinfo
set outf2 [ open "${outname}.par" w+ ]
set outf3 [ open "${outname}.disp" w+ ]
set outf4 [ open "${outname}_1stpass.sim" w+ ]
set outf5 [ open "${outname}_2ndpass.sim" w+ ]
#-------------------------------------------------------

#-----------------read input arguements-----------------
set ana(1) [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ] ]
set ana(2) [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ] ]

$ana(1) Load [ lindex $argv 0 ] ; #load ref
set ref_img [ [ pxitclimage \#auto ] GetThisPointer ]  
$ref_img  ShallowCopyImage [ $ana(1) GetOutput ]

$ana(2) Load [ lindex $argv 1 ] ; #load weight
set wgt_img [ [ pxitclimage \#auto ] GetThisPointer ]  
$wgt_img  ShallowCopyImage [ $ana(2) GetOutput ]

set nclist [ list 0 ]
set inappnd  [ vtkImageAppendComponents [ pxvtable::vnewobj ] ]

#load images to be corrected
for { set i 3 } { $i < $argc} { incr i } { 
puts [ lindex $argv $i ] 
    set ana($i) [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ] ]
    $ana($i) Load [ lindex $argv $i ] 
    $inappnd AddInput [ $ana($i) GetOutput ]
    set nc [ [ $ana($i) GetOutput ] GetNumberOfScalarComponents ]    
    lappend nclist [ expr $nc + [ lindex $nclist [ expr $i - 3 ] ] ]
}

set numinp [ expr [ llength $nclist ] -1 ]
$inappnd Update
set tr_img  [ [ pxitclimage \#auto ] GetThisPointer ]  ; 
$tr_img   ShallowCopyImage [ $inappnd GetOutput ]
if { $debug > 0 } { $tr_img Save "${outname}_all.nii.gz" }
#-------------------------------------------------------

#-----------------create reference eigen map-----------------
if { $dobiasfield } { $ref_img ShallowCopyImage  [ RunTripleSliceHomogeneity [ $ref_img GetObject ] ] }
set ref_eig [ [ pxitclimage \#auto ] GetThisPointer ] 
$ref_eig ShallowCopyImage [ GetEigenValue [ $ref_img GetObject ] $whicheigen ]
if { $debug > 0 } { $ref_eig Save  "${outname}_ref.nii.gz" }
#$ref_eig ShallowCopyImage [ GetEigenValue [ $ref_img GetObject ] 1 ]
#if { $debug > 0 } { $ref_eig Save  "${outname}_ref1.nii.gz" }
#$ref_eig ShallowCopyImage [ GetEigenValue [ $ref_img GetObject ] 2 ]
#if { $debug > 0 } { $ref_eig Save  "${outname}_ref2.nii.gz" }
#$ref_eig ShallowCopyImage [ GetEigenValue [ $ref_img GetObject ] 3 ]
#if { $debug > 0 } { $ref_eig Save  "${outname}_ref3.nii.gz" }
#-------------------------------------------------------

#-----------------make weightimage-----------------
$wgt_img ShallowCopyImage [ MakeWeightImage [ $wgt_img GetObject ] $dilate $blursigma ]
if { $debug > 0 } { $wgt_img Save  "${outname}_ref_weight.nii.gz" }
#-------------------------------------------------------

#-----------------1stpass registration setup-----------------
set registration [ vtkpxLinearRegistration New ]
$registration SetReferenceImage  [ $ref_eig GetObject ]
if { $useweight } { $registration SetReferenceWeightImage [ $wgt_img GetObject ] }
$registration SetTransformModeToRigid
$registration SetAutoNormalizeIntensities 1
$registration SetReferenceOrientation 0
$registration SetTransformOrientation 0 
$registration SetOptimizationScaleFactor 1 
$registration SetStepSize $step 
$registration SetNumberOfIterations $numit
$registration SetNumberOfLevels $numlevels
$registration SetNumberOfSteps  $numsteps 
$registration SetResolution $resolution
$registration SetOptimizationMethodToSlowClimb 
$registration SetSimilarityMeasureToCorrelation ;$registration SetNumberOfBins  1024

set resl [ vtkbisImageReslice New ]
$resl SetInformationInput [ $ref_eig GetObject ]
$resl SetInterpolationMode 3 ; # 3 is for cubic
#-------------------------------------------------------

#final setup for looping
set extr [ vtkImageExtractComponents [ pxvtable::vnewobj ] ]
$extr SetInput [ $tr_img GetObject ]
set numframes [ [ $tr_img GetObject ] GetNumberOfScalarComponents ]
set totaltime 0
set 1stpass_sim [ list ]
#-------------------------------------------------------

puts "Beginning Motion Correction"

for { set i 0 } { $i < $numframes } { incr i } {

    puts  "1stpass: frame ${i}" 

    #get single frame out
    $extr SetComponents $i
    $extr Modified
    $extr Update
    
    #biasfield correction on current frame
    set originalimg($i) [ [ pxitclimage \#auto ] GetThisPointer ]
    if { $dobiasfield } { 
	$originalimg($i) ShallowCopyImage [ RunTripleSliceHomogeneity [ $extr GetOutput ] ] 
    } else { 
	$originalimg($i) ShallowCopyImage [ $extr GetOutput ]  
    }
    $resl SetInput [ $originalimg($i) GetObject ]
    
    #eigenvalue on current frame
    set eigenimg($i) [ [ pxitclimage \#auto ] GetThisPointer ]
    $eigenimg($i) ShallowCopyImage [ GetEigenValue [ $originalimg($i) GetObject ] $whicheigen ]
    $registration SetTransformImage [ $eigenimg($i) GetObject ]

    #Skull strip to get 2nd weight image
    if { $useskullstrip } {
	set 2ndweightimage($i) [ [ pxitclimage \#auto ] GetThisPointer ]
	$2ndweightimage($i) ShallowCopyImage [ DoSkullStrip $eigenimg($i) $originalimg($i) $blursigma ] 
	$registration SetTransformWeightImage [ $2ndweightimage($i) GetObject ]
    }

    #1stpass reg
    set start [ clock clicks  -milliseconds ]        
    $registration Run   
    
    set txform($i) [ [ pxitcltransform \#auto ] GetThisPointer ]
    $txform($i) CopyTransformation [ $registration GetTransformation ]
    $resl SetResliceTransform [ $registration GetTransformation ]

#    puts "1st params $i: [ MotionDescription [ ExtractLinearTransform [ $txform($i) GetObject ] [ $ref_eig GetObject ] [ $ref_eig GetObject ] 9 ] ]"

    #Get and Save last similarity metric (for censoring)
    lappend 1stpass_sim [ $registration GetLastSimilarity ]
    puts $outf4  "[ $registration GetLastSimilarity ]"

    #reslice the images
    $resl Update
    set reslimg1($i) [ [ pxitclimage \#auto ] GetThisPointer ]
    $reslimg1($i) ShallowCopyImage [ $resl GetOutput ]

    #Print stuff to text files and screen
    set totaltime [ expr $totaltime + [ clock clicks  -milliseconds ]  -  $start ]
}

#---------------------create mean image
set tmpappnd [ vtkImageAppendComponents [ pxvtable::vnewobj ] ]
for { set i 0 } { $i < $numframes } { incr i } {
    $tmpappnd AddInput [ $reslimg1($i) GetObject ]
}
$tmpappnd Update

set average [ vtkbisTimeSeriesStat [ pxvtable::vnewobj ] ]
$average SetMode 0
$average SetInput [ $tmpappnd GetOutput ]
$average Update

if { $debug > 0 } { 
    set anaw1 [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ] ]
    $anaw1 SetImageHeader [ $ana(1) GetImageHeader ]
    $anaw1 SetForceOutputFileFormat 2
    $anaw1 SetInput [ $average GetOutput ]
    $anaw1 Save  "${outname}_1stmeanV2.nii.gz"
    $anaw1 Delete
}

set 2ndref_eig [ [ pxitclimage \#auto ] GetThisPointer ] 
$2ndref_eig ShallowCopyImage [ GetEigenValue [ $average GetOutput ] $whicheigen ]
if { $debug > 0 } { $2ndref_eig Save  "${outname}_2ndref.nii.gz" }

$average Delete
$tmpappnd Delete
#-------------------------------------------------------

#-----------------frametoframe displacement stuff-----------------
set cog  [ vtkbisCenterOfGravity [ pxvtable::vnewobj ] ]
$cog SetInput  [ $wgt_img GetObject ] 
$cog SetInVoxels 0
$cog Update

set disparray [ vtkFloatArray [ pxvtable::vnewobj ] ]
$disparray SetNumberOfComponents 1
$disparray SetNumberOfTuples 3

set frametoreflist [list]
set frametoframelist [list]
set olddisplist [list]
#-------------------------------------------------------

#---------------------final setup 
set 2ndpass_sim [ list ]
$registration SetReferenceImage  [ $2ndref_eig GetObject ]
#-------------------------------------------------------

for { set i 0 } { $i < $numframes } { incr i } {

    puts  "2ndpass: frame ${i}" 
    #2ndpass reg
    set start [ clock clicks  -milliseconds ]        

    set oldlinear [ ExtractLinearTransform [ $txform($i) GetObject ] [ $ref_eig GetObject ] [ $ref_eig GetObject ] 9 ]
#    puts "old params: [ MotionDescription $oldlinear ]	"

    $registration SetTransformImage [ $eigenimg($i) GetObject ]
    if { $useinitial } { $registration SetInitialTransform $oldlinear }
    if { $useskullstrip } { $registration SetTransformWeightImage [ $2ndweightimage($i) GetObject ] }

    $registration Run

    if { $usebetter > 0 && [ lindex $1stpass_sim $i ] > [ $registration GetLastSimilarity ] } { 
	puts "New similarity is worse then old similarity: reverting to old transform"
	set trn [ $txform($i) GetObject ]
	set tmplinear $oldlinear
	lappend 2ndpass_sim [ lindex $1stpass_sim $i ]
	puts $outf5  "[ lindex $1stpass_sim $i ]"
    } else { 
	$oldlinear Delete    
	set trn [ $registration GetTransformation ]
	set tmplinear [ ExtractLinearTransform [ $registration GetTransformation ] [ $2ndref_eig GetObject ] [ $2ndref_eig GetObject ] 9 ]
	lappend 2ndpass_sim [ $registration GetLastSimilarity ]
	puts $outf5  "[ $registration GetLastSimilarity ]"
    }

    
#   puts "New params: [ MotionDescription $tmplinear ]	"
    #puts "old sim: [ lindex $1stpass_sim $i ]"
    #puts "New sim: [ lindex $2ndpass_sim $i ]"

    #frame-to-frame displace; make own function
    $cog ComputeDisplacement $tmplinear [ $cog GetOutput ] $disparray 
    set framedisp 0 ; set refdisp 0 
    if { $i > 0 } { 
	set framedisp [ ComputeFrameToFrameDisp $disparray $olddisplist ]
	lappend frametoframelist $framedisp
    } else { 
	lappend frametoframelist 0
    }
    set refdisp [ ComputeFrameToRefDisp $disparray ]
    lappend frametoreflist $refdisp

    set olddisplist [ list [ $disparray GetComponent 0 0 ] [ $disparray GetComponent 0 1 ] [ $disparray GetComponent 0 2 ] ]

    puts $outf3 "${refdisp}\t${framedisp}"
    puts $outf2 "[ MotionDescription $tmplinear ]"
    set parlist($i) [ MotionDescription $tmplinear ]

    #reslice the images
    #$resl SetResliceTransform [ $registration GetTransformation ]
    $resl SetResliceTransform $trn
    $resl SetInput [ $originalimg($i) GetObject ]
    $resl Update

    set reslimg2($i) [ [ pxitclimage \#auto ] GetThisPointer ]
    $reslimg2($i) ShallowCopyImage [ $resl GetOutput ]

    #Print stuff to text files and screen; 
    set totaltime [ expr $totaltime + [ clock clicks  -milliseconds ]  -  $start ]
    
    $tmplinear Delete    
}

#append output images
set reslappnd1     [ vtkImageAppendComponents [ pxvtable::vnewobj ] ]
set reslappnd2     [ vtkImageAppendComponents [ pxvtable::vnewobj ] ]
set eigenappnd     [ vtkImageAppendComponents [ pxvtable::vnewobj ] ]
set trweightappnd  [ vtkImageAppendComponents [ pxvtable::vnewobj ] ]

for { set i 0 } { $i < $numframes } { incr i } {
    $reslappnd1 AddInput [ $reslimg1($i) GetObject ]
    $reslappnd2 AddInput [ $reslimg2($i) GetObject ]
    $eigenappnd AddInput [ $eigenimg($i) GetObject ]
    if { $useskullstrip } { $trweightappnd AddInput [ $2ndweightimage($i) GetObject ] }    
}

$reslappnd1 Update
$reslappnd2 Update
$eigenappnd Update
if { $useskullstrip } { $trweightappnd Update }
#-------------------------------------------------------

#Setup image writere
set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ] ]
$anaw SetImageHeader [ $ana(1) GetImageHeader ]
$anaw SetForceOutputFileFormat 2
#-------------------------------------------------------

#to treshold negatives from cubic inter
set thresholdF  [  vtkImageThreshold New ]
$thresholdF ThresholdBetween  0 1000000000
$thresholdF SetInValue    1
$thresholdF SetOutValue   0
$thresholdF SetReplaceOut 1
$thresholdF SetReplaceIn  0
#-------------------------------------------------------

#save 2nd mean image
set average [ vtkbisTimeSeriesStat [ pxvtable::vnewobj ] ]
$average SetMode 0
$average SetInput [ $reslappnd2 GetOutput ]
$average Update
$anaw SetInput [ $average GetOutput ]
$anaw Save  "${outname}_2ndmean.nii.gz"
$average Delete
#-------------------------------------------------------

#Calulate Mask for later use and constrast to noise
set finalmask [ CalculateFinalMask $2ndref_eig  ]
$anaw SetInput $finalmask
$anaw Save  "${outname}_finalmask.nii.gz"
#-------------------------------------------------------

#save 1stpass resliced image
if { $debug > 0 } { 
    $thresholdF SetInput  [ $reslappnd1 GetOutput ]
    $thresholdF Update
    $anaw SetInput [ $thresholdF GetOutput ]
    $anaw Save "${outname}_1stpass.nii.gz"
}
#-------------------------------------------------------

#1stpass  SNR
if { $debug > 0 } { set 1stpass_snr [ CalculateAndSaveSNR "${outname}_1stpass.snr" [ $thresholdF GetOutput ] $finalmask ] }
#-------------------------------------------------------

#save 2ndpass resliced image
$thresholdF SetInput  [ $reslappnd2 GetOutput ]
$thresholdF Update
$anaw SetInput [ $thresholdF GetOutput ]
$anaw Save "${outname}_2ndpass.nii.gz"
#-------------------------------------------------------

#2ndpass  SNR
set 2ndpass_snr [ CalculateAndSaveSNR "${outname}_2ndpass.snr" [ $thresholdF GetOutput ] $finalmask  ]
#-------------------------------------------------------x

set precensored [ [ pxitclimage \#auto ] GetThisPointer ]    
$precensored ShallowCopyImage  [ $thresholdF GetOutput ]

#create skip frame list to remove "outliers"
set snr_mean  [ ComputeMean $2ndpass_snr ] ; set snr_std  [ ComputeSTD $snr_mean  $2ndpass_snr ] 
set sim_mean  [ ComputeMean $2ndpass_sim ] ; set sim_std  [ ComputeSTD $sim_mean  $2ndpass_sim ] 
set disp_mean [ ComputeMean $frametoframelist ] ; set disp_std [ ComputeSTD $disp_mean $frametoframelist ]

foreach factor $factorlist {
puts "++++$factor"
    set skiplist [ list ] 
    set skiplist [ CreateSkipList $2ndpass_snr $skiplist $snr_mean $snr_std $factor ]
puts "1: $skiplist"
    set skiplist [ CreateSkipList $2ndpass_sim $skiplist $sim_mean $sim_std $factor ]
puts "2: $skiplist"
    set skiplist [ CreateSkipList $frametoframelist $skiplist $disp_mean $disp_std $factor ]
puts "3: $skiplist"
    set skipstring [ ConvertListToString $skiplist $numframes ]
    
    set skip_alg [ bis_imageremoveframes [pxvtable::vnewobj]]
    $skip_alg InitializeFromContainer 0 
    $skip_alg SetOptionValue unit frames
    $skip_alg SetOptionValue offset 1
    $skip_alg SetOptionValue framelist $skipstring
    $skip_alg SetInput $precensored
    $skip_alg SetOptionValue keep 0
    $skip_alg Execute
    
    [ $skip_alg GetOutput ] Save  "${outname}_censored_F${factor}.nii.gz"

    set outtmp [ open "${outname}_censored_F${factor}.par" w+ ]  
    set N [ llength $skiplist ] 

    for { set j 0 } { $j < $numframes } { incr j } {
	set val [ lsearch $skiplist $j ]
	if { $val<0 } {
	    puts $outtmp $parlist($j)
	}
    }
    close $outtmp

    itcl::delete object $skip_alg
}
#-------------------------------------------------------

#split 2ndpass image into indiv runs
for { set i 0 } { $i < $numinp } { incr i } {
    
    set f [ lindex $argv [ expr $i + 3 ] ]
    set ext [ file extension $f ]
    
    if { $ext == ".gz" } {
	set indivname "[ file root [ file root $f ] ]_${outname}"
    } else { 
	set indivname "[ file root $f ]_${outname}"
    }

    set startt [ lindex $nclist $i ]
    set stopt  [ expr [ lindex $nclist [ expr $i+1 ] ] -1 ]

    puts "--------   $indivname    from $startt to $stopt -------"

    #check dustin
    set skip_alg [ bis_imageremoveframes [pxvtable::vnewobj]]
    $skip_alg InitializeFromContainer 0 
    $skip_alg SetOptionValue unit frames
    $skip_alg SetOptionValue offset 1
    $skip_alg SetOptionValue framelist "$startt $stopt"    
    $skip_alg SetInput $precensored
    $skip_alg SetOptionValue keep 1
    $skip_alg Execute
    [ $skip_alg GetOutput ] Save "${indivname}.nii.gz"
    itcl::delete object $skip_alg

    set outtmp [ open "${indivname}.par" w+ ]  
    for { set jj $startt } { $jj <= $stopt } { incr jj } {
	puts $outtmp $parlist($jj)
    }
    close $outtmp 

    set tmpsnr [ lrange $2ndpass_snr $startt $stopt ]
    set tmpsim [ lrange $2ndpass_sim $startt $stopt ]
    set tmpframetoframelist [ lrange $frametoframelist $startt $stopt ]
    set numframes_run [ expr $stopt - $startt + 1]
puts $numframes_run
    foreach factor $factorlist {
puts "++++$factor"
	set outskip [ open "${indivname}_F${factor}.skip" w+ ]
	
	set skiplist [ list ]
	set skiplist [ CreateSkipList $tmpsnr $skiplist $snr_mean $snr_std $factor ]
puts "1: $skiplist"
	set skiplist [ CreateSkipList $tmpsim $skiplist $sim_mean $sim_std $factor ]
puts "2: $skiplist"
	set skiplist [ CreateSkipList $tmpframetoframelist $skiplist $disp_mean $disp_std $factor ]
puts "3: $skiplist"
	set skipstring [ ConvertListToString $skiplist $numframes_run ]
	
	puts $outskip $skipstring
    }
}
itcl::delete object $precensored
#-------------------------------------------------------

#save 2ndweight
if { $useskullstrip && $debug > 0 } {	
    $anaw SetInput [ $trweightappnd GetOutput ]
    $anaw Save "${outname}_trnweight.nii.gz"
}
#-------------------------------------------------------

#save eigvalue (edge) maps
if { $debug > 0 } {
    $anaw SetInput [ $eigenappnd GetOutput ]
    $anaw Save "${outname}_input.nii.gz"
}
#-------------------------------------------------------

#--------Deletep Object-------
for { set ii 1 } { $ii <= [ array size ana ] } { incr ii } {
    $ana($ii) Delete
}

$disparray Delete
$registration Delete
$resl Delete
$extr Delete

$reslappnd1    Delete
$reslappnd2    Delete
$eigenappnd    Delete
$trweightappnd Delete

$anaw Delete
$thresholdF Delete

itcl::delete object $tr_img
itcl::delete object $ref_img
itcl::delete object $wgt_img
itcl::delete object $ref_eig
itcl::delete object $2ndref_eig

for { set i 0 } { $i < $numframes } { incr i } {
    itcl::delete object $originalimg($i)
    itcl::delete object $eigenimg($i)
    itcl::delete object $txform($i)
    itcl::delete object $reslimg1($i)
    itcl::delete object $reslimg2($i)
    if { $useskullstrip } {
	itcl::delete object $2ndweightimage($i)
    }
}

puts "Done in $totaltime"

close $outf2
close $outf3
close $outf4
close $outf5


exit

