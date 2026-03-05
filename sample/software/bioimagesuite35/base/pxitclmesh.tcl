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

package provide pxitclmesh 1.0

# 	$Id: pxitclmesh.tcl,v 1.2 2003/08/14 17:49:42 xenios Exp xenios $	




package require  pxitclobject  1.0
package provide pxitclmesh 1.0

# -------------------------------------------------------------------
# Definition of pxitclmesh
#
#    a class that encapsulates a mesh (vtkUnstructureGrid)
#            its orientation , filename and status
# -------------------------------------------------------------------

itcl::class pxitclmesh {

    inherit pxitclobject

    # --- begin variable def -----

    public variable status 
    protected variable mesh 

    # --- end of variable def -----

    constructor { } {
	pxitclobject::constructor 
    } {
	CreateNewMesh
	UpdateStatus    
    }

    destructor  { $mesh Delete     }


    # --- begin method def -----sur
    public method GetObject { } { return $mesh }
    public method GetType { } { return [ $mesh GetNumberOfPoints ] }
    public method GetDescription { } 
    public method UpdateStatus { } { set status [ $mesh GetNumberOfPoints ]  }
    public method Copy   { obj args }
    public method Clear { } 
    public method UnLoad { } { return [ Clear ] }

    public method Load   { args }
    public method Save   { args }

    # Methods additional to pxitclobject
    
    public method GetMesh { } { return $mesh }
    public method GetSurfaceRepresentation { }

    public method GetLongDescription { } 
    public method GetShortDescription { } 
    public method GetMeshSize { } 
    public method GetSize { } { return [ $this GetMeshSize ] }

    public method DeepCopy    { obj } { Copy $obj 1    }
    public method ShallowCopy { obj } { Copy $obj 0    }

    public method DeepCopyMesh    { newmesh } { CopyMesh $newmesh 1    }
    public method ShallowCopyMesh { newmesh } { CopyMesh $newmesh 0    }
    public method CopyMesh   { newmesh mode }

    public method CreateNewMesh { } 

    # Procedures to Just Set Filename
    public method Browse { description }

    # Procedures to Ship To Viewer
    public method Display { baseviewer }
    public method Transform { gen }


    # Compare with FileName
    public method CompareTo  { fname } 


    # --- end method def -----
}

# ------------------- End of Header ---------------------------------
itcl::body pxitclmesh::CreateNewMesh { } {

    set mesh [ vtkUnstructuredGrid [ pxvtable::vnewobj ]]
}


itcl::body pxitclmesh::Copy   { obj args } {

    set mode 0
    if { [ llength $args ] > 0 } {
	set mode [ expr [ lindex $args 0 ] > 0 ]
    }

    if { [ $obj isa pxitclmesh ] == 0 } {
	return 0
    }

    set oldimg [ $obj GetMesh ] 
    CopyMesh $oldimg $mode
    set filename    [ $obj cget -filename ]
    UpdateStatus
}


