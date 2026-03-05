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
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] mjack]

package require bis_imagetoimagealgorithm 1.0
package provide bis_interleave 1.0

#
# interleave
#

itcl::class bis_interleave {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Interleave Frames" }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_interleave::Initialize { } {

#    puts stdout "bis_interleave::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ interleave "Reorder Slices/Frames" "Interleave"  boolean   1 { 0 1 }  0 }
	{ numframes "number of output frames" "Num Frames"  int   1 { 1 10000 }  2 }
	{ numslices "number of output slices" "Num Slices"  int   1 { 1 10000 }  1 }
    }

    set defaultsuffix { "_interleave" }
    
    set scriptname bis_interleave

    set description "interleaves image."
    set description2 ""
    set backwardcompatibility "Reimplemented from mpjinterleave.tcl. Once default output file (***_inter) was output, now you need to specify output file name."
    set authors "hirohito.okuda@yale.edu,marcel.jackowski.yale.edu"
    set category "Image Processing-4D"
    $this InitializeImageToImageAlgorithm

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_interleave::Execute {  } {

    set currentimage  [ $this GetInput ]


    set nc [ [ $currentimage GetImage ] GetNumberOfScalarComponents ]
    set outfr [ $OptionsArray(numframes) GetValue ] 
    set outsl [ $OptionsArray(numslices) GetValue ] 
    set doreord [ $OptionsArray(interleave) GetValue ] 
    
    if { $nc == $outfr && $doreord == 0 } {
	set errormessage "Current image already has $nc frames!\n No need to reorder slices/frames!"
	return 0
    }

    set currentresults [ $this GetOutput ] 
	
    set tmpimg [ vtkImageData [ pxvtable::vnewobj ]]

    if { $nc == 1 } {
	set co [ vtkpxImageComponentsToFrames [ pxvtable::vnewobj ]]
	$co SetInverse 1
	$co SetInput [ $currentimage GetImage ]
	if { $doreord == 0 } {
	    $co SetSlicesPerFrame $outsl
	} else {
	    $co SetSlicesPerFrame $outfr
	}
	$co Update
	$tmpimg ShallowCopy [ $co GetOutput ]
	$co Delete
    } else {
	$tmpimg ShallowCopy [ $currentimage GetImage ] 
    }

    if { $doreord == 1 } {
	set ut [ vtkpxUtil  [ pxvtable::vnewobj ]]
	$ut ReorderImage [ $currentresults GetImage ] $tmpimg
	$ut Delete
    } else {
	$currentresults ShallowCopyImage $tmpimg
    }
    
    $tmpimg Delete
    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $currentimage GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment" 0
    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_interleave.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_interleave [pxvtable::vnewobj]]
    $alg MainFunction 
}

