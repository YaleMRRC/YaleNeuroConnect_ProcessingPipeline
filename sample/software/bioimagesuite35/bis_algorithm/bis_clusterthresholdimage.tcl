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

package require bis_basethresholdimage 1.0
package require bis_thresholdimage 1.0

package provide bis_clusterthresholdimage 1.0

# -----------------------------------------------------------------------------------------
# threshold image
#

itcl::class bis_clusterthresholdimage {

    inherit bis_basethresholdimage

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Cluster Threshold" }
    public method UpdateInputsFromContainer { }

};


# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_clusterthresholdimage::Initialize { } {

    PrintDebug "bis_clusterthresholdimage::Initialize" 
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ clustersize "Cluster Threshold Value" "Cluster Size"  integer  100 { 0 100000000 }  4 }
	{ oneconnected  "Use 1-Connected Clustering (if off use 3x3x3 cube around voxel, if on using 6 neighbors of voxel)"  "1-Connected" boolean  1 { 0 1 }  -10 }
	{ outputclustno "Output Cluster Number" "Output Cluster Number"  boolean  0 { 0 1 }  7 }
	{ absolutevalue "Cluster Based on Absolute Value of input" "Absolute Value"  boolean  0 { 0 1 }  -12 }
	{ frame   "Frame to use when clustering" "Frame"  integer  1 { 0 100000000 }  11 }
    }

    set defaultsuffix { "_cthr" }
    
    set scriptname bis_clusterthresholdimage
    set completionstatus "Implementation needs work, interface is OK" 
    #document
    #
    set description "thresholds an image to generate a binary output using a specific threshold and clusters to a certain voxel size."
    set description2 "The output is a binary image with value = 100 where the original image had values above the threshold and zero elsewhere."
    set backwardcompatibility "Reimplemented from pxmat_clusterthresholdimage.tcl"
    

    $this InitializeBaseThresholdImage
}

# -----------------------------------------------------------------------------------------
# Update GUI
# -----------------------------------------------------------------------------------------
itcl::body bis_clusterthresholdimage::UpdateInputsFromContainer { } {


    bis_basethresholdimage::UpdateInputsFromContainer 

    # This happens when image has changed 
    set currentimage  [ $InputsArray(input_image) GetObject ]
    set d [ $currentimage GetImageSize ]

    $OptionsArray(clustersize) SetValueRange [ list 0 $d ]

    set r [ [ [ [ $currentimage GetImage ] GetPointData ] GetScalars ] GetRange ]
    set minr [ expr [ lindex $r 0 ] + 0.8 * [ lindex $r 1 ]]
    set maxr [ lindex $r 1 ]

    $OptionsArray(minth) SetValue $minr
    $OptionsArray(maxth) SetValue $maxr

}

