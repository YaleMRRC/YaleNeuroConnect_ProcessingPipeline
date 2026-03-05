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
package provide bis_computeoverlap 1.0

#
# compute overlap
#

itcl::class bis_computeoverlap {

    inherit bis_dualimagetransformationalgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Compute Overlap" }
    public method UpdateContainerWithOutput { } { }

    #
    #protected
    #
    protected method ComputeOverlap      { img1 img2 comment sigma xform } 
    protected method ComputeMultiOverlap { img1 img2 comment sigma xform } 

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_computeoverlap::Initialize { } {

    PrintDebug "bis_computeoverlap::Initialize" 
    set options {
	{ sigma     "gaussian standard deviation for smoothing binary image" "sigma"  real    1.0 { 0.0 10.0 }  0 }
	{ multioverlap "Treat Intensity levels as separate obejcts"  "Multi Overlap Mode"  boolean   0  { 0 1  }  1  } 
    	{ filename   "specify the filname for the output text file" "Text File Name" { filename writefile } "" { text { .txt } 50 } -30 }
	{ saveasimage "If on the output is an image instead of a text file"  "SaveImage"  boolean   0  { 0 1  }  -40  } 
    }

    set defaultsuffix { "_overlap" }
    
    set scriptname bis_computeoverlap
    set completionstatus "Done -- some issues with 4D images"

    #
    #document
    #

    set category    "Registration"
    set description  "computes overlap metrics of the pre-segmented structures after registration."
    set description2 "Computed metrics are overlap1 = 100*(intersection(V1,V2))/(Union(V1,V2)),overlap2 = 100* V2/avarage(V1,V2), where V1 is the pre-segmented structure in the reference image and V2 is the pre-segmented structure in the target image after transformation. If the transformation is not specified, metrics are computed without transformation. "
    set backwardcompatibility "Reimplemented from pxmat_computeoverlap.tcl"
    set authors "alark.joshi@yale.edu, hirohito.okuda@yale.edu, xenophon.papademetris.yale.edu"

    $this InitializeDualImageTransformationAlgorithm

    $this RenameInput 0 "Reference Objectmap" 1  
    $this RenameInput 1 "Target Objectmap" 2
    $this RenameInput 2 "Tranformation" 101


}

# -----------------------------------------------------------------------------------------
# duplicated from pxmat_computeoverlap
# -----------------------------------------------------------------------------------------
itcl::body bis_computeoverlap::ComputeOverlap { img1 img2 comment sigma xform } {

    #    puts stdout "Comment=$comment, $sigma, [ $xform GetClassName ]"

    set image(1) $img1
    set image(2) $img2

    scan [ $image(1) GetDimensions ] "%f %f %f" x1 y1 z1
    scan [ $image(2) GetDimensions ] "%f %f %f" x2 y2 z2

    if { $x1 < 2 || $x2  < 2 } { 
	set errormessage  "No Reference or Transform Image in Memory\n Cannot Compute Overlap!"
	return  ""
    }

    set range [ [ [ $image(1) GetPointData ] GetScalars ] GetRange ]
    
    set highthr  [ lindex $range 1 ]
    set lowthr   [ expr $highthr *0.5 ]
    set output ""

    for { set k 1 } { $k <= 2 } { incr k } {
	    
	set cast($k)  [  vtkImageCast [ pxvtable::vnewobj ] ]
	$cast($k) SetInput $image($k)
	$cast($k) SetOutputScalarTypeToFloat
	$cast($k) Update
	
	set prethreshold($k)  [  vtkImageThreshold [ pxvtable::vnewobj ] ]
	
	$prethreshold($k) SetInput [$cast($k)  GetOutput ]
	$prethreshold($k) ThresholdBetween  $lowthr $highthr
	$prethreshold($k) SetInValue    100
	$prethreshold($k) SetOutValue   0
	$prethreshold($k) ReplaceInOn
	$prethreshold($k) ReplaceOutOn
	$prethreshold($k) SetOutputScalarTypeToFloat
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
	$threshold($k) SetOutputScalarTypeToInt
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
    
    # vae == intersection 
    set vae [ [ [ [ $accumcompare1 GetOutput ] GetPointData ] GetScalars ] GetComponent 1 0 ]
    
    set overlap [ expr 100.0 * $vae / ( $va + $ve - $vae ) ]
    set overlap2 [ expr 100.0* $vae / ( 0.5 * ( $va + $ve )  ) ]
    
    if { $output == "" } {
	set output  "\#thr \t Va\t Ve\t Vae\t Overlap\t Overlap2 \t Sigma\n"
	$this PrintMessage $output
    }

    set line1 [ format "%.1f\t %.0f\t %.0f\t%.0f\t %.2f\t%.2f\t%.3f\n" $lowthr $va $ve $vae $overlap $overlap2 $sigma ]
    $this PrintMessage $line1

    set output  "${output}${line1}"

    for { set k 1 } { $k <= 2 } { incr k } {
	$threshold($k) Delete
	$accum($k) Delete
	$smooth($k) Delete
	$finalimage($k) Delete
    }
    
    $compare1 Delete
    $accumcompare1 Delete
    return $output
}

# -----------------------------------------------------------------------------------------
# duplicated from pxmat_computeoverlap
# -----------------------------------------------------------------------------------------
itcl::body bis_computeoverlap::ComputeMultiOverlap { img1 img2 comment sigma xform } {

    #    puts stdout "Comment=$comment, $sigma, [ $xform GetClassName ]"

    set image(1) $img1
    set image(2) $img2

    set ut [ vtkpxTransformationUtil New ]

    scan [ $image(1) GetDimensions ] "%f %f %f" x1 y1 z1
    scan [ $image(2) GetDimensions ] "%f %f %f" x2 y2 z2

    if { $x1 < 2 || $x2  < 2 } { 
	set errormessage  "No Reference or Transform Image in Memory\n Cannot Compute Overlap!"
	return  ""
    }

    set output ""

    set range [ [ [ $image(1) GetPointData ] GetScalars ] GetRange ]

    set low_thr [ expr [ lindex $range 0 ] + 1 ]
    set high_thr  [ lindex $range 1 ]

    # Step One Threshold both 
    
    for { set thr $low_thr } { $thr <=$high_thr } { set thr [ expr $thr +1.0 ] } {
	for { set k 1 } { $k <= 2 } { incr k } {
	    
	    set cast($k)  [  vtkImageCast New ]
	    $cast($k) SetInput $image($k)
	    $cast($k) SetOutputScalarTypeToFloat
	    $cast($k) Update

	    set prethreshold($k)  [  vtkImageThreshold New ]
	    
	    set low  $thr 
	    #[ expr $thr - 0.000001 ]
	    set high $thr 
	    #[ expr $thr + 0.000001 ]


	    #	    puts stdout "Thresholds $low:$high"
	    $prethreshold($k) SetInput [$cast($k)  GetOutput ]
	    $prethreshold($k) ThresholdBetween  $low $high
	    $prethreshold($k) SetInValue    100
	    $prethreshold($k) SetOutValue   0
	    $prethreshold($k) ReplaceInOn
	    $prethreshold($k) ReplaceOutOn
	    $prethreshold($k) SetOutputScalarTypeToFloat
	    $prethreshold($k) Update

	    $cast($k) Delete

	    set spa [ $image($k)  GetSpacing ]
	    
	    for { set i 0 } { $i <= 2 } { incr i } {
		set smsigma($i) [ expr $sigma / [ lindex $spa $i ]]
	    }
	    
	    set smooth($k)  [ vtkImageGaussianSmooth New ]  
	    $smooth($k) SetStandardDeviations $smsigma(0) $smsigma(1) $smsigma(2)
	    $smooth($k) SetInput [ $prethreshold($k) GetOutput ] 
	    $smooth($k) SetRadiusFactors 1.5 1.5 1.5
	    $smooth($k) Update
	    $prethreshold($k) Delete
	    
	    set threshold($k)  [  vtkImageThreshold New ]
	    
	    if { $k == 2 } {
		set resl [ vtkbisImageReslice New ]
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

	    #	    puts stdout "r=$r\n"

	    set lowr [ expr 0.5* ([lindex $r 0 ] + [ lindex $r 1 ]) ]
	    set highr [ lindex $r 1 ]
	    if { $highr == $lowr } {
		if { $highr == 0.0 } {
		    set lowr [ expr $lowr + 1.0 ]
		} else {
		    set lowr [ expr $lowr - 1.0 ]
		}
		set highr [ expr $lowr +1.0 ]

	    }
	    #	    puts stdout "New lowr:highr $lowr:$highr"
	    $threshold($k) ThresholdBetween  $lowr $highr
	    $threshold($k) SetInValue    1
	    $threshold($k) SetOutValue   0
	    $threshold($k) ReplaceInOn
	    $threshold($k) ReplaceOutOn
	    $threshold($k) SetOutputScalarTypeToUnsignedChar
	    $threshold($k) Update

	    set r2 [ lindex [ [ [ [ $threshold($k) GetOutput ] GetPointData ] GetScalars ] GetRange ] 1 ]
	    set finalimage($k) [ $threshold($k) GetOutput ]
		set accum($k)  [  vtkImageAccumulate New ]
	    
	    if { $r2 > 0 } {
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
	    } else {
		if { $k == 1 } {
		    set ve 0.0
		} else {
		    set va 0.0
		}
	    }
	}
	    
	set compare1 [ vtkImageMathematics New ] 
	$compare1 SetInput1 $finalimage(1)
	$compare1 SetInput2 $finalimage(2)
	$compare1 SetOperationToMultiply
	$compare1 Update
	
	set accumcompare1  [  vtkImageAccumulate New ]
	$accumcompare1 SetInput [ $compare1 GetOutput ]
	$accumcompare1 SetComponentExtent 0 1 0 0 0 0
	$accumcompare1 SetComponentOrigin 0 0 0 
	$accumcompare1 SetComponentSpacing 1.0 1.0 1.0
	$accumcompare1 Update
	
	# vae == intesection 
	set vae [ [ [ [ $accumcompare1 GetOutput ] GetPointData ] GetScalars ] GetComponent 1 0 ]
	
	if { $va ==0 && $ve == 0 } {
	    set overlap 0
	    set overlap2 0
	} else {
	    set overlap [ expr 100.0 * $vae / ( $va + $ve - $vae ) ]
	    set overlap2 [ expr 100.0* $vae / ( 0.5 * ( $va + $ve )  ) ]
	}
	
	if { $output == "" } {
	    set output  "\#thr \t Va\t Ve\t Vae\t Overlap\t Overlap2 \t Sigma\n"
	    $this PrintMessage $output
	}
	set line1 [ format "%.1f\t %.0f\t %.0f\t%.0f\t %.2f\t%.2f\t%.3f\n" $thr $va $ve $vae $overlap $overlap2 $sigma ]
	$this PrintMessage $line1

	set output  "${output}${line1}"
	
	for { set k 1 } { $k <= 2 } { incr k } {
	    $threshold($k) Delete
	    $accum($k) Delete
	    $smooth($k) Delete
		$finalimage($k) Delete
	}
	
	${compare1} Delete
	${accumcompare1} Delete
	
    }

    return $output
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_computeoverlap::Execute {  } {

    PrintDebug "bis_computeoverlap::Execute"

    set saveimage [  $OptionsArray(saveasimage)  GetValue ]

    if { $saveimage == 0 } {
	if { $guimode == "commandline" } {
	    if { [ $OptionsArray(filename) GetValue ] == "" } {
		set errormessage "Empty Output Filename (-filename) for computing overlaps"
		return 0
	    }
	}
    }
    
    set sigma   [ $OptionsArray(sigma) GetValue ]
    set ref    [ [ $this GetInput ] GetObject ]
    set trg    [ [ $this GetSecondInput ]  GetObject ]
    set xform  [ [  $this GetTransformation ]  GetObject ]

    set comment ""
    if { $guimode !="commandline" } {
	#	puts "GUIMODE = $guimode "
	pxtkconsole; 
	pxtkprint "\n-------------------------------------------------\n"
	pxtkprint "Computing Overlaps [ $this GetCommandLine short ]\n" 
	pxtkprint "-------------------------------------------------\n"
    }

    if { [  $OptionsArray(multioverlap) GetValue ] == 0 } {
	set output [ ComputeOverlap $ref $trg $comment $sigma $xform ]
    } else {
	set output [ ComputeMultiOverlap $ref $trg $comment $sigma $xform ]
    }
    

    if { $saveimage == 0 } { 
	if { [ $OptionsArray(filename) GetValue ] != "" } {
	    set fout [ open [ $OptionsArray(filename) GetValue ] w ]
	    puts $fout $output
	    close $fout
	    PrintMessage "Output saved in [ $OptionsArray(filename) GetValue ]\n"
	}
    } 
	
    set lines [ split $output "\n" ]
    set goodlines ""
    set max 0 

    for { set i 0 } { $i < [ llength $lines ] } { incr i } {
	set line [ lindex $lines $i ] 
	#	puts stdout "Line $i = $line"
	set n [ llength $line ]
	set m [ string range $line 0 0 ]
	if { $m != "\#"  && $n > 1 } {
	    lappend goodlines $line
	    if { $n > $max } {
		set max $n
	    }
	}
    }

    set img [ vtkImageData New ]
    $img SetDimensions [ llength $goodlines ] $max 1
    $img SetScalarTypeToFloat
    $img AllocateScalars
    
    set dat [ [ $img GetPointData ] GetScalars ]
    $dat FillComponent 0 -10000.0

    for { set i 0 } { $i < [ llength $goodlines ] } { incr i } {
	set line [ lindex $goodlines $i ]
	for { set j 0 } { $j < [ llength $line ] } { incr j } {
	    catch { $img SetScalarComponentFromDouble $i $j 0 0 [ lindex $line $j ]  }
	}
    }

    set outimage [ $this GetOutput ]
    $outimage ShallowCopyImage $img;     $img Delete
    $outimage CopyImageHeader [ [ $this GetInput ] GetImageHeader ]
    
    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment" 0
    [ $outimage GetImageHeader ] AddComment "Overlap Output\n$output\n" 0
    
    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_computeoverlap.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function
   

    set alg [bis_computeoverlap [pxvtable::vnewobj]]
    $alg MainFunction 
}

