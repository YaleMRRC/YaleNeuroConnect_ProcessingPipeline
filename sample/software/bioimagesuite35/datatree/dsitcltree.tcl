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

package provide dsitcltree 1.0

package require Itcl
package require pxvtable 1.0
package require struct;          #This package includes the "struct::tree"

lappend auto_path [file dirname [info script]]

::itcl::class dsitcltree {
   
    protected variable imageList 
    protected variable imagePath
    protected variable treeArray
    protected variable pathArray
    protected variable masterCount
    protected variable tree

    public method printSelf {}
    
    #accessor methods
    public method GetThisPointer   { } 
    public method getNumberOfNodes { }
    public method getRoot          { }
    public method getPathList      { }
    public method pathExist        { path }
    public method getMasterCount   { } { return $masterCount }
    public method getAllNodes      { } 

    protected method getNodeProperty     { property nodeID }

    public method getNodeParent          { nodeID } 
    public method getNodeType            { nodeID } { return [ getNodeProperty type     $nodeID ] }
    public method getNodeTitle           { nodeID } { return [ getNodeProperty title    $nodeID ] }
    public method getNodeFileName        { nodeID } { return [ getNodeProperty filename $nodeID ] }
    public method getNodeNotes           { nodeID } { return [ getNodeProperty note     $nodeID ] }
    public method getNodeImageObject     { nodeID } { return [ getNodeProperty imageobject          $nodeID ] }
    public method getNodeTransFromParent { nodeID } { return [ getNodeProperty transfromparfilename $nodeID ] }
    public method getNodeTransToParent   { nodeID } { return [ getNodeProperty transfromparfilename $nodeID ] }


    public method getCommonAncestor      { node1 node2 }

    #modifer methods
    public method setNodeFileName        { fileName  nodeID }
    public method setNodeType            { fileName  nodeID }
    public method setNodeNotes           { fileName  nodeID }    
    public method setNodeTransFromParent { transform nodeID }
    public method setNodeTransToParent   { transform nodeID }
    public method setNodeImageObject     { object    nodeID }
    public method setNodeTitle           { title     nodeID }    

    public method addSubTree        { treeObj newParentNode }
    public method addNode           { title parentNode type }
    public method deleteNode        { nodeID }
    public method initializeNewTree { }

    public method copyTree       { treeObj }
    public method copyTreeAtNode { treeobj node }
    public method copyNode       { treeobj path newPath newParentPath }

    protected method convertNodeNumberToNodePath { nodeID }
    protected method convertNodePathToNodeNumber { nodeID }
    public method uniqueTitle { title parentPath }

    protected method getTreeFile  { {mode 0} }
    public method saveReorangized { {filename ""} }
    public method writeDatatree   { {relativePath 1} {filename ""} }
    public method readDatatree    { {filename ""} }
   
    protected method readChellyDatatree { filename } 
    protected method formatIDValue { text }
    constructor { args } {

	set tree [ struct::tree [ pxvtable::vnewobj ] ]
	set imageList [ list "MNI_T1_1mm.nii.gz" "MNI_T1_1mm_stripped.nii.gz" "MNI_T1_2mm.nii.gz" "MNI_T1_2mm_stripped.nii.gz" ]
	set imagePath [ file normalize [ file join [ file join [ file dirname [ info script ] ] [ file join ..  images  ] ] ] ]
	set masterCount 1
	$tree rename root /Data
	
	if { [string length $args] } { $this initializeNewTree }
    }
    
    destructor {
	set pathList [ $tree descendants /Data ]
	foreach path $pathList {
	    if { [ $tree keyexists $path imageobject ] } {
		::itcl::delete object [ getNodeImageObject ]
	    }   
	}
	$tree destroy
    }
}
#change to use struct tree
::itcl::body dsitcltree::printSelf { } {

    puts \n
    set pathList [ $tree descendants /Data ]
    foreach path $pathList {
	puts "path=$path"
	foreach property { Parent Title Type Notes
	    FileName TransToParent TransFromParent }  {
	    puts "$property= [ getNode${property} $path ]"
	}
	puts "-----------------------"
    }
}


