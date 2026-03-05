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

package require bis_guitreeimageutility 1.0
package provide bis_guitreecreate4d     1.0

itcl::class bis_guitreecreate4d {

    inherit bis_guitreeimageutility
    
    constructor { args } { 
	set componentnamelist [ list bis_create4dimage ]
    }
    
    public method DelayedCreateGUI  { }
    public method GrabTreeSelection { field { imageNumber 0 } } 
    public method updateGUI         { tab } { return 0 }
    public method SetSpaceNode      { }
    public method ClearSpaceNode    { } 
}

itcl::body bis_guitreecreate4d::DelayedCreateGUI { } {

    if { $fullyinitialized == 1 } {
	return 1
    }

    if { $basewidget == 0 } {
	return 0
    }
    ::bis_guitreeimageutility::DelayedCreateGUI
    
    wm geometry $basewidget 620x600
    
    pack forget $guiArray(ent1) $guiArray(but1) $guiArray(f1)
    pack forget $guiArray(f2) $guiArray(label) $guiArray(radio1) $guiArray(radio2) $guiArray(check)
    
    set guiArray(f12)   [ labelframe $basewidget.f12 ]
    set guiArray(but12) [ eval "button $guiArray(f12).grabbutton -activebackground white -foreground black -activeforeground black -text \"Grab Selection\" -command {$this GrabTreeSelection 0 2 } " -state disabled ] 
  
    set guiArray(f32)   [ labelframe $basewidget.f32 ]
    set guiArray(ent32) [ ::iwidgets::entryfield $guiArray(f32).ent -width 30 -state normal -labeltext "Space Node" -foreground black -textbackground white ]
    set guiArray(but22) [ eval "button $guiArray(f32).grabbutton  -activebackground white -foreground black -activeforeground black -text \"Set Space Node\" -command {$this SetSpaceNode } " ] 
    set guiArray(but32) [ eval "button $guiArray(f32).clearbutton -activebackground white -foreground black -activeforeground black -text \"Clear Space Node\" -command {$this ClearSpaceNode } -state disable " ] 
    
    pack $guiArray(f12)   -side top  -fill x -pady 6
    pack $guiArray(but12) -side left -fill x -expand 1 -padx 3
    pack $guiArray(f32)   -side top  -fill x -pady 6
    pack $guiArray(ent32) $guiArray(but22) $guiArray(but32) -side left -fill x -expand 1 -padx 3
    pack $guiArray(f2)    -side top  -fill x -pady 6
    pack $guiArray(label) $guiArray(radio1) $guiArray(radio2) $guiArray(check) -side left -fill x -expand 1 -padx 3

    $this SetTitle "BioImageSuite::Concatenate Image (bis_algo)"
}

itcl::body bis_guitreecreate4d::GrabTreeSelection { field { imageNumber 0 } } {

    set tree1 [ $treeGUI getTree ]
    if { $tree != $tree1 || [ lsearch [ $tree1 getPathList ] $parentNode ] < 0 } { 
 	tk_messageBox -type ok  -title "Cannot Grab Image" -message "Cannot Find Parent Node" -icon error
 	return 0 
    }
    set imageNode [ $treeGUI getSelectionPath ]
    
    if { ![ file exists [ $tree1 getNodeFileName $imageNode ] ] } { 
	tk_messageBox -type ok  -title "Cannot Grab Image" -message "File does not exist" -icon error
	return 0
    }
    
    if { [ $tree1 getNodeType $imageNode ] != "Image" } { 
	tk_messageBox -type ok  -title "Cannot Grab Image" -message "Node must be an image type" -icon error
	return 0
    }
    
    set img [ $treeGUI getReslicedImage $parentNode $imageNode ]
    if { $img == 0 } { return 0 }
    [ lindex $componentlist 0 ] addImage $imageNode $img
}

::itcl::body bis_guitreecreate4d::SetSpaceNode { } {

    set tree [ $treeGUI getTree ]
    set imageNode [ $treeGUI getSelectionPath ]

    if { [ $tree getNodeType $imageNode ] != "Image" && [ $tree getNodeType $imageNode ] != "Folder" } {
	tk_messageBox -type ok -title "Cannot Grab Node" -message "Node must be a Image or Folder" -icon error
	return 0
    }
    
    set pathName [ $tree getNodeTitle $imageNode ]

    [ lindex $componentlist 0 ] deleteAll

    $guiArray(ent32) clear
    $guiArray(ent32) insert 0 $pathName
    $guiArray(ent32) configure -foreground black
    $guiArray(but32) configure -state normal
    $guiArray(but12) configure -state normal
    
    set parentNode $imageNode
}

::itcl::body bis_guitreecreate4d::ClearSpaceNode { } {

    if { $parentNode == "" } { return 0 }
    [ lindex $componentlist 0 ] deleteAll
    set parentNode ""
    $guiArray(ent32)   clear
    $guiArray(but32) configure -state disable
    $guiArray(but12) configure -state normal
}
