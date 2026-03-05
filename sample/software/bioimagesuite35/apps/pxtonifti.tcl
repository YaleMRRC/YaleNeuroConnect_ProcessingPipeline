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




set argc [llength $argv]
if { $argc < 1 } {
    puts stderr "Usage  pxtonifti.tcl  image1  image2 image 3  ...\n"
    exit
}



lappend auto_path /usr/local/bioimagesuite30/apps
lappend auto_path [ file dirname [ info script ]]; package require pxappscommon
wm withdraw .


for { set i 0 } { $i < $argc } { incr i } {

    set anar [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
    set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]

    set fname [ lindex $argv $i ]
    $anar Load $fname

    set head [ $anar GetImageHeader ]
    # SetModeToAnalyze() 
    # SetModeToNIFTI_HDRIMG
    $head SetModeToNIFTI_NII

    set outname [ file rootname $fname ].nii.gz

    $anaw SetInput [ $anar GetOutput ]
    $anaw SetImageHeader $head
    $anaw Save $outname
    
    puts stderr "From $fname --> $outname"
    $anaw Delete
    $anar Delete
}

exit

    
