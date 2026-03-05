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

package provide bis_polygonaldisplaymanager 1.0
package require vtkpxcontrib 1.0
package require  Itcl
package require bis_option 1.0
package require bis_common 1.0
package require Iwidgets 
package require pxitclsurface 1.0
package require pxitclmesh 1.0
package require pxitcllandmarks 1.0
package require pxitclelectrodemultigrid 1.0
package require pxitclbasecontrol 1.0
package require bis_optiondialog 

itcl::class bis_polygonaldisplaymanager {

    #
    #public
    #
    inherit pxitclbasecontrol

    constructor { { par 0 } } { 
	::pxitclbasecontrol::constructor $par
    } {	$this Initialize }
    destructor { $this CleanAll }


    # Key Outside Interface
    public method AddObject { sur { linked 0 } { attr "" }  }
    public method RemoveObject { sur { updgui 1}  }
    public method SaveObject { }
    public method LoadObject { }
    public method AddOrReplaceObject { inputsur { linked 0 } { attr "" }  } 
    public method UpdateSameObject { sur { attr "" } { updisplay 1 } }
    protected method CreateActor { sur ren }

    
    # Update Display for object
    public method UpdateObject { { sur -1 } { updviewer 1 }}
    public method UpdateRendererList { args }
    public method SetAttributes { sur attr }
    public method GetAttribute { sur attname }
    
    # Final one is GUI
    public method SetColor { }
    protected method ColorToHex { cl }
    public method ShowAll { mode }
    public method UpdateGUI { }
    public method SelectionBoxCallback { }

    public method UpdateFromGUI { args }
    public method CreateGUI { base { dlgmode 1  }}

    # Set/Get Current Object via index or pointer
    public method SetCurrentObjectIndex { indx} 
    public method SetCurrentObject { sur }
    public method GetCurrentObjectIndex { }
    public method GetCurrentObject { }


    # ------------------------------------------------------------------------------
    # Internal Stuff
    # ------------------------------------------------------------------------------

    # protected method
    protected method Initialize { } 
    public method CleanAll { } 

    # key internal variables
    protected variable objectlist ""
    protected variable rendererlist ""

    # actorarray(object,renderer)
    protected variable actorarray

    # label arrey is only for surfaces
    protected variable labelactorarray

    # attributearray(object,type) = { Surface, Landmarks, Electrodes }
    # attributearray(object,color) =
    # attributearray(object,linewidth) =
    # attributearray(object,pointsize) =
    protected variable attributearray

    # renderermode( )   , slice or volume
    protected variable renderermode
    
    protected variable externalattributelist ""
    protected variable currentobject    0
    protected variable vtk_viewer       0 
    protected variable orthoviewermode  1
    protected variable attributebox     0
    protected variable selectionbox     0
    protected variable optionslist     ""
    protected variable objindex         1
    protected variable currentsurface   0
    protected variable colorbar   0
    # Common Stuff
    protected common guiparam
};

