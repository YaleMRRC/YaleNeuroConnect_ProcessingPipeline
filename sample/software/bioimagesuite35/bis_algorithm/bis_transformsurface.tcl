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

package require bis_surfacetosurfacealgorithm 1.0

package provide bis_transformsurface 1.0

#
# transform polydata
#

itcl::class bis_transformsurface {

    inherit bis_surfacetosurfacealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }

    public method GetTransformation { }
    public method SetTransformation { tr }
    public method SetVTKTransformation { tr }
    public method GetGUIName { } { return "Transform Surface" }
    public method  UpdateOutputFilenames { } 
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_transformsurface::Initialize { } {

    PrintDebug "bis_transformsurface::Initialize" 
    #name,description,type,object,filename(if applicable),priority (optional)
    set inputs {
	{ transformation "Transformation"    pxitcltransform  ""  80 }
	{ transformation2 "Transformation 2"    pxitcltransform  ""  300 }
	{ transformation3 "Transformation 3"    pxitcltransform  ""  400 }
    }

    set options { 
	{ guicmt2  "Description of the filter"  "Note"  comment "Transform surface" "Transforms a surface using the transformation specified." 400 }
    }

    
    set defaultsuffix { "_xform" }
    
    set scriptname bis_transformsurface

    #
    #document
    #

    set category "Surface Processing"
    set description "Transforms (warps) a surface using a transformation"
    set description2 ""
    set backwardcompatibility ""
    set authors "hirohito.okuda@yale.edu"

    $this InitializeSurfacetoSurfaceAlgorithm
}

itcl::body bis_transformsurface::SetTransformation  { tr } {

    $this SetInputObject transformation $tr
}

itcl::body bis_transformsurface::SetVTKTransformation  { tr } {

    set t [ $this GetInputObject transformation ]
    #    puts stderr "$t copying transformation from $tr ([$tr GetClassName])"
    $t CopyTransformation $tr
    $t configure -filename [ $tr GetClassName ]
}

itcl::body bis_transformsurface::GetTransformation { } {

    return [ $this GetInputObject transformation ]
}

itcl::body bis_transformsurface::UpdateOutputFilenames { } {

    set f(0) [ $InputsArray(input_surface) GetFileName ]
    set f(1) [ [ $this GetTransformation ] cget -filename ]

    for { set i 0 } { $i <= 1 } { incr i } {
	set l($i) [ ::bis_common::SplitFileNameGZ $f($i) ]
	set p($i) [ file dirname $f($i) ]
	set f($i) [ file tail [ lindex $l($i) 0 ] ]

	set ext($i) [ lindex $l($i) 1 ]
    }
    
    set fname [ file join $p(0) "$f(0)_$f(1)" ]
    
    set outlist [ $this CreateDefaultOutputFileList $fname ]
    set force 0; if { $guimode == "managed" } {	set force 1    }
    $OutputsArray(output_surface) SetFileName "[ lindex $outlist 0 ]$ext(0)" $force 
    return 1

}


# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_transformsurface::Execute {  } {

    set surface    [ $InputsArray(input_surface) GetObject ]
    set trans      [ $InputsArray(transformation) GetObject ] 

    #set xform1 [ $trans GetTransformation ]
    set xform1 [ $trans GetObject ]
    set xform2 0 
    set xform3 0
    if { [ $InputsArray(transformation2) IsFileNameTheDefault ] != 1 } {
        set xform2 [[ $InputsArray(transformation2) GetObject ] GetObject ]
    }
    if { [ $InputsArray(transformation3) IsFileNameTheDefault ] != 1 } {
        set xform3 [[ $InputsArray(transformation3) GetObject ] GetObject ]
    }

    puts stdout "xform2: $xform2"
    puts stdout "xform3: $xform3"

    set transform [ vtkGeneralTransform [ pxvtable::vnewobj ]] 
    $transform Identity
    $transform PostMultiply
    $transform Concatenate $xform1
    if { $xform2 != 0 } {
        $transform Concatenate $xform2
        puts stdout "xform2 in use"
    }
    if { $xform3 != 0 } {
        $transform Concatenate $xform3
        puts stdout "xform3 in use"
    }


    set filter [ vtkTransformPolyDataFilter [ pxvtable::vnewobj ] ]
    $filter SetInput  [ $surface  GetSurface ]
    #$filter SetTransform  [ $trans  GetTransformation ]
    $filter SetTransform $transform
    $transform Delete
    $filter Update

    set surface_out [$filter GetOutput ]

    [ $OutputsArray(output_surface) GetObject ] DeepCopySurface $surface_out 

    $filter Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_transformsurface.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function
    set alg [bis_transformsurface [pxvtable::vnewobj]]
    $alg MainFunction 
}

