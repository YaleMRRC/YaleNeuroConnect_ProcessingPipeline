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

package provide bis_computejointhistogram 1.0
package require bis_dualimagealgorithm 1.0

itcl::class bis_computejointhistogram {

    inherit bis_dualimagealgorithm
    
    constructor { } {	 $this Initialize  }
    
    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Compute Joint Histogram" }
    #override parent function
    
    public method CheckInputObjects { }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_computejointhistogram::Initialize { } {

    PrintDebug "bis_computejointhistogram::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ numbins     "Number Of Bins"	"Number Of Bins"  int 64 { 2 1024 } 0 }
	{ usegpu   "Use GPU Implementation (if available)"  "Use GPU"  boolean   0  { 0 1  }  1  }
	{ weighted   "Compute Weighted  Histogram"  "Weighted"  boolean   0  { 0 1  }  1  }
	{ optimized   "Use Optimized GPU Implementation (if available)"  "Optimized"  boolean   0  { 0 1  }  2  }
    }

    set inputs { 
    	{ weight_image1 "Weight Image 1" pxitclimage "" 102}     
    	{ weight_image2 "Weight Image 2" pxitclimage "" 103}     
    }


    set defaultsuffix { "_computejointhistogram" }
    set scriptname bis_computejointhistogram
    set completionstatus "Done"
    
    #
    #document
    #
    
    set description "joint histogram."
    set description2 "computes joint histogram from two images"

    set backwardcompatibility ""
    set authors "xenophon.papademetris@yale.edu"

    $this InitializeDualImageAlgorithm
    
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_computejointhistogram::Execute {  } {
    PrintDebug "bis_computejointhistogram::Execute"
    

    
    set image1 [ $this GetInput ]
    set image2 [ $this GetSecondInput ]
    
    set img1  [ $image1 GetImage ]
    set img2  [ $image2 GetImage ] 

    set wgt1 [ [ $this GetInputObject weight_image1 ] GetObject ]
    set wgt2 [ [ $this GetInputObject weight_image2 ] GetObject ]

    set usegpu [ $OptionsArray(usegpu) GetValue ]
    set numbins [ $OptionsArray(numbins) GetValue ]
    set optimized [ $OptionsArray(optimized) GetValue ]
    set weighted [ $OptionsArray(weighted) GetValue ]

    set histo 0
    if { $usegpu > 0 } {
	catch { set histo  [ vtkbisCUDAJointHistogram New ] }
	if { $histo == 0 } { set usegpu 0 }
    }

    if { $usegpu == 0 } {
	catch { set histo  [ vtkpxJointHistogram New  ] }
	if { $histo ==0 } {
	    return 0
	}
    }

    if { [ $histo GetClassName ] == "vtkbisCUDAJointHistogram" } {
	puts stdout "+++++++++++++ Using GPU Accelerated Version "
    }

    if { $weighted > 0 } {
	puts stdout "Computing Dual Weighted!!!!"
	$histo CreateDualWeightedHistogram $img1 $numbins $img2 $numbins $wgt1 $wgt2
    } elseif { $usegpu == 0 } {
	$histo CreateHistogram $img1 $numbins $img2 $numbins
    } else {
	$histo CreateHistogram $img1 $numbins $img2 $numbins $optimized
    }

    set ex  [ $histo EntropyX ]
    set ey  [ $histo EntropyY ]
    set je  [ $histo JointEntropy ]
    set nmi [ $histo NormalizedMutualInformation ]
    puts stdout "Normalized Mutual Information = $nmi (ex=$ex, ey=$ey je=$je)"
    set ssd [ $histo SumsOfSquaredDifferences ]
    puts stdout "SSD = $ssd"
    set cc  [ $histo CrossCorrelation ]
    puts stdout "CC = $cc"
    set N [ $histo GetNumberOfSamples ]
    puts stdout "Num Samples = $N"

    set img [ $histo GetHistogramAsImage ]

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage $img
    $img Delete
    $histo Delete
    
    set comment [ format " [ $this GetCommandLine full ], nmi=$nmi" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

               
    return 1
}

# -----------------------------------------------------------------------------------------------------
itcl::body bis_computejointhistogram::CheckInputObjects { } {

    set image1 [ $this GetInput ]
    set image2 [ $this GetSecondInput ]
    
    set img1  [ $image1 GetImage ]
    set img2  [ $image2 GetImage ] 
    if { [ $img1 GetNumberOfPoints ] != [ $img2 GetNumberOfPoints ] } {
	set errormessage "Unequal Image Sizes\n Cannot Perform Compare $mode t-test!"
	return 0
    }
    
    
    return 1
    
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_computejointhistogram.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
	# this is essentially the main function

	set alg [bis_computejointhistogram [pxvtable::vnewobj]]
	$alg MainFunction 
}





