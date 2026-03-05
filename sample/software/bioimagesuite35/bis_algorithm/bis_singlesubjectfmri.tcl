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
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] main]

package require bis_algorithm 1.0
package require bis_fmrisetup 1.0
package provide bis_singlesubjectfmri 1.0

#
# Operations involving multisubject average for testing ....
#

itcl::class bis_singlesubjectfmri {

    inherit bis_algorithm
    
    constructor { } {
	$this Initialize
    }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "MultiSubject fMRI" }
    public method UpdateContainerWithOutput { } 
}
# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_singlesubjectfmri::Initialize { } {

    PrintDebug "bis_singlesubjectfmri::Initialize" 

    #name,description,type,object,filename(if applicable),priority (optional)
    set inputs { }


    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ setup "Input .xmlg Setup file name" "Setup Name:"  { filename readfile }  "" { "Setup Files" { .xmlg}} 1 }
	{ setup2 "Optional Second .xmlg Setup file name" "Second Setup Name:"  { filename readfile }  "" { "Setup Files" { .xmlg}} 1 }
	{ mode "Operation to perform" "Mode"  listofvalues  glm { glm seed matrix taskseed whole ipsi contra }   2}
	{ guilabel  "Current XML Tree Name" "Tree Name"  comment  "         " ""  6 }
	{ outdir  "Specify the output directory for the results" "Output Directory" { filename directory 40 } "" "" 4 }
	{ tmpresults "If on then results will be deleted on exit (use for testing)" "Discard Results"  boolean  0 { 0 1 }  5 }
    }

    set outputs { 
	{ output_image "Output Image"  pxitclimage  "" 101 }
	{ output2 "Output 2"  pxitclimage  "" 102 }
	{ output3 "Output 3"  pxitclimage  "" 103 }
	{ output4 "Output 4"  pxitclimage  "" 104 }
	{ output5 "Output 5"  pxitclimage  "" 105 }
	{ output6 "Output 6"  pxitclimage  "" 106 }
	{ output7 "Output 7"  pxitclimage  "" 107 }
	{ output8 "Output 8"  pxitclimage  "" 108 }
	{ output9 "Output 9"  pxitclimage  "" 109 }
    }


    set defaultsuffix { "_singlesubject" }

    
    set scriptname bis_singlesubjectfmri
    set completionstatus ""
    #
    #document
    #
    set category "Functional Imaging"
    set description "Mostly a test class for bis_fmrisetup.tcl based single subject fMRI Operations"
    set description2 ""
    set backwardcompatibility "Uses bis_fmrisetup.tcl"
    set authors "xenophon.papademetris.yale.edu"

    $this AddDefaultOptions


}


# -----------------------------------------------------------------------------------------
itcl::body bis_singlesubjectfmri::UpdateContainerWithOutput { } {

    set img  [ $this GetOutputObject output_image ] 

    PrintDebug "In Update Container With Output $this, $img [ $img GetDescription ]\n"
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

itcl::body bis_singlesubjectfmri::Execute {  } {

    set fname [ $OptionsArray(setup) GetValue ]
    set fname2  [ $OptionsArray(setup2) GetValue ]
    set mode [ $OptionsArray(mode) GetValue ]
    set outdir   [ $OptionsArray(outdir) GetValue ]
    set tmpmode [ $OptionsArray(tmpresults) GetValue ]

    if { [ string length $fname2 ] < 3 } {
	set fname2 "_do_not_use"
    }

    if { $fname == "" } {
	set errormessage "Must set setup file to non empty value"
	return 0
    }

    set outdir [ $OptionsArray(ctesttmpdir)  GetValue ]
    set outdir [ $this CreateTempOutputDirectory $outdir ]
    
    if { [ file writable $outdir ] == 0 } {
	set errormessage "Output directory $outdir is not writable by the current user"
	return 0
    }
    
    
    puts stdout "Parameters = $fname, ($fname2) mode=$mode, outdir=$outdir"

    set arglist [ list $fname $mode $fname2 $outdir ]


    set alg [bis_fmrisetup \#auto ]
    set status [ $alg MainFunction [ llength $arglist ] $arglist  ]
    set ok [ lindex $status 0 ]
    if { $ok == 0 } {
	set errormessage [ lindex $status 1 ]
	itcl::delete obj $alg
	catch { $OptionsArray(guilabel) SetValue "Failed" }
	return 0
    }

    catch { $OptionsArray(guilabel) SetValue  [ $alg GetDataManagerFilename ]  }


    set dm [ $alg GetDataManager ]
    set nd [ $dm FindNode "Outputs" ]

    set numout [ llength [ $this GetOutputsList ] ]

    for { set j 0 } { $j < [ $nd GetNumberOfNestedElements ] } { incr j } {
	set child [ $nd GetNestedElement $j ]
	set f [ $child GetAttribute Filename ]
	if { $j < $numout } {
	    set obj [ $this GetOutputObjectByIndex $j ]
	    $obj Load $f
	    if { $guimode == "commandline" } {
		$obj configure -filename ""
	    }
	    puts stdout "Storing output $j/ $numout = $f"
	}
    }

    itcl::delete obj $alg
    if { $tmpmode > 0 } {
	set tst [ $this RemoveTempOutputDirectory $outdir ]
	puts stdout "Deleting $outdir, success=$tst"
    }

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_singlesubjectfmri.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_singlesubjectfmri [pxvtable::vnewobj]]
    $alg MainFunction 
}

