#!/bin/sh
# the next line restarts using wish \
    exec wish "$0" "$@"

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



#Now we have access to tk from within this script

package provide SPECTProcessProg 1.0

#Add to the auto path the bioimagesuite dirs base and main
lappend auto_path [ file dir [ info script ] ]
package require pxitclchellypackages 

# Require key packages
package require Itcl
package require Iwidgets

# C++ Extensions
package require vtkpxcontrib 1.2

# Simple Naming package  [ pxvtable::vnewobj ]
package require pxvtable         1.0

#Chelly's ImageUtils Package
package require mdImageUtils     1.0



::itcl::class SPECTprocess {

    public variable IsSolo 0
    public variable basewidget 0
    public variable thisfolder 0
    public variable viewer

    #GUI variables
    public variable MainGUIObject 0
    public variable mainname 0
    public variable Tabs 0

    public variable SPECTmessagebox 
    public variable blobMessagebox 

    #imageArray variables refer to nodes, 
    #objectArray refer to pxitcl objects
    public variable imageArray
    public variable objectArray

    #These are the parameter variables
    public variable parameters
    public variable statDisplay 
    public variable entryfieldArray

    public variable resultTreeFolder 
    public variable SPECTpath  
    public variable MNINode 
    public variable PatientMRINode 
    public variable InterictalNode 

    private variable tree 0; #pointer to the main tree
	
    constructor { args } {
	set parameters(smoothingSigma) 16
	set parameters(extentThresh) 125
	set parameters(sigLevel) 0.01
	set parameters(useMask) 1
	set parameters(saveprocessdata) 0

	set thisfolder [ file dirname [ info script ] ]
	set SPECTpath [ file join $thisfolder .. images ]
    }
    
    #GUI Init Method for SPECTprocess
    public method Initialize { widget mainGUIObj viewerIn } 
    public method setTabs  { color label index }
    public method setTab1  { iframe color }
    public method setTab23 { topfr botfr index }
    public method setTab4 { iframe color }
    public method setResultDispField { index1 mode }
    
    #Button Callbacks
    public method AddTreeInMain { }
    public method addImageToTree { nodeName nodeLoc nodeTitle imageName  } 
    public method GrabTreeSelection { num field }
    public method ClearTab1Fields { args }
	
    #Processing Methods
    public method ShowTop { } 
    public method toggle { name value }

    public method bisCalcs { }
    public method RVIEWcalcs { }
    public method ISAScalcs { }
    public method rejoinBlobs { }
	
    public method preprocess { mode }
    public method stats { ictal inter }
    public method message { messageList messagebox }
    public method finishMessage { messagebox }
    public method saveInTree { inputImage treeLoc imageTitle messagebox }
    public method checkForImage { inputImage inputObject inputName }
    public method checkLoadImage { imageName inputObject }    
    public method setResultFolder { inputImage folderTitle }
    public method getTransform { inputImage1 inputImage2 }
    public method clusterStats { mode }
    public method saveStats    { }
    public method setCrosshair { index }
    public method resetDisplayField { }
    public method displayStats { statList }
} 

#------------------------------------------------------------------------------------------
# GUI Methods
#------------------------------------------------------------------------------------------

#creates the basic gui window and calls setTabs to create each tab individually 
::itcl::body SPECTprocess::Initialize { widget mainGUIObj viewerIn } {

    set MainGUIObject $mainGUIObj
    set mainname [ $MainGUIObject cget -myname ]
    set viewer $viewerIn
   
    set basewidget [ toplevel $widget -bg "grey85" ]
    wm title $basewidget "SPECT Processing Tool"
    wm geometry $basewidget 610x600+100+50
    
    set Tabs [ iwidgets::tabnotebook $basewidget.notebook  -tabpos s ]
    $Tabs config -background "grey85" -backdrop "grey85" -raiseselect 1 
    pack $Tabs -side top -expand 1 -fill both

    for { set index 1 } { $index < 5 } { incr index } {
	switch -exact $index {
	    "1" { $this setTabs grey10    [ list "Images"  "Select The Images"         ] 1 }
	    "2" { $this setTabs grey30    [ list "SPECT Processing"                    ] 2 }  
	    "4" { $this setTabs Darkgreen [ list "Results" "Most Significant Clusters" ] 4 } 
	} 
    }

    $Tabs select 0 
    eval "wm protocol $basewidget WM_DELETE_WINDOW { wm withdraw $basewidget }"
    wm withdraw $basewidget
}

