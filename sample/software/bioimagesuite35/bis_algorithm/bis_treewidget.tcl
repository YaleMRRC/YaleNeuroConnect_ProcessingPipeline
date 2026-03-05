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


# Add Surface Display now!

if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    lappend auto_path [ file dirname [ info script ]]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".."] base ]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".."] bis_algorithm ]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".."] main]
}
package require  vtkpxcontrib 1.1
package require  pxtclutil    1.0
package require  pxvtable     1.0
package require  pxtclhelp    1.0
package require  Itcl         
package require VisTree 3.0
package require  Iwidgets     4.0
package require bis_datamanager 1.0
package require bis_resliceimage 1.0
package require bis_optiondialog 1.0
package require pxtclutil
package require bis_createoverlayimage 1.0
package provide bis_treewidget 1.0
package require bis_viewer 1.0
package require bis_algorithm 1.0
# --------------------------------------------------------------------------
#
#  Todo --- add node
#       --- edit node properties
#       --- display in ref space
#      
#   File:   New/Load/Save/Save Reorganized Copy/Anonymize/Validate (all objects exist)/Exit
#   Edit:   Undo/Delete/Cut/Copy/Paste/Paste Structure/enable drag and drop/Properties
#   Insert: Image/Surface/Landmarks/Electrodes/Folder/Subject/Tree
#      
# start here ..........
# Right Click Menu: Set Filenames (Object/Xform1/Xform2), Insert Child, Edit Properties
#              edit node properties dialog (eventually)
#
#
#  to create a new element
#   set datamanager [ $xmltree GetDataManager ]
#      create this parentnode
#   set ref [ eval "$datamanager CreateChildElement $parentnode Image MNI_Image { Filename $f2 } " ]
#
#   $xmltree UpdateVisTree $parentnode
#
# --------------------------------------------------------------------------


itcl::class bis_treewidget {

    inherit bis_algorithm

    constructor { } { $this Initialize }

    public method GetThisPointer { } { return $this }
    protected method Initialize { }
    # Cleaned up
    public method UpdateVisTree  { {  rdnode 0 } args } 
    public method UpdateExpandedFlag {  {  rdnode 0 } }
    public method UpdateAll { }

    # Not cleaned up
    public method CreateGUI { base { overlaymode 0 } { readonly 0 }  { hasfilemenu 0 } }
    public method CreateUglyGUI { base }

    # Shortest path along tree
    public method SetReferenceSpace { { nd 0 } }


    # Mouse Bindings
    public method SetSelection { W x y }
    public method GetCurrentXMLElement { }
    public method GetCurrentObject { }
    public method GetCurrentObjectFilename { }

    public method UpdateStatus {  }
    public method PrintCurrentNode { }
    public method LockEditing { }
    public method LockSpace { } 
    public method DisplayObject { img }
    public method DisplayCurrentNode { { space ref } }
    public method EditCurrentSurface { } 
    public method UpdateEditedSurface { elem obj } 
    public method DisplayNodeInReferenceSpace { elem }
    public method ResliceNodeInReferenceSpace { elem }
    


    # ----------------------------
    public method ClipboardOperation { operation }


    # Overlay Tool Stuff
    # -----------------------------------
    public method CreateOverlayTool { base }
    public method UpdateOverlayTool { mode }
    public method ShowOverlayTool {  }

    # Viewer Stuff
    # --------------------------------------------
    #    public method SetViewerList { lst } { set viewerlist $lst; $this SetBisViewer [ lindex $lst 0 ] }
    #    public method SetCurrentViewer { args }


    # Context Menus ..............
    #$mdmenubar add cascade -label $m -menu $mdmenubar.m$m -background $menucolor 

    protected method AddContextMenuEntry { mb label  command {  ronlyflag 0 } { spaceflag 0 } }
    protected method AddToolbarEntry { mb text balloonstring { command 0 } {  ronlyflag 0 } { spaceflag 0 } }

    protected method CreateContextMenus { }
    protected method CreateContextToolbars { w }

    
    public method ShowContextMenu { W x y }   
    public method ShowContextToolbar {  }
    public method SetNodeFilename { md }  
    public method SaveNode { md }  
    public method EditNodeProperties { args } 
    public method UpdateNodeProperties { args } 
    public method ToggleNodeProperty { property } 
    public method AddNewNode { ndtype } 


    # Load & Save
    public method LoadDataTree { { fname "" } }
    public method SaveDataTree { { fname "" } }

    # GetDatamanager
    public method GetDataManager { } { return $datamanager }

    # Transformation Stuff
    public method GetTransformation   { } 
    public method SetTransformation   { newtr args } 
    public method AddTransformation { tr { name "" }  }
    public method UpdateTransformation   { } 
    public method SetBisViewer { vr } {
	::bis_algorithm::SetBisViewer $vr
	if { $overlaytool !=0 } {
	    $overlaytool SetBisViewer $vr
	}
    }
    
    # --------------------------------------------------



    # Variables
    # This is the manager
    protected variable datamanager 0
    # this is the root node
    protected variable rootnode 0

    # This is the tree!
    protected variable vistree 0
    
    # Parameters for other stuff
    protected common guiparams

    # Context Menus
    protected variable contextmenu
    protected variable contextbar
    protected variable currentcontextbar 0
    protected variable optionsdialog 0
    protected variable forcereadonlymode 0
    protected variable readonlybuttonlist ""
    protected variable readonlymenulist ""
    protected variable setspacebuttonlist ""
    protected variable setspacemenulist ""

    # Overlay Tool Stuff
    protected variable overlaytool 0
    protected variable reslicealg  0
    protected variable overlaytooldlg 0
    protected variable hasfilemenu 0
    protected variable viewerlist ""
    protected variable transformation_control 0
    protected variable owns_current_transformation 0
    protected variable current_transformation 0 
    public variable createtransformcontrol 0
}

