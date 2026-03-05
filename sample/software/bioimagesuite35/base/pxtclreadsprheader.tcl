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

package provide pxtclreadsprheader 1.0

# 	$Id: pxtclreadsprheader.tcl,v 1.1 2002/02/20 18:07:50 Xenios Exp Xenios $	







package require pxvtable 1.0

namespace eval ::pxtclreadsprheader {

    #initialize vtable
    pxvtable::initvlist 

    #variable header
    namespace export ReadHeader PrintHeader SetAnalyzeImageSource

    # Procedure to Load Spr File -- Static no $this variable involved 
    # --------------------------
    proc LoadFile { ana fname } {

	set this [ pxvtable::vnewobj ]
	::pxtclreadsprheader::ReadHeader $this $fname
	::pxtclreadsprheader::SetAnalyzeImageSource $this $ana
	$ana Update
    }

    # Helper Procedure to Load Spr File 
    # ----------------------------------
    pxvtable::vproc SetAnalyzeImageSource { this ana } {

	$ana SetHeaderInfo $thisparam(width) $thisparam(height) $thisparam(numslices) $thisparam(numframes) $thisparam(swapbytes) $thisparam(bytes)
	$ana SetDataOrigin $thisparam(originx) $thisparam(originy) $thisparam(originz)
	$ana SetDataSpacing $thisparam(spacingx) $thisparam(spacingy) $thisparam(spacingz)

	set or [ string index $thisparam(orient) 0 ]
	set or [ string toupper $or ]

	if { $or == "S" } {
	    $ana SetOrientation 2
	} else {
	    if { $or == "C"} {
		$ana SetOrientation 1 
	    } else {
		$ana SetOrientation 0
	    }
	}
	    
	set f [file rootname $thisparam(filename)]
	$ana SetFilePrefix "$f.sdt"
    }

    # Print Header Array
    # ------------------
    pxvtable::vproc PrintHeader { this } {

	puts stdout "Header Values:"
	foreach { key value } [array get thisparam] {
	    puts stdout "$key  : $value"
	}
    }

    # Initialize Header
    # ------------------

    pxvtable::vproc InitHeader { this } {
	global tcl_platform

	set thisparam(filename) ""
	set thisparam(numDim) 0
	set thisparam(width) 0
	set thisparam(height) 1
	set thisparam(numslices) 1
	set thisparam(numframes) 0
	set thisparam(originx) 0.0
	set thisparam(originy) 0.0
	set thisparam(originz) 0.0
	set thisparam(origint) 0.0
	set thisparam(spacingx) 0.0
	set thisparam(spacingy) 0.0
	set thisparam(spacingz) 0.0
	set thisparam(spacingt) 0.0
	set thisparam(fovx) 0.0
	set thisparam(fovy) 0.0
	set thisparam(fovz) 0.0
	set thisparam(fovt) 0.0
	set thisparam(bytes) 2
	set thisparam(swapbytes) 0
	set thisparam(orient) "COR"

	if { $tcl_platform(byteOrder) == "littleEndian" } { 
	    set thisparam(swapbytes) 1
	}
    }    

    # Read spr Header
    # ---------------
    pxvtable::vproc ReadHeader { this fname } {
	
	::pxtclreadsprheader::InitHeader $this
	
	if { [string length $fname] < 1 } {
	    set fname [tk_getOpenFile -title "Filename" -filetypes { {"spr files" {.spr}}}]
	}
	
	if { [string length  $fname] < 1 } {
	    return 0
	}

	set thisparam(filename) $fname
	

	if { [ file exists $fname ] == 0 } {
	    return 0
	}
	set fileid [open $fname r]
	
	# Parse file one-line at a time
	while { [gets $fileid line] >=0 } {
	    set index [string first ":" $line]
	    
	    if { $index > 0 }  {
		set len   [string length $line]
		
		set key [string trim   [string range $line 0 [expr $index - 1]]]
		set value [string trim [string range $line [expr $index +1] [expr $len -1]]]
		
		switch $key {
		    numDim {
			scan $value "%d" thisparam(numDim)
		    }
		    
		    dim {
			scan $value "%d %d %d %d" thisparam(width) thisparam(height) thisparam(numslices) thisparam(numframes) 
		    }
		    
		    origin {
			scan $value "%f %f %f %f" thisparam(originx) thisparam(originy) thisparam(originz) thisparam(origint) 
		    }
		    
		    fov {
			scan $value "%f %f %f %f" thisparam(fovx) thisparam(fovy) thisparam(fovz) thisparam(fovt) 
		    }
		    
		    interval {
			scan $value "%f %f %f %f" thisparam(spacingx) thisparam(spacingy) thisparam(spacingz) thisparam(spacingt) 
			
		    }
		    
		    dataType {
			if { $value == "WORD"} { 
			    set thisparam(bytes) 2 
			} else {
			    set thisparam(bytes) 1
			}
		    }
		    
		    sdtOrient {
			set thisparam(orient) $value
		    }
		}
	    }
	}
	

	close $fileid
	return 1
    }
}