#sets the tab and the their display fields 
#first creates common features to all tabs and then calls each tabs own set method	
::itcl::body SPECTprocess::setTabs { color label index } { 
   
    set parent [ $Tabs add -label [ lindex $label 0 ] -background $color -selectbackground $color -foreground white -selectforeground white ]
    set tabTop [ frame $parent.top -bg $color -padx 10 -pady 10 ]
    pack $tabTop -fill both -expand 1
		
    if { [ llength $label ] == 2 } {
	set iframe [ labelframe $tabTop.imageframe -bg $color -text [ lindex $label 1 ] -foreground white -padx 10 -pady 5 ]
	pack $iframe -fill both -expand 1
	$this setTab$index $iframe $color
    } else {
	set topfr [ frame $tabTop.top -bg $color ]; pack $topfr -side top -fill x
	set botfr [ frame $tabTop.bot -bg $color ]; pack $botfr -side top -fill both -expand 1 -pady { 2 0 }
	$this setTab23 $topfr $botfr $index
    }
}

#Tab 1 Method
::itcl::body SPECTprocess::setTab1 { iframe color } { 
     
    for { set index 1 } { $index <= 3 } { incr index } {
        set f$index [ frame $iframe.frame$index -bg $color ]
        
	switch -exact $index {
	    "1" { set parent $f1; set label "Interictal SPECT"    }
	    "2" { set parent $f2; set label "Ictal SPECT"         }
	    "3" { set parent $f3; set label "MNI Template"        }
	} 

	pack $parent -side top -fill x -pady 6 
	
	set parentent [ ::iwidgets::entryfield $parent.ent -width 30 -state normal -labeltext $label -foreground red -background $color -textbackground black ]
	set parentbut [ eval "button $parent.grabbutton -background grey10 -activebackground grey15 -foreground white -activeforeground white -text \"Grab Selection\" -command {$this GrabTreeSelection $index $parent.ent } "  ] 
	
	pack $parentent $parentbut -side left -fill x -expand 1 -padx 3
    }
    
    ::iwidgets::Labeledwidget::alignlabels $f1.ent $f2.ent $f3.ent
    
    set f8 [ frame $iframe.frame8 -bg $color ]
    pack $f8 -side top -fill x -pady 2 

    set treebut  [ eval "button $f8.treebutton  -text \"Make Tree\" -background grey10 -activebackground grey15 -width 30 -foreground white -activeforeground white -command {$this AddTreeInMain}" ]
   
    set clearbut [ eval "button $f8.clearbutton -text \"Clear All\" -background grey10 -activebackground grey15 -foreground white -activeforeground white -command {$this ClearTab1Fields $f1.ent $f2.ent $f3.ent  }" ]
   
    pack $treebut -side left; pack $clearbut -side left -fill x -expand 1

    for { set index 10 } { $index <= 50 } { incr index 10 } { 
	set tempFrame [ frame $iframe.frame$index -bg $color ]; pack $tempFrame
    }
  
    set chkButMask [ checkbutton $iframe.frame50.chkMask -text "Use SPECT mask" -variable [ itcl::scope parameters(useMask) ] ]
    set chkButSave [ checkbutton $iframe.frame50.chkSave -text "Save Intermediate Data" -variable [ itcl::scope parameters(saveprocessdata) ] ]

    pack $chkButMask $chkButSave -side left -fill x -expand 1 -padx 3

    set entryfieldArray(smooth) [ ::iwidgets::entryfield $iframe.frame10.ent -width 30 -state normal -labeltext "Smoothing Kernel FWHM(mm)" -background $color -foreground green -textbackground black ]
   
    set entryfieldArray(extentThresh) [ ::iwidgets::entryfield $iframe.frame20.ent -width 30 -state normal -labeltext "Extent Threshold" -background $color -foreground green -textbackground black ]

    set entryfieldArray(significance) [ ::iwidgets::entryfield $iframe.frame30.ent -width 30 -state normal -labeltext "Significance Level" -background $color -foreground green -textbackground black ]
	
    pack $entryfieldArray(smooth) $entryfieldArray(extentThresh) $entryfieldArray(significance) -side left -fill x -expand 1 -padx 3
    $entryfieldArray(smooth)       insert 0 $parameters(smoothingSigma) 
    $entryfieldArray(extentThresh) insert 0 $parameters(extentThresh)
    $entryfieldArray(significance) insert 0 $parameters(sigLevel)
    ::iwidgets::Labeledwidget::alignlabels $entryfieldArray(smooth) $entryfieldArray(extentThresh) $entryfieldArray(significance)
}

