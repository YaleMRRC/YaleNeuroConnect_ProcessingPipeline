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

package provide bis_guitreeimageutility 1.0
package require bis_guiimageutility 1.0


itcl::class bis_guitreeimageutility {

    inherit bis_guiimageutility

    protected variable treeGUI ""
    protected variable tree ""
    protected variable parentNode ""
    protected variable output 0
    protected variable save   0
    protected variable guiArray 
    protected variable nodeObjectArray
    protected variable inputName

    constructor { args } { 

	if { [ llength $args ] } {
	    set componentnamelist [ list bis_seedcorrelation bis_roimean bis_temporalsmoothimage  bis_mediantemporalsmoothimage bis_removetemporaldrift bis_removeslicemean  bis_matrixcorrelation ]
	} else {
	set componentnamelist [ lsort [ list bis_thresholdimage bis_listthresholdimage bis_castimage  bis_flipimage bis_shiftscaleimage bis_piecewiseimagemap  bis_resampleimage bis_cropimage bis_cylindricalcropimage bis_interleave  bis_smoothimage bis_nonlinearsmoothimage bis_imagemedian bis_edgedetectimage  bis_relabelimage  bis_reorientimage  bis_fftimage bis_rfftimage ] ]
	}

	set nodeObjectArray(1) "" ; set nodeObjectArray(2) ""
    }
    
    public method AddTreeGUI { GUI } { set treeGUI $GUI }
   
    public method DelayedCreateGUI  { }
    public method GrabTreeSelection { field { imageNumber 0 } } 
    public method SetResultsFromObject { img obj }
    public method ShowWindow { args }
    public method SaveInTree { out } 
    public method TabCommand { }
    public method updateGUI  { tab } 
}

::itcl::body bis_guitreeimageutility::DelayedCreateGUI { } {

    if { $fullyinitialized == 1 } {
	return 1
    }

    if { $basewidget == 0 } {
	return 0
    }
    ::bis_guiimageutility::DelayedCreateGUI
    
      wm geometry $basewidget 620x600
  
    set guiArray(f1)  [ labelframe $basewidget.f1 ]
    set guiArray(ent1) [ ::iwidgets::entryfield $guiArray(f1).ent -width 30 -state normal -labeltext "Input Image" -foreground black -textbackground white ]
    set guiArray(but1) [ eval "button $guiArray(f1).grabbutton -activebackground white -foreground black -activeforeground black -text \"Grab Selection\" -command {$this GrabTreeSelection $guiArray(ent1) } "  ] 
    pack $guiArray(f1) -side top -fill x -pady 6
    pack $guiArray(ent1) $guiArray(but1) -side left -fill x -expand 1 -padx 3

    set guiArray(f3)  [ labelframe $basewidget.f3 ]
    set guiArray(ent) [ ::iwidgets::entryfield $guiArray(f3).ent -width 30 -state normal -labeltext "Second input" -foreground black -textbackground white ]
    set guiArray(but) [ eval "button $guiArray(f3).grabbutton -activebackground white -foreground black -activeforeground black -text \"Grab Selection\" -command {$this GrabTreeSelection $guiArray(ent) 1 } "  ] 

    set guiArray(f2)     [ labelframe $basewidget.f2 ]
    set guiArray(label)  [ label $guiArray(f2).label -text "Output Viewer:" ]
    set guiArray(radio1) [ radiobutton $guiArray(f2).radio1 -text "Reference Viewer"     -variable [ itcl::scope output ] -value 0 ]
    set guiArray(radio2) [ radiobutton $guiArray(f2).radio2 -text "Transform Viewer"     -variable [ itcl::scope output ] -value 1 ]
    set guiArray(check)  [ checkbutton $guiArray(f2).check  -text "Save Results in Tree" -variable [ itcl::scope save   ] ]
   
    pack $guiArray(f2) -side top -fill x -pady 6
    pack $guiArray(label) $guiArray(radio1) $guiArray(radio2) $guiArray(check) -side left -fill x -expand 1 -padx 3
}

