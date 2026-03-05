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

package provide pxitclsurface 1.0

# 	$Id: pxitclsurface.tcl,v 1.2 2003/08/14 17:49:42 xenios Exp xenios $	




package require  pxitclobject  1.0
package provide pxitclsurface 1.0

# -------------------------------------------------------------------
# Definition of pxitclsurface
#
#    a class that encapsulates an image (vtkImageData)
#            its orientation , filename and status
# -------------------------------------------------------------------

itcl::class pxitclsurface {

    inherit pxitclobject

    # --- begin variable def -----

    public variable status 
    protected variable sur 

    # --- end of variable def -----

    constructor { } {
	pxitclobject::constructor 
    } {
	CreateNewSurface
	UpdateStatus    
    }

    destructor  { $sur Delete     }


    # --- begin method def -----
    public method GetObject { } { return $sur }
    public method GetType { } { return [ $sur GetNumberOfPoints ] }
    public method GetDescription { } 
    public method UpdateStatus { } { set status [ $sur GetNumberOfPoints ]  }
    public method Copy   { obj args }
    public method Clear { } 
    public method UnLoad { } { return [ Clear ] }

    public method Load   { args }
    public method Save   { args }

    # Methods additional to pxitclobject
    
    public method GetSurface { } { return $sur }

    public method GetLongDescription { } 
    public method GetShortDescription { } 
    public method GetSurfaceSize { } 
    public method GetSize { } { return [ $this GetSurfaceSize ] }

    public method DeepCopy    { obj } { Copy $obj 1    }
    public method ShallowCopy { obj } { Copy $obj 0    }

    public method DeepCopySurface    { newsur } { CopySurface $newsur 1    }
    public method ShallowCopySurface { newsur } { CopySurface $newsur 0    }
    public method CopySurface   { newsur mode }

    public method CreateNewSurface { } 

    # Procedures to Just Set Filename
    public method Browse { description }

    # Procedures to Ship To Viewer
    public method Display { baseviewer }
    public method Transform { gen }


    # Compare with FileName
    public method CompareTo  { fname { thr 0.001 } } 
    # This is misnomer it really is a correspondence check
    public method CorrelateWith  { fname { thr 1.0 } }

    # --- end method def -----
}

# ------------------- End of Header ---------------------------------
itcl::body pxitclsurface::CreateNewSurface { } {

#    set sphere [ vtkSphereSource [ pxvtable::vnewobj ]]
#    $sphere SetRadius 1
#    $sphere Update

    set sur [ vtkPolyData [ pxvtable::vnewobj ]]
#    $sur ShallowCopy [ $sphere GetOutput ]
#    $sphere Delete
}


itcl::body pxitclsurface::Copy   { obj args } {

    set mode 0
    if { [ llength $args ] > 0 } {
	set mode [ expr [ lindex $args 0 ] > 0 ]
    }

    if { [ $obj isa pxitclsurface ] == 0 } {
	return 0
    }

    set oldimg [ $obj GetSurface ] 
    CopySurface $oldimg $mode
    set filename    [ $obj cget -filename ]
    UpdateStatus
}
# ----------------------------------------------------------
itcl::body pxitclsurface::CopySurface { newimg mode } {

    set mode [ expr $mode > 0 ]

    if { [ $newimg IsA "vtkPolyData" ] == 0 } {
	puts stdout "Bad Input"
	return
    }

    $sur Delete
    set sur [ vtkPolyData [ pxvtable::vnewobj ]]

    #    puts stderr "In Copy Surface mode=$mode, sur = $sur [ $sur GetClassName ], newimg=$newimg [ $newimg GetClassName ]"

    if { $mode == 0 } {
	$sur ShallowCopy $newimg
    } else {
	$sur DeepCopy $newimg
    }

    UpdateStatus
}

# ----------------------------------------------------------
itcl::body pxitclsurface::Clear { } {
    catch { $sur Delete }
    CreateNewSurface
    set orientation 0
    set filename    ""
    UpdateStatus
}
# ----------------------------------------------------------
itcl::body pxitclsurface::GetSurfaceSize { } {

    return [ $sur GetNumberOfPoints ]
}