# ------------------------------------------------------------------------------------------------------
#             Implementation
# ------------------------------------------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::Initialize { }  {
    
    set isdialog 0
    set currentobject 0
    set vtk_viewer [ $parent GetViewer ]
    if { [ $vtk_viewer IsA "vtkpxGUIOrthogonalViewer" ] } {
	set orthoviewermode 1
	set renererlist ""
	for { set i 0 } { $i <=3 } { incr i } {
	    set r [ [ $vtk_viewer GetRenderer $i ] GetRenderer ]
	    lappend rendererlist $r
	    if { $i < 3 } {
		set renderermode($r) "Slice"
	    } else {
		set renderermode($r) "Volume"
	    }
	}
    } else {
	set orthoviewermode 0
	$vtk_viewer SetCallback "$this UpdateRendererList"
	$this UpdateRendererList
    }


    set optionslist { 
	{  name "Name" "Name" comment "" ""  0 }
	{  type "Object Type" "Type" comment Surface ""  1 }
	{  color "Surface Color" "Color" comment "" ""  2 }
	{  visible "Show Object" "Show Object" boolean 0 { 0 1 }  3 }

	{  lsize "Curve Point Scale" "Curve Point Scale" { real scale } 1.0 { 0.1 10.0 }  10 }
	{  lmode "Curve Mode"       "Landmark Mode"   listofvalues landmarks { landmarks open_curve closed_curve "land+open" "land+closed"  } 11 }
	{ dispgridlist "Grid To Display" "Electrode: Disp Grids" { multiplevalues } 0 { 0 1 2 } 10 }
	{ gridfontsize "Grid Font" "Electrode: Label Font Size" listofvalues 0 { 0 6 8 10 12 14 16 24 32 } 11 }
	{ gridfontgap "Grid Label Skip" "Electrode: Label Skip" listofvalues 1 { 0 1 2 3 4 }  12 }
	{ gridshowlines "Grid Show Lines" "Electrode: Show Lines" boolean 1 { 0 1 } 13 }

	{  opacity "Surface Opacity" "Opacity" { real scale } 1.0 { 0.0 1.0 } 20 }
	{  dispmode "Display Mode (for 3D Viewer)" "Display Mode" listofvalues Filled { Filled Wireframe Points }  21 }
	{  lwidth "Line width  (for wireframe rendering)" "LineWidth" listofvalues 2.0 { 0.1 0.5 1.0 2.0 4.0 6.0 8.0 10.0 }  22 }
	{  psize "Point size  (for points rendering)" "PointSize" listofvalues 2.0 { 0.1 0.5 1.0 2.0 4.0 6.0 8.0 10.0 } 23 }

    }

    set  externalattributelist [ list name color visible lsize lmode dispgridlist gridfontsize gridfontgap gridshowlines opacity dispmode lwidth psize ]


}

itcl::body bis_polygonaldisplaymanager::CleanAll { } {

    $this ShowAll 0
    #    puts stderr "Clean All $objectlist"
    foreach obj $objectlist {    
	$this RemoveObject $obj 0
    }

#    puts stderr "Cleaning selection box $objectlist"
    $selectionbox delete 0 end
    set currentobject 0

    if { [ llength $objectlist ] > 0 } {
	for { set i 0 } { $i < [ llength $objectlist ] } { incr i } {
	    set newptr [ lindex $objectlist $i ]
	    $selectionbox insert end $attributearray($newptr,name) 
	}
	$selectionbox selection set end end
	$this SetCurrentObject $newptr
	$this UpdateGUI
	$this UpdateObject $newptr
	return
    }

    $this UpdateGUI
}

# -----------------------------------------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::UpdateSameObject { sur { attr "" } { updisplay 1 } } {

    set v [ lsearch $objectlist $sur ]
    if { $v == -1 } {
	puts stdout "Object $sur not found"
	return 0
    }

    if { $attr != "" } {
	$this SetAttributes $sur $attr
    }



    foreach ren $rendererlist {
	
	set map [ $actorarray($sur,$ren) GetMapper ]
	if { [ $sur isa pxitclsurface ] } {
	    $map SetInput [ $sur GetObject ] 
	} elseif { [ $sur isa pxitclmesh ] } {
            $map SetInput [ $sur GetSurfaceRepresentation ]
	} else {
	    $map SetInput [ [ $sur GetObject ] GetOutput ]
	}
	if { [ $sur isa pxitclelectrodemultigrid  ] } {
	    set map [ $labelactorarray($sur,$ren) GetMapper ]
	    $map SetInput [ [ $sur GetObject ] GetLabelSurface ]
	}
    
	if { [ $sur isa pxitclelectrodemultigrid  ] } {
	    [ $labelactorarray($sur,$ren) GetMapper ] Modified
	    $labelactorarray($sur,$ren) Modified
	}

	$map Modified
	$actorarray($sur,$ren) Modified
	
    }
    $this UpdateObject $sur $updisplay
    $this UpdateGUI
    return 0
}
# -----------------------------------------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::AddOrReplaceObject { inputsur { linked 0 } { attr "" }  } { 

#    puts stderr "Add Or Replace\n"
    if { $inputsur == 0 || $inputsur == "" } { return 0 }
    set v [ lsearch $objectlist $inputsur ]
    if { $v > -1 } { 
#	puts stderr "Updating Same\n"
	return [ $this UpdateSameObject $inputsur $attr ]
    } 

    set fn [ $inputsur cget -filename ]
    if { $fn == "" || $fn == "0" || [ file tail $fn ] == "0" } {
#	puts stderr "On to adding fn=$fn"
	return [ $this AddObject $inputsur $linked $attr ]
    }
    
    set goodsurface 0

