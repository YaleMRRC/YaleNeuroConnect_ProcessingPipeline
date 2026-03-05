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






# 	$Id: pxmat_computestrains.tcl,v 1.1 2004/01/15 15:07:53 xenios Exp xenios $	

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon


if { [ llength $argv ] < 3 } { 
    puts stdout "pxmat_computestrains is a script that reslices an image using one or more transformations"
    puts stdout "\npxmat_computestrains.tcl reference_image output_jacobian xform \[ threshold \]"
    exit
}

#puts stdout " Number of Arguments = [ llength $argv ] "

set reference     [ lindex $argv 0 ]
set outname       [ lindex $argv 1 ]
set xform         [ lindex $argv 2 ]
if { [ llength $argv ] > 3  } {
    set threshold [ lindex $argv 3 ]
} else {
    set threshold -1.0
}


set ana1 [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
$ana1 Load $reference
puts stdout "Loaded image [ $ana1 GetFilePrefix ] dim [ [ $ana1 GetOutput ] GetDimensions ]"

set ut [ vtkpxTransformationUtil [ pxvtable::vnewobj ]]
set trans [ $ut LoadAbstractTransform $xform ]
puts stdout "Loading transformation from $xform [ $trans GetClassName ]"
$ut Delete

set reg [ vtkpxRegistration [ pxvtable::vnewobj ]]
set img [ vtkImageData [ pxvtable::vnewobj ]]
$reg ComputePrincipalStrains [ $ana1 GetOutput ] $img $trans $threshold
$reg Delete

set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]
$anaw SetInput  $img 
$anaw SetImageHeader [ $ana1 GetImageHeader ]
$anaw Save $outname

puts stdout "Saved in [ $anaw GetFileName ] dimensions [ $img GetDimensions ], threshold=$threshold"
 
$anaw  Delete
$ana1  Delete
$trans Delete

exit

