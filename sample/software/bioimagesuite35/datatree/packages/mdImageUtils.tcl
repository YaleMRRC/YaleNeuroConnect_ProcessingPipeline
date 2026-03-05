#!/bin/sh
# the next line restarts using wish \
    exec wish "$0" "$@"

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

#Now we have access to tk from within this script

package provide mdImageUtils 1.0

#Add to the auto path the bioimagesuite dirs base and main
lappend auto_path [file dir [info script]]
package require pxitclchellypackages

# Require key packages
package require Itcl
package require Iwidgets

# C++ Extensions
package require vtkpxcontrib     1.2
package require vtknrcontrib 1.2

# Simple Naming package  [ pxvtable::vnewobj ]
package require pxvtable         1.0

# Call us ::mdImageUtil::SmoothImage { }

#set util [vtkClusterSignificance [pxvtable::vnewobj ] ]
#puts stderr "Util Created"
#$util Delete

namespace eval ::mdImageUtil { 


    # ------------------------------------------------------------------------
    #   Convert vtkImageData to pxitclimage using ref (pxitclimage) and prefix
    # ------------------------------------------------------------------------

    proc ProcessResultingImage { img ref prefix } {
	
	set thisnewobj  [ [ pxitclimage \#auto] GetThisPointer ]
	$thisnewobj CopyImageHeader [ $ref GetImageHeader ]
	$thisnewobj ShallowCopyImage $img
	
#	puts [ $ref cget -filename  ] 
	set dname [ file dirname [ $ref cget -filename  ] ]
	set tname [ file tail    [ $ref cget -filename  ] ]
	set newname [ file join $dname $prefix ]
	set newname "${newname}_${tname}"

	#make sure the filename is unique, so it doesn't overwrite anything
	set sufnum 1
	while {[file exists $newname]} {
	    set newroot [string trimright [file rootname $newname] ${sufnum}]
	    set newext [file extension $newname]
	    set newname "${newroot}${sufnum}${newext}"
	    incr sufnum
	}

	$thisnewobj configure -filename $newname
	return $thisnewobj
    }

    
    # --------------------------------------------------------------------

 
    # --------------------------------------------------------------------
    # Threshold image works with percentile values in the image
    # lower and upper are values 0.1..1.01 
    #    

    proc ThresholdImage { currentimage { lower 0.01 } { upper 1.01 } } {

	set range [ [ [ [ $currentimage GetImage ] GetPointData ] GetScalars ] GetRange ]
	set lv    [ lindex $range 0 ]
	set up    [ lindex $range 1 ]

	set thr1 [ expr $lv + $lower*($up-$lv) ]
	set thr2 [ expr $lv + $upper*($up-$lv) ]

	puts stderr "Input Range = $range .. input thresholds $lower, $upper, output = $thr1, $thr2"

	set thresholdF  [  vtkImageThreshold [ pxvtable::vnewobj ] ]
	$thresholdF ThresholdBetween  $thr1 $thr2 
	$thresholdF SetInValue    1
	$thresholdF SetOutValue   0
	$thresholdF ReplaceInOn
	$thresholdF ReplaceOutOn
	$thresholdF SetInput [ $currentimage GetImage ]
	$thresholdF SetOutputScalarTypeToFloat
	$thresholdF Update

	set results [ ::mdImageUtil::ProcessResultingImage [ $thresholdF GetOutput ] $currentimage "Thr" ] 	
	$thresholdF Delete
	return $results
    }

    proc threshold { image lowThr highThr } {

	set thresholdF  [  vtkImageThreshold [ pxvtable::vnewobj ] ]
	$thresholdF ThresholdBetween  $lowThr $highThr 
	$thresholdF SetInValue    1
	$thresholdF SetOutValue   0
	$thresholdF ReplaceInOn
	$thresholdF ReplaceOutOn
	$thresholdF SetInput [ $image GetImage ]
	$thresholdF SetOutputScalarTypeToFloat
	$thresholdF Update

	set results [ ::mdImageUtil::ProcessResultingImage [ $thresholdF GetOutput ] $image "Thr" ] 	
	$thresholdF Delete
	return $results
    }


    proc Erode { currentimage { kernelsize 3 }  } {
    
	set erode  [  vtkImageContinuousErode3D [ pxvtable::vnewobj ] ]
	$erode SetInput [ $currentimage GetImage ]
	$erode SetKernelSize $kernelsize $kernelsize $kernelsize
	$erode Update
	
	set results [ ::mdImageUtil::ProcessResultingImage [ $erode GetOutput ] $currentimage "Erod" ] 	
	$erode Delete
	return $results
    }



    proc SmoothImage { currentimage smoothingsigma } {

	set spa [ [ $currentimage GetImage ] GetSpacing ]
	
	for { set i 0 } { $i <= 2 } { incr i } {
	    set sigma($i) [ expr $smoothingsigma / [ lindex $spa $i ]]             
	}

	set smooth  [ vtkImageGaussianSmooth [ pxvtable::vnewobj ]  ]
	$smooth SetStandardDeviations $sigma(0) $sigma(1) $sigma(2)
	$smooth SetRadiusFactors [ expr round(6*$sigma(0)) ] [ expr round(6*$sigma(1)) ] [ expr round(6*$sigma(2)) ]
    	$smooth SetInput [ $currentimage GetImage ]
	$smooth Update

	set results [ ::mdImageUtil::ProcessResultingImage [ $smooth GetOutput ] $currentimage "Smooth" ] 	
	$smooth Delete
	return $results
    }

    # ------------------------------------------------------------------------------

    #    (in+shift)*scale

    proc ShiftScale { currentimage shift scale } {

	set scale  [ vtkImageShiftScale [ pxvtable::vnewobj ]  ]
    	$scale SetInput [ $currentimage GetImage ]
	$scale SetShift $shift
	$scale SetScale $scale
	$scale SetOutputScalarToFloat
	$scale Update

	set results [ ::mdImageUtil::ProcessResultingImage [ $scale GetOutput ] $currentimage "ShSc" ] 	
	$scale Delete
	return $results
    }

    # -----------------------------------------------------------------------------------------------------
    proc PropScale { image } {
	
	set highThreshold 10000
	set lowThreshold 40 
	set scale  [ vtkdsSpectUtil [ pxvtable::vnewobj ]  ]
	set mean [ $scale imageMean [ $image GetImage ] -1 ] 
	set mean [ $scale imageMean [ $image GetImage ] [ expr $mean/8 ] ]
	set results [ ::mdImageUtil::MultiplyByConstant $image [ expr 50.0/$mean ] ]	
	puts [ expr 50.0/$mean ]
	set mask [ ::mdImageUtil::threshold  $results $lowThreshold $highThreshold  ] 
	set results [ ::mdImageUtil::Multiply $results $mask ]
	$scale Delete
	set returnList [ list $mask $results ]
	return $returnList
    }

    proc Normalize { currentimage pxitclimgRef { threshold 0.05 } } {
    
	if {  [ $currentimage GetImageSize ]  ==  [ $pxitclimgRef GetImageSize ] } {

	    set diff [ vtkpxImageComputeNormalizedDifference [ pxvtable::vnewobj ]]
	    $diff SetInput  [ $pxitclimgRef GetImage ]
	    $diff SetInput2 [ $currentimage GetImage ]
	    $diff SetThreshold 0.2
	    $diff SetSigma     1.0
	    $diff SetPercentageThreshold $threshold
	    $diff Update

	    set results [ ::mdImageUtil::ProcessResultingImage [ $diff GetNormalizedSecondImage ] $currentimage "Normalized" ]
	    $diff Delete

	    return $results
	}
	puts stderr "Error Bad Dimensions!"
	return -1
    }


    # Feed in the ictal and the interictal unnormalized
    # -------------------------------------------------
    # (currentimage-pxitclimgRef)

    proc NormalizeDifference { currentimage pxitclimgRef { threshold 0.05} } {
    
	if {  [ $currentimage GetImageSize ]  ==  [ $pxitclimgRef GetImageSize ] } {

	    set diff [ vtkpxImageComputeNormalizedDifference [ pxvtable::vnewobj ]]
	    $diff SetInput  [ $pxitclimgRef GetImage ]
	    $diff SetInput2 [ $currentimage GetImage ]
	    $diff SetThreshold 0.2
	    $diff SetSigma     1.0
	    $diff SetPercentageThreshold $threshold
	    $diff Update

	    set results1 [ ::mdImageUtil::ProcessResultingImage [ $diff GetOutput ] $currentimage "NormDiff" ]
	    set results2 [ ::mdImageUtil::ProcessResultingImage [ $diff GetPercentageOutput ] $currentimage "PercDiff" ]
	    $diff Delete

	    return [ list $results1 $results2 ]
	}
	puts stderr "Error Bad Dimensions!"
	return -1
    }


    # ------------------------------------------------------------------------------

    proc Add { image1 image2 } {

	if {  [ $image1 GetImageSize ]  !=  [ $image2 GetImageSize ] } {
	    puts stderr "Error Bad Dimensions!"
	    return -1
	}
	    
	set cast1 [ vtkImageCast [ pxvtable::vnewobj ]]
	$cast1 SetInput  [ $image1 GetImage ]
	$cast1 SetOutputScalarTypeToFloat
	$cast1 Update
    
	set cast2 [ vtkImageCast [ pxvtable::vnewobj ]]
	$cast2 SetInput [ $image2 GetImage ]
	$cast2 SetOutputScalarTypeToFloat
	$cast2 Update
	
	set diff [ vtkImageMathematics [ pxvtable::vnewobj ]]
	$diff SetInput1  [ $cast1 GetOutput ]
	$diff SetInput2 [ $cast2 GetOutput ]
	$diff SetOperationToAdd
	$diff Update

	set results [ ::mdImageUtil::ProcessResultingImage [ $diff GetOutput ] $image1 "Sum" ]
	$diff Delete
	$cast2 Delete
	$cast1 Delete

	return $results
    }

    # -------------------------------------------------------------------------------------

    proc Multiply { image1 image2 } {

	if {  [ $image1 GetImageSize ]  !=  [ $image2 GetImageSize ] } {
	    puts stderr "Error Bad Dimensions!"
	    return -1
	}
	    
	set cast1 [ vtkImageCast [ pxvtable::vnewobj ]]
	$cast1 SetInput  [ $image1 GetImage ]
	$cast1 SetOutputScalarTypeToFloat
	$cast1 Update
    
	set cast2 [ vtkImageCast [ pxvtable::vnewobj ]]
	$cast2 SetInput [ $image2 GetImage ]
	$cast2 SetOutputScalarTypeToFloat
	$cast2 Update
	
	set diff [ vtkImageMathematics [ pxvtable::vnewobj ]]
	$diff SetInput1  [ $cast1 GetOutput ]
	$diff SetInput2 [ $cast2 GetOutput ]
	$diff SetOperationToMultiply
	$diff Update
	
	set results [ ::mdImageUtil::ProcessResultingImage [ $diff GetOutput ] $image1 "Product" ]
	$diff Delete
	$cast2 Delete
	$cast1 Delete

	return $results
    }


    proc MultiplyByConstant { currentimage const } {
	
	set cast1 [ vtkImageCast [ pxvtable::vnewobj ]]
	$cast1 SetInput  [ $currentimage GetImage ]
	$cast1 SetOutputScalarTypeToFloat
	$cast1 Update

	set prod [ vtkImageMathematics [ pxvtable::vnewobj ]]
	$prod SetInput1 [$cast1 GetOutput]
	$prod SetConstantK $const
	$prod SetOperationToMultiplyByK
	$prod Update
	set results [ ::mdImageUtil::ProcessResultingImage [ $prod GetOutput ] $currentimage "ProductK" ]
	$prod Delete
	return $results

    }


    proc Square { image1 } {
	
	set cast1 [ vtkImageCast [ pxvtable::vnewobj ]]
	$cast1 SetInput  [ $image1 GetImage ]
	$cast1 SetOutputScalarTypeToFloat
	$cast1 Update
	
	set squa [ vtkImageMathematics [ pxvtable::vnewobj ]]
	$squa SetInput1  [ $cast1 GetOutput ]
	$squa SetInput2 [ $cast1 GetOutput ]
	$squa SetOperationToMultiply
	$squa Update
	
	set results [ ::mdImageUtil::ProcessResultingImage [ $squa GetOutput ] $image1 "Squared" ]
	$squa Delete
	$cast1 Delete
	
	return $results
    }

    proc SquareRoot { image1 } {
	
	set cast1 [ vtkImageCast [ pxvtable::vnewobj ]]
	$cast1 SetInput  [ $image1 GetImage ]
	$cast1 SetOutputScalarTypeToFloat
	$cast1 Update
	
	set sqroot [ vtkImageMathematics [ pxvtable::vnewobj ]]
	$sqroot SetInput1  [ $cast1 GetOutput ]
	$sqroot SetOperationToSquareRoot
	$sqroot Update
	
	set results [ ::mdImageUtil::ProcessResultingImage [ $sqroot GetOutput ] $image1 "SqRoot" ]
	$sqroot Delete
	$cast1 Delete
	
	return $results
    }


   
    # -------------------------------------------------------------------------------------
    proc Subtract { image1 image2 } {

	# ---------------------
	# ( image1 - image2 )
	# ---------------------
	if {  [ $image1 GetImageSize ]  !=  [ $image2 GetImageSize ] } {
	    puts stderr "Error Bad Dimensions!"
	    return -1
	}
	    
	set cast1 [ vtkImageCast [ pxvtable::vnewobj ]]
	$cast1 SetInput  [ $image1 GetImage ]
	$cast1 SetOutputScalarTypeToFloat
	$cast1 Update
    
	set cast2 [ vtkImageCast [ pxvtable::vnewobj ]]
	$cast2 SetInput [ $image2 GetImage ]
	$cast2 SetOutputScalarTypeToFloat
	$cast2 Update
	
	set diff [ vtkImageMathematics [ pxvtable::vnewobj ]]
	$diff SetInput1  [ $cast1 GetOutput ]
	$diff SetInput2 [ $cast2 GetOutput ]
	$diff SetOperationToSubtract
	$diff Update

	set results [ ::mdImageUtil::ProcessResultingImage [ $diff GetOutput ] $image1 "Difference" ]
	$diff Delete
	$cast2 Delete
	$cast1 Delete

	return $results
    }

    # -------------------------------------------------------------------------------------
    # petimage/spectimage
    proc Ratio { spectimage petimage } {

	if {  [ $petimage GetImageSize ]  !=  [ $spectimage GetImageSize ] } {
	    puts stderr "Error Bad Dimensions!"
	    return -1
	}
	    
	set diff [ vtkpxImageComputeNormalizedRatio [ pxvtable::vnewobj ]]
	$diff SetInput  [ $spectimage GetImage ]
	$diff SetInput2 [ $petimage GetImage ]
	$diff SetThreshold 0.2
	$diff SetSigma     1.0
	$diff SetNormalizedThreshold 0.05
	$diff Update
	
	set results [ ::mdImageUtil::ProcessResultingImage [ $diff GetOutput ] $spectimage "Ratio_v_PET" ]
	$diff Delete
	return $results
    }

    proc AbsoluteValue { currentimage } {
	
	set absval [ vtkImageMathematics [ pxvtable::vnewobj ]]
	$absval SetInput1  [ $currentimage GetImage ]
	$absval SetOperationToAbsoluteValue
	$absval Update

	set results [ ::mdImageUtil::ProcessResultingImage [ $absval GetOutput ] $currentimage "AbsVal" ]
	$absval Delete
	return $results

    }

    proc mask { currentImage lowThreshold highThreshold } {
	
	set mask   [ ::mdImageUtil::threshold $currentImage $lowThreshold $highThreshold ]
	set output [ ::mdImageUtil::Multiply $mask $currentImage ]
	return $output
    }

    proc TmapToZscore { tmap dof scaleFactor } {
	
	
	set tm [ vtkpxComputeTmap [ pxvtable::vnewobj ] ]

	set img [ $tm TmapToZScoreConversion [ $tmap GetImage ] $dof $scaleFactor ]
        
	set results [ ::mdImageUtil::ProcessResultingImage $img  $tmap "Zscore" ]
	$img Delete
	$tm Delete
	return $results
    }

    proc PvalueToTscore { pvalue dof } {
	
	set Pvalue [ vtkpxMath [ pxvtable::vnewobj ] ]
	set tscore [ $Pvalue PvalueToTvalue $pvalue $dof ]
	return $tscore
    }

    #      Group v Group
    #      Mean1-Mean2/ (Sigma1+Sigma2)
    #
    #      Invidividual v Group
    #      (Image-Mean)/Sigma1

 proc ComputeIndividualVsGroup { currentimage STDInputImg numberofsubjects { MeanImg 0 } } {


	set results $currentimage
	set newresults 0
	

	puts stderr "Input Image = [ $results cget -filename ] range: [ [ [ [ $results GetImage ] GetPointData ] GetScalars ] GetRange ]"
	puts stderr "Input Sigma = [ $STDInputImg cget -filename ] range: [ [ [ [ $STDInputImg GetImage ] GetPointData ] GetScalars ] GetRange ]"

	if { $MeanImg !=0 } {
	    set results [ Subtract $currentimage $MeanImg ]
	}

	set math [ vtkpxComputeTmap [ pxvtable::vnewobj ]]
	$math SetInput [ $results GetImage ]
	$math SetInputStandardDeviation [ $STDInputImg GetImage ]
	$math SetNumberOfSamples1 $numberofsubjects
	$math SetNumberOfSamples2 1
	$math SetNumberOfInputs 1
	$math SetScaleFactor 1.0
	$math Update

	
	set newresults [ ::mdImageUtil::ProcessResultingImage [ $math GetOutput ] $currentimage "Ttest" ]
	$math Delete

#	$currentimage Save current.hdr
#	$STDInputImg Save std.hdr
#	$MeanImg Save mean.hdr

	if { $newresults !=0 } { 
	    itcl::delete object $results
	}

	return $newresults
    }

    proc calcHAI { hypoBlob } {

	set util [ vtkdsSpectUtil [ pxvtable::vnewobj ] ]
	$util HAI [ $hypoBlob GetImage ] 
	$util Delete
    }

    proc ComputeCluster { zscoreImage { expectedVoxPerCluster 0 } { expectedNumOfCluster 0 } { threshold 2.65 } { minClusterSize 125 } { mode 1 }  } {

	set clusterThreshold [ vtknrImageCluster [ pxvtable::vnewobj ] ]
	$clusterThreshold SetInput [ $zscoreImage GetImage ] 
	$clusterThreshold SetIntensityThreshold $threshold

	$clusterThreshold Update
	
	set clusterSize [ ::mdImageUtil::ProcessResultingImage [ $clusterThreshold GetOutput ] $zscoreImage "clusterSize" ]
	set clusterId   [ ::mdImageUtil::ProcessResultingImage [ $clusterThreshold GetClusterNumberImage ]  $zscoreImage "clusterId" ]
	set clusterId   [ ::mdImageUtil::mask $clusterId 0 100000 ]
	
	set mask [ ::mdImageUtil::threshold $clusterSize $minClusterSize 1000000 ]
	
	set clusterSize [ ::mdImageUtil::Multiply $clusterSize $mask ]
	set clusterId   [ ::mdImageUtil::Multiply $clusterId   $mask ]
	set bothBlobs   [ ::mdImageUtil::Multiply $zscoreImage $mask ]
	
	$clusterThreshold Delete
	
	if { $mode == 1 } { return $bothBlobs }
	    
	if { $mode == 3 } {
	    set singleBlob [ ::mdImageUtil::mask $bothBlobs -100 -0.01 ]
	    set util [ vtkdsSpectUtil [ pxvtable::vnewobj ] ]
	    $util HAI [ $singleBlob GetImage ]
	    $util Delete
	} else {
	    set singleBlob [ ::mdImageUtil::mask $bothBlobs 0.01 100 ]
	}
	
	return [ ::mdImageUtil::clusterStats $singleBlob $clusterSize $clusterId $expectedVoxPerCluster $expectedNumOfCluster ]
    }
     


    proc reselCount { image xFHWM yFHWM zFHWM } {
	
	set xDim 2/$xFHWM;set yDim 2/$yFHWM;set zDim 2/$zFHWM
	set util [ vtkdsSpectUtil [ pxvtable::vnewobj ] ]
	set componentArray [ $util reselCount [ $image GetImage ] ]
	
	set volume [ $componentArray GetComponent 0 0 ];
	set cube   [ $componentArray GetComponent 0 1 ]
	set xyFace [ $componentArray GetComponent 0 2 ]
	set yzFace [ $componentArray GetComponent 0 3 ]
	set xzFace [ $componentArray GetComponent 0 4 ]
	set xEdge  [ $componentArray GetComponent 0 5 ]
	set yEdge  [ $componentArray GetComponent 0 6 ]
	set zEdge  [ $componentArray GetComponent 0 7 ]
	$util Delete
	$componentArray Delete
		
	set outputList [ list ]
	lappend outputList [ expr $volume - $xEdge - $yEdge - $zEdge + $xyFace + $xzFace + $yzFace - $cube ]
	lappend outputList [ expr ($xEdge-$xyFace-$xzFace+$cube)*$xDim + ($yEdge-$xyFace-$yzFace+$cube)*$yDim + ($zEdge-$yzFace-$xzFace+$cube)*$zDim ]
	lappend outputList [ expr ($xyFace-$cube)*$xDim*$yDim + ($xzFace-$cube)*$xDim*$zDim + ($yzFace-$cube)*$zDim*$yDim ]
	lappend outputList [ expr $cube*$xDim*$yDim*$zDim ]
	
	return $outputList
    }
    
    proc eulerCharacteristicDensity { tscore sigLevel } {
	
	set tmp [ expr pow(1+$tscore*$tscore/13,-6) ]
	set outputList [ list ]
	lappend outputList $sigLevel 
	lappend outputList [ expr 0.2650*$tmp ]
	lappend outputList [ expr 0.1727*$tscore*$tmp ] 
	lappend outputList [ expr 0.1169*$tmp*(12*$tscore*$tscore/13-1) ]
	return $outputList
    }
	
	
     proc clusterStats { singleBlob clusterSize clusterId expectedVoxPerCluster expectedNumOfCluster } {
	 
	 set util [ vtkdsSpectUtil [ pxvtable::vnewobj ] ]
	 set clusterInfo [ $util ClusterImage [ $singleBlob GetImage ] [ $clusterId GetImage ] [ $clusterSize GetImage ] $expectedVoxPerCluster $expectedNumOfCluster ]
	 $util Delete
	 
	 set numComponents [ $clusterInfo GetNumberOfComponents ]
	 set numTuples [ $clusterInfo GetNumberOfTuples ]
	 set outputList [ list ]

	 for { set tupleCount 0 } { $tupleCount<$numTuples } { incr tupleCount } {
	     set tempList [ list ]
	     for { set compCount 0 } { $compCount<$numComponents } { incr compCount } {	  
		 lappend tempList [ $clusterInfo GetComponent $tupleCount $compCount ]
	     }
	     lappend outputList $tempList
	 }
	  return  [ lsort -increasing -index 1 -real $outputList ]
     }

    proc ComputeGroupVsGroup { mean1 sigma1 nsubjects1 mean2 sigma2 nsubjects2 } {

	set math [ vtkpxComputeTmap [ pxvtable::vnewobj ]]
	$math SetInput  [ $mean1 GetImage ]
	$math SetInput2 [ $mean2 GetImage ]
	$math SetInputStandardDeviation  [ $sigma1 GetImage ]
	$math SetInputStandardDeviation2 [ $sigma2 GetImage ]
	$math SetNumberOfSamples1 $nsubjects1
	$math SetNumberOfSamples2 $nsubjects2
	$math SetNumberOfInputs 2
	$math SetScaleFactor 1000.0
	$math Update
	
	set newresults [ ::mdImageUtil::ProcessResultingImage [ $math GetOutput ] $mean1 "Group_ttest" ]
	$math Delete

	return $newresults
    }
    
    #------------------------------------------------------------------------------------------
    #A couple procs to create a binary mask (or other piecewise mapped image) out of an ROI image
    proc InsertBump { map c1 val } {
	$map InsertNextTuple [ expr $c1 - 0.01  ] 0 0
	$map InsertNextTuple [ expr $c1 - 0.005 ] $val 0
	$map InsertNextTuple [ expr $c1 + 0.005 ] $val 0
	$map InsertNextTuple [ expr $c1 + 0.01  ] 0 0
    }
    
    proc ListMaskImage { currentimage roilist0 } {
	
	set map [ vtkFloatArray [ pxvtable::vnewobj ]]
	$map SetNumberOfComponents 3
	$map InsertNextTuple3 $x $y 0.0
	
	st roilist [ lsort $roilist0 ]
	
	for { set i 0 } { $i < [ llength $roilist ] } { incr i } {
	    InsertBump $map [ lindex $roilist $i ] 1
	}
	
	set sh  [ vtkpxImageAlgebra [ pxvtable::vnewobj ]  ]
	$sh SetInput [ $currentimage GetImage ]
	$sh SetMap $map
	$sh SetOutputScalarTypeToShort
	$sh Update

	set newresults [ ::mdImageUtil::ProcessResultingImage [ $sh GetOutput ] $currentimage "Mask" ]
	$sh Delete
	return $newresults
	
    }
    
    #------------------------------------------------------------------------------------------

}
    


    



