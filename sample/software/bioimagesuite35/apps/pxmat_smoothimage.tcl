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






# 	$Id: pxmat_smoothimage.tcl,v 1.2 2004/01/15 15:04:47 xenios Exp xenios $	



if { [ llength $argv ] < 2 } { 
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "$scriptname is a script that smooths an image using a specific gaussian smoothing kernel"
    puts stdout "Syntax: pxmat_smoothimage.tcl kernel_size  input_image1 input_image2 ..... "
    puts stdout "\t\tsmoothing kernel_size in mm represents FWHM filter size"
    puts stdout "\n"
    exit 0
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon
set numc [ llength $argv ]
set blursigma       [ lindex $argv 0 ]


for { set i 1 } { $i < $numc } { incr i } {

    set ana1 [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ] ]


    set reference [ lindex $argv $i ]
    $ana1 Load $reference

    set spa [ [ $ana1 GetOutput ] GetSpacing ]
    puts stdout "\nLoaded image $i [ [ $ana1 GetImageHeader ] GetHeaderDescription 0 ]"

    for { set j 0 } { $j <=2 } { incr j } {
	set sigma($j) [ expr $blursigma * 0.4247 / [ lindex $spa $j ]]
    }
    puts stdout "\n\tSmoothing kernel size  [ format "%.2fx%.2fx%.2f voxels from input %.2f mm" $sigma(0) $sigma(1) $sigma(2) $blursigma ]"

    set header [ $ana1 GetImageHeader ]

    set smooth  [ vtkImageGaussianSmooth [ pxvtable::vnewobj ]  ]
    $smooth SetStandardDeviations $sigma(0) $sigma(1) $sigma(2)
    $smooth SetRadiusFactors 1.5 1.5 1.5
    $smooth SetInput [ $ana1 GetOutput ]
    $smooth Update

    $header AddComment [ format "BIS::pxmat_smoothimage.tcl blursigma=%.2f in voxels (%.2f,%.2f,%.2f)" $blursigma $sigma(0) $sigma(1) $sigma(2) $blursigma ] 0

    set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ] ]
    $anaw SetImageHeader $header
    $anaw SetInput [ $smooth GetOutput ]
    set outfname [ ::pxappscommon::GenOutputName $reference sm${blursigma} ]
    $anaw Save $outfname
    
    puts stdout "\nSmoothed image saved  [ [ $anaw GetImageHeader ] GetHeaderDescription 0 ]\n"
    exit

    $smooth Delete
    $anaw Delete
    $ana1 Delete

}

exit 0