itcl::body pxitclmesh::GetSurfaceRepresentation { } {

    set sur [ vtkPolyData [ pxvtable::vnewobj ]]

    # This works, but is very slow compared to the C++ version
    set ok [ pxtclvtkpxcontrib::ConditionalLoadLibrary vtkjoStereoVisionTCL vtkjoConvertUnstructuredGridToPolyDataFilter ]
    if { $ok != 0 } {
        set convert [ vtkjoConvertUnstructuredGridToPolyDataFilter New ]
        $convert SetGridInput $mesh
        $convert Update
        $sur ShallowCopy [ $convert GetOutput ]
        $convert Delete
    } else {
    
        # Procedure taken from vtkpxAbaqusUtil::CreateSurfaceFromGrid
        $sur SetPoints [ $mesh GetPoints ]
        [ $sur GetPointData ] SetScalars [[ $mesh GetPointData ] GetScalars ]

        set ntetra [[ $mesh GetCells ] GetNumberOfCells ]

        set polys [ vtkCellArray [ pxvtable::vnewobj ]]
        $polys Allocate [ expr $ntetra * 4 ] 1000

        set npts [ vtkIdList [ pxvtable::vnewobj ]]
        for { set j 0 } { $j < $ntetra } { incr j } {
            set cell [ $mesh GetCell $j ]
            set numpts [ $cell GetNumberOfPoints ]
            set pts [ vtkIdList [ pxvtable::vnewobj ]]
        
            for { set i 0 } { $i < $numpts } { incr i } {
                $pts InsertNextId [ $cell GetPointId $i ]
            }
        
            $npts InsertId 0 [ $pts GetId 0 ]
            $npts InsertId 1 [ $pts GetId 1 ]
            $npts InsertId 2 [ $pts GetId 2 ]
            $polys InsertNextCell $npts

            $npts InsertId 0 [ $pts GetId 1 ]
            $npts InsertId 1 [ $pts GetId 2 ]
            $npts InsertId 2 [ $pts GetId 3 ]
            $polys InsertNextCell $npts

            $npts InsertId 0 [ $pts GetId 2 ]
            $npts InsertId 1 [ $pts GetId 3 ]
            $npts InsertId 2 [ $pts GetId 0 ]
            $polys InsertNextCell $npts

            $npts InsertId 0 [ $pts GetId 3 ]
            $npts InsertId 1 [ $pts GetId 0 ]
            $npts InsertId 2 [ $pts GetId 1 ]
            $polys InsertNextCell $npts

            $pts Delete
        }
        $npts Delete
    
        $sur SetPolys $polys
        $polys Delete
    }
    # puts stderr "Done creating surface"
    
    return $sur
}


# ----------------------------------------------------------
itcl::body pxitclmesh::CopyMesh { newimg mode } {

    set mode [ expr $mode > 0 ]

    if { [ $newimg IsA "vtkUnstructuredGrid" ] == 0 } {
	puts stdout "Bad Input"
	return
    }

    $mesh Delete
    set mesh [ vtkUnstructuredGrid [ pxvtable::vnewobj ]]

    #    puts stderr "In Copy Mesh mode=$mode, mesh = $mesh [ $mesh GetClassName ], newimg=$newimg [ $newimg GetClassName ]"

    if { $mode == 0 } {
	$mesh ShallowCopy $newimg
    } else {
	$mesh DeepCopy $newimg
    }

    UpdateStatus
}

# ----------------------------------------------------------
itcl::body pxitclmesh::Clear { } {
    catch { $mesh Delete }
    CreateNewMesh
    set orientation 0
    set filename    ""
    UpdateStatus
}
# ----------------------------------------------------------
itcl::body pxitclmesh::GetMeshSize { } {

    return [ $mesh GetNumberOfPoints ]
}

