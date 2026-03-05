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





# 	$Id: pxmat_computesimilarity.tcl,v 1.1 2004/01/15 15:11:23 xenios Exp xenios $	



set argc [ llength $argv ]

if { $argc != 3 && $argc != 8 } {
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"

    puts stdout "$scriptname is a script that prints the image similarity after a transform and optionally point distances"
    puts stdout "Syntax: $scriptname image1 image2 transformation \[ pointset1.vtk \] \[ pointset2.vtk \] \[ temperature \] \[ numpoints \] \[ matchmode  \]"
    puts stdout "\t\t matchmode = 0 = ICP, 1=Mixture, 2=RPM (Use 0 for nearest neighbor), temperature is used if matchmode !=0, number of points = number of points to use for distance computation"
    puts stdout "\n"
    exit
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon



vtkpxAnalyzeImageSource ana1
ana1 Load [ lindex $argv 0 ]

vtkpxAnalyzeImageSource ana2
ana2 Load [ lindex $argv 1 ]


vtkpxTransformationUtil ut
set trn [ ut LoadAbstractTransform [ lindex $argv 2 ]]


puts stderr "Image 1 Loaded from [ lindex $argv 0 ] dim = [ [ ana1 GetOutput ] GetDimensions ] vox = [ [ ana1 GetOutput ] GetSpacing ]"
puts stderr "Image 2 Loaded from [ lindex $argv 1 ] dim = [ [ ana2 GetOutput ] GetDimensions ] vox = [ [ ana2 GetOutput ] GetSpacing ]"
puts stderr "Transformation loaded from [ lindex $argv 2 ],  [ $trn GetClassName ]"


if { $argc == 8 } {
    vtkPolyDataReader p1
    p1 SetFileName [ lindex $argv 3 ]
    p1 Update

    vtkPolyDataReader p2
    p2 SetFileName [ lindex $argv 4 ]
    p2 Update

    set sur(0) [ p1 GetOutput ]
    set nam(0) [ lindex $argv 0 ]
    set sur(1) [ p2 GetOutput ]
    set nam(1) [ lindex $argv 1 ]

    set temperature [ lindex $argv 5 ]
    set numpoints [ lindex $argv 6 ]
    set matchmode [ lindex $argv 7 ]

    puts stderr "Surface 1  [ file tail $nam(0) ] pts = [ $sur(0) GetNumberOfPoints ]"
    puts stderr "Surface 2  [ file tail $nam(1) ] pts = [ $sur(1) GetNumberOfPoints ]"
    puts stderr "Temperature = $temperature, numpoints=$numpoints"
}


set reg [ vtkpxRegistration [ pxvtable::vnewobj ]]
set current_transform $trn
set image_ref [ ana1 GetOutput ]
set image_trn [ ana2 GetOutput ]


set image_ref_short [vtkImageData [pxvtable::vnewobj]]
set image_trn_short [vtkImageData [pxvtable::vnewobj]]

 
set reg_measures [ list "Joint Entropy" "CR" "Gradient Correlation" "Mutual Information" "NMI" "Sum of Sq Diff" "Correlation ratio C(X|Y)" "Correlation ratio C(Y|X)" "Product" "DifferenceEntropy" ]

   
set arr [ vtkFloatArray [ pxvtable::vnewobj ]]
$reg ExtractComponentAndCastImageToShort $image_ref_short $image_ref 0
$reg ExtractComponentAndCastImageToShort $image_trn_short $image_trn 0
$reg ComputeAllSimilarityMetricsBetweenImages $image_ref_short $image_trn_short $current_transform $arr
puts stderr "Similarity between ref and resliced transform using \t [ lindex $argv 2 ]"
for { set i 0 } { $i < [ $arr GetNumberOfTuples ] } { incr i } {
#    if { $i ==1 || $i==4 } {
	puts -nonewline stdout [ format "EX \t %s \t %s \t %8.5f \n" [ lindex $argv 2 ] [ lindex $reg_measures $i ] [ $arr GetComponent $i 0 ] ]
#    }
}

if { [ $current_transform IsA vtkpxComboTransform  ] ==1 } {
    set sm [ [ $current_transform GetGridTransform ] ComputeTotalBendingEnergy ]
    puts stdout [ format "EX \t %s \t BEN \t %8.5f \n" [ lindex $argv 2 ] $sm ]
}

puts stdout ""
$arr Delete
$reg Delete

if { $argc == 8 } {
    vtkpxRPMCorrespondenceFinder rpm

    puts stdout "Point Distances temp=$temperature, numpoints=$numpoints matchmode=$matchmode)"
    rpm SetSource $sur(0)
    rpm SetTarget $sur(1)
    rpm SetMaximumNumberOfLandmarks $numpoints
    rpm SetMatchMode $matchmode
    rpm SetUseLabels 1
    rpm SetFastThreshold 3.0
    rpm Initialize
    
    rpm WarpAndUpdateCorrespondence $trn $temperature
    set d [ rpm ComputeDistance [ lindex $argv 2 ] ]

    #puts stdout [ format "EX \t %s \t RPM \t %8.5f \n" [ lindex $argv 2 ] $d ]
    rpm Delete
    p1 Delete
    p2 Delete
}

ana1 Delete
ana2 Delete
$trn Delete

exit


