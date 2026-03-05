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






# 	$Id: pxmat_computeoverlap.tcl,v 1.1 2004/01/15 15:07:53 xenios Exp xenios $	

if { [ llength $argv ] < 2 } { 
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"

    puts stdout "$scriptname computes overlap metrics. overlap1 = 100*(V1 ^ V2)/(V1 U V2),overlap2 = 100* V2/Avarage(V1,V2)"
    puts stdout "Syntax: $scriptname reference_image target_image \[ sigma=1.0 \] \[ transformation \]"
    puts stdout "\t\t sigma=gaussian st. deviation for smoothing binary image, and transformation is optional mapping"
    puts stdout "\n"
    exit
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon


proc ComputeOverlap { img1 img2 comment sigma xform } {

    puts stdout "Comment=$comment, $sigma, [ $xform GetClassName ]"

    set image(1) $img1
    set image(2) $img2

    scan [ $image(1) GetDimensions ] "%f %f %f" x1 y1 z1
    scan [ $image(2) GetDimensions ] "%f %f %f" x2 y2 z2

    if { $x1 < 2 || $x2  < 2 } { 
	puts stderr  "No Reference or Transform Image in Memory\n Cannot Compute Overlap!"
	return  0
    }




    # Step One Threshold both 
    
    for { set k 1 } { $k <= 2 } { incr k } {

	set spa [ $image($k)  GetSpacing ]
	
	for { set i 0 } { $i <= 2 } { incr i } {
	    set smsigma($i) [ expr $sigma / [ lindex $spa $i ]]
	}

	set smooth($k)  [ vtkImageGaussianSmooth [ pxvtable::vnewobj ]  ]
	$smooth($k) SetStandardDeviations $smsigma(0) $smsigma(1) $smsigma(2)
	$smooth($k) SetInput $image($k)
	$smooth($k) SetRadiusFactors 1.5 1.5 1.5
	$smooth($k) Update

	if { $k == 1 } {
	    set r  [ [ [ [ $smooth($k) GetOutput ] GetPointData ] GetScalars ] GetRange ]
	    set low($k) [ expr  0.5*( [ lindex $r 0 ] + [ lindex $r 1 ]) ]
	    set high($k) [ expr  1 + [ lindex $r 1 ]]
	    puts stderr "Thresholding Image $k ($r) $low($k):$high($k)"
	    set threshold($k)  [  vtkImageThreshold [ pxvtable::vnewobj ] ]
	}

	if { $k == 2 } {
	    set resl [ vtkbisImageReslice [ pxvtable::vnewobj ]]
	    $resl SetInput [ $smooth($k)  GetOutput ]
	    $resl SetInformationInput [ $smooth(1) GetOutput ]
	    $resl SetInterpolationMode 1
	    $resl SetBackgroundLevel 0.0
	    $resl SetResliceTransform $xform
	    $resl Update

	    set r  [ [ [ [ $resl GetOutput ]  GetPointData ] GetScalars ] GetRange ]
	    set low($k) [ expr  0.5*( [ lindex $r 0 ] + [ lindex $r 1 ]) ]
	    set high($k) [ expr  1 + [ lindex $r 1 ]]
	    puts stderr "Thresholding Image $k ($r) $low($k):$high($k)"
	    set threshold($k)  [  vtkImageThreshold [ pxvtable::vnewobj ] ]
	    $threshold($k) SetInput [ $resl GetOutput ]
	    $resl Delete
	} else {
	    $threshold($k) SetInput [ $smooth($k) GetOutput ]
	}

	$threshold($k) ThresholdBetween  $low($k) $high($k)
	$threshold($k) SetInValue    1
	$threshold($k) SetOutValue   0
	$threshold($k) ReplaceInOn
	$threshold($k) ReplaceOutOn
	$threshold($k) SetOutputScalarTypeToUnsignedChar
	$threshold($k) Update

	set image($k) [ $threshold($k) GetOutput ]
	
	set accum($k)  [  vtkImageAccumulate [ pxvtable::vnewobj ] ]

	$accum($k) SetInput $image($k)
	$accum($k) SetComponentExtent 0 1 0 0 0 0
	$accum($k) SetComponentOrigin 0 0 0 
	$accum($k) SetComponentSpacing 1.0 1.0 1.0
	$accum($k) Update
	
	if { $k == 1 } {
	    set ve [ [ [ [ $accum($k) GetOutput ] GetPointData ] GetScalars ] GetComponent 1 0 ]
	} else {
	    set va [ [ [ [ $accum($k) GetOutput ] GetPointData ] GetScalars ] GetComponent 1 0 ]
	}
    }
    
    set compare1 [ vtkImageMathematics [ pxvtable::vnewobj ]]
    $compare1 SetInput1 $image(1)
    $compare1 SetInput2 $image(2)
    $compare1 SetOperationToMultiply
    $compare1 Update

    set accumcompare1  [  vtkImageAccumulate [ pxvtable::vnewobj ] ]
    $accumcompare1 SetInput [ $compare1 GetOutput ]
    $accumcompare1 SetComponentExtent 0 1 0 0 0 0
    $accumcompare1 SetComponentOrigin 0 0 0 
    $accumcompare1 SetComponentSpacing 1.0 1.0 1.0
    $accumcompare1 Update

    # vae == intesection 
    set vae [ [ [ [ $accumcompare1 GetOutput ] GetPointData ] GetScalars ] GetComponent 1 0 ]

    set overlap [ expr 100.0 * $vae / ( $va + $ve - $vae ) ]
    set overlap2 [ expr 100.0* $vae / ( 0.5 * ( $va + $ve )  ) ]

    set line1 [ format "Va:\t %d \t Ve:\t %d \t Vae:\t %d \t Overlap:\t %.2f \t Overlap2\t %.2f \t Sigma:\t %.3f " $va $ve $vae $overlap $overlap2 $sigma ]

    puts stdout  "$comment:OV\t  $line1"
    
    for { set k 1 } { $k <= 2 } { incr k } {
	$threshold($k) Delete
	$accum($k) Delete
    }
    
    ${compare1} Delete
    ${accumcompare1} Delete
    

    return 1
}

# -----------------------------------------------------------------------------------------------------------

proc ComputeMultiOverlap { img1 img2 comment sigma xform } {

    puts stdout "Comment=$comment, $sigma, [ $xform GetClassName ]"

    set image(1) $img1
    set image(2) $img2

    vtkpxTransformationUtil ut

    scan [ $image(1) GetDimensions ] "%f %f %f" x1 y1 z1
    scan [ $image(2) GetDimensions ] "%f %f %f" x2 y2 z2

    if { $x1 < 2 || $x2  < 2 } { 
	puts stderr  "No Reference or Transform Image in Memory\n Cannot Compute Overlap!"
	return  0
    }


    set range [ [ [ $image(1) GetPointData ] GetScalars ] GetRange ]

    set low_thr [ expr [ lindex $range 0 ] + 1 ]
    set high_thr  [ lindex $range 1 ]

    # Step One Threshold both 
    
    for { set thr $low_thr } { $thr <=$high_thr } { set thr [ expr $thr +1.0 ] } {

	for { set k 1 } { $k <= 2 } { incr k } {
	
	    set cast($k)  [  vtkImageCast [ pxvtable::vnewobj ] ]
	    $cast($k) SetInput $image($k)
	    $cast($k) SetOutputScalarTypeToFloat
	    $cast($k) Update

	    set prethreshold($k)  [  vtkImageThreshold [ pxvtable::vnewobj ] ]
	    
	    set low  [ expr $thr - 0.1 ]
	    set high [ expr $thr + 0.1 ]

	    $prethreshold($k) SetInput [$cast($k)  GetOutput ]
	    $prethreshold($k) ThresholdBetween  $low $high
	    $prethreshold($k) SetInValue    100
	    $prethreshold($k) SetOutValue   0
	    $prethreshold($k) ReplaceInOn
	    $prethreshold($k) ReplaceOutOn
	    $prethreshold($k) SetOutputScalarTypeToUnsignedChar
	    $prethreshold($k) Update

	    $cast($k) Delete

	    set spa [ $image($k)  GetSpacing ]
	    
	    for { set i 0 } { $i <= 2 } { incr i } {
		set smsigma($i) [ expr $sigma / [ lindex $spa $i ]]
	    }
	    
	    set smooth($k)  [ vtkImageGaussianSmooth [ pxvtable::vnewobj ]  ]
	    $smooth($k) SetStandardDeviations $smsigma(0) $smsigma(1) $smsigma(2)
	    $smooth($k) SetInput [ $prethreshold($k) GetOutput ] 
	    $smooth($k) SetRadiusFactors 1.5 1.5 1.5
	    $smooth($k) Update
	    $prethreshold($k) Delete
	    
	    set threshold($k)  [  vtkImageThreshold [ pxvtable::vnewobj ] ]

	    if { $k == 2 } {
		set resl [ vtkbisImageReslice [ pxvtable::vnewobj ]]
		$resl SetInput [ $smooth($k)  GetOutput ]
		$resl SetInformationInput [ $smooth(1) GetOutput ]
		$resl SetInterpolationMode 1
		$resl SetBackgroundLevel 0.0
		$resl SetResliceTransform $xform
		$resl Update
		$threshold($k) SetInput [ $resl GetOutput ]		
		$resl Delete
	    } else {
		$threshold($k) SetInput [ $smooth($k) GetOutput ]
	    }
	    

	    set r [ [ [ [ $threshold($k) GetInput ] GetPointData ] GetScalars ] GetRange ]
	    set lowr [ expr 0.5* ([lindex $r 0 ] + [ lindex $r 1 ]) ]
	    set highr [ lindex $r 1 ]
	    $threshold($k) ThresholdBetween  $lowr $highr
	    $threshold($k) SetInValue    1
	    $threshold($k) SetOutValue   0
	    $threshold($k) ReplaceInOn
	    $threshold($k) ReplaceOutOn
	    $threshold($k) SetOutputScalarTypeToUnsignedChar
	    $threshold($k) Update
	    
	    set finalimage($k) [ $threshold($k) GetOutput ]
	
	    set accum($k)  [  vtkImageAccumulate [ pxvtable::vnewobj ] ]
	    
	    $accum($k) SetInput $finalimage($k)
	    $accum($k) SetComponentExtent 0 1 0 0 0 0
	    $accum($k) SetComponentOrigin 0 0 0 
	    $accum($k) SetComponentSpacing 1.0 1.0 1.0
	    $accum($k) Update
	    
	    if { $k == 1 } {
		set ve [ [ [ [ $accum($k) GetOutput ] GetPointData ] GetScalars ] GetComponent 1 0 ]
	    } else {
		set va [ [ [ [ $accum($k) GetOutput ] GetPointData ] GetScalars ] GetComponent 1 0 ]
	    }
	}
	
	set compare1 [ vtkImageMathematics [ pxvtable::vnewobj ]]
	$compare1 SetInput1 $finalimage(1)
	$compare1 SetInput2 $finalimage(2)
	$compare1 SetOperationToMultiply
	$compare1 Update
	
	set accumcompare1  [  vtkImageAccumulate [ pxvtable::vnewobj ] ]
	$accumcompare1 SetInput [ $compare1 GetOutput ]
	$accumcompare1 SetComponentExtent 0 1 0 0 0 0
	$accumcompare1 SetComponentOrigin 0 0 0 
	$accumcompare1 SetComponentSpacing 1.0 1.0 1.0
	$accumcompare1 Update
	
	# vae == intesection 
	set vae [ [ [ [ $accumcompare1 GetOutput ] GetPointData ] GetScalars ] GetComponent 1 0 ]
	
	set overlap [ expr 100.0 * $vae / ( $va + $ve - $vae ) ]
	set overlap2 [ expr 100.0* $vae / ( 0.5 * ( $va + $ve )  ) ]

	set line1 "thr=$thr overlap=$overlap\n"
	catch { set line1 [ format "thr:%.1f\t Va:\t %d \t Ve:\t %d \t Vae:\t %d \t Overlap:\t %.2f \t Overlap2:\t %.2f \t Sigma:\t %.3f " $thr $va $ve $vae $overlap $overlap2 $sigma ] }
	
	puts stdout  "$comment:OV\t  $line1"
	
	for { set k 1 } { $k <= 2 } { incr k } {
	    $threshold($k) Delete
	    $accum($k) Delete
	    $smooth($k) Delete

	}
	
	${compare1} Delete
	${accumcompare1} Delete

	    
	
    }

    return 1
}

# -----------------------------------------------------------------------------------------------------------


#puts stdout " Number of Arguments = [ llength $argv ] "

set reference     [ lindex $argv 0 ]
set target        [ lindex $argv 1 ]
set sigma   1.0

if { [ llength $argv ]  > 2 } {
    set sigma [ lindex $argv 2 ]
}

set ana1 [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
$ana1 Load $reference

set ana2 [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
$ana2 Load $target

puts stdout "\nComputing Overlap"
puts stdout "\tLoaded image [ $ana1 GetFilePrefix ] dim [ [ $ana1 GetOutput ] GetDimensions ]"
puts stdout "\tLoaded image [ $ana2 GetFilePrefix ] dim [ [ $ana2 GetOutput ] GetDimensions ]"

set comment "[ file tail [ file rootname [ $ana1 GetFilePrefix ] ]]\t[ file tail [ file rootname [ $ana2 GetFilePrefix ] ]]"

if { [ llength $argv ] > 3 } {

    set fname [ lindex $argv 3 ]
    set ut [ vtkpxTransformationUtil [ pxvtable::vnewobj ]]
    set xform [ $ut LoadAbstractTransform $fname ]
    puts stderr "Transformation Loaded from $fname [ $xform GetClassName ]"
    set comment "[ file dirname $fname] \t [ file tail $fname ] \t ${comment}"
} else {
    set xform [ vtkIdentityTransform [ pxvtable::vnewobj ]]
    set comment "${comment}:identity"
}


set ref [ $ana1 GetOutput ]
set trg [ $ana2 GetOutput ]

if { $sigma > 0.0 } {
    ComputeOverlap $ref $trg $comment $sigma $xform
} else {
    ComputeMultiOverlap $ref $trg $comment [ expr abs($sigma) ] $xform
}


$ana1 Delete
$ana2 Delete
$xform Delete
catch { $ut Delete }

exit