# ----------------------------------------------------------
itcl::body pxitclmesh::GetLongDescription { } {
    
    set x1 [ $mesh GetNumberOfPoints ] 
    set s1 [ $mesh GetNumberOfCells  ]
    set bd [ $mesh GetBounds ]
    set t1 [ $mesh GetNumberOfScalarComponents ] 
    
    set line [ format "Number Of Points %d Cells=%d Bounds= $bd" $x1 $s1 ]

    set line  "name=$this\n\t$line\n\tFilename= $filename"
    return $line
}
# ----------------------------------------------------------
itcl::body pxitclmesh::GetDescription { } {
    
    set x1 [ $mesh GetNumberOfPoints ] 
    set s1 [ $mesh GetNumberOfCells  ]
    set line [ format "Number Of Points %d Cells=%d" $x1 $s1 ]
    set line  "$line\nFilename=$filename\n"
    return $line
}
# ----------------------------------------------------------
itcl::body pxitclmesh::GetShortDescription { } {
    
    set x1 [ $mesh GetNumberOfPoints ] 
    set s1 [ $mesh GetNumberOfCells  ]
    set line [ format "Number Of Points %d Cells=%d" $x1 $s1 ]
    set line  "[ file tail $filename]  $line"
    return $line
}
# ----------------------------------------------------------
itcl::body pxitclmesh::Browse { description } {

    set f2path [ file dirname $filename ]
    set f2tail [ file tail    $filename ]
	
    set fname  [tk_getOpenFile -title "Get Filename for $description" -filetypes { {"Mesh Files" {.ugrid .ugridx}}} -initialfile $f2tail -initialdir $f2path ]   
    if { [ string length $fname ] > 0 } {
	set filename $fname
	return 1
    }
    return 0
}
# ----------------------------------------------------------
itcl::body pxitclmesh::Load { args } {

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
	set desc "Mesh"
    }


    if { [ string length $fname ] == 0 } {


	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set fname  [tk_getOpenFile -title "Load $desc" -filetypes { {"Mesh Files" {.ugrid .ugridx}}} -initialfile $f2tail -initialdir $f2path ]   
    }
    

    if { [ string length $fname ] <1 } {
	return 0
    }

    catch {
	if { [ file extension $fname ]  == ".ugridx"  } {
	    set ana [ vtkXMLUnstructuredGridReader [ pxvtable::vnewobj ]]
	} else {
	    set ana [ vtkUnstructuredGridReader [ pxvtable::vnewobj ]]
	}
	$ana SetFileName $fname
	$ana Update
	$this ShallowCopyMesh [ $ana GetOutput ]
	$this configure -filename $fname
	$ana Delete
    }
    return 1
}
# ----------------------------------------------------------
itcl::body pxitclmesh::Save { args } {

    set len [ llength $args ]
    if { $len < 1 } {
	set fname $filename
    } else  { 
	set fname [ lindex $args 0 ] 
    }

    set desc "Image"
    if { $len > 1 } { 
	set desc [ lindex $args 1 ]
    }


    if { [ string length $fname ] == 0 } {
	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set fname  [tk_getSaveFile -title "Saving $desc" -filetypes { {"Mesh Files" {.ugrid}}} -initialfile $f2tail -initialdir $f2path ]   
    }
    
    if { [ string length $fname ] < 0 } {
	return 0
    }
    
    set ana [ vtkUnstructuredGridWriter  [ pxvtable::vnewobj ]]
    $ana SetInput $mesh
    $ana SetFileName $fname
    $ana Update
    set filename $fname
#$this configure -filename $fnamea
    $ana Delete 
    return 1
}
# ----------------------------------------------------------
itcl::body pxitclmesh::Display { baseviewer } {
    
    # Create a surface and send to polydatacontrol as per pxitclsurface
    set polydatacontrol 0
    catch { set polydatacontrol [ [ $baseviewer GetPolyDataControl ] GetPolyDataControl ] }

    if { $polydatacontrol == 0 } {
        ::pxtclutil::Warning "Bad baseviewer ($baseviewer) specified. Cannot display mesh surface\n"
        return 0
    }

    # Create surface representation by calling this oject's GetSurfaceRepresentation method
    $polydatacontrol SetClipboardSurface [ $this GetSurfaceRepresentation ] $filename
    ::pxtclutil::Info "Placed mesh surface $filename in the clipboard of the surface control"

    [ $baseviewer GetPolyDataControl ] ShowWindow
    return 1
} 
# ----------------------------------------------------------
itcl::body pxitclmesh::Transform { transformation } {

    # Transform Points and then copy back
    # Actually, maybe this can just be done using vtkTransformFilter,
    # which takes a vtkPointSet as input
    # TODO: Test
    set xform [ vtkTransformFilter [ pxvtable::vnewobj ]]
    $xform SetInput $mesh 
    $xform SetTransform $transformation
    $xform Update
    $this ShallowCopyMesh [ $xform GetOutput ]
    $xform Delete
    return 1
} 


