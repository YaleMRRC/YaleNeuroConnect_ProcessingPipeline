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

lappend auto_path [ file dirname [ info script ]]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]

package require bis_imagetoimagealgorithm 1.0
package provide bis_intsegment 1.0

#
# segment image
#

itcl::class bis_intsegment {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Intensity Segmentation" }
    #
    #protected
    #

    protected method HistogramSegmentation { img  } 
    protected method MRFSegmentation       { img  }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_intsegment::Initialize { } {

    PrintDebug "bis_intsegment::Initialize" 
    #name,description,type,object,filename(if applicable),priority (optional)
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ algorithm  "Algorithm to use for segmentation " "Algorithm" { listofvalues radiobuttons }  Clustering { Clustering MRF }   1}
	{ numclasses "Number of classes (tissue labels) including background " "Number of Classes"  int    3 { 2 10 }  3 }
	{ smoothness  "Spatial smoothness. If  algoirithm is set to clustering this is ignored " "Smoothness" real  1.0 { 0.01 10.0 }  2 }
	{ maxsigmaratio    "The ratio of the max standard deviation to the min standard deviation" "MaxSigmaRatio" real  0.05   { 0.0 1.0 }  -100 }
	{ iterations    "Number of iterations in Markov Random Field smoothness relaxation" "Iterations" int  20  { 2 40 }  2 }
	{ clustiterations    "Number of iterations in Clustering Step" "Initial Iterations" int  50  { 2 100 }  -101 }
	{ numbins    "Number of bins in Clustering Step" "Clustering Bins" int  256  { 16 1024 }  -102 }
	{ epsilon    "Convergence level (percentage of changed voxels)" "Epsilon" real  0.05  { 0.0 10.0 }  -103 }
    }

    set defaultsuffix { "_segm" }
    
    set scriptname bis_intsegment

    #
    #document
    #

    set category "Segmentation"
    set description "segment image."
    set description2 ""
    set backwardcompatibility "The default output filename was ****_quicksegm when smoothness is set 0. Now the default output file is always  **_segm. upon request."
    set authors "hirohito.okuda@yale.edu,xenophon.papademetris.yale.edu"

    $this InitializeImageToImageAlgorithm
}

itcl::body bis_intsegment::HistogramSegmentation { img  } {

    set numclasses     [ $OptionsArray(numclasses) GetValue ]
    set smoothness     [ $OptionsArray(smoothness) GetValue ]
    set maxsigmaratio  [ $OptionsArray(maxsigmaratio) GetValue ]
    set mrfiterations  [ $OptionsArray(iterations)    GetValue ]

    set segm [ vtkpxHistogramSegmentation [ pxvtable::vnewobj ]]
    $segm SetInput $img
    $segm SetNumberOfClasses $numclasses
    $segm SetIterations [ $OptionsArray(clustiterations) GetValue ]
    $segm SetNumberOfBins [ $OptionsArray(numbins) GetValue ]
    $segm SetConvergence [ $OptionsArray(epsilon) GetValue ]
    $segm SetSigma 0.05
    $segm GenerateLabelsOn
    $segm SetOutlierDetection 0
    $segm SetPreprocessingMode 0
    $segm SetDistributionModel 0
    $segm SetOutlierProbability 0
    $this SetFilterCallbacks $segm "Histogram Segmenting Image"
    $segm SetMaxSigmaRatio     $maxsigmaratio
    $segm Update

    set img [ vtkImageData [ pxvtable::vnewobj ]]
    $img ShallowCopy [ $segm GetOutput ]
    $segm Delete
    return $img
}

# ------------------------------------------------------------------------------------

itcl::body bis_intsegment::MRFSegmentation { img  } {

    set numclasses     [ $OptionsArray(numclasses) GetValue ]
    set smoothness     [ $OptionsArray(smoothness) GetValue ]
    set maxsigmaratio  [ $OptionsArray(maxsigmaratio) GetValue ]
    set mrfiterations  [ $OptionsArray(iterations)    GetValue ]

    set segm [ vtkpxMRFSegmentation [ pxvtable::vnewobj ]]
    $segm SetInput $img
    $segm SetNumberOfClasses $numclasses
    $segm SetIterations [ $OptionsArray(clustiterations) GetValue ]
    $segm SetNumberOfBins [ $OptionsArray(numbins) GetValue ]
    $segm SetConvergence [ $OptionsArray(epsilon) GetValue ]
    $segm SetSigma 0.05
    $segm GenerateLabelsOn
    $segm SetOutlierDetection 0
    $segm SetPreprocessingMode 0
    $segm SetDistributionModel 0
    $segm SetOutlierProbability 0
    $segm SetMaxSigmaRatio     $maxsigmaratio
    $segm SetComputeBiasField 0
    $segm SetMRFIterations $mrfiterations
    $segm SetSmoothness $smoothness
    $this SetFilterCallbacks $segm "MRF Segmenting Image"
    $segm Update

    set img [ vtkImageData [ pxvtable::vnewobj ]]
    $img ShallowCopy [ $segm GetOutput ]
    $segm Delete
    return $img
}


# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_intsegment::Execute {  } {

    PrintDebug "bis_intsegment::Execute"

    set algorithm      [ $OptionsArray(algorithm) GetValue ]

    set image_in      [ $this GetInput ] 

    if { $algorithm == "Clustering" } {
	set image_out [ HistogramSegmentation [ $image_in GetObject ]  ]
    } else {
	set image_out [  MRFSegmentation [$image_in GetObject ]  ]
    }

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage $image_out 

    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    [ $outimage GetImageHeader ] AddComment [ $this GetCommandLine full ] 
    return 1
}



# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_intsegment.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_intsegment [pxvtable::vnewobj]]
    $alg MainFunction 
}