::itcl::body dsitcltree::GetThisPointer { } {
    return $this
}
#do we need it
::itcl::body dsitcltree::getNumberOfNodes { } {
    return [ llength [ array names pathArray ] ]
}
#do we need it
::itcl::body dsitcltree::getRoot { } {
    return $treeArray(rootname)
}
#do we need it
::itcl::body dsitcltree::getPathList { } {

    set root [ $tree rootname ]
    set out  [ $tree descendants $root  ]
    set out  [ linsert $out 0 $root ]
    return $out
}
#do we need it
::itcl::body dsitcltree::getAllNodes { } {
   return [ lsort [ $tree nodes ] ]
}

#is used in tree gui
::itcl::body dsitcltree::pathExist { path } {
    #also could do return [ $tree exsists $path ]
    if { [ lsearch -exact [ getPathList ] $path ] > -1 } {
	return 1
    } else { 
	return 0
    }
}

#possilbe add getDesendant to return current node with [ tree decendant ]
#possilbe add getDesendant to return current node with [ tree decendant ] with ancestor

#takes in a node path and returns the node parent 
::itcl::body dsitcltree::getNodeParent { nodeID } {
 
    if { [ $tree exists $nodeID  ] && $nodeID != [ $tree rootname ] } {
	return [ $tree parent $nodeID  ]
    } else { return "" }
}

#takes in a node path and a property key for the node
#return the value stored by the node for the key
#returns empty string if key doesn't exists
#private method-- should only be called be the other accesor methods
::itcl::body dsitcltree::getNodeProperty { property nodeID } {
    
    if { [ $tree keyexists $nodeID $property ] } {
	return [ $tree get $nodeID $property ]
    } else { return "" }
}

::itcl::body dsitcltree::getCommonAncestor { node1 node2 } {
 
    set oneuppers [ $tree ancestors $node1 ] 
    set twouppers [ $tree ancestors $node2 ]
    
    set ones [ linsert $oneuppers 0 $node1 ]
    set twos [ linsert $twouppers 0 $node2 ]
    
    set length [ llength $ones ]

    for { set x 0 } { $x < [ llength $ones ] } { incr x } {
	if { [ lsearch $twos [ lindex $ones $x ] ] != -1 } {
	    return [ lindex $twos [ lsearch $twos [ lindex $ones $x ] ] ]
	}
    }
    return [ $tree rootname ]
}
#delete
::itcl::body dsitcltree::convertNodePathToNodeNumber { nodeID } {

    set isPath [ regexp {\D} $nodeID ]
    if { $isPath } {
	set nodeID $pathArray($nodeID)   
    }
    return $nodeID
}
#delete
::itcl::body dsitcltree::convertNodeNumberToNodePath { nodeID } {

    set isPath [ regexp {\D} $nodeID ]
    if { $isPath != 1 } {
	set nodeID $treeArray($nodeID,path) 
    }
    return $nodeID
}

#Modifier methods to change the filename, type, transforms and object of a node
#all take in the new value and the node
::itcl::body dsitcltree::setNodeFileName { fileName nodeID } {
    
    $tree set   $nodeID filename $fileName
    #add delete object
    $tree unset $nodeID imageobject
}

::itcl::body dsitcltree::setNodeType { fileName nodeID } {
   
    $tree set $nodeID type $fileName
}

::itcl::body dsitcltree::setNodeNotes { fileName nodeID } {

    $tree set $nodeID note $fileName
}

::itcl::body dsitcltree::setNodeTransFromParent { transform nodeID } {

    $tree set $nodeID transfromparfilename $transform
}

::itcl::body dsitcltree::setNodeTransToParent { transform nodeID } {

    $tree set $nodeID transtoparfilename $transform
}

::itcl::body dsitcltree::setNodeImageObject { object nodeID } {

    $tree set $nodeID imageobject $object 
}