itcl::body pxitclmesh::CompareTo  { fname } {

    # TODO: Test
    set tmp [ pxitclmesh \#auto ]
    set ok [ $tmp Load $fname ]
    if { $ok == 0 } {
        itcl::delete object $tmp
        return 0
    }

    set ut [ vtkbisTestUtil New ]
    # Just compare the surface representations!
    set ok [ $ut CompareSurfaces [[ $this GetMesh ] GetSurfaceRepresentation ] [[ $tmp GetMesh ] GetSurfaceRepresentation ]
    itcl::delete object $tmp
    $ut Delete
    return $ok
}


# ----------------------------------------------------------
#  GUI for pxitclmesh
# ----------------------------------------------------------
itcl::class pxitclmeshGUI {

    inherit pxitclobjectGUI

    public variable browsebutton

    constructor { } {
	pxitclobjectGUI::constructor
    } { 
	set thisparam($this,status) "vtkUnstructuredGrid"
	set thisparam($this,shortfilename) "none"
	set thisparam($this,descriptionbox) 0
	Reset
    }

    destructor { }

    public method SetObject { tr } { return [ SetMesh $tr ] }
    public    method GetMesh { } { return $itclobject  }

    protected method CreateNewObject { } 
    public    method Initialize { basewidg } 
    public    method SetMesh { imesh }
    public    method BrowseMesh { } 


}
# ----------------------------------------------------------
itcl::body pxitclmeshGUI::CreateNewObject { } {
    set itclobject  [ [  pxitclmesh \#auto ] GetThisPointer ]
}

itcl::body pxitclmeshGUI::BrowseMesh { } {
    $itclobject Browse $description
    Update
}

itcl::body pxitclmeshGUI::SetMesh { trn } {
    
    if { [ $trn isa pxitclmesh ] == 0 } {
	return 0
    }
	
    if { $owns_object == 1} {
	catch { itcl::delete object $itclobject }
    }

    set itclobject $trn
    set owns_object 0
    Update
}

itcl::body pxitclmeshGUI::BrowseMesh { } {
    $itclobject Browse $description
    Update
}

itcl::body pxitclmeshGUI::Initialize { basewidg } {

    if { $initialized == 1 } { return $basewidget }
    pxitclobjectGUI::Initialize $basewidg

    set browsebutton [ eval "button $buttonbar.b -text Browse -command { $this BrowseMesh }" ]
    pack  $buttonbar.b   -side left -fill x -expand f
    update idletasks

    Update
    return $basewidget
}

# ----------------------------------------------------------
#  GUI for multiple image object
# ----------------------------------------------------------
itcl::class pxitclmultiMeshGUI {

    inherit pxitclmultiObjectGUI

    constructor { } {
	pxitclmultiObjectGUI::constructor
	set description "Mesh"
    } {
    }
    
    destructor { }
    
    public    method Initialize { basewidg } 

    public    method AddMesh { descr }
    public    method SetMesh { index } 
    public    method GetMesh { index } { return [ GetObject $index ] }
    public    method DeleteMesh { index } { DeleteObject $index }

    protected method CreateNewObject { }
    protected method CreateNewObjectGUI { widget }

}

# ----------------------------------------------------------
itcl::body pxitclmultiMeshGUI::CreateNewObject { } {

    return  [ [  pxitclmesh \#auto ] GetThisPointer ]
}

itcl::body pxitclmultiMeshGUI::CreateNewObjectGUI { widget } {
    set itclimageGUI [ [ pxitclmeshGUI \#auto ] GetThisPointer ]
    pack [ $itclimageGUI Initialize $widget.[ pxvtable::vnewobj ] ] -side left -fill x
    return $itclimageGUI
}

itcl::body pxitclmultiMeshGUI::AddMesh { descr } {
    
    set newobj [ $this AddObject $descr ]
    $this SetMesh [ expr [ llength $itclobjectlist ] -1 ]    
    return $newobj
}

itcl::body pxitclmultiMeshGUI::SetMesh { index } {

    $this SetObject $index
    $objectGUI configure -description [ $listbox get $currentobject ]
    $objectGUI Update
}

itcl::body pxitclmultiMeshGUI::Initialize { basewidg } {
    
    if { $initialized == 1 } { 
	return $basewidget 
    }
    
    pxitclmultiObjectGUI::Initialize $basewidg

    $listbox configure -selectmode single -exportselection 0
    eval "$listbox configure -selectioncommand { $this SetMesh -1 }"
    
    set initialized 1

    
    return $basewidget
}