#    puts stderr "Linked=$linked, looking for inputsur in $objectlist"

    set v [ lsearch $objectlist $inputsur ]

    foreach tmpsur $objectlist {
	set f2 ""
	set f2 $attributearray($tmpsur,filename) 
	if { $f2 == $fn && $f2 != "" } { 
	    #	    puts stderr "Found existing copying ... $inputsur [ $inputsur isa pxitclsurface ], $tmpsur, [ $tmpsur  isa pxitclsurface ], linked=$linked"
	    if { [ $tmpsur isa "pxitclsurface" ] == 1 || [ $tmpsur isa "pxitclmesh" ] == 1 } {
		$tmpsur ShallowCopy $inputsur
	    } else { 
		$tmpsur Copy $inputsur
	    }
	    set goodsurface $tmpsur
	}
    }
    
    if { $goodsurface == 0 } {
#	puts stderr "no good surface .... adding $inputsur"
	$this AddObject $inputsur $linked $attr
	return 1
    }

    $this UpdateSameObject $goodsurface $attr 
    $this SetCurrentObject $goodsurface
    return 0
}
# -----------------------------------------------------------------------------------------------------

itcl::body bis_polygonaldisplaymanager::AddObject { sur { linked 0 } { attr "" }  } {

    if { $sur == 0 || $sur == "" } { 
	return 0
    }

#    puts stderr "\n\n\n\n AddObject Sur=$sur linked=$linked attr=$attr  addingobject"

    set newptr 0
    set adding 1

    if { $linked > 0 } {
	set v [ lsearch $objectlist $sur ]
	set newptr $sur
	if { $v > -1 } {
#	    puts stderr "Linked::Object $sur exists, nothing to do ... updating same"
	    return [ $this UpdateSameObject $sur $attr ]
	} else {
#	    puts stderr "Linked::Object $sur does not exist adding to pointer list"
	    lappend objectlist $newptr
	    set adding 1
	}
    } else {
#	puts stderr "Not Linked:Copying and creating surface "
	set cl [ $sur info class ]
	set newptr [ [ eval "$cl \#auto" ]  GetThisPointer ]
	if { [ $newptr isa pxitclsurface ] || [ $newptr isa pxitclmesh ] } {
	    $newptr ShallowCopy $sur
	} else { 
	    $newptr Copy $sur
	}
	set adding 1
	lappend objectlist $newptr
    }


    set l [ expr [ llength $objectlist ] -1 ]
    while { $l > 10 } {
	set l [ expr $l -10 ]
    }

    if { [ $newptr isa pxitclelectrodemultigrid  ] } {
	set cl "1.0 1.0 1.0"
    } else {
	set ut [ vtkpxSurfaceUtil New ]
	set cl [ $ut GetColor $l ]
	$ut Delete
    }

    set attributearray($newptr,linked) [ expr $linked > 0 ]

    set attributearray($newptr,color) $cl
    set attributearray($newptr,opacity)    1.0
    set attributearray($newptr,type)      Electrodes
    set attributearray($newptr,visible)     1
    set attributearray($newptr,lwidth)  2.0
    set attributearray($newptr,psize)  3.0
    set attributearray($newptr,dispmode)    "Filled"
    set attributearray($newptr,dispgridlist) ""
    set attributearray($newptr,gridfontsize) 12
    set attributearray($newptr,gridfontgap) 2
    set attributearray($newptr,gridshowlines) 1
    set attributearray($newptr,name) ""

    if { [ $newptr isa pxitclsurface  ] } {
	set attributearray($newptr,type)      Surface
    } 

    if { [ $newptr isa pxitclmesh  ] } {
	set attributearray($newptr,type)      Mesh
    } 

    if { [ $newptr isa pxitcllandmarks  ] } {
	set attributearray($newptr,type)      Landmarks
	set attributearray($newptr,lsize)  1.0
	set attributearray($newptr,lmode)  "land+open"
    }


    if { [ $newptr isa pxitclelectrodemultigrid  ] } {
	set multigrid [ $newptr GetObject ]
	for { set i 0 } { $i < [ $multigrid GetNumberOfGrids ] } { incr i } {
	    [ $multigrid GetElectrodeGrid $i ] Modified
	    [ $multigrid GetElectrodeGrid $i ] SetVisible [ expr ($i == 0) ] 
	}
	set attributearray($newptr,dispgridlist) [ $newptr GetDisplayedGridNamesList ]
    }

    if { $attr != "" } {
	# Potentially copy stuff from attributes
#	puts stderr "Adding Copying attributes $attr"
	$this SetAttributes $newptr $attr
    }

    foreach ren $rendererlist {
	$this CreateActor $newptr $ren
    }

#    puts stderr "Adding $newptr, linked = $attributearray($newptr,linked)"


    if { $attributearray($newptr,name) == "" } {
	set filename [ $newptr cget -filename ]  
	set attributearray($newptr,filename) $filename    
	set fn [ file tail $filename  ]
	if { [ string length $fn ] < 2 } {
	    set fn $attributearray($newptr,type)
	}
    } else {
	set fn $attributearray($newptr,name)
    }

    set fn "${fn}.${objindex}" ; incr objindex
    $selectionbox insert end $fn
    if {  $attributearray($newptr,linked) > 0 } {  
	set fn "RO:${fn}"
    }
    set attributearray($newptr,name) $fn

    update idletasks
    $selectionbox selection clear 0 end
    $selectionbox selection set end end
    

    
    $this SetCurrentObject $newptr
    $this UpdateGUI
    $this UpdateObject $newptr

}
# -------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::GetAttribute { sur attname } {
    set v [ lsearch $objectlist $sur ]
    if { $v == -1 } {
	return 0
    }

    if { [ lsearch -exact $externalattributelist $attname ] > -1 } {
	return $attributearray($sur,$attname) 
    }

    return 0
}