#setNodeTitle - inputs a new title and node path
#change the title of the selected node
#also corrects the paths for the node
#and it children for the change in title
::itcl::body dsitcltree::setNodeTitle { title nodeID } {

    set parentID [ getNodeParent $nodeID ]
    set title    [ uniqueTitle $title $parentID ]
    set newnode  "$parentID/$title"

    $tree rename $nodeID $newnode
    $tree set $newnode title $title

    set childList [ $tree descendants $newnode ]
    foreach child $childList {
	set newChild [ regsub $nodeID $child $newnode ]
	$tree rename $child $newChild
    }

    return $newnode
} 

::itcl::body dsitcltree::addSubTree { treeObj newParentNode } {
   
    set path [ lindex [ $treeObj getPathList ]  1 ]
    set newParentPath [ regsub {/Data} [ $treeObj getNodeParent $path ] $newParentNode ]
    set newTitle [ $this uniqueTitle [ $treeObj getNodeTitle  $path ] $newParentPath ]
    
    if { $newTitle != [ $treeObj getNodeTitle $path ] } {
	$treeObj setNodeTitle $newTitle $path
    }

    foreach path [ lrange [ $treeObj getPathList ]  1 end ] {
	set newPath [ regsub {/Data} $path $newParentNode ]
	set newParentPath [ regsub {/Data} [ $treeObj getNodeParent $path ] $newParentNode ]
	$this copyNode $treeObj $path $newPath $newParentPath 
    }
}

#take in the new nodes title, parentNode, and type
#surfaces, electordes, landmarks, and folders all have their transform set to identity
::itcl::body dsitcltree::addNode { title parentNode type } {

    set title [ uniqueTitle $title $parentNode ]
    set newNode "$parentNode/$title"

    $tree insert $parentNode end $newNode
    $tree set $newNode title $title
    $tree set $newNode type  $type

    if { $type != "Image" } { 
	$tree set $newNode transtoparfilename   1
	$tree set $newNode transfromparfilename 1
    }
}

#delete input node and all children from tree
::itcl::body dsitcltree::deleteNode { nodeID } {
    
    if { [ $tree exists $nodeID ] } {
	$tree delete $nodeID
    }
}

#takes in the title and a node
#ensures that all nodes have a unique path
#if a node exisits with the same path an interger is added to the title
::itcl::body dsitcltree::uniqueTitle { title parentNode } {

    if { $parentNode == "" } { return $title } 
    set count 1
    set newTitle $title
    set pathList [ $tree children $parentNode ]
    while { [ lsearch -exact $pathList "$parentNode/$newTitle" ] >= 0  } {
	set newTitle "$title$count"
	incr count
    }
    return $newTitle
}
		
#add the first node to the tree
#is called by the constructor if arguments are given to the constructor
::itcl::body dsitcltree::initializeNewTree { } {

    addNode "MNI T1 1mm" /Data Image
    setNodeFileName "$imagePath/MNI_T1_1mm.nii.gz" "/Data/MNI T1 1mm"
}

#COPY treeobj at the node to this
itcl::body dsitcltree::copyTree { treeObj } {

    set pathList [ $tree descendants [ $tree rootname ] ]
    foreach path $pathList {
	$this copyNode $treeObj $path $path [ $treeObj getNodeParent $path ]
    }
}

itcl::body dsitcltree::copyTreeAtNode { treeObj node } {
    
    set node [ $treeObj convertNodeNumberToNodePath $node ]
    set nodeParent [ $treeObj getNodeParent $node ]
    set pathList [ $treeObj getPathList ]

    foreach path $pathList {
	set exp1 "$node/"; set exp2 "$node$"
	if {[ regexp $exp1 $path ] || [ regexp $exp2 $path ]} {
 
	    set newPath [ regsub $nodeParent $path /Data ]
	    set parentPath [ $treeObj getNodeParent $path ]
	    set newParentPath [ regsub $nodeParent $parentPath /Data ]
	    
	    $this copyNode $treeObj $path $newPath $newParentPath 
	}    
    }
}

