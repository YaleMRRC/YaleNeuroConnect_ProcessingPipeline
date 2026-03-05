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
# 	$Id: pxappscommon.tcl,v 1.2 2004/01/15 15:01:11 xenios Exp xenios $	






package provide pxappscommon 1.0

catch { wm withdraw . }

lappend auto_path [ file dirname [ info script ]]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".."] base ]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".."] main ]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".."] mjack ]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".."] bis_algorithm ]

package require pxtclutil 1.0
package require pxtcluserprefs 1.0
package require Itcl
package require pxitclimage  


set no_gui 1
catch {  if { $vtkpxcontrib_no_gui == 0 } {
    set no_gui 0 }
}

if { $no_gui == 1 } {
    set vtkpxcontrib_no_gui 1
}
unset no_gui
package require vtkpxcontrib  1.1
unset vtkpxcontrib_no_gui 

package require vtkmpjcontrib 

package require pxvtable 1.0

namespace eval ::pxappscommon {
    
    proc GenOutputName { input tag { outsuffix .hdr } { insuffix .hdr } } {

	if { [ file extension $input ] == ".gz" } {
	    set input [ file rootname $input ]
	}

	if { [ file extension $input ] == ".nii" } {
	    set outsuffix .nii.gz
	    set insuffix  .nii
	}

	if { [ file extension $input ] == $insuffix } {
	    set fname "[ file rootname $input ]"
	} else {
	    set fname $input
	}


	if { [ string length $tag ] > 0 } {
	    set fname "${fname}_${tag}$outsuffix"
	} else {
	    set fname "${fname}$outsuffix"
	}
	return $fname
    }

    proc RestrictRange { input minv maxv } {
	if { $input < $minv } {
	    return $minv
	}
	
	if { $input > $maxv } {
	    return $maxv
	}

	return $input
    }

    proc RestrictIntRange { input minv maxv } {
	return [ expr round([RestrictRange $input $minv $maxv ])]
    }

    proc CheckAnalyzeSource { ana imagename filename vtkobjs } {
	set ok 0
	catch {
	    set img [ $ana GetOutput ]
	    set dim [ $img GetDimensions ]
	    set spa [ $img GetSpacing    ]
	    set pt  [ $img GetNumberOfPoints ]
	    set ok 1
	}
	
	if { $ok ==0 } {
	    puts stderr "Failed to load $imagename from $filename\n exiting"
	    cleanup $vtkobjs
	    exit
	} 

	puts stdout "Loaded $imagename from $filename ([ lindex $dim 0 ] x [ lindex $dim 1 ] x [ lindex $dim 2 ]), ([ lindex $spa 0 ] x [ lindex $spa 1 ] x [ lindex $spa 2 ])"
    }

    proc Cleanup { vtkobjs } {
	for { set i 0 } { $i < [ llength $vtkobjs ] } {incr i } {
	    catch { [ lindex $vtkobjs $i ] Delete }
	}
    }


    # Check whether file exists and 
    proc CompressedFileExists { fname } {
	
	set ext [ file extension $fname ]
	if { $ext == ".gz" } {
	    set fname [ file rootname $fname ]
	}

	if { [ file exists $fname ] > 0 } {
	    return [ file size $fname ]
	}

	if { [ file exists "${fname}.gz" ] > 0 } {
	    return [ expr -[ file size ${fname}.gz ] ]
	}
	return 0
    }

    proc EnsureImageExists { fname }  {

	if { $fname == "" } {
	    return 0
	}

	set ext [ file extension $fname ]
	if { $ext == ".gz" } {
	    set fname [ file rootname $fname ]
	    set ext   [ file extension $fname ]
	}

	if { $ext == ".hdr" } {
	    set fname [ file rootname $fname ]
	    set ok1 [ ::pxappscommon::CompressedFileExists ${fname}.hdr ]
	    set ok2 [ ::pxappscommon::CompressedFileExists ${fname}.img ]
	    
	    if { $ok1 != 0 && $ok2 != 0 } {
		set ext1 ""
		set ext2 ""
		if { $ok1 < 0 } {   set ext1 ".gz"; set ok1 [ expr - $ok1 ] }
		if { $ok2 < 0 } {   set ext2 ".gz"; set ok2 [ expr - $ok2 ] }


		return [ list ${fname}.hdr${ext1} "($ok1)" ${fname}.img${ext2} "($ok2)" ]
	    }
	}

	set ok [ ::pxappscommon::CompressedFileExists $fname ] 
	if { $ok !=0 } {
	    set ext1 ""
	    if { $ok < 0 } {   set ext1 ".gz"; set ok [ expr - $ok ] }
	    return [ list $fname${ext1} "($ok)" ]
	}
    }

}


set tmp  [  [ pxitclimage \#auto ] GetThisPointer ]
if {   $pxtcl_pref_array(ForceOutputFormat) == "Analyze" } {
    $tmp SetOutputFormat 1
} elseif { $pxtcl_pref_array(ForceOutputFormat) == "NIFTI" } {
    $tmp SetOutputFormat 2
} else {
    $tmp SetOutputFormat 0
}
itcl::delete object $tmp 
unset tmp