itcl::body bis_polygonaldisplaymanager::SetAttributes { sur attr } {

    set v [ lsearch $objectlist $sur ]
    if { $v == -1 } {
	return 0
    }

    set n [ llength $attr ]
    set maxn [ expr $n -1 ]
    if { $maxn < 1 } {
	return
    }
	
    for { set i 0 } { $i < $maxn } { set i [ expr $i +2 ] } {
	set attname [ lindex $attr $i ]
	set val     [ lindex $attr [ expr $i +1 ] ]
	if { [ lsearch -exact $externalattributelist $attname ] > -1 } {
	    set attributearray($sur,$attname) $val
	    #	    puts stderr "Setting attributes of $sur $attname=$val"
	}
    }


}
# -----------------------------------------------------------------------

itcl::body bis_polygonaldisplaymanager::CreateActor { sur ren  }  {

    set map [ vtkPolyDataMapper New ]
    #if { [ $sur isa pxitclsurface ] || [ $sur isa pxitclmesh ] } {}
    if { [ $sur isa pxitclsurface ] } {
	$map SetInput [ $sur GetObject ] 
    } elseif { [ $sur isa pxitclmesh ] } {
        $map SetInput [ $sur GetSurfaceRepresentation ]
    } else { 
	$map SetInput [ [ $sur GetObject ] GetOutput ]
    } 
    #$map SetInput [ [ $sur GetObject ] GetLabelSurface ]

    set act [ vtkActor New ]
    $act SetMapper $map
    $map Delete
    $act SetVisibility 0
    $ren AddActor $act
    set actorarray($sur,$ren) $act
    
    if { [ $sur isa pxitclelectrodemultigrid  ] } {
	
	set m [ vtkLabeledDataMapper [ pxvtable::vnewobj ]]
	$m SetInput [ [ $sur GetObject ] GetLabelSurface ]
	$m SetLabelModeToLabelScalars

	set a [ vtkActor2D [ pxvtable::vnewobj ]]
	$a SetMapper $m
	$a SetVisibility 0
	set labelactorarray($sur,$ren) $a
	$m Delete

	$ren AddActor2D $a
    }
}