::itcl::body bis_guitreeimageutility::GrabTreeSelection { field { imageNumber 0 } } {

    if { $imageNumber && $nodeObjectArray(1) == "" } {
	tk_messageBox -type ok -title "Cannot Grab Image" -message "Please set $inputName first" -icon error
	return 0
    }

    set tree [ $treeGUI getTree ]
    set imageNode [ $treeGUI getSelectionPath ]
    
    if { ![ file exists [ $tree getNodeFileName $imageNode ] ] } { 
	tk_messageBox -type ok -title "Cannot Grab Image" -message "File does not exist" -icon error
	return 0
    }
    
    if { [ $tree getNodeType $imageNode ] != "Image" } { 
	tk_messageBox -type ok -title "Cannot Grab Image" -message "Node must be an image type" -icon error
	return 0
    }
    
    if { [ $tree getNodeImageObject $imageNode ] == "" } {
	set img [ [ pxitclimage \#auto ] GetThisPointer ]
	$img Load "[ $tree getNodeFileName $imageNode ]"
	$tree setNodeImageObject $img $imageNode 
    }
    
    if { $imageNumber } {
 	set img [ $treeGUI getReslicedImage $parentNode $imageNode ]
 	if { $img == 0 } { return 0 }
	set nodeObjectArray(2) $img
    } else { 
	set nodeObjectArray(1) [ $tree getNodeImageObject $imageNode ]
	$guiArray(ent) clear; set nodeObjectArray(2) ""
	set parentNode $imageNode
    }
    
    $field clear
    $field insert 0 [ $tree getNodeTitle $imageNode ]
    $field configure -foreground black
    
    SetImage $nodeObjectArray(1) $nodeObjectArray(2)
 }

::itcl::body bis_guitreeimageutility::SetResultsFromObject { img obj } {
    
    set out [ $this GetFirstOutputObject ]
    $out ShallowCopy $img
    
    if { $output } { 
	set viewer [ $treeGUI cget -viewer2 ]
    } else {
	set viewer [ $treeGUI cget -viewer1 ]
    }
    
    $viewer SetImageFromObject $out $treeGUI
    $viewer ShowWindow
    if { $save } { SaveInTree $out }
}

::itcl::body bis_guitreeimageutility::SaveInTree { out } {

    if { $tree != [ $treeGUI getTree ] || [ lsearch [ [ $treeGUI getTree ] getPathList ] $parentNode ] < 0 } { 
	tk_messageBox -type ok  -title "Cannot Save Image in Tree" -message "Cannot Find Parent Node" -icon error
	return 0 
    }
    if { [ expr ![ $out Save "" ] ] } { return 0 }
    
    $treeGUI addNodeToTree Image [ file tail [ $out cget -filename ] ] $parentNode
    $treeGUI setIdentityToggle
    $treeGUI setFileName [ $out cget -filename ]
}

::itcl::body bis_guitreeimageutility::ShowWindow { args } {
 
    ::bis_guicontainer::ShowWindow [ lindex $args 0 ]
    $this updateGUI [ lindex $args 0 ]
}

::itcl::body bis_guitreeimageutility::TabCommand { } {
    
    updateGUI [ lindex [ $maintabnotebook pageconfigure select -label] end ]
}

::itcl::body bis_guitreeimageutility::updateGUI { tab } {

    set nameList [ list ]
    foreach alg $dualImageList { 
	lappend nameList [ $alg GetGUIName ]
    }    

    set index [ lsearch $nameList $tab ] 
    
    if { $index > -1 } {
	set inputName [ [ lindex $dualImageList $index ] GetInputName 0 ]
	$guiArray(ent1) configure -labeltext $inputName
	$guiArray(ent)  configure -labeltext [ [ lindex $dualImageList $index ] GetInputName 1 ]
	catch { pack forget $guiArray(f2) $guiArray(label) $guiArray(radio1) $guiArray(radio2) $guiArray(check) }
	catch { pack $guiArray(f3) -side top -fill x -pady 6 }
	catch { pack $guiArray(ent) $guiArray(but) -side left -fill x -expand 1 -padx 3 }
	catch { pack $guiArray(f2) -side top -fill x -pady 6 }
	catch { pack $guiArray(label) $guiArray(radio1) $guiArray(radio2) $guiArray(check) -side left -fill x -expand 1 -padx 3 }
    } else {
	$guiArray(ent1) configure -labeltext "Input Image" 
	catch { pack forget $guiArray(f3) $guiArray(ent) $guiArray(but) }
    }
}
