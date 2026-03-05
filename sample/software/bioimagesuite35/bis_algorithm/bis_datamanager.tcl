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

package provide bis_datamanager 1.0


if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    lappend auto_path [ file dirname [ info script ]]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] main]
}

package require Itcl
package require struct
package require  pxitclsubjectentry     1.0
package require pxtcluserprefs 1.0
# ----------------------------------------------------------
#
#  Tree like interface for managing data
#
# ----------------------------------------------------------


itcl::class bis_datamanager {

    constructor { } { 
	$this Initialize
    }

    destructor { $this Cleanup }

    # Initialization and Cleanup
    # --------------------------
    protected method Initialize { }
    protected method Cleanup { }
    public method GetThisPointer { } { return $this }

    # Utility
    # ----------------------------------
    public method GetTypeAttributeForObjectType { obj }
    public method GetObjectTypeForTypeAttribute { tp }

    # Basic Interface
    # ---------------
    public method GetRootNode { } { return $rootnode }
    public method FindNode { nodename  } 
    public method FindFirstNodeByAttribute { attname attval } 

    # Import Old Style Data Tree file (.tre) or MSB File (.msb)
    # ---------------------------------------------------------
    protected method ConvertTreeElementToXMLElement { xmltree tcltreenode tcltree { depth 0 } } 
    public method ImportTree { fname }
    public method ImportMSBFile { fname }


    # Tree Maintenance
    # ----------------
    public method RecursiveDeleteChildren { elem }
    protected method RecursiveFixTreeAndAllocatePointers { elem { globalpath "" } }
    public method CleanXML { }
    public method UpdateDisplayAttributes { elem } 
    public method UpdateAttributesByList { elem changedlist  } 

    public method LoadObjectPointers { elem } 
    public method SaveObjectPointers { elem } 
    protected method RecursiveAllocateNewPointersAndCopy { elem }
    protected method CreateUniqueIds { elem }

    # Tree Edit & Paste style
    # -----------------------
    public method CopyElement { elem newparent }
    public method MoveElement { elem newparent }
    public method DeleteElement { elem  }
    public method InsertElement { elem newparent }


    # Load and Save new style XML file
    # --------------------------------
    public method XMLElementToString { elem { n 0 } { savemode 0 } { globalpath "" }  }
    public method LoadXML  { fname }
    public method SaveXML  { fname }
    public method CheckSavedObjects  { { node 0 } { dosave 0 } }

    # Methds to Create Elements and basic utility functions
    #Next Id to ensure that all nodes have unique ids!
    # ------------------------------------------------------
    public method FileNameToRelative { fname globalpath }
    public method FileNameToAbsolute { fname globalpath }
    protected method GetNextId { } 
    protected method CleanString { line } 
    protected method SetUniqueName { elem { title "" } }
    protected method AllocatePointersXMLDataElement { elem }
    public method GetNewXMLDataElement { { ndtype Folder } { title "" } { attlist "" } }
    public method CreateChildElement { parent { ndtype Folder } { title "" } { attlist "" } }


    #Path Issues
    # -----------
    public method GetAncestors { elem }
    public method GetShortestPath { e1 e2 }
    public method GetTransformationList { first last }
    public method GetCombinedTransformation { xformlist }

    # variables
    protected variable rootnode 0
    private variable nextid   0

    # associative array  mapping Chelly field names to attributes
    protected variable treemap
    # list of attributes in rootnode which are global
    protected common globalattributes ""

    # attributes to be set to zero on import/load/save
    protected common attributeszero ""
    # attributes that are pointers and needed to be deleted
    protected common attributepointers ""
    # Filenames of all pointers
    protected common attributepointerfilenames ""
    # list of all attributes
    protected common attributeslist ""
    # boolean attributes
    protected common attributesboolean ""
    # guionly attributes
    protected common attributesgui ""


    # Static Interface
    public method GetAttributesList { } { return $attributeslist }
    public method GetFilenamesList { } { return $attributepointerfilenames }
    public method GetAttributesZeroList { } { return $attributeszero }
    public method GetAttributePointersList { } { return $attributepointers }
    public method GetAttributeBooleanList { } { return $attributesboolean }
    public method GetAttributeGUIList { } { return $attributesgui }
}

# ---------------------------------------------------------------------------------------------------------------------
itcl::body bis_datamanager::Initialize { } {
    # Transformation stuff

    array unset treemap

    set treemap(FromParFilenameSet) "none"
    set treemap(TransFromParFileName) "TransformationFilename"
    set treemap(pxitclTransToParent)  "none"
    set treemap(ToParFilenameSet)   "none"
    set treemap(TransToParFileName)  "InverseTransformationFilename"
    set treemap(pxitclTransFromParent) "none"
    set treemap(IsIdentity) "IsIdentity"

    set treemap(group) "Group"
    set treemap(linecolor) "Linecolor"
    set treemap(icon) "Icon"
    set treemap(type) "Type"
    set treemap(expanded) "Expanded"
    set treemap(notes) "Notes"
    set treemap(FileName) "Filename"
    set treemap(FileLoaded) "none"
    set treemap(title)  "Title"
    set treemap(pxitclobj) "none"

    if { $globalattributes == "" } {
	# Initialize Stuff if needed -- these are common
	set globalattributes { GlobalSubjectProperties GlobalDataTypes GlobalFilename GlobalPath }
	set attributeszero { PointerTransformation PointerInverseTransformation  ObjectLoaded PointerObject VisTreePath }
	set attributepointers { PointerObject PointerTransformation PointerInverseTransformation   }
	set attributepointerfilenames {  Filename TransformationFilename InverseTransformationFilename }
	set attributesboolean {  IsIdentity ObjectLoaded Expanded }
	set attributesgui     {  VisTreePath Linecolor DisplayList }

	set attributeslist { 
	    { Filename "" }
	    { Title "" }
	    { Type Image }
	    { SubType None }
	    { Group 1 }
	    { Notes "" } 
	    { IsIdentity 0 } 
	    { TransformationFilename "" } 
	    { InverseTransformationFilename "" }
	    { Icon ifile }
	    { VisTreePath  0 }
	    { Linecolor red } 
	    { Expanded 0 }
	    { PointerTransformation 0 } 
	    { PointerInverseTransformation 0 } 
	    { ObjectLoaded 0 } 
	    { PointerObject 0 } 
	    { DisplayList 0 }
	}
    }
	
    # -----------------------------------------------
    $this CleanXML


}


itcl::body bis_datamanager::Cleanup { } {
    $this CleanXML
    $rootnode Delete
}

# -----------------------------------------------------------------------
# Creating Elements and utility functions
# -----------------------------------------------------------------------
itcl::body bis_datamanager::GetTypeAttributeForObjectType { objtype } {
 
    while { [string first ":" $objtype  ] == 0 } {
	set objtype [ string range $objtype 1 end ]
    }
   
    switch --  $objtype {
	"pxitclimage" { return "Image" }
	"pxitclsurface"  { return "Surface" }
	"pxitclmesh"  { return "Mesh" }
	"pxitcllandmarks" { return "Landmarks" }
	"pxitclelectrodemultigrid" { return "Electrodes" }
    }

    return 0
}

