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

package require bis_algorithm 1.0

package provide bis_split4dimage 1.0

#
# split4d image
#

itcl::class bis_split4dimage {

    inherit bis_algorithm
    
    constructor { } {
	$this Initialize
    }
    
    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Split 4D Image" }
}
# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_split4dimage::Initialize { } {

    PrintDebug "bis_split4dimage::Initialize" 

    #name,description,type,object,filename(if applicable),priority (optional)
    set inputs {
	{ input_image "input 4D image" pxitclimage  ""  }
    }

    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ begin       "begin frame" "begin frame" int 1  {1 1000} 0 }
	{ end         "end   frame" "end frame"   int 1000  {1 1000} 1 }
	{ ostem       "Stem of output filename, if set output files will be ostem_frame.extension, else the input name is used" "Output Stem"  string "" { "" } 2}

    }

    set defaultsuffix { "" }
    #default output is created by rule2
    
    set scriptname bis_split4dimage
    set completionstatus "Xenios has revisited  this -- looks almost done"
    #
    #document
    #
    set category "Utility"
    set description "extracts 3D volumes from the beginning time-frame to the ending time-frame from a 4D image."
    set description2 "Output files are input_001.hdr, input_002.hdr ,,, etc (or input_001.nifti, input_002.nifti ,,, ). input_001.hdr corresponds to the begin frame. If the -begin and -end option is not specified, all the the 3D volumes are extracted. "
    set backwardcompatibility "Reimplemented from pxmat_split4dimage.tcl."
    set authors "hirohito.okuda@yale.edu,xenophon.papademetris.yale.edu"

    $this AddDefaultOptions

}


# -----------------------------------------------------------------------------------------

itcl::body bis_split4dimage::Execute {  } {

    PrintDebug "bis_split4dimage::Execute"
    
    set image_in        [ $InputsArray(input_image) GetObject ]
    set beginframe      [ $OptionsArray(begin)  GetValue  ]
    set endframe        [ $OptionsArray(end)    GetValue  ]
    set stem            [ $OptionsArray(ostem)    GetValue  ]
    regsub -all "\"" $stem "" stem


    set number_of_frames [ [$image_in GetObject ] GetNumberOfScalarComponents ]
    set name [ $InputsArray(input_image) GetFileName]

    if { $number_of_frames == 1 } {
	puts stdout "Nothing to do $name only has one frame"
	return 1
    }

    if { $beginframe < 1 } { set beginframe 1 }
    if { $beginframe > $number_of_frames } { set beginframe $number_of_frames }

    if { $endframe <= $beginframe }      { set endframe $beginframe }
    if { $endframe > $number_of_frames } { set endframe $number_of_frames }

    PrintDebug "beginframe = $beginframe, endframe = $endframe"

    set extr [ vtkImageExtractComponents [ pxvtable::vnewobj ]]
    $extr SetInput [$image_in GetObject ]

    set bg [ expr $beginframe -1 ]


    set number [expr $endframe - $beginframe + 1 ]


    set l [ ::bis_common::SplitFileNameGZ $name ]
    set ext [ lindex $l 1 ]
    set m [ lindex $l 0 ]

    if { [ string length $stem ] > 1 } {
	set m $stem
    }

    set namelist [lsort [array names OutputsArray ]]

    set outimage [ [ pxitclimage \#auto ] GetThisPointer ]


    for { set i $bg } { $i < $endframe } { incr i } {
	set idx [ expr $i +1 ]

	$extr SetComponents $i
	$extr Modified
	$extr Update
	set image_out [ $extr GetOutput ]
	
	set outfilename  "${m}_${idx}${ext}" 

	$outimage ShallowCopyImage $image_out 
	# Output orientation etc. is same as input
	$outimage CopyImageHeader [ $image_in GetImageHeader ]
	[ $outimage GetImageHeader ] AddComment "split4d" 0
	$outimage Save  $outfilename

	puts stdout "Saved Output Frame $idx  in $outfilename"
    }

    $extr Delete
    itcl::delete obj $outimage

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_split4dimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_split4dimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