# -----------------------------------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::SaveObject { } {

    set sur $currentobject 
    $sur Save ""
}
# -----------------------------------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::LoadObject { } {

    set sur [ [ pxitclsurface \#auto ] GetThisPointer ]
    $sur Load ""
    set n [ $sur GetSurfaceSize ]
    if { $n > 3 } {
	$this AddObject  $sur
    }
    itcl::delete obj $sur 
}
# -----------------------------------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::RemoveObject { sur { updgui 1 } }  {

    if { $sur == 0 } { set sur $currentobject }
    if { $sur == 0 } { return }

    set ind [ lsearch -exact $objectlist $sur ]
    if { $ind == - 1 } {
	return 0
    }



    if { $attributearray($sur,linked) > 0 } {
	if { $updgui == 1 } {
	    set ok [ tk_messageBox -type ok -default ok -title "Think again ..." -message "This object can not be deleted" -icon info  ]
	} else {
	    puts stderr "Not Removing $sur, linked=$attributearray($sur,linked)"	    
	}
	return 0
    }

    if { $updgui == 1 } {
	set ok [ tk_messageBox -type yesno -default no -title "Think again ..." -message "Do you want to delete $attributearray($sur,name)?" -icon question  ]
	if { $ok == "no" } {
	    return
	}
    }

    foreach ren $rendererlist {
	$ren RemoveActor $actorarray($sur,$ren)
	$actorarray($sur,$ren) Delete
	if { [ $sur isa pxitclelectrodemultigrid  ] } {
	    $ren RemoveActor $labelactorarray($sur,$ren)
	    $labelactorarray($sur,$ren) Delete
	}
    }
    #    array unset attributearray "(${sur},*"

#    puts stderr "Objectlist $objectlist -->\n"

    if { $ind > 0 } {
	set obj1 [ lrange $objectlist 0 [ expr $ind -1 ] ]
    } else { 
	set obj1 ""
    }
    set obj2 [ lrange $objectlist [ expr $ind +1 ] end ]

    set objectlist [ concat $obj1 $obj2 ]
#    puts stderr "\t\t $objectlist -->\n"

    itcl::delete object $sur
    
    if { $updgui } {
#	puts stderr "Cleaned Selection box"
	$selectionbox delete 0 end
#	puts stderr "Cleaned Selection box"
	for { set i 0 } { $i < [ llength $objectlist ] } { incr i } {
	    set newptr [ lindex $objectlist $i ]
	    $selectionbox insert end $attributearray($newptr,name)
#	    puts stderr "Inserting $attributearray($newptr,name)"
	}

	if { $currentobject ==  $sur } {
	    if { [ llength $objectlist  ] > 0 } {
		set currentobject [ lindex $objectlist 0 ]
		$selectionbox selection set 0 0
	    } else {
		set currentobject 0
	    }
	    $this UpdateGUI
	}
    }
}