itcl::body bis_datamanager::GetObjectTypeForTypeAttribute { tp } {

    switch --  $tp {
	"Folder" { return 0 } 
	"Subject" { return 0 }
	"Subject" { return pxitclsurface  }
	"Landmarks" { return pxitcllandmarks }
	"Electrodes" { return  pxitclelectrodemultigrid } 
	"Mesh" { return  pxitclmesh } 
	"Image" { return pxitclimage }
    }
    return 0
}
# -----------------------------------------------------------------------------------------------------
itcl::body bis_datamanager::FileNameToRelative { fname globalpath } {

    if { [ string length $fname ] < 1 } {
	return 0
    }

    if { $fname == "\"0\"" || $fname == "0" || $fname == "" || $fname =="-1" } {
	return "0"
    }


    set f [ file pathtype $fname ]

    if { $f != "absolute" } {
	return $fname
    }

#    puts stderr "Looking at $fname in $globalpath, $f"
	
    set ind [ string first $globalpath $fname ]
    if { $ind >=0 } {
	set n [ expr [ string length $globalpath ] +1 ]
	return [ string range $fname $n end ]
    }

    return $fname
}
# -----------------------------------------------------------------------------------------------------
itcl::body bis_datamanager::FileNameToAbsolute { fname globalpath } {

    if { [ string length $fname ] <1 } {
	return 0
    }

    if { $fname == "\"0\"" || $fname == "0" || $fname == "" || $fname =="-1" } {
	return "0"
    }

    
    set f [ file pathtype $fname ]
    if { $f == "absolute" } {
	return $fname
    }
    set f2 [ file join $globalpath $fname ]
    return $f2
}

itcl::body bis_datamanager::CleanString { line } {
    set line [ string trim $line ]
    regsub -all "\n" $line " " line
    regsub -all "\t" $line " " line
    regsub -all ":" $line "_" line
    regsub -all " +" $line "_" line
    regsub -all "_-_" $line "-" line
    return $line
}

itcl::body bis_datamanager::GetNextId  {  } {
    incr nextid
    return $nextid
}

itcl::body bis_datamanager::SetUniqueName { elem { title "" } } {

    set ttl [ $this CleanString [ $elem GetAttribute Title ] ]
    if { $ttl =="" } {
	set ttl "Node:[ $elem GetAttribute UniqueId]"
    }
    set nd [ $this FindNode $ttl ]
    if { $nd == 0 ||  $nd == $elem  } {
	$elem SetName $ttl
    } else {
	$elem SetName "$ttl:[ $elem GetAttribute UniqueId]"
    }
}