# -----------------------------------------------------------------------
itcl::body bis_treewidget::Initialize { } {

    set guiparams($this,helpVar) ""
    set guiparams($this,status) ""
    set guiparams($this,ref_space) ""
    set guiparams($this,clipboard) ""
    set guiparams($this,clipboardelement) 0
    set guiparams($this,interpmode) 0
    set guiparams($this,viewerindex) 0
    set guiparams($this,undoelement) 0
    set guiparams($this,undoelementparent) 0
    set guiparams($this,treefilename) ""
    set guiparams($this,displayonlymode) 1
    set guiparams($this,lockspaceimage) 1
    

    set current_transformation [ [ pxitcltransform \#auto ] GetThisPointer ]
    set  owns_current_transformation 1

    set datamanager [ [ bis_datamanager \#auto ] GetThisPointer ]
    set rootnode [ $datamanager GetRootNode ]

    set p1 [ file dirname [ info script ]]
    set p2 [ file normalize [ file join $p1 [ file join ".." images ] ] ]
    set f2 "[ file join $p2 MNI_T1_1mm_stripped.nii.gz ]" 

    set ref [ eval "$datamanager CreateChildElement $rootnode Image MNI_Image { Filename $f2 } " ]

    set optionsdialog [ bis_optiondialog \#auto ]
    $optionsdialog InitializeAsXMLDataElement $datamanager
    $optionsdialog SetCallback "$this UpdateNodeProperties"

    set guiparams($this,ref_space) [ $ref GetName ]
    $this AddDefaultOptions
}

# ------------------------------------------------------------------------------------
# Transformation Interface
# ------------------------------------------------------------------------------------

::itcl::body bis_treewidget::GetTransformation   { }  {

    $this UpdateTransformation
    return $current_transformation 
}


itcl::body bis_treewidget::AddTransformation { tr { name "" } } {

    if { $transformation_control == 0 } { return 0 } 
    set ind [ $transformation_control GetNextObjectIndex ]
    if { $name == "" } {
	$transformation_control AddInternalObject 
    } else {
	$transformation_control AddObject  "$name.$ind"
    }
    set basetr [ $transformation_control GetCurrentObject ]

    set vtkmode 1
    catch { 
	if { [ $tr isa pxitcltransform ] == 1 } {
	    set vtkmode 0
	}
    }
    
    if { $vtkmode == 0 } {
	$basetr Copy $tr
    } else {
	$basetr CopyTransformation $tr
    }
    $transformation_control CurrentObjectModified
    return $ind
}
# -----------------------------------------------------------------------
itcl::body bis_treewidget::SetTransformation { newtr args } {

    if { $transformation_control == 0 } { return 0 } 
    set mode "modify"
    if { [ llength $args ] > 0 } {
	set mode [ lindex $args 0 ]
    }
    
    if { $mode == "add" } {
	$transformation_control AddInternalObject 
    }

    set basetr [ $transformation_control GetCurrentObject ]
    $basetr CopyTransformation $newtr
    $transformation_control CurrentObjectModified
    update idletasks
}

# -------------------------------------------------------------------
::itcl::body bis_treewidget::UpdateTransformation   { }  {
    
    if { $transformation_control == 0 } { return 0 } 

    if {  $owns_current_transformation == 1 } {
	itcl::delete object $current_transformation
	set owns_current_transformation 0
    }
    set current_transformation [ $transformation_control GetObject -1 ]
    
}

# --------------------------------------------------------------------------
#::itcl::body bis_treewidget::SetCurrentViewer { args } {
#    #    puts stderr "args=$args"
#    set vname [ lindex $args 1 ]
#    set number [ expr [ string range [ file extension $vname ] 1 end ] -1 ]
#    #puts stderr "Index=$number"
#    $this SetBisViewer [ lindex $viewerlist $number ]
#    puts stderr "Tree viewer = $bis_viewer "
#}
# --------------------------------------------------------------------------
::itcl::body bis_treewidget::UpdateExpandedFlag { { rdnode 0 } } {

    if { $rdnode ==0 }  {
	set rdnode $rootnode
    }
    set pathname  [ $rdnode GetAttribute VisTreePath ]
    set v $::Tree::Tree($vistree:$pathname:open)  
    $rdnode SetAttribute Expanded $v
    set num 0
    catch { set num [ $rdnode GetNumberOfNestedElements ] }
    if { $num > 0 } {
	for { set j 0 } { $j < $num } { incr j } {
	    $this UpdateExpandedFlag  [ $rdnode GetNestedElement $j ]
	}
    }
}
# --------------------------------------------------------------------------
::itcl::body bis_treewidget::UpdateVisTree { { rdnode 0 } args } {
    
    if { $rdnode !=0 }  {
	set nodename [ $rdnode GetName ] 
	if { [ llength $args ] == 0 } {
	    set pathname  [ file rootname  [ $rdnode GetAttribute VisTreePath ] ]
	} else {
	    set basename [ lindex $args 0 ]
	    set pathname [ file join $basename $nodename ]
	}
	set dirname [ file dirname $pathname ]
    } else {
	set rdnode $rootnode
	set nodename [ $rdnode GetName ]
	set pathname "/Data"
	set dirname "/Data"
    }

    
    #Delete the node in the vis tree (which deletes all children)
    ::Tree::delitem $vistree $pathname 

    
    # Add new one based on tree
    #    puts stderr "Updating attributes [ $rdnode GetName ]"
    $datamanager UpdateDisplayAttributes $rdnode
    set linecolor goldenrod2
    set x [ $rdnode GetAttribute Linecolor ]
    switch -exact -- $x {
	0 { set linecolor red}
	1 { set linecolor purple}
	2 { set linecolor green}
	green { set linecolor green }
	purple { set linecolor purple }
	red { set linecolor red }
    }
    
    set icname [ $rdnode GetAttribute Icon ]

    if { [ string length $icname ] > 1 } {
	Tree::newitem $vistree $pathname -image $icname -linecolor $linecolor 
    } else {
	Tree::newitem $vistree $pathname  -linecolor $linecolor 
    }

    $rdnode SetAttribute VisTreePath $pathname

    #--------------------------------------------------------------------------------
    # Now deal with the children in the same way
    #--------------------------------------------------------------------------------
    set num 0
    catch { set num [ $rdnode GetNumberOfNestedElements ] }

    if { $num > 0 } {

	for { set j 0 } { $j < $num } { incr j } {
	    set elem [ $rdnode GetNestedElement $j ]
	    $this UpdateVisTree $elem $pathname
	}
    }

    Tree::open $vistree $pathname
    if { [ $rdnode GetAttribute Expanded ] != 1 && $dirname!= "/Data" } {
	Tree::close $vistree $pathname
    } 

    set guiparams($this,status) ""
    set guiparams($this,clipboard) ""
    set guiparams($this,clipboardelement) 0

    
};#End updateVisTree method



#----------------------------------------------------------------------
#These methods set the functions for the mouse bindings in the tree
#----------------------------------------------------------------------
::itcl::body bis_treewidget::SetSelection { W x y } {
    set lbl [Tree::labelat $W $x $y ]
    if { $lbl == "" } { 
	return 
    }
    Tree::setselection $W $lbl
    if { $lbl == "/Data" } { 
	return 
    }
    set nodeID [ file tail $lbl ]
    $this UpdateStatus
    $this ShowContextToolbar 
} 

# ---------------------------------------------------------------------
itcl::body bis_treewidget::GetCurrentObject { } {
    set p [ $this GetCurrentXMLElement ] 
    if { $p ==0 } {
	return
    }
    
    return [ $p GetAttribute PointerObject ]
}
# ---------------------------------------------------------------------
itcl::body bis_treewidget::GetCurrentObjectFilename { } {
    set p [ $this GetCurrentXMLElement ] 
    if { $p ==0 } {
	return
    }
    return [ $p GetAttribute Filename ]
}
# ---------------------------------------------------------------------
itcl::body bis_treewidget::GetCurrentXMLElement { } {

    set nodepath [Tree::getselectionpath $vistree ]
    set p [ file tail $nodepath ]
    set elem [ $datamanager FindNode $p ]

    if { $elem ==0  } {
	return 0
    }
    return $elem
}
# ---------------------------------------------------------------------
::itcl::body bis_treewidget::UpdateStatus {} {   

    set p [ $this GetCurrentXMLElement ] 
    if { $p ==0 } {
	return
    }
	
    set fn [ file tail [ $p GetAttribute Filename ]]
    if { $fn == 0 } {
	set fn ""
    } else {
	set fn ":${fn}"
    }
    set guiparams($this,status) "[ $p GetName ]([ string toupper [ $p GetAttribute Type ]])$fn"
    
    if { $overlaytool !=0 } {
	#	$this UpdateOverlayTool func
    }
}

itcl::body bis_treewidget::LockEditing { } {

    if { $forcereadonlymode ==  1 } {
	set guiparams($this,displayonlymode) 1
    }

    set state normal
    if { $guiparams($this,displayonlymode) == 1 } {
	set state disabled 
    }
    
    foreach pair $readonlybuttonlist {
	set mb [ lindex $pair 0 ]
	set en [ lindex $pair 1 ]
	$mb itemconfigure $en -state $state
    }

    foreach pair $readonlymenulist {
	set mb [ lindex $pair 0 ]
	set en [ lindex $pair 1 ]
	$mb entryconfigure $en -state $state
    }

}
# -----------------------------------------------
itcl::body bis_treewidget::LockSpace { } {

    set state normal
    if { $guiparams($this,lockspaceimage) == 1 } {
	set state disabled 
    }
    
    foreach pair $setspacebuttonlist {
	set mb [ lindex $pair 0 ]
	set en [ lindex $pair 1 ]
	$mb itemconfigure $en -state $state
    }

    foreach pair $setspacemenulist {
	set mb [ lindex $pair 0 ]
	set en [ lindex $pair 1 ]
	$mb entryconfigure $en -state $state
    }

}



itcl::body bis_treewidget::PrintCurrentNode { } {

    set elem [ $this GetCurrentXMLElement ] 
    if { $elem == 0 || $elem == "" } {
	puts stdout "no node selected\n"
	return 
    }
    set lst [ list PointerObject PointerTransformation PointerInverseTransformation ]
#    pxtkconsole
    pxtkprint "\n ----------------------------------------------------------------\n"
    pxtkprint "Reporting on node [ $elem GetName ]\n"
    for { set i 0 } { $i < [ $elem GetNumberOfAttributes ] } { incr i } {
	set desc ""
	set nm  [ $elem GetAttributeName $i ]
	set ind [ lsearch -exact $lst $nm ]
	if { $ind >= 0 } {
	    set obj [ $elem GetAttribute $nm ]
	    if { $obj !=0 && $obj != "" } {
		set desc [ $obj GetShortDescription ]
	    }
	}
	pxtkprint "\t\t [ $elem GetAttributeName $i ]=[ $elem GetAttributeValue $i] $desc\n"
    }

    pxtkprint "\t ********* Objects\t\n"
    set ptrs  [ $datamanager GetAttributePointersList ]
    for { set i 0 } {$i < [ llength $ptrs ] } {incr i } {
	set obj [ $elem GetAttribute [ lindex $ptrs $i ] ]
	if { $obj > 0 } {
	    pxtkprint "\n ********* [ lindex $ptrs $i ] = [ $obj GetDescription ]\n"
	} else {
	    pxtkprint "\n ********* [ lindex $ptrs $i ] = NULL\n"
	}
    }
	

    pxtkprint " ----------------------------------------------------------------\n"
}
# ----------------------------------------------------------------------
itcl::body bis_treewidget::LoadDataTree { { fname "" } } {

    if { [ string length $fname ] == 0 } {
	set typelist { {"XMLTree Files" { .xmltree  .tre .msb}}}
	set fname  [tk_getOpenFile -title "Load Tree" -filetypes $typelist ]   
    }
    
    if { [ string length $fname ] <1 } {
	return 0
    }

    set ext [ file extension $fname ]
    if { $ext == ".tre" } {
	set ok [ $datamanager ImportTree $fname ]
    } elseif { $ext == ".msb" }  {
	set ok [ $datamanager ImportMSBFile $fname ]
    } else {
	set ok [ $datamanager LoadXML $fname ]
    }

    if { $ok == 0 } {
	pxtclutil::Error "Failed to load tree from $fname"
	return 0
    }
    if { [ file extension $fname  ] != ".xmltree" } {
	set fname "[ file rootname $fname].xmltree"
    }

    set guiparams($this,treefilename) $fname

    $this UpdateAll 
    return $fname
}

# -----------------------------------------------------------------------
itcl::body bis_treewidget::UpdateAll { } {

    $this UpdateVisTree
    set guiparams($this,undoelementparent) 0

    set guiparams($this,lockspaceimage) 0
    $this SetReferenceSpace [ $datamanager FindFirstNodeByAttribute Type Image ]

    set guiparams($this,displayonlymode) 1
    set guiparams($this,lockspaceimage) 0
    $this LockEditing
    $this LockSpace
    return 1
}

#--------------------------------------------------------------------------

itcl::body bis_treewidget::SaveDataTree { { fname "" } } {

    if { [ string length $fname ] == 0 } {
	set typelist { {"XMLTree Files" { .xmltree }}}
	lappend typelist {"Old Style Files" {.tre }}
	set fname  [tk_getSaveFile -title "Load Tree" -filetypes $typelist -initialdir [ file dirname $guiparams($this,treefilename) ] -initialfile [ file tail $guiparams($this,treefilename) ] ]
    }

    if { [ string length $fname ] < 1 } {
	return 0
    }
    $this UpdateExpandedFlag

    set ok [ $datamanager SaveXML $fname ]
        if { $ok == 0 } {
	pxtclutil::Error "Failed to save tree in $fname"
	return 0
    }

    set guiparams($this,treefilename) $fname
    return $fname
}
# ----------------------------------------------------------------------
itcl::body bis_treewidget::ClipboardOperation { operation } {

    if { $guiparams($this,displayonlymode) == 1 } { return }

    if { $operation != "undo" } {
	set elem [ $this GetCurrentXMLElement ] 
	if { $elem ==0 } {
	    return 0
	}
	
	
	if { $operation == "cut" || $operation == "delete" } {
	    if { $elem == $rootnode } {
		puts stderr "Can't move rootnode"
		return 0
	    }
	}
    }

    if { $operation == "cut" } {
	set guiparams($this,clipboard) [ $elem GetAttribute VisTreePath ]
	set guiparams($this,clipboardelement) $elem	
	puts stdout "Reporting on clipboard node [ $elem GetName ]"
	for { set i 0 } { $i < [ $elem GetNumberOfAttributes ] } { incr i } {
	    puts stdout "\t\t [ $elem GetAttributeName $i ]=\"[ $elem GetAttributeValue $i]\"" 
	}

	return 1
    }

    if { $operation == "paste" } {
	if { $guiparams($this,clipboardelement) == 0 } {
	    puts stderr "Nothing to paste\n"
	    return 0
	}

	set clipelem $guiparams($this,clipboardelement)
	if { $elem == $clipelem } {
	    puts stderr "Paste to itself makes no sense"
	    return 0
	}

	set ok [ $datamanager MoveElement $clipelem $elem ]
	if { $ok == 1 } {
	    $elem SetAttribute Expanded  1
	    $this UpdateVisTree
	}
	return 1
    }

    if { $operation == "delete" } {
	
	if { $guiparams($this,undoelement)  != 0 } {
	    $datamanager RecursiveDeleteChildren $guiparams($this,undoelement)
	}
	set guiparams($this,undoelement) $elem
	set guiparams($this,undoelementparent) [ $elem GetParent ]
	$elem Register $rootnode
	puts stderr "Detatching $elem"
	[ $elem GetParent ] RemoveNestedElement $elem
	puts stderr "Detached $elem, [ $elem GetName ]"

	$this UpdateVisTree
	return 1
    }

    if { $operation == "undo" } {

	puts stderr "in Undo"
	if { $guiparams($this,undoelement)  == 0 || $guiparams($this,undoelementparent) == 0 } {
	    puts stderr "0 undoelement or parent"
	    return 0
	}

	set nm [ $guiparams($this,undoelementparent) GetName ]
	set par [ $datamanager FindNode $nm ]
	if { $par != $guiparams($this,undoelementparent) } {
	    puts stderr "Bad parent $par"
	    return 0
	}

	set elem $guiparams($this,undoelement)
	$par AddNestedElement $elem
	$par SetAttribute Expanded  1
	$elem Register $rootnode
	puts stderr "Re-attached $elem, [ $elem GetName ]"

	set guiparams($this,undoelement) 0
	set guiparams($this,undoelementparent) 0
	$this UpdateVisTree
	return 1
    }

}
# ----------------------------------------------------------------------

itcl::body bis_treewidget::SetReferenceSpace { { nd 0 } } {

    if { $guiparams($this,lockspaceimage) == 1 } {
	return 0
    }

    if { $nd == 0 } {
	set elem [ $this GetCurrentXMLElement ]
    } else {
	set elem $nd
    }
	
    if { $elem ==0 } {
	return 0
    }

    if { [ $elem GetAttribute Type ] != "Image" } {
	return 0
    }

    set currentselection [ $elem GetName ]
    set guiparams($this,ref_space) $currentselection

    if { $overlaytool !=0 } {
	#	$this UpdateOverlayTool ref
    }


    return 1

}
# -----------------------------------------------------------------------
itcl::body bis_treewidget::DisplayNodeInReferenceSpace { nd } {


    set img [  $this ResliceNodeInReferenceSpace $nd ]
    $this DisplayObject $img
    itcl::delete object $img
}

# -----------------------------------------------------------------------
itcl::body bis_treewidget::ResliceNodeInReferenceSpace { nd } {

    if { $nd == 0 || $nd == "" } {
	return 0
    }


    set elem(1) [ $datamanager FindNode $guiparams($this,ref_space) ]
    set elem(2) $nd

    if { $elem(1) == $elem(2) } {
	puts stderr "Same Node"
	return 1
    }

    if { $elem(1) == 0 || $elem(2) == 0 } {
	puts stderr "Nodes not found\n"
	return 0
    }
	

    for { set i 1 } { $i <=2 } { incr i } {
	set anc($i) [ $datamanager GetAncestors $elem($i) ]
    }
    
    if { [ $nd GetAttribute Type ] != "Image" } {
	set lst [ $datamanager GetTransformationList $elem(2) $elem(1) ]
    } else {
	set lst [ $datamanager GetTransformationList $elem(1) $elem(2) ]
    }


    if { [ lindex $lst 0 ] == "Failed" } {
	pxtclutil::Info "Error $lst"
	return 0
    }

#    pxtkconsole
    pxtkprint "\nTransformation list:\n"
    for { set i 0 } { $i < [ llength $lst ] } { incr i } {
	pxtkprint "[expr $i+1 ] : [ [ lindex $lst $i ] cget -filename ], [ [ lindex $lst $i ] GetShortDescription ]\n"
    }

    
    set tr [ $datamanager GetCombinedTransformation $lst ]
    set inputobj [ $elem(2) GetAttribute PointerObject ]

    switch -exact [ $nd GetAttribute Type ] {
	"Surface" {
	    pxtkprint  "Transforming Surface ...\n"
	    set tempobject [ [ pxitclsurface \#auto] GetThisPointer ]
	    $tempobject ShallowCopy $inputobj
	    $tempobject Transform $tr
	}
	"Mesh" {
	    pxtkprint  "Cannot Transform Mesh ...\n"
	    pxtkconsole
	    # Needs fixing -- i.e. Transform method needs fixing
	    set tempobject [ [ pxitclmesh \#auto] GetThisPointer ]
	    $tempobject ShallowCopy $inputobj
	    $tempobject Transform $tr
	}
	"Landmarks" {
	    set tempobject [ [ pxitcllandmarks \#auto] GetThisPointer ]
	    pxtkprint  "Transforming Landmarks ...\n"
	    $tempobject Copy $inputobj
	    $tempobject Transform $tr
	} 
	"Electrodes" {
	    set tempobject [ [ pxitclelectrodemultigrid \#auto] GetThisPointer ]
	    puts "Sending $tempobject to electrodecontrol: $electrodecontrol"
	    pxtkprint  "Transforming Electrodes ...\n"
	    $tempobject Copy $inputobj
	    $tempobject Transform $tr
	} 
	"Image"  {
	    pxtkprint  "Reslicing ...\n"
	    set resl [ bis_resliceimage \#auto ]
	    $resl InitializeFromContainer 0
	    $resl SetInput [ $elem(1) GetAttribute PointerObject ]
	    $resl SetSecondInput [ $elem(2) GetAttribute PointerObject ]
	    $resl SetVTKTransformation $tr
	    $resl SetOptionValue interp [ $guiparams($this,interpmode) GetValue ]
	    $resl SetOptionValue background 0.0
	    $resl Execute
	    
	    
	    set tempobject  [ [ pxitclimage \#auto ] GetThisPointer ]
	    $tempobject ShallowCopy [ $resl GetOutput ]
	    itcl::delete object $resl 
	}
    }
    $tr Delete

    return $tempobject

}
# ----------------------------------------------------------------------
itcl::body bis_treewidget::EditCurrentSurface {  } { 

    if { $bis_viewer ==0 } {
	return
    }

    set elem [ $this GetCurrentXMLElement ]
    if { $elem == 0 || $elem == "" } {
	puts stdout "no node selected\n"
	return 
    }
	
    $datamanager LoadObjectPointers $elem
    set sur [ $elem GetAttribute PointerObject ]
    $sur configure -filename "editObj"
    $bis_viewer EditPolygonalObject $sur $this $elem

}

# ------------------------------------------------------------------
itcl::body bis_treewidget::UpdateEditedSurface { xmlpointer obj }  {


    set nm ""
    catch { set nm [ $xmlpointer GetName ] }
    if { $nm != "" } {
	set newelem [ $datamanager FindNode $nm ]
    } else {
	set newelem -1
    }

    if { $newelem != $xmlpointer } {
	puts stderr "Tree has changed ... can't update, save and update nm=$nm"
	return 0
    }

    set obj2 [  $newelem GetAttribute PointerObject ] 
    if { [ $obj2 info class ] != [ $obj info class ] } {
	puts stderr "Class mismatch [ $obj2 info class ] != [ $obj info class ]"
    }

    puts stdout "OK proceeding newelem=$newelem, xmlpointer=$xmlpointer, obj = [ $obj info class ], obj2=[ $obj2 info class ]"

    puts stderr "Old = [ $obj2 GetDescription ]"
    $obj2 Copy $obj
    [ $obj2 GetObject ]  Modified
    [ $obj2 GetObject ]  Update
    
    puts stderr "New = [ $obj2 GetDescription ], $newelem"
}

# --------------------------------------------------------------

itcl::body bis_treewidget::DisplayCurrentNode { { space ref } } {

    set elem [ $this GetCurrentXMLElement ]
    if { $elem == 0 || $elem == "" } {
	puts stdout "no node selected\n"
	return 
    }
	
    if { [ $elem GetAttribute ObjectLoaded ] != 1 } {
	$datamanager LoadObjectPointers $elem
    }
    if { $space == "ref" } {
	return [ $this DisplayNodeInReferenceSpace $elem ]
    }

    $this DisplayObject [ $elem GetAttribute PointerObject ]
    return
}

# ----------------------------------------------------------------------
itcl::body bis_treewidget::DisplayObject { img } {

    if { $img ==0 || $img =="" } {
	return
    }

    if { $bis_viewer !=0 } {
	if { [ $img isa pxitclimage  ] } {
	    $bis_viewer SetImage $img	    
	} else {
	    puts stderr "displaying [ $img GetDescription ]"
	    $bis_viewer AddOrReplacePolygonalObject $img
	} 
    } elseif { $vtk_viewer !=0 } {
	$vtk_viewer SetImage [ $img GetImage ] [ $img GetOrientation ]
	$vtk_viewer SetPresetLookupTable -1
    } 
}

# -----------------------------------------------------------
itcl::body bis_treewidget::AddToolbarEntry { mb txt balloonstring { command 0 } {  ronlyflag 0 } { spaceflag 0 } } {

    set nm [ pxvtable::vnewobj ]
    if { $txt == "frame" } {
	set ln "$mb add frame \"$nm\" $balloonstring"
	eval $ln
	return
    }
	

    set nm [ pxvtable::vnewobj ]
    set ln "$mb add button \"$nm\"  -balloonstr \"$balloonstring\" -command { $command } -text $txt"
    eval $ln
    if { $ronlyflag > 0 } {
    	lappend readonlybuttonlist [ list $mb $nm  ]
    }
    if { $spaceflag > 0 } {
	lappend  setspacebuttonlist [ list $mb $nm ] 
    }

}
# -----------------------------------------------------------
itcl::body bis_treewidget::CreateContextToolbars { tc } { 

    foreach m { Image Surface Folder Subject } {

	set contextbar($m) [ iwidgets::toolbar $tc.[ pxvtable::vnewobj ] \
				 -balloondelay1 100 \
				 -balloondelay2 50 \
				 -orient vertical \
				 -font { helvetica 9 }\
				 -disabledforeground \#A0A0A0 \
				 -helpvariable guiparams($this,helpVar) ]

#				 -balloonbackground darkgray  -balloonforeground white 
#				 -background black -foreground \#ffffee 


	set tb $contextbar($m)
    }
    
    foreach m { Image Surface } {
	$this AddToolbarEntry $contextbar($m) ".." "Set Filename" "$this SetNodeFilename 0" 1
	$this AddToolbarEntry $contextbar($m) "Sv" "Save Object" "$this SaveNode 0" 1
	$this AddToolbarEntry $contextbar($m) frame "-borderwidth 1 -width 7 -height 4" 
	$this AddToolbarEntry $contextbar($m) "D" "Display" "$this DisplayCurrentNode native" 0 
        $this AddToolbarEntry $contextbar($m) "DR" "Display in Ref Space"  "$this DisplayCurrentNode ref" 0 
    }

    foreach m { Surface } {
        $this AddToolbarEntry $contextbar($m) "ED" "Edit Surface"  "$this EditCurrentSurface" 1
    }
	

    $this AddToolbarEntry $contextbar(Subject)  frame "-borderwidth 1 -width 7 -height 4"
    $this AddToolbarEntry $contextbar(Subject) "+F" "Add Folder" "$this AddNewNode Folder" 1


    foreach m { Image Folder } {
	$this AddToolbarEntry $contextbar($m) frame "-borderwidth 1 -width 7 -height 4"
	if { $m == "Folder" } {
	    $this AddToolbarEntry $contextbar(Folder) "+X" "Add Subject" "$this AddNewNode Subject" 1
	}
	$this AddToolbarEntry $contextbar($m)   "+F" "Add Folder" "$this AddNewNode Folder" 1
	$this AddToolbarEntry $contextbar($m)   "+I" "Add Image" "$this AddNewNode Image" 1
	$this AddToolbarEntry $contextbar($m)   "+S" "Add Surface " "$this AddNewNode Surface" 1
	$this AddToolbarEntry $contextbar($m)   "+L" "Add Landmark Set" "$this AddNewNode Landmarks" 1
	$this AddToolbarEntry $contextbar($m)   "+E" "Add Electrode Set" "$this AddNewNode Electrodes" 1
	$this AddToolbarEntry $contextbar($m)   "+M" "Add Mesh" "$this AddNewNode Mesh" 1



	if { $m == "Image" } {
	    $this AddToolbarEntry $contextbar($m) frame "-borderwidth 1 -width 7 -height 4"
	    $this AddToolbarEntry $contextbar($m) "Sp" "Set As Space" "$this SetReferenceSpace" 0 1
	    $this AddToolbarEntry $contextbar($m) frame "-borderwidth 1 -width 7 -height 4" 
	    $this AddToolbarEntry $contextbar($m) "ST" "Set Transformation" "$this SetNodeFilename 1" 1
	    $this AddToolbarEntry $contextbar($m) "SI" "Set Inverse Transformation" "$this SetNodeFilename 2" 1
	    $this AddToolbarEntry $contextbar($m) "Id" "(Un)set as Identity"  "$this ToggleNodeProperty IsIdentity" 1
	    $this AddToolbarEntry $contextbar($m) "cL" "Clear Transformations" "$this ToggleNodeProperty ClearTransformations" 1
	}
    }


    pack $contextbar(Folder) -side top -expand false -fill x
    set currentcontextbar $contextbar(Folder)
}
# -----------------------------------------------------------
itcl::body bis_treewidget::CreateUglyGUI { base } {

    set w3 [ frame $base.bot2 ]
    entry $w3.a -textvariable [ itcl::scope guiparams($this,status) ] -relief ridge \
	-disabledforeground white -state disabled  -disabledbackground black
    pack $w3.a -side top  -expand true -fill x

    frame $w3.b ;     pack $w3.b -side bottom -expand false -fill x
    pack $w3 -side top  -fill x -expand false

    set opt7 [ [ bis_option \#auto ] GetThisPointer ]
    $opt7 SetAllProperties "-interp" "Reslice Mode" "Mode" "listofvalues" Linear { "NearestNeighbor" "Linear" "Cubic" }  0 
    $opt7 CreateGUIElement $w3.b.1
    pack $w3.b.1 -side right 
    set guiparams($this,interpmode) $opt7

#    if { [ llength $viewerlist ] > 1 } {
#	set vname ""
#	for { set i 1 } { $i <= [ llength $viewerlist ] } { incr i } {
#	    lappend vname "Viewer.$i"
#	}
#
#	set opt8 [ [ bis_option \#auto ] GetThisPointer ]
#	$opt8 SetAllProperties "-viewer" "Viewer" "Viewer" "listofvalues" "Viewer.1" $vname  0 
#	eval "$opt8 CreateGUIElement $w3.b.11 { $this SetCurrentViewer }"
#	pack $w3.b.11 -side right 
#	set guiparams($this,viewerindex) $opt8
#    }
#


    set sp [ frame $w3.b.2  ]
    label $sp.1 -text "Reference Space:" 
    entry $sp.2  -textvariable [ itcl::scope guiparams($this,ref_space) ] -relief ridge \
	-disabledbackground black -disabledforeground white -state disabled 
    pack $sp.1 -side left -expand false
    pack $sp.2 -side right -expand true -fill x
    pack $w3.b.2 -side left -expand true -fill x


    set w [ frame $base.bot5  ]; pack $w -side top -expand true -fill x
    if { $hasfilemenu == 0 } {
	eval "button $w.1 -text \"Load\" -command { $this LoadDataTree } "
	eval "button $w.2 -text \"Save\" -command { $this SaveDataTree } "
	pack $w.1 $w.2  -side left -expand false -padx 2
    } 

    eval "button $w.3 -text \"Redraw\" -command {   $this UpdateExpandedFlag;  $this UpdateVisTree; $this UpdateStatus   } "
    eval "button $w.4 -text \"Overlay Tool\" -command { $this ShowOverlayTool   } "
    pack $w.3 $w.4 -side left -expand false -padx 2



}

# -------------------------------------------------------------------------
itcl::body bis_treewidget::AddContextMenuEntry { mb label  command {  ronlyflag 0 } { spaceflag 0 } } {

    set ln "$mb add command -label \"$label\" -command { $command }"
    eval $ln
    if { $ronlyflag > 0 } {
	lappend readonlymenulist [ list $mb  [ $mb index last ] ]
    }
    if { $spaceflag > 0 } { 
	lappend setspacemenulist [ list $mb  [ $mb index last ] ]
    }
}
 

itcl::body bis_treewidget::CreateContextMenus { } {
    
    foreach m { Image Surface Folder Subject } {
	set contextmenu($m) [menu $vistree.[ pxvtable::vnewobj ] -tearoff 0 ] 
	set mb $contextmenu($m)
	if { $m == "Image" || $m == "Surface" } {
	    $this AddContextMenuEntry $mb "Set Filename (..)" "$this SetNodeFilename 0" 1
	    $this AddContextMenuEntry $mb "Display (D)" "$this DisplayCurrentNode native" 0
	    $this AddContextMenuEntry $mb "Display in Ref Space (DR)" "$this DisplayCurrentNode ref" 0
	    $mb add separator
	}
	$this AddContextMenuEntry $mb "Edit Properties" "$this EditNodeProperties" 1
    }
}

itcl::body bis_treewidget::ShowContextMenu { W x y } {

    $this SetSelection $W $x $y
    set nd [ $this GetCurrentXMLElement ] 
    if { $nd == 0 } {
	return 0
    }

    set tp [ $nd GetAttribute Type ]

    if { $tp == "Surface" || $tp == "Landmarks" || $tp == "Electrodes" || $tp == "Mesh" } {
	set tp Surface
    } elseif { $tp != "Image" && $tp !="Subject" } {
	set tp Folder
    }


    set h [ expr 300- [ winfo height $contextmenu($tp) ] ]
    if { $h > 190 } {
	if { $tp == "Surface" || $tp == "Image" } {
	    set h 200
	} else {
	    set h 200
	}
    }
    puts stderr "h=$h, tp=$tp, $x, $y"
    tk_popup $contextmenu($tp) [ expr $x + 20 ] [ expr $y + $h ]
}


itcl::body bis_treewidget::ShowContextToolbar {  } {
    set nd [ $this GetCurrentXMLElement ] 
    if { $nd == 0 } {
	return 0
    }

    set tp [ $nd GetAttribute Type ]
    if { $tp == "Surface" || $tp == "Landmarks" || $tp == "Electrodes" || $tp == "Mesh" } {
	set tp Surface
    } elseif { $tp != "Image" && $tp !="Subject" } {
	set tp Folder
    }
    regsub -all "\"" $tp "" tp
    if { $currentcontextbar != 0 } {
	pack forget $currentcontextbar
    }
    pack $contextbar($tp) -side top -expand false -fill x
    set currentcontextbar $contextbar($tp)

}


itcl::body bis_treewidget::AddNewNode { ndtype } { 
    if { $guiparams($this,displayonlymode) == 1 } { return 0 }

    set nd [ $this GetCurrentXMLElement ] 
    if { $nd == 0 } {
	return 0
    }

    set elem [ $datamanager GetNewXMLDataElement $ndtype "New $ndtype" ]
    $nd AddNestedElement $elem
    $nd SetAttribute "Expanded" 1
    $this UpdateVisTree $nd
    Tree::setselection $vistree  [ $elem GetAttribute VisTreePath ]
    $this ShowContextToolbar
    return $elem
}



itcl::body bis_treewidget::EditNodeProperties { args }  {

    if { $guiparams($this,displayonlymode) == 1 } { return 0 }
    set p [ $this GetCurrentXMLElement ] 
    if { $p==0 || $p == "" } {
	return
    }
    
    set w [ $optionsdialog GetBaseWidget ]
    if { $w == 0 } {
	set w [ $optionsdialog CreateGUI  $basewidget ]
	wm geometry $w 700x350
	$optionsdialog SetOptionStatus Type 0
	$optionsdialog SetOptionStatus Icon 0
	$optionsdialog SetOptionStatus Expanded 0
    }
    $optionsdialog SetOptionsFromXMLDataElement $p
    $optionsdialog SetTitle "Editing Node [ $p GetAttribute Title ] Properties"

    set tp [ $p GetAttribute Type ]
    set dt 1
    if { $tp != "Image" } { 
	set dt 0 
    }
    $optionsdialog SetOptionStatus     TransformationFilename $dt 
    $optionsdialog SetOptionStatus     InverseTransformationFilename $dt
    $optionsdialog SetOptionStatus     IsIdentity $dt

    
    if { $tp == "Folder" || $tp == "Subject" } {
	$optionsdialog SetOptionStatus Filename 0
    } else {
	$optionsdialog SetOptionStatus Filename 1
    }

    wm deiconify $w
    wm focus $w
    $optionsdialog ShowWindow
}

# --------------------------------------------------------------------------

itcl::body bis_treewidget::ToggleNodeProperty { property } { 

    if { $guiparams($this,displayonlymode) == 1 } { return 0 }
    $this UpdateExpandedFlag
    set p [ $this GetCurrentXMLElement ] 
    if { $p == 0 } {
	return
    }
    if { $property == "ClearTransformations" } {
	set propery ""
	set ptrs  [ $datamanager GetAttributePointersList ]
	set fn    [ $datamanager  GetFilenamesList ]
	for { set i 1} { $i <=2 } { incr i } {
	    $p SetAttribute [ lindex $fn $i ] 0
	    set obj [ $p GetAttribute [ lindex $ptrs $i ] ] 
	    #	    puts stderr "obj=$obj"
	    catch { $obj Clear }
	    lappend property [ lindex $fn $i ]
	}
    } else {
	set v [ $p GetAttribute $property ]
	if { $v == 1 } {
	    $p SetAttribute $property 0
	} elseif { $v == 0 } {
	    $p SetAttribute $property 1
	}
    }

    $datamanager UpdateAttributesByList $p $property
    $this UpdateVisTree  [ $p GetParent ]
    $this UpdateStatus 
    $optionsdialog SetOptionsFromXMLDataElement $p
    
    Tree::setselection $vistree  [ $p GetAttribute VisTreePath ]

}

# -----------------------------------------------------------

itcl::body bis_treewidget::UpdateNodeProperties { args } {

    if { $guiparams($this,displayonlymode) == 1 } { return 0 }    
    $this UpdateExpandedFlag
    set xml [ $optionsdialog GetXMLElement ]
#    puts stderr "In Update Node Properties $xml"

    if { $xml == 0 || $xml == "" } {
	return 0
    }

    set name [ $xml GetName ]
    set elem [ $datamanager FindNode $name ]
    if { $elem == 0 || $elem =="" } {
	return 0
    }

    if { [ llength $args ] < 2 } {
	return
    }
    
    set nm [ $elem GetName ]
    $datamanager UpdateAttributesByList $elem [ lrange $args 1 end ]
    set nm2 [ $elem GetName ]

    if {  $nm != $nm2 &&  $guiparams($this,ref_space) == $nm } {
	# Refspace rename!
	#	puts stderr "Chaning ref space to $nm2"
	set guiparams($this,ref_space) $nm2
    }

    $this UpdateVisTree [ $elem GetParent ]
    Tree::setselection $vistree  [ $elem GetAttribute VisTreePath ]
    $this UpdateStatus 
    
}
# ---------------------------------------------------------------------------

itcl::body bis_treewidget::SetNodeFilename { args }  {
    
    if { $guiparams($this,displayonlymode) == 1 } { return 0 }

    set p [ $this GetCurrentXMLElement ] 
    if { $p ==0 || $p == "" } {
	return 0
    }

    set dt [ $p GetAttribute Type ]
    if { $dt == "Folder" || $dt == "Patient" } {
	return 0
    }

    if { $dt == "Image" } {
        set l [ lindex $args 0 ]
	if { $l !=1 && $l !=2 } {
	    set l 0
	}
    } else {
	set l 0
    }

    set ptrs  [ $datamanager GetAttributePointersList ]
    set fn    [ $datamanager  GetFilenamesList ]
    set obj   [ $p GetAttribute [ lindex $ptrs $l ] ]
    set fname [ $p GetAttribute [ lindex $fn $l ] ]
    if { $fname == 0 || $fname == -1 } {
	set fname ""
    }

    set fold [ $obj cget -filename ]
    $obj configure -filename $fname
    set ok [ $obj Browse "[$p GetName ]:  [ lindex $fn $l ]" ]
    if { $ok > 0 } {
	set fname [ $obj cget -filename ]
	#	puts stderr "Updating $fname=$fold"
	if { $fname != $fold } {
	    $obj Clear
	}
	#	puts stderr "Setting [ lindex $fn $l ]= $fname "
	$p SetAttribute [ lindex $fn $l ] $fname 
	$this UpdateVisTree $p
	$this  UpdateStatus 
	$optionsdialog SetOptionsFromXMLDataElement $p
	Tree::setselection $vistree  [ $p GetAttribute VisTreePath ]
    }
}
# ---------------------------------------------------------------------------------------------------------------------  
itcl::body bis_treewidget::SaveNode { args }  {
    
    if { $guiparams($this,displayonlymode) == 1 } { return 0 }

    set p [ $this GetCurrentXMLElement ] 
    if { $p ==0 || $p == "" } {
	return 0
    }

    set dt [ $p GetAttribute Type ]
    if { $dt == "Folder" || $dt == "Patient" } {
	return 0
    }

    set ptrs  [ $datamanager GetAttributePointersList ]
    set fn    [ $datamanager  GetFilenamesList ]
    set obj   [ $p GetAttribute [ lindex $ptrs 0 ] ]
    set fname [ $p GetAttribute [ lindex $fn 0 ] ]
    if { $fname == 0 || $fname == -1 } {
	set fname ""
    }

    set fold [ $obj cget -filename ]
    $obj configure -filename $fname
    set ok [ $obj Save "" "[$p GetName ]" ]
    if { $ok > 0 } {
	set fname [ $obj cget -filename ]
	if { $fname != $fold } {
	    $obj Clear
	}
	$p SetAttribute [ lindex $fn 0 ] $fname 
	$this UpdateVisTree $p
	$this  UpdateStatus 
	$optionsdialog SetOptionsFromXMLDataElement $p
	Tree::setselection $vistree  [ $p GetAttribute VisTreePath ]
    }
}
# ---------------------------------------------------------------------------------------------------------------------  
    
itcl::body bis_treewidget::CreateOverlayTool { base } {

#    protected variable overlaytool 0
#    protected variable overlaytooldlg 0

    set tp [ toplevel $base.[pxvtable::vnewobj ]];  wm withdraw $tp
    eval "wm protocol $tp WM_DELETE_WINDOW { wm withdraw $tp  }"
    wm title $tp "Overlay Tool"

    set buttonbar [ frame $tp.bt ]
    set bbt [ frame $tp.bt2 -bg black -height 5 ]
    pack $buttonbar $bbt -side bottom -expand false -fill x 
    
    eval "button $buttonbar.close   -text Close -command { wm withdraw $tp }"
    pack $buttonbar.close -side right
    
    set w [ frame $tp.top  ]
    pack $w -side top -expand true -fill both

    set overlaytool [ [ bis_createoverlayimage \#auto ] GetThisPointer ]
    $overlaytool InitializeFromContainer 0
    $overlaytool SetGUIMode managed
    if { $bis_viewer !=0 } {
	$overlaytool SetBisViewer $bis_viewer
    } else {
	$overlaytool SetBisViewer $vtk_viewer
    }
    $overlaytool CreateGUI $w
    $overlaytool SetOptionValue interp "NearestNeighbor"



    wm geometry $tp 600x400

    return $tp
}
# -----------------------------------------------------------------------
itcl::body bis_treewidget::UpdateOverlayTool {  mode } {

    if { $overlaytool == 0 } {
	return 0
    }

    set elem [ $this GetCurrentXMLElement ]
    if { $elem == 0 } { 
	return 0
    }

    set img [  $this ResliceNodeInReferenceSpace $elem ]
    if { $img == 0 } {
	return 0
    }
    
    set ref [ $datamanager FindNode $guiparams($this,ref_space) ]


    set f1 [ file tail  [ $ref  GetAttribute Filename ] ]
    set f2 [ file tail  [ $elem GetAttribute Filename ] ]

    $overlaytool SetInput   [ $ref GetAttribute PointerObject ]
    $overlaytool SetSecondInput  $img
    wm title $overlaytooldlg "$f1 <-> $f2"
    $overlaytool UpdateInputRanges
    itcl::delete obj $img

    return 1

}

itcl::body bis_treewidget::ShowOverlayTool {  } {

    if { $overlaytool == 0 } {
	return 0
    }
    set ok [ $this UpdateOverlayTool both ]
    if { $ok > 0 } {
	wm withdraw $overlaytooldlg
	wm deiconify $overlaytooldlg
    } else {
	wm withdraw $overlaytooldlg
    }
}

# -----------------------------------------------------------------------
# Create GUI -- be all , end all
# -----------------------------------------------------------------------

itcl::body bis_treewidget::CreateGUI { base { overlaymode 0 } { readonly 0 } { filem 0 } }  {

    set forcereadonlymode [ expr $readonly > 0 ]
    set hasfilemenu [ expr $filem > 0 ]

    set  basewidget $base.btf
    set btf [ [ iwidgets::labeledframe $basewidget  -labeltext "Data Manager Control"  ] childsite ]
    pack $basewidget -side top -expand true -fill both

    set overlaytooldlg [ $this CreateOverlayTool $basewidget ]

    # ------------------------------
    # Bottom Bar
    # ------------------------------

    set pbar [ frame $btf.bot5 ]
    pack $pbar -side bottom -expand false -fill x

    CreateProgressBar  $pbar

    set bbar [ frame $btf.bot ]
    $this CreateUglyGUI $bbar
    pack $bbar -side bottom -expand false -fill x
    
    #Set a variable "vistree" to hold the tree


    if { $createtransformcontrol == 1 } {
	set notebook [  iwidgets::tabnotebook $btf.top -tabpos n  -angle 45 -margin 2 -backdrop gray -raiseselect true ]
	pack $notebook -side top -expand true -fill both
	set maintab  [ $notebook add -label "Main Tree" ]
	set xformtab [ $notebook add -label "Transformations" ]
	$notebook view "Main Tree"
    } else {
	set maintab $btf
    }

    set tbar [ frame $maintab.0 ]
    set tbarleft  [ frame $tbar.1  ]
    set tbarright [ frame $tbar.2 ]
    pack $tbarleft -side left -expand false -fill x
    pack $tbarright -side left -expand true -fill both

    set tb [ iwidgets::toolbar $tbarright.[ pxvtable::vnewobj ] \
		 -balloondelay1 500 \
		 -balloondelay2 50 \
		 -orient horizontal \
		 -font { helvetica 9 }\
		 -helpvariable guiparams($this,helpVar)\
		 -disabledforeground \#A0A0A0 \
		 -selectcolor \#ff1000  ]

#		 -background black -foreground \#ffffee -disabledforeground \#A0A0A0 
#		 -balloonbackground darkgray 		 -balloonforeground white \

    pack $tb -side top -expand false -fill x 
    eval "$tb add button undo -height 1 -balloonstr \"Undo Delete\" -helpstr \"Undo Delete\"  -command { $this ClipboardOperation undo } -text \"Undo\""
    eval "$tb add button delete -height 1 -balloonstr \"Delete\" -helpstr \"Delete\"  -command { $this ClipboardOperation delete } -text \"Delete\""
    eval "$tb add button cut -height 1 -balloonstr \"Cut\"  -helpstr \"Cut\"  -command { $this ClipboardOperation cut } -text \"Cut\""
    eval "$tb add button paste -height 1 -balloonstr \"Paste\" -helpstr \"Cut\"  -command { $this ClipboardOperation paste } -text \"Paste\""

    lappend readonlybuttonlist [ list $tb undo ]
    lappend readonlybuttonlist [ list $tb delete ]
    lappend readonlybuttonlist [ list $tb cut ]
    lappend readonlybuttonlist [ list $tb paste ]
    lappend readonlybuttonlist [ list $tb edit ]

    $tb add frame spacer2 -borderwidth 1 -width 3 -height 8
    eval "$tb add button edit -height 1 -balloonstr \"Edit Properties\" 	-helpstr \"Edit Properties\"  -command { $this EditNodeProperties } -text \"Edit Node\""
    eval "$tb add button desc -height 1 -balloonstr \"Show Properties\" 	-helpstr \"Print Properties\"  -command { $this PrintCurrentNode } -text \"Print\""
    $tb add frame spacer3 -borderwidth 1 -width 3 -height 8

    eval "$tb add checkbutton ae -text \"Lock\" -variable [ itcl::scope guiparams($this,displayonlymode) ] -command { $this LockEditing } "
    $tb add frame spacer4 -borderwidth 1 -width 3 -height 8

    eval "$tb add checkbutton ag -text \"Lock Space\" -variable [ itcl::scope guiparams($this,lockspaceimage) ] -command { $this LockSpace}"
    

    
    set treeframe [ frame $tbarright.tree ]
    pack $treeframe -side top -expand true -fill both

    $this CreateContextToolbars $tbarleft

    set vistree $treeframe.v

    eval "Tree::create $vistree -bg white -width 170 -yscrollcommand {$treeframe.sb set} -xscrollcommand { $maintab.mid set }"
    eval "scrollbar $treeframe.sb -orient vertical -command { $treeframe.v yview } "
    eval "scrollbar $maintab.mid -orient horizontal -command { $treeframe.v xview } "
    pack $maintab.mid -side bottom -expand false -fill x

    pack $vistree -side left -fill both -expand 1 -padx {4 0} -pady {0 0}
    focus $vistree
    pack $treeframe.sb -side left -fill both -padx {0 3} -pady {0 3}

    pack $tbar -side top -expand true -fill both
    pack $maintab -side top -expand true -fill both
    
    #eval "$vistree bind x <1> { $this SetSelection %W %x %y }"
    eval "bind $vistree <ButtonPress-1> { $this SetSelection %W %x %y }"
    eval "bind $vistree <ButtonPress-3> { $this ShowContextMenu %W %x %y }"

    if { $createtransformcontrol == 1 } {
	set w $xformtab
	set transformation_control [ [ pxitclmultiTransformGUI \#auto  ] GetThisPointer ]
	$transformation_control Initialize $w.b
	$transformation_control AddTransformation "Default"
	eval "$transformation_control configure -callback \"$this UpdateTransformation\""
	$this UpdateTransformation
	pack $w.b -side top -expand false -fill x
    }



    $this CreateContextMenus
    $this LockEditing
    $this LockSpace



$this UpdateVisTree     
    return $basewidget
}





# ---------------------------------------------------------------------------------------------------------------------
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
 
    package require vtkpxcontrib
    package require bis_datamanager


    # Random Testing Code Here

    wm geometry . 1100x600
    frame .bot; pack .bot -side bottom
    set nt [ panedwindow .base -orient horizontal -showhandle 1 \
		 -borderwidth 10 -relief raised -sashwidth 4 -sashpad 4 \
		 -handlesize 5 -handlepad 50  ]
    pack .base -side top -expand true -fill both

    set guibase  [ frame $nt.c  -width 500 ]
    set viewbase  [ frame $nt.v -width 450 ]
    $nt add $guibase -minsize  500
    $nt add $viewbase -minsize 500

    set viewer [ bis_viewer \#auto ]
    $viewer CreateGUI $viewbase

    set alg [ bis_treewidget \#auto ]
    $alg SetBisViewer $viewer
    $alg CreateGUI $guibase 1 0


    if { [ llength $argv ] > 0 } {
	$alg LoadDataTree [ lindex $argv 0 ]
    }


    wm title . "Test Data Tree Widget"
    update idletasks

} 


