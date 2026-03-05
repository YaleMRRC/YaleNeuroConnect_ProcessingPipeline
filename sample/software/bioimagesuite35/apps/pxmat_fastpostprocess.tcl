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





# --------------------------------------------------------------------------------------------------------
# 	$Id: pxmultiregister_int.tcl,v 1.1 2004/01/15 15:06:06 xenios Exp xenios $	


set imglist ""
set numclasses 3
set imgtype 1
set identifier "segm"

set argc [llength $argv]
if { $argc <3 } {
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "$scriptname is a script that converts fsl/fast output into a format suitable for use by BioImage Suite"
    puts stdout "Syntax: $scriptname basename outname numclasses"
    puts stdout "\n"
    exit
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon
package require  pxitclimage            1.0
package require  pxitcltransform        1.0
package require  pxitclsubjectentry     1.0
    
set basename [ lindex $argv 0 ]
set nc [ lindex $argv 2 ]
set out  [ lindex $argv 1 ] 
set outb ${out}_restore
set outo ${out}_seg

set anabase [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ] ]
$anabase Load $basename
set baseimg [ $anabase GetOutput ]
puts stdout "Dim/Comp: [ $baseimg GetDimensions ] [ $baseimg GetNumberOfScalarComponents ] $basename\n-----------------------------\n"

set anasource [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ] ]
$anasource Load ${outo}.hdr
set newimg [ $anasource GetOutput ]
puts stdout "Read Output File $outo [ $newimg GetDimensions ]"

#catch { file delete ${outo}.img }
#catch { file delete ${outo}.hdr }

puts stdout "Dim/Comp: [ $newimg GetDimensions ] [ $newimg GetNumberOfScalarComponents ] $outo"

set cast [ vtkImageShiftScale [ pxvtable::vnewobj ]]
$cast SetInput $newimg
$cast SetScale [ expr 1.0 / $nc ]
$cast SetOutputScalarTypeToFloat
$cast Update

puts stdout "Cast to float [ [ $cast GetOutput ] GetDimensions ] [ [ $cast GetOutput ] GetNumberOfScalarComponents ]"

set merg [ vtkImageAppendComponents [ pxvtable::vnewobj ]]
$merg AddInput [ $cast GetOutput ]

for { set i 0 } { $i < $nc } { incr i } {
    set pimg($i) [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ] ]
    set tname ${out}_pbmap_$i
    $pimg($i) Load $tname
    puts stdout "Loaded $tname [ [ $pimg($i) GetOutput ] GetDimensions ] [ [ $pimg($i) GetOutput ] GetNumberOfScalarComponents ]"
    
    $merg AddInput [ $pimg($i) GetOutput ]
    $pimg($i) Delete
    
    #catch { file delete ${tname}.img }
    #catch { file delete ${tname}.hdr }
}

$merg Update
set newimage [ vtkImageData [ pxvtable::vnewobj ]]
$newimage ShallowCopy [ $merg GetOutput ]

set t [ $merg GetOutput ]
puts stdout "Dim/Comp: [ $t GetDimensions ] [ $t GetNumberOfScalarComponents ]"
puts stdout "Dim/Comp: [ $newimage GetDimensions ] [ $newimage GetNumberOfScalarComponents ]"

$merg Delete
$cast Delete


set anaw  [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ] ]
$anaw SetInput $newimage
$anaw SetImageHeader [ $anabase GetImageHeader ]
$anaw Save ${out}_classification.hdr

exit

}