# --------------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_clusterthresholdimage::Execute {  } {

    set lst [ $this ParseArgs ]
    set invalue  [ lindex $lst 0 ]
    set outvalue [ lindex $lst 1 ]
    set replin   [ lindex $lst 2 ] 
    set replout  [ lindex $lst 3 ]
    set dobinary [ lindex $lst 4 ]
    set minth         [ $OptionsArray(minth) GetValue ]
    set maxth         [ $OptionsArray(maxth) GetValue ]
    set clustsize     [ $OptionsArray(clustersize) GetValue ]
    set shownumber    [ $OptionsArray(outputclustno) GetValue ]

    #    set util [ vtkpxUtil New ]


    #$util SaveAnalyze 00_inp.hdr [ [ $this GetInput ] GetImage ] 0

    # ---------------------------------------------------------------------
    # First Threshold the Image as usual ....

    set frame [ expr [ $OptionsArray(frame) GetValue ] -1 ]
    set numc [ [ [ $this GetInput ] GetImage ] GetNumberOfScalarComponents ]

    set extr 0
    if { $numc > 1 } {
	if { $frame  <  0 } { set frame 0 } 
	if { $frame  >= $numc } { set frame [ expr $numc -1 ] }
	
	set extr [ vtkImageExtractComponents [ pxvtable::vnewobj ]]
	$extr SetInput [ [ $this GetInput ] GetImage ]
	$extr SetComponents $frame
	$extr Update
	set img [ $extr GetOutput ]
    } else {
	set img [ [ $this GetInput ] GetImage ]
    }

    
    set abs [ $OptionsArray(absolutevalue) GetValue ]
    set clusterThreshold [ vtknrImageCluster New ]
    if { $abs == 0 } {
	set thresholdF  [  vtkImageThreshold New ]
	$thresholdF ThresholdBetween  $minth $maxth
	$thresholdF SetInValue    100
	$thresholdF SetOutValue   0
	$thresholdF ReplaceOutOn
	$thresholdF ReplaceInOn
	$thresholdF SetInput $img
	$thresholdF SetOutputScalarTypeToInt
	SetFilterCallbacks $thresholdF "Thresholding image"
	$thresholdF Update
	$clusterThreshold SetInput [ $thresholdF GetOutput ] 
	$thresholdF Delete
	$clusterThreshold SetIntensityThreshold 50
    } else {
	$clusterThreshold SetIntensityThreshold $minth
	$clusterThreshold SetInput $img
    }

    $clusterThreshold SetOneConnected  [ $OptionsArray(oneconnected) GetValue ]
    SetFilterCallbacks $clusterThreshold "Clustering image $abs"
    $clusterThreshold Update
    
    set rr [ [ [ [ $clusterThreshold GetOutput ] GetPointData ] GetScalars ] GetRange ]
    pxtkprint "\nCluster Threshold: Cluster Size Range $rr\n"

    $OptionsArray(clustersize) SetValueRange [ list 0 [ lindex $rr 1 ] ]

    # Then Figure out the Threshold by size if need be
    set imageThreshold [ vtkImageThreshold New ]
    $imageThreshold SetInput [ $clusterThreshold GetOutput ]
    $imageThreshold ThresholdByUpper $clustsize
    SetFilterCallbacks $imageThreshold "Thresholding Clustered image"
    $imageThreshold ReplaceInOn
    $imageThreshold SetInValue $invalue 
    $imageThreshold ReplaceOutOn
    $imageThreshold SetOutValue 0


    #    puts stderr "Dobinary=$dobinary, shownumber=$shownumber "

    set math 0
    if { $shownumber == 1 || $dobinary == 0 } {
	set math [ vtkImageMathematics New ]
    }

    if { $shownumber == 1 } {
	$imageThreshold SetOutputScalarType [ [ $clusterThreshold GetClusterNumberImage ] GetScalarType  ]
	set tmp [ vtkImageData New ]
	$tmp ShallowCopy [ $clusterThreshold GetClusterNumberImage ]
	$clusterThreshold RenumberClusterImage $tmp [expr int($clustsize)]
	$math SetInput1 $tmp
	#	puts stderr "Math Input 1 = renumber cluster image = [ $tmp GetScalarType ]"
	$tmp Delete
    } elseif { $dobinary == 0 } {
	$imageThreshold SetOutputScalarType [ [ [ $this GetInput ] GetImage ] GetScalarType ]
	$math SetInput1 $img 
    }
    
    $imageThreshold Update
    if { $math !=0 } {
	$math SetInput2 [ $imageThreshold GetOutput ]
	#puts stderr "Math Input 2 = threshold image = [ [ $imageThreshold GetOutput ] GetScalarType ]"
	$math SetOperationToMultiply
	$math Update
	$imageThreshold Delete
	if { $dobinary != 0 } {   
	    pxtkconsole
	    set ncl [ [ [ [ $math GetOutput ] GetPointData ] GetScalars ] GetRange ]
	    pxtkprint "Total Number Of Clusters > $clustsize = [ lindex $ncl 1 ]\n"
	}
	set outfilter $math 
    } else {
	set outfilter $imageThreshold 
    }

    # ----------------------------------------------------------------------

    set outimage [ $this GetOutput ]
    $outimage ShallowCopyImage [ $outfilter GetOutput ] 
    $outimage CopyImageHeader  [ [ $this GetInput ] GetImageHeader ]
    [ $outimage GetImageHeader ] AddComment "[ $this GetCommandLine full ]" 0

    catch { $clusterThreshold Delete }
    catch { $outfilter Delete }
    catch { $extr Delete }
    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_clusterthresholdimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {

    set alg [bis_clusterthresholdimage [pxvtable::vnewobj]]
    $alg MainFunction 

}





