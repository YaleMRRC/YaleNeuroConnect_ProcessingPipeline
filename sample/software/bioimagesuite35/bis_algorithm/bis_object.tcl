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

package provide bis_object 1.0

#
# bis_object.tcl
# 

package require pxitclobject 1.0
package require pxitclimage
package require pxitcltransform
package require pxitclsurface
package require pxitclmesh
package require pxitcllandmarks
package require pxitclelectrodemultigrid
package require bis_common

itcl::class bis_object {

#
#protected
#
    protected variable name "some object"
    protected variable description "this is some object"
    protected variable cmdlineoption ""

    # this is a list of allowed object types
    protected common objecttypelist { pxitclimage pxitcltransform pxitclsurface pxitcllandmarks pxitclelectrodemultigrid pxitclmesh }

    protected variable objecttype ""
    protected variable multipleobjectflag 0

    protected variable internalobject    0

    # For multiple inputs this contains objects 2..N
    protected variable objectlist  ""

    protected variable objectgui 0
    protected variable objectguimode "normal"

    protected variable updatecallback ""
    protected variable priority 0
    protected variable update_gui_internally 0
    protected variable default_filename ""
    protected variable guimode ""
    protected variable xmlpointer 0
    protected variable algparent 0
    protected common guiparam
#
#public
#
    # Constructor and Destructor
    constructor { } {      set guiparam($this,treelistbox) 0 }
    destructor { $this CleanAll }

    public method GetThisPointer { } { return $this }
    protected method CleanAll { }

    # Name of Object e.g. Input Image
    public method SetName        { a } { set name $a }
    public method GetName        {   } { return $name}

    # Description of what the object does
    public method SetDescription { a } { set description $a }
    public method GetDescription {   } { return $description }

    # Priority of  the object for GUI Generation
    public method SetPriority { a } { set priority $a }
    public method GetPriority {   } { return $priority }

    # Type of Object e.g. pxitclimage
    public method SetObjectType        { a } 
    public method GetObjectType        {   } { 	return $objecttype     }

    public method SetMultipleObjectFlag  { a }  { if { $a == "multiple" } { set multipleobjectflag 1 } else { set multipleobjectflag 0 }}
    public method GetMultipleObjectFlag  {  }   { return  $multipleobjectflag }

    public method CreateVTKObject      {  mode  }

    # Filename of Object 
    public method SetFileName    { a { force 0 } } 
    public method GetFileName    {   } 
    public method IsFileNameTheDefault { }

    # This is for multiobject stuff ....
    public method AddFileNames { fnamelist }
    public method GetFileNameList {  }


    # Command Line Option for Object 
    public method SetCommandSwitch    { a } { set cmdlineoption $a }
    public method GetCommandSwitch    {   } { return $cmdlineoption }
    public method GetCmdLineString {} { 
	return [ list ${cmdlineoption}.arg $default_filename "filename for $description" ] 	
    }
    public proc   GetSlicerListXMLDescription { dlist { input 1 } { index 1 } { channelindex -1 } }
    public method GetLONIXMLDescription { { input 1 }  }
    public method  GetJSONString     {  dlist { input 1 } { index 1 } { channelindex -1 } }


    # Return a pointer to the object (pxitcl....) 
    public method GetObject      {   } { 		return $internalobject         }
    public method GetObjectList      {   } { 		return $objectlist     }
    public method GetAllObjects    {   } {  return [ concat $internalobject $objectlist ]  }


    # Use this to link to parent
    public method SetUpdateCallback { c } {  set updatecallback $c }

    # Return a pointer to the object GUI If it exists
    public method GetObjectGUI { } { return $objectgui }
    public method CreateObjectGUI { base { enablesave 1 } { desc "" } { parent 0 } }
    protected method CreateMultipleObjectGUI { base { enablesave 1 } { desc "" } { parent 0 } }

    public method CreateDataTreeObjectGUI { base { enablegrab 0 } { enablestore 0 } { parent 0 } { datatree 0 }}
    protected method CreateMultipleDataTreeObjectGUI { base { enablegrab 0 } { enablestore 0 } { parent 0 } { datatree 0 }}

    public method GrabTreeSelection { datatree { refspace 0 } }
    public method ClearTreeObject { { mode current } }
    public method StoreInTree { datatree }
    public method GUICallback { }
    public method UpdateInternalGUI { }
    public method UpdateObjectListFromGUI { }

    # Returns the vtkObject e.g. vtkImageData encapsulated in the the itcl object
    public method GetVTKObject   { }

    # XML Pointer -- for interfacing with Datatree cleanly
    public method SetXMLPointer  { a } { set xmlpointer $a  }
    public method GetXMLPointer  {   } { return $xmlpointer }


    # GUI Callbacks Internal
    public method InfoObject {  }
    public method DisplayImage { image viewer }
    public method DisplayObject { sur viewer }
    public method GUIQuickHelp { image args }


    # Load and Save Object (args means a list  of parameters, possibly empty)
    # If I call this as LoadObject a.hdr 2 --> args  = { a.hdr 2 }
    # argument 0 = filename (if absent it will popup a dialog to get it )
    # argument 1 = description (for Get FileName Dialog 
    # argument 2 = parent object in GUI (for 
    # LoadObject "a.hdr" "Input FileName" $someviewer
    # For command line usage use one argument -- the filename
    public method LoadObject { args } 
    public method SaveObject { args } 

    public method LoadObjectList { index args } 
    public method SaveObjectList { index args } 



    public method SetValueAsList { input  } 
    public method SetValue       { i_name i_desc i_type i_fname {  i_priority 0 } } {
	SetName         $i_name
	SetDescription  $i_desc
	SetObjectType   [ lindex $i_type 0 ]
	if { [ llength $i_type ] > 1 } {
	    SetMultipleObjectFlag [ lindex $i_type 1 ]
	}
	set default_filename $i_fname 
	SetPriority     $i_priority
    }

    public method PrintSelf     { } {
	puts stdout "name =         [$this GetName]"
	puts stdout "description =  [$this GetDescription]"
	puts stdout "objecttype  =  [$this GetObjectType]"
	puts stdout "filename    =  [$this GetFileName]"
	puts stdout "default_filename    =  $default_filename "
	puts stdout "object      =  [$this GetObject]"
	puts stdout "objectgui   =  [$this GetObjectGUI]"
	puts stdout "priority    =  [$this GetPriority]"
	puts stdout "cmdlineoption    =  [$this GetCommandSwitch ]"
	puts stdout "\n"
    }
}