#copies from treeobj to this 
itcl::body dsitcltree::copyNode { treeObj path newPath newParentPath } {

    set type [ $treeObj getNodeType $path ]
    
    $this addNode                [ $treeObj getNodeTitle    $path ] $newParentPath $type
    $this setNodeFileName        [ $treeObj getNodeFileName $path ] $newPath
    $this setNodeNotes           [ $treeObj getNodeNotes    $path ] $newPath

    if { $type == "Image" } {
	$this setNodeTransToParent   [ $treeObj getNodeTransToParent   $path ] $newPath
	$this setNodeTransFromParent [ $treeObj getNodeTransFromParent $path ] $newPath
    }
}

::itcl::body dsitcltree::getTreeFile { {mode 0} } {
    
    set typelist {
	{"Tree Definition File" {.tre}}
	{"All Files" {*}}
    }
    if { $mode } {
	return [tk_getOpenFile -filetypes $typelist]
    } else {
	return [tk_getSaveFile -filetypes $typelist]
    }
}

::itcl::body dsitcltree::saveReorangized { {filename ""} } { 
    
    if { $filename == "" } { set filename [ $this getTreeFile 0 ] }
    if {![string length $filename]} {return 0}
    set treepath [ file dirname $filename ]
    set savePath $treepath

    foreach path [ lsort [ array names pathArray ] ] {
	set nodeID $pathArray($path)
	if { $nodeID && $treeArray($nodeID,type) == "Folder" } {
	    file mkdir [ file join $treepath $treeArray($nodeID,title) ]
	    set savePath [ file join $treepath $treeArray($nodeID,title) ]
	}

	foreach value { filename transtoparfilename transfromparfilename }  {
	    if { [ info exist treeArray($nodeID,$value) ] && [ file exist $treeArray($nodeID,$value) ] && ![ regexp {/MNI_T1_(1|2)mm(_stripped)?.nii.gz$} $treeArray($nodeID,$value) ] } {
			
		set fileID [ file tail $treeArray($nodeID,$value) ]
		set newFilePath [ file join $savePath $fileID ] 
		puts "copying $treeArray($nodeID,$value) to $newFilePath"
	        file copy -force $treeArray($nodeID,$value) $newFilePath
		
		if { [ file extension $fileID ] == ".hdr" } {
		    set fileRoot [ file rootname $fileID ]
		    set fileDir  [ file dirname  $treeArray($nodeID,$value) ]
		    set oldImagePath   [ file join $fileDir "$fileRoot.img"    ]
		    set oldImageGzPath [ file join $fileDir "$fileRoot.img.gz" ]
		    
		    if { [ file exist $oldImagePath ] } {
			set newImagePath   [ file join $savePath "$fileRoot.img"    ]
			puts "copying $oldImagePath to $newImagePath"
			file copy -force -- $oldImagePath   $newImagePath 
		    } elseif { [ file exist $oldImageGzPath ] } {
			set newImageGzPath [ file join $savePath "$fileRoot.img.gz" ]
			puts "copying $oldImagePath to $newImagePath"
			file copy -force -- $oldImageGzPath $newImageGzPath
		    }
		}
		set treeArray($nodeID,$value) $newFilePath
	    }
	}
    }
    writeDatatree 1 $filename
}

::itcl::body dsitcltree::writeDatatree { {relativePath 1} {filename ""} } {
 
    if { $filename == "" } { set filename [ $this getTreeFile 0 ] }
    
    if {![string length $filename]} {return 0}
    
    if { [ file extension $filename ] != ".tre" } {
	set filename "${filename}.tre"
    }
        
    set treepath "[ file dirname $filename ]/"
    set fileID [ open $filename w ]
    
    puts $fileID "\#new Datatree File Format"

    if { $relativePath } { 
	puts $fileID "relativePath : 1" 
    } else { 
	puts $fileID "relativePath : 0" 
    }
    
    puts $fileID "\n\n"
    
    set pathList [ $tree descendants /Data ]
    
    foreach path $pathList {
	
	puts $fileID "Path : $path"
	foreach value { Parent Title Type Notes }  {
	    puts $fileID "$value : [ getNode${value} $path]"
	}
	foreach value { FileName TransToParent TransFromParent } {
	    if { $relativePath } {
		regsub $treepath [ getNode${value} $path] "" match
		puts $fileID "$value : $match"
	    } else {
		puts $fileID "$value : [ getNode${value} $path]"
	    }   
	}
	puts $fileID "-------------------------"
    }
    close $fileID
    return 1
}

