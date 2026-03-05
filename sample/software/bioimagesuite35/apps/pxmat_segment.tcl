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





# 	$Id: pxflipslices.tcl,v 1.1 2004/01/15 15:11:59 xenios Exp xenios $	

set num $argc 

if { $num < 2 } {
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "Syntax: $scriptname input numclasses \[ smoothness = 1.0 \] \[ maxsigmaratio = 0.05 \] \[ mrfiterations = 20 \] \[ outputname = \"\" \] "
    puts stdout "\t\tNumber of classes = number of tissue labels (background is a tissue label so add this)"
    puts stdout "\t\tSmoothness = spatial smoothness, is set to zero -- a faster algorithm is used"
    puts stdout "\t\tMaxSigmaRatio  = this constrains the ratio of the max standard deviation to the min standard deviation"
    puts stdout "\t\tIf Output Name is blank defaults are either input_quicksegm (smoothness=0.0) or input_segm "
    puts stdout "\n"
    exit 0
}

# ---------------------------------------------------------------------------------------------------------

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon


set name [ lindex $argv 0 ]
set numclasses [ ::pxappscommon::RestrictRange [ lindex $argv 1 ] 2 10 ]

set smoothness 1.0
if { [ llength $argv ] > 2 } {
    set smoothness [ ::pxappscommon::RestrictRange [ lindex $argv 2 ] 0.0 10.0 ]
}

set sigmaratio 0.05
if { [ llength $argv ] > 3 } {
    set sigmaratio [ ::pxappscommon::RestrictRange [ lindex $argv 3 ] 0.0 1.0 ]
}

set mrfiterations 20
if { [ llength $argv ] > 4 } {
    set mrfiterations [ ::pxappscommon::RestrictIntRange [ lindex $argv 4 ] 2 40 ]
}

set outputname ""
if { [ llength $argv ] > 4 } {
    set outputname [ lindex $argv 5 ]
}


# ---------------------------------------------------------------------------------------------------------

proc HistogramSegmentation { img numcl sigmaratio } {

    set segm [ vtkpxHistogramSegmentation [ pxvtable::vnewobj ]]
    $segm SetInput $img
    $segm SetNumberOfClasses $numcl
    $segm SetIterations 50
    $segm SetNumberOfBins 256
    $segm SetConvergence 0.05
    $segm SetSigma 0.05
    $segm GenerateLabelsOn
    $segm SetOutlierDetection 0
    $segm SetPreprocessingMode 0
    $segm SetDistributionModel 0
    $segm SetOutlierProbability 0
    $segm SetMaxSigmaRatio     $sigmaratio
    $segm Update

    set img [ vtkImageData [ pxvtable::vnewobj ]]
    $img ShallowCopy [ $segm GetOutput ]
    $segm Delete
    return $img
}

# ------------------------------------------------------------------------------------

proc MRFSegmentation { img numcl sigmaratio smoothness mrfiterations } {

    set segm [ vtkpxMRFSegmentation [ pxvtable::vnewobj ]]
    $segm SetInput $img
    $segm SetNumberOfClasses $numcl
    $segm SetIterations 50
    $segm SetNumberOfBins 256
    $segm SetConvergence 0.05
    $segm SetSigma 0.05
    $segm GenerateLabelsOn
    $segm SetOutlierDetection 0
    $segm SetPreprocessingMode 0
    $segm SetDistributionModel 0
    $segm SetOutlierProbability 0
    $segm SetMaxSigmaRatio     $sigmaratio
    $segm SetComputeBiasField 0
    $segm SetMRFIterations $mrfiterations
    $segm SetSmoothness $smoothness
    $segm Update

    set img [ vtkImageData [ pxvtable::vnewobj ]]
    $img ShallowCopy [ $segm GetOutput ]
    $segm Delete
    return $img
}





set ana [ vtkpxAnalyzeImageSource  [ pxvtable::vnewobj ]]
$ana Load $name
set or [ $ana GetOrientation ]
puts stdout "\nRead $name [ [ $ana GetOutput ] GetDimensions ] ori=$or "

set outimage 0

set fname $outputname

if { $smoothness == 0.0 } {
    set outimage [ HistogramSegmentation [ $ana GetOutput ]  $numclasses $sigmaratio ]
    if { $fname == "" } {
	set fname [ ::pxappscommon::GenOutputName $name quicksegm ]
    }
} else {
    set outimage [  MRFSegmentation [ $ana GetOutput ]  $numclasses $sigmaratio $smoothness $mrfiterations ]
    if { $fname == "" } {
	set fname [ ::pxappscommon::GenOutputName $name segm ]
    }
}


set ana2 [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]
$ana2 SetInput $outimage
$ana2 SetImageHeader [ $ana GetImageHeader ]

$ana2 Save $fname

puts stderr "Segmentation saved to $fname"

$ana2 Delete
$ana Delete
$outimage Delete

exit