itcl::body bis_object::GetJSONString     {  dlist { input 1 } { index 1 } { channelindex -1 } } {

    set name [ lindex $dlist 0 ]
    set desc [ lindex $dlist 1 ]
    
    if { [ llength $dlist ] > 4 } {
	set priority  [ lindex $dlist 4 ] 
    } else {
	set priority 0
    }
    set objecttype [ lindex [ lindex $dlist 2 ] 0 ]
    
    set cmd "inp"
    if { $input == 0 } {
	set cmd "out"
    }
    if { $index > 1 } {
	append cmd "$index"
    }
    
    set txt "\t\t\"$cmd\": \{\n"
    append txt "\t\t\t\"name\": [ ::bis_common::CleanString $name],\n"
    append txt "\t\t\t\"description\": [ ::bis_common::CleanString $desc],\n"
    append txt "\t\t\t\"objecttype\": [ ::bis_common::CleanString $objecttype],\n"
    append txt "\t\t\t\"priority\": [ ::bis_common::CleanString $priority]\n"
    append txt "\t\t\}"
    return $txt
}

# -------------------------------------------------------------------------------------------------
itcl::body bis_object::GetSlicerListXMLDescription { dlist { input 1 } { index 1 } { channelindex -1 } } {

    set name [ lindex $dlist 0 ]
    set desc [ lindex $dlist 1 ]

    #    puts stderr "Adding $name, index=$index, channel=$channelindex"
    if { [ llength $dlist ] > 4 } {
	set optional [ expr [ lindex $dlist 4 ] >= 100 ]
    } else {
	set optional 0
    }
    set objecttype [ lindex [ lindex $dlist 2 ] 0 ]

    if {$objecttype == "pxitclimage" } {
	set line "<image fileExtensions=\".nii.gz,.hdr\">\n"
    } elseif { $objecttype=="pxitcllandmarks" || $objecttype=="pxitclsurface"}  {
	set line "<geometry type=\"model\" fileExtensions=\".vtk,.vtp\">\n"
    } elseif { $objecttype=="pxitcllandmarks" || $objecttype=="pxitclmesh"}  {
	set line "<geometry type=\"model\" fileExtensions=\".ugrid,.ugridx\">\n"
    } elseif { $objecttype=="pxitcltransform" } {
	set line "<file fileExtensions=\".matr,.grd,.vtk\">\n"
    } else {
	set line "<file fileExtensions=\".mgrid\">\n"
    }
    
    set cmd "inp"
    if { $input == 0 } {
	set cmd "out"
    }
    if { $index > 1 } {
	append cmd "$index"
    }

    if { $channelindex >=0 } {
	set s [ expr $channelindex + 1 ]
    } else {
	set s ""
    }

    append line "\t<label>$name$s</label>\n"
    append line "\t<description>$desc$s</description>\n"
    if { $channelindex >=0 } {
	append line "\t<index>$channelindex</index>\n"	
    } else {
	append line "\t<longflag>--$cmd</longflag>\n"
    }
    if {  $optional > 0 } {
	append line "\t<default>\"\"</default>\n"
    }
    
    if { $input > 0 } {
	append line "\t<channel>input</channel>\n"
    } else {
	append line "\t<channel>output</channel>\n"
    }
    
    if {$objecttype == "pxitclimage" } {
	append line "</image>\n"
    } elseif { $objecttype=="pxitcllandmarks" || $objecttype=="pxitclsurface" || $objecttype=="pxitclmesh"}  {
	append line "</geometry>\n"
    } else {
	append line "</file>\n"
    }
    return $line
}