#formatIDValue puts curly brackets around each string in idString
#this is need because string with space already are enclosed in curly brackets
#returns a string in format [ path number path2 number2 ... ]
::itcl::body dsitcltree::formatIDValue { idString } {

    set start 0
    set returnString ""
    puts "formating ids"
    while { [ regexp -lineanchor -start $start -indices {(?:.).+?(?:\{|\}|$)} $idString sub ] } {
	set start [ lindex $sub 1 ]
	set text1 [ string range $idString [ lindex $sub 0 ] [ lindex $sub 1 ] ]
	if { [ regexp {(?:\})(.+)} $text1 -> text1]} {
	    set text1 [ regsub      {^\s} $text1 "\{"   ]
	    set text1 [ regsub      {\s$} $text1 "\}"   ]
	    set text1 [ regsub -all {\s}  $text1 "\}\{" ]
	} 
	set returnString "$returnString$text1"
    }
    return $returnString
}

::itcl::body dsitcltree::readChellyDatatree { filename } {   



    if {[llength $filename]} {
	set treepath [file dirname $filename]
	
	set fileid [ open $filename r ]
	gets $fileid line
	
	if { [ string compare $line "#Chelly's Datatree File Format" ] != 0 } {
	    puts stderr " File is not in Chelly's Datatree File Format "
	    close $fileid
	    return 0
	}
	
	
	#    set OutTreeList [read $f]
	
	while { [ gets $fileid line ] >=0 } {
	    set index [string first ":" $line]
	    
	    if { $index > 0 }  {
		set len   [string length $line]
		set key   [string trim   [string range $line 0 [expr $index - 1]]]
		
		if {[string match -nocase {*filename} $key]} {
		    
		    set tempvalue [string trim [string range $line [expr $index +1] [expr $len -1]]]
		    if {$tempvalue != -1} {
			set value [file join $treepath $tempvalue]
		    } else {
			set value $tempvalue
		    }
		    
		} else {
		    set value [string trim [string range $line [expr $index +1] [expr $len -1]]]
		}
		set masterlist ""; set masterpath "" 
		if { [ llength $masterlist ] > 0 } {
		    
		    # Detect and change
		    set newindex [string first "filename" $key]
		    if { $newindex >= 0 } {
			set fname [ file tail $value ]
			set tt [ lsearch $masterlist $fname ]
			if { $tt >= 0 } {
			    set newfname [ file join $masterpath $fname ]
			    pxtkprint "DataTree: Found $fname, $value replacing with $newfname\n"
			    set value $newfname
			}
		    }
		}

		set newtree($key)  $value 
		puts stderr "New key = \"$key\" \t\t value = \"$value\""
	    }
	}  

#	puts stderr [ array names newtree ]
	close $fileid
	#end of chelly's method

	#a small work around for the different naming schemes
	#create a new tree and copy it to the current tree
	set tree2 [ struct::tree [ pxvtable::vnewobj ] ]
	$tree2 deserialize $newtree(serialized)
	$tree2 --> $tree
	$tree2 destroy
	
	#loop through each node and rename certain properties to fit new scheme
	$tree rename Data /Data
	set pathList [ $tree descendants /Data ]
	foreach path $pathList { 

	    #rename all the paths to work with current naming scheme
	    set parentID [ getNodeParent $path ]
	    set title    [ getNodeTitle  $path ]
	    set title    [ uniqueTitle $title $parentID ]
	    set newnode  "$parentID/$title"
	    $tree rename $path $newnode

	    #rename the types to fit current scheme (no change to Folder type)
	    #Surface Surface -> Surface, Surface Landmark -> Landmark,  
	    #Surface Electrode -> Electrode, any numbers -> Image
	    #set transformations: surface, electrodes, landmarks, and folders are idenity
	    switch  -exact -- [ getNodeType $newnode ] {

		"Surface Surface"   { 
		    setNodeType Surface      $newnode 
		    setNodeTransFromParent 1 $newnode
		    setNodeTransToParent   1 $newnode
		}

		"Surface Electrode" { 
		    setNodeType Electrode    $newnode 
		    setNodeTransFromParent 1 $newnode
		    setNodeTransToParent   1 $newnode
		}

		"Surface Landmark"  { 
		    setNodeType Landmark     $newnode 
		    setNodeTransFromParent 1 $newnode
		    setNodeTransToParent   1 $newnode
		}

		"Folder"            { 
		    setNodeType Folder       $newnode 
		    setNodeTransFromParent 1 $newnode
		    setNodeTransToParent   1 $newnode
		}
		default             {
		    setNodeType Image     $newnode 
		    if { [ $tree keyexists $newnode TransFromParFileName ] \
			     && [ $tree get $newnode TransFromParFileName ] != -1 } {
			setNodeTransFromParent [ $tree get $newnode TransFromParFileName ] $newnode
		    }
		    #need to check if *.matr and update the transto parent
		    if { [ $tree keyexists $newnode TransToParFileName  ] \
			     && [ $tree get $newnode TransToParFileName ] != -1 } {
			setNodeTransToParent [ $tree get $newnode TransToParFileName ] $newnode
		    }
		}
	    }								  
	    
	    #filename if there are any
	    if { [ $tree keyexists $newnode FileName ] && [ $tree get $newnode FileName ] != -1 } {
		setNodeFileName [ $tree get $newnode FileName ] $newnode
	    }

	}
	
	
	printSelf
	return 1
    }
}

