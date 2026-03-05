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


set num $argc 

if { $num < 4 } {
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "Usage: $scriptname refname voiname numframes directory (optional series # 3T only)"
    exit 0
}

lappend auto_path [ file dirname [ info script ]]; 
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] bis_algorithm]

package require pxappscommon
package require bis_cropimage 1.0
package require bis_realtimefmri  1.0
package require bis_realtimefmri2 1.0

set ref [ pxitclimage \#auto ]
$ref Load [ lindex $argv 0 ]

set voi [ pxitclimage \#auto ]
$voi Load [ lindex $argv 1 ]

puts "number of arg = $argc"

#force the reference to be a singel frame image
#saves time later in the motion correction

set crop_alg [ bis_cropimage \#auto ]
$crop_alg InitializeFromContainer 0
$crop_alg SetInput $ref
$crop_alg SetOptionValue startt 3
$crop_alg SetOptionValue stopt  3
$crop_alg Execute

set mode 15T

if { $mode == "3T" } {
    set realtime [ bis_realtimefmri2 \#auto ]
    $realtime configure -directoryname [ lindex $argv 3 ]
    if { $argc > 4 } {
	$realtime configure -series [ lindex $argv 4 ]
    } else { 
	$realtime DetermineSeries 
    }
    
} else {
    set realtime [ bis_realtimefmri \#auto ]
    $realtime configure -directoryname [ lindex $argv 3 ]
    $realtime ClearIMAFiles 
}

$realtime configure -referenceimage [ $crop_alg GetOutput ] 
$realtime configure -voiimage $voi
$realtime configure -maxframes [ lindex $argv 2 ]

$realtime SetImageDimensionsFromReference
$realtime Run

exit






