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
package require bis_viewer 1.0
package require pxitclcamera 1.0
package provide bis_testviewer 1.0

#
# Operations involving multisubject average for testing ....
#

itcl::class bis_testviewer {

    inherit bis_algorithm
    
    constructor { } {
	$this Initialize
    }
    destructor {
	if { $test_viewer !=0 } {
	    wm deiconify $tp
	    destroy $tp
	    itcl::delete object $test_viewer
	}
    }
	

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Test Viewer" }

    protected variable test_viewer 0
    protected variable tp 0

}
# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_testviewer::Initialize { } {

    PrintDebug "bis_testviewer::Initialize" 

    #name,description,type,object,filename(if applicable),priority (optional)
    set inputs { 
	{ input_image "Input Image" pxitclimage  ""    1000 }
	{ objectmap_image "Objectmap Image" pxitclimage  ""    1001 }
	{ input_surface "Input Surface" pxitclsurface  ""    1002 }
	{ input_landmarks "Input Landmarks" pxitcllandmarks  ""    1003 }
    }
    set outputs { 
	{ out_image "Viewer 2D Grab Image" pxitclimage  ""    2000 }
    }

    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ magn "Zoom Mode for Snapshots" "Magnification" integer 1 { 1 4 } 1 }
	{ vtype "Type of Viewer" "ViewerType"  listofvalues  ortho { ortho ortho4d mos singleslice }   -1 }
	{ edit "Enable Editor in viewer" "Editor:"  { boolean checkbutton } 0 { 0 1 }  -2 }
	{ ortho3d "Items to display in 3D Viewer Mode" "Ortho3D"  integer 1 { 0 7 } -10 }
	{ orthomode "Mode for ortho viewer" "OrthoMode" integer 1 { 0 7 } -11 }
	{ mosrows  "Rows to display in mosaic Viewer" "Mosaic Rows" integer 1 { 1 6 } -12 }
	{ moscols  "Columns to display in mosaic Viewer" "Mosaic Columns" integer 1 { 1 6 } -12 }
	{ camera "Input camera file name" "Camera Name:"  { filename readfile }  "" { "Camera Files" { .cm}} -15 }
    }


    set createviewermode 0


    set defaultsuffix { "" }

    set scriptname bis_testviewer
    set completionstatus ""
    #
    #document
    #
    set category "Utility"
    set description "This is a test script for the BioImage Suite Viewers, primarily for regression testing"
    set description2 ""
    set backwardcompatibility ""
    set authors "xenophon.papademetris.yale.edu"

    $this AddDefaultOptions


}




itcl::body bis_testviewer::Execute {  } {

    if { $test_viewer == 0 } {
	set tp [ toplevel .[ pxvtable::vnewobj ] -bg red ]
	wm deiconify $tp
	wm geometry $tp 800x620
	update idletasks
	wm title $tp "Test Viewer "

	set nv [ frame $tp.1 -height 600 -width 600 ]
	pack $nv -side left -expand false
	
	frame $tp.2 -bg darkgreen -height 600 -width 100
	pack $tp.2 -side right -expand true -fill both
	
	
	set test_viewer [ [ bis_viewer \#auto ] GetThisPointer ]
	$test_viewer configure -enable_toolbar 0
	$test_viewer configure -enable_openigtlinkgadget 0
	$test_viewer configure -enable_landmarkeditor 0
	$test_viewer configure -enable_electrodeeditor 0
	$test_viewer SetViewerType [ $OptionsArray(vtype) GetValue ] [ $OptionsArray(edit) GetValue ]
	$test_viewer CreateGUI $nv
	[ $test_viewer GetViewer ] SetShowControls 0 
	update idletasks
	puts stdout "Width = [ $nv cget -width ], Height = [ $nv cget -height ]"
    } 
	
    wm deiconify $tp
    update idletasks    

    set img  [ $this GetInputObject input_image ]

    if { [ $img GetSize  ] > 1 } {
	$test_viewer SetImage $img
	$test_viewer SetImageColormapMode 0
    }

    set msk  [ $this GetInputObject objectmap_image ] 
    $test_viewer SetMask $msk

    set vt [ $test_viewer GetViewer ]
    if { [ $vt IsA "vtkpxGUIOrthogonalViewer"  ] == 1 } {
	$vt SetDisplayMode [ expr int([$OptionsArray(orthomode) GetValue]) ]
	$vt SetDisplay3DMode [ expr int([$OptionsArray(ortho3d) GetValue]) ]

	if { [ $OptionsArray(camera)  GetValue ] != ""  } {
	    set cam [ pxitclcamera #auto ]
	    $cam Load [ $OptionsArray(camera) GetValue ]
	    set ren [ $vt GetRenderer 3 ]
	    set newcam [ [ $ren GetRenderer ] GetActiveCamera ]
	    $ren CopyCamera $newcam [ $cam GetCamera ]
	    itcl::delete object $cam
	    $ren CameraModifiedCallback
	    $ren Render
	}
    } else {
	$vt SetConfiguration [ expr int([$OptionsArray(mosrows) GetValue ]) ] [ expr int([$OptionsArray(moscols) GetValue]) ]
    }

    if { [ $vt IsA "vtkpxGUIOrthogonalViewer"  ] == 1 } {
	set sur [ $this GetInputObject input_surface ]
	if { [ $sur GetSize ] > 0 } {
	    $test_viewer AddPolygonalObject $sur
	}
	
	set land [ $this GetInputObject input_landmarks ]
	if { [ $sur GetSize ] > 0 } {
	    $test_viewer AddPolygonalObject $sur
	}
    }

    $this SetOptionValue ctestgui 1

    update idletasks

    # --------------------
    # Generate Output
    # ---------------------
    set img [ $test_viewer GetScreenshotImage [ $OptionsArray(magn) GetValue ] ]
    [ $this GetOutputObject out_image ] ShallowCopyImage $img
    $img Delete

    return 1
}
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_testviewer [pxvtable::vnewobj]]
    $alg MainFunction 
}

