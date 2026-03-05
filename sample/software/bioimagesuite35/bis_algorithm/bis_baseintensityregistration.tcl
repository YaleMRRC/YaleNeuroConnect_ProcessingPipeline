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

package provide bis_baseintensityregistration 1.0
package require bis_algorithm 1.0
package require bis_common 1.0
package require bis_resliceimage 1.0
package require bis_colorblendimage 1.0


itcl::class bis_baseintensityregistration {

    inherit bis_algorithm

    constructor { } { }
    public method InitializeBaseIntensityRegistration { }

    # Get Info about Algorithm for use in GUI Container
    public method IsImageToImage { } { return 0 }
    public method SetContainer { cont }  { set containerobject $cont }
    public method GetContainer { }  { return $containerobject }
    public method UpdateInputsFromContainer { }
    public method UpdateContainerWithOutput { } 
    public method ProgressCallback   { filter lab }  

    # Input and Output Methods
    public method GetReferenceImage { }
    public method GetTransformImage { }
    public method GetOutputTransformation { }
    public method GetOutputImage { }
    public method GetInitialTransformation { }
    public method SetReferenceImage { img }
    public method SetTransformImage { img }
    public method SetInitialTransformation { img }

    # Set Filenames etc
    public method  UpdateOutputFilenames { } 
    public method CheckInputObjects { } 
    protected method SetCommonIntensityRegistrationOptions { regobj }


    # Generate Resliced Image
    public method GenerateReslicedTransformImage { }
    public method CreateWarpedImage { } 
    # Generate Method 
    public method GetExtension { } { return ".matr" }


    protected variable current_registration 0
    protected variable has_weights 1
    protected variable single_input 0

}


# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_baseintensityregistration::InitializeBaseIntensityRegistration { } {


    # This assumes that a derived class has done some work here already

    PrintDebug "bis_baseintensityregistration::Initialize" 

    set tmp $inputs
    set ismidline 0


    if { $single_input > 0 } {
	set inputs { 
	    { reference_image   "Input Image" pxitclimage  ""  0}    
	    { initial_transform "Initial Transformation" pxitcltransform  "" 100  }
	}
    } else {
	set inputs { 
	    { reference_image   "Reference Image" pxitclimage  ""  0}    
	    { transform_image   "Transform Image" pxitclimage  ""  1}     
	    { initial_transform "Initial Transformation" pxitcltransform  "" 100  }
	}
	
	if { $has_weights == 1 } {
	    set inputs {
		{ reference_image   "Reference Image" pxitclimage  ""  0}    
		{ transform_image   "Transform Image" pxitclimage  ""  1}     
		{ initial_transform "Initial Transformation" pxitcltransform  "" 100  }
		{ weight_image "Reference Weight Image" pxitclimage  "" 101  }
		{ weight_image2 "Transform Weight Image" pxitclimage  "" 102  }
	    }
	}
    }

    for { set i 0 } { $i < [ llength $tmp ] } { incr i } {
	lappend inputs [ lindex $tmp $i ]
    }
    
    #name,description,type,object,filename(if applicable),priority (optional)
    set tmp $outputs
    
    set outputs { 
	{ output_transform "Output Transformation"  pxitcltransform  "" }
	{ output_image   "Transformed Image" pxitclimage  ""  200 }
    }
    for { set i 0 } { $i < [ llength $tmp ] } { incr i } {
    	lappend outputs [ lindex $tmp $i ]
    }
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    #    lappend options [ list outname  "output filename root" "Output" string ""     { "" }  -1000 ]
    set myclassname [ string range  [ $this info class ] 2 end ]
    if {  $myclassname != "bis_nonlineardistortioncorrection"  } {
	lappend options [ list resolution      "resolution "                                   "Resolution (x Native)"     real  1.5   { 0.5 10.0 }  20 ]
	lappend options [ list stepsize       "step size "                                    "Step Size"       real  1.0   { 0.1 5.0 }  -151 ]
    } else {
	lappend options [ list resolution      "resolution "                                   "Resolution (x Native)"     real  2.0   { 0.5 10.0 }  20 ]
	lappend options [ list stepsize       "step size "                                    "Step Size"       real  3.0   { 0.1 5.0 }  -151 ]
    }

    lappend options [ list numberoflevels  "number of multiresolution levels"          "Number of Levels"     int   3    { 1  5 } 2 ]
    lappend options [ list metric  "Similarity Metric"   "Metric"  listofvalues  "NMI"    { SSD CC MI NMI JE }  -10  ]
    lappend options [ list iterations      "Number of iterations "                                   "Number of Iterations"     int   15    { 1     50 }  -100 ]
    lappend options [ list resolutionrate  "Rate at which to decrease the resolution"   "Resolution Rate"  real   2    { 1.05 3.0 } -101 ]
    lappend options [ list  autonormalize   "Autonormalize Intensities (i.e. staturate between 1% and 99% of intensity range)"                                 "Auto Normalize"  boolean   1     { 0 1  }  -102  ]
    lappend options [ list optimization    "Optimization Method"          "OptMethod"   listofvalues   default { default "SlowClimb" "GradientDescent" "ConjugateGradient" "Hybrid" }  -103 ]
    lappend options [ list numberofbins    "Number of bins for the joint histogram"          "Number of Bins"     int   64    { 32  1024 } -104 ]

    lappend options [ list numberofsteps    "Number of steps/level for the optimization"          "Number Of Steps"     int   1    { 1 5 } -150 ]
    lappend options [ list guiautosave       "AutoSave Result" "Autosave"  boolean  1 { 0 1 }  99 ]
    lappend options [ list reslimage   "Output a resliced image, or  a red-green blend image, or no  resliced image" "Resliced Image"  listofvalues Resliced  { Resliced ColorBlend }  200 ]
    lappend options [ list usegpu   "Use GPU Implementation (if available)"  "Use GPU"  boolean 1  { 0 1  }  -500  ]
    lappend options [ list gputouse "Select which GPU to use, default =-1 (fastest) " "GPU to use" int -1 { 0 1 }  -502 ]
    lappend options [ list threadmode "GPU Thread Mode " "GPU ThreadMode" int 3 { 0 4 }  -501 ]

    if { $has_weights == 1 } {
	lappend options [ list  useweightimage  "Weighted Registrations (0=none,1=ref only,2=both ref and target weights)"  "Num Weight Images:"  listofvalues  0     { 0 1 2  }  -10  ]
    }

    
    if { $defaultsuffix == "" } {
	set defaultsuffix { "_xform" }
    }


    set category    "Registration"
    
    if { $authors == "" } {
	set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu."
    }

    $this AddDefaultOptions
}



