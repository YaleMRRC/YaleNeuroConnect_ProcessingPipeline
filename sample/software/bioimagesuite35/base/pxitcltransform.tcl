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

package provide pxitcltransform 1.0

# 	$Id: pxitcltransform.tcl,v 1.1 2002/07/19 22:17:02 papad Exp papad $	





package require pxitclobject 1.0
# -------------------------------------------------------------------
# Definition of pxitcltransform
#
#    a class that encapsulates a transformation and its filename
# -------------------------------------------------------------------

itcl::class pxitcltransform {

    inherit pxitclobject

    public variable transformation

    constructor { } {
	pxitclobject::constructor 
    } {
	set transformation [ vtkTransform [ pxvtable::vnewobj ]]
	$transformation Identity
    }

    destructor  { $transformation Delete  }


    # --- begin method def -----


    
    public method GetObject { } { return $transformation }
    public method GetType { } { return [ $transformation GetClassName ]} 
    public method GetDescription { } 
    public method GetShortDescription { } 
    public method UpdateStatus { } 
    public method Copy    { obj args }
    public method Clear   { }
    public method IsIdentity   { }
    public method GetSize { } { return [ expr 1 -[ $this IsIdentity ] ]}
    public method IsLinear   { }
    public method Load { args }
    public method Browse { description }
    public method Save { args }

    # Methods additional to pxitclobject
    public method GetTransformation { } { return $transformation }
    public method Invert  { } 
    public method CopyTransformation { obj }
    
    public method CompareTo  { fname { thr 0.001 } }

    # --- end method def -----
}

# ------------------- End of Header ---------------------------------
itcl::body pxitcltransform::Copy   { obj args  } {

    if { $obj == 0 } {
	return 0
    }


    if { [ $obj isa pxitcltransform ] == 0 } {
	return 0
    }

    CopyTransformation  [ $obj GetTransformation ]  
    set filename [ $obj cget -filename ] 
    return 1
}
# ----------------------------------------------------------


itcl::body pxitcltransform::CopyTransformation { oldxform  } {
    
    set thistype "[ $transformation GetClassName ]"
    $transformation Delete
    set transformation [ [ $oldxform GetClassName ] [ pxvtable::vnewobj ] ]
    #    puts stdout "executing set transformation [ $oldxform GetClassName ] [ pxvtable::vnewobj ] "

    if { [ $oldxform GetClassName ] == "vtkTransform" } {
	$transformation Identity
	$transformation Concatenate $oldxform
    } else {
	$transformation DeepCopy $oldxform
    }   

}
# ----------------------------------------------------------
itcl::body pxitcltransform::GetShortDescription { } {
    return  "[ file tail $filename] [ $transformation GetClassName ]"
}

