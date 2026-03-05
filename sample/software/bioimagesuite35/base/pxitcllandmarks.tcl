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

package provide pxitcllandmarks 1.0

# 	$Id: pxitcllandmarks.tcl,v 1.2 2003/08/14 17:49:42 xenios Exp xenios $	




package require  pxitclobject  1.0


# -------------------------------------------------------------------
# Definition of pxitcllandmarks
#
#    a class that encapsulates an image (vtkImageData)
#            its orientation , filename and status
# -------------------------------------------------------------------

itcl::class pxitcllandmarks {

    inherit pxitclobject

    # --- begin variable def -----

    public variable status 
    protected variable landmarkset 

    # --- end of variable def -----

    constructor { } {
	pxitclobject::constructor 
    } {
	CreateNewLandmarks
	UpdateStatus    
    }

    destructor  { $landmarkset Delete     }


    # --- begin method def -----
    public method GetObject { } { return $landmarkset }
    public method GetType { } { return [ [ $landmarkset GetPoints ] GetNumberOfPoints ] }
    public method GetDescription { } 
    public method UpdateStatus { } { set status [ [ $landmarkset GetPoints ] GetNumberOfPoints ]  }
    public method Copy   { obj args }
    public method Clear { } 
    public method UnLoad { } { return [ Clear ] }

    public method Load   { args }
    public method Save   { args }

    # Methods additional to pxitclobject
    
    public method GetLandmarks { } { return $landmarkset }

    public method GetLongDescription { } 
    public method GetShortDescription { } 
    public method GetSize { } { return [ $this GetLandmarksSize ] }
    public method GetLandmarksSize { } 

    public method CopyLandmarks   { newlandmarkset args }

    public method CreateNewLandmarks { } 

    # Procedures to Just Set Filename
    public method Browse { description }


    # Procedures to Ship To Viewer
    public method Display { baseviewer }
    public method Transform { transformation } 


    # Testing Stuff
    public method CompareTo  { fname { thr 0.001 } } 
    # --- end method def -----
}

# ------------------- End of Header ---------------------------------
itcl::body pxitcllandmarks::CreateNewLandmarks { } {

    set landmarkset [ vtkpxBaseCurve [ pxvtable::vnewobj ]]
}


itcl::body pxitcllandmarks::Copy  { obj  } {

    if { [ $obj isa pxitcllandmarks ] == 0 } {
	return 0
    }

    set oldimg [ $obj GetLandmarks ] 
    CopyLandmarks $oldimg 
    set filename    [ $obj cget -filename ]
    UpdateStatus
}
# ----------------------------------------------------------
itcl::body pxitcllandmarks::CopyLandmarks { newimg  } {

    if { [ $newimg IsA "vtkpxBaseCurve" ] == 0 } {
	puts stdout "Bad Input"
	return
    }

    $landmarkset Delete
    set landmarkset [ vtkpxBaseCurve [ pxvtable::vnewobj ]]

    $landmarkset Copy $newimg
    UpdateStatus
}

# ----------------------------------------------------------
itcl::body pxitcllandmarks::Clear { } {
    catch { $landmarkset Delete }
    CreateNewLandmarks
    set orientation 0
    set filename    ""
    UpdateStatus
}
# ----------------------------------------------------------
itcl::body pxitcllandmarks::GetLandmarksSize { } {

    return [ $landmarkset GetNumPoints ]
}

# ----------------------------------------------------------
itcl::body pxitcllandmarks::GetLongDescription { } {
    
    set x1 [ $landmarkset GetNumPoints ] 
    
    set line [ format "Number Of Points %d " $x1 ]

    set line  "name=$this\n\t$line\n\tFilename= $filename"
    return $line
}
# ----------------------------------------------------------
itcl::body pxitcllandmarks::GetDescription { } {
    
    set x1 [ $landmarkset GetNumPoints ] 
    set line [ format "Number Of Points %d" $x1 ]
    set line  "$line\nFilename=$filename\n"
    return $line
}
# ----------------------------------------------------------
itcl::body pxitcllandmarks::GetShortDescription { } {
    
    set x1 [ $landmarkset GetNumPoints ] 
    set line [ format "Number Of Points %d" $x1  ]
    set line  "[ file tail $filename]  $line"
    return $line
}
# ----------------------------------------------------------
itcl::body pxitcllandmarks::Browse { description } {

    set f2path [ file dirname $filename ]
    set f2tail [ file tail    $filename ]
	
    set fname  [tk_getOpenFile -title "Get Filename for $description" -filetypes { {"Landmark Files" {.land .vtk}}} -initialfile $f2tail -initialdir $f2path ]   
    if { [ string length $fname ] > 0 } {
	set filename $fname
	return 1
    }
    return 0
}
# ----------------------------------------------------------
itcl::body pxitcllandmarks::Load { args } {

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
	set desc "Landmark Set"
    }


    if { [ string length $fname ] == 0 } {


	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set fname  [tk_getOpenFile -title "Load $desc" -filetypes { {"Landmarks Files" {.land .vtk .vtp}}} -initialfile $f2tail -initialdir $f2path ]   
    }
    

    if { [ string length $fname ] <1 } {
	return 0
    }

    if { [ file extension $fname ] == ".vtk" || [ file extension $fname ] == ".vtp" } {
	if { [ file extension $fname ]  == ".vtp"  } {
	    set ana [ vtkXMLPolyDataReader [ pxvtable::vnewobj ]]
	} else {
	    set ana [ vtkPolyDataReader [ pxvtable::vnewobj ]]
	}
	$ana SetFileName $fname
	$ana Update
	$landmarkset SetFromPoints [ [ $ana GetOutput ] GetPoints ]
	$this configure -filename $fname
	$ana Delete
    } else {
	$landmarkset Load $fname
	$this configure -filename $fname
    }
    

    return 1

}
# ----------------------------------------------------------
itcl::body pxitcllandmarks::Save { args } {

    set len [ llength $args ]
    if { $len < 1 } {
	set fname $filename
    } else  { 
	set fname [ lindex $args 0 ] 
    }

    set desc "Landmark Set"
    if { $len > 1 } { 
	set desc [ lindex $args 1 ]
    }


    if { [ string length $fname ] == 0 } {
	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set fname  [tk_getSaveFile -title "Saving $desc" -filetypes { {"Landmarks Files" {.land}}} -initialfile $f2tail -initialdir $f2path ]   
    }
    

    if { [ string length $fname ] < 1 } {
	return 0
    }
    
    $landmarkset Save $fname
    set filename $fname
    return 1
}
# ----------------------------------------------------------

