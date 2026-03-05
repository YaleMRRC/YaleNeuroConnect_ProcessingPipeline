#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" -- "$@"

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

lappend auto_path [ file dirname [ info script ]]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]

package provide bis_imagelisttoimagealgorithm 1.0
package require bis_algorithm 1.0


#
# create 4d image
#

itcl::class bis_imagelisttoimagealgorithm {

    #inherit bis_algorithm
    inherit bis_algorithm


    constructor { } { }
    protected method InitializeImageListToImageAlgorithm { }
    public method CheckInputObjects { } 
    public method UpdateOutputFilenames { } 
    public method UpdateContainerWithOutput { } 

}



# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_imagelisttoimagealgorithm::InitializeImageListToImageAlgorithm { } {
    

    #name,description,type,object,filename(if applicable),priority (optional)
    set tmp $outputs
    set outputs {
	{ output_image "output 4d image "  pxitclimage  "" }
    }
    for { set i 0 } { $i < [ llength $tmp ] } { incr i } {
    	lappend outputs [ lindex $tmp $i ]
    }


    #number of input files should be equal or larger than 1
    set tmp $inputs
    set inputs { { input_image "Input Image List" { pxitclimage multiple } "" 0  } }


    for { set i 0 } { $i < [ llength $tmp ] } { incr i } {
	lappend inputs [ lindex $tmp $i ]
    }

    set directinputs "input_image"
    if { $defaultsuffix == "" } {
	set defaultsuffix { "_4D" }
    }

    if { $scriptname == "" } {
	set scriptname bis_imagelisttoimagealgorithm
    }

    #
    #document
    #

    if { $category == "" } {
	set category "Image Processing Multiple"
    }


    $this AddDefaultOptions

}

# -----------------------------------------------------------------------------------------
itcl::body bis_imagelisttoimagealgorithm::UpdateOutputFilenames { }  {

    set inplist [ $InputsArray($directinputs) GetAllObjects ]
    set numfiles [ llength $inplist ]

    set fn [ $InputsArray(input_image) GetFileName ]
    set outlist [ $this CreateDefaultOutputFileList $fn ]
    set l [ ::bis_common::SplitFileNameGZ $fn ]
    set ext [ lindex $l 1 ]
    set m [ lindex $outlist 0 ]

    set force 0;    if { $guimode == "managed" } {	set force 1    }    
    $OutputsArray(output_image) SetFileName "${m}_N${numfiles}${ext}"  $force
    return 1

}

itcl::body bis_imagelisttoimagealgorithm::CheckInputObjects { }  {
    set inplist [ $InputsArray($directinputs) GetAllObjects ]
    set numfiles [ llength $inplist ]
    
    set sz [ [ lindex $inplist 0 ] GetImageSize ]
    if { $sz < 1 } {
	return 0
    }
    
    if { $numfiles > 1 } {
	for { set i 1 } { $i < $numfiles } { incr i } {
	    if { $sz != [ [ lindex $inplist $i ] GetImageSize ] } {
		set errormessage "Input Images must have same size (index = [ expr $i +1 ] )"
		return 0
	    }
	}
    }
    return 1
}

itcl::body bis_imagelisttoimagealgorithm::UpdateContainerWithOutput { } {

    set img  [ $this GetOutputObject output_image ] 

    if { $containerobject == 0 } {
	if { $bis_viewer !=0 } {
	    $bis_viewer SetImage $img
	}  elseif { $vtk_viewer !=0 } {
	    $vtk_viewer SetImage [ $img GetImage ] [ $img GetOrientation ]
	} 
    } else {
	PrintDebug "Calling Container ($this, $containerobject) SetResultsFromObject" 
	$containerobject SetResultsFromObject $img $this
	# Unload result at this point
	$img Clear
    }
}




# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_imagelisttoimagealgorithm.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 