itcl::body pxitcltransform::GetDescription { } {
    
    set line ""
    


    if { [ $transformation IsA "vtkHomogeneousTransform" ] ==1 } {
	set matr [ $transformation GetMatrix ] 
	for { set row 0 } { $row <= 3 } { incr row } {
	    set line "$line\[ "
	    for { set col 0 } { $col <= 3 } { incr col } {
		set key [ $matr GetElement $row $col ]
		set line "$line [format "%-7.3f" $key ]"
	    }
	    set line "$line\]\n"
	}
    } elseif { [ $transformation IsA "vtkGridTransform" ] == 1 } {
	set grd [ $transformation GetDisplacementGrid ]
	set dim [ $grd GetDimensions ]
	set sp [ $grd GetSpacing ]
	set or [ $grd GetOrigin ]
	set line "Dimensions = $dim"
	set line "$line\nSpacing = $sp\n"
	set line "$line\nOrigin = $or\n"
    } elseif { [ $transformation IsA "vtkpxComboTransform" ] == 1 } {
	set grd [ [ $transformation GetGridTransform ] GetDisplacementGrid ]
	set dim [ $grd GetDimensions ]
	set sp [ $grd GetSpacing ]
	set or [ $grd GetOrigin ]
	set line "Combo Transform:  (NonLinearFirst: [ $transformation GetNonLinearFirst])"
	set line "$line\n Num_Grids [ $transformation GetNumberOfGridTransformations ]"
	set line "$line\n Dimensions = $dim"
	set line "$line\n Spacing = $sp"
	set line "$line\n Origin = $or"
    } elseif { [ $transformation IsA "vtkpxPolySimilarityTransform" ] } {
	set nt [ $transformation GetNumberOfTransformations ]
	set np [ $transformation GetNumberOfParameters ]
	set lp "No TPS transform"
	catch {
	    set np2 [ [ [ $transformation GetThinPlateSplineTransform ] GetSourceLandmarks ] GetNumberOfPoints ]
	    set lp "TPS present: $np2 control points"
	}
	set line "PolySimilarityTransform :\n $nt transformations\n $np pararameters\n$lp"
    } elseif { [ $transformation IsA "vtkThinPlateSplineTransform" ] } {
	set line "ThinPlateSplineTransform :\n Number of Control Points = [ [ $transformation GetSourceLandmarks ] GetNumberOfPoints ]" 
    } else {
	set line "Transformation Type:\n [ $transformation GetClassName ]"
    }

    set line "$line\n Filename = $filename"

    return $line 
}
# ----------------------------------------------------------
itcl::body pxitcltransform::Browse { description } {

    set f2path [ file dirname $filename ]
    set f2tail [ file tail    $filename ]
	
	set typelist { 
	    {"Matrix/Grid Files" {".matr" ".grd" ".grd.gz" } }
	    {"Grid/Combo Transform Files"  {".grd" ".grd.gz" ".vtk" }}
	    {"VTK Displacement Fields" {.vtk}} 
	    {"Matrix Files" {.matr}} 
	    {"All Files" {*}}}
    
    set fname  [tk_getOpenFile -title "Get Filename for $description" -filetypes $typelist -initialfile $f2tail -initialdir $f2path ]   
    if { [ string length $fname ] > 0 } {
	set filename $fname
	return 1
    }
    return 0
}
# ------------------------------------------------------------------------
itcl::body pxitcltransform::Load { args } {
    
    set len [ llength $args ]
    if { [ string length $filename ] == 0 && $len == 0 } { return    }


    if { $len > 0 } {
	set f [ lindex $args 0 ]
    }  else {
	set f $filename
    }

    if { $len > 1 } { 
	set desc [ lindex $args 1 ]
    } else {
	set desc "Transformation"
    }

    if { [ string length $f ] < 1 } { 
	set typelist { 
	    {"Matrix/Grid Files" {".matr" ".grd" ".grd.gz" } }
	    {"Grid/Combo Transform Files"  {".grd" ".grd.gz" }}
	    {"VTK Displacement Fields" {.vtk}} 
	    {"PolySimilarity Transforms" {.psim}} 
	    {"Matrix Files" {.matr}} 
	    {"Thin Plate Spline Transforms" {.tps}} 
	    {"All Files" {*}}}
	
	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set f [tk_getOpenFile -title "Load $desc" -initialfile $f2tail -filetypes $typelist -initialdir $f2path]
    }

    if { [string length $f ] < 2 || $f=="identity" } {
	return 0;
    }
    
    set filename  $f
    set ut [ vtkpxTransformationUtil [ pxvtable::vnewobj ]]
    set newtr [ $ut LoadAbstractTransform $f ]
    $ut Delete
    
    if { [ string length $newtr ] ==0 } {
	::pxtclutil::Warning "Failed to Load transformation from $f!"
	return 0;
    } 
	
    
    CopyTransformation $newtr

    $newtr Delete
    return 1;

}
# ----------------------------------------------------------
itcl::body pxitcltransform::Save { args } {

    set f    $filename
    set desc "Transformation"
    
    
    if { [ llength $args ] > 0 } {
	set f [ lindex $args 0 ]
    } 
    if { [ llength $args ] > 1 } { 
	set desc [ lindex $args 1 ]
    }

    set dovtk 0

    if { [ string length $f ] < 1 } { 
	set f1 $filename  
	set f1path [ file dirname $f1 ]
	set f1tail [ file tail    $f1 ]

	if { [ $transformation IsA "vtkHomogeneousTransform" ] ==1 } {		
	    set f  [tk_getSaveFile -title "Saving $desc" -initialfile $f1tail -initialdir $f1path -filetypes { {"Matrix Files" {.matr}} } ]
	} elseif { [ $transformation IsA "vtkGridTransform" ] ==1 } {		
	    set f  [tk_getSaveFile -title "Saving $desc" -initialfile $f1tail -initialdir $f1path -filetypes { {"Grid Transform Files" {.grd .vtk}} } ]
	    set dovtk 1
	} elseif { [ $transformation IsA "vtkpxComboTransform" ] ==1 } {		
	    set f  [tk_getSaveFile -title "Saving $desc" -initialfile $f1tail -initialdir $f1path -filetypes { {"Combo Transform Files" {.grd}} } ]
	} elseif {[ $transformation IsA "vtkThinPlateSplineTransform" ] ==1 } {		
	    set f  [tk_getSaveFile -title "Saving $desc" -initialfile $f1tail -initialdir $f1path -filetypes { {"ThinPlateSpline Transform Files" {.tps}} } ]
	} elseif {[ $transformation IsA "vtkpxPolySimilarityTransform" ] ==1 } {		
	    set f  [tk_getSaveFile -title "Saving $desc" -initialfile $f1tail -initialdir $f1path -filetypes { {"PolySimilarity Transform Files" {.psim}} } ]
	}
    }

    if { [string length $f ] > 0 } {
	set filename  $f

	if { $dovtk ==1 && [ file extension $f ] == ".vtk"  } {
	    set w [ vtkStructuredPointsWriter New ]
	    $w SetFileName $f
	    $w SetFileTypeToBinary
	    $w SetInput [ $transformation GetDisplacementGrid ]
	    $w Write
	    $w Delete
	    set ok 0
	    if { [ file exists $f ] } { set ok 1 }
	} else {
	    set ut [ vtkpxTransformationUtil [ pxvtable::vnewobj ]]
	    set ok [ $ut SaveAbstractTransform $transformation $f ]
	    $ut Delete
	}
	if { $ok == 0 } {
	    ::pxtclutil::Warning "Failed to Save Transformation in $f!"
	    return 0;
	} 
    }
    return 1;
}
# ----------------------------------------------------------
itcl::body pxitcltransform::Clear { } {
    
    if { [ $transformation IsA "vtkHomogeneousTransform" ] !=1 } { 
	$transformation Delete
	set transformation [ vtkTransform [ pxvtable::vnewobj ] ]
    }
    $transformation Identity
    set filename "identity"
}