# -------------------------------------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::UpdateObject { { sur -1 } { updviewer 1 }} {

    if { $vtk_viewer == 0 } {	return    }
    if { $sur == -1 } {	set sur [ $this GetCurrentObject ]    } 
    if { [ llength $rendererlist ] == 0 } { return }
    if { [ llength $objectlist ] == 0 } { return }



    set ind [ lsearch -exact $objectlist $sur ]
    if { $ind < 0 } {
	return 0
    }

    set tp  $attributearray($sur,type)     
    regsub -all "\"" $tp "" tp

    if { $tp == "Landmarks" } {
	set land [ $sur GetLandmarks ]
	$land SetPointScale $attributearray($sur,lsize)  
	set sland $attributearray($sur,lmode)
	set cl 0   ; if { $sland == "closed_curve" || $sland == "land+closed"  } { set cl 1 } 
	set sc 0   ; if { $sland != "landmarks" } { set sc 1 } 
	set sl 1   ; if { $sland == "closed_curve" || $sland == "open_curve" } { set sl 1 }
	$land SetClosedCurve  $cl
	$land SetShowCurve    $sc
	$land SetShowControls $sl
	$land Update
    } elseif { $tp == "Electrodes" } {
	$sur SetLabelGap $attributearray($sur,gridfontgap) 
	#	puts stdout "Setting SetLabelGap to $attributearray($sur,gridfontgap) "
	$sur SetGridNamesToDisplay $attributearray($sur,dispgridlist)
	$sur SetJustShowElectrodes [ expr 1 - $attributearray($sur,gridshowlines) ] 

	set egrid [ $sur GetObject ]
	$egrid Modified
    }

    # --------------------------------------------

    foreach ren $rendererlist { 

	set cl  $attributearray($sur,color) 

	set act $actorarray($sur,$ren)
	set prop [ $act GetProperty ]
	
	regsub -all "\"" $cl "" cl
	if {  [ llength $cl ] == 3 } {
	    $prop SetColor [ lindex $cl 0 ] [ lindex $cl 1 ] [ lindex $cl 2 ]
	}
	$prop SetOpacity  $attributearray($sur,opacity)   

	set dt $attributearray($sur,dispmode)    
	if { $renderermode($ren) == "Slice" } {
	    set dt "Wireframe"
	}
	    
	$prop SetLineWidth $attributearray($sur,lwidth)
	$prop SetPointSize $attributearray($sur,psize)

	if { $dt == "Filled" } {
	    $prop SetRepresentationToSurface
	    $prop SetDiffuse 1.0
	    $prop SetAmbient 0.0
	    $prop SetSpecular 0.0
	} else {
	    $prop SetDiffuse 0.0
	    $prop SetAmbient 1.0
	    $prop SetSpecular 0.0
	    if { $dt == "Wireframe" } {
		$prop SetRepresentationToWireframe
	    } else {
		$prop SetRepresentationToPoints
	    }
	}

	$act SetVisibility $attributearray($sur,visible)
	if { [ $sur isa pxitclelectrodemultigrid  ] } {
	    set fontsize $attributearray($sur,gridfontsize)
	    set act $labelactorarray($sur,$ren)
	    set map [ $act GetMapper ]
	    set prop [ $map GetLabelTextProperty ]
	    if { $renderermode($ren) == "Slice" } {
		$act SetVisibility 0
	    } elseif { $fontsize > 0 } {
		$prop SetFontSize $fontsize
		$prop ShadowOff
		if {  [ llength $cl ] == 3 } {
		    $prop SetColor [ lindex $cl 0 ] [ lindex $cl 1 ] [ lindex $cl 2 ]
		}
		$map Modified
		$act Modified
		$act SetVisibility 1

	    } else {
		$act SetVisibility 0
	    }
	}
    }

    if { $updviewer > 0 } {
	$vtk_viewer Update
    }
}
# -----------------------------------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::UpdateRendererList { args } {

    if { $orthoviewermode == 1 } {
	return 0
    }

    #    puts stderr "updating renderer list"

    set numold [ llength $rendererlist ]
    set newrenlist ""
    set num [ $vtk_viewer GetNumberOfViewers ]
    for { set i 0 } { $i < $num } { incr i } {
	set r [ $vtk_viewer GetRenderer $i ] 
	if { $r !="" } {
	    if { [ lsearch -exact $rendererlist $r ] == -1 } {
		#		puts stderr "Adding Renderer $r"
		lappend rendererlist $r
		lappend newrenlist $r
		set renderermode($r) "Slice"
	    } 
	}
    }

    if { [ llength $objectlist ] > 0  && [ llength $newrenlist ] > 0  } {
	foreach ren $newrenlist  {
	    foreach sur $objectlist {
		#		puts stderr "Creating new actor $sur $ren"
		$this CreateActor $sur $ren
	    }
	}

	foreach sur $objectlist {
	    $this UpdateObject $sur
	}
	return 1
    }
    
    return 0
    
}

# --------------------------------------------------------------------
#
# Get/Set Current Object
#
# --------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::GetCurrentObject { } {

    if { $objectlist == "" } {	return 0 }
    return $currentobject 
}