# -------------------------------------------------------------------------------------------------
itcl::body bis_object::GetLONIXMLDescription { { input 1 } } {
    
    set optional  0
    if { $priority >= 100  } {
	set optional 1
    }

    if { $input > 0 } {
	set line "\t\t\t<input name=\"$name\" "
    } else {
	set line "\t\t\t<output name=\"$name\" "
    }
    
    append line  "description=\"$description\" "

    if { $optional == 0 } {
	append line  "required=\"true\" "
    } else {
	append line  "required=\"false\" "
    }
    append line  "switchedSpaced=\"true\" "
    append line  "switch=\"-[$this GetCommandSwitch ]\">\n"
    append line "\t\t\t\t<format type=\"File\" cardinality=\"1\">\n"
    append line "\t\t\t\t\t<fileTypes>\n"

    switch $objecttype {
	pxitclimage {
	    append line "\t\t\t\t\t\t<filetype name=\"NIFTI file\" extension=\"nii.gz\" description=\"NIFTI File Format Compressed\"/>\n"
	    append line "\t\t\t\t\t\t<filetype name=\"NIFTI file\" extension=\"nii\" description=\"NIFTI File Format\"/>\n"
	    if { $input == 1 } {
		append line "\t\t\t\t\t\t<filetype name=\"Analyze file format\" extension=\"hdr\" description=\"Analyze File Format\">" 
		append line "<need>img</need></filetype>\n"
	    } else {
		append line "\t\t\t\t\t\t<filetype name=\"Analyze file format\" extension=\"hdr\" description=\"Analyze File Format\"/>\n" 
	    }
	}
	pxitcltransform {
	    append line "\t\t\t\t\t\t<filetype name=\"BioImage Suite matrix file\" extension=\"matr\" description=\"BioImage Suite Matrix File\"/>\n"
	    append line "\t\t\t\t\t\t<filetype name=\"BioImage Suite non-linear transform file\" extension=\"grd\" description=\"BioImage Non-linear grid transform file\"/>\n"
	    append line "\t\t\t\t\t\t<filetype name=\"BioImage Suite non-linear transform file\" extension=\"vtk\" description=\"BioImage Non-linear grid transform file as image\"/>\n"
	}
	pxitclsurface {
	    append line "\t\t\t\t\t\t<filetype name=\"VTK Surface file\" extension=\".vtk\" description=\"VTK Surface File\"/>\n"
	    append line "\t\t\t\t\t\t<filetype name=\"VTK Surface file\" extension=\".vtp\" description=\"VTK Surface File\"/>\n"
	}
	pxitclmesh {
	    append line "\t\t\t\t\t\t<filetype name=\"VTK Mesh file\" extension=\".ugrid\" description=\"VTK Mesh File\"/>\n"
	    append line "\t\t\t\t\t\t<filetype name=\"VTK Mesh file\" extension=\".ugridx\" description=\"VTK Mesh File\"/>\n"
	}
	pxitcllandmarks {
	    append line "\t\t\t\t\t\t<filetype name=\"BioImage Surface landmarks file\" extension=\".land\" description=\"BioImage Suite Landmarks File\"/>\n"
	    append line "\t\t\t\t\t\t<filetype name=\"VTK Surface file\" extension=\".vtk\" description=\"VTK Surface File\"/>\n"
	    append line "\t\t\t\t\t\t<filetype name=\"VTK Surface file\" extension=\".vtp\" description=\"VTK Surface File\"/>\n"
	}
	pxitclelectrodemultigrid {
	    append line "\t\t\t\t\t\t<filetype name=\"BioImage Surface electrode file\" extension=\".mgrid\" description=\"BioImage Suite Electrode File\"/>\n"
	}
    }

    append line "\t\t\t\t\t</fileTypes>\n"
    append line "\t\t\t\t</format>\n"
    if { $input > 0 } {
	append line "\t\t\t</input>\n"
    } else {
	append line "\t\t\t</output>\n"
    }
    return $line
}

# ------------------------------------------------------------------------------------

itcl::body bis_object::CleanAll    {   } {

    foreach obj $objectlist {
	itcl::delete obj $obj 
    }

    catch { itcl::delete obj $objectgui }
    catch { itcl::delete obj $internalobject }
}

#------------------------------------------
#Set object type and allocate a new one
#------------------------------------------

itcl::body bis_object::SetValueAsList    { input  } {

    if { [ llength $input ] < 4 } {
	return 0
    }

    if { [ llength $input ] == 4 } {
	SetValue [lindex $input 0] [lindex $input 1] [lindex $input 2] [lindex $input 3]
	return 4
    }

    SetValue [lindex $input 0] [lindex $input 1] [lindex $input 2] [lindex $input 3]  [ lindex $input 4 ]
    return 5
}


