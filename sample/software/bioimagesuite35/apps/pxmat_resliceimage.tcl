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






# 	$Id: pxmat_resliceimage.tcl,v 1.1 2004/01/15 15:07:53 xenios Exp xenios $	




if { [ llength $argv ] < 5 } { 
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "$scriptname is a script that reslices an image using one or more transformations"
    puts stdout "Syntax: $scriptname reference_image target_image output_image interpolation_mode xform1 \[ xform2 \] \[ xform3 \]\n"
    puts stdout "interpolation_mode = 0,1,3 nearest neighbor,linear,cubic"
    puts stdout "xform1 = Ref -> 3D, xform2 = 3D -> Conv , xform3 = Conv->Echo"
    puts stdout "\n"
    exit
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon

set reference     [ lindex $argv 0 ]
set target        [ lindex $argv 1 ]
set outname       [ lindex $argv 2 ]
set intmode       [ lindex $argv 3 ]
set xform(1)        [ lindex $argv 4 ]
set xform(2) ""
set xform(3) ""
if { [ llength $argv ] >= 6 } {
    set xform(2)    [ lindex $argv 5 ] 
    if { [ llength $argv ] >= 7 } {
	set xform(3)    [ lindex $argv 6 ] 
    }
}

if { $intmode <= 0 } { 
    set intmode 0
} elseif { $intmode <2 } {
    set intmode 1
} else {
    set intmode 3
}


set ana1 [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
$ana1 Load $reference

set ana2 [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
$ana2 Load $target

puts stdout "Loaded image [ $ana1 GetFilePrefix ] dim [ [ $ana1 GetOutput ] GetDimensions ]"
puts stdout "Loaded image [ $ana2 GetFilePrefix ] dim [ [ $ana2 GetOutput ] GetDimensions ]"

set ut [ vtkpxTransformationUtil [ pxvtable::vnewobj ]]

set counttr 0

for { set i 1 } { $i <= 3 } { incr i } {
    if { $xform($i) != "" } {
	set tr($i) [ $ut LoadAbstractTransform $xform($i) ]
	incr counttr
	puts stdout "Loading transformation $i from $xform($i)"
    } else {
	set tr($i) [ vtkIdentityTransform [ pxvtable::vnewobj ]]
	puts stdout "Setting transformation $i to identity"
    }
}

if { $counttr>1 } {
    set trans [ vtkGeneralTransform [ pxvtable::vnewobj ]]
    $trans Identity
    $trans PostMultiply
    $trans Concatenate $tr(1)
    $trans Concatenate $tr(2)
    $trans Concatenate $tr(3)
} else {
    set trans $tr(1)
    puts stdout "Only using One Transformation"
}

set resl [ vtkbisImageReslice [ pxvtable::vnewobj ]]
$resl SetInput [ $ana2 GetOutput ]
$resl SetInformationInput [ $ana1 GetOutput ]
$resl SetInterpolationMode $intmode
$resl SetBackgroundLevel 0.0
$resl OptimizationOff
$resl SetResliceTransform $trans
$resl Update

set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]
$anaw SetInput [ $resl GetOutput ]
$anaw SetImageHeader [ $ana1 GetImageHeader ]

# Test this  -- extensions addition
# ---------------------------------
[ $anaw  GetImageHeader ] CopyExtensionsOnly [ $ana2 GetImageHeader ]
# -----------------------------------
$anaw Save $outname

puts stdout "Saved in [ $anaw GetFileName ] dimensions [ [ $resl GetOutput ] GetDimensions ]"
 
$anaw Delete
$resl Delete
$ana1 Delete
$ana2 Delete
$tr(1) Delete
$tr(2) Delete
$tr(3) Delete
$ut Delete

exit