# --------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::SetCurrentObject { sur } {
    if { $objectlist == "" } {	return }

    set ind [ lsearch -exact $objectlist $sur ]
    if { $ind != -1 } {
	$this SetCurrentObjectIndex $ind
	set currentobject $sur
    }
}
# -------------------------------------------------------------------------    
itcl::body bis_polygonaldisplaymanager::SetCurrentObjectIndex { index } {

    if { $objectlist == "" } {	return }

    $selectionbox selection clear 0 end
    $selectionbox selection set $index $index

}
# --------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::GetCurrentObjectIndex { } {
    if { $objectlist == "" } {	return 0 }
    set ind [ lsearch -exact $objectlist $currentobject ]
    return $ind

}

# -------------------------------------------------------------------------    
#
# Create and update GUI
#
# -------------------------------------------------------------------------    
itcl::body bis_polygonaldisplaymanager::UpdateFromGUI { args } { 

    set sur [ $this GetCurrentObject ]
    if { $sur == 0 } {
	return
    }



    for { set i 1 } { $i < [ llength $optionslist ] } { incr i } {
	set opt [ lindex [ lindex $optionslist $i ] 0 ]
	set attributearray($sur,$opt) [ $attributebox GetOptionValue $opt ]
	#	puts stderr "Setting ($sur,$opt) to [ $attributebox GetOptionValue $opt ]"
    }

    $this UpdateObject $sur

}
# ------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::ShowAll { md } {
    set md [ expr $md > 0 ]

    foreach obj $objectlist {    
	set attributearray($obj,visible)  $md
	foreach ren $rendererlist {
	    $actorarray($obj,$ren) SetVisibility $md
	}
    }
    $this UpdateGUI
    $vtk_viewer Update
}
# ------------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::ColorToHex { cl } {

    regsub -all "\"" $cl "" cl


    if { [ llength $cl ]  != 3 } {
	set cl { 1.0 0.0 0.0 }
    }

    set line "\#"
    for { set i 0 } { $i <= 2 } { incr i } {
	set v 0.0
	catch { set v [expr int(255.0*[ lindex $cl $i ])] }
	if { $v < 0 } {set v 0 }
	if { $v > 255 } { set v 255 }
	set h [format %02x $v ]
	set line "$line$h"
    }
    return $line
}
# ------------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::SetColor { } {

    set sur [ $this GetCurrentObject ]
    if { $sur == 0 } {
	return
    }


    set cl  $attributearray($sur,color) 
    set line [ $this ColorToHex $cl ]

    set name 	[ $attributebox GetOptionValue name ]
    set inhex [ tk_chooseColor -title "Color for $name" -initialcolor $line -parent $basewidget ]
    if { $inhex == "" } {
	return
    }
    set inhex [ string range $inhex 1 end ]

    for { set i 0 } { $i <=2 } { incr i } {
	set im [ expr 2*$i ]
	set ip [ expr $im + 1 ]
	set nh  [ string range $inhex $im $ip ]
	set out($i) [expr 0x$nh]
	set out($i) [ expr $out($i) / 255.0 ]

    }

    set outcl [ format "%.2f %.2f %.2f" $out(0) $out(1) $out(2) ]


    set attributearray($sur,color) $outcl
    $this UpdateObject $sur
    $this UpdateGUI


}
# ------------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::SelectionBoxCallback { } { 

    set ind [ [ $selectionbox component listbox ] curselection ]
#    puts stderr "Here in Callback ind=$ind"
    if { $ind == "" || $ind < 0 } {
	return 
    }
    set currentobject [ lindex $objectlist $ind ]
    $this UpdateGUI 

}