itcl::body pxitcllandmarks::Display { baseviewer } {
    
    set landmarkcontrol 0
    catch {     set  landmarkcontrol [ [ $baseviewer GetLandmarkControl ] GetLandmarkControl ] }

    if { $landmarkcontrol == 0 } {
	::pxtclutil::Warning "Bad baseviewer ($baseviewer) Specified. Cannot display landmarks\n"
	return 0
    }
    
    #    $landmarkset Save "temp.land"
    $landmarkcontrol SetClipboardCollection $landmarkset 0
    ::pxtclutil::Info "Placed landmarks $filename in the clipboard of the landmarks control"
    
    [ $baseviewer GetLandmarkControl ] ShowWindow
    return 1
} 
# ----------------------------------------------------------
itcl::body pxitcllandmarks::Transform { transformation } {

    set pt [ vtkpxBaseCurve [ pxvtable::vnewobj ]]
    $pt Copy $landmarkset
    $pt Compact


    
    set poly [ vtkPolyData [ pxvtable::vnewobj ]]
    $poly SetPoints [ $pt GetPoints ]

    set vt [ vtkTransformPolyDataFilter [ pxvtable::vnewobj ]]
    $vt SetInput $poly
    $vt SetTransform $transformation
    $vt Update

    $landmarkset SetFromPoints [ [ $vt GetOutput ] GetPoints ]
    $vt Delete
    $poly Delete
    $pt Delete

    UpdateStatus
    return 1
} 


itcl::body pxitcllandmarks::CompareTo  { fname { thr 0.001 } }  {

    set pt [ vtkpxBaseCurve [ pxvtable::vnewobj ]]
    $pt Copy [ $this GetLandmarks ]
    $pt Compact

    set pt2 [ vtkpxBaseCurve [ pxvtable::vnewobj ]]
    $pt2 Load $fname
    $pt2 Compact

    set ut [ vtkbisTestUtil New ]
    $ut ClearStatus
    puts stderr "Comparing [ $this GetDescription ] to $fname, threshold=$thr"
    set ok [ $ut ComparePoints [ $pt GetPoints ] [ $pt2 GetPoints ] $thr ]
    set a [ $ut ReturnStatus ]
    $ut Delete
    $pt Delete
    $pt2 Delete
    return [ list $ok $a ]
}
# ---------------------------------------------------------------------------------------------


itcl::class pxitcllandmarksGUI {

    inherit pxitclobjectGUI

    public variable browsebutton

    constructor { } {
	pxitclobjectGUI::constructor
    } { 
	set thisparam($this,status) "vtkpxBaseCurve"
	set thisparam($this,shortfilename) "none"
	set thisparam($this,descriptionbox) 0
	Reset
    }

    destructor { }

    public method SetObject { tr } { return [ SetLandmarks $tr ] }
    public    method GetLandmarks { } { return $itclobject  }

    protected method CreateNewObject { } 
    public    method Initialize { basewidg } 
    public    method SetLandmarks { isur }
    public    method BrowseLandmarks { } 


}
# ----------------------------------------------------------
itcl::body pxitcllandmarksGUI::CreateNewObject { } {
    set itclobject  [ [  pxitcllandmarks \#auto ] GetThisPointer ]
}

itcl::body pxitcllandmarksGUI::BrowseLandmarks { } {
    $itclobject Browse $description
    Update
}

itcl::body pxitcllandmarksGUI::SetLandmarks { trn } {
    
    if { [ $trn isa pxitcllandmarks ] == 0 } {
	return 0
    }
	
    if { $owns_object == 1} {
	catch { itcl::delete object $itclobject }
    }

    set itclobject $trn
    set owns_object 0
    Update
}

itcl::body pxitcllandmarksGUI::BrowseLandmarks { } {
    $itclobject Browse $description
    Update
}

itcl::body pxitcllandmarksGUI::Initialize { basewidg } {

    if { $initialized == 1 } { return $basewidget }
    pxitclobjectGUI::Initialize $basewidg

    set browsebutton [ eval "button $buttonbar.b -text Browse -command { $this BrowseLandmarks }" ]
    pack  $buttonbar.b   -side left -fill x -expand f
    update idletasks

    Update
    return $basewidget
}


