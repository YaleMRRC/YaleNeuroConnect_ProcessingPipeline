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

package provide bis_piecewiseimagemap 1.0
package require bis_imagetoimagealgorithm 1.0


itcl::class bis_piecewiseimagemap {

    inherit bis_imagetoimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "PiecewiseMap" }
    public method UpdateInputsFromContainer { }

    # Number of knots
    protected variable numknots 8

    # Improve GUI Somewhat
    protected method PackOptionsGUIInterface { lst }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------


itcl::body bis_piecewiseimagemap::Initialize { } {

    PrintDebug "bis_piecewiseimagemap::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ type "output image type.Specify one of  Default (same as input) UnsignedChar Short Float Double" "Output Type"  listofvalues  Default { Default UnsignedChar Float Double Short }  50 }
    }

    set count 1
    for { set i 1 } { $i <= $numknots } { incr i } {

	lappend options [ list on$i  "enable knot $i"  "Enable $i"  { boolean }  0 { 0 1 }  $count ] ; incr count
	lappend options [ list x$i   "input value for knot  $i"  "X$i"  { real default }  0.0 { -10000000000 1000000000 }  $count ]; incr count
	lappend options [ list y$i   "output value for knot $i" "Y$i"   { real default }  0.0 { -10000000000 1000000000 }  $count ]; incr count
    }

    set defaultsuffix { "_mt" }
    
    set scriptname bis_piecewiseimagemap
    set completionstatus "Done"

    #
    #document
    #
    
    set description "Perfoms piecewise mapping of an image using a linear spline with prescribed knots."
    set description2 " "
    set backwardcompatibility "Reimplemented from code in pxitcloverlaytool.tcl"

    $this InitializeImageToImageAlgorithm

}

# ------------------------------------------------------------------------------

itcl::body bis_piecewiseimagemap::UpdateInputsFromContainer { } {

    bis_imagetoimagealgorithm::UpdateInputsFromContainer 

    # This happens when image has changed 
    set currentimage  [ $InputsArray(input_image) GetObject ]

    set r [ [ $currentimage GetImage ] GetScalarRange ]
    set rmin [ lindex $r 0 ]
    set rmax [ lindex $r 1 ]
    if { $rmax == $rmin } {
	set rmax [ expr $rmin +1 ]
    }

    for { set i 1 } { $i <= $numknots } { incr i } {
	$OptionsArray(x$i)  SetValueRange [ list $rmin $rmax ]
    }
}

# ------------------------------------------------------------------------------
itcl::body bis_piecewiseimagemap::PackOptionsGUIInterface { lst } { 


    set n [ llength $lst ]
    PrintDebug "\n\n Length of list = $n"

    for { set tab 0 } { $tab <= 1 } { incr tab } {
	set wlist ""
	for { set i 0 } { $i < $n } { incr i } {
	    
		set pair [ lindex $lst $i ]
		set ind  [ lindex $pair 1 ]
		if { $ind == $tab } {
		    lappend wlist $pair
		}
	    }

	set wlist [ lsort -integer  -index 0 $wlist ]


	if { $tab == 1 } {
	    for { set j 0 } { $j < [ llength $wlist ] } { incr j } {
		set pair [ lindex $wlist $j ]
		set name [ lindex $pair 2 ]
		set widg [ lindex $pair 3 ]
		pack $widg -side top -expand false -fill x -padx 1
	    }
	} else {
	    # Custom Pack

	    for { set l 1 } { $l <= $numknots } { incr l } {
		grid  [ $OptionsArray(on$l) GetBaseWidget ]  -row $l -column 0 -padx 0
		 $OptionsArray(on$l) HideHelpButton
		grid  [ $OptionsArray(x$l) GetBaseWidget ]  -row $l -column 1 -padx 0
		$OptionsArray(x$l) HideHelpButton
		grid  [ $OptionsArray(y$l) GetBaseWidget ]  -row $l -column 2 -padx 0
		$OptionsArray(y$l) SetHelpMessage "Map x$l -> y$l if enabled"
	    }

	    grid  [ $OptionsArray(type) GetBaseWidget ] -row [ expr $numknots +1 ] -column 0 -columnspan 3 -padx 0

	    set v  [ file rootname  [ $OptionsArray(type) GetBaseWidget ] ]
	    grid rowconfigure $v 10 -weight 100
	    grid columnconfigure $v 10 -weight 100




	}
    }
    update idletasks
}


# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_piecewiseimagemap::Execute {  } {

    PrintDebug "bis_piecewiseimagemap::Execute"

    set otype   [ $OptionsArray(type) GetValue ]

    
    set newmap [ vtkDoubleArray [ pxvtable::vnewobj ]]
    $newmap SetNumberOfComponents 2

    for { set l 1 } { $l <= $numknots } { incr l } {
	set enableknot [ $OptionsArray(on$l) GetValue ]
	if { $enableknot > 0 } {
	    set x [ $OptionsArray(x$l) GetValue ]
	    set y [ $OptionsArray(y$l) GetValue ]
	    $newmap InsertNextTuple2 $x $y
	}
    }

    if { [ $newmap GetNumberOfTuples ] < 1 } {
	$newmap Delete
	return 0
    }

    set sh  [ vtkpxImageAlgebra [ pxvtable::vnewobj ]  ]
    $sh SetInput [ [ $this GetInput ] GetImage ]
    set ok [  $sh CreateMapArrayFromKnots $newmap ]
    $newmap Delete

    if { $otype != "Default" } {
	
	$sh SetOutputScalarTypeTo$otype
    }
    $this SetFilterCallbacks $sh "Multi-Linear Scaling of Image"
    $sh Update
    
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $sh GetOutput ]
    $outimage CopyImageHeader [ [ $this GetInput ] GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0


    $sh Delete
    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_piecewiseimagemap.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_piecewiseimagemap [pxvtable::vnewobj]]
    $alg MainFunction 
}