::itcl::body dsitcltree::readDatatree { {filename ""} } {   
    
    if {$filename == ""} { set filename [ $this getTreeFile 1 ] }
    
    if {![string length $filename]} { return 0 }
    
    set treepath [file dirname $filename]
    set fileid [open $filename r]
    
    gets $fileid line

    if {[ regexp {\#Chelly's Datatree File Format} $line ]} {
	close $fileid
	puts "Tree in old format"
	return [ readChellyDatatree $filename ]
    }

    if {![ regexp {\#new Datatree File Format} $line ]} {
	tk_messageBox -type ok -title "Please select another file" -message "File is not in the correct file format" -icon error
	close $fileid
       	return [ $this readDatatree ]
    }
    
    gets $fileid line
#    regexp {(?\S+:\s+:\s)(.+)} $line -> relativePath
    regexp {(\S+)(?:\s+:\s)(.+)} $line -> key relativePath ; #double check this

    while { [ gets $fileid line ] >=0 } {

	#only read line that fit "key : value"
	#store value into an array
	#-> is a dummy variable that store " : "

	if {[ regexp {([[:alpha:]]+)(?:\s:\s)(.+)} $line -> key value ]} {

	    #parse out any key with thats a filename#double check
	    if { [ regexp {filename} $key ] } {
		if { [ regexp {/MNI_T1_(1|2)mm(_stripped)?.nii.gz$} $value ] && [ llength $imageList ] } {
		    set fname [ file tail $value ]
		    set value [ file join $imagePath $fname ]
		} elseif { $relativePath && $value != "linear.nosave" && $value != 1} {
		    set value [file join $treepath $value]
		}
	    }	       
	    set treeArray($key) $value
	}
	
	#once at the finished reading a node completely add it to the tree
	if { $line == "-------------------------" } { 

	    addNode $treeArray(Title) $treeArray(Parent) $treeArray(Type)

	    catch { setNodeTransFromParent $treeArray(TransFromParent) $treeArray(Path) } 
	    catch { setNodeTransToParent $treeArray(TransToParent) $treeArray(Path) }
	    catch { setNodeFileName $treeArray(FileName) $treeArray(Path) }
	    catch { setNodeNotes $treeArray(Notes) $treeArray(Path) }
	    
	    array unset treeArray
	} 
    }
    close $fileid
    return 1
}
	