# ----------------------------------------------------------
itcl::body pxitclsurface::GetLongDescription { } {
    
    set x1 [ $sur GetNumberOfPoints ] 
    set s1 [ $sur GetNumberOfCells  ]
    set bd [ $sur GetBounds ]
    set t1 [ $sur GetNumberOfScalarComponents ] 
    
    set line [ format "Number Of Points %d Cells=%d Bounds= $bd" $x1 $s1 ]

    set line  "name=$this\n\t$line\n\tFilename= $filename"
    return $line
}
# ----------------------------------------------------------
itcl::body pxitclsurface::GetDescription { } {
    
    set x1 [ $sur GetNumberOfPoints ] 
    set s1 [ $sur GetNumberOfCells  ]
    set line [ format "Number Of Points %d Cells=%d" $x1 $s1 ]
    set line  "$line\nFilename=$filename\n"
    return $line
}
# ----------------------------------------------------------
itcl::body pxitclsurface::GetShortDescription { } {
    
    set x1 [ $sur GetNumberOfPoints ] 
    set s1 [ $sur GetNumberOfCells  ]
    set line [ format "Number Of Points %d Cells=%d" $x1 $s1 ]
    set line  "[ file tail $filename]  $line"
    return $line
}
# ----------------------------------------------------------
itcl::body pxitclsurface::Browse { description } {

    set f2path [ file dirname $filename ]
    set f2tail [ file tail    $filename ]
	
    set fname  [tk_getOpenFile -title "Get Filename for $description" -filetypes { {"Surface Files" {.vtk .vtp}}} -initialfile $f2tail -initialdir $f2path ]   
    if { [ string length $fname ] > 0 } {
	set filename $fname
	return 1
    }
    return 0
}
# ----------------------------------------------------------
itcl::body pxitclsurface::Load { args } {

    set len [ llength $args ]
    if { [ string length $filename ] == 0 && $len == 0 } { return  }


    if { $len < 1 } {
	set fname $filename
    } else  { 
	set fname [ lindex $args 0 ] 
    }

    if { $len > 1 } { 
	set desc [ lindex $args 1 ]
    } else {
	set desc "Surface"
    }


    if { [ string length $fname ] == 0 } {


	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set typelist { {"VTK Surface Files" { .vtk .vtp } } { "STL Files" { .stl }} }
	set fname  [tk_getOpenFile -title "Load $desc" -filetypes $typelist -initialfile $f2tail -initialdir $f2path ]   
    }
    

    if { [ string length $fname ] <1 } {
	return 0
    }

    catch {
	if { [ file extension $fname ]  == ".stl"  } {
	    set ana [ vtkSTLReader [ pxvtable::vnewobj ]]
	} elseif { [ file extension $fname ]  == ".vtp"  } {
	    set ana [ vtkXMLPolyDataReader [ pxvtable::vnewobj ]]
	} else {
	    set ana [ vtkPolyDataReader [ pxvtable::vnewobj ]]
	}
	$ana SetFileName $fname
	$ana Update
	$this ShallowCopySurface [ $ana GetOutput ]
	$this configure -filename $fname
	$ana Delete
    }
    return 1
}
# ----------------------------------------------------------
itcl::body pxitclsurface::Save { args } {

    set len [ llength $args ]
    if { $len < 1 } {
	set fname $filename
    } else  { 
	set fname [ lindex $args 0 ] 
    }

    set desc "Surface"
    if { $len > 1 } { 
	set desc [ lindex $args 1 ]
    }


    if { [ string length $fname ] == 0 } {
	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set typelist { {"VTK Surface Files" { .vtk } } { "STL Files" { .stl }} }
	set fname  [tk_getSaveFile -title "Saving $desc" -filetypes $typelist -initialfile $f2tail -initialdir $f2path ]   
    }
    
    if { [ string length $fname ] < 0 } {
	return 0
    }
    
    if { [ file extension $fname ] == ".stl" } {
	set ana [ vtkSTLWriter  [ pxvtable::vnewobj ]]
    } else {
	set ana [ vtkPolyDataWriter  [ pxvtable::vnewobj ]]
    }
    $ana SetInput $sur
    $ana SetFileTypeToBinary
    $ana SetFileName $fname
    $ana Update
    set filename $fname

    $ana Delete 
    return 1
}
# ----------------------------------------------------------
itcl::body pxitclsurface::Display { baseviewer } {
    
    set polydatacontrol 0
    catch {     set  polydatacontrol [ [ $baseviewer GetPolyDataControl ] GetPolyDataControl ] }

    if { $polydatacontrol == 0 } {
	::pxtclutil::Warning "Bad baseviewer ($baseviewer) Specified. Cannot display surface\n"
	return 0
    }

    $polydatacontrol SetClipboardSurface $sur $filename
    ::pxtclutil::Info "Placed surface $filename in the clipboard of the surface control"
    
    [ $baseviewer GetPolyDataControl ] ShowWindow
    return 1
} 
# ----------------------------------------------------------
itcl::body pxitclsurface::Transform { transformation } {
    
    set vt [ vtkTransformPolyDataFilter [ pxvtable::vnewobj ]]
    $vt SetInput $sur
    $vt SetTransform $transformation
    $vt Update
    $this ShallowCopySurface [ $vt GetOutput ]
    $vt Delete
    return 1
} 