#Tab 2 and 3 Method
::itcl::body SPECTprocess::setTab23 { topfr botfr mode } {

    if { $mode == 2 } { set buttonList [ list "ISAS_Processing" ISAScalcs "ISAS_HN_Processing" bisCalcs "Subtraction_Processing" RVIEWcalcs SPECTmessagebox ] 
    } else { return }

    for { set index 1 } { $index < [ llength $buttonList ] } { incr index 2 } {
	set but [ eval "button $topfr.button$index -text [ lindex $buttonList [ expr $index - 1 ] ] -command { $this [ lindex $buttonList $index ] } -background green -activebackground LightGreen" ]
	pack $but -fill x
    }
	
    set  [ lindex $buttonList [ expr [ llength $buttonList ] - 1 ] ] [ iwidgets::scrolledtext $botfr.output -width 40 -height 14 -wrap word -background grey80 -textbackground white ];
    pack $botfr.output -side top -fill both -expand 1
}   
    
#Tab 4 Method
::itcl::body SPECTprocess::setTab4 { iframe color } {

    for { set index 1 } { $index <= 12 } { incr index } {
	set h$index [ labelframe $iframe.frame$index -bg $color ] 
    }

    pack $h1 $h2 $h3 $h4 $h5 $h6 $h7 $h8 $h9 $h10 -side top -fill x -pady 3
    pack  $h11 $h12
    #label $h9.label -text "Note: Only the five most significant clusters are listed" -background $color -foreground orange; pack $h6.label 

    set grabEnt [ ::iwidgets::entryfield $h11.ent -width 30 -state normal -labeltext "TMAP" -foreground red -background $color -textbackground black ]
    set grabBut [ eval "button $h11.grabbutton -background $color -activebackground grey15 -foreground white -activeforeground white -text \"Grab Selection\" -command { $this GrabTreeSelection 8 $h11.ent } "  ]
    pack $grabEnt $grabBut -side left -fill x -expand 1 -padx 3

    set but1 [ eval "button $h12.button1 -text \"Hyperperfusion Statistics\" -command { $this clusterStats 2 } -background $color -activebackground grey15 -foreground white -activeforeground white" ]
    set but2 [ eval "button $h12.button2 -text \"Hypoperfusion Statistics\"  -command { $this clusterStats 3 } -background $color -activebackground grey15 -foreground white -activeforeground white" ]
    set but3 [ eval "button $h12.button3 -text \"Save Statisitcs\"  -command { $this saveStats } -background $color -activebackground grey15 -foreground white -activeforeground white" ]
    pack $but1 $but2 $but3 -side left -fill x -expand 1 -padx 3

    for { set index1 0 } { $index1 < 10 } { incr index1 } {
	for { set index2 0 } { $index2 < 7} { incr index2 } {
	    
	    switch -exact $index1 {
		"0" { set entField $h1 }
		"1" { set entField $h2 }
		"2" { set entField $h3 }
		"3" { set entField $h4 }
		"4" { set entField $h5 }
		"5" { set entField $h6 }
		"6" { set entField $h7 }
		"7" { set entField $h8 }
		"8" { set entField $h9 }
		"9" { set entField $h10 }
	    }
	   
	    switch -exact $index2 {
		"0" { set width 5;  set label "ksize" }
		"1" { set width 12; set label "cluster pvalue" }
		"2" { set width 14; set label "corrected pvalue" }
		"3" { set width 9;  set label "max tscore" }
		"4" { set width 3;  set label "x" }
		"5" { set width 3;  set label "y" }
		"6" { set width 3;  set label "z" }
	    }
	    set tmp [ ::iwidgets::entryfield $entField.ent$index2 -width $width -state normal -foreground white -background $color -textbackground black -textvariable [ itcl::scope statDisplay($index1,$index2) ] ]
	    if { $index1 == 0 } { 
		set statDisplay(0,$index2) $label 
	    } else {
		set statDisplay($index1,$index2) 0
	    }
		    
	    pack $tmp -side left -padx 1 -pady 4            
	}
	if { $index1 != 0 } {
	    set but [ eval "button $entField.button -text \"Set Crosshairs\"  -command { $this setCrosshair $index1 } -background $color -activebackground grey15 -foreground white -activeforeground white" ]
	    pack $but -side left -padx 1 -pady 4
	}
    }
} 
  
#------------------------------------------------------------------------------------------
# Button callbacks
#------------------------------------------------------------------------------------------

