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

package require bis_imagelisttoimagealgorithm 
package provide bis_create4dimage 1.0

#
# create 4d image
#

itcl::class bis_create4dimage {

    #inherit bis_imagelisttoimagealgorithm
    inherit bis_imagelisttoimagealgorithm

    constructor { } {
	$this Initialize
    }

    public method Initialize { }
    public method Execute    { }
    public method GetGUIName    { } { return "Concatenate Set of 3D Images" }
}



# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_create4dimage::Initialize { } {
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{  guicmt "Inputs"  "Note"  comment "Takes in a variable amount of images" \
	       "Create a 4d image by appending each image to the first image as a new frame"  1 }

    }

    set defaultsuffix { "_4D" }
    
    set scriptname bis_create4dimage
    set completionstatus "Done"
    #
    #document
    #
    set category "Image Processing Multiple"
    set description  "combines a number of 3D volumes into a single 4D image."
    set description2 "Output filename is image1_4D.hdr (or image1_4D.nifti)"

    set backwardcompatibility "Reimplemented from pxmat_create4dimage.tcl."
    set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu, dustin.scheinost@yale.edu"

    $this InitializeImageListToImageAlgorithm
}


# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_create4dimage::Execute {  } {

    PrintDebug "bis_create4dimage::Execute"

    set maxi 0
    set errorflag 0

    set inplist [ $InputsArray($directinputs) GetAllObjects ]
    set numfiles [ llength $inplist ]
    
    if { $numfiles < 2 } {
	set errormessage "Nothing do less than 2 inputs specified"
	return 0
    }

    set appnd [ vtkImageAppendComponents [ pxvtable::vnewobj ]]	
    for { set i 0 } { $i < $numfiles } { incr i } {
	puts stdout "Adding image [ expr $i+1 ], [ [ lindex $inplist $i ] GetShortDescription ]"
	$appnd AddInput  [ [ lindex $inplist $i]  GetImage ]
    }
    $this SetFilterCallbacks $appnd "Creating 4D Image"
    $appnd Update
    set image_out [ $appnd GetOutput ]
    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage $image_out

    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader  [ [ lindex $inplist 0 ] GetImageHeader ]
    [ $outimage GetImageHeader ] AddComment [ $this GetCommandLine full ] 0
    $appnd Delete
    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_create4dimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_create4dimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