itcl::body pxitclsurface::CompareTo  { fname { thr 0.001 } } {

    set tmp [ pxitclsurface \#auto ]
    set ok [$tmp Load $fname  ]
    if { $ok == 0 } {
	itcl::delete object $tmp
	return 0
    }

    set ut [ vtkbisTestUtil New ]
    $ut ClearStatus
    set ok [ $ut CompareSurfaces [ $this GetSurface ] [ $tmp GetSurface ] $thr ]
    set a [ $ut ReturnStatus ]
    itcl::delete object $tmp
    $ut Delete
    return [ list $ok $a ]
}


itcl::body pxitclsurface::CorrelateWith  { fname { thr 1.0 } } {

    set tmp [ pxitclsurface \#auto ]
    set ok [$tmp Load $fname  ]
    if { $ok == 0 } {
	itcl::delete object $tmp
	return 0
    }

    set ut [ vtkbisTestUtil New ]
    $ut ClearStatus
    set ok [ $ut CompareSurfacesByCorrespondence [ $this GetSurface ] [ $tmp GetSurface ] $thr ]
    itcl::delete object $tmp
    set a [ $ut ReturnStatus ]
    $ut Delete
    return [ list $ok $a ]

}
# ----------------------------------------------------------
#  GUI for pxitclsurface
# ----------------------------------------------------------
itcl::class pxitclsurfaceGUI {

    inherit pxitclobjectGUI

    public variable browsebutton

    constructor { } {
	pxitclobjectGUI::constructor
    } { 
	set thisparam($this,status) "vtkPolyData"
	set thisparam($this,shortfilename) "none"
	set thisparam($this,descriptionbox) 0
	Reset
    }

    destructor { }

    public method SetObject { tr } { return [ SetSurface $tr ] }
    public    method GetSurface { } { return $itclobject  }

    protected method CreateNewObject { } 
    public    method Initialize { basewidg } 
    public    method SetSurface { isur }
    public    method BrowseSurface { } 


}
# ----------------------------------------------------------
itcl::body pxitclsurfaceGUI::CreateNewObject { } {
    set itclobject  [ [  pxitclsurface \#auto ] GetThisPointer ]
}

itcl::body pxitclsurfaceGUI::BrowseSurface { } {
    $itclobject Browse $description
    Update
}

itcl::body pxitclsurfaceGUI::SetSurface { trn } {
    
    if { [ $trn isa pxitclsurface ] == 0 } {
	return 0
    }
	
    if { $owns_object == 1} {
	catch { itcl::delete object $itclobject }
    }

    set itclobject $trn
    set owns_object 0
    Update
}

itcl::body pxitclsurfaceGUI::BrowseSurface { } {
    $itclobject Browse $description
    Update
}

itcl::body pxitclsurfaceGUI::Initialize { basewidg } {

    if { $initialized == 1 } { return $basewidget }
    pxitclobjectGUI::Initialize $basewidg

    set browsebutton [ eval "button $buttonbar.b -text Browse -command { $this BrowseSurface }" ]
    pack  $buttonbar.b   -side left -fill x -expand f
    update idletasks

    Update
    return $basewidget
}

# ----------------------------------------------------------
#  GUI for multiple image object
# ----------------------------------------------------------
itcl::class pxitclmultiSurfaceGUI {

    inherit pxitclmultiObjectGUI

    constructor { } {
	pxitclmultiObjectGUI::constructor
	set description "Surface"
    } {
    }
    
    destructor { }
    
    public    method Initialize { basewidg } 

    public    method AddSurface { descr }
    public    method SetSurface { index } 
    public    method GetSurface { index } { return [ GetObject $index ] }
    public    method DeleteSurface { index } { DeleteObject $index }

    protected method CreateNewObject { }
    protected method CreateNewObjectGUI { widget }

}

# ----------------------------------------------------------
itcl::body pxitclmultiSurfaceGUI::CreateNewObject { } {

    return  [ [  pxitclsurface \#auto ] GetThisPointer ]
}

itcl::body pxitclmultiSurfaceGUI::CreateNewObjectGUI { widget } {
    set itclimageGUI [ [ pxitclsurfaceGUI \#auto ] GetThisPointer ]
    pack [ $itclimageGUI Initialize $widget.[ pxvtable::vnewobj ] ] -side left -fill x
    return $itclimageGUI
}

itcl::body pxitclmultiSurfaceGUI::AddSurface { descr } {
    
    set newobj [ $this AddObject $descr ]
    $this SetSurface [ expr [ llength $itclobjectlist ] -1 ]    
    return $newobj
}

itcl::body pxitclmultiSurfaceGUI::SetSurface { index } {

    $this SetObject $index
    $objectGUI configure -description [ $listbox get $currentobject ]
    $objectGUI Update
}

itcl::body pxitclmultiSurfaceGUI::Initialize { basewidg } {
    
    if { $initialized == 1 } { 
	return $basewidget 
    }
    
    pxitclmultiObjectGUI::Initialize $basewidg

    $listbox configure -selectmode single -exportselection 0
    eval "$listbox configure -selectioncommand { $this SetSurface -1 }"
    
    set initialized 1

    
    return $basewidget
}