#Adds a Node to the tree with name nodeTitle to the location nodeLoc if the image exsist in SPECT_images it's set in the tree
::itcl::body SPECTprocess::addImageToTree { nodeName nodeLoc nodeTitle imageName } {

    set temp [ lindex [ $MainGUIObject AddImage [ $MainGUIObject GetRealTree ] $nodeLoc $nodeTitle ] 2 ]
    set $nodeName $temp
    if { [ file exists [ file join $SPECTpath $imageName ] ] && $imageName != "" } {
	$MainGUIObject setNodeFilename $temp [ file join $SPECTpath $imageName ]
	$MainGUIObject toggleIdentity $temp 1
    }
}

#creates the tree structure for SPECT processing 
::itcl::body SPECTprocess::AddTreeInMain { } {

    #Join the name of the main script with "packages" and "SPECT_Images" folders to get path
    #to SPECT processing images
        
    set SelectionID [ $MainGUIObject GetIDFromSelection ]
    #Add a containing folder
    set FolderNode [ lindex [ $MainGUIObject AddFolder [ $MainGUIObject GetRealTree ] $SelectionID "SPECT Processing" ] 2 ]
	
    $this addImageToTree MNINode           $FolderNode     "MNI Template MRI"          MNI_T1_2mm.nii.gz
    $this addImageToTree MNIstrippedNode   $MNINode        "MNI Template MRI stripped" MNI_T1_2mm_stripped.nii.gz
    $this addImageToTree TemplateSPECTNode $MNINode        "MNI Template SPECT"        ISAS_SPECT_Template.nii.gz
    $this addImageToTree PatientMRINode    $MNINode	   "Patient MRI" 	       ""
    $this addImageToTree InterictalNode    $PatientMRINode "Interictal SPECT"          ""
    $this addImageToTree IctalNode         $InterictalNode "Ictal SPECT"               ""

    $MainGUIObject updateVisTree [ $MainGUIObject GetVisTree ]  [ $MainGUIObject GetRealTree ]
}

::itcl::body SPECTprocess::GrabTreeSelection { num field } {
    
    set SelectionID [ $MainGUIObject GetIDFromSelection ]
    set tree [ $MainGUIObject GetRealTree ]
    
    if { $SelectionID != -1 && $SelectionID != [ $tree rootname ] } {    
    	$MainGUIObject EnsureFileLoaded $SelectionID
	set imageArray($num) $SelectionID
	$field clear
	$field insert 0 [ $tree get $SelectionID title ]
	$field configure -foreground green
    }
}

#Clears the all the Fields in Tab1
::itcl::body SPECTprocess::ClearTab1Fields { args } {
    
    foreach field $args {
	$field clear
	$field config -foreground red;
    }
   
    for { set index 1 } { $index <= 7 } { incr index } {
        if { [ info exists imageArray($index) ] } {
	    unset imageArray($index)
	}
    }
}

::itcl::body SPECTprocess::setCrosshair { index } {
    
    for { set i 4 } { $i < 7 } { incr i } {
	set coordinate$i [ expr 2*$statDisplay($index,$i) ]
    }

    [ $viewer GetViewer ] SetScaledCoordinates $coordinate4 $coordinate5 $coordinate6
}

#------------------------------------------------------------------------------------------
# Processing methods
#------------------------------------------------------------------------------------------



#Saves the imputImage to the harddrive
#Places a node on the datatree at treeloc with name imageTitle and pointing to the inputImage
#If identity is true the transformation is set to indentity
::itcl::body SPECTprocess::saveInTree { inputImage treeLoc imageTitle messagebox} {
   
   $inputImage Save 
   set thenewimg [ lindex [ $MainGUIObject AddImage $tree $treeLoc $imageTitle ] 2 ]
   $MainGUIObject toggleIdentity $thenewimg 1
   $MainGUIObject setNodeFilename $thenewimg [ $inputImage cget -filename ]
   $MainGUIObject updateVisTree [ $MainGUIObject GetVisTree ] $tree
   $messagebox insert end "$imageTitle Saved as : [ $inputImage cget -filename ]\n"
}

#Only checks to see in the input image is specified in the SPECTtool gui; does not check if image exsist
::itcl::body SPECTprocess::checkForImage { arrayLoc inputObject inputName } {
   
   if { [ info exists imageArray($arrayLoc) ] } {
       set objectArray($inputObject) [ $tree get $imageArray($arrayLoc) pxitclobj ]
       return 0
   } else {
       set ok [ tk_messageBox -type ok -message "$inputName is not set. Quiting Process" -icon error ]
       return -1
   }
}