itcl::body bis_polygonaldisplaymanager::UpdateGUI { } {

    set sur [ $this GetCurrentObject ]
    if { $sur == 0 } {
	return
    }
    
    set md 0
    if { [ $sur isa pxitclelectrodemultigrid  ] } {
	set md 2 
    } elseif { [ $sur isa pxitcllandmarks  ] } {
	set md 1
    } 

    foreach opt { lsize lmode } {
	if { $md != 1 } {
	    $attributebox DisableOption $opt
	} else {
	    $attributebox EnableOption $opt
	    $attributebox SetOptionValue $opt $attributearray($sur,$opt)
	}
    }


    foreach opt { gridfontsize gridfontgap gridshowlines } {
	if { $md != 2 } {
	    $attributebox DisableOption $opt
	} else {
	    $attributebox EnableOption $opt
	    $attributebox SetOptionValue $opt $attributearray($sur,$opt)
	}
    }

    if { $md != 2 } {
	$attributebox DisableOption dispgridlist
    } else {
	$attributebox EnableOption dispgridlist
	$attributebox SetOptionRange dispgridlist [ $sur GetGridNamesList ]
	$attributebox SetOptionValue dispgridlist [ $sur GetDisplayedGridNamesList ]
    }


    foreach opt { name color type }  {
	regsub -all "\"" $attributearray($sur,$opt) "" tp
	if { $opt == "color" } {
	    $attributebox SetOptionValue $opt $tp
	    set optgui [ [ $attributebox GetOption $opt ]  GetBaseWidget ]
	    set h [ $this ColorToHex $tp ]
	    $colorbar configure -background  [ $this ColorToHex $tp ]
	} else {
	    $attributebox SetOptionValue $opt $tp
	}
    }

    foreach opt { opacity visible dispmode lwidth psize } {
	$attributebox SetOptionValue $opt $attributearray($sur,$opt)
	$attributebox EnableOption $opt
    }

}
# -------------------------------------------------------------------------------------------------
itcl::body bis_polygonaldisplaymanager::CreateGUI { base { dlgmode 1  } } {

    if { $basewidget !=0 } { return $basewidget }

    set basewidget $base
    if { $dlgmode > 0 } {
	toplevel $basewidget
	wm withdraw $basewidget
	eval "wm protocol $basewidget WM_DELETE_WINDOW { wm withdraw $basewidget  }"
	wm geometry $basewidget 500x480
	wm title $basewidget "Surface Display Manager"
	set isdialog 1

	#	set bar [ frame $basewidget.bt ]
	#	pack $bar -side bottom -expand false -fill x

	set btf $basewidget
    } else {
	set btf [ [ iwidgets::labeledframe $basewidget  -labeltext "Polygonal Object Control"  ] childsite ]
	set isdialog 0
	pack $basewidget -side top -expand true -fill both
    }


    set bbar [ iwidgets::buttonbox $basewidget.bt -orient horizontal ]
    set bbar2 [ frame $basewidget.bt2 -height 2 -bg black ]
    set bbar0 [ iwidgets::buttonbox $basewidget.bt0 -orient horizontal ] 
    pack $bbar $bbar0 $bbar2 -side bottom -expand false -fill x 


    # ------------------------------------------------------------------------------

    set w [ frame $btf.b -width 400]

    set lf [ [ iwidgets::labeledframe $btf.a  -labeltext "List"  ] childsite ]
    frame $btf.mid -width 2 -bg black 
    pack $btf.a -side left -expand true -fill both
    pack $btf.mid -side left -expand false -fill y

    set colorbar $lf
    eval "iwidgets::scrolledlistbox $lf.a -selectmode single -labelpos nw -vscrollmode dynamic -hscrollmode dynamic -selectioncommand { $this SelectionBoxCallback } -exportselection 1 -height 500"

    pack $lf.a -side top -expand false -fill both -padx 4 -pady 4
    pack $w -side right -expand false -fill y
    set selectionbox $lf.a 

    set attributebox  [ bis_optiondialog \#auto ]
    $attributebox SetCallback "$this UpdateFromGUI"
    $attributebox CreateGUI $w 0 $optionslist


    $bbar0 add sv1  -text "Add Surface" -command [ itcl::code  $this LoadObject ]
    $bbar0 add sv2  -text "Save Object" -command [ itcl::code  $this SaveObject ]


    set bb [ $attributebox GetButtonBar ]
    $bb add cl  -text "Set Color" -command [ itcl::code  $this SetColor ]
    $bbar add dl  -text "Delete Current" -command [ itcl::code  $this RemoveObject 0 ]
    $bbar add c1  -text "Hide All" -command [ itcl::code  $this ShowAll 0 ]
    $bbar add c2  -text "Show All" -command [ itcl::code  $this ShowAll 1 ]
    if { $dlgmode > 0 } {
	$bbar add c3  -text "Close" -command [ itcl::code  $this HideWindow ]
    }


    # ------------------------------------------------------------------------------
    return $basewidget
}
# -------------------------------------------------------------------------------------------------
