# ----------------------------------------------------------
#
#  Input/Output Utility Stuff
#
# ----------------------------------------------------------

itcl::body bis_baseintensityregistration::SetReferenceImage  { img } {
    #    puts stderr "I am here $img"
    $this SetInputObject reference_image $img
}

itcl::body bis_baseintensityregistration::SetTransformImage  { img } {
    if { $single_input == 0 } {
	$this SetInputObject transform_image $img
    }
}

itcl::body bis_baseintensityregistration::SetInitialTransformation  { tr } {
    $this SetInputObject initial_transform $tr
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

itcl::body bis_baseintensityregistration::GetReferenceImage  { } {
    return [ $this GetInputObject reference_image ]
}

itcl::body bis_baseintensityregistration::GetTransformImage  { } {

    if { $single_input == 0 } {
	return [ $this GetInputObject transform_image ]
    } 
    return 0
}

itcl::body bis_baseintensityregistration::GetOutputTransformation  { } {
    return [ $this GetOutputObject output_transform ]
}

itcl::body bis_baseintensityregistration::GetOutputImage  { } {
    return [ $this GetOutputObject output_image ]
}

itcl::body bis_baseintensityregistration::GetInitialTransformation  {  } {
    return [ $this GetInputObject initial_transform ]
}

# ------------------------------------------------------------------------------------
#        Container Stuff 
# ------------------------------------------------------------------------------------

itcl::body bis_baseintensityregistration::ProgressCallback   { filter lab }  {

    if { $current_registration == 0 } {
	return 0
    }

    ::bis_algorithm::ProgressCallback $filter $lab

    set t [ string trim [ $current_registration GetOutputStatus ] ]
    puts  stderr "$t"

}

itcl::body bis_baseintensityregistration::UpdateInputsFromContainer { } {

    if { $containerobject == 0 } {    
	return
    }

#    puts stderr "Updating Base Intensity Reg"

    $this SetTransformImage [ $containerobject GetTargetImage ] 
    $this SetReferenceImage [ $containerobject GetReferenceImage ] 
    $this SetInitialTransformation [ $containerobject GetTransformation ] 
    [ $this GetOutputTransformation ] configure -filename ""

#    puts stderr "\n\n --------------------------------------\n Updating $this"
#    puts stderr "[ [ $this GetReferenceImage  ] GetDescription ]"
#    puts stderr "[ [ $this GetTransformImage  ] GetDescription ]"
#    puts stderr "[ [ $this GetInitialTransformation  ] GetDescription ]"

    $this UpdateOutputFilenames
#    puts stderr "\n"

    return

}

itcl::body bis_baseintensityregistration::UpdateContainerWithOutput { } {

    # Reslice on the fly and update viewer ......................

    if { $current_registration != 0 } {
	return 0
    }


    set img  [ $this GenerateReslicedTransformImage ] 
    if { $img == 0 } {
	return 0
    }

#    PrintDebug "In Update Container With Output $this, $img [ $img GetDescription ]\n"
#    puts stderr "In Update Container With Output $this, $img [ $img GetDescription ]\n"

    set autosave [ $this GetOptionValue guiautosave ]

    if { $autosave > 0 } {
	$OutputsArray(output_transform) SaveObject
    }
    
    if { $containerobject == 0 } {
	if { $bis_viewer !=0 } {
	    $bis_viewer SetImage $img
	}  elseif { $vtk_viewer !=0 } {
	    $vtk_viewer SetImage [ $img GetImage ] [ $img GetOrientation ]
	} 
    } else {
	PrintDebug "Calling Container ($this, $containerobject) SetResultsFromObject" 
	$containerobject SetResultsFromObject $img $this
	$containerobject SetTransformationFromObject [ $this GetOutputTransformation ] $this
    }

    itcl::delete obj $img

}

# --------------------------------------------------------------------------------------------

itcl::body bis_baseintensityregistration::UpdateOutputFilenames { } {


    set f1 [ [ $this GetOutputTransformation ] cget -filename ]

    if { [ string length $f1 ] > 1 } {
	return 1
    }

    set f(0) [ $InputsArray(reference_image) GetFileName ]
    if { $single_input == 0 } {
	set f(1) [ $InputsArray(transform_image) GetFileName ]
    } else {
	set f(1) "self"
    }
    
    for { set i 0 } { $i <= 1 } { incr i } {
	set l($i) [ ::bis_common::SplitFileNameGZ $f($i) ]
	set f($i) [ file tail [ lindex $l($i) 0 ] ]
    }
    
    set fname [ file join [ file dirname $f(0) ] "$f(0)_$f(1)" ]
    
#    puts stdout "\n suffixlist = $defaultsuffix"
    set outlist [ $this CreateDefaultOutputFileList $fname ]
    set force 0;    if { $guimode == "managed" } {	set force 1    }    

#    puts stdout "\n suffixlist = $defaultsuffix"
#    puts stdout "\nxformname = [ lindex $outlist 0 ][ $this GetExtension ]" 
 
    $OutputsArray(output_transform) SetFileName "[ lindex $outlist 0 ][ $this GetExtension ]" $force

    return 1
}


itcl::body bis_baseintensityregistration::CheckInputObjects { } {


    set image_in    [ $this GetReferenceImage ]
    set d [ $image_in GetImageSize ]

    if { $d < 2 } {
	return 0
    }

    if { $single_input == 0 } {
	set image_in    [ $this GetTransformImage ]
	set d [ $image_in GetImageSize ]
	
	if { $d < 2 } {
	    return 0
	}
    }

    return 1

}

itcl::body bis_baseintensityregistration::CreateWarpedImage { } {

    set reslice_alg [bis_resliceimage [pxvtable::vnewobj]]
    $reslice_alg InitializeFromContainer 0
    $reslice_alg SetInput [ $this GetReferenceImage ] 
    if { $single_input == 1 } {
	$reslice_alg SetSecondInput [ $this GetReferenceImage ] 
    } else {
	$reslice_alg SetSecondInput [ $this GetTransformImage ] 
    }
    $reslice_alg SetTransformation [ $this GetOutputTransformation ] 
    $reslice_alg Execute

    [ $this GetOutputImage ] ShallowCopy [ $reslice_alg GetOutput ]
    itcl::delete obj $reslice_alg
}

itcl::body bis_baseintensityregistration::GenerateReslicedTransformImage { } {

    set d [ $this CheckInputObjects ]
    if { $d == 0 } {
	return 0
    }

    if { [ $OptionsArray(reslimage) GetValue ] == "Resliced" } {
	set reslice_alg [bis_resliceimage [pxvtable::vnewobj]]
    } else {
	set reslice_alg [bis_colorblendimage [pxvtable::vnewobj]]
    }
    $reslice_alg InitializeFromContainer 0
    $reslice_alg SetInput [ $this GetReferenceImage ] 
    if { $single_input == 1 } {
	$reslice_alg SetSecondInput [ $this GetReferenceImage ] 
    } else {
	$reslice_alg SetSecondInput [ $this GetTransformImage ] 
    }
    $reslice_alg SetTransformation [ $this GetOutputTransformation ] 
    $reslice_alg Execute

    set img [ [ pxitclimage \#auto ] GetThisPointer ]
    $img ShallowCopy [ $reslice_alg GetOutputObject output_image ]

    itcl::delete obj $reslice_alg 
    return $img
}

itcl::body bis_baseintensityregistration::SetCommonIntensityRegistrationOptions { regobj } {

    set image1    [ $this GetReferenceImage  ]
    if { $single_input == 0 } {
	set image2    [ $this GetTransformImage ]
    }

    set resolution     [ $OptionsArray(resolution) GetValue ]
    set iterations     [ $OptionsArray(iterations) GetValue ]
    set numlevels     [ $OptionsArray(numberoflevels) GetValue ]

    set numbins        [ $OptionsArray(numberofbins) GetValue ]
    set numsteps       [ $OptionsArray(numberofsteps) GetValue ]
    set optmethod      [ $OptionsArray(optimization) GetValue ]
    set resolrate      [ $OptionsArray(resolutionrate) GetValue ]
    set metric         [ $OptionsArray(metric) GetValue ]
    set stepsize       [ $OptionsArray(stepsize) GetValue ]
    set autonormalize  [ $OptionsArray(autonormalize) GetValue ]


    if { $has_weights == 1 } {
	set useweights     [ $OptionsArray(useweightimage) GetValue ]
	puts stdout "UseWeights=$useweights"

	
	if { $useweights > 0 } {
	    #	puts stderr "Using Weight Image"
	    $regobj SetReferenceWeightImage [ [ $this GetInputObject weight_image  ] GetImage ]
	    if { $useweights > 1 } {
		$regobj SetTransformWeightImage [ [ $this GetInputObject weight_image2  ] GetImage ]
	    }
	}
    }

    $regobj SetResolution $resolution 
    $regobj SetNumberOfIterations $iterations 
    $regobj SetNumberOfLevels $numlevels
    $regobj SetNumberOfBins  $numbins
    $regobj SetNumberOfSteps  $numsteps


    

    $regobj SetOptimizationMethodToDefault
    
    puts stdout "Optmethod $optmethod [ $regobj GetClassName ]"

    switch -exact $optmethod {
	"SlowClimb" {  $regobj SetOptimizationMethodToSlowClimb }
	"GradientDescent" {  $regobj SetOptimizationMethodToGradientDescent }
	"ConjugateGradient" {  $regobj SetOptimizationMethodToConjugateGradient }
	"Hybrid" {  $regobj SetOptimizationMethodToHybrid }
    }

    $regobj SetResolutionRate $resolrate

    $regobj SetSimilarityMeasureToNormalizedMutualInformation 
    switch -exact $metric { 
	"SSD" { $regobj SetSimilarityMeasureToSumofSquaredDifferences } 
	"CC" { $regobj SetSimilarityMeasureToCorrelation } 
	"MI" { $regobj SetSimilarityMeasureToMutualInformation } 
	"JE" { $regobj SetSimilarityMeasureToJointEntropy } 

    }

    puts stdout "Metric set to [ $regobj GetSimilarityMeasure ], $metric "

    $regobj SetStepSize       $stepsize
    $regobj SetAutoNormalizeIntensities $autonormalize

    if { $single_input == 1 } {
	puts stdout "MIDLINE\n\n"
	$regobj SetReferenceImage [ $image1 GetObject ]
	$regobj SetTransformImage [ $image1 GetObject ]
	$regobj SetReferenceOrientation [$image1 GetOrientation]
	$regobj SetTransformOrientation [$image1 GetOrientation]
    } else {
	$regobj SetReferenceImage [ $image1 GetObject ]
	$regobj SetTransformImage [ $image2 GetObject ]
	$regobj SetReferenceOrientation [$image1 GetOrientation]
	$regobj SetTransformOrientation [$image2 GetOrientation]
    }


    if { [ $OptionsArray(usegpu) GetValue ] > 0 } {
    set gpuindex [ $OptionsArray(gputouse) GetValue ]
    set dv 0
    catch { 
	set dv [ vtkbisCUDAUtil New ]
    }
    if { $dv > 0 } {
	set gpuindex [ $dv SelectDevice $gpuindex ]
	$dv Delete
	puts stdout "\n\n Using GPU = $gpuindex\n\n"
	$OptionsArray(gputouse) SetValue $gpuindex
    } else {
	puts stdout "No CUDA Capability detected"
    }
    }
    
    return 1
}


