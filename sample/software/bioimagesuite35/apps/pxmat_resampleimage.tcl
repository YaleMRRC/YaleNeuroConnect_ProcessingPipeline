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






# 	$Id: pxmat_resampleimage.tcl,v 1.1 2004/01/15 15:08:09 xenios Exp xenios $	




if { [ llength $argv ] < 4 } { 
    set scriptname [ file tail $argv0 ]
    puts stderr "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"

    puts stdout "$scriptname is a script that resamples an image to a specific resolution"
    puts stdout "Syntax: $scriptname input_image  output_image blur_mode  voxelsize1 \[ voxelsize2 \] \[ voxelsize3 \]"
    puts stdout "\t\tblurmode = 0 or 1 to blur with appropriate FHWM filter"
    puts stdout "\t\tvoxelsize1 = voxel size x, voxelsize2=voxel size y, voxelsize3=voxel size z"
    puts stdout "\n"
    exit
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon

set reference     [ lindex $argv 0 ]
set outname       [ lindex $argv 1 ]
set blurmode       [ lindex $argv 2 ]
set spacing(0)        [ lindex $argv 3 ]
set spacing(1) $spacing(0)
set spacing(2) $spacing(0)
if { [ llength $argv ] >= 5 } {
    set spacing(1)    [ lindex $argv 4 ] 
    if { [ llength $argv ] >= 6 } {
	set spacing(2)    [ lindex $argv 5 ] 
    }
}

if { $blurmode != 0 } { 
    set blurmode 1
} 

set ana1 [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ] ]
$ana1 Load $reference

puts stdout "Loaded image [ [ $ana1 GetImageHeader ] GetHeaderDescription 0 ]"


set smooth  [ vtkImageGaussianSmooth [ pxvtable::vnewobj ]  ]
    
set resl [ vtkbisImageResample [ pxvtable::vnewobj ]]
for { set i 0 } { $i <=2 } { incr i } {
    $resl SetAxisOutputSpacing $i $spacing($i)
}

if { $blurmode == 1 } {
    set spa   [ [ $ana1 GetOutput ] GetSpacing ]
    for { set i 0 } { $i <=2 } { incr i } {
	set sigma($i) [ expr $spacing($i) *0.4247 / [ lindex $spa $i ]]
    }
    $smooth SetStandardDeviations $sigma(0) $sigma(1) $sigma(2)
    $smooth SetRadiusFactors 1.5 1.5 1.5
    $smooth SetInput [ $ana1 GetOutput ]
    $smooth Update
    $resl SetInput [ $smooth GetOutput ]
} else {
    $resl SetInput [ $ana1 GetOutput ]
}

$resl InterpolateOn
$resl SetDimensionality 3
$resl Update

set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]
$anaw SetInput [ $resl GetOutput ]
$anaw SetImageHeader [ $ana1 GetImageHeader ]
$anaw Save $outname

puts stdout "Saved in [ [  $anaw GetImageHeader ] GetHeaderDescription 0 ]"
 
$anaw Delete
$resl Delete
$ana1 Delete
$smooth Delete

exit