# --------------------------------------------------------
itcl::body bis_datamanager::AllocatePointersXMLDataElement {  element } {

    set ndtype [ $element GetAttribute Type ]
    
    set orig $ndtype
    set subtype "None"

    switch --  $ndtype {
	"Folder" {
	    set lst { { Type "Folder" }	{ Icon "idir" }	{ Linecolor "green" } { IsIdentity "1" } }
	}
	"Subject" {
	    set lst { {  Type "Subject" } { Icon ipersonicon }	{ Linecolor green } { IsIdentity 1 }}
	}
	"Surface" {
	    set lst -1 
	    $element SetAttribute  Type "Surface"
	    $element SetAttribute "PointerObject" [ [ pxitclsurface \#auto ] GetThisPointer ]
	}
	"Mesh" {
	    set lst -1 
	    $element SetAttribute  Type "Mesh"
	    $element SetAttribute "PointerObject" [ [ pxitclmesh \#auto ] GetThisPointer ]
	}
	"Landmarks" {
	    set lst  -1
	    $element SetAttribute Type "Landmarks"
	    $element SetAttribute "PointerObject" [ [ pxitcllandmarks \#auto ] GetThisPointer ]
	}
	"Electrodes" {
	    set lst -1 
	    $element SetAttribute  Type  Electrodes
	    $element SetAttribute "PointerObject" [ [ pxitclelectrodemultigrid \#auto ] GetThisPointer ]
	}
	default {
	    $element SetAttribute Type Image
	    $element SetAttribute SubType $subtype
	    $element SetAttribute "PointerObject" [ [ pxitclimage \#auto ] GetThisPointer ]
	    $element SetAttribute "PointerTransformation" [ [ pxitcltransform \#auto ] GetThisPointer ]
	    $element SetAttribute "PointerInverseTransformation" [ [ pxitcltransform \#auto ] GetThisPointer ]
	    set lst {  { Icon ibraingrey } { Linecolor red }  }
	}
    }
    
    if { $lst == -1 } {
	set lst {  { Icon ibraingrey } { Linecolor green } { IsIdentity 1 } { TransformationFilename "" } { InverseTransformationFilename "" } } 
    }

    foreach pair $lst {
	set attr [ lindex $pair 0 ]
	set val  [ lindex $pair 1 ]
	$element SetAttribute $attr $val
    }

    # Set name #1 -- this should be the place 

    return 1
}
# ----------------------------------------------------------------------------------------------
itcl::body bis_datamanager::GetNewXMLDataElement { { ndtype Folder } { title "" } { attlist "" } } {

    set element [ vtkXMLDataElement New ]

    # 1. Set Defaults first
    set num [ llength attributeslist ]
    foreach pair $attributeslist {
	set attr [ lindex $pair 0 ]
	set val  [ lindex $pair 1 ]
	$element SetAttribute $attr $val
    }
    
    # 2. Set ID
    $element SetAttribute UniqueId  [ $this GetNextId ]

    # 3. Set Type and allocate pointers
    $element SetAttribute Type $ndtype
    $this AllocatePointersXMLDataElement $element

    # 4. Set Title if specified as option
    if { $title != "" } {
	$element SetAttribute Title $title
    }

    # 5. Set Attributes as specified in attlist
    set n [ expr [ llength $attlist ] -1 ]
    if { $n > 0 } {
	for { set i 0 } { $i < $n } { set i [ expr $i+2 ] } {
	    set ip [ expr $i + 1 ]
	    set attname [ lindex $attlist $i ]
	    set attvalue [ lindex $attlist $ip ]
	    $element SetAttribute $attname $attvalue
	}
    }

    # 6. Give this a unique name
    $this SetUniqueName $element

    # 7. Done
    return $element
}
# ----------------------------------------------------------------------------------------------------------
itcl::body bis_datamanager::CreateChildElement { parent { ndtype Folder } { title "" } { attlist "" } } {

    if { $parent == 0 || $parent == "" } {
	return 0
    }
    set elem [ $this GetNewXMLDataElement $ndtype $title $attlist ]
    if { $elem !=0  } {
	$parent AddNestedElement $elem
    }
    return $elem
}


# ----------------------------------------------------------------------------------------------------------
#
#   Traversing tree ancestors/lists etc
#
# ----------------------------------------------------------------------------------------------------------

itcl::body bis_datamanager::GetAncestors { elem }  {

    if { $elem == "" } {
	#	puts stderr "Empty!"
	return ""
    }

    if { $elem == $rootnode } {
	return "[ $rootnode GetName ]"
    }

    set done 0
    set ancestors [ $elem GetName ]
    while { $done == 0 } {
	set e [ $elem GetParent ]
	lappend ancestors [ $e GetName ] 
	set elem $e
	if { $e == $rootnode } {
	     set done 1
	} 
    }
    return $ancestors
}

# -----------------------------------------------------------------------------

itcl::body bis_datamanager::GetShortestPath { e1 e2 } {

    # e1 = ref
    # e2 = trg

    set trglist [ $this GetAncestors $e2 ]
    set reflist [ $this GetAncestors $e1 ]

    if { $e1 == $e2 } {
	return [ list 1 1 ]
    }
    
    set lst1 ""
    set i 0
    set found  0
    set f1 ""
    set f2 ""

    while { $i < [ llength $trglist ] && $found == 0 } {

	set ind [ lsearch -exact $reflist [ lindex $trglist $i ] ]
	#	puts stderr "Looking for [ lindex $trglist $i ] in *** $reflist *** \t\t index = $ind"
	if { $ind >=0 } {
	    set found 1
	    set f1 [ lrange $trglist 0 $i ]
	    set f2 [ lrange $reflist 0 $ind ]
	}
	incr i
    }
    
    if { $found == 0 } {
	return [ list 0 0 ]
    }
    
    set f3 ""
    for { set i 0 } { $i < [ llength $f1 ] } { incr i } {
	set ind [ expr ([ llength $f1 ]-1) - $i ]
	lappend f3 [ lindex $f1 $ind ]
    }
    return [ list $f2 $f3 ]
}

# ---------------------------------------------------------------------------------
itcl::body bis_datamanager::GetTransformationList { first last } {

#    puts stderr "first=$first, last=$last"

    set p [ $this GetShortestPath $first $last ]

    set t(1) [ lindex $p 0 ]
    set t(2) [ lindex $p 1 ]
    set m(1) "Inverse"
    set m(2) "Forward"

    set tlist ""
    set tnamelist ""
    for { set pass 1 } { $pass <= 2 } { incr pass } {
	for { set i 0 } { $i < [ expr [ llength $t($pass)]  -1 ] } { incr i } {
	    
	    set e1 [ lindex $t($pass) $i ]
	    set e2 [ lindex $t($pass) [ expr $i +1 ]]
#	    puts stderr "\n\n ************************ $m($pass) $e1 --> $e2"


	    if { $pass == 2 } {
		set mode "transformation"
		set currentelement [ $this FindNode $e2 ]
	    } else {
		set mode "inverse transformation"
		set currentelement [ $this FindNode $e1 ]
	    }
	    
	    if { $currentelement ==0 } {
		return "Failed :: missing node in pair ($e1,$e2)"
	    }

	    if { [ $currentelement GetAttribute IsIdentity ] != 1 } {
#		puts stderr "Needs to load $currentelement [ $currentelement GetName ], $mode"
		if {  [ $currentelement GetAttribute ObjectLoaded ] != 1 } {
		    set ok [ $this LoadObjectPointers $currentelement  ]
		    if { [ lindex $ok 0 ] == 0 } {
			return "Failed :: $ok"
		    }
		}
		    
		if { $pass == 2 } {
		    set fname  [ $currentelement GetAttribute TransformationFilename ]
		    if {  $fname == 0 || $fname == "-1" || $fname == ""  } {
			return "Failed :: missing transformation in [ $currentelement GetName ]"
		    }
		    set tr [ $currentelement GetAttribute PointerTransformation ]
		} else {
		    set fname  [ $currentelement GetAttribute InverseTransformationFilename ]
		    if {  $fname == 0 || $fname == "-1" || $fname == ""  } {
			return "Failed :: missing inverse transformation in [ $currentelement GetName ]"
		    }
		    set tr [ $currentelement GetAttribute PointerInverseTransformation ]
		}
		lappend tlist $tr
		lappend tnamelist [ $tr cget -filename ]
	    } else {
#		puts stderr "[$currentelement GetName ] Is Identity ... skipping"
	    }
	    
	}
    }

    set lst [ list  $first $last ]
    foreach nodename $lst {
	if {  [ $nodename GetAttribute ObjectLoaded ] != 1 } {
	    set ok [ $this LoadObjectPointers $nodename  ]
	    if { [ lindex $ok 0 ] == 0 } {
		return "Failed :: loading node [ $nodename GetName ] $ok"
	    }
	}
    }
#    puts stderr "tnamelist=$tnamelist"
    return $tlist
}
# ----------------------------------------------------------------------------------------

itcl::body bis_datamanager::GetCombinedTransformation { xformlist } {

    # step 1 ... are they linear

    if { [ llength $xformlist ] == 0  } {
	return [ vtkIdentityTransform New ]
    }

    set alllinear 1

    foreach tr $xformlist { 
	if { [ $tr IsLinear ] ==0 } {
	    set alllinear 0
	}
    }

    if { $alllinear == 1 } {
	set gen [ vtkTransform New ]
    } else {
	set gen [ vtkGeneralTransform New ]
    }
    $gen Identity
    $gen PostMultiply

    for { set i 0 } { $i < [ llength $xformlist ]} { incr i } {
	$gen Concatenate [ [ lindex $xformlist $i ] GetTransformation ]
    }
    return $gen
}

# ----------------------------------------------------------------------------------------------
#  Find Node
# ----------------------------------------------------------------------------------------------
itcl::body bis_datamanager::FindNode {  nodename } {

    if { $rootnode == 0 } {
	return 0
    }
    
    if { $nodename == [ $rootnode GetName ] } {
#	puts stderr "Nodename is rootname"
	return $nodename
    }

    set elem [ $rootnode LookupElementWithName $nodename ]
    if { $elem == $rootnode } {
	puts stderr "Bad Search ... "
	return 0
    }
    if { $elem != ""  && $elem !=0 } {
	#	puts stderr "Found $nodename, $elem"
	return $elem
    }

    return 0
}
# --------------------------------------------------------
itcl::body bis_datamanager::FindFirstNodeByAttribute { attname attval } {

    set currentlist $rootnode 
    set done 0
    set error 0

    while { $done == 0 } {

	#	puts  -nonewline stderr "Examining {"
	#	for { set i 0 } { $i < [ llength $currentlist ] } { incr i } {
	#	    puts -nonewline stderr " [ [ lindex $currentlist $i ] GetName ]"
	#	}
	#	puts stderr "}"
	
	for { set i 0 } { $i < [ llength $currentlist ] } { incr i } {
	    set nd [ lindex $currentlist $i ]
	    set val [ $nd GetAttribute $attname ]
	    if { $val == $attval } {
		return $nd
	    }
	}

	set newlist ""
	set done 1
	for { set i 0 } { $i < [ llength $currentlist ] } { incr i } {
	    set elem [ lindex $currentlist $i ]
	    for { set j 0 } { $j < [ $elem GetNumberOfNestedElements ] } { incr j } {
		lappend newlist [ $elem GetNestedElement $j ]
		# At least one element found
		set done 0 
	    }
	}
	set currentlist $newlist
    }
    
    return 0
}
# --------------------------------------------------------
# Updates from GUI/Updates
# --------------------------------------------------------
itcl::body bis_datamanager::UpdateAttributesByList { elem changedlist }  {

#    puts stderr "The following has changed = $changedlist"
    if {  [ lsearch -exact $changedlist "Title" ] > -1 } {
	set ttl [ $this CleanString [ $elem GetAttribute Title ] ]
	regsub -all "\"" $ttl "" ttl
	$elem SetAttribute Title $ttl
	puts -nonewline stderr "Changing the name of $elem from [ $elem GetName ] to "
	$this SetUniqueName $elem
	puts stderr "\t\t [ $elem GetName ]"
	
    }

    if {  [ lsearch -exact $changedlist IsIdentity ] > -1 } {
#	puts stderr "IsIdentity Changed!"
	if { [ $elem GetAttribute "IsIdentity"  ] == 1 } {
	    $elem SetAttribute Icon ibraingreen
	} else {
	    set fn [  $elem GetAttribute Filename ]
	    if {  $fn != "" && $fn !=0 } {
		$elem SetAttribute Icon ibrainpurple
	    } else {
		$elem SetAttribute Icon ibraingrey
	    }
	}
    }

    set fn    [ $this  GetFilenamesList ]
    set ptrs  [ $this GetAttributePointersList ]

    # Filenames done !
    for { set i 0 } { $i < [ llength $fn ] } { incr i } {
	set p $elem
	if {  [ lsearch -exact $changedlist [ lindex $fn $i ] ] > -1 } {
	    puts stderr "[ lindex $fn $i ] Changed !"
	    
	    set obj   [ $p GetAttribute [ lindex $ptrs $i ] ]
	    set fname [ $p GetAttribute [ lindex $fn $i ] ]
	    set fold  [ $obj cget -filename ]
	    if { $fname != $fold } {
		$obj Clear
		$obj configure -filename $fname
		if { $i == 0 } {
		    $elem SetAttribute ObjectLoaded 0
		}
	    }
	}
    }
	  
}

# -------------------------------------------------------------------------------


itcl::body bis_datamanager::UpdateDisplayAttributes { elem }  {

    set ndtype [ $elem GetAttribute Type ]
    #    puts stderr "Updating display attributes [ $elem GetName ] $ndtype"

    if { $ndtype == "Folder" || $ndtype == "Subject" } {
	return 0
    }

    if {  $ndtype == "Image" } {
	
	# Step 1 check for transformations!
	if { [ $elem GetAttribute IsIdentity ] !=1 } {
	    set t(1) [ $elem GetAttribute  TransformationFilename ]
	    set t(2) [ $elem GetAttribute  InverseTransformationFilename ]
	    set ok(1) 1
	    set ok(2) 1

	    if { [ file extension $t(1) ] == ".matr" } {
		set t(2) "$t(1).donotsave"
		$elem SetAttribute  InverseTransformationFilename $t(2)
	    } else {
		for { set i 1 } { $i<=2 } { incr i } {
		    if { $t($i) ==0 || $t($i) == -1 || $t($i) == "" } {
			set ok($i) 0
		    } 
		}
	    }
	    
	    if { $ok(1) == 1 && $ok(2) == 1 } {
		$elem SetAttribute Linecolor green
	    } elseif { $ok(1) == 1 && $ok(2) == 0 } {
		$elem SetAttribute Linecolor goldenrod
	    } elseif { $ok(1) == 0 && $ok(2) == 1  } {
		$elem SetAttribute Linecolor purple
	    } else {
		$elem SetAttribute Linecolor red
	    }
	} else {
	    $elem SetAttribute  TransformationFilename 0
	    $elem SetAttribute  InverseTransformationFilename 0
	    $elem SetAttribute Linecolor green
	    $elem SetAttribute Icon iarrowbrain
	}
	
	# Step 2 check if loaded
	set img [ $elem GetAttribute PointerObject ]
	set d [ $img GetImageSize ]
	if { $d > 1 } {
	    $elem SetAttribute ObjectLoaded 1
	} else {
	    $elem SetAttribute ObjectLoaded 0

	} 

	set fn [  $elem GetAttribute Filename ]
	if {  $fn != "" && $fn !=0 } {
	    $elem SetAttribute Icon ibrainpurple
	} else {
	    $elem SetAttribute Icon ibraingrey
	}

	if { [ $elem GetAttribute "IsIdentity"  ] == 1 } {
	    $elem SetAttribute Icon ibraingreen
	}

	return 1
    }

    if { $ndtype == "Surface" || $ndtype == "Landmarks" || $ndtype == "Electrodes" || $ndtype == "Mesh"} {
	set obj [ $elem GetAttribute PointerObject ]
	set d -1
	if { $ndtype == "Surface" } {
	    set d [ $obj GetSurfaceSize ]
	} elseif { $ndtype == "Landmarks" } {
	    set d [ $obj GetLandmarksSize ]
	} elseif { $ndtype == "Mesh" } {
	    set d [ $obj GetMeshSize ]
	} elseif { $ndtype == "Electrodes" } {
	    set d [ $obj GetElectrodeMultiGridSize ]
	}
	if { $d > 0 } {
	    $elem SetAttribute FileLoaded 1
	} elseif { $d !=-1 } {
	    $elem SetAttribute FileLoaded 0
	} 

	set fn [  $elem GetAttribute Filename ]
	if {  $fn != "" && $fn !=0 } {
	    $elem SetAttribute Icon ibrainyellow
	} else {
	    $elem SetAttribute Icon ibraingrey
	}

    }
}
# --------------------------------------------------------
itcl::body bis_datamanager::LoadObjectPointers { elem } {

    #set attributepointers { PointerObject PointerTransformation PointerInverseTransformation   }
    #set attributepointerfilenames {  Filename TransformationFilename InverseTransformationFilename }

    set maxno [ llength $attributepointers ]
    set ndtype [ $elem GetAttribute Type ]
    if { $ndtype == "Folder" || $ndtype == "Subject" } {
	return 1
    } elseif { $ndtype != "Image" } {
	set maxno 1
    } 

#    puts stderr "maxno=$maxno"
    
    set err ""
    set i 0
    while { $i < $maxno && $err == "" } {
	set fname [ $elem GetAttribute [ lindex $attributepointerfilenames  $i ] ]
	#	puts stderr "To load $fname"
	set ext [ file extension $fname ]
	set doload 1
	if { $ext == ".donotsave" || $fname == 0 || $fname == "-1" || $fname == "" } {
	    set doload 0
	}
	
	if { $doload } {
	    set obj [ $elem GetAttribute [ lindex $attributepointers $i ] ]
	    if { $i == 0 } {
		#		puts stderr "To load $fname in $obj"
		set ok [ $obj Load $fname ]
		if { $ok == 0 } {
		    set err "Failed to load [ lindex $attributepointers $i ] from $fname" 
		    $obj Clear
		} else {
		    #		    puts stderr "Ok=$ok loaded $fname in $obj"
		    $elem SetAttribute ObjectLoaded 1
		}
	    } else {
		if { $obj == 0 } {
		    set obj [ [  pxitcltransform \#auto ] GetThisPointer ]
		}
		set ok [ $obj Load $fname ]
		if { $ok > 0 } {
		    $elem SetAttribute [ lindex $attributepointers $i ] $obj
		} else {
		    $elem SetAttribute [ lindex $attributepointerfilenames  $i ] ""
		    set err "Failed to load [ lindex $attributepointers $i ] from $fname" 
		    $obj Clear
		}
	    }
	}
	
	if { $i == 1 && $err == "" } {
	    set tr1 [ $elem GetAttribute [ lindex $attributepointers 1 ]]
	    set tr2 [ $elem GetAttribute [ lindex $attributepointers 2 ]]
	    if { [ $tr1 IsLinear ] > 0 } {
		if { $tr2 == 0 } {
		    set tr2 [ [  pxitcltransform \#auto ] GetThisPointer ]
		}
		$tr2 Copy $tr1
		$tr2 Invert
		$tr2 configure -filename "[ $tr1 cget -filename].donotsave"
		$elem SetAttribute [ lindex $attributepointers 2 ] $tr2
		set i 4
	    }
	}
	incr i
    }

    if { $err == "" } {
	$this UpdateDisplayAttributes $elem
	return 1
    }
		     
    return [ list 0 $err ]
}
# --------------------------------------------------------
itcl::body bis_datamanager::SaveObjectPointers { elem }  {
    #set attributepointers { PointerObject PointerTransformation PointerInverseTransformation   }
    #set attributepointerfilenames {  Filename TransformationFilename InverseTransformationFilename }

    set maxno [ llength $attributepointers ]
    set ndtype [ $elem GetAttribute Type ]
    if { $ndtype == "Folder" || $ndtype == "Subject" } {
	return 1
    } elseif { $ndtype != "Image" } {
	set maxno 1
    } 

    set err ""

    while { $i < $maxno && $err == "" } {
	set fname [ $elem GetAttribute [ lindex $attributepointerfilenames  $i ] ]
	set obj [ $elem GetAttribute [ lindex $attributepointers $i ] ]
	if { $obj != 0  } {
	    set ext [ file extension $fname ]
	    set dosave 1
	    if { $ext != ".donotsave" && [ string length $fname ] > 2 } {
		set ok [ $obj Save $fname ]
		if { $ok == 0 } {
		    set err "Failed to save [ lindex $attributepointers $i ] from $fname" 
		}
	    }
	}else {
	    set err "Failed to save [ lindex $attributepointers $i ], bad pointer" 
	}
	incr i
    }

    if { $err == "" } {
	$this UpdateDisplayAttributes
	return 1
    }
		     
    return { 0 $err }
}
# --------------------------------------------------------
#  Importing Other Formats .tre and .msb
# --------------------------------------------------------
itcl::body bis_datamanager::ConvertTreeElementToXMLElement { xmltree tcltreenode tcltree { depth 0 } } {

    set offset ""
    for { set i 0 } { $i < $depth } { incr i } {
	set offset "${offset}\t"
    }
    set n ""
    catch { set n  [ $tcltree get $tcltreenode $name  ] }

#    puts stderr "$offset Starting ConvertTreeElementToXMLElement $tcltreenode ($n) ***************************\n"

    set lst [ array names treemap ]
    for { set i 0 } { $i < [ llength $lst ] } { incr i } {
	set name [ lindex $lst $i ]
	set val 0
	catch { set val  [ $tcltree get $tcltreenode $name  ] }
	set attname $treemap($name)
	if { $name == "type" } {


	    if { $val == -1 || $val == 0 } {
		$xmltree SetAttribute Type "Image"
	    } elseif { $val == "Patient" } {
		$xmltree SetAttribute Type "Subject"
	    } elseif { $val == "Folder" } {
		$xmltree SetAttribute Type "Folder"
	    } elseif { $val == "Surface Surface" } {
		$xmltree SetAttribute Type "Surface"
	    } elseif { $val == "Surface Landmark" } {
		$xmltree SetAttribute Type "Landmarks"
	    } elseif { $val == "Surface Electrode" }  {
		$xmltree SetAttribute Type "Electrodes" 
	    } else {
		$xmltree SetAttribute Type "Image"
		set outname "None"
		array set dtypes [ $rootnode GetAttribute GlobalDataTypes ]
		catch { set outname $dtypes($val) }
		$xmltree SetAttribute SubType "$outname"
	    }
	} elseif { $attname != "none" } {
	    $xmltree SetAttribute $attname  [ CleanString $val  ]
	}
    }

    set name ""
    set keys [ $tcltree keys $tcltreenode ]
    catch { set name  [ $tcltree get $tcltreenode title  ] }
    if { $name == "" } {
	set name "Folder"
    }

    if { $xmltree != $rootnode } { 
	set nm [ CleanString $name ]
	$this SetUniqueName $xmltree $nm
    }

    foreach attr $attributeszero { 
	$xmltree SetAttribute $attr 0
    }
    
    set par [ $xmltree GetParent ]
    if { $par == "" || $par == 0 } {
	set nm ""
    } else {
	set nm "<-- [ $par GetName ]"
    }

    # -------------------------------------------------------------------------------------------------------
    #    puts stderr "$offset Added Element [$xmltree GetName ], [ $xmltree GetAttribute Filename ] to $nm"
    # -------------------------------------------------------------------------------------------------------

    set children  [ $tcltree children $tcltreenode ]
    if { [ llength $children ] > 0 } {
	for { set j 0 } { $j < [ llength $children ] } { incr j } {
	    set child [ lindex $children $j ]
	    set newxml [ $this GetNewXMLDataElement ]
	    $xmltree AddNestedElement $newxml
	    $this ConvertTreeElementToXMLElement $newxml $child $tcltree  [ expr $depth +1 ]
	}
    } 
}

# ---------------------------------------------------------------------------------------------------------------------
itcl::body bis_datamanager::ImportTree { fname } { 

    if { [ file readable $fname ]  == 0 } {
	return 0
    }

    set fileid [open $fname r]
    gets $fileid line
    
    if { [ string compare $line "#Chelly's Datatree File Format" ] != 0 } {
	puts stderr " File is not in Datatree File Format "
	close $fileid
	return 0
    }
	
    while { [ gets $fileid line ] >=0 } {
	set index [string first ":" $line]
	
	if { $index > 0 }  {
	    set len   [string length $line]
	    
	    set key   [string trim   [string range $line 0 [expr $index - 1]]]
	    set value [string trim [string range $line [expr $index +1] [expr $len -1]]]
	    set newtree($key)  $value 
#	    puts stderr "Importing $key $value"
	}
    }  
    close $fileid
	
    #Throw a key into the array to tag its type
    set newtree(ChellysTreeFormat) 1
    set newtree(ThisFileName) $fname
    set newlist [ array get newtree ]

    set patientprops $newtree(PatientProps)
    set typedefarray $newtree(TypeDefArray)

    array set TreeDefArray $newlist

    set mytree [ ::struct::tree [ pxvtable::vnewobj ] deserialize $TreeDefArray(serialized)  ]
    set treeelement [ $mytree rootname ]
    
    foreach node [ $mytree children -all $treeelement ] {
		
	#set the notes for the node
	$mytree set $node notes [string map {{\n} \n} $TreeDefArray($node,notes)]
		
	#--------------------------------------------------
	#Set the filenames if they are saved
	#--------------------------------------------------
	if { $TreeDefArray($node,filename) != -1 } {
	    $mytree set $node FileName $TreeDefArray($node,filename)
	}
	if { $TreeDefArray($node,transtoparfilename) != -1 } {
	    $mytree set $node TransToParFileName $TreeDefArray($node,transtoparfilename)
	}
	if { $TreeDefArray($node,transfromparfilename) != -1 } {
	    $mytree set $node TransFromParFileName $TreeDefArray($node,transfromparfilename)
	}
    }

    # ---------------------------------------------------
    
    # ---------------------------------------------------

#    puts stderr "Serialized ............. [ $mytree serialize [ $mytree rootname ]]"

    #    puts stderr "OK -- Heading out to XML $nextid ----------------------------\n"
    $this CleanXML


    
    #    set xml2 [ vtkXMLDataElement New ]
    #    $rootnode AddNestedElement $xml2

    #    puts stderr "Begin importing tree \n\n"
    $this ConvertTreeElementToXMLElement $rootnode $treeelement $mytree

    #    puts stderr "\n\n\n Done Importing \n\n\n\n\n"

    $rootnode SetName "BioImageSuite_DataTree"
    $rootnode SetAttribute Title "BioImageSuite_DataTree"
    $rootnode SetAttribute "Type" "Folder"
    $rootnode SetAttribute "Icon" "idir"
    $rootnode SetAttribute "Linecolor"  green
    $rootnode SetAttribute "IsIdentity"  1
    $rootnode SetAttribute "Expanded"  1
    $rootnode SetAttribute GlobalSubjectProperties $patientprops
    $rootnode SetAttribute GlobalDataTypes $typedefarray
    $rootnode SetAttribute GlobalFilename [ file normalize $fname ]
    $rootnode SetAttribute GlobalPath    [ file dirname  [ file normalize $fname ] ]

    $this RecursiveFixTreeAndAllocatePointers $rootnode [ $rootnode GetAttribute GlobalPath ]
    return 1
}

# ------------------------------------------------------------------
# Importing MSB File
# ---------------------------------------------------------------------------------------------------------------------
itcl::body bis_datamanager::ImportMSBFile { fname } { 

    if { [ file readable $fname ] == 0 } {
	puts stderr "Failed to read $fname"
	return 0
    }

    set fileid [open $fname r]
	
    gets $fileid line

    set setupmode 0

    if { [ string compare $line "#Multisubject Description File"  ] != 0 } {
	if { [ string compare $line "#Multisubject Description File v2"  ] != 0 } {
	    if { [ string compare $line "#Multisubject Description File v3"  ] != 0 } {
		close $fileid
		puts stderr "Cannot read setupfile file from $fname\n Bad File Type"
		return 0
	    } else {
		set setupmode 2
	    }
	} else {
	    set setupmode 1
	}
    }

    #    puts stderr "Setupmode =$setupmode"

    gets $fileid line ;     gets $fileid line  ;     set numtasks $line ;    gets $fileid line 

    set tasklist ""

    for { set i 0 } { $i < $numtasks } { incr i } {
	set tmp [ [ pxitcltask \#auto ]  GetThisPointer ]
	lappend tasklist $tmp
	$tmp LoadFromSetupFile $fileid
    }


    gets $fileid line ;     gets $fileid line  ;     set numsub $line ;    gets $fileid line 

    set subjectlist ""

    for { set i 0 } { $i < $numsub } { incr i } {
	set tmp [ [ pxitclsubject \#auto ]  GetThisPointer ]
	lappend subjectlist $tmp
	$tmp LoadFromSetupFile $fileid $setupmode
    }

    gets $fileid line ; gets $fileid line 

    # Do the Reference Separately
    set refname [ pxitclsubject::GetFileElement $fileid ]
    # Next do the VOI Control
    if { $setupmode == 2 } {
	set voiname [ pxitclsubject::GetFileElement $fileid ]
    } else {
	set voiname ""
    }
    
    set output_list [ list "Average Anatomical" "Std Anatomical" "Average Functional" "Std Functional" "Tscore Functional" ]

    for { set i 0 } { $i < [ llength $output_list ] } { incr i } {
	set resname($i) [ pxitclsubject::GetFileElement $fileid ]
    }

    #    puts stderr "OK -- Heading out to XML $nextid ----------------------------\n"
    $this CleanXML
    # ---------------------------------------------------------------------------------
    $rootnode SetName "BioImageSuite_DataTree"
    $rootnode SetAttribute Title "BioImageSuite_DataTree"
    $rootnode SetAttribute "Type" "Folder"
    $rootnode SetAttribute "Icon" "idir"
    $rootnode SetAttribute "Linecolor"  green
    $rootnode SetAttribute "IsIdentity"  1
    $rootnode SetAttribute "Expanded"  1
    $rootnode SetAttribute GlobalSubjectProperties "MSB File"
    $rootnode SetAttribute GlobalDataTypes ""
    $rootnode SetAttribute GlobalFilename [ file normalize $fname ]
    $rootnode SetAttribute GlobalPath    [ file dirname  [ file normalize $fname ] ]


    set ref [ eval "$this CreateChildElement $rootnode Image Reference_Image { Filename $refname } " ]
    set refdata [ $this CreateChildElement $ref Folder  A_Reference_Data {  Expanded "1" } ]
    set subjectdata [ $this CreateChildElement $ref Folder B_Subject_Data {  Expanded "1"  IsIdentity 1 } ]
    eval "$this CreateChildElement $refdata Image  VOI_Image { Filename \"$voiname\" IsIdentity  1 }"


    for { set i 0 } { $i < [ llength $subjectlist ] } { incr i } {
	
	set ind [ expr $i + 1 ]
	set sname "S$ind-"
	set pt [ lindex $subjectlist $i ]
	set subj [ $this CreateChildElement  $subjectdata "Subject" "${sname}[ $this CleanString [ $pt GetBaseName ] ]" { IsIdentity 1 } ]
#	puts stderr "Added Subject $i [ $subj GetAttribute Title ]"
	

	set aname [ [ $pt cget -anatomical_image ] cget -filename ]
	set xname [ [ $pt cget -reference_transform ] cget -filename ]
	set cname [ [ $pt cget -conventional_image ] cget -filename ]
	set iname [ [ $pt cget -internal_transform ] cget -filename ]
	set ename [ [ $pt cget -echoplanar_image ] cget -filename ]
	set dname [ [ $pt cget -distortion_transform ] cget -filename ]
#	puts stderr "images = ($aname,$cname,$ename)\n, xforms=($xname,$iname,$dname)"


	set anat [ eval "$this CreateChildElement $subj Image \"${sname}3D_Anatomical_Image\" { Filename \"$aname\"   TransformationFilename \"$xname\" }" ]
	set conv [ eval "$this CreateChildElement $anat Image \"${sname}Conventional_Image\" { Filename \"$cname\"  TransformationFilename \"$iname\" }" ]
	set epi [ eval "$this CreateChildElement $conv Image  \"${sname}Echoplanar_Image\" { Filename \"$ename\"  TransformationFilename \"$dname\" } " ]
	set func [ $this CreateChildElement $epi "Folder" "${sname}Functional_Data" ]
	set fname [ [ $pt cget -functional_image ] cget -filename  ]
	set oldfname $fname
	set oldsuffix ""

	for { set j 0 } { $j < [ llength $tasklist ] } { incr j } {
	    set task [ lindex $tasklist $j ]
	    set tname   [ $task cget -task_name ]
	    set tsuffix [ $task cget -task_suffix ]

	    set ttsname "T[ expr $j +1 ]-"
	    
	    if { $oldsuffix != "" } {
		set ind [ string last $oldsuffix $fname ]
		if { $ind >=0 } {
		    regsub -start $ind $oldsuffix $fname $tsuffix fname
		}
	    }
	    set oldsuffix $tsuffix
	    set t [ $this CreateChildElement $func Image "${sname}${ttsname}[ $this CleanString $tname]" ]
	    $t SetAttribute Filename $fname
	    $t SetAttribute IsIdentity 1

	    
	}
    }

    set n 0
    for { set i 0 } { $i < 5 } { incr i } {
	set n [ expr $n + [ string length $resname($i) ] ]
    }

    if { $n > 0 } {
	set results [ $this CreateChildElement $ref "Folder"  C_Results { IsIdentity 1  Expanded "1" } ]
	
	if { [ string length $resname(0) ] > 0 || [ string length $resname(1) ] > 0 } {
	    set func [ $this CreateChildElement $results "Folder" "Anatomical_Images"  ]
	    eval "$this CreateChildElement $func Image  Average_Anatomical_Image {  Filename \"$resname(0)\"   IsIdentity 1 } "
	    eval "$this CreateChildElement $func Image  Stdev_Anatomical_Image   { Filename \"$resname(1)\"   IsIdentity 1 } "
	}
	
	set tfname(0) $resname(2)
	set tfname(1) $resname(3)
	set tfname(2) $resname(4)
	
	set tn 0
	for { set i 0 } { $i < 3 } { incr i } {
	    set tn [ expr $tn + [ string length $tfname($i) ] ]
	}
	
	if { $tn > 0 } {
	    
	    set tflist { "Average_Functional" "Std_Functional" "Tscore_Functional" }
	    set oldsuffix ""
	    
	    
	    for { set j 0 } { $j < [ llength $tasklist ] } { incr j } {
		set task [ lindex $tasklist $j ]
		set tname   [ $task cget -task_name ]
		set tsuffix [ $task cget -task_suffix ]
		
		if { $oldsuffix != "" } {
		    set ind [ string last $oldsuffix $fname ]
		    if { $ind >=0 } {
			for { set k 0 } { $k <=2 } { incr k } {
			    regsub -start $ind $oldsuffix $tfname($k) $tsuffix tfname($k)
			}
		    }
		}
		set oldsuffix $tsuffix
		set ttsname "T[ expr $j +1 ]-"	
		set funcdir [ eval "$this CreateChildElement $results Folder [ $this CleanString \"${ttsname}Results_$tname\" ] " ]
		for { set k 0 } { $k<=2 } { incr k } {
		    eval " $this CreateChildElement $funcdir Image [ $this CleanString \"${ttsname}[ lindex $tflist $k ]_$tname\" ] {  Filename \"$tfname($k)\"  IsIdentity 1 } "
		}
	    }
	}
    }
    # This is the critical command
    # unique names, allocate pointers, fixes icons/colors .....
    $this RecursiveFixTreeAndAllocatePointers $rootnode [ $rootnode GetAttribute GlobalPath ]
    return 1
}

# ------------------------------------------------------------------
itcl::body bis_datamanager::RecursiveFixTreeAndAllocatePointers { elem { globalpath "" } } {

    for { set j 0 } { $j < [ $elem GetNumberOfNestedElements ] } { incr j } {
	set e [ $elem GetNestedElement $j ]
	$this RecursiveFixTreeAndAllocatePointers $e $globalpath
    }


    if { $elem == $rootnode } {
	return 1
    }

    $this AllocatePointersXMLDataElement $elem 
    $this SetUniqueName $elem

    foreach attr $attributepointerfilenames {
	set in [ $elem GetAttribute $attr ]
	set f [ $this FileNameToAbsolute $in $globalpath ]
	if { $in != $f }  {
	    $elem SetAttribute $attr $f
	}
    }
    $this UpdateDisplayAttributes $elem

    return 1
}

itcl::body bis_datamanager::RecursiveDeleteChildren { elem } {

    for { set j 0 } { $j < [ $elem GetNumberOfNestedElements ] } { incr j } {
	set e [ $elem GetNestedElement $j ]
	$this RecursiveDeleteChildren $e
	$elem RemoveNestedElement $e
	#	$e Delete
    }

    foreach nm $attributepointers { 
	set ptr [ $elem GetAttribute $nm ]
	if { $ptr !=0 &&  $ptr != "" } {
	    #	    puts stderr "Deleting children"
	    itcl::delete obj $ptr
	} 
    }
}
# -----------------------------------------------------------------------
# Load & Save Issues
# -----------------------------------------------------------------------

itcl::body bis_datamanager::CleanXML  {  } {

    if { $rootnode !=0 } {
	$this RecursiveDeleteChildren $rootnode
    } else {
	set rootnode [ $this GetNewXMLDataElement "Folder" ]
    }

    #    puts stderr "Adding Root node [ $rootnode GetAttribute UniqueId ]"
    $rootnode SetName "BioImageSuite_DataTree"
    $rootnode SetAttribute "Type" "Folder"
    $rootnode SetAttribute "Icon" "idir"
    $rootnode SetAttribute "Linecolor"  green
    $rootnode SetAttribute "IsIdentity"  1
    $rootnode SetAttribute "Expanded"  1
}
# ------------------------------------------------------------------
itcl::body bis_datamanager::CheckSavedObjects {  { node 0 } { dosave 0 } } {

    if { $node == 0 } {
	set node [ $this GetRootNode ]
    }

    puts stderr "Checking [ $node GetName ]"
    set lst ""
    for { set j 0 } { $j < [ $node GetNumberOfNestedElements ] } { incr j } {
	set a [ $this CheckSavedObjects [ $node GetNestedElement $j ] ]
	if { [ llength $a ] > 0 } {
	    set lst [ concat $lst $a ]
	}
    }

    set maxno [ llength $attributepointers ]
    set ndtype [ $node GetAttribute Type ]
    if { $ndtype == "Folder" || $ndtype == "Subject" } {
	return $lst
    } elseif { $ndtype != "Image" } {
	set maxno 1
    } 

    set i 0
    while { $i < $maxno  } {
	set fname [ $node GetAttribute [ lindex $attributepointerfilenames  $i ] ]
	set obj [ $node GetAttribute [ lindex $attributepointers $i ] ]
        set name [ $node GetName ]
	set attr [ lindex $attributepointers $i ]
	if { $obj != 0  } {
	    set ext [ file extension $fname ]
	    set sz [ $obj GetSize ]
	    if { [ $obj isa pxitclimage ] } {
		set sz [ expr $sz -1 ]
	    }
	    if { $ext != ".donotsave" && $sz > 0 } {
		set ok 0
		if { [ string length $fname ]  < 2 } {
		    set fname ""
		} elseif { [ file exists $fname ] == 1 } {
		    set ok 1
		}
		
		if { $ok == 0 &&  $dosave > 0 } {
		    set ok [ $obj Save $fname ]
		    if { $ok > 0 } {
			pxtkprint "Saved $name:$attr --> ($fname)"
		    }
		}

		if { $ok == 0 } {
		    lappend lst "$name:$attr ($fname)  [ $obj GetSize ]"
		}
	    }
	}
	incr i
    }
    
    puts stderr "lst=$lst"
    return $lst


}
# ------------------------------------------------------------------
itcl::body bis_datamanager::LoadXML  { fname } {

    set parse [ vtkXMLDataParser New ]
    $parse SetFileName $fname
    $parse SetIgnoreCharacterData 1
    $parse Parse

    set elem [ $parse GetRootElement ]
    set ok 0
    if { $elem != "" } {
	if { [ $elem GetName ] ==  "BioImageSuite_DataTree"  } {
	    $this CleanXML
	    $rootnode DeepCopy $elem
	    #	    puts stdout "Succesfully  Read XML Data Tree File from $fname"
	}
	set ok 1
    }
    $parse Delete
    $rootnode SetName "BioImageSuite_DataTree"
    $rootnode SetAttribute "Type" "Folder"
    $rootnode SetAttribute "Icon" "idir"
    $rootnode SetAttribute "Linecolor"  green
    $rootnode SetAttribute "IsIdentity"  1
    $rootnode SetAttribute "Expanded"  1
    $rootnode SetAttribute GlobalFilename [ file normalize $fname ]
    $rootnode SetAttribute GlobalPath    [ file dirname  [ file normalize $fname ] ]

    $this RecursiveFixTreeAndAllocatePointers $rootnode [ $rootnode GetAttribute GlobalPath ]
    return ok
}
# -----------------------------------------------------------------------------------------------------
itcl::body bis_datamanager::SaveXML  { fname } {

    set fout [ open $fname w ]
    if { $fout!=0 } {
	set gp [ file dirname  [ file normalize $fname ] ]
	$rootnode SetAttribute GlobalFilename [ file normalize $fname ]
	$rootnode SetAttribute GlobalPath     $gp
	set line [ $this XMLElementToString $rootnode 0 1  $gp ]
	puts $fout $line
	close $fout
	return 1
    }
    return 0
}

# -----------------------------------------------------------------------------------------------------
itcl::body bis_datamanager::XMLElementToString { elem { n 0 } { savemode 0 } { globalpath "" } } {
    set line ""
    set offset ""
    for { set i 0 } { $i < $n } { incr i } {
	set offset "$offset\t"
    }
    set line ""

    set preservelist [ concat $attributeszero $attributepointerfilenames ]
    
    if { $savemode  == 1 } {
	foreach attr $preservelist {
	    set old($attr) [ $elem GetAttribute $attr ]
	}
	
	foreach attr $attributeszero {
	    $elem SetAttribute $attr 0 
	}

	foreach attr $attributepointerfilenames {
	    set f  [ $elem GetAttribute $attr ]
	    set f2 [ $this FileNameToRelative $f $globalpath ]
	    if { $f2 != $f } {
#	    puts stderr "Remapping to relative filenames $f -> $f2"
		$elem SetAttribute $attr $f2 
	    }
	}
    }


    if { $elem != $rootnode } {
	set tagname "Node"
	set myline "\n${offset}<$tagname "
    } else {
	set tagname "[ $rootnode GetName ]"
	set myline "<$tagname"
    }
    if { [ $elem GetNumberOfAttributes ] > 0 } { 
	for { set i 0 } { $i < [ $elem GetNumberOfAttributes ] } { incr i } {
	    set myline "$myline [ $elem GetAttributeName $i ]=\"[ $elem GetAttributeValue $i]\"" 
	}
    }

    set myline "$myline\>"
    #    puts stderr "$offset *** myline=$myline *** "
    set line "${line}${myline}"

    if { $savemode  == 1 } {
	foreach attr $preservelist {
	    $elem SetAttribute $attr $old($attr)
	}
    }

    for { set j 0 } { $j < [ $elem GetNumberOfNestedElements ] } { incr j } {
	set newline "[ $this XMLElementToString [ $elem GetNestedElement $j ] [ expr $n +1 ] $savemode  $globalpath]"
	#	puts stderr "$offset ****** newline=$newline *** "
	set line "${line}${newline}"
    }

    set cline "$offset</$tagname>"
#    puts stderr "$offset *** cline = $cline *** "
    set line "${line}\n${cline}"
    return $line
}

# ---------------------------------------------------------------------------------------------------------------------
# Tree Manipulation -- this is key !
# 
# Theoretically all in place -- check, check, check
# ---------------------------------------------------------------------------------------------------------------------
itcl::body bis_datamanager::RecursiveAllocateNewPointersAndCopy { elem } {

    if { $elem == 0 || $elem == $rootnode } {
	return 0
    }

    for { set j 0 } { $j < [ $elem GetNumberOfNestedElements ] } { incr j } {
	$this RecursiveAllocateNewPointersAndCopy [ $elem GetNestedElement $j ]
    }

    foreach nm $attributepointers { 
	set ptr [ $elem GetAttribute $nm ]
	if { $ptr !=0 &&  $ptr != "" } {

	    #do something
	    set cl [ $ptr info class ]
	    set newptr [ eval "$cl #auto" ]
	    set newptr [ $newptr GetThisPointer ]
	    $newptr Copy $ptr
	    $elem SetAttribute $nm $newptr
	} 
    }

    return 1
    

}
# ---------------------------------------------------------------------------------------------------------------------
itcl::body bis_datamanager::CreateUniqueIds { elem } {

    if { $elem == 0 } {
	return 0
    }

    set nm [ $elem GetName ]
    set lst [ split $nm : ]
    set id [ $this GetNextId ]
    

    if { [ llength $lst ] == 2 } {
	set newname "[lindex $lst 0 ]"
    } else {
	set upper [ expr [ llength $lst ] -2 ]
	set newname ""
	for { set i 0 } { $i < $upper } { incr i } {
	    set newname "$newname[llength $lst $i]"
	}
	set newname "${newname}"
    }

    $xmltree SetAttribute UniqueId $id
    $this SetUniqueName $xmltree $newname
    
    for { set j 0 } { $j < [ $elem GetNumberOfNestedElements ] } { incr j } {
	$this CreateUniqueIds [ $elem GetNestedElement $j ]
    }
    return $id
}
# ---------------------------------------------------------------------------------------------------------------------
itcl::body bis_datamanager::CopyElement { elem newparent } {

    if { $elem == 0 || $elem == $rootnode } {
	return 0
    }

    if { [ $elem GetParent ] == $newparent } {
	return 0
    }

    set newnode [ vtkXMLDataElement New ]
    $newnode DeepCopy $elem
    $this CreateUniqueIds $newnode
    $this RecursiveAllocateNewPointersAndCopy $newnode
    $newparent AddNestedElement $newnode
    return 1
}
# ---------------------------------------------------------------------------------------------------------------------
itcl::body bis_datamanager::MoveElement { elem newparent } {

    if { $elem == 0 || $elem == $rootnode } {
	return 0
    }

    if { [ $elem GetParent ] == $newparent } {
	return 0
    }
    
    puts stderr "[[ $elem GetParent ] GetName ] Removing [ $elem GetName ]"

    $elem Register $rootnode
    [ $elem GetParent ] RemoveNestedElement $elem
    #    puts stderr "[ $newparent GetName ] Adding [ $elem GetName ]"
    $newparent AddNestedElement $elem
    $elem UnRegister $rootnode
    return 1
    
}
# ---------------------------------------------------------------------------------------------------------------------
itcl::body bis_datamanager::DeleteElement { elem  } {

    if { $elem ==0 || $elem == $rootnode } {
	return 0
    }

    $this RecursiveDeleteChildren $elem
    [ $elem GetParent ] RemoveNestedElement $elem
    $elem Delete
}
# ---------------------------------------------------------------------------------------------------------------------
itcl::body bis_datamanager::InsertElement { elem newparent } {

    if { $elem == 0 || $elem == $rootnode } {
	return 0
    }

    if { [ $elem GetParent ] == $newparent } {
	return 0
    }
    
    set newnode [ vtkXMLDataElement New ]
    $newnode DeepCopy $elem
    $this CreateUniqueIds $newnode
    $newparent AddNestedElement $newnode
    return 1
}


# ---------------------------------------------------------------------------------------------------------------------

if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {

    package require vtkpxcontrib

    # Random Testing Code Here

    set alg [ bis_datamanager \#auto ]
    set f [ lindex $argv 0 ]
    set ok [ $alg ImportMSBFile $f ]
    if { $ok > 0 } {
	set ok [ $alg SaveXML "$f.xmltree" ]
	puts stderr "Saved in $f.xmltree" 
    }

    exit
}