itcl::body bis_object::SetObjectType { objtype } {

    set index [ lsearch -exact $objecttypelist $objtype ]
    if { $index == -1 } {
	return 0
    }

   # eval "set object [ [ $objecttype \#new ] GetThisPointer ]"

    set  objecttype $objtype
}

itcl::body bis_object::CreateVTKObject { mode  } {

    if { $internalobject !=0 } {
	#puts stderr "--------------------------------  Already created  $this $name \n"
	return 1
    } 


    switch $objecttype {
	pxitclimage {
	    set internalobject [ [ pxitclimage \#auto ] GetThisPointer ]
	}
	pxitcltransform {
	    set internalobject [ [ pxitcltransform \#auto ] GetThisPointer ]
	}
	pxitclsurface {
	    set internalobject [ [ pxitclsurface \#auto ] GetThisPointer ]
	}
	pxitclmesh {
	    set internalobject [ [ pxitclmesh \#auto ] GetThisPointer ]
	}
	pxitcllandmarks {
	    set internalobject [ [ pxitcllandmarks \#auto ] GetThisPointer ]
	}
	pxitclelectrodemultigrid {
	    set internalobject [ [ pxitclelectrodemultigrid \#auto ] GetThisPointer ]
	}
	default { 
	    puts stderr "Specifid type $objecttype is not among pxitcl..."
	    return 0
	}
    }

    set guimode $mode
    $this SetFileName $default_filename 1

    return 1
}

#------------------------------------------

itcl::body bis_object::IsFileNameTheDefault { } {

    if { $internalobject == 0 } {
	return 1
    }

    if {  $default_filename == [ $this GetFileName ]  } {
	return 1
    }

    return 0
}

#------------------------------------------
# Return a pointer to the VTK object.essentially same as GetObject
#------------------------------------------
itcl::body bis_object::GetVTKObject {  } {

    return [ $internalobject GetObject ]
}

# --------------------------------------------------------------------------------------------------------

itcl::body bis_object::CreateObjectGUI { base { enablesave 1 } { desc "" } { parent 0 } } {
    
    if { $internalobject == 0 } {
	return 0
    }

    if { $multipleobjectflag > 0 } {
	return [ $this CreateMultipleObjectGUI $base $enablesave $desc $parent ]
    }

    set algparent  $parent
    switch $objecttype { 
	pxitclimage {
	    set objectgui [ [ pxitclimageGUI \#auto ] GetThisPointer ]
	}
	pxitcltransform {
	    set objectgui [ [ pxitcltransformGUI \#auto ] GetThisPointer ]
	}
	pxitclsurface {
	    set objectgui [ [ pxitclsurfaceGUI \#auto ] GetThisPointer ]
	}
	pxitclmesh {
	    set objectgui [ [ pxitclmeshGUI \#auto ] GetThisPointer ]
	}
	pxitcllandmarks {
	    set objectgui [ [ pxitcllandmarksGUI \#auto ] GetThisPointer ]
	}
	pxitclelectrodemultigrid {
	    set objectgui [ [ pxitclelectrodemultigridGUI \#auto ] GetThisPointer ]
	}
	default { 
	    puts stderr "Specifid type $objecttype is not among pxitcl..."
	    set objectgui 0
	}
    }

    if { $desc == "" } {
	$objectgui configure -description $description
    } else {
	$objectgui configure -description $desc
    }

    $objectgui InitializeLite $base 2
    if { $enablesave == 0 } {
	set but [ $objectgui cget -savebutton ]; pack forget $but
	set but [ $objectgui cget -clearbutton ]; pack forget $but
    }
    
    $objectgui SetObject $internalobject
    $objectgui Update
    $objectgui configure -callback "$this GUICallback"

    if { $parent == 0 } {
	return
    }

    if { $objecttype == "pxitclimage" } {
	set viewer [ $parent GetViewer ]
	if { $viewer !=0 } {
	    $objectgui AddFunction "$this DisplayImage" "Display" "$viewer"
	}
    } elseif { $objecttype != "pxitcltransform" } {
	set viewer [ $parent GetBisViewer ]
#	puts stderr "Viewer =$viewer, parent=$parent [ $parent info class ]"
	$objectgui AddFunction "$this DisplayObject" "Display" "$viewer"
    }

    $objectgui AddFunction "$this GUIQuickHelp" "?" ""

    

}
# --------------------------------------------------------------------------------------------------------
itcl::body bis_object::LoadObject { args } { 	
    set ok [ $internalobject Load $args]     
    return $ok
}

itcl::body bis_object::SaveObject { args } { 
    return [ $internalobject Save $args]         
}

# -------------------------------------------------------------------------

itcl::body bis_object::LoadObjectList { index args } { 	
    if { $index >=0 && $index < [ llength $objectlist ] } {
	set obj [ lindex $objectlist $index ]
	return [ $obj Load $args]     
    }
    return -1
}

itcl::body bis_object::SaveObjectList { index args } { 
    if { $index >=0 && $index < [ llength $objectlist ] } {
	set obj [ lindex $objectlist $index ]
	return [ $obj Save $args]         
    }
    return -1
}
# -------------------------------------------------------------------------
itcl::body bis_object::GetFileNameList {  } { 
    set n ""
    for { set i 0 } { $i < [ llength $objectlist ] } { incr i } {
	append n " [ [ lindex $objectlist $i ] cget -filename ]"
    }
    return $n

}
# ----------------------------------------------------------------
itcl::body bis_object::AddFileNames { fnamelist } { 

    if { $multipleobjectflag == 0 } {
	return 0
    }

    if { $objectlist != "" } {
	return 0
    }

#    puts stderr "Filenames =$fnamelist"

    set n [ llength $fnamelist ]
    for { set i 0 } { $i < $n } { incr i } {
	switch $objecttype { 
	    pxitclimage {
		set newobj [ [ pxitclimage \#auto ] GetThisPointer ]
	    }
	    pxitcltransform {
		set newobj [ [ pxitcltransform \#auto ] GetThisPointer ]
	    }
	    pxitclsurface {
		set newobj [ [ pxitclsurface \#auto ] GetThisPointer ]
	    }
	    pxitclmesh {
		set newobj [ [ pxitclmesh \#auto ] GetThisPointer ]
	    }
	    default { 
		puts stderr "Specifid type $objecttype is not among pxitcl... for multiple"
		set newobj 0
	    }
	}
	if { $newobj !=0 } {
	    $newobj configure -filename [ lindex $fnamelist $i ]
	    #	    puts stderr "Adding object $newobj filename = [ $newobj cget -filename ]"
	    lappend objectlist $newobj
	}
    }

    $this UpdateInternalGUI

}

itcl::body bis_object::CreateMultipleObjectGUI { base { enablesave 1 } { desc "" } { parent 0 } } {
    
    if { $internalobject == 0 } {
	return 0
    }

    set algparent  $parent
    switch $objecttype { 
	pxitclimage {
	    set objectgui [ [ pxitclmultiImageGUI \#auto ] GetThisPointer ]
	}
	pxitcltransform {
	    set objectgui [ [ pxitclmultiTransformGUI \#auto ] GetThisPointer ]
	}
	pxitclsurface {
	    set objectgui [ [ pxitclmultiSurfaceGUI \#auto ] GetThisPointer ]
	} 
	pxitclmesh {
	    set objectgui [ [ pxitclmultiMeshGUI \#auto ] GetThisPointer ]
	}
	default { 
	    puts stderr "Specifid type $objecttype is not among pxitcl... for multiple"
	    set objectgui 0
	}
    }



    if { $desc == "" } {
	$objectgui configure -description $description
    } else {
	$objectgui configure -description $desc
    }


    $objectgui configure -enabledeleteall 1
    $objectgui configure -enableupdown 1
    $objectgui InitializeLite $base 
    if { $enablesave == 0 } {
	set but [ [ $objectgui GetObjectGUI ] cget -savebutton ]; pack forget $but
	set but [ [ $objectgui GetObjectGUI ] cget -clearbutton ]; pack forget $but
    }
    

    [ $objectgui GetObjectGUI ] configure -description $description
    $objectgui Update
    $objectgui configure -callback "$this GUICallback"

    if { $parent == 0 } {
	$this UpdateInternalGUI
	return
    }

    if { $objecttype == "pxitclimage" } {
	set viewer [ $parent GetViewer ]
	if { $viewer !=0 } {
	    [ $objectgui GetObjectGUI ] AddFunction "$this DisplayImage" "Display" "$viewer"
	}
    } elseif { $objecttype != "pxitcltransform" } {
	set viewer [ $parent GetBisViewer ]
#	puts stderr "Viewer =$viewer, parent=$parent [ $parent info class ]"
	[ $objectgui GetObjectGUI ] AddFunction "$this DisplayObject" "Display" "$viewer"
    }

    $objectgui AddFunction "$this GUIQuickHelp" "?" ""
    $this UpdateInternalGUI
    

}
# ------------------------------------------------------------------------------------------------------------------
itcl::body bis_object::CreateDataTreeObjectGUI { base { enablegrab 0 } { enablestore 0 } { parent 0 } { datatree 0 }} {

    if { $internalobject == 0 } {
	return 0
    }

    if { $multipleobjectflag == 1 } {
	return [ $this CreateMultipleDataTreeObjectGUI $base $enablegrab $enablestore $parent $datatree ]
    }


    set algparent  $parent
    #    puts stderr "Parent=$parent, datatree=$datatree"
    set objectguimode "datatree"

    set fr [ [  iwidgets::Labeledframe $base -labelpos n -labeltext $description ] childsite ]
    pack $base -side top -expand true -fill x -pady 0

    set guiparam($this,treetext) ""
    set ent1 [ entry $fr.ent -width 30 -state normal  -foreground black -background white -textvariable [ itcl::scope guiparam($this,treetext) ]]

    if { $objecttype!="pxitcltransform" } {
	set but2 [ eval "button $fr.grabbutton2 -activebackground white -foreground black -activeforeground black -text \"Display\" -command { $this DisplayObject 0 $datatree }" ]
	pack $but2 -side left -expand false -padx 1
	
	if { $enablegrab >  1 } {
	    set but2 [ eval "button $fr.grabbutton0 -activebackground white -foreground black -activeforeground black -text \"GRef\" -command { $this GrabTreeSelection $datatree 1 }" ]
	    pack $but2 -side left -expand false -padx 0
	}
    } else {
	set but2 [ eval "button $fr.grabbutton2 -activebackground white -foreground black -activeforeground black -text \"Info\" -command { $this InfoObject }" ]
	pack $but2 -side left -expand false -padx 1
    }
	
    if { $enablegrab >  0 } {
	set but1 [ eval "button $fr.grabbutton -activebackground white -foreground black -activeforeground black -text \"Grab\" -command { $this GrabTreeSelection $datatree 0 }" ]
	pack $but1  -side left -expand false -padx 0
    }

    if { $enablestore >  0 } {
	set but1 [ eval "button $fr.grabbutton -activebackground white -foreground black -activeforeground black -text \"Store\" -command { $this StoreInTree $datatree  }" ]
	pack $but1  -side left -expand false -padx 0
    }


    pack $ent1 -side right -expand true -padx 0 -fill x
}
# ------------------------------------------------------------------------------------------------------------------
itcl::body bis_object::CreateMultipleDataTreeObjectGUI { base { enablegrab 0 } { enablestore 0 } { parent 0 } { datatree 0 }} {

    if { $internalobject == 0 } {
	return 0
    }

    set algparent  $parent
    set objectguimode "datatree"

    set fr [ [  iwidgets::Labeledframe $base -labelpos n -labeltext $description ] childsite ]
    pack $base -side top -expand true -fill x -pady 0
    frame $fr.right; pack $fr.right -side right -expand false -fill x -padx 2

    set guiparam($this,treelistbox) [ iwidgets::scrolledlistbox $fr.left -vscrollmode dynamic -hscrollmode dynamic -selectmode single -labelpos nw -visibleitems 5x20 ]
    [ $fr.left component listbox ] configure -bg white -fg black -width 30
    pack $fr.left -side left -expand true -fill both

    set fr $fr.right

    if { $objecttype!="pxitcltransform" } {
	set but2 [ eval "button $fr.grabbutton2 -activebackground white -foreground black -activeforeground black -text \"Display\" -command { $this DisplayObject 0 $datatree }" ]
	pack $but2 -side top -expand true -padx 1 -fill x -pady 5
	
	if { $enablegrab >  1 } {
	    set but2 [ eval "button $fr.[ pxvtable::vnewobj ]  -activebackground white -foreground black -activeforeground black -text \"GRef\" -command { $this GrabTreeSelection $datatree 1 }" ]
	    pack $but2 -side top -expand false -padx 0 -fill x -pady 5
	}
    } else {
	set but2 [ eval "button $fr.[ pxvtable::vnewobj ] -activebackground white -foreground black -activeforeground black -text \"Info\" -command { $this InfoObject }" ]

	pack $but2 -side top -expand false -padx 1 -fill x -pady 5
    }


    if { $enablegrab >  0 } {
	set but1 [ eval "button $fr.[ pxvtable::vnewobj ] -activebackground white -foreground black -activeforeground black -text \"Grab\" -command { $this GrabTreeSelection $datatree 0 }" ]
	pack $but1  -side top -expand false -padx 0 -fill x -pady 5
    }

    if { $enablestore >  0 } {
	set but1 [ eval "button $fr.[ pxvtable::vnewobj ] -activebackground white -foreground black -activeforeground black -text \"Store\" -command { $this StoreInTree $datatree  }" ]
	pack $but1  -side top -expand false -padx 0 -fill x -pady 5
    }

	set but3 [ eval "button $fr.[ pxvtable::vnewobj ] -activebackground white -foreground black -activeforeground black -text \"Clear Last\" -command { $this ClearTreeObject current }" ]
	set but4 [ eval "button $fr.[ pxvtable::vnewobj ] -activebackground white -foreground black -activeforeground black -text \"Clear All\" -command { $this ClearTreeObject all }" ]
	pack $but3 $but4 -side top -expand false -padx 0 -fill x -pady 10

    #    pack $ent1 -side right -expand true -padx 0 -fill x
}
# ---------------------------------------------------------------------------------------------------------

itcl::body bis_object::GUIQuickHelp { image args } {

    set line $description
    if { $cmdlineoption != "" } {
	set line "$line\n specify on the command line using -$cmdlineoption"
    }
    
    tk_messageBox -type ok -message $line -title "Quick Help: $name" -icon info
}
# ----------------------------------------------------------------------------------------------
itcl::body bis_object::InfoObject {  } {
    if { $multipleobjectflag == 0 } {
	tk_messageBox -type ok -title "Object Info" -message  [ $internalobject GetDescription ] 
    } else {
	set sur [ $objectgui GetObject -1 ]
	tk_messageBox -type ok -title "Object Info" -message  [ $sur GetDescription ] 
    }
}

itcl::body bis_object::DisplayImage { image viewer } {	
    $viewer SetImage [ $image GetImage ] [ $image GetOrientation ] 
}
# ----------------------------------------------------------------------------------------------
itcl::body bis_object::DisplayObject { sur viewer } {	

    if { $sur == 0 } {
	if { $multipleobjectflag == 0 } {
	    set sur [ $this GetObject ]
	} else {
	    set ind [ [ $guiparam($this,treelistbox) component listbox ] curselection ]
	    
	    if { $ind == -1  || $ind == "" } {
		return
	    }
	    if { $ind == 0 } {
		set sur [ $this GetObject ]
	    } else {
		set sur [ lindex $objectlist [ expr $ind -1 ]]
	    }
	}
    }
    
    if { [ $viewer  info class ] != "::bis_viewer"  } {
	puts stderr "My viewer is an algorithm!"
	set viewer [ $viewer GetBisViewer ]
	puts stderr "Using viewer = $viewer"
    }
    

    if { $sur == 0 } {
	return 0
    }

    if { [ $sur isa "pxitclimage" ] == 1 } {
	return [ $viewer SetImage $sur ]
    }
    $viewer AddOrReplacePolygonalObject $sur 0 { visible 1 }
}
    
# ----------------------------------------------------------------------------------------------
itcl::body bis_object::ClearTreeObject { { mode current } } {

    if {  [ $guiparam($this,treelistbox) index end ] == 0 } {
	return
    }

    if { $mode == "current" } {
	if { [ llength $objectlist ] > 0 } {
	    set n [ expr [ llength $objectlist] -1 ]
	    itcl::delete object [ lindex $objectlist $n ] 
	    set lst [ lrange $objectlist 0 [ expr $n -1 ] ]
	    set objectlist $lst
	} else {
	    $internalobject Clear
	}
	$guiparam($this,treelistbox) delete end end 
    } else {
	set ok [ tk_messageBox -type yesno -default no -title "Think again ..." -message "Do you want to clear the whole list?" -icon question  ]
	if { $ok == "no" } {
	    return
	}
	$internalobject Clear
	foreach obj $objectlist {
	    itcl::delete object $obj
	}
	$guiparam($this,treelistbox) delete 0 end 
    }
}

itcl::body bis_object::GrabTreeSelection { datatree { refspace 0 } } {

    if { $datatree == 0 } {
	return  0
    }

    if { $objecttype=="pxitcltransform" } {
	$internalobject  Copy  [ $datatree GetTransformation ] 
	set guiparam($this,treetext) "[$internalobject GetShortDescription]"
	
	if { $updatecallback != "" } {
	    eval $updatecallback
	}
	return 1
    }

    set datamanager [ $datatree GetDataManager ]
    set elem [ $datatree GetCurrentXMLElement ]
    if { $elem == "" || $elem == "0" } {
	return 0
    }

    set tp [ $elem GetAttribute Type ]
    set otype [ $datamanager GetObjectTypeForTypeAttribute $tp ]

    if {  $otype  != $objecttype } {
	return 0
    }

    # -----------------------------------

    if {  [ $elem GetAttribute ObjectLoaded ] != 1 } {
	set ok [ $datamanager LoadObjectPointers $elem  ]
	if { $ok == 0 } {
	    return 0 
	}
    }
    

    set newobj $internalobject
    if { $multipleobjectflag == 1 } {
	if {  [ $guiparam($this,treelistbox) index end ] > 0 } {
	    puts stderr "Adding new object"
	    set cl [ $internalobject info class ]
	    set newobj [ [ eval "$cl \#auto" ] GetThisPointer ]
	    lappend objectlist $newobj
	}
    }

    if { $refspace == 1 } {
	set img [  $datatree ResliceNodeInReferenceSpace $elem ]
	if { $img == 1 } {
	    set refspace 0
	}
	if { $img != 0 && $img!=1 } {
	    $newobj ShallowCopy $img
	    itcl::delete object $img
	    set xmlpointer 0
	}
    }
    
    if { $refspace == 0 } {
	$newobj ShallowCopy [ $elem GetAttribute PointerObject ]
	set xmlpointer $elem
    }



    set fn [ file tail [ $elem GetAttribute Filename ]]
    if { $fn == 0 } {
	set fn ""
    } else {
	set fn ":${fn}"
    }

    set txt "[ $elem GetName ]$fn ([$internalobject GetShortDescription])"
    if { $multipleobjectflag == 0 } {
	set guiparam($this,treetext)  $txt
    } else {
	set n [ expr [ llength $objectlist ] +1 ]
	$guiparam($this,treelistbox) insert end $txt.$n
	$guiparam($this,treelistbox) selection clear 0  end 
	$guiparam($this,treelistbox) selection set end  end 
    }
    
    if { $updatecallback != "" } {
	eval $updatecallback
    }
}
# ----------------------------------------------------------------------------------------------
itcl::body bis_object::StoreInTree { datatree } {

    if { $datatree == 0 } {
	return  0
    }
    

    set nm ""
    catch { set nm "[ $algparent GetGUIName ]" }
    regsub -all " " $nm "_" nm

    if { $objecttype=="pxitcltransform" } {
	$datatree AddTransformation  $internalobject $nm
	return 1
    }


    set elem [ $datatree GetCurrentXMLElement ]
    if { $elem == "" || $elem == "0" } {
	return 0
    }

    set datamanager [ $datatree GetDataManager ]
    set ndtype [ $datamanager GetTypeAttributeForObjectType $objecttype ]

    set newelem [ $datatree AddNewNode $ndtype ]
    if  { $newelem == 0 } {
	return 0
    }

    if { [ $internalobject isa "pxitclimage" ] == 1 || [ $internalobject isa "pxitclsurface"  ] ==1  || [ $internalobject isa "pxitclmesh" ] == 1 } {
	[ $newelem GetAttribute PointerObject ] ShallowCopy $internalobject
    } else {
	[ $newelem GetAttribute PointerObject ] Copy $internalobject
    }
    $newelem SetAttribute Filename [ $internalobject cget -filename ]

    set nm ""
    catch { set nm "[ $algparent GetGUIName ]_" }
    append nm $description

    $newelem SetAttribute Title    $nm
    $datamanager UpdateAttributesByList $newelem { "ObjectLoaded" Filename Title }
    $datatree    UpdateVisTree  [ $newelem GetParent ]
    $datatree    UpdateStatus 
    return $newelem
}
# ----------------------------------------------------------------------------------------------
itcl::body bis_object::UpdateInternalGUI { } {

    if { $objectguimode  == "normal" && $objectgui !=0 } {

	if { $multipleobjectflag == 0 } {
	    $objectgui Update
	} else {
	    set update_gui_internally 1
	    set num [ $objectgui GetNumberOfObjects ]
	    set newlist [ concat $internalobject $objectlist ]
	    set num2 [ llength $newlist ]

	    for { set i 0 } { $i < $num2 } { incr i } {
		set oldobj [ lindex $newlist $i ]
		if { $i >= $num } {
		    set newobj [ $objectgui AddInternalObject ]
		} else {
		    set newobj [ $objectgui GetObject $i ]
		}

		$newobj ShallowCopy $oldobj
	    }

	    set num [ $objectgui GetNumberOfObjects ]
	    if { $num > 0 } {
		$objectgui CurrentObjectModified
	    }
	    set update_gui_internally 0
	}
    }
    set guiparam($this,treetext) "[$internalobject GetShortDescription]"
}


itcl::body bis_object::UpdateObjectListFromGUI { } {

    if { $objectguimode  == "normal" && $objectgui !=0 } {
	set update_gui_internally 1
	set num [ $objectgui GetNumberOfObjects ]
	if { $num == 0 } {
	    set update_gui_internally 0
	    return 
	}
	set newlist [ concat $internalobject $objectlist ]
	set num2 [ llength $newlist ]
	
	for { set i 0 } { $i < $num } { incr i } {
	    set oldobj [ $objectgui GetObject $i ]
	    
	    if { $i < $num2 } {
		set newobj [ lindex $newlist $i ]
	    } else {
		set cl [ $oldobj info class ]
		set newobj [ [ eval "$cl \#auto" ] GetThisPointer ]
		lappend objectlist $newobj
	    }
	    $newobj ShallowCopy $oldobj
	}
	set update_gui_internally 0
    }
}
# ----------------------------------------------------------------------------------------------
itcl::body bis_object::GUICallback { } {


    if { $update_gui_internally == 1 } {
	return
    }

    if { $objectgui == 0 || $internalobject == 0 } {
	return 0
    }
    
    if { $multipleobjectflag == 0 } {
	if { $internalobject != [ $objectgui GetObject ] } {
	    $internalobject ShallowCopy [ $objectgui GetObject ]
	}
    } else {

    }

    if { $updatecallback != "" } {
	eval $updatecallback
    }
}

itcl::body bis_object::GetFileName { } { 
    if { $internalobject == 0 } {
	return ""
    }
    return [ $internalobject cget -filename ]
}

itcl::body bis_object::SetFileName { a { force 0 } } {

    if { $a == "" } {
	return 0
    }

    if { $guimode == "managed" } {
	set force 1
    }
    
#    puts stderr "Setting FileName of $name, $description to \"$a\" force=$force $internalobject"
    if { $internalobject == 0 } {
	return 0
    }


    set fn [ $this GetFileName ]
    if { [ string length $fn ] > 1 && $force == 0 } {
	#	puts stderr "Filenames not set to $a"
	return 0
    }



    $internalobject configure -filename $a  
    set update_gui_internally 1
    if { $objectgui != 0 } {
	$objectgui Update
    }
    set update_gui_internally 0

 #   puts stderr "Filenames set to $a"

    return 1
}