itcl::body pxitcltransform::IsLinear   { } {

    if { [ $transformation IsA "vtkHomogeneousTransform" ] } {
	return 1
    } 
    return 0
}



itcl::body pxitcltransform::IsIdentity   { } {

    if { [ $transformation IsA "vtkTransform" ] !=1 } { 
	return 0
    }

    set sum 0.0

    set matr [ $transformation GetMatrix ] 
    for { set row 0 } { $row <= 3 } { incr row } {
	for { set col 0 } { $col <= 3 } { incr col } {
	    set v [ $matr GetElement $row $col ]

	    if { $row == $col } {
		set sum [ expr $sum + abs ($v-1.0) ]
	    } else {
		set sum [ expr $sum + abs ($v) ]
	    }
	}
    }

    if { $sum > 0.0001 } {
	return 0
    }

    
    return 1
}
# ----------------------------------------------------------
    
itcl::body pxitcltransform::Invert { } {
    $transformation Inverse
    set dname [ file dirname $filename ]
    set tname [ file tail    $filename ]
    set filename [ file join $dname "Inverse_${tname}" ]
}

itcl::body pxitcltransform::CompareTo  { fname { thr 0.001 } } {

    if { [ file tail $fname ] == "do_not_use" } {	return 1    }

    set tmp [ pxitcltransform \#auto ]
    set ok [$tmp Load $fname  ]
    if { $ok == 0 } {
	itcl::delete object $tmp
	return 0
    }

    set ut [ vtkbisTransformationTestUtil New ]
    $ut ClearStatus
    set ok [ $ut CompareTransformations [ $this GetTransformation ] [ $tmp GetTransformation ] $thr ]
    set a [ $ut ReturnStatus ]
    itcl::delete object $tmp
    $ut Delete
    return [ list $ok $a ]
}


# ----------------------------------------------------------
#  GUI for pxitcltransform
# ----------------------------------------------------------

itcl::class pxitcltransformGUI {

    inherit pxitclobjectGUI


    constructor { } {
	pxitclobjectGUI::constructor
    } { 
	set thisparam($this,status) "vtkTransform"
	set thisparam($this,shortfilename) "identity"
	set  description "Transformation"
	set  filename "identity.matr"
	set  numlines 4
	Reset
    }

    destructor { }

    public    method GetTransformation { } { return $itclobject  }
    public    method Initialize { basewidg } 
    public    method SetTransformation { tr } 
    public    method InvertTransformation { }

    protected method CreateNewObject { } 
    public method SetObject { tr } { return [ $this SetTransformation $tr ] }

}
# ----------------------------------------------------------
itcl::body pxitcltransformGUI::CreateNewObject { } {

    set itclobject  [ [  pxitcltransform \#auto ] GetThisPointer ]
}


itcl::body pxitcltransformGUI::InvertTransformation { } {
    $itclobject Invert 
    Update
}

itcl::body pxitcltransformGUI::SetTransformation { trn } {
    
    set continue 0
    
    catch { 
	if { [ $trn isa pxitcltransform ] == 1 } {
	set  continue 1
	}
    }

    if { $continue == 0 } {
	return 0 
    }
	
	
    if { $owns_object == 1} {
	catch { itcl::delete object $itclobject }
    }

    set itclobject $trn
    
    set owns_object 0
    Update
}

itcl::body pxitcltransformGUI::Initialize { basewidg } {

    if { $initialized == 1 } { return $basewidget }
    
    pxitclobjectGUI::Initialize $basewidg

    eval "button $buttonbar.in -text Invert -command {  $this InvertTransformation }"
    pack  $buttonbar.in  -side left -fill x -expand f
    Update
    return $basewidget
}

# ----------------------------------------------------------
#  GUI for multiple transform object
# ----------------------------------------------------------
itcl::class pxitclmultiTransformGUI {

    inherit pxitclmultiObjectGUI

    constructor { } {
	pxitclmultiObjectGUI::constructor
	set description "Transformation"
    } {
    }
    
    destructor { }
    
    public    method Initialize { basewidg } 

    public    method AddTransformation { descr }
    public    method SetTransformation { index } 
    public    method GetTransformation { index } { return [ GetObject $index ] }
    public    method DeleteTransformation { index } { DeleteObject $index }

    protected method CreateNewObject { }
    protected method CreateNewObjectGUI { widget }

}

# ----------------------------------------------------------
itcl::body pxitclmultiTransformGUI::CreateNewObject { } {
    
    return [ [  pxitcltransform \#auto ] GetThisPointer ]
}

itcl::body pxitclmultiTransformGUI::CreateNewObjectGUI { widget } {
    set itcltransformGUI [ [ pxitcltransformGUI \#auto ] GetThisPointer ]
    pack [ $itcltransformGUI Initialize $widget.[ pxvtable::vnewobj ] ] -side left -fill x
    return $itcltransformGUI
}

itcl::body pxitclmultiTransformGUI::AddTransformation { descr } {
    
    set newobj [ $this AddObject $descr ]
    set index [ expr [ llength $itclobjectlist ] -1 ]
    $this SetTransformation $index
    return $newobj
}

itcl::body pxitclmultiTransformGUI::SetTransformation { index } {

    $this SetObject $index
    $objectGUI Update
}

itcl::body pxitclmultiTransformGUI::Initialize { basewidg } {
    
    if { $initialized == 1 } { 
	return $basewidget 
    }
    
    pxitclmultiObjectGUI::Initialize $basewidg

    $listbox configure -selectmode single -exportselection 0
    set initialized 1
    
    return $basewidget
}
 