::itcl::body SPECTprocess::checkLoadImage { imageName inputObject } {
    
    set fileName [ file join $SPECTpath $imageName ]
    set objectArray($inputObject) [ [pxitclimage \#auto] GetThisPointer ]
    if { [ file exists $fileName ] } {
	$objectArray($inputObject) Load $fileName
	return 0
    } else {
	tk_messageBox -type ok -message "Could not find $imageName. Please set load it now." -icon error
	if { [ $objectArray($inputObject) Load "" ] } { 
	    return 0
	} else {
	    ::itcl::delete object $objectArray($inputObject)
	    return -1 
	}
    }
}

#Gets the transformations from inputImage to inputImage2 and returns them in a list
::itcl::body SPECTprocess::getTransform { inputImage1 inputImage2 } {
	
    $MainGUIObject findTransforms $tree $inputImage1 $inputImage2
    array set TransCache [ $MainGUIObject GetTransformsCache ]
    set TransList $TransCache($mainname,$inputImage1:$inputImage2)
    return $TransList
}

#Creates a folder for results name folderTitle as a child of inputImage
::itcl::body SPECTprocess::setResultFolder { inputImage folderTitle } {
	
    set resultTreeFolder [ lindex [ $MainGUIObject AddFolder $tree $inputImage $folderTitle ] 2 ]
    $MainGUIObject updateVisTree [ $MainGUIObject GetVisTree]  $tree
}

#Inserts this finishing message to messagebox
::itcl::body SPECTprocess::finishMessage { messagebox } {
   
    $messagebox insert end "\n\n-----------------------------------------\n"
    $messagebox insert end "-------------Finished!!-----------\n"
    $messagebox insert end "-----------------------------------------\n"
    $messagebox yview moveto 1
}

#Inserts the text into the messagebox and scrolls the messagebox so the message is the first thing on the messagebox
::itcl::body SPECTprocess::message { messageList messagebox } {
    
    for { set index 0 } { $index < [ llength $messageList ] } { incr index } {
	$messagebox insert end [ lindex $messageList $index ] 
    }
    $messagebox yview moveto 1
}


#RVIEWcalcs does not smooth, warp, or mask the images.
#It does this simple subtraction as a check for ISAS against smoothing and warping errors.
::itcl::body SPECTprocess::RVIEWcalcs { } {

    if { [ $this checkForImage 1 InterSPECTObj "Interictal SPECT" ] || [ $this checkForImage 2 IctalSPECTObj "Ictal SPECT" ] } {
	 return -1
    }

    $this setResultFolder $imageArray(1) "Subtraction SPECT Results"
    $this message [ list "Subtraction Calulation\n---------------------\n" ] $SPECTmessagebox

    set TransList [ $this getTransform $imageArray(1) $imageArray(2) ]

    #Applies transformation and reslices ictal into interictal space 
    set Ictal_in_Int_Space [ $MainGUIObject ResliceImage $objectArray(InterSPECTObj) $objectArray(IctalSPECTObj) $TransList ] 
    if { $parameters(saveprocessdata) } { $this saveInTree $Ictal_in_Int_Space $resultTreeFolder "Resliced Ictal" $SPECTmessagebox }
    $this message [ list "Done Reslicing Ictal\n" "\Ictal resliced into Interictal space\n" ] $SPECTmessagebox

    #Normalizes ictal to the interictal
    #A the percentage threshold is applied, based on the option set in the Options Tab
    set Ict_norm [ ::mdImageUtil::Normalize $Ictal_in_Int_Space $objectArray(InterSPECTObj) 0.05] 
    if { $parameters(saveprocessdata) } { $this saveInTree $Ict_norm $resultTreeFolder "Normalize Ictal" $SPECTmessagebox }
    $this message [ list "Done Normalizing Ictal\n" "Ictal thresholded at 0.05 of their max value\n\n" ] $SPECTmessagebox
    
    #Subtracts ictal from the interictal
    set DiffSPECT [ ::mdImageUtil::Subtract $Ict_norm $objectArray(InterSPECTObj) ]
    $this message [ list "\nDone Computing Difference SPECT\n" ] $SPECTmessagebox
    $this saveInTree $DiffSPECT $resultTreeFolder "Subtraction_SPECT" $SPECTmessagebox
    
    $this finishMessage $SPECTmessagebox
}

#==========================================================================================

::itcl::body SPECTprocess::rejoinBlobs { } {
  
    $blobMessagebox clear
	
    if { [ $this checkForImage 6 hyperBlob "Hyperprefusion Blob" ] || [ $this checkForImage 7 hypoBlob  "Hypoprefusion Blob" ] } {
       	return -1
    }

    $blobMessagebox insert end "Blob Reconstruction\n---------------------\n"

    SPECTprocess::setResultFolder $imageArray(6) "ISAS Blob" 
 
    set reconstructedBlob [ ::mdImageUtil::Subtract $objectArray(hyperBlob) $objectArray(hypoBlob) ]
    $this saveInTree $reconstructedBlob $resultTreeFolder "reconstructedBlob" $blobMessagebox
 
    $this finishMessage $blobMessagebox
}
       
	
#-------------------------------------------------------------------------------------------------
#ISAScalcs does the "full monty". It normalizes, masked, and smooths the images before subtraction
#------------------------------------------------------------------------------------------------

# preprocessing for ISAS (reslice, mask, smooth, scales) 
# returns created mask for implicate masking and preprocessed SPECT 
::itcl::body SPECTprocess::preprocess { mode } {
    
    set smoothingSigma [ expr { [ $entryfieldArray(smooth) get ] / sqrt( 8 * log(2) ) } ] 

    #Reslice into MNI space
    if { [ string length $mode ] == 10 } {
	set inMNI [ $MainGUIObject ResliceImage $objectArray(STDdiffObj) $objectArray(InterSPECTObj) [ $this getTransform $imageArray(3) $imageArray(1) ] ]
    } else {
	set inMNI [ $MainGUIObject ResliceImage $objectArray(STDdiffObj) $objectArray(IctalSPECTObj) [ $this getTransform $imageArray(3) $imageArray(2) ] ] 
    }
    $this message [ list "\nDone Reslicing $mode SPECT" "\n$mode SPECT resliced into MNI space\n" ] $SPECTmessagebox    
    if { $parameters(saveprocessdata) } { $this saveInTree $inMNI $resultTreeFolder "Reslice_$mode" $SPECTmessagebox } 
   
    if { $parameters(useMask) } {
	#Mask the reslice spect with optional mask
	set inMNI [ ::mdImageUtil::Multiply $inMNI $objectArray(SPECTMaskObj) ]
	$this message [ list "\nDone Masking $mode SPECT\n" ] $SPECTmessagebox
	if { $parameters(saveprocessdata) } { $this saveInTree $inMNI $resultTreeFolder "Mask_$mode" $SPECTmessagebox }
    }
 
    #Gaussian smooth the spect default to 16 mm fwhm
    set smInMNI [ ::mdImageUtil::SmoothImage $inMNI $smoothingSigma ]
    $this message [ list "\nDone Smoothing $mode SPECT\n" ] $SPECTmessagebox 
    if { $parameters(saveprocessdata) } { $this saveInTree $smInMNI $resultTreeFolder "Smooth_$mode" $SPECTmessagebox }
 
    #propotional scaling to 50 
    set scale [ ::mdImageUtil::PropScale $smInMNI ]
    $this message [ list "\nDone Scaling $mode SPECT\n" ] $SPECTmessagebox 
    $this saveInTree [ lindex $scale 1 ] $resultTreeFolder "Preprocessed_$mode" $SPECTmessagebox
    
    return $scale
}

::itcl::body SPECTprocess::stats { ictal inter } {
    
    #subtracts Interictal SPECT from the Ictal SPECT
    set DiffSPECT [ ::mdImageUtil::Subtract $ictal $inter ]
    if { $parameters(saveprocessdata) } { $this saveInTree $DiffSPECT $resultTreeFolder "Diff_SPECT" $SPECTmessagebox }
    $this message [ list "\nDone Subtracting Ictal and Interictal SPECT\n" ] $SPECTmessagebox

    if { $parameters(saveprocessdata) } { $this saveInTree $objectArray(STDdiffObj)   $resultTreeFolder "STD SPECT"  $SPECTmessagebox }
    if { $parameters(saveprocessdata) } { $this saveInTree $objectArray(MeanSPECTObj) $resultTreeFolder "mean SPECT" $SPECTmessagebox }

    #Calculate the tmap for ISAS
    #H0 is the DiffSPECT - MeanSPECTObj = 0
    #Ha is the DiffSPECT - MeanSPECTobj != 0

    set tmap [ ::mdImageUtil::ComputeIndividualVsGroup $DiffSPECT $objectArray(STDdiffObj) 1 $objectArray(MeanSPECTObj) ] 
    #set tmap [ ::mdImageUtil::MultiplyByConstant $tmap 3 ] 
    $this saveInTree $tmap $resultTreeFolder "TMAP" $SPECTmessagebox 
    $this message [ list "\nDone calculating Tmap\n" ] $SPECTmessagebox

    return $tmap
}

::itcl::body SPECTprocess::clusterStats { mode } {
 
    if { [ $this checkForImage 8 TMAP "TMAP" ] } {
	 return -1
    }

    $this resetDisplayField

    set extentThreshold [ $entryfieldArray(extentThresh) get ]
    set sigLevel [ expr [ $entryfieldArray(significance) get ] * 2 ] 
    set tscore [ ::mdImageUtil::PvalueToTscore $sigLevel 13 ] 

    set eulerDensity [ ::mdImageUtil::eulerCharacteristicDensity $tscore [ $entryfieldArray(significance) get ] ]
    set reselCount   [ ::mdImageUtil::reselCount $objectArray(TMAP) 17.2 16.6 18.3 ]

    set expectedVoxPerCluster [ expr [ lindex $eulerDensity 0 ] / [ lindex $eulerDensity 3 ] ]  
    set expectedNumOfCluster 0.0
    for { set index 0 } { $index < 4 } { incr index } {
	set expectedNumOfCluster [ expr $expectedNumOfCluster + [ lindex $eulerDensity $index ] * [ lindex $reselCount $index ] ]
    } 
  
    set statList [ ::mdImageUtil::ComputeCluster $objectArray(TMAP) $expectedVoxPerCluster $expectedNumOfCluster $tscore $extentThreshold $mode ]
    $this displayStats $statList
}   

:::itcl::body SPECTprocess::saveStats { } {

    set typelist {
	{"text" {.txt}}
	{"All Files" {*}}
    }

    set filename [ tk_getSaveFile -filetypes $typelist ]
    if { ![ string length $filename ] } { return 0 }
    set fileid [ open $filename w ]
    puts $fileid "\n#Vxs\tuncorrPvalue \tcorrPvalue \tmaxTscore \tX \tY \tZ"
    for { set index1 1 } { $index1 < 10 } { incr index1 } {
	puts $fileid "\n$statDisplay($index1,0) \t$statDisplay($index1,1) \t$statDisplay($index1,2) \t$statDisplay($index1,3) \t$statDisplay($index1,4) \t$statDisplay($index1,5) \t$statDisplay($index1,5)"
    }
    close $fileid
} 

:::itcl::body SPECTprocess::displayStats { statList } {
    
    $this message [ list "\n\n#Vxs\tuncorrPvalue \tcorrPvalue \tmaxTscore \tX \tY \tZ" ] $SPECTmessagebox
    for { set index1 1 } { $index1 <= [ llength $statList ] && $index1 < 10 } { incr index1 } {
	$this message [ list "\n" ] $SPECTmessagebox
	for { set index2 0 } { $index2 < 7 } { incr index2 } {
	    set statDisplay($index1,$index2) [ lindex [ lindex $statList [ expr $index1 - 1 ] ] $index2 ]
	    $this message [ list "[ lindex [ lindex $statList [ expr $index1 - 1 ] ] $index2 ]\t" ] $SPECTmessagebox
	}
    }
}

::itcl::body SPECTprocess::resetDisplayField { } {
    for { set index1 1 } { $index1 < 10 } { incr index1 } {
	for { set index2 0 } { $index2 < 7 } { incr index2 } {
	     set statDisplay($index1,$index2) 0
	}
    }
}

::itcl::body SPECTprocess::ISAScalcs { } {
 
    if {    [ $this checkForImage 1 InterSPECTObj "Interictal SPECT" ] 
         || [ $this checkForImage 2 IctalSPECTObj "Ictal SPECT"      ]
         || [ $this checkForImage 3 MNIObj        "MNI Template"     ] } {
	     return -1
    }
    
    if { [ $this checkLoadImage ISAS_Mean_Diff_SPECT.nii.gz MeanSPECTObj ] } {
	return -1
    }

    if { [ $this checkLoadImage ISAS_Standard_Deviation.nii.gz  STDdiffObj ] } {
	return -1
    }
   
    if { $parameters(useMask) } {
	if { [ $this checkLoadImage ISAS_SPECT_Mask.nii.gz SPECTMaskObj ] } {
	    return -1
	}
    }

    $this message [ list "\nStarting ISAS calculations\n" ] $SPECTmessagebox
  
    $this setResultFolder $imageArray(3) "ISAS Results"
    
    set intPreprocessList [ $this preprocess "Interictal" ]
    set ictPreprocessList [ $this preprocess "Ictal" ]

    set stdMask [ ::mdImageUtil::threshold $objectArray(STDdiffObj) .01 10000 ]
    set mask    [ ::mdImageUtil::Multiply [ lindex $intPreprocessList 0 ]  [ lindex $ictPreprocessList 0 ] ]
    set mask    [ ::mdImageUtil::Multiply $mask $stdMask ]
    if { $parameters(saveprocessdata) } { $this saveInTree $mask $resultTreeFolder "Mask" $SPECTmessagebox }
  
    set preprocessIct [ ::mdImageUtil::Multiply [ lindex $ictPreprocessList 1 ] $mask ]
    set preprocessInt [ ::mdImageUtil::Multiply [ lindex $intPreprocessList 1 ] $mask ]
    set objectArray(MeanSPECTObj) [ ::mdImageUtil::Multiply $objectArray(MeanSPECTObj) $mask ]
    set objectArray(STDdiffObj)   [ ::mdImageUtil::Multiply $objectArray(STDdiffObj)   $mask ]
   
    #$this setResultFolder $imageArray(2) "ISAS Results"

    set tmap [ $this stats $preprocessIct $preprocessInt ]

    set blobs [ ::mdImageUtil::ComputeCluster $tmap ] 
    $this saveInTree [ lindex $blobs 0 ] $resultTreeFolder "Perfusion Blobs" $SPECTmessagebox 

    $this RVIEWcalcs
    $this finishMessage $SPECTmessagebox
}
 

::itcl::body SPECTprocess::bisCalcs { } {
 
    if {    [ $this checkForImage 1 InterSPECTObj "Interictal SPECT" ] 
         || [ $this checkForImage 2 IctalSPECTObj "Ictal SPECT"      ]
	 || [ $this checkForImage 3 MNIObj        "MNI Template"     ] } {
	 return -1
    }
       
    if { [ $this checkLoadImage  ISASHN_Standard_Deviation.nii.gz STDdiffObj ] } {
	return -1
    }

    if { $parameters(useMask) } {
	if { [ $this checkLoadImage ISAS_SPECT_Mask.nii.gz SPECTMaskObj ] } {
	    return -1
	}
    }

    $this message [ list "\nStarting ISASHN calculations\n" ] $SPECTmessagebox

    $this setResultFolder $imageArray(3) "ISASHN Results"

    set intPreprocessList [ $this preprocess "Interictal" ]
    set ictPreprocessList [ $this preprocess "Ictal" ]
    set objectArray(MeanSPECTObj) [ ::mdImageUtil::MultiplyByConstant $objectArray(STDdiffObj) 0 ]

    set stdMask  [ ::mdImageUtil::threshold $objectArray(STDdiffObj) .01 10000 ]
    set mask     [ ::mdImageUtil::Multiply [ lindex $intPreprocessList 0 ]  [ lindex $ictPreprocessList 0 ] ]
    set mask     [ ::mdImageUtil::Multiply $mask $stdMask ]
    if { $parameters(saveprocessdata) } { $this saveInTree $mask $resultTreeFolder "Mask" $SPECTmessagebox }

    set preprocessIct [ ::mdImageUtil::Multiply [ lindex $ictPreprocessList 1 ] $mask ]
    set preprocessInt [ ::mdImageUtil::Multiply [ lindex $intPreprocessList 1 ] $mask ]
    set objectArray(STDdiffObj)   [ ::mdImageUtil::Multiply $objectArray(STDdiffObj)   $mask ]

    set tmap [ $this stats $preprocessIct $preprocessInt ]

    set blobs [ ::mdImageUtil::ComputeCluster $tmap ] 
    $this saveInTree [ lindex $blobs 0 ] $resultTreeFolder "Perfusion Blobs" $SPECTmessagebox 

    $this RVIEWcalcs
    $this finishMessage $SPECTmessagebox
}
    


#------------------------------------------------------------------------------------------
# End Processing methods
#------------------------------------------------------------------------------------------

::itcl::body SPECTprocess::ShowTop { } {
    
    if { $basewidget == 0 } { 
	return 
    }
    
    
    if { [ winfo ismapped $basewidget ] == 1 } {
	raise $basewidget
	return $basewidget
    }
    
    wm deiconify $basewidget
    
    return $basewidget
}


# ---------------------------------------------------------------------------
# if called from the command line, start module in its own window
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    
    set thisSPECT [SPECTprocess \#auto]
    wm withdraw .
    
    $thisSPECT configure -IsSolo 1
    $thisSPECT Initialize .[pxvtable::vnewobj] 2
    $thisSPECT ShowTop
    
}  

