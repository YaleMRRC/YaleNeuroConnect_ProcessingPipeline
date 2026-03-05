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
package require pxitclmultisubjectaverage
package provide bis_multisubjectfmri 1.0

#
# Operations involving multisubject average for testing ....
#

itcl::class bis_multisubjectfmri {

    inherit bis_algorithm
    
    constructor { } {
	$this Initialize
    }

    destructor { $this DeleteMultiSubject }
    
    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "MultiSubject fMRI" }

    public method UpdateContainerWithOutput { } 
    public method ConfigureOptionsGUICallbacks { } 
    public method ShowMultiSubject {  args } 
    protected method DeleteMultiSubject { }

    # variables
    protected variable multigadget 0
}
# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_multisubjectfmri::Initialize { } {

    PrintDebug "bis_multisubjectfmri::Initialize" 

    #name,description,type,object,filename(if applicable),priority (optional)
    set inputs { }


    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ setup "MultiSubject .msb Setup file name" "Setup Name:"  { filename readfile }  "" { "Setup Files" { .msb}} 1 }
	{ mode "Operation to perform" "Mode"  listofvalues  Average { Average AverageAnat VOI Create4D Create4DVOI }   2}
	{ resol "Resolution of Output Image" "Resolution" listofvalues 3.0 { "Ref" "1.5" "2.0" "3.0" "4.5" } -11 }
	{ interp "Interpolation Mode" "Interpolation" listofvalues "Cubic" { "NearestNeighbor" "Linear" "Cubic" } -10 }
	{ task  "Task Number to perform operation for" "Task Number" integer 1 { 1 40 } 3 }
	{  guitask  "Current Task Name" "Task Name"  comment  "         " ""  4 }
	{ guishowmsb  "Show MultiSubject Control" "Show Control"  { boolean } 0 { 0 1 }  5 }
    }

    set outputs { 
	{ output_image "Output Image"  pxitclimage  "" 101 }
	{ second_output "Sigma Image"  pxitclimage  "" 102 }
	{ third_output "Tscore Image"  pxitclimage  "" 103 }
    }


    set defaultsuffix { "_multisubject" }

    
    set scriptname bis_multisubjectfmri
    set completionstatus "Xenios has revisited  this -- looks almost done"
    #
    #document
    #
    set category "Functional Imaging"
    set description "Mostly a test class for pxitclmultisubject.tcl based multi subject operations"
    set description2 ""
    set backwardcompatibility "Uses pxitclmultisubject.tcl"
    set authors "xenophon.papademetris.yale.edu"

    $this AddDefaultOptions


}

itcl::body bis_multisubjectfmri::DeleteMultiSubject { } {

    if { $multigadget == 0 } {
	return
    }

    itcl::delete obj $multigadget
}

# -----------------------------------------------------------------------------------------
itcl::body bis_multisubjectfmri::ConfigureOptionsGUICallbacks { } {

    eval "$OptionsArray(guishowmsb) SetGUICallbackFunction { $this ShowMultiSubject }"
}

itcl::body bis_multisubjectfmri::ShowMultiSubject {  args } {


    if { $multigadget != 0 } {
	if { [ $OptionsArray(guishowmsb) GetValue ] ==0 } {
	    $multigadget HideWindow
	} else  {
	$multigadget ShowWindow Results
	}
    }
}

itcl::body bis_multisubjectfmri::UpdateContainerWithOutput { } {

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

itcl::body bis_multisubjectfmri::Execute {  } {

    set fname [ $OptionsArray(setup) GetValue ]
    set mode  [ $OptionsArray(mode) GetValue ]
    set resol [ $OptionsArray(resol) GetValue ]
    set interp [ $OptionsArray(interp) GetValue ]
    set task   [ $OptionsArray(task) GetValue ]

    puts stdout "Parameters = $fname, $mode, $resol, $interp, $task"
    catch { cd [ file dirname [ file normalize $fname ]] }
    puts stdout "Operating in Directory [ pwd ]"

  


    if { $multigadget == 0 } {
	set vr [ $this GetViewer ]
	if { $basewidget!=0 } {
	    set b $basewidget.[pxvtable::vnewobj ]
	} else {
	    set b .[pxvtable::vnewobj ]
	}
	set  multigadget [ [  pxitclmultisubjectaverage \#auto $vr  ] GetThisPointer ]
	$multigadget Initialize $b
	$multigadget ShowWindow Results
	$multigadget HideWindow
    }

    if { [ $OptionsArray(guishowmsb) GetValue ] == 1 } {
	$multigadget ShowWindow Results
    } else {
	$multigadget HideWindow
    }
    
    $multigadget SetInterpolationAndResolution $interp $resol
    update
    set ok [ $multigadget LoadSetup $fname ]
    if { $ok ==0 } {
	set errormessage "Failed to Load Setup $fname"
	return 0
    }


    puts stderr "Setting New Task [ expr $task -1 ]"
    set c [ $multigadget SetCurrentTask [ expr $task -1 ] ]
    $OptionsArray(task) SetValue [ expr [ lindex $c 0 ]  +1 ]
    $OptionsArray(guitask) SetValue "Using   [ lindex $c 1 ]:[lindex $c 2] (ind=[ expr [ lindex $c 0 ]  +1 ])"
    $multigadget LoadAll 0

    if { $mode == "Average" } {
	$multigadget ComputeAverages Functional
	[ $this GetOutputObject output_image ] ShallowCopy [ $multigadget GetMeanFunctionalOutput ]
	[ $this GetOutputObject second_output ] ShallowCopy [ $multigadget GetSigmaFunctionalOutput ]
	[ $this GetOutputObject third_output ] ShallowCopy [ $multigadget GetTscoreFunctionalOutput ]
    } elseif { $mode == "AverageAnat" } {
	$multigadget ComputeAverages Images
	[ $this GetOutputObject output_image ] ShallowCopy [ $multigadget GetMeanAnatomicalOutput ]
	[ $this GetOutputObject second_output ] ShallowCopy [ $multigadget GetSigmaAnatomicalOutput ]
    } elseif { $mode == "VOI" } {
	set img [ $multigadget DoVOIAnalysis "_do_not_save" 0 ]
	[ $this GetOutputObject output_image ] ShallowCopyImage $img
	$img Delete
    } else {
	if { $mode == "Create4DVOI" } {
	    $multigadget SetInterpolationAndResolution $interp "Ref"
	    set imglist [ $multigadget WarpTasksToCommonSpace warp "" 0 ]
	    set roimeanalg [ [ bis_roimean \#auto ] GetThisPointer ]
	    $roimeanalg InitializeFromContainer $this
	    set cimg [ $multigadget  Create4DImageForSingleFrameAndCurrentTask $imglist 0 $roimeanalg ]
	    itcl::delete object $roimeanalg
	    $multigadget SetInterpolationAndResolution $interp $resol
	} else {
	    set imglist [ $multigadget WarpTasksToCommonSpace warp "" 0 ]
	    set cimg [ $multigadget  Create4DImageForSingleFrameAndCurrentTask $imglist 0 0 ]
	}
	[ $this GetOutputObject output_image ] ShallowCopy $cimg
	itcl::delete obj $cimg
	for { set ai 0 } { $ai < [ llength $imglist ] } { incr ai } {
	    [ lindex $imglist $ai ] Delete
	}
    }


    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_multisubjectfmri.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_multisubjectfmri [pxvtable::vnewobj]]
    $alg MainFunction 
}

