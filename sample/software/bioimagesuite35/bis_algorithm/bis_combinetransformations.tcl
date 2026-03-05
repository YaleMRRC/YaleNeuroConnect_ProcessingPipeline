#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" "$@"

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

package require bis_dualimagetransformationalgorithm 1.0
package provide bis_combinetransformations 1.0

#
# combinetransformations
#

itcl::class bis_combinetransformations {

    inherit bis_dualimagetransformationalgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Combine Transformations" }
    public method  UpdateOutputFilenames { } 

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_combinetransformations::Initialize { } {


    set defaultsuffix "dispfield"

    set inputs {
	{ xform2   "Transformation 2"    pxitcltransform  "" 101 }
	{ xform3   "Transformation 3"    pxitcltransform  "" 102 }
    }

    set outputs {
	{ comboxform   "Combined Transformation"    pxitcltransform  "" 1 }
    }

    set options {
	{ inverse  "Create Inverse Transformation" "Inverse" boolean   0  { 0 1 } 1 }
    }
    set scriptname bis_combinetransformations


    #
    #document
    #
    set defaultsuffix { "combined" }
    set category "Registration"
    set description  "computes a combined (optionally inverse) transformation  for a set  transformation given an image to define the space."
    set description2 ""
    set backwardcompatibility ""
    set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu."

    $this InitializeDualImageTransformationAlgorithm

    $this RenameInput 1 "Unused Second Image" 200
    $this RenameInput 2 "Transformation 1" 101
    $this RenameOutput 0 "Combined Disp Field" 200

}
# -----------------------------------------------------------------------------------------
itcl::body bis_combinetransformations::UpdateOutputFilenames { } {

    set f(0) [ $InputsArray(transformation) GetFileName ]
    set f(1) [ $InputsArray(xform2) GetFileName ]
    set f(2) [ $InputsArray(xform3) GetFileName ]

    for { set i 0 } { $i <= 2 } { incr i } {
	set l($i) [ ::bis_common::SplitFileNameGZ $f($i) ]
	set f($i) [ file tail [ lindex $l($i) 0 ] ]
	set ext($i) [ lindex $l($i) 1 ]
    }

    set fname [ file join [ file dirname $f(0) ] $f(0) ]
    for { set i 1 } { $i<=2 } { incr i } {
	if { $f($i) != "" } {
	    set fname "${fname}_$f($i)"
	}
    }
    
    set md [ $OptionsArray(inverse) GetValue ]
    if { $md == 1 } {
	set defaultsuffix "inverse"
    } else  {
	set defaultsuffix "comb"
    }

    set dest [ $OutputsArray(comboxform) GetObject ] 

    unset ext

    if { [  [ $dest GetTransformation ] IsA "vtkHomogeneousTransform" ] ==1 } {
	set ext ".matr"
    } else {
	set ext ".grd.gz"
    }
    
    set force 0;    if { $guimode == "managed" } {	set force 1    }    

    $OutputsArray(comboxform) SetFileName "${fname}_${defaultsuffix}${ext}" $force
    $OutputsArray(output_image) SetFileName "" $force


    return 1
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_combinetransformations::Execute {  } {

    PrintDebug "bis_combinetransformations::Execute"
    set inversemode [ $OptionsArray(inverse) GetValue ]
    set numgoodxforms 1
    set allxformsarelinear 1
    set ref_image    [ $InputsArray(input_image) GetObject ] 

    set tlist(0)  [ $this GetInputObject transformation ] 
    set tlist(1)  [ GetInputObject xform2 ] 
    set tlist(2)  [ GetInputObject xform3 ]

    set xforms ""

    for { set i 0 } { $i <= 2 } { incr i } {
	if { [ $tlist($i)  IsIdentity ] == 0 } {
	    lappend xforms $tlist($i) 
	    if { [ [ $tlist($i) GetTransformation ] IsA "vtkHomogeneousTransform" ] == 0  } {
		set allxformsarelinear 0
	    }
	}
    }
    set numgoodxforms [ llength $xforms ]
    
    set dest [ $OutputsArray(comboxform) GetObject ] 
    set fname [ $dest cget -filename ]
    $dest Clear
    $dest configure -filename $fname

    puts stderr "xforms=$xforms, allxformsarelinear=$allxformsarelinear"

    # No Tranformations
    if { $numgoodxforms == 0 } {
	puts stdout "All Transformations are identity. Operation is pointless"
	return 1
    }
    
    if { $numgoodxforms == 1 } {
	puts stdout "One Transformation copying"
	set dest [ $OutputsArray(comboxform) GetObject ] 
	set fname [ $dest cget -filename ]
	$dest Copy  [ $this GetInputObject transformation ] 
	
	if { $inversemode == 1 && $allxformsarelinear == 1} {
	    puts stdout " and inverting"
	    $dest Invert
	}

	if { $inversemode == 0 || ( $inversemode ==1 && $allxformsarelinear ==1 ) } {
	    if { $fname != "" } {
		if { [ [ $dest GetTransformation ]  IsA "vtkHomogeneousTransform" ] ==1 } {
		    set fname "[ file rootname $fname ].matr"
		}
		$dest configure -filename $fname
	    } else {
		$dest configure -filename ""
	    }
	    return 1
	} else {
	    puts stdout "Need to invert a single nonlinear transformation"
	}
    }
   
    if { $allxformsarelinear == 1 } {
	set trans [ vtkTransform [ pxvtable::vnewobj ]]
	$trans Identity
	$trans PostMultiply
	for { set i 0 } { $i < $numgoodxforms } { incr i } {
	    puts stdout "Concatenating linear [ [ lindex $xforms $i ] cget -filename ]"
	    $trans Concatenate [ [ lindex $xforms $i ] GetObject ]
	}
	if { $inversemode == 1 } {
	    $trans Inverse
	}
	set dest [ $OutputsArray(comboxform) GetObject ] 
	$dest CopyTransformation  $trans
	$trans Delete
	return 1
    }
	
    set trans [ vtkGeneralTransform [ pxvtable::vnewobj ]]
    $trans Identity
    $trans PostMultiply
    for { set i 0 } { $i < $numgoodxforms } { incr i } {
	puts stdout "Concatenating linear/non-linear [ [ lindex $xforms $i ] cget -filename ]"
	$trans Concatenate [ [ lindex $xforms $i ] GetObject ]
    }

    set dim [[ $ref_image GetObject ] GetDimensions ]
    set spa [[ $ref_image GetObject ] GetSpacing ]
    set ori [[ $ref_image GetObject ] GetOrigin ]

    puts stderr "Spacing = $spa, Origin=$ori, dim=$dim"


    set tgrid [ vtkTransformToGrid [ pxvtable::vnewobj ]]
    $tgrid SetGridExtent 0 [ expr [ lindex $dim  0 ] -1 ] 0 [ expr [ lindex $dim  1 ] -1 ] 0 [ expr [ lindex $dim  2 ] -1 ]
    $tgrid SetGridOrigin  [ lindex $ori 0 ] [ lindex $ori 1 ] [ lindex $ori 2 ] 
    $tgrid SetGridSpacing [ lindex $spa 0 ] [ lindex $spa 1 ] [ lindex $spa 2 ] 
    $tgrid SetInput $trans
    $tgrid Update

    set tr2 [ vtkpxGridTransform [ pxvtable::vnewobj ]]
    $tr2 SetInterpolationModeToLinear

    if { $inversemode == 1 } {
	set trg [ vtkGridTransform [ pxvtable::vnewobj ]]
	$trg SetDisplacementGrid [ $tgrid GetOutput ]
	$trg SetInterpolationModeToLinear
	$trg Inverse
	
	set tgrid2 [ vtkTransformToGrid [ pxvtable::vnewobj ]]
	$tgrid2 SetGridExtent  0 [ expr [ lindex $dim  0 ] -1 ] 0 [ expr [ lindex $dim  1 ] -1 ] 0 [ expr [ lindex $dim  2 ] -1 ]
	$tgrid2 SetGridOrigin  [ lindex $ori 0 ] [ lindex $ori 1 ] [ lindex $ori 2 ] 
	$tgrid2 SetGridSpacing [ lindex $spa 0 ] [ lindex $spa 1 ] [ lindex $spa 2 ] 
	$tgrid2 SetInput $trg
	$tgrid2 Update
	
	$tr2 SetDisplacementGrid [ $tgrid2 GetOutput ]
	$tgrid2 Delete
	$trg Delete
    } else {
	$tr2 SetDisplacementGrid [ $tgrid GetOutput ]
    }

    set image_out [ $tgrid GetOutput ]

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage [ $tr2 GetDisplacementGrid ]

    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $ref_image GetImageHeader ]
    [ $outimage GetImageHeader ] AddComment [ $this GetCommandLine full ] 

    set dest [ $OutputsArray(comboxform) GetObject ] 
    $dest CopyTransformation  $tr2
    $dest configure -filename $fname

    
    $tr2 Delete
    $tgrid Delete
    $trans Delete
    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_displacementfield.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

#    DebugOn

    set alg [bis_combinetransformations [pxvtable::vnewobj]]
    $alg MainFunction 
}

