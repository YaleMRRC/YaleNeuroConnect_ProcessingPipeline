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

package provide bis_treegui 1.0

#---------------------------------------------------------------------------------------------
#Import of required packages and other required initialization defs
#---------------------------------------------------------------------------------------------
# This package sets the required paths
lappend auto_path [file dirname [info script]]

package require pxitclchellypackages 1.0
package require pxitclfilelistmenu   1.0
package require dsitcltree           1.0
package require bis_guiimageutility  1.0

package require bis_resliceimage        1.0
package require bis_guitreeimageutility 1.0
package require bis_guitreecreate4d     1.0                    
#------------------------------------------------------------------------------------------

package require VisTree2;        #This is the "Tcl only" Tree widget that handles the tree display


# Optional Modules - require if files are present in packages directory
if {[file exists [ file join [ file dirname [ info script ] ] packages AtlasProg.tcl]]} {
      package require AtlasProg;       #This is the atlas lookup package
}

# Optional Modules - require if files are present in packages directory
if {[file exists [ file join [ file dirname [ info script ] ] packages SPECTtools.tcl]]} {
    package require SPECTProcessProg;       #This is the atlas lookup package
}

if {[file exists [ file join [ file dirname [ info script ] ] packages AdvancedRegTools.tcl]]} {
    package require AdvancedRegTools;       #This is the atlas lookup package
}


if {[file exists [ file join [ file dirname [ info script ] ] packages ElectrodeAttrProg.tcl]]} {
    package require ElectrodeAttrProg;       #This is the atlas lookup package
}

# Require key packages
package require Itcl
package require Iwidgets

# Xenios' C++ Extensions
package require vtkpxcontrib     1.0

# Simple Naming package  [ pxvtable::vnewobj ]
package require pxvtable         1.0

# Wrappers around vtkImageData and vtkAbstractTransform
package require pxitclimage              1.0
package require pxitcllandmarks          1.0
package require pxitclelectrodemultigrid 1.0
package require pxitcltransform          1.0

::itcl::class bis_treegui {
    

    #inherit bis_treeguibase
    #Note: throughout this class, Image 2 is the Image to Be Resliced into the Space of
    #Image 1, which is sometimes referred to as Base Image
    public variable nodeInfoBox ""
    
    #Class Data Members
    
    #----------------------------------------------------
    #---------Module Enable/Disable Options--------------
    public variable enable_atlas 0
    public variable enable_SPECT 1
    public variable enable_AdvancedReg 1
    public variable enable_elec_att 1
    #----------------------------------------------------

    public variable relativePath 1;
    public variable FileManager 0;         #This is the FileManager Object (an instance of a child of chellyDB)

    #Package Variables
    public variable AtlasModule 0;         #This is the Atlas Lookup program 
    public variable AtlasRefFilename -1;   #This is the filename of the reference image for the atlas
    public variable SPECTmodule 0;         #This is the SPECT processing program
    public variable SPECT_initialized 0;   #Has the SPECT tool been initialized?
    public variable REGmodule 0;         #This is the REG processing program
    public variable REG_initialized 0;   #Has the REG tool been initialized?


    public variable ElectAttrModule 0;     #This is the Electrode Attribute Selector Program
    #--------------------------------------------------
    public variable clipBoardTree; #This is the temporary serialized tree, for cutting and pasting

    public variable mdTopWidget
   
    public variable menucolor; # color for the top menu
    public variable menuactivebgcolor; # active background for top menu
    public variable leftpane
    public variable midpane
    public variable rightpane
    public variable treeframe 
    public variable descriptionbox
    public variable hasatlastool 1
    public variable toolsmenu 0

    public variable TreeChanged 0

    public variable SurgeryMode 0; # Disables some options
    public variable SpaceLocked 0; # Locks SpaceImage

    public variable brainiconchoice "ibrainpurple"
    public variable surfaceiconchoice "ibrainyellow"
    public variable resulticonchoice "ibrainred"
    public variable atlasiconchoice "ibrainrainbow"
    public variable roiiconchoice "ibrainorange"

    public variable reslmode Linear

    public variable IC;   #This is the canvas widget in the middle pane
    public variable rbX
    public variable rbY
    public variable abX
    public variable abY
    public variable fbX
    public variable fbY
    public variable REF_AnatomicalImage 0
    public variable REF_FunctionalImage 0

    public variable OCanv -1; #This varible will point to the canvas in the overlay tab
    public variable OCdispX
    public variable OCdispY

    protected variable surgerygadget 0
    protected variable mdmenubar

    public variable SpaceImage -1
    public variable AnatomicalImage -1
    public variable FunctionalImage -1
    public variable AtlasImage -1
    
    variable RecognizedTypes
    variable PatientProperties ""
    variable RealTree; # This is the main tree array
    variable TransformsCache
    variable NodeIDs
    variable statusbar
    variable statusLabel
    variable vistree
    variable popup
    variable surfacepopup
    variable electrodepopup
    variable folderpopup
    variable patientpopup
    variable rootpopup
    variable rightpanelpopup
    
    variable NodeInfoDialogName ""

    variable mdEntries 
    variable RecognizedTypesChecks
    variable dialogEntries ""
    variable RecogTypeDialogName -1
    variable showGrabButtonDialogName -1
    variable SearchDialogName -1

    variable PatientPropDialogName -1
    variable PatientProperty_selectionbox1 -1
    
    variable ImageThresholdForROICalcs
    variable threshDialog

    variable SearchResultList ""
    variable titlequery ""
    variable FinalResultList ""
    variable ResultDisplay
    variable foldersearchselbox
    variable folderchoicearray
    variable foldersearchboxlist
    variable folderbox
    
    public variable viewer1 0
    public variable viewer2 0
    public variable electrodecontrol1 0
    public variable electrodecontrol2 0
    public variable overlaycontrol 0
    public variable myname 0
    
    protected variable dragAndDropEnabled 1    
    public variable undoList ""
    protected variable theNoCursor

    protected variable spaceImageList ""
    protected variable anatomicalImageList ""
    protected variable functionalImageList ""
    
    public variable dustin
    public variable selectionPath ""

    public method getTree          { } { return $dustin }
    public method getSelectionPath { } { return $selectionPath }

    # Switch Directory
    public method SwitchDirectory { { newdir ""  } }

    #---------------
    #private methods
    #---------------
    public method drawFuncSpaceArrow { color }
    public method drawAnatSpaceArrow { color } 

    public  method findTransforms { node1 node2 direction }
    private method commonAncestor { realtreename node1 node2 }
    public  method setNodeFilename { node {filename -1}}
    private method setNodeTransformToParFile { node {filename -1}}
    private method setNodeTransformFromParFile { node {filename -1}}
    public  method toggleIdentity { node {explicitSetting -1}}
    
    private method checkForIllegalCharacters { inputName }
    private method getPath {realtreename ImageID}
    private method nodeName { node }
    private method getNodesOfTransformation { trans }    
    
    #--------------
    #public methods
    #--------------
    public method GetThisPointer { } { return $this }
  
    public method AddPatient {realtreename ParentNodeID {title -1}}
    public method AddImage {realtreename ParentNodeID {title -1} {type -1}}
    public method AddSubtree { {treeObj ""} { parentNode "" } }
    public method AddMSBData {  realtreename ParentNodeID {title -1} {ListedTree -1} }
    public method AddCSIPatient { realtreename ParentNodeID {title -1} {ListedTree -1}} 
    public method AddAllCSI { realtreename  ParentNodeID }
    public method addSubtreeAtSelection { {type 1} }

    public method OnWidgetClose { }

    #This forces an update of the visualization tree with the contents of the real data tree
    public method updateBigTransLines { } 
    public method updateOverlayCanvas { }
    public method updateRightCanvasDisplay { }

    #Here are some methods to send/receive surfaces to/from the viewers (surfaces, landmarks, electrodes)
    #------------------------------------------------------------------------------------------
    public method sendSelectionToDisplay { viewerNumber node { inRefSpace 0 } } 
    public method checkSpaceImageExsist { }
    public method displayImage      { viewerNumber imageNode inRefSpace {background 0} }
    public method setViewer   { viewerNumber }
    public method setElectrodeViewer { econtrolNumber }
    public method displaySurface    { viewerNubmer surfaceNode inRefSpace }
    public method setNodeObject { node }
    public method reslice { spaceNode imageNode transform }  
    public method resliceSetOverlayInputs { }
    public method getReslicedImage { spaceNode imageNode }
    
    #These grab the images from the viewers
    public method PutViewerObjectInTree { viewerno objtype }
    
    public method GrabViewerImage { viewerno }
    public method GrabViewerSurface { viewer }
    public method GrabViewerLandmark { viewer } 
    public method GrabViewerElectrode { electrodecontrolno }

    public method grabElectrodeAttributes { electrodecontrolno }
    
    
    #methods to create the total concatenated transformation and export it
    public method CreateTransformation { listoftransforms }
    public method sureTransLoad { transobjname }
    
    #User I/O methods
    public method showButtonToolBar {mdTopWidget {args}}
    public method showGrabButtonDialog { }
    public method Single_Entry_Dialog {title msgstring {defstring ""}}
    public method ImageEntryDialog { }
    public method createNodeInfoGUI { } 
    public method showNodeInfoBox { }
    public method updateGUI { }
    public method updateNotes { }

    public method GetIDFromSelection { args }
    public method IsNodeImage { node {treename -1} {broad 0}}
    public method IsNodeSurface { node {treename -1} }

    #button click methods and related helper methods
    public method bindxrelease1 { W x y mode }
    public method bindxmotion1 { W x y } 
    public method bindx1 { W x y }
    public method isCurrentAChildOfSelection { currentPath selectionPath W }
    public method isCurrentTheParentOfSelection { currentPath selectionPath W }
    public method bindxcontrol1 { W x y }
    public method bindxdouble1 { W x y }
    public method bindx3 { W x y }
    public method bindxRightPane { W x y menu }  
    public method bindRightPaneTest { W x y text }
    public method setCurrent { W x y }
    public method setSelection { W x y }
    public method bindxControlX { W K N }
    public method bindxControlC { W K N }
    public method releaseOnTreeCut { W x y }
    public method releaseOnTreeCopy { W x y }
    public method releaseOnImagesTab { x y }
    public method displayMarkerOnImageTab { W x y }

    public method NodeInfoDialog { } 
    public method updateNodeDialogField  { entry function node item} 
    public method updateAllNodeDialogFields {entries node items}
    public method updateNodeNotes { realtreename node text dialogname} 
    public method setPatientProperty { property entryfield }
    
    public method ShowMidpaneTools { parent } 
    public method OCanvasInitialize { parent }
    public method ShowManager {pw surgerygadget0 menubase };#This is the most imporatant method
    public method ShowTextBox { parent }
    
    #methods that deal with event bindings, menus and such
    public method makeFileMenu { menu0 }
    public method makeEditMenu { menu0 }
    public method makeToolsMenu { menu0 }
    public method makeImageMenu { menu0 }
    public method makeSurfaceMenu { menu0 }
    public method makeFolderMenu { menu0 } 
    public method makeElectrodeMenu { menu0 }
    public method makePatientMenu { menu0 }
    public method makeDataMenu { menu0 }
    public method makeAtlasMenu { menu0 }
    public method makeOptionsMenu { menu0 }
    public method makeViewMenu { menu0 }
    public method makeColorMenu { colormenu icon }
    public method menuActivation { menu menutype }
    
    public method addNodeToTree { type { title "" } { path "" }}
    public method addPatientToTree { }
    public method addSubtree { {treeObj ""} { parentNode "" } } 
    
    public method mdLoadElectrodeAttributes { }


    public method delSelectedFromTree { }
    
    public method setSelectionSpace { }
    public method setSelectionAnatomical { }
    public method setSelectionFunctional { }
    


    
    public method nameNode {realtreename node newtitle } 
    #----------------------------------------
    
    
    #Atlas Module methods--------------------
    public method addAtlasToTree { }
    public method AddAtlasNode { realtreename ParentNodeID {title -1}} 
    public method AtlasInitialize { realtreename node }  
    
    public method ShowAtlas { } { $AtlasModule ShowTop }
    public method AtlasShowSelectedNode { }
    public method SendImageToAtlasModule { { nodeID -1} {raise 1}} 
    public method BringUpAtlasModule { } 
    #----------------------------------------

    #SPECT Processing Tool methods-----------
    public method ShowSPECTtool { }
    public method ShowREGtool { }
    #----------------------------------------

    #ElectrodeAtrribute Module methods-------
    public method SendElectrodeToAtrrControl { { nodeID -1} {raise 1} }
    public method PutElectrodeAttrControlOutputInTree { }
    #----------------------------------------
    
    #ROI Defintion methods-------------------
    public method addROIDefToTree { }
    public method AddROIDefNode { realtreename ParentNodeID {title -1}}
    public method ROIDefInitialize { realtreename node }
    #----------------------------------------
    
    #Search Module methods-------------------
    public method SearchDialog { }
    public method SearchGetFolder { }
    public method FolderSelectionInsert { }
    public method SearchCallback { dialog command }
    public method doSearch { dialog }
    
    #Method to enable searching of the tree for a given characteristic
    public method SearchTree { realtreename startnode key args }
    
    public method SaveAllInRef { {listofnodes -1} }
    public method sendAllToCommonSpace { spacenode imagelist } 
    public method ComputeAverages { imagelist filename { background -32767 } } 
    public method ComputeTscoreMap { immean imvar numsubjects }
    public method ComputeROIStatistics  { functional_input roi_image_input { threshold none } } 
    public method MultipleROI { imagelist } 
    public method ThresholdLevelDialogCallback { } 
    #----------------------------------------
    
    #Subject Property List editor dialog-----
    public method EditPatientPropList { }
    public method PatientPropDialogCallback { command }
    #----------------------------------------

    #Recognized type setter module-----------
    public method showRecognizedTypes { array }
    public method recognizedTypeDialogCallback { dlg mode }
    public method setRecognizedTypes { }
    #----------------------------------------
    
    #----------------------------------------
    #Cut/Copy/Paste methods
    public method mdCopy { {cut 0} {parentNode ""} }
    public method mdPaste { { parentNode "" } }
    public method undo { }
    public method redo { }
    public method setUndoList { }
    #----------------------------------------

    #-----------------------------
    # Added Methods to handle Save/Load 
    #------------------------------
    public method mdSaveTree { }
    public method mdNewTree { }
    public method saveReorganize { }
    public method mdLoadTree { {filename ""} }
    public method mdGetTreeFileName { } {
	array set AddedTreeDefArray $ListedTree
	return $TreeDefArray(ThisFileName)
    }

    public method mdSaveTypeDefs { }
    public method mdLoadTypeDefs { }
   
    public method updateTreeWidget { {nodeID ""}}
    public method dsrevertGUI {}
    public method displayFileName {}
    public method setDisplayBox { nodePath }
    public method getIcon { nodePath }
    public method getLineColor { nodePath }
    public method isRoot { nodeID }
    public method printTree { } 
    public method makeTransformList { refNode transNode }
    public method combineTransforms { transformList }
    #constructor

    public method setTitle           { } 
    public method setFileName        { { name "" } } 
    public method setTransFromParent { }
    public method setTransToParent   { }
    public method setIdentityToggle  { }
    public method clearTrans         { item }

    public method showImageProcessTool { }

    constructor { args } {

	global tcl_platform
	
	set thisfolder [ file dirname [ info script ] ]

	if { $tcl_platform(platform) == "unix" } {
	    set theNoCursor [ list @$thisfolder/no.xbm black ]
	} elseif { $tcl_platform(platform) == "windows" } { 
	    set theNoCursor "no" 
	} else {
	    set theNoCursor "boat" 
	}

	#-------------------------------------------------------------------------------------------------------
	# Optional Module Loading
	#-------------------------------------------------------------------------------------------------------
	
	# The Atlas Tool
	#-------------------------------------------------------------------------------------------------------
	if {![file exists [ file join [ file dirname [ info script ] ] packages AtlasProg.tcl]]} {
	    set enable_atlas 0
	}
	if {$enable_atlas == 1} {
	    set AtlasModule [AtlasTool \#auto] 
	    $AtlasModule configure -folderpath [ file join [ file dirname [ info script ] ] packages AtlasDefImages]
	    $AtlasModule Initialize .[pxvtable::vnewobj]
	}
	#-------------------------------------------------------------------------------------------------------
	
	#The SPECT Processing Tool
	#-------------------------------------------------------------------------------------------------------
	if {![file exists [ file join [ file dirname [ info script ] ] packages SPECTtools.tcl]]} {
	    set enable_SPECT 0
	}
	if {$enable_SPECT == 1} {
	    set SPECTmodule [SPECTprocess \#auto]
	}
	#-------------------------------------------------------------------------------------------------------

	#The Advanced Registration Tool
	#-------------------------------------------------------------------------------------------------------
	if {![file exists [ file join [ file dirname [ info script ] ] packages AdvancedRegTools.tcl]]} {
	    set enable_AdvancedReg 0
	}
	if {$enable_AdvancedReg == 1} {
	    set REGmodule [ AdvancedReg \#auto]
	}
	#-------------------------------------------------------------------------------------------------------


	#The ElectrodeAttribute Tool
	#-------------------------------------------------------------------------------------------------------
	if {![file exists [ file join [ file dirname [ info script ] ] packages ElectrodeAttrProg.tcl]]} {
	    set enable_elec_att 0
	}
	if {$enable_elec_att == 1} {
	    set ElectAttrModule [ElectrodeAttr \#auto]
	    $ElectAttrModule Initialize .[pxvtable::vnewobj] [::itcl::scope RealTree] $this
	}
	#-------------------------------------------------------------------------------------------------------

	#-------------------------------------------------------------------------------------------------------
	#End of optional module loading
	#-------------------------------------------------------------------------------------------------------
	
	#--------------------------------------------------
	#Initialize a default array of recognized types
	set RecognizedTypes(10)   "Common Space"
	set RecognizedTypes(1000) "3D Anatomical MR"
	set RecognizedTypes(7100) "Post-op MR"
	set RecognizedTypes(7200) "Post-op CT"
	set RecognizedTypes(8000) "Interictal SPECT"
	set RecognizedTypes(8100) "Ictal SPECT"
	set RecognizedTypes(8200) "Differential SPECT"
	set RecognizedTypes(3000) "PET-FDG"
	set RecognizedTypes(9000) "CSI Scout"
	set RecognizedTypes(9100) "CSI Raw Data"
	set RecognizedTypes(9200) "CSI PMAP"
	set RecognizedTypes(4000) "fMRI Scout - Conventional 2D"
	set RecognizedTypes(4100) "Spin-Echo Echoplanar"
	set RecognizedTypes(4050) "Field Map"
	set RecognizedTypes(4200) "fMRI Motor Task"
	set RecognizedTypes(4300) "fMRI Language Task"
	set RecognizedTypes(4400) "fMRI Sensory Task"
	#--------------------------------------------------

	#--------------------------------------------------
	#Initialize a default list of patient parameters
	set PatientProperties [list Sex Age Weight Height IQ Cholesterol {Fat percentage} BP]
	#--------------------------------------------------

   }
    
    #destructor
    destructor { 
	foreach item $undoList {
	    ::itcl::delete Object $item
	}
	::itcl::delete Object $dustin
    }
    
    
};#End bis_treegui class


#------------------------------------------------------------------------------------------
#Method defs for class bis_treegui
#------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------
itcl::body bis_treegui::SwitchDirectory { { dirname "" } } {

    if { $dirname == "" } {
	set dirname  [tk_chooseDirectory -title "Select Current Directory" ]
    }
    
    if {![string length $dirname]} {return 0}
    
    cd $dirname
}


::itcl::body bis_treegui::OnWidgetClose { } { 
    
    if { $TreeChanged == 0 } { $surgerygadget ExitCommand; return }
    
    set answer [tk_messageBox -type yesnocancel -default yes -message \
	   "The tree has changed since it was last saved.  Would you like to save it before exiting?" -icon question] 
    
    if { $answer == "cancel" } { return }
    
    if { $answer == "yes" } {
	mdSaveTree 
    }

    pxtkexit
}

::itcl::body bis_treegui::Single_Entry_Dialog {title msgstring {defstring ""}} {

    #defstring is the default entry in the dialog

    global Single_Entry_Dialog_Result ""

    iwidgets::promptdialog .sed -modality application -title $title -modality application \
	-labeltext $msgstring -labelpos s
    .sed hide Apply

    .sed buttonconfigure OK -command { set Single_Entry_Dialog_Result [.sed get]; .sed deactivate }
    .sed buttonconfigure Cancel -command { set Single_Entry_Dialog_Result ""; .sed deactivate }

    .sed insert 0 $defstring
    .sed selection range 0 end
  
    focus [.sed component prompt component entry]
    .sed center
    update idletasks
    .sed activate

    destroy .sed
    
    return $Single_Entry_Dialog_Result
}

::itcl::body bis_treegui::ImageEntryDialog {} {
    
    global ImageDialogEntryResult ""
    
    iwidgets::selectiondialog .selbox -borderwidth 2 -height 200 \
	-labelfont -Adobe-Helvetica-Bold-R-Normal--*-140-*-*-*-*-*-* \
	-title "Add a Child Image" \
	-textbackground ghostwhite -itemslabel "Select an Image Type:" \
	-selectionlabel "or Specify a Custom Image Type:"
    
    #This just makes sure that they are displayed sorted by type key (which is not seen by the user)
    foreach index [array names RecognizedTypes] {
	lappend typekeyz $index
    }
    set typekeyz [lsort -integer $typekeyz]
    
    for {set tx 0} {$tx < [llength $typekeyz]} {incr tx} {
	lappend imagetypes $RecognizedTypes([lindex $typekeyz $tx])
    }
    
    eval .selbox insert items 0 $imagetypes
    .selbox hide Apply
    .selbox center
    .selbox configure -modality application
    .selbox buttonconfigure OK -command {set ImageDialogEntryResult [.selbox get]; .selbox deactivate }
    .selbox buttonconfigure Cancel -command {set ImageDialogEntryResult ""; .selbox deactivate }
    
    update idletasks
    .selbox activate
    
    destroy .selbox
    
    return $ImageDialogEntryResult
 }

::itcl::body bis_treegui::drawAnatSpaceArrow { color } {
    
    $IC create line [expr $rbX - 13] [expr $rbY + 50] \
	[expr $rbX - 55 ] [expr $rbY + 55] \
	[expr $abX + 35 ] [expr $abY - 85] \
	[expr $abX + 50 ] [expr $abY - 8] \
	-tag Anat2Space -smooth true  -splinesteps 20 -width 12 \
	-arrow first -arrowshape {15 18 8} -fill $color
}

::itcl::body bis_treegui::drawFuncSpaceArrow { color } {

    $IC create line [expr $rbX + 150] [expr $rbY + 50] \
	[expr $rbX + 190] [expr $rbY + 55] \
	[expr $fbX + 95 ] [expr $fbY - 85] \
	[expr $fbX + 80 ] [expr $fbY - 8] \
	-tag Func2Space -smooth true  -splinesteps 20 -width 12 \
	-arrow first -arrowshape {15 18 8} -fill $color
}

#------------------------------------------------------------------------------------------
# Private methods of bis_treegui
#------------------------------------------------------------------------------------------

::itcl::body bis_treegui::updateBigTransLines { } {

    set anatomcialColor grey80; set functionalColor grey80
    $IC delete Anat2Space Func2Space
   
    if { [ llength $spaceImageList ] && [ llength $anatomicalImageList ] } {
	if { [ makeTransformList [ lindex $spaceImageList 0 ] [ lindex $anatomicalImageList 0 ] ] == 0 } { 
	    set anatomcialColor red
	} else {
	    set anatomcialColor green
	}
    }
	    
    if { [ llength $spaceImageList ] && [ llength $functionalImageList ] } {
	if { [ makeTransformList [ lindex $spaceImageList 0 ] [ lindex $functionalImageList 0 ] ] == 0 } { 
	    set functionalColor red
	} else {
	    set functionalColor green
	}
    }
    drawFuncSpaceArrow $functionalColor
    drawAnatSpaceArrow $anatomcialColor 
}

::itcl::body bis_treegui::updateRightCanvasDisplay { } {

    #Clear all
    catch {$IC delete refPIC};    $IC delete refTEXT
    catch {$IC delete anatomPIC}; $IC delete anatomTEXT
    catch {$IC delete funcPIC};   $IC delete funcTEXT
    
    #--Anatomical Image------------------------------------------------------------------------------
    if { [ llength $anatomicalImageList ] } {
	set anatomicalcolorbrainPIC [$IC create image $abX $abY -image multicolorbrain -anchor nw -tag anatomPIC]
	set anatomicalbrainTEXT  [$IC create text [expr $abX+65] [expr $abY+52] -text "[ lindex $anatomicalImageList 1 ]" \
				      -fill white -activefill yellow -font {helvetica 15 bold} -tag anatomTEXT -width 150]
    } else {
	set anatomicalbrainTEXT  [$IC create text [expr $abX+65] [expr $abY+52] -text "Not Set" \
				      -fill grey61 -font {helvetica 15 bold}  -activefill yellow -tag anatomTEXT]
    }
    #-------------------------------------------------------------------------------------------------
    
    #--Functional Image------------------------------------------------------------------------------
    if { [ llength $functionalImageList ] } {
	set funccolorbrainPIC [$IC create image $fbX $fbY -image multicolorbrain -anchor nw -tag funcPIC]
	set funcbrainTEXT  [$IC create text [expr $fbX+65] [expr $fbY+52] -text "[ lindex $functionalImageList 1 ]"\
				-fill white -activefill yellow -font {helvetica 15 bold} -tag funcTEXT -width 150]
    } else {
	set funcbrainTEXT  [$IC create text [expr $fbX+65] [expr $fbY+52] -text "Not Set" \
				-fill grey61 -activefill yellow -font {helvetica 15 bold} -tag funcTEXT]
    }
    #-------------------------------------------------------------------------------------------------
    
    #--Space Image------------------------------------------------------------------------------
    if { [ llength $spaceImageList ] } {
	set refcolorbrainPIC [$IC create image $rbX $rbY -image multicolorbrain -anchor nw -tag refPIC]
	set refbrainTEXT  [$IC create text [expr $rbX+65] [expr $rbY+52] -text "[ lindex $spaceImageList 1 ]" \
			       -fill white -activefill yellow -font {helvetica 15 bold} -tag refTEXT -width 150]	
    } else {
	set refbrainTEXT  [$IC create text [expr $rbX+65] [expr $rbY+52] -text "Not Set" \
			       -fill grey61 -activefill yellow  -font {helvetica 15 bold} -tag refTEXT]
    }
    #------------------------------------------------------------------------------------------------
    updateBigTransLines
}

::itcl::body bis_treegui::undo { } {

    if { [ llength $undoList ] < 1 } { return }
    itcl::delete object $dustin
    set dustin [ [ dsitcltree \#suto ] GetThisPointer ]
    $dustin copyTree [ lindex $undoList 1 ]
    lappend undoList [ lindex $undoList 0 ]
    set undoList [ lrange $undoList 1 end ]
    
    updateTreeWidget /Data
    setDisplayBox    /Data
}

::itcl::body bis_treegui::redo { } {

    if { [ llength $undoList ] < 1 } { return }
    itcl::delete object $dustin
    set dustin [ [ dsitcltree \#suto ] GetThisPointer ]
    $dustin copyTree [ lindex $undoList end ]
    set undoList [ linsert $undoList 0 [ lindex $undoList end ] ]
    set undoList [ lrange  $undoList 0 end-1 ]
  
    updateTreeWidget /Data
    setDisplayBox    /Data
}

::itcl::body bis_treegui::setUndoList { } {

    set tmpTree [ [ dsitcltree \#auto ] GetThisPointer ]
    $tmpTree copyTree $dustin
    set undoList [ linsert $undoList 0 $tmpTree ]
}

::itcl::body bis_treegui::addSubtree { {treeObj ""} { parentNode "" } } {

    set delete 0
    if {$treeObj == ""} {
	set treeObj [ [ dsitcltree \#auto ] GetThisPointer ]
	$treeObj readDatatree
	set delete 1
    }
    
    if { $parentNode == "" } {
	set parentNode $selectionPath 
    }

    $dustin addSubTree $treeObj $parentNode
    if { $delete } {  itcl::delete object $treeObj }
    updateTreeWidget $parentNode
    setUndoList; set TreeChanged 1
}

# for findtransfrom node2 is an ancestor of node1
::itcl::body bis_treegui::findTransforms { node1 node2 direction } {

    set transformList ""
    while { $node1 != $node2 } {
	set trans [ $dustin getNodeTrans$direction $node1 ]

	if { $trans == "" } {
	    return 0
	}

	if { $trans == 1 } { 
	    set node1 [ $dustin getNodeParent $node1 ]
	} else {
	    set newtr [ [pxitcltransform \#auto ] GetThisPointer  ]
	    if {[ regexp {linear.nosave$} $trans ]} {
		set ut [ vtkpxTransformationUtil [ pxvtable::vnewobj ]]
		$newtr CopyTransformation [ $ut LoadAbstractTransform [ $dustin getNodeTransFromParent $node1 ] ]
		$ut Delete
		$newtr Invert
		puts "inverting transform"
	    } else {
		set ut [ vtkpxTransformationUtil [ pxvtable::vnewobj ]]
		$newtr CopyTransformation [ $ut LoadAbstractTransform [ $dustin getNodeTrans$direction $node1 ] ]
		$ut Delete
	    }
	    lappend transformList $newtr
	    set node1 [ $dustin getNodeParent $node1 ]
	}
    }
   
    return $transformList
}
    
#input is two nodes
#returns 0 if no transform exsist between the nodes or the nodes are the same
#return a list of transform objects starting at the transnode and ending at the refnode
::itcl::body bis_treegui::makeTransformList { refNode transNode } {
    
    set ancestor [ $dustin getCommonAncestor $refNode $transNode ]

    # determine which direction the transforms must be applied 
    #surfaces are reversed from images
    if { [ $dustin getNodeType $transNode ] == "Image" } {
	set directionList [ list FromParent ToParent ]
    } else { set directionList [ list ToParent FromParent ]}

    set transformList  [ findTransforms $transNode $ancestor [ lindex $directionList 0 ] ]
    set transformList2 [ findTransforms $refNode   $ancestor [ lindex $directionList 1 ] ]

    if { $transformList == 0 || $transformList2 == 0 } {
	return 0
    }

    for { set index 0 } { $index < [ llength $transformList2 ] } { incr index } {
	lappend transformList [ lindex $transformList2 $index ] 
    }

    return $transformList
}

#take in a proposed title for a node
#give an error and return 0 if an illegal char exists
::itcl::body bis_treegui::checkForIllegalCharacters { inputName } {
    
    if {[ regexp {[^A-Za-z0-9\^\-\_\.\s]} $inputName illegalChar ]} {
	
	set warning "Cannot rename node using character $illegalChar  -- Node names can only can contain the following characters: \n     a-z, A-Z, 0-9, _, -, ., ^, and spaces."
	
	tk_messageBox -type ok -title "Please choose a new name" -message $warning -icon error
	return 0
    } 
    return 1
}   
    
::itcl::body bis_treegui::sendSelectionToDisplay { viewerNumber node { inRefSpace 0 } } {
    
    switch -exact -- $node {
	
	"SpaceImage" {
	    set node [ lindex $spaceImageList 0 ]
	    set inRefSpace 0
	}
	
	"AnatomicalImage" {
	    set node [ lindex $anatomicalImageList 0 ]
	    set inRefSpace $REF_AnatomicalImage
	}
	
	"FunctionalImage" {
	    set node [ lindex $functionalImageList 0 ]
	    set inRefSpace $REF_FunctionalImage
	}	
	
	default {
	    set node $selectionPath
	}
    }
    
    switch -exact -- [ $dustin getNodeType $node ] { 
	
	"Image"     { displayImage     $viewerNumber $node $inRefSpace }
	"Surface"   { displaySurface   [ setViewer          $viewerNumber ] $node $inRefSpace }
	"Landmark"  { displaySurface   [ setViewer          $viewerNumber ] $node $inRefSpace }
	"Electrode" { displaySurface   [ setElectrodeViewer $viewerNumber ] $node $inRefSpace }
    }
}

::itcl::body bis_treegui::setNodeObject { node } {

    if { [ $dustin getNodeImageObject $node ] != "" } { return 0 }

    switch -exact [ $dustin getNodeType $node ] {
	"Image"     { set img [ [ pxitclimage              \#auto ] GetThisPointer ] }
	"Surface"   { set img [ [ pxitclsurface            \#auto ] GetThisPointer ] }
	"Landmark"  { set img [ [ pxitcllandmarks          \#auto ] GetThisPointer ] }
	"Electrode" { set img [ [ pxitclelectrodemultigrid \#auto ] GetThisPointer ] }
    }
    
    $img Load "[ $dustin getNodeFileName $node ]"
    $dustin setNodeImageObject $img $node 
}

::itcl::body bis_treegui::checkSpaceImageExsist { } {
    
    if { $spaceImageList == "" } { 
	tk_messageBox -type ok  -title "Cannot Reslice" -message "space image is not set" -icon error
	return 1
    } else { return 0 }
}

::itcl::body bis_treegui::displayImage { viewerNumber imageNode inRefSpace {background 0} } {
   
    if { ![ file exists [ $dustin getNodeFileName $imageNode ] ] } { 
	tk_messageBox -type ok  -title "Cannot open image" -message "File does not exist" -icon error
	return 0
    }
   
    if { $viewerNumber == 1 } { set viewer $viewer1 } else { set viewer $viewer2 }
	
    setNodeObject $imageNode

    if { [ expr !$inRefSpace ] } {
	$viewer SetImageFromObject [ $dustin getNodeImageObject $imageNode ] $this
	$viewer ShowWindow
	return 0
    }
    
    if { [ checkSpaceImageExsist ] } { return 0 } 

    set spaceNode [ lindex $spaceImageList 0 ]
    setNodeObject $spaceNode
    
    set transformList [ makeTransformList $spaceNode $imageNode ]
    if { $transformList == 0 } {
	tk_messageBox -type ok  -title "Cannot open image" -message "Transformation is missing" -icon error
	return 0
    }

    if { ![ llength $transformList ] } {
	$viewer SetImageFromObject [ $dustin getNodeImageObject $imageNode ] $this
	$viewer ShowWindow
	return 0
    }

    set transform [ combineTransforms $transformList ]

    set reslicedImg [ $this reslice $spaceNode $imageNode $transform ]
    itcl::delete object $transform

    $viewer SetImage $reslicedImg 
    $viewer ShowWindow
    itcl::delete object $reslicedImg
}

::itcl::body bis_treegui::reslice { spaceNode imageNode transform } {
 
    set reslice_alg [ bis_resliceimage   [ pxvtable::vnewobj ] ]

    $reslice_alg InitializeFromContainer $this			
    $reslice_alg SetInput                [ $dustin getNodeImageObject $spaceNode ]
    $reslice_alg SetSecondInput          [ $dustin getNodeImageObject $imageNode ]
    $reslice_alg SetTransformation       $transform
    $reslice_alg SetOptionValue          interp $reslmode
    $reslice_alg Execute
    
    #set output [ [ pxitclimage \#auto ] GetThisPointer ]
    #$output ShallowCopy [ $reslice_alg GetOutput ] 
    #$output Save "test.hdr"
    #itcl::delete object $reslice_alg
    #return $output
    return [ $reslice_alg GetOutput ] 
}

::itcl::body bis_treegui::resliceSetOverlayInputs { } {

    if { [ checkSpaceImageExsist ] } { return 0 }
    set spaceImage [ lindex $spaceImageList 0 ]
    setNodeObject $spaceImage 

    if { $anatomicalImageList != "" } { 
	set anatomicalImage [ lindex $anatomicalImageList 0 ]
	setNodeObject $anatomicalImage
	set reslicedAnatomicalImage [ getReslicedImage $spaceImage $anatomicalImage ]
	set input1 1
    }  else { set input1 0 }
   
    if { $functionalImageList != "" } { 
	set functionalImage [ lindex $functionalImageList 0 ]
	setNodeObject $functionalImage
	set reslicedFunctionalImage [ getReslicedImage $spaceImage $functionalImage ]
	set input2 1
    } else { set input2 0 }
 
    if { $input1 && $input2 } {
	$surgerygadget SetOverlayToolInputs $reslicedAnatomicalImage $reslicedFunctionalImage 
	::itcl::delete object $reslicedAnatomicalImage
	::itcl::delete object $reslicedFunctionalImage 
    } elseif { $input1 } {
	$surgerygadget SetOverlayToolInputs [ $dustin getNodeImageObject $spaceImage ] $reslicedAnatomicalImage
	::itcl::delete object $reslicedAnatomicalImage
    } elseif { $input2 } { 
	$surgerygadget SetOverlayToolInputs [ $dustin getNodeImageObject $spaceImage ] $reslicedFunctionalImage 
	::itcl::delete object $reslicedFunctionalImage 
    } else {
	$surgerygadget SetOverlayToolInputs [ $dustin getNodeImageObject $spaceImage ] [ $dustin getNodeImageObject $spaceImage ]
    }
    updateOverlayCanvas
}

::itcl::body bis_treegui::getReslicedImage { spaceNode imageNode } {
    
    setNodeObject $spaceNode ; setNodeObject $imageNode
    
    set transformList [ makeTransformList $spaceNode $imageNode ]
    
    if { $transformList == 0 } {
	tk_messageBox -type ok  -title "Cannot open image" -message "Transformation is missing" -icon error
	return 0
    }
    
    if { ![ llength $transformList ] } {
	set img [ [ pxitclimage \#auto ] GetThisPointer ]
	$img ShallowCopy [ $dustin getNodeImageObject $imageNode ]
	return $img
    }

    set transform [ combineTransforms $transformList ]
    return [ reslice $spaceNode $imageNode $transform ]
}

::itcl::body bis_treegui::setViewer { viewerNumber } {
   
    if { $viewerNumber == 1 } { set viewer $viewer1 } else { set viewer $viewer2}
    return $viewer
}

::itcl::body bis_treegui::setElectrodeViewer { econtrolNumber } {

    if { $econtrolNumber == 1 } { set viewer $electrodecontrol1 } else { set viewer $electrodecontrol2}
    return $viewer
}

::itcl::body bis_treegui::displaySurface { viewer surfaceNode inRefSpace } {
    
    if { ![ file exists [ $dustin getNodeFileName $surfaceNode ] ] } { 
	tk_messageBox -type ok  -title "Cannot open surface" -message "File does not exist" -icon error
	return 0
    }
    
    if { [ string match [ $dustin getNodeType $surfaceNode ] "Electrode" ] } { 
	set exp [ string match [ [ $viewer2 GetDisplayedImage ] cget -filename ] "" ] 
    } else {
	set exp [ string match [ [ $viewer  GetDisplayedImage ] cget -filename ] "" ] 
    }

    if { $exp } {
	::pxtclutil::Info "Please put an image into the viewer to properly display the surface" 
    }
    
    setNodeObject $surfaceNode
    
    if { [ expr !$inRefSpace ] } {
	catch { [ $dustin getNodeImageObject $surfaceNode ] Display $viewer }
	$viewer ShowWindow
	return 0
    }
    
    if { [ checkSpaceImageExsist ] } { return 0 }
    
    set spaceNode [ lindex $spaceImageList 0 ]
    setNodeObject $spaceNode

    set transformList [ makeTransformList $spaceNode $surfaceNode ]
    if { $transformList == 0 } {
	tk_messageBox -type ok  -title "Cannot open aurface" -message "Transformation is missing" -icon error ; return 
	return 0
    }
    
    if { ![ llength $transformList ] } {
	[ $dustin getNodeImageObject $surfaceNode ] Display $viewer
	$viewer ShowWindow
	return 0
   }
    
    set transform [ combineTransforms $transformList ]

    switch -exact [ $dustin getNodeType $surfaceNode ] {
	
	"Surface"  { 
	    set newsur [ pxitclsurface \#auto ] 
	    $newsur ShallowCopy [ $dustin getNodeImageObject $surfaceNode ]
	}
	
	"Electrode" {
	    set newsur [ pxitclelectrodemultigrid \#auto ] 
	    $newsur Copy [ $dustin getNodeImageObject $surfaceNode ]
	}
	
	"Landmark" {
	    set newsur [ pxitcllandmarks \#auto ]
	    $newsur Copy [ $dustin getNodeImageObject $surfaceNode ]
	}
	
	default { :itcl::delete object $transform; return 0 }
    }
	
    $newsur Transform [ $transform GetObject ]
    catch { $newsur Display $viewer }
  
    ::itcl::delete object $newsur
    ::itcl::delete object $transform
}

::itcl::body bis_treegui::combineTransforms { transformList } {
  
    set trans [ vtkGeneralTransform [ pxvtable::vnewobj ] ]
    $trans Identity
    $trans PostMultiply

    for { set index 1 } { $index <= [ llength $transformList ] } { incr index } {
	set index2 [ expr [ llength $transformList ] - $index ]
	$trans Concatenate [ [ lindex $transformList $index2 ] GetTransformation ]
	itcl::delete object [ lindex $transformList $index2 ]
    }
 
    set output [ [ pxitcltransform \#auto ] GetThisPointer ]
    $output CopyTransformation $trans
    #$trans Delete
    $output Save /tmp/output
    return $output
}

::itcl::body bis_treegui::setTitle {  } {
    
    set oldTitle [ $dustin getNodeTitle $selectionPath ]
    set newTitle [ Single_Entry_Dialog "Rename" "Enter the new name for this node" $oldTitle ]
   
    if { $newTitle == ""} {return}
    if { $newTitle == $oldTitle } {return}  
    
    if { [checkForIllegalCharacters $newTitle] } {
    	set tmpPath $selectionPath
	#because of trouble with updating the path and title at the same time with the node info box
	#we switch the node info box to the parent node and then change the title of the selected node 
	#then update the node info box to the selected node
	set selectionPath [ $dustin getNodeParent $selectionPath ]; updateGUI
	setDisplayBox  [ $dustin setNodeTitle $newTitle $tmpPath ]; updateGUI
	updateTreeWidget $tmpPath
	#puts [ lindex $spaceImageList      0 ]
	if { ![ $dustin pathExist [ lindex $spaceImageList      0 ] ] } { set spaceImageList      "" }
	if { ![ $dustin pathExist [ lindex $functionalImageList 0 ] ] } { set functionalImageList "" }
	if { ![ $dustin pathExist [ lindex $anatomicalImageList 0 ] ] } { set anatomicalImageList "" }
	updateRightCanvasDisplay
    } else {
	$this setTitle
    }
}

::itcl::body bis_treegui::setFileName { { name "" } } {
    
    switch -exact [ $dustin getNodeType $selectionPath ] {
	"Image"      { set typelist {{"Image"       {".hdr" ".hdr.gz" ".nii" ".nii.gz"}} {"All Files" {*}}}}
	"Landmark"   { set typelist {{"Landmark"    {".land"}}                           {"All Files" {*}}}}
	"Surface"    { set typelist {{"Surface"     {".vtk"}}                            {"All Files" {*}}}}
	"Electrode"  { set typelist {{"Electrodes"  {".mgrid"}}                          {"All Files" {*}}}}
	default      { return 0 }
    }
    
    if { $name == "" } { set name [tk_getOpenFile -filetypes $typelist] }
    if { $name == "" } { return }
    $dustin setNodeFileName $name $selectionPath 
    displayFileName
    updateTreeWidget $selectionPath
    updateGUI 
}

::itcl::body bis_treegui::setTransFromParent {  } {
  
    set typelist {
	{"Linear/Non-Linear Transforms" {".matr" ".grd" }}
	{"Linear Transforms" {.matr}}
	{"Non-Linear Transforms" {.grd}}
	{"All Files" {*}}
    }
   
    set transform [tk_getOpenFile -filetypes $typelist]
    if { $transform == "" } { return }
    $dustin setNodeTransFromParent $transform $selectionPath
    if { [ file extension $transform ] == ".matr" } {
	$dustin setNodeTransToParent "linear.nosave" $selectionPath 
    }
    updateTreeWidget $selectionPath; updateBigTransLines
}

::itcl::body bis_treegui::setTransToParent {  } {
    
    set typelist {
	{"Non-Linear Transforms" {.grd}}
	{"Linear Transforms" {.matr}}
	{"All Files" {*}}
    }
   
    set transform [tk_getOpenFile -filetypes $typelist]
    if { $transform == "" } { return }
    $dustin setNodeTransToParent $transform $selectionPath
    updateTreeWidget $selectionPath;  updateBigTransLines
}

::itcl::body bis_treegui::setIdentityToggle {  } {
    
    if { [ $dustin getNodeTransFromParent $selectionPath ] == 1 \
	    && [ $dustin getNodeTransToParent $selectionPath ] == 1 } { 
	$dustin setNodeTransFromParent "" $selectionPath 
	$dustin setNodeTransToParent   "" $selectionPath 	
	updateTreeWidget $selectionPath
	updateBigTransLines
    } else { 
	$dustin setNodeTransFromParent 1 $selectionPath 
	$dustin setNodeTransToParent   1 $selectionPath 
	updateTreeWidget $selectionPath
	updateBigTransLines
    }
}

::itcl::body bis_treegui::clearTrans { item } { 
    $dustin setNode${item} "" $selectionPath 
    updateOverlayCanvas ; updateTreeWidget $selectionPath ;  updateGUI
}

::itcl::body bis_treegui::grabElectrodeAttributes { electrodecontrolno } {

    set electrodecontrol $electrodecontrol1; if { $electrodecontrolno == 2 && $electrodecontrol2 != 0 }  { set electrodecontrol $electrodecontrol2 }
    if { $electrodecontrol == 0 } {	return    }

    set source [ $electrodecontrol GetMultiGrid ]

    set ThisNode [GetIDFromSelection]
    EnsureFileLoaded $ThisNode
    set electrodeobj        [$RealTree get $ThisNode pxitclobj]
    set target  [$electrodeobj GetObject]

    $target CopyAttributes $source

    #Save a new file
    set newName "[file rootname [$RealTree get $ThisNode FileName]]_Attr_Updated.mgrid"
    $target Save $newName
    setNodeFilename $ThisNode $newName
}

::itcl::body bis_treegui::PutViewerObjectInTree { viewerno objtype } {
    
    set MC [ $dustin getMasterCount ]
    set filename [ GrabViewer${objtype} $viewerno ]
    if { $filename == "" } { return 0 }
    addNodeToTree $objtype "Grabbed_${objtype}_$MC"
    setFileName $filename
}

::itcl::body bis_treegui::GrabViewerImage { viewerno } {
    
    set viewer [ setViewer $viewerno ]
    
    set img [ $viewer GetDisplayedImage ]
    if { [ $img cget -filename ] == "" } {
	tk_messageBox -type ok  -title "Cannot Grab Image" -message "No image in viewer" -icon error ; return ""
    }

    if { [ $img Save "" ] } {
	return [ $img cget -filename ]
    } else { return "" }
}

::itcl::body bis_treegui::GrabViewerSurface { viewerno } {
    
    set viewer  [ setViewer $viewerno ]
    set newsur  [ [ pxitclsurface \#auto ] GetThisPointer ]
    set surface [ [ [ $viewer GetPolyDataControl ] GetPolyDataControl ]  GetSurface  -1 ]
    $newsur ShallowCopySurface $surface
    
    if { [ $newsur GetSurfaceSize ] < 6 } { 
	tk_messageBox -type ok  -title "Cannot Grab Surface" -message "No surface in the control" -icon error ; return ""
    }

    if { [ $newsur Save "" ] } {
	set fname [ $newsur cget -filename ]
	itcl::delete object $newsur
	return $fname
    } else { 
	itcl::delete object $newsur
	return "" 
    }
}

::itcl::body bis_treegui::GrabViewerLandmark { viewerno } {
    
    set viewer  [ setViewer $viewerno ]
    set newsur  [ [ pxitcllandmarks \#auto ] GetThisPointer ]
    set surface [ [ [ $viewer GetLandmarkControl ] GetLandmarkControl ]  GetCollection  -1 ] 
    $newsur CopyLandmarks $surface
    
    # GetLandmarkSize outputs a interger with the format of # of  PointSet and some other #
    # 20 is no points`
    if { [ $newsur GetLandmarksSize ] == 20 } { 
	tk_messageBox -type ok  -title "Cannot Grab landmark" -message "No landmark in the control" -icon error ; return ""
    }

    if { [ $newsur Save "" ] } {
	set fname [ $newsur cget -filename ]
	itcl::delete object $newsur
	return $fname
    } else { 
	itcl::delete object $newsur
	return "" 
    }
}

::itcl::body bis_treegui::GrabViewerElectrode { electrodecontrolno } {
    
    set viewer [ setElectrodeViewer $electrodecontrolno ]

    if { [ $viewer SaveElectrodeMultiGrid "" ] } {
	return [ $viewer GetLastFilename ]
    } else { return "" }
}


::itcl::body bis_treegui::mdCopy { {cut 0} {node ""} } {

    if { $node == "" } {
	set node $selectionPath 
    }
    
    if {[ info exist clipBoardTree ]} {
	itcl::delete object $clipBoardTree
	set clipBoardTree [ [ dsitcltree \#auto ] GetThisPointer ]
    } else {
	set clipBoardTree [ [ dsitcltree \#auto ] GetThisPointer ]
    }
    $clipBoardTree copyTreeAtNode $dustin $node

    if {$cut == 1} {
	$this delSelectedFromTree
    }
}

::itcl::body bis_treegui::mdPaste { { parentNode "" } } {

    if { $parentNode == "" } {
	set parentNode $selectionPath 
    }
    
    if {![ info exist clipBoardTree ]} {
	tk_messageBox -type ok -title "Cannot paste" -message "Nothing in the clipboard" 
	return 0
    }
    
    if {     [ $dustin getNodeType $parentNode ] == "Surface"   || \
	     [ $dustin getNodeType $parentNode ] == "Electrode" || \
	     [ $dustin getNodeType $parentNode ] == "Landmark" } {
	
	tk_messageBox -type ok -title "Cannot paste" -message "Surface cannot have children nodes"
	return 0
    } 

    $this addSubtree $clipBoardTree $parentNode
    setUndoList; set TreeChanged 1
}

#Save and Load Tree Methods 

::itcl::body bis_treegui::mdSaveTree { } {
    
    updateNotes
    $dustin writeDatatree $relativePath
}

::itcl::body bis_treegui::saveReorganize { } {
    
    updateNotes
    $dustin saveReorangized
}

::itcl::body bis_treegui::mdNewTree { } {
    
    updateNotes 
    destroy $NodeInfoDialogName
    ::itcl::delete object $dustin
    
    set dustin [ [ dsitcltree \#auto new ] GetThisPointer ]
    
    set spaceImageList ""; set anatomicalImageList ""; set functionalImageList ""
    updateRightCanvasDisplay
    updateTreeWidget /Data
    setDisplayBox /Data
}

::itcl::body bis_treegui::mdLoadTree { {filename ""} } {
   
    set tmpTree [ [ dsitcltree \#auto ] GetThisPointer ]

    if { ![ $tmpTree readDatatree $filename ] } {
	::itcl::delete object $tmpTree
	return 0
    }

    foreach path [ $dustin getPathList ] {
	if {[ regexp {(/)(.+)(/)} $path ]} { 
	    if {[ Tree::itemexists $vistree $path ]} { Tree::delitem $vistree $path }
	}
    }	
    
    updateNotes
    destroy $NodeInfoDialogName
    ::itcl::delete object $dustin
    set dustin $tmpTree
    set spaceImageList ""; set anatomicalImageList ""; set functionalImageList ""
    updateRightCanvasDisplay
    updateTreeWidget Data
    setDisplayBox /Data
    #wm title $mdTopWidget $filename 
}

::itcl::body bis_treegui::mdSaveTypeDefs { } {
    
    $FileManager SaveTypeDefs [array get RecognizedTypes]
    
}

::itcl::body bis_treegui::mdLoadTypeDefs { } {
    
    catch {array unset RecognizedTypes}
    set loadedtypes [$FileManager LoadTypeDefs]
    if {$loadedtypes != -1} {
	array set RecognizedTypes $loadedtypes
	set RecogTypeDialogName -1
	setRecognizedTypes
    }

}

::itcl::body bis_treegui::EditPatientPropList { } {

   if {$PatientPropDialogName == -1} {

       #Make a dialog box
       set PatientPropDialogName .[ pxvtable::vnewobj ]
       iwidgets::dialog $PatientPropDialogName -title "Patient Properties" -modality application
       $PatientPropDialogName hide Help
       $PatientPropDialogName hide Apply
       $PatientPropDialogName hide Cancel
       eval "$PatientPropDialogName buttonconfigure OK -command { $this PatientPropDialogCallback ok }"
       eval "$PatientPropDialogName add removebutton -text Remove -command { $this PatientPropDialogCallback remove }"
       eval "$PatientPropDialogName add addbutton -text Add -command { $this PatientPropDialogCallback add }"

       set cs1 [ $PatientPropDialogName childsite ]
       set PatientProperty_selectionbox1 [iwidgets::selectionbox $cs1.selbox -itemslabel "Patient Property List" -selectionlabel "Add:"]
       pack $PatientProperty_selectionbox1
       
	
   }
    
   set patientproplistbox [$PatientProperty_selectionbox1 component items]
   $patientproplistbox clear
   for {set u 0} {$u < [llength $PatientProperties]} {incr u} {
       $patientproplistbox insert end [lindex $PatientProperties $u]
   }
   
   wm geometry $PatientPropDialogName +300+200
   $PatientPropDialogName activate
   
}

::itcl::body bis_treegui::PatientPropDialogCallback { command } {

  
    #Get pointers to the entry field and the listbox
    set thisentryfield [$PatientProperty_selectionbox1 component selection]
    set thislistbox [$PatientProperty_selectionbox1 component items]

    #If the command is OK, update the internal property list, and deactivate dialog
    if {$command == "ok"} {
	set PatientProperties ""
	for {set y 0} {$y < [llength [$thislistbox get 0 end]]} {incr y} {
	    lappend PatientProperties [$thislistbox get $y]
	}
	
	$PatientPropDialogName deactivate; return 0
    }
     
    #If the command is add, insert the contents of the entryfield into the list
    if {$command == "add"} {
	set input [$thisentryfield get]
	if {[llength $input]} {
	    $thislistbox insert 0 $input
	    $thisentryfield clear
	}
    }

    #If the command is remove, remove the selected items from the list
    if {$command == "remove"} {
	set sel  [$thislistbox getcurselection]
	if { [llength $sel] } {
	    $thislistbox delete $sel
	}
    }
}

::itcl::body bis_treegui::showRecognizedTypes { arraylist } {
    
    catch {array unset tempArray}
    array set tempArray $arraylist
    set keylist [ array names tempArray ]
    set keylist [lsort $keylist]
    
    if {$RecogTypeDialogName == -1} {
	set mdEntries ""
    	set RecogTypeDialogName .[ pxvtable::vnewobj ]
	iwidgets::dialog $RecogTypeDialogName -title "Recognized Image Types" -modality application
	
	for { set k 0 } { $k < [llength $keylist] } { incr k } {
	    set key [lindex $keylist $k]
	    set val $tempArray($key)
	    
	    set f $key; append f "_f"	
	    set c $key; append c "_c"
	    set y $key; append y "_y"
	    set v $key; append v "_v"
	    
	    set cs [$RecogTypeDialogName childsite]
	    set framebox [frame $cs.$f]	
	    
	    set checkedvar $key; append checkedvar "_checked"
	    set RecognizedTypesChecks($checkedvar) 0
	    set checkbox [checkbutton $framebox.$c -variable [itcl::scope RecognizedTypesChecks($checkedvar)]]
	    
	    set keybox [iwidgets::entryfield $framebox.$y -clientdata "Keybox$f" ]
	    $keybox insert 0 $key
	    
	    set valbox [iwidgets::entryfield $framebox.$v -clientdata "Valbox$v" ]
	    $valbox insert 0 $val
	    
	    pack $checkbox $keybox $valbox  -padx 4 -pady 4 -side left
	    pack $framebox -side top
	    
	    lappend mdEntries $checkedvar
	    lappend mdEntries $keybox
	    lappend mdEntries $valbox
	    
	}
	
	$RecogTypeDialogName hide Help
	$RecogTypeDialogName hide Cancel
	$RecogTypeDialogName hide Apply
	eval "$RecogTypeDialogName buttonconfigure OK -command { $this recognizedTypeDialogCallback $RecogTypeDialogName OK }"
	eval "$RecogTypeDialogName add Add -text Add -command { $this recognizedTypeDialogCallback $RecogTypeDialogName Add }"
	eval "$RecogTypeDialogName add Delete -text \"Delete Checked\" -command { $this recognizedTypeDialogCallback $RecogTypeDialogName Delete }"
	
    }
    
    set dialogEntries -1
    
    for { set k 0 } { $k < [llength $keylist] } { incr k } {
	set key [lindex $keylist $k]
	set varname $key; append varname "_checked"
    }
    
    wm geometry $RecogTypeDialogName +300+200
    $RecogTypeDialogName activate
    
    return $dialogEntries
    
};#End showRecognizedTypes method


::itcl::body bis_treegui::recognizedTypeDialogCallback { dialogname mode } {
    
    if { $mode == "Cancel" } {
	$dialogname deactivate
    }
    
    set dialogEntries ""
    foreach {checkbox keyentry valentry} $mdEntries {
#	puts [$checkbox cget -variable]
	lappend dialogEntries [$keyentry get]	   
	lappend dialogEntries [$valentry get] 
    }
    
    #--------------------------------------------------------------------------------
    if {$mode == "Add"} {
	set newList $dialogEntries
	lappend newList 99999
	lappend newList "New Type"
	
	$dialogname deactivate
    	set RecogTypeDialogName -1
	showRecognizedTypes $newList
    }

    #--------------------------------------------------------------------------------
    if {$mode == "Delete"} {
	set dialogEntries ""
	foreach {checkvar keyentry valentry} $mdEntries {
	    if {$RecognizedTypesChecks($checkvar) != 1} {
		lappend dialogEntries [$keyentry get]	   
		lappend dialogEntries [$valentry get] 
	    }
	}
	set newList $dialogEntries
	$dialogname deactivate
    	set RecogTypeDialogName -1
	showRecognizedTypes $newList
    }
    
    #--------------------------------------------------------------------------------
    if { $mode == "OK" } {
	$dialogname deactivate
    }
}


::itcl::body bis_treegui::setRecognizedTypes { } {
    
    set newarray [showRecognizedTypes [array get RecognizedTypes] ]
    if {$newarray != -1} {
	catch {array unset RecognizedTypes}
	array set RecognizedTypes $newarray
    }
    
}



::itcl::body bis_treegui::SearchTree { realtreename startnode key values } {
    
    set SearchResult ""
    foreach val $values {
	
	set nodelist [$realtreename children -all $startnode]
	set ValList [$realtreename attr $key -nodes $nodelist]
	
	
	foreach { node nodevalue } $ValList {
	    if {$nodevalue == $val} {
		lappend SearchResult $node
	    }
	}
	
    }
    
    if {[llength $SearchResult]} {
	set SearchResult [lsort $SearchResult]
    }
    
    #    puts "The following nodes have value(s) of $values for key \"$key\": $SearchResult"
    return $SearchResult
    
}

##########################################################################################

::itcl::body bis_treegui::makeFileMenu { menu0 } {

    eval "$menu0 add command -label \"New Datatree\"  -command { $this mdNewTree  } -underline 0  -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Load Datatree\" -command { $this mdLoadTree } -underline 0 -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Save Datatree\" -command { $this mdSaveTree } -underline 0 -activebackground \"$menuactivebgcolor\""
    $menu0 add separator 
    eval "$menu0 add command -label \"Save Reorganized Copy\" -command { $this saveReorganize } -underline 0 -activebackground \"$menuactivebgcolor\""
    $menu0 add separator 
    eval "$menu0 add command -label \"Switch Directory\" -command { $this SwitchDirectory } "
    set thisparam($this,custdirectories)  [ pxitclfilelistmenu \#auto $menu0 "Custom Directories" "$this SwitchDirectory" ]
    $thisparam($this,custdirectories) SetModeToDirectories
    $thisparam($this,custdirectories) InitializeDisplay

    global env
    set thisparam($this,custtrees)  [ pxitclfilelistmenu \#auto $menu0 "Previous Trees" "$this mdLoadTree" "$this mdGetTreeFileName" ]
    $thisparam($this,custtrees) SetModeToCustom "DataTrees" .tre [ file join $env(HOME) .datatrees ] 1 
    $thisparam($this,custtrees) InitializeDisplay

    $menu0 add separator 
    eval "$menu0 add command -label Exit -command { $this OnWidgetClose; } -underline 1 -activebackground \"$menuactivebgcolor\""
}

::itcl::body bis_treegui::makeEditMenu { menu0 } {

    eval "$menu0 add command -label \"Cut\" -command {$this mdCopy 1} -underline 1 -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Copy\" -command {$this mdCopy 0} -underline 0 -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Undo\" -command {$this undo} -underline 0 -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Redo\" -command {$this redo} -underline 0 -activebackground \"$menuactivebgcolor\""
    $menu0 add separator
    eval "$menu0 add command -label \"Paste\" -command {$this mdPaste} -activebackground \"$menuactivebgcolor\""   
    $menu0 add separator
    eval "$menu0 add checkbutton -label \"Enable Drag and Drop\" -variable {[itcl::scope dragAndDropEnabled]} \
	    -onvalue 1 -offvalue 0 -activebackground \"$menuactivebgcolor\""
 }

::itcl::body bis_treegui::makeToolsMenu { menu0 } {

    set toolsmenu $menu0
    eval "$menu0 add command -label \"Multiple Image Calculations\" -command { $this SearchDialog } -activebackground \"$menuactivebgcolor\""   

    #------------------------------------------------------------------------------------------
    # If the SPECT module is loaded, make a menu for it
    if {$enable_SPECT == 1} {
	eval "$menu0 add command -label \"SPECT Processing Tool\" -command { $this ShowSPECTtool } -activebackground \"$menuactivebgcolor\""  
    }
    
    if {$enable_AdvancedReg == 1 } {
	eval "$menu0 add command -label \"Advanced Registration Tool\" -command { $this ShowREGtool } -activebackground \"$menuactivebgcolor\""  
   }
    
    #eval "$menu0 add command -label \"Image Processing\" -command { $this showImageProcessTool } -activebackground \"$menuactivebgcolor\""  

    #showImageProcessTool

   #------------------------------------------------------------------------------------------
    # If the atlas module is loaded, make a menu for it
    if {$enable_atlas == 1} {
	$menu0 add cascade -label "Atlas" -menu $menu0.atlas -activebackground "$menuactivebgcolor"
	set atlasSubMenu [menu $menu0.atlas -tearoff 0]
       	makeAtlasMenu $atlasSubMenu
    }
    
    #Set the background for all menu entries
    for {set i 0} {$i <= [$menu0 index end]} {incr i} {
	$menu0 entryconfigure $i -background $menucolor 
    }
}


#----------------------------------------------------------------------
# Node Menu and Tree Popup Menu Option Methods (Can be accessed from elsewhere, too)
# (This Menu is associated with image files)
#----------------------------------------------------------------------

::itcl::body bis_treegui::printTree { } {
    $dustin printSelf
}


::itcl::body bis_treegui::makeImageMenu { menu0 } {
    #Set the "Node" menu contents (same as tree popup menu contents)
    eval "$menu0 add command -label \"Printtree\" -command { $this printTree } -underline 0 -activebackground \"$menuactivebgcolor\""
    $menu0 add separator
    eval "$menu0 add command -label \"Set Filename\" -command { $this setFileName } -underline 0 -activebackground \"$menuactivebgcolor\""
    $menu0 add separator
    eval "$menu0 add command -label \"Rename\" -command { $this setTitle } -underline 0 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label Delete -command { $this delSelectedFromTree } -underline 0 -activebackground \"$menuactivebgcolor\""    
    $menu0 add separator
    eval "$menu0 add command -label \"Add an Image as Child\" -command { $this addNodeToTree Image } -underline 7 -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Add a ROI as Child\" -command { $this addROIDefToTree } -activebackground \"$menuactivebgcolor\""
    $menu0 add cascade -label "Add a Surface as Child" -menu $menu0.surfsub -activebackground "$menuactivebgcolor"
    set surfsubmenu [menu $menu0.surfsub -tearoff 0]
    eval "$surfsubmenu add command -label \"Surface\" -command { $this addNodeToTree Surface } -background \"$menucolor\" -activebackground \"$menuactivebgcolor\""
    eval "$surfsubmenu add command -label \"Landmark\" -command { $this addNodeToTree Landmark } -background \"$menucolor\" -activebackground \"$menuactivebgcolor\""
    eval "$surfsubmenu add command -label \"Electrode\" -command { $this addNodeToTree Electrode } -background \"$menucolor\" -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Add a Folder as Child\" -command { $this addNodeToTree Folder } -activebackground \"$menuactivebgcolor\""    
    $menu0 add cascade -label "Add Subtree" -menu $menu0.subtreesub -activebackground "$menuactivebgcolor"
    set subtreemenu [menu $menu0.subtreesub -tearoff 0]
    eval "$subtreemenu add command -label \"Native Type\" -command { $this addSubtree } -activebackground \"$menuactivebgcolor\""        
    eval "$subtreemenu add command -label \"Multisubject Definition (*.msb)\" -command { $this addSubtreeAtSelection 5} -activebackground \"$menuactivebgcolor\""  
    $menu0 add separator
    eval "$menu0 add command -label \"Load Transformation FROM Parent\" -command { $this setTransFromParent } -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Load Transformation TO Parent (if nonlinear)\" -command { $this setTransToParent } -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"(Un)set as Identity\" -command {$this setIdentityToggle } -activebackground \"$menuactivebgcolor\""
}

#----------------------------------------
#This menu will go with Surfaces and Landmarks
#----------------------------------------

::itcl::body bis_treegui::makeSurfaceMenu { menu0 } {

    #Set the "Node" menu contents (same as tree popup menu contents)
    eval "$menu0 add command -label \"Set Filename\" -command { $this setFileName } -underline 0 -activebackground \"$menuactivebgcolor\""
    $menu0 add separator
    eval "$menu0 add command -label \"Rename\" -command { $this setTitle } -underline 0 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label Delete -command { $this delSelectedFromTree } -underline 0 -activebackground \"$menuactivebgcolor\""    
    $menu0 add separator
    eval "$menu0 add command -label \"Send to Left Viewer\"  -command { $this sendSelectionToDisplay 1 \"\" } -underline 9 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label \"Send to Right Viewer\" -command { $this sendSelectionToDisplay 2 \"\" } -underline 9 -activebackground \"$menuactivebgcolor\"" 
    $menu0 add separator
    eval "$menu0 add command -label \"Send to Left Viewer (in Reference Space)\"  -command { $this sendSelectionToDisplay 1 \"\" 1} -underline 9 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label \"Send to Right Viewer (in Reference Space)\" -command { $this sendSelectionToDisplay 2 \"\" 1} -underline 9 -activebackground \"$menuactivebgcolor\"" 
}

::itcl::body bis_treegui::makeFolderMenu { menu0 } {
    
    eval "$menu0 add command -label \"Rename\" -command { $this setTitle  } -underline 0 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label Delete -command { $this delSelectedFromTree } -underline 0 -activebackground \"$menuactivebgcolor\"" 
    $menu0 add separator
    eval "$menu0 add command -label \"Add an Image as Child\" -command { $this addNodeToTree Image } -underline 7 -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Add an ROI Definition\" -command { $this addROIDefToTree } -activebackground \"$menuactivebgcolor\""
    $menu0 add cascade -label "Add Subtree" -menu $menu0.subtreesub -activebackground "$menuactivebgcolor"
    set subtreemenu [menu $menu0.subtreesub -tearoff 0]
    eval "$subtreemenu add command -label \"Native Type\" -command { $this addSubtree } -activebackground \"$menuactivebgcolor\""        
    eval "$subtreemenu add command -label \"Multisubject Definition (*.msb)\" -command { $this addSubtreeAtSelection 5} -activebackground \"$menuactivebgcolor\""   
}

#----------------------------------------
#This menu will go with Electrodes
#----------------------------------------
::itcl::body bis_treegui::makeElectrodeMenu { menu0 } {
    #Set the "Node" menu contents (same as tree popup menu contents)
    eval "$menu0 add command -label \"Set Filename\" -command { $this setFileName } -underline 0 -activebackground \"$menuactivebgcolor\""
   
    #If the attribute package is loaded, then allow manipulation of attirbutes
    if {$enable_elec_att == 1} {
	$menu0 add separator
	eval "$menu0 add command -label \"Attribute Visualization Control\" -command { $this SendElectrodeToAtrrControl } -underline 0 -activebackground \"$menuactivebgcolor\""
	eval "$menu0 add command -label \"Load Attributes\" -command { $this mdLoadElectrodeAttributes } -underline 0 -activebackground \"$menuactivebgcolor\""
	eval "$menu0 add command -label \"Update Attributes from Viewer Electrodes\" -command { $this grabElectrodeAttributes 1 } -underline 0 -activebackground \"$menuactivebgcolor\""
	
    }
    $menu0 add separator
    eval "$menu0 add command -label \"Rename\" -command { $this setTitle } -underline 0 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label Delete -command { $this delSelectedFromTree } -underline 0 -activebackground \"$menuactivebgcolor\""    
    $menu0 add separator
    eval "$menu0 add command -label \"Send to Electrode Control 1\" -command { $this sendSelectionToDisplay 1 \"\" } -underline 9 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label \"Send to Electrode Control 1 (in Reference Space)\" -command { $this sendSelectionToDisplay 1 \"\" 1 } -underline 9 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label \"Send to Electrode Control 2\" -command { $this sendSelectionToDisplay 2 \"\" } -underline 9 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label \"Send to Electrode Control 2 (in Reference Space)\" -command { $this sendSelectionToDisplay 2 \"\" 1} -underline 9 -activebackground \"$menuactivebgcolor\""    
}


#------------------------------------------------------------------------------------------
# This Menu is associated with Patient nodes
#------------------------------------------------------------------------------------------
::itcl::body bis_treegui::makePatientMenu { menu0 } {
    
    #Set the "Patient" menu contents (same as tree popup menu contents)
    eval "$menu0 add command -label \"Rename\" -command { $this setTitle } -underline 0 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label \"Delete Selected Patient\" -command { $this delSelectedFromTree } -underline 0 -activebackground \"$menuactivebgcolor\""    
    $menu0 add separator
    eval "$menu0 add command -label \"Load Transformation FROM Parent\" -command { $this setTransFromParent } -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Load Transformation TO Parent (if nonlinear)\" -command { $this setTransToParent $this } -activebackground \"$menuactivebgcolor\""
    $menu0 add separator
    eval "$menu0 add command -label \"Add a Patient to Tree at Selection\" -command { $this addPatientToTree } -underline 0 -activebackground \"$menuactivebgcolor\""    
}

#------------------------------------------------------------------------------------------
# This Menu is associated with the top Data node
#------------------------------------------------------------------------------------------

::itcl::body bis_treegui::makeDataMenu { menu0 } {
    
    eval "$menu0 add command -label \"Add an Image as Child\" -command { $this addNodeToTree Image } -underline 7 -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Add a ROI as Child\" -command { $this addROIDefToTree } -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Add a Folder as Child\" -command { $this addNodeToTree Folder } -activebackground \"$menuactivebgcolor\""    
    $menu0 add cascade -label "Add Subtree" -menu $menu0.subtreesub -activebackground "$menuactivebgcolor"
    set subtreemenu [menu $menu0.subtreesub -tearoff 0]
    eval "$subtreemenu add command -label \"Native Type\" -command { $this addSubtree } -activebackground \"$menuactivebgcolor\""        
    eval "$subtreemenu add command -label \"Multisubject Definition (*.msb)\" -command { $this addSubtreeAtSelection 5} -activebackground \"$menuactivebgcolor\"" 
}

#------------------------------------------------------------------------------------------
# This Menu is for bringing up and dealing with the Atlas Tool
#------------------------------------------------------------------------------------------

::itcl::body bis_treegui::makeAtlasMenu { menu0 } {
    
    eval "$menu0 add command -label \"Open Atlas Tool\" -command { $this ShowAtlas } -activebackground \"$menuactivebgcolor\"" 
    eval "$menu0 add command -label \"Send Selected Image to Atlas Tool\" -command { $this AtlasShowSelectedNode } -activebackground \"$menuactivebgcolor\"" 
    $menu0 add separator
    eval "$menu0 add command -label \"Add Atlas to Tree at Selection\" -command { $this addAtlasToTree } -activebackground \"$menuactivebgcolor\""  
    
    #Set the background for all menu entries
    for {set i 0} {$i <= [$menu0 index end]} {incr i} {
	$menu0 entryconfigure $i -background $menucolor 
    }
}

#------------------------------------------------------------------------------------------
# This is the definition method for the Options Menu
#------------------------------------------------------------------------------------------

::itcl::body bis_treegui::makeOptionsMenu { menu0 } {
    
    eval "$menu0 add checkbutton -label \"Lock Space Image\" -variable {[itcl::scope SpaceLocked]} \
-onvalue 1 -offvalue 0 -command {$this updateBigTransLines} -activebackground \"$menuactivebgcolor\""
    $menu0 add separator
    eval "$menu0 add command -label \"View/Set Recognized Image Types\" -command { $this setRecognizedTypes } -activebackground \"$menuactivebgcolor\""  
    eval "$menu0 add command -label \"Save Image Type Definition File\" -command { $this mdSaveTypeDefs } -activebackground \"$menuactivebgcolor\""  
    eval "$menu0 add command -label \"Load Image Type Definition File\" -command { $this mdLoadTypeDefs } -activebackground \"$menuactivebgcolor\""  
    $menu0 add separator    
    eval "$menu0 add command -label \"Edit Patient Property List\" -command { $this EditPatientPropList } -activebackground \"$menuactivebgcolor\""  
    $menu0 add separator
    
    $menu0 add cascade -label "File Path Save Mode" -menu $menu0.savemodesub -activebackground "$menuactivebgcolor"
    set savemodemenu [menu $menu0.savemodesub -tearoff 0]
    eval "$savemodemenu add radio -label Relative -variable {[itcl::scope relativePath]} -value 1 -activebackground \"$menuactivebgcolor\""
    eval "$savemodemenu add radio -label Absolute -variable {[itcl::scope relativePath]} -value 0 -activebackground \"$menuactivebgcolor\""
    
    $menu0 add separator
    $menu0 add cascade -label "Choose Icon Colors" -menu $menu0.icontypesub -activebackground "$menuactivebgcolor"
    set icontypecascade [menu $menu0.icontypesub -tearoff 0]
    
    $icontypecascade add cascade -label "Images" -menu $icontypecascade.colorsub1 -activebackground "$menuactivebgcolor"
    set colormenu [menu $icontypecascade.colorsub1 -tearoff 0]
    makeColorMenu $colormenu brainiconchoice
    
    $icontypecascade add cascade -label "Surfaces" -menu $icontypecascade.colorsub2 -activebackground "$menuactivebgcolor"
    set colormenu [menu $icontypecascade.colorsub2 -tearoff 0]
    makeColorMenu $colormenu surfaceiconchoice
    
    $icontypecascade add cascade -label "Results" -menu $icontypecascade.colorsub3 -activebackground "$menuactivebgcolor"
    set colormenu [menu $icontypecascade.colorsub3 -tearoff 0]
    makeColorMenu $colormenu resulticonchoice

    $icontypecascade add cascade -label "ROI Definitions" -menu $icontypecascade.colorsub4 -activebackground "$menuactivebgcolor"
    set colormenu [menu $icontypecascade.colorsub4 -tearoff 0]
    makeColorMenu $colormenu roiiconchoice
}

#------------------------------------------------------------------------------------------
# This is the definition method for the View Menu
#------------------------------------------------------------------------------------------

::itcl::body bis_treegui::makeViewMenu { menu0 } {
    
    #$menu0 add separator
    $menu0 add cascade -label "Choose Icon Colors" -menu $menu0.icontypesub -activebackground "$menuactivebgcolor"
    set icontypecascade [menu $menu0.icontypesub -tearoff 0]
    
    $icontypecascade add cascade -label "Images" -menu $icontypecascade.colorsub1 -activebackground "$menuactivebgcolor"
    set colormenu [menu $icontypecascade.colorsub1 -tearoff 0]
    makeColorMenu $colormenu brainiconchoice
    
    $icontypecascade add cascade -label "Surfaces" -menu $icontypecascade.colorsub2 -activebackground "$menuactivebgcolor"
    set colormenu [menu $icontypecascade.colorsub2 -tearoff 0]
    makeColorMenu $colormenu surfaceiconchoice
    
    $icontypecascade add cascade -label "Results" -menu $icontypecascade.colorsub3 -activebackground "$menuactivebgcolor"
    set colormenu [menu $icontypecascade.colorsub3 -tearoff 0]
    makeColorMenu $colormenu resulticonchoice

    $icontypecascade add cascade -label "ROI Definitions" -menu $icontypecascade.colorsub4 -activebackground "$menuactivebgcolor"
    set colormenu [menu $icontypecascade.colorsub4 -tearoff 0]
    makeColorMenu $colormenu roiiconchoice
}

::itcl::body bis_treegui::makeColorMenu { colormenu icon } {
    
    eval "$colormenu add radio -label Red -variable {[itcl::scope $icon]} -value ibrainred -command { $this updateVisTree $vistree $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$colormenu add radio -label Orange -variable {[itcl::scope $icon]} -value ibrainorange -command { $this updateVisTree $vistree $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$colormenu add radio -label Yellow -variable {[itcl::scope $icon]} -value ibrainyellow -command { $this updateVisTree $vistree $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$colormenu add radio -label Green -variable {[itcl::scope $icon]} -value ibraingreen -command { $this updateVisTree $vistree $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$colormenu add radio -label Blue -variable {[itcl::scope $icon]} -value ibrainblue -command { $this updateVisTree $vistree $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$colormenu add radio -label \"Light Blue\" -variable {[itcl::scope $icon]} -value ibrainlightblue -command { $this updateVisTree $vistree $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$colormenu add radio -label Purple -variable {[itcl::scope $icon]} -value ibrainpurple -command { $this updateVisTree $vistree $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$colormenu add radio -label Rainbow -variable {[itcl::scope $icon]} -value ibrainrainbow -command { $this updateVisTree $vistree $RealTree } -activebackground \"$menuactivebgcolor\""
}

::itcl::body bis_treegui::addNodeToTree { type { title "" } { path "" } } {
    
    if { $path == "" } { set path $selectionPath }
 
    if { $type == "Image" && $title == ""} { 
	set title [ ImageEntryDialog ]
    } elseif { $title == "" } {
	set title [ Single_Entry_Dialog "Set Title" "Enter the name for this node" $type ]
    }

    if { $title == "" } { return }
    
    if { [checkForIllegalCharacters $title] } {
	set title [ $dustin uniqueTitle $title $path ]
	$dustin addNode $title $path $type
	updateTreeWidget
	setDisplayBox "$path/$title"
	setUndoList; set TreeChanged 1
    } else {
	addNodeToTree $type 
    }
}

::itcl::body bis_treegui::addSubtreeAtSelection { {type 1} } {
    
    $mdTopWidget config -cursor watch;  update idletasks

    switch -exact -- $type {

	1 { AddSubtree $RealTree [GetIDFromSelection] }
	2 { AddMultiSubjfMRI $RealTree [GetIDFromSelection] }
	3 { AddCSIPatient $RealTree [GetIDFromSelection] }
	4 { AddAllCSI $RealTree [GetIDFromSelection] }
	5 { AddMSBData $RealTree [GetIDFromSelection] }
	
    }
	$mdTopWidget config -cursor ""
}

::itcl::body bis_treegui::delSelectedFromTree { } {
        
    if { $selectionPath == [ lindex $anatomicalImageList 0 ] } {
	set anatomicalImageList ""
    }
    if { $selectionPath == [ lindex $functionalImageList 0 ] } {
	set functionalImageList ""
    } 
    if { $selectionPath == [ lindex $spaceImageList      0 ] } {
	set spaceImageList ""
    }
    updateRightCanvasDisplay

    set deletedNode $selectionPath
    setDisplayBox [ $dustin getNodeParent $selectionPath ]
    updateGUI
    puts $deletedNode
    $dustin deleteNode $deletedNode
    updateTreeWidget   $deletedNode
    setUndoList; set TreeChanged 1
}
# -----------------------------------------------------

::itcl::body bis_treegui::showImageProcessTool { } { 

    set imageutility [ bis_guiimageutility \#auto ]
    $imageutility InitializeFromContainer $surgerygadget
    set w $mdmenubar.$imageutility
    
    set imageutility [ $imageutility GetThisPointer ]
    $imageutility CreateGUI $w 
    $imageutility AddToMenuButton $toolsmenu
}

#------------------------------------------------------------------------------------------
# These are the SPECT Processing Module Integration Methods
#------------------------------------------------------------------------------------------

::itcl::body bis_treegui::ShowSPECTtool { } {

    if {$SPECT_initialized == 0} {
	$SPECTmodule Initialize .[pxvtable::vnewobj] $this $viewer2
	set SPECT_initialized 1
    }

    $SPECTmodule ShowTop
}

::itcl::body bis_treegui::ShowREGtool { } {

    if {$REG_initialized == 0} {
	$REGmodule Initialize .[pxvtable::vnewobj] $this
	set REG_initialized 1
    }
    $REGmodule ShowTop

}


#------------------------------------------------------------------------------------------
# This is the end of the SPECT Processing Module Integration Methods
#------------------------------------------------------------------------------------------


#------------------------------------------------------------------------------------------
# These are the Electrode Attribute Control Module Integration Methods
#------------------------------------------------------------------------------------------

::itcl::body bis_treegui::mdLoadElectrodeAttributes { } { 

 
    catch {unset AttrArray}
    set newlyLoadedArray [$FileManager LoadElectrodeAttributes]
    if { $newlyLoadedArray != -1} {array set AttrArray $newlyLoadedArray} else {return -1}
    
    #Get all grids, and set up a lookup array
    #----------------------------------------------------------------------
    set ThisNode [GetIDFromSelection]
    EnsureFileLoaded $ThisNode
    set electrodeobj        [$RealTree get $ThisNode pxitclobj]
    set electrodemultigrid  [$electrodeobj GetObject]
   
    set ng [$electrodemultigrid GetNumberOfGrids] 

    for {set gridnumber 0} {$gridnumber < $ng} {incr gridnumber} {
	set grid [ $electrodemultigrid GetElectrodeGrid $gridnumber ]
	set gridname [ $grid GetGridName  ]
	set gridletter [ string range [ string trim $gridname ] 0 0 ]
	set gridnum($gridletter) $gridnumber
	
	scan [ $grid GetDimensions ] "%d %d" dimx dimy
	set gridsize [ expr $dimx * $dimy ]
	
	# Make an array to hash real index to internal index
	#iindex = electrodeInternalIndex(gridnumber,realindex)
	for {set j 0} {$j < $gridsize} {incr j} {
	    set realindex [ $grid GetElectrodeRealIndex $j ]
	    set electrodeInternalIndex($gridnumber,$realindex) $j
	    set elec [ $grid GetElectrode $j ]
	    $elec SetElectrodePresent 0
	    set values [ $elec GetValues ]
	    $values SetNumberOfTuples [llength $AttrArray(titles)]
	    $values FillComponent 0 -1.0
	}
    }
    #----------------------------------------------------------------------

    set l [llength [array names AttrArray]]

    # Now read the attribute array back out and store it in appropriate electrode

    for { set i 0 } { $i < $l } { incr i } {
	
	set thisname [lindex [lsort [array names AttrArray]]  $i]

	if {$thisname != "titles"} {
	    #####-------
	    set gridletter [string range $thisname 0 [expr [string first , $thisname] - 1] ]
	    #####-------
	    
	    set firstcommaindex [string first , $thisname]
	    set secondcommaindex [string first , $thisname [expr $firstcommaindex + 1] ]
	    
	    #####-------
	    set electrodenumber [ string range $thisname [expr $firstcommaindex + 1] [expr $secondcommaindex - 1] ]
	    set valueindex      [ string range $thisname [expr $secondcommaindex +1 ] end ]
	    
	    #####-------
	    
	    set gridindex $gridnum($gridletter) 
	    set electrodeindex $electrodeInternalIndex($gridindex,$electrodenumber) 
	    
	    set grid       [ $electrodemultigrid GetElectrodeGrid $gridindex ]
	    set electrode  [ $grid GetElectrode $electrodeindex ]
	    $electrode SetElectrodePresent 1

	    [ $electrode GetValues ] SetComponent $valueindex 0 $AttrArray($gridletter,$electrodenumber,$valueindex)
#	    puts stderr "$gridletter, $electrodenumber $valueindex =  $AttrArray($gridletter,$electrodenumber,$valueindex) "
	} else {
#	    puts stderr "$thisname is bad"
	}
    }

    #----------------------------------------------------------------------
    #Now all electrode properties have been set - Save a file
    #----------------------------------------------------------------------

    #Save a new file
    set newName "[file rootname [$RealTree get $ThisNode FileName]]_Attr_Loaded.mgrid"
    $electrodemultigrid Save $newName
    
    set changefname [tk_messageBox -type yesno -default no -title "Warning"\
			  -message "Would you like to have this node in the tree point to the new electrode file you just created?" -icon question]

    if {$changefname == "no"} { return -1 }
    if {$changefname == "yes"} {
	setNodeFilename $ThisNode $newName
	$RealTree set $ThisNode Attributes $AttrArray(titles)
	$RealTree set $ThisNode notes "The following attributes are loaded for this electrode file:\n-------------------------------------------------------------\n\n$AttrArray(titles)"
    }
    



}; #end mdLoadElectrodeAttributes method


::itcl::body bis_treegui::SendElectrodeToAtrrControl { { nodeID -1} {raise 1} } {
    
    if {$nodeID == -1} {
	set node [GetIDFromSelection]
    } else { set node $nodeID }
    	

    if {$node != -1 && $node != ""} {
	    
	#--------------------------------------------------
	# First be sure node is an electrode, and is loaded
	#--------------------------------------------------
	EnsureFileLoaded $node
	set pxielectrodeobj [$RealTree get $node pxitclobj]
	set type [$RealTree get $node type]
	if {$type != {Surface Electrode} } { 
	    error "The selected object is not an Electrode Map"
	    return -1  
	}
	
	#--------------------------------------------------
	# Now transform the selected electrode to ref space
	#--------------------------------------------------
	
	if {$SpaceImage != -1} {
	    
	    findTransforms $RealTree $node $SpaceImage
	    set BottomUpTransList $TransformsCache($myname,$node:$SpaceImage)
	    EnsureTransListLoaded $BottomUpTransList
	    
	    set gen [ CreateTransformation $BottomUpTransList ]
	    set newelec [ [pxitclelectrodemultigrid \#auto] GetThisPointer ]
	    $newelec Copy $pxielectrodeobj
	    $newelec Transform $gen
	    
	    #--------------------------------------------------
	    # Now send the transformed electrode object, space 
	    # image object, and selected node's  Attribute title 
	    # list to the Attribute Control
	    #--------------------------------------------------
	    
	    
	    set SpaceImageObject [$RealTree get $SpaceImage pxitclobj]
	    $ElectAttrModule SetElectrodeObject $newelec  $SpaceImageObject \
		[$RealTree get $node Attributes] [$RealTree get $node FileName]
	    if {$raise} {
		$ElectAttrModule ShowTop
	    } 
	    
	} else {
	    error "You must have a Space Image set in order to create an electrode visulization overlay."
	    return -1
	}
	
	
    }
    
};# end SendElectrodeToAttrControl method

::itcl::body bis_treegui::PutElectrodeAttrControlOutputInTree { } {

    if { [$ElectAttrModule GetOutputImage] != -1 } {

	set NewImage [$ElectAttrModule GetOutputImage]
	
	set ObjectID $MasterCount
	incr MasterCount
	$RealTree insert $SpaceImage end $ObjectID
	ImageInitialize $RealTree $ObjectID

	[$RealTree get $ObjectID pxitclobj] ShallowCopy $NewImage

	nameNode $RealTree $ObjectID "Electrode_Overlay_$ObjectID"
	toggleIdentity $ObjectID 1
	
	#-----------------------------------------------------------------------------
	#Everything below here occurs for the initialization of any type added to tree
	#-----------------------------------------------------------------------------
	set pathList [$RealTree rootname]
	set pathListIDs [$RealTree ancestors $ObjectID]
	
	for {set y [expr [llength $pathListIDs] - 1]} {$y > -1} {incr y -1} {
	    if {[lindex $pathListIDs $y] != [$RealTree rootname]} {
		lappend pathList [$RealTree get [lindex $pathListIDs $y] title]
		
	    }
	}
	
	set pathName /
	for {set i 0} {$i < [llength $pathList]} {incr i} {
	    append pathName [lindex $pathList $i]
	    append pathName /
	}
	append pathName [$RealTree get $ObjectID title]
	set NodeIDs($pathName) $ObjectID
	
	set newfilename [$FileManager SaveFile [$RealTree get $ObjectID pxitclobj]]
	setNodeFilename $ObjectID $newfilename
	
	updateVisTree $vistree $RealTree $ObjectID			

	puts "[[$RealTree get $ObjectID pxitclobj] GetDescription]"


    }

};# end BringUpElectrodeAttrControl method


#------------------------------------------------------------------------------------------
# This is the end of the Electrode Attribute Control Module Integration Methods
#------------------------------------------------------------------------------------------


#------------------------------------------------------------------------------------------
# ROI Definiton Stuff
#------------------------------------------------------------------------------------------

::itcl::body bis_treegui::addROIDefToTree { } {
    
    set newnode [lindex [AddROIDefNode $RealTree [GetIDFromSelection]] 2]
    
    #recalculate the transformation cache
    if {[llength $newnode]} {
	updateVisTree $vistree $RealTree $newnode
    }
}

::itcl::body bis_treegui::AddROIDefNode { realtreename ParentNodeID {title -1}} {
    
    if {[llength $ParentNodeID] > 0} {
	if {$title == -1} {
	    set ROIDefTitle [Single_Entry_Dialog "ROI Definition" "Enter a name for the ROI Definition Image"]
	} else { set ROIDefTitle $title }
	
	set origTitle $ROIDefTitle
	
	if {[string match $ROIDefTitle -1] | $ROIDefTitle == ""} { return } else {


	    #----Input Validation----------------------------------------------------------------------
	    for {set a 0} {$a < [string length $ROIDefTitle]} {incr a} {
		set achar [string range $ROIDefTitle $a $a]
		
		if {![string is wordchar $achar] && ![string is space $achar] \
			&& ![string match {[.]} $achar] && ![string match {[-]} $achar] && ![string match {[^]} $achar]} {
		    
		    error "Cannot add ROI image using character $achar  -- Node names can only can contain the following characters: \n     a-z, A-Z, 0-9, _, -, ., ^, and spaces"

		}
	    }
	    #------------------------------------------------------------------------------------------
	    
	    
	    set ProposedPath [file join [getPath $realtreename $ParentNodeID] $ROIDefTitle]
	    set UniqueSuffix 1
	    set suffixed 0
	    
	    while {[Tree::itemexists $vistree $ProposedPath]} {
		
		if { $suffixed == 1 } {
		    #delete the suffix
		    set ROIDefTitle [string replace $ROIDefTitle [string last _ $ROIDefTitle] end]
		}
		
		append ROIDefTitle _ $UniqueSuffix
		set ProposedPath [file join [getPath $realtreename $ParentNodeID] $ROIDefTitle]
		set suffixed 1
		incr UniqueSuffix
	    }
	    
	    
	    if {![Tree::itemexists $vistree $ProposedPath]} {
		
		#Create a unique identifier for the ROIDef
		set ROIDefID $MasterCount
		incr MasterCount
		
		set ROIDefImage $ROIDefID
		
		$realtreename insert $ParentNodeID end $ROIDefID
		ROIDefInitialize $realtreename $ROIDefID
		nameNode $realtreename $ROIDefID $ROIDefTitle
		$realtreename set $ROIDefID type ROIDef
		
				
	    } else { 
		error "Please select a unique image name"
	    }
	}

	set TreeChanged 1	
	return [list $suffixed $origTitle $ROIDefID]
	
    } else {tk_messageBox -type ok -title "Need Selection" -message "Please select a parent in the tree" -icon info}
}

::itcl::body bis_treegui::ROIDefInitialize { realtreename node } {
    
    NodeInitialize $realtreename $node
    
    $realtreename set $node type ROIDef
    $realtreename set $node pxitclobj [ [pxitclimage \#auto] GetThisPointer ]
    
    #A couple display properties for the node
    $realtreename set $node icon $atlasiconchoice
    $realtreename set $node linecolor red
    
    #This node property toggles the "identity" propery for the image - ie, no transformation 
    $realtreename set $node FromParFilenameSet 0
    $realtreename set $node ToParFilenameSet 0
    $realtreename set $node IsIdentity 0
    
        
};# end ROIDefInitialize method


#------------------------------------------------------------------------------------------
# end of ROI Definiton Stuff
#------------------------------------------------------------------------------------------

::itcl::body bis_treegui::bindx1 { W x y } {
    
    #Events for tree function
    set lbl [Tree::labelat $W $x $y ]
    $this setDisplayBox $lbl 
}
 
::itcl::body bis_treegui::setDisplayBox { nodePath } {
   
    if { $nodePath == "" } { return }
    Tree::setCurrent $vistree $nodePath
    Tree::setselection $vistree $nodePath
    if { [ info exist selectionPath ] } { updateNotes }
    set selectionPath [ lindex [ Tree::getselectionpath $vistree ] 0 ]
    updateGUI 
    $this displayFileName
}

::itcl::body bis_treegui::displayFileName { } {
    
    if { $selectionPath == "" } { return }
    $descriptionbox delete 1.0 end
    
    if { [ isRoot $selectionPath ] } { 
	$statusLabel config -text "Filename: Root"
    } else {
	$statusLabel config -text "Filename: [ $dustin getNodeFileName $selectionPath ]"
    }
}

::itcl::body bis_treegui::bindxdouble1 { W x y } {
    
    set lbl [Tree::labelat $W $x $y]
    if { $lbl == "" } { return }
    Tree::setselection $W $lbl
    if { ![ winfo exists $NodeInfoDialogName ] } { createNodeInfoGUI }
    showNodeInfoBox
}

::itcl::body bis_treegui::bindx3 { W x y } {
      
    set lbl [Tree::labelat $W $x $y]
    setDisplayBox $lbl
    if { $lbl == "" } { return }

    switch  -exact [ $dustin getNodeType $selectionPath ] {
	Image     { set menu $popup          }
	Surface   { set menu $surfacepopup   }
	Landmark  { set menu $surfacepopup   }
	Folder    { set menu $folderpopup    }
	Electrode { set menu $electrodepopup }
	default   { set menu $rootpopup      }
    }
    
    tk_popup $menu [winfo pointerx $vistree] [winfo pointery $vistree]
 }


::itcl::body bis_treegui::bindxRightPane { W x y menu} {

    tk_popup $menu [winfo pointerx $IC] [winfo pointery $IC]
}



#----------------------------------------------------------------------
#drag and drop 
#----------------------------------------------------------------------

::itcl::body bis_treegui::bindxcontrol1 { W x y } { 
    #Control Clicking on the tree adds multiple selections
    if { $dragAndDropEnabled } { return 0 }
    set lbl [Tree::labelat $W $x $y]
    Tree::addselection $W $lbl
    displayFileName    
}

::itcl::body bis_treegui::bindxmotion1 { W x y } {
    
    if { $dragAndDropEnabled == 0 } { return 0 }
    if { $selectionPath == "/Data" } { return 0 }

    set widget [ winfo containing [winfo pointerx $W] [winfo pointery $W] ]

    if { $widget == $IC } { 
	displayMarkerOnImageTab $W $x $y
    } elseif { $widget == $vistree } {
	set selectionPath [ lindex [ Tree::getselectionpath $W ] 0 ]
	set currentPath   [ lindex [ Tree::getCurrentPath $W ] 0 ]
	set lbl [Tree::labelat $W $x $y ]
	Tree::setCurrent $vistree $lbl
	$this displayFileName
	if { $currentPath != "" && $selectionPath != "" } {
	    $W configure -cursor plus
	} else { 
	    $W configure -cursor $theNoCursor
	}
    } else {
	$W configure -cursor $theNoCursor
   }
}

::itcl::body bis_treegui::displayMarkerOnImageTab { W x y } {

    set width [ winfo width $vistree ]
    catch {$IC delete box}

    if { $x > [expr 63 + $width] && $x < [expr 203 + $width] && $y > 335 && $y < 448 } {

	$IC create rect 23 265 163 375 -tag box
	$W configure -cursor plus

    } elseif { $x > [expr 203 + $width] && $x < [expr 343 + $width] && $y > 117 && $y < 230 } {

	$IC create rect  163 47 303 157 -tag box
	$W configure -cursor plus

    } elseif { $x > [expr 353 + $width] && $x < [expr 493 + $width] && $y > 335 && $y < 448 } {

	$IC create rect 313 265 453 375 -tag box
	$W configure -cursor plus

    } else { $W configure -cursor $theNoCursor }
}


::itcl::body bis_treegui::bindxrelease1 { W x y mode } {
    
    if { $dragAndDropEnabled == 0 } { return -1 }
  
    set widget [ winfo containing [winfo pointerx $W] [winfo pointery $W] ]
    
    $vistree configure -cursor ""
    . configure -cursor ""

    if { $widget == $IC } { 
	$this releaseOnImagesTab $x $y 
	return 0
    }

    if { $widget == $vistree && $mode } { 
	$this releaseOnTreeCut $W $x $y  
	return 0
    }
    
    if { $widget == $vistree } { 
	$this releaseOnTreeCopy $W $x $y  
	return 0
    }
}

::itcl::body bis_treegui::releaseOnTreeCut { W x y } {
    
    set selectionPath [ lindex [ Tree::getselectionpath $W ] 0 ]
    set currentPath   [ lindex [ Tree::getCurrentPath $W ] 0 ]
     
    #puts "$selectionPath----------$currentPath"
 
    if { $currentPath == "" } { return 0 }
    if { $selectionPath == $currentPath } { return 0 }	

    if { [ $this isCurrentAChildOfSelection $currentPath $selectionPath $W ] } { 
	tk_messageBox -type ok -title "Warning" -message "Cannot cut a node to its descendant." -icon question
	Tree::eraseCurrentBox $W 
	return 0
    }

    if { [ $this isCurrentTheParentOfSelection $currentPath $selectionPath $W ] } {
	tk_messageBox -type ok -title "Warning" -message "Unnecessary cut to parent node." -icon question
	Tree::eraseCurrentBox $W 	
	return 0
    }

    if {       [ $dustin getNodeType $currentPath ] == "Surface"   || \
	       [ $dustin getNodeType $currentPath ] == "Electrode" || \
	       [ $dustin getNodeType $currentPath ] == "Landmark" } {
	
	tk_messageBox -type ok -title "Cannot paste" -message "Surface cannot have children nodes"
	Tree::eraseCurrentBox $W
	return 0
    } 
    
    set ok [ tk_messageBox -type okcancel -title "Warning" -message "Cutting from $selectionPath to $currentPath" -icon question ]
    if { $ok == "ok" } {
	set lbl [Tree::labelat $W $x $y ]
	$this mdCopy 1 
	Tree::setselection $W $lbl
	$this displayFileName
	$this mdPaste $currentPath
	$this updateTreeWidget
    }
    
    Tree::eraseCurrentBox $W 
}

::itcl::body bis_treegui::releaseOnTreeCopy { W x y } {

    set selectionPath [ lindex [ Tree::getselectionpath $W ] 0 ]
    set currentPath   [ lindex [ Tree::getCurrentPath $W ] 0 ]
    
    #puts "$selectionPath----------$currentPath"

    if { $currentPath == "" } {	return 0 }
	
    if {     [ $dustin getNodeType $currentPath ] == "Surface"   || \
	     [ $dustin getNodeType $currentPath ] == "Electrode" || \
	     [ $dustin getNodeType $currentPath ] == "Landmark" } {
	
	tk_messageBox -type ok -title "Cannot paste" -message "Surface cannot have children nodes"
	Tree::eraseCurrentBox $W
	return 0
    } 
    
    set ok [ tk_messageBox -type okcancel -title "Warning" -message "Copying from $selectionPath to $currentPath" -icon question ]
    if { $ok == "ok" } {
	set lbl [Tree::labelat $W $x $y ]
	$this mdCopy 0 
	Tree::setselection $W $lbl
	$this displayFileName
	$this mdPaste $currentPath
	$this updateTreeWidget
    }
    
    Tree::eraseCurrentBox $W 
}

::itcl::body bis_treegui::releaseOnImagesTab { x y } {

    set width [ winfo width $vistree ]
    catch {$IC delete box}

    if { $x > [expr 63 + $width] && $x < [expr 203 + $width] && $y > 335 && $y < 448 } {
	$this setSelectionAnatomical 
    }

    if { $x > [expr 203 + $width] && $x < [expr 343 + $width] && $y > 117 && $y < 220 } {
	$this setSelectionSpace 
    }
    
    if { $x > [expr 353 + $width] && $x < [expr 493 + $width] && $y > 335 && $y < 448 } {
	$this setSelectionFunctional
    }
}

::itcl::body bis_treegui::isCurrentAChildOfSelection { currentPath selectionPath W } {
    
    set exp "^$selectionPath/"
    return [ regexp $exp $currentPath ]
}

::itcl::body bis_treegui::isCurrentTheParentOfSelection { currentPath selectionPath W } {

    if { [ $dustin getNodeParent $selectionPath ] == $currentPath } { 
	return 1 
    } else { return 0 }
}

::itcl::body bis_treegui::showNodeInfoBox { } {

    if { [ wm state $NodeInfoDialogName ] == "normal" } {
	raise $NodeInfoDialogName
    } else { 
	wm deiconify $NodeInfoDialogName
    } 
}

::itcl::body bis_treegui::createNodeInfoGUI { } {

    set NodeInfoDialogName .[ pxvtable::vnewobj ]
    set nodeDialogBGColor "Light Cyan"
    toplevel $NodeInfoDialogName -bg $nodeDialogBGColor
    wm geometry $NodeInfoDialogName +300+200
    
    set infolabelframe [ frame $NodeInfoDialogName.labelfr -bg $nodeDialogBGColor ]
    set infolabeltext  [ label $infolabelframe.labeltxt -bg $nodeDialogBGColor -font -*-times-bold-r-normal-*-18-*-*-*-*-*-iso8859-1 ]
    pack $infolabeltext -side left -padx [list 0 4]
    
    set   NodeInfoTopFrame [ labelframe $NodeInfoDialogName.topframe -bg $nodeDialogBGColor -labelwidget $infolabelframe ]
    pack $NodeInfoTopFrame -side top -ipadx 3 -ipady 7 -padx 10 -pady [list 2 10] -expand true -fill both

    foreach item [ list Type Title FileName TransFromParent TransToParent ] {
	set frame [ frame $NodeInfoTopFrame.frame${item} -bg $nodeDialogBGColor ]
	set entry${item} [ iwidgets::entryfield $frame.ent -background $nodeDialogBGColor -width 75  -labeltext "$item" -relief sunken ]
	if { [ lsearch [ list Title FileName TransFromParent TransToParent ] $item ] > -1 } { 
	    set but [ eval "button $frame.but -text ... -command { $this set${item} ; $this updateGUI } -background white -width 5" ]
	}
	
	if { [ lsearch [ list FileName TransFromParent TransToParent ] $item ] > -1 } { 
	    set clear [ eval "button $frame.clear -text \"Clear\" -command { $this clearTrans $item } -background white -width 5" ]
	}

	pack $frame.ent -fill both -padx {10 0} -side left -expand true
	pack $frame     -side top -anchor w -expand true -fill x
	catch { pack $but   -side left -padx {0 10} }
	catch { pack $clear -side left -padx {0 10} }
    }

    set bottomframe [ frame $NodeInfoTopFrame.bottomsection      -background "$nodeDialogBGColor" ] ; pack $bottomframe -side top -expand 1 -fill both
    set notelabel   [ label $bottomframe.notelabel -text "Notes" -background "$nodeDialogBGColor" ] ; pack $notelabel -side left
    set notebox     [ iwidgets::scrolledtext $bottomframe.note -wrap none -vscrollmode static -hscrollmode static -width 5i -height 2i ]
    pack $notebox -fill x -padx 10 -pady 10 -expand true -fill both -side left

    ::iwidgets::Labeledwidget::alignlabels $entryTitle $entryType $entryFileName $entryTransFromParent $entryTransToParent
   
    updateGUI
}

::itcl::body bis_treegui::updateNotes { } {

    if { ![ winfo exists $NodeInfoDialogName ] } { return }
    if { ![ regexp {.+[^\n]} [ $NodeInfoDialogName.topframe.bottomsection.note get 1.0 end ] text ] } { set text "" }
    set text [ regsub -all {\n} $text  \\n ]
    $dustin setNodeNotes $text $selectionPath
    $NodeInfoDialogName.topframe.bottomsection.note delete 1.0 end
}

::itcl::body bis_treegui::updateGUI { } {
    
    if { ![ winfo exists $NodeInfoDialogName ] } { return }

    if {[ isRoot $selectionPath ]}  { set nodeTitle "Root" 
    } else { set nodeTitle [ $dustin getNodeTitle $selectionPath ] }

    wm title $NodeInfoDialogName "Info for $nodeTitle"
    $NodeInfoDialogName.labelfr.labeltxt configure -text $nodeTitle 
    
    set updateList [ list Type Title FileName ] 
    set hideList   [ list TransFromParent TransToParent ]

    #surface,landmarks, and electrode all have same option definded above
    switch  -exact [ $dustin getNodeType $selectionPath ] {
	
	Surface   { } 
	Landmark  { } 
	Electrode { }
	Image     { 
	    set updateList [ list Type Title FileName TransFromParent TransToParent ] 
	    set hideList   [ list ]
	}
	Folder    {
	    set updateList [ list Type ]
	    set hideList   [ list FileName Title TransFromParent TransToParent ] 
	}
	default   {     
	    set updateList [ list ]
	    set hideList   [ list Type Title FileName TransFromParent TransToParent ] 
	}
    }
    
    foreach item $updateList {
	catch { pack $NodeInfoDialogName.topframe.frame${item}       -side top -anchor w -expand true -fill x }
	catch { pack $NodeInfoDialogName.topframe.frame${item}.ent   -fill both -padx {10 0} -side left -expand true } 
	catch { pack $NodeInfoDialogName.topframe.frame${item}.but   -side left -padx {0 10} }
	catch { pack $NodeInfoDialogName.topframe.frame${item}.clear -side left -padx {0 10} }
	$NodeInfoDialogName.topframe.frame${item}.ent delete 0 end
	$NodeInfoDialogName.topframe.frame${item}.ent insert 0 [ $dustin getNode${item} $selectionPath ]
    }
    
    foreach item $hideList { 
	catch { pack forget $NodeInfoDialogName.topframe.frame${item} }
	catch { pack forget $NodeInfoDialogName.topframe.frame${item}.ent } 
	catch { pack forget $NodeInfoDialogName.topframe.frame${item}.but }
	catch { pack forget $NodeInfoDialogName.topframe.frame${item}.clear }
    }

    pack forget $NodeInfoDialogName.topframe.bottomsection -side top -expand 1 -fill both
    pack $NodeInfoDialogName.topframe.bottomsection -side top -expand 1 -fill both
    set text [ regsub -all {\\n} [ $dustin getNodeNotes $selectionPath ] \n ]
    $NodeInfoDialogName.topframe.bottomsection.note insert 1.0 $text
}

::itcl::body bis_treegui::setPatientProperty { property entryfield } {
    
    #Get input from user
    set thisinput6 [Single_Entry_Dialog "New Value" "Enter new value for $property"]
    if {$thisinput6 != -1 } {

	set thisnode [GetIDFromSelection]
	array set tempProps [$RealTree get $thisnode Properties]
    
 	set tempProps($property) $thisinput6

	$RealTree set $thisnode Properties [array get tempProps]
	
	#update the nodeinfo box
	$entryfield clear
	$entryfield insert 0 $thisinput6

	set TreeChanged 1

    }


}; #End setPatientProperty method

::itcl::body bis_treegui::isRoot { nodeID } {
    
    return [ expr ![ regexp {(/)(.+)(/)} $selectionPath ] ]
}     

::itcl::body bis_treegui::setSelectionSpace { } {

    if { [ isRoot $selectionPath ] } { return }
    set filename [ $dustin getNodeFileName $selectionPath ] 
   
    if { $SpaceLocked == 1 } {
	tk_messageBox -type ok -title "Warning: Cannot set Space Image" -message "Space Image Locked" -icon error ; return
    }
    
    if { $filename  == "" } {
	tk_messageBox -type ok -title "Warning: Cannot set Space Image" -message "Image Filename not set" -icon error ; return
    }
    
    if { ![ file exist $filename ] } {
	tk_messageBox -type ok -title "Warning: Cannot set Space Image" -message "Image Filename does not exist" -icon error ; return
    }
    
    set spaceImageList [ list $selectionPath [ $dustin getNodeTitle $selectionPath ] ]
    updateRightCanvasDisplay 
}


::itcl::body bis_treegui::setSelectionAnatomical { } {
    
    if { [ isRoot $selectionPath ] } { return }
    set filename [ $dustin getNodeFileName $selectionPath ] 
    
    if { $filename  == "" } {
	tk_messageBox -type ok -title "Warning: Cannot set Anatomical Image" -message "Image Filename not set" -icon error ; return
    }
    
    if { ![ file exist $filename ] } {
	tk_messageBox -type ok -title "Warning: Cannot set Anatomical Image" -message "Image Filename does not exist" -icon error ; return
    }

    set anatomicalImageList [ list $selectionPath [ $dustin getNodeTitle $selectionPath ] ]
    updateRightCanvasDisplay 
}

::itcl::body bis_treegui::setSelectionFunctional { } {
    
    if { [ isRoot $selectionPath ] } { return }
    set filename [ $dustin getNodeFileName $selectionPath ] 
    
    if { $filename  == "" } {
	tk_messageBox -type ok -title "Warning: Cannot set Functional Image" -message "Image Filename not set" -icon error ; return
    }
    
    if { ![ file exist $filename ] } {
	tk_messageBox -type ok -title "Warning: Cannot set Functional Image" -message "Image Filename does not exist" -icon error ; return
    }
    
    set functionalImageList [ list $selectionPath [ $dustin getNodeTitle $selectionPath ] ]
    updateRightCanvasDisplay 
}

::itcl::body bis_treegui::updateOverlayCanvas { } {
    
    $OCanv delete presPIC
    if { [ $surgerygadget cget -overlayinputbase ] != -1 && [ $surgerygadget cget -overlayinputfunc ] != -1 } {
	set OC_reslice_presentPIC [ $OCanv create image $OCdispX $OCdispY -image multicolorbrain -anchor nw -tag presPIC ]
    } 
    
    $OCanv delete ocSPACE
    if { $spaceImageList == "" } {
	set OC_SPACE [ $OCanv create text [ expr $OCdispX+205 ] [ expr $OCdispY+60 ] -text \
			   "Space" -fill grey61 -font {helvetica 15 bold} -tag ocSPACE ]
    } else {
	set OC_SPACE [ $OCanv create text [expr $OCdispX+220] [expr $OCdispY+60] -text \
			   "SPACE: [ lindex $spaceImageList 1 ]" -fill "darkgreen" -font {helvetica 11 bold} -tag ocSPACE -width 145 ]
    }
    
    $OCanv delete ocFUNC
    if { $functionalImageList == "" } {
	set OC_FUNC [ $OCanv create text [ expr $OCdispX+375 ] [ expr $OCdispY+20 ] -text \
			  "Functional" -fill grey61 -font {helvetica 15 bold} -tag ocFUNC ]
    } else { 
	set OC_FUNC [ $OCanv create text [ expr $OCdispX+315 ] [ expr $OCdispY+20 ] -text \
			  "FUNCTIONAL: [ lindex $functionalImageList 1 ]" -fill "darkgreen" -font {helvetica 11 bold} -tag ocFUNC -width 150 -justify left -anchor w ]
    }
    
    $OCanv delete ocANAT
    if { $anatomicalImageList == "" } {
	set OC_ANAT  [ $OCanv create text [ expr $OCdispX+375 ] [ expr $OCdispY+110 ] -text \
			  "Anatomical" -fill grey61 -font {helvetica 15 bold} -tag ocANAT ]
    } else { 
	set OC_ANAT  [ $OCanv create text [ expr $OCdispX+315 ] [ expr $OCdispY+110 ] -text \
			  "ANATOMICAL: [ lindex $anatomicalImageList 1 ]" -fill "darkgreen" -font {helvetica 11 bold} -tag ocANAT -width 150 -justify left -anchor w ]
    }
}

::itcl::body bis_treegui::ShowTextBox { parent } {
    
    set base $parent
    
    frame $base.toptextboxframe    -width 450 -height 400
    frame $base.bottomtextboxframe -width 450 -height 70
    
    set descriptionbox $base.toptextboxframe.descriptionbox 
    set ybar    $base.toptextboxframe.ybar 
    set xbar    $base.xbar 
    eval "scrollbar $ybar  -command { $descriptionbox yview } -orient vertical"
    eval "scrollbar $xbar  -command { $descriptionbox xview } -orient horizontal"
    eval "text $descriptionbox  -width 150 -height 30  -wrap word -relief ridge -yscrollcommand { $ybar set} -xscrollcommand {$xbar set} -bg black -fg white"
    
    pack $base.bottomtextboxframe -side bottom -expand f -fill x -padx 5 -pady 2
    pack $xbar -side bottom -expand f -fill x 
    pack $base.toptextboxframe -side top -expand true -fill both -padx 2 -pady 5
    pack $ybar -side right -expand false -fill y
    pack $descriptionbox -side left -expand true -fill both
    $descriptionbox configure -state disabled
}

::itcl::body bis_treegui::showGrabButtonDialog { } {
    
    if {![winfo exists $showGrabButtonDialogName]} {
        set showGrabButtonDialogName .[ pxvtable::vnewobj ]
	toplevel $showGrabButtonDialogName
	wm title $showGrabButtonDialogName "Grab"
	
	#Create the control frame at the bottom of the left pane
	set leftwrapperframe [frame $showGrabButtonDialogName.leftwrapper -bg "light blue"]
	pack $leftwrapperframe -side bottom -fill x -padx 4 -pady 4
	set leftcontrolsframe [labelframe $leftwrapperframe.controls -bg "light blue" -text "Grab Item From Viewer" -labelanchor n]
	pack $leftcontrolsframe -side bottom -fill x -padx 4 -pady 2
	
	set refgrabsframe [labelframe $leftcontrolsframe.refgrabbuttons -bg "light blue" -text "Reference" -labelanchor s]
	set transgrabsframe [labelframe $leftcontrolsframe.transgrabbuttons -bg "light blue" -text "Transform" -labelanchor s]
    
	set grimagebut [eval "button $refgrabsframe.getimg -text \"Image\" -command { $this PutViewerObjectInTree 1 Image}"]
	set grsurfacebut [eval "button $refgrabsframe.getsurf -text \"Surface\" -command { $this PutViewerObjectInTree 1 Surface }"]
	set grlandbut [eval "button $refgrabsframe.getland -text \"Landmark\" -command { $this PutViewerObjectInTree 1 Landmark }"]
	set grelecbut [eval "button $refgrabsframe.getelec -text \"Electrode\" -command { $this PutViewerObjectInTree 1 Electrode }"]
	set gtimagebut [eval "button $transgrabsframe.getimg -text \"Image\" -command { $this PutViewerObjectInTree 2 Image}"]
	set gtsurfacebut [eval "button $transgrabsframe.getsurf -text \"Surface\" -command { $this PutViewerObjectInTree 2 Surface }"]
	set gtlandbut [eval "button $transgrabsframe.getland -text \"Landmark\" -command { $this PutViewerObjectInTree 2 Landmark }"]
	set gtelecbut [eval "button $transgrabsframe.getelec -text \"Electrode\" -command { $this PutViewerObjectInTree 2 Electrode }"]
	
	pack $refgrabsframe -side left -fill x -expand 1 -padx 2 -pady 3
	pack $transgrabsframe -side left -fill x -expand 1 -padx 2 -pady 3 
	pack $grimagebut -side top -fill both -expand 1 -padx 5 -pady [list 3 0]
	pack $grsurfacebut $grlandbut $grelecbut -side top -fill both -expand 1 -padx 5
	pack $gtimagebut  -side top -fill both -expand 1 -padx 5 -pady [list 3 0]
	pack $gtsurfacebut $gtlandbut $gtelecbut -side top -fill both -expand 1 -padx 5
    }

    if { [wm state $showGrabButtonDialogName] == "normal" } {
	raise $showGrabButtonDialogName
    } else { 
	wm deiconify $showGrabButtonDialogName
    }    
}


::itcl::body bis_treegui::ShowMidpaneTools { parent } {
        
    image create photo smallviewericon -data {
	R0lGODlhHgAaAOf/AAABAAIABQACAAYAAAcAAAABDgEEAAIFAQUHAwYGEgcJBQgL\
	    Bw8JBwsNCgwPCxcLCxIUERUSHw8WHBUWHRYYFRYXHhcYFhkbGBocGRwd\
	    Gx0fHCUcHSIkIiosKSU0JTAxLzg5Nzk6OEI3ODs9Ojw+O0E8Oz0/PD9APj9C\
	    T0BJOkRGQ0VHRElKSE5KSU1PTFtRUVVWVFtaUltdWlxeW1NiZ15gXWBiX2Fj\
	    YF1oaWFlcmhoYCh8r2hpZ2Vodmxua29uZm1vbG9xbj+CnnFzcHtwcHV3dHZ4\
	    dT6Ou3SBdXt9ekCQvX9+dkGRv31/fEiPt02TvIKEgXuHh0+VvY1/jISGg1CW\
	    voeGfleVuFGXv1OYwYqJgYSIl1SZwoiKh1Wbw4yMg4eLmouNil2bvo6NhYyO\
	    i4+OhpCPh4+RjpSTi5SWk5iXj5ial5aZqJybk5Wjl52fnJakmKebnJufrpim\
	    mqWgn5upnaOloqijop2rn6WnpKaopbCkpaqpoKuqoaGtrqmrqKyroq2so6er\
	    u6utqq6tpK+upaqvsa6wrbGwqKeztLKxqa2ytKm3qrOyqrC2rLW0rKu5rbO1\
	    sra2rbW3tLm4r7u6sbm7uLy7srq9rbm6xL28s7PBtbu9ur69tL++tcC/tsHA\
	    t77BvbjGucLBucDCvsPCusfDtcTEu8DGvMXFvMPFwsTGw8fGvb3Lv8jHvs3F\
	    vsPKv8bIxdPDvsnIv8XMwcvKwdLGxsnLyMzLwsfOw83Mw8vOys/OxcbUx9DP\
	    x8vSx87QzNHRyNDSz9PSyc7VytTTytHU0NXUy9rSy9DXzNbVzNPW0tfWzdrW\
	    x9/S0tjXztvXyOHU1NrZ0NXa3Nzb0uDczeDa2d7d1OHb2uHez9/e1drh1uLf\
	    0ODf1uPd3N7g3eHg1+Tg0eLh2OXh0uDi3+Pi2ebi0+fj1OXk2+jk1efm3eno\
	    3+fp5uzp2urp4Ovq4e7q2+zr4u/r3O3s4/Ds3e7t5PHt3uvu6u/v5e3v6/Pv\
	    4O7w7fHw5vLx6PPy6fL08CH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAsAAAA\
	    AB4AGgAACP4AhTDhUuWIlCwDmWTJ8kRJFi9VshxBSLDKkx07nFwRkwgTJj6d\
	    avXBVEhSoFyOAgXqg6pTIULVAgGitA0cuHDhiOEAouWLz58+rejQ8aNoM3vx\
	    6MGzp8+evXr17G2TQECAgAACAAhAgIBAVa1ZW0WFSjaqPX7dJGz9gOIEAqtW\
	    I3DgoEAAAVpmnTolu2+ahABdVLHJlOQthBtbwiThcUFALn384uWilQuWvsvq\
	    eEkoYWhfJna2PgSgckfQoj13mhBglW7btmvJtiVTpw6dumIVXuyJNiXaHhEK\
	    +GyiAgcPHkceLqHKVW8bJZvbYKnrBEsCj0h0thg6UwJACxw9DP7ZSgSjgSlk\
	    r0aZkoWpkblfjoYlk5DhDpkcce5YyBogAQxSewQAgAxF/RAED0X84MMz1eCC\
	    y18BMFBABhaA1R8AH2Tw1hJhfGGGGWWsgUYb3JxDzS8SAKBiAQBgBReLKmI1\
	    SzW6aMLNPM3Q81RUaWlFQAFwBRkkAIFsc86R2+hS4pHuVJKiVQiAJWSQnYzz\
	    Dj/z8KNOPPx0aU8ualHQxRx/jDAlXADUEs4vmGRTDzHyOIVPc3/xYIwo3mTi\
	    wJlWwdTaOenkss2f7Tj5ABG2eOJNHBtUNSUAnYRjz5zN1aNPP/zgo8tmd2DT\
	    izd3tODolLRsk4sm49gDTT387DUVEcrC7NPKPrEkwacAhFBzzqDq0DKOa+k0\
	    KQEU5GSChC3sEHErJdrEE8829ZTzzmX+6HOLBCEss4wbmQhzgpRBEgAIKq4w\
	    g0o1v8jmiCOoaBbAGs4wYkwY4AqZCjWndGNPMp1w0086o6Cb4gIupNBCvUPq\
	    gokn9KxTyyntxFNKLZ0ok6KKGN8qgCnqtGYOoEYeWQ4xNNRQgw0mp5yyDCys\
	    sAILnzwjzTPJJCNNzck88wwwfjzCSzLKBC100L7Iscgihhx9yNGLLK000gEB\
	    ADs=
    }			
    
    
    image create photo brainbg -data {
	
	R0lGODlhigBzAKEDAMnJycrKyszMzP///yH+FUNyZWF0ZWQgd2l0aCBUaGUg\
	    R0lNUAAh+QQBCgADACwAAAAAigBzAAAC/pyPqcvdAqOctAqHs968MwuG4uSV\
	    5ukF48qG6AujakvXUIznj83b+o/rCYXAYmeIJBqXiqTTyQQ+p9BojIpFWlHZ\
	    rnZ79IqVYMxsjK6VHek2b910y9XwwfxOg+P3qzX/P7IFOAgSRXhosYS4SFHE\
	    +BjxAzl5E0RJeXWJ+aKpydl5eQLaWTJKGmbqyZEKqsE66vrayiY7u1N7uoBr\
	    +rFri+DLmxAMC0z8a3f8qwwacMBsC30qPU3taX2Njam9ze39DR4uPk5ebn6O\
	    nq6+zt7u/g4fLz9PD59cj3WPP2WwT2Vwxt+XfgIHEizYQwEAhD56MWSB4WGg\
	    DBJdxKpIYgPGdQkAUG30sLGSx4qlPpYkaQIjF4mfGMJ4mMmfDoGS5jFx5+dc\
	    HWPjdsYJ59Oht6BCsRG9ZfQoUmhKKULr2DSisqiriFEd+erqyT9ac/LpWmcP\
	    2J13xvqcY5ZomrRNvbDVyu/t2CFy0yasa5cOXrN69/Lt47dEAQA7
    }
    
    
    image create photo blackandwhitebrain -data {
	
	
	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
    }
    
    
    
    
    image create photo multicolorbrain -data {
	
	R0lGODlhigBzAOf/AAgLBxkbGDkOJiwWIzURNDAWRkQYFkgZDTgeITYVW1IU\
	    GEkYJSkpJz0kGTMjPkUZV0EfVzEoUzAtO0UiRUEoOE0iODwlVzsyHk4jb1st\
	    JGAuFFE0I1I3FEctcEctgVQmiWMwR1cwbGkrcD1Af2I0XGA5SlU7Zk9ETmI2\
	    aFUypFRAX0lKSUs7olJAdkpFclZPIUtUKk1XFmdLEEpLY29BNVs7lHZCJWA8\
	    hV5TEURFo2M9eldQOFZAlVhEiU9GmG5MKGpMO2s9iXxKGVhiBYsukT5SonU4\
	    n09SlJoqplFLvWdDuKgpn4U+loo4qVBUs2hEyXtcGF1fXGVMs2JZgUdaxj1k\
	    sag0kmlVjV1bjntDwFJjhmxZeXtVZnVRjWBYq1BlkndnHUtva19ie0tit4lA\
	    yU1sgXVlOktnpmpyGIdNkG5ib5NJkW9Wr2FpcGdoZnhOxHdhYVxipnZUsYJN\
	    t3Faolx9I3JpVIRSo2h9EIRkWaJRcpdeW09u3WNryWptsmKAZVl1uVV1xEaA\
	    tE6LZlSBj2hyqVF7uGJ0sKVZj2d7goxftXd2dLNWfIRgx1t6rVaNVm6CUVx9\
	    pH9ze1B61nJ1llOKemN9mGODeFyEhmt3o41lrGR/kXmDQ3l4fkyHqZB+IIWF\
	    G0qCz3F6kKdjeVeFnatqSrFqO6tlaVOMiIJrvZZvdJRrkIJvsYtuo354ko9z\
	    hXaTHoJ1omecIZV3a4t1k6RwaoKDbp16YJiEPXmGjpKCdJiDY4uEg2aZeIWH\
	    hFmjZqOAWIyKZ52FWWeNyI2EkmmiVJWLWWqQuHCuEGKbp4mVZWCnfZaXQH+f\
	    V3iha5OYVXuOzYeYeJGRjnCikpKVf2+hoIukR5eQqp6PnX2wTaCmK5eXoGS8\
	    aZqZlniti2u6e5i0OHrKFJq4H52Yw4C5bYvAK6edonjEWqKkoa2eq7OWzKeo\
	    pY7ITIPVPaayqK+vrYPXVZ7TI43fILW3psOo0be2tMGx0qrJoLq60cPCwcrM\
	    ydDO2dXX1N7g3Obo5f///yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQB\
	    CgD/ACwAAAAAigBzAAAI/gD/CRxIsKDBgwgTJtTHsKHDhxAj6lNIsaLFixgz\
	    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\
	    msf6qdd6PewHnIF5LD63rd/ngAAAOw==	
    }
    
    # ShowMidpaneTools begins here 
    
    set wr $parent
    
    #This stuff ends up on the "Images" tab of the middle window in bis_treegui
    set ICbackgroundcolor "LightSteelBlue1"
    set IC [canvas $wr.imagecanvas -height 500 -bg "$ICbackgroundcolor"];     pack $IC -fill both -expand 1
    
    #This is the button frame window which will pack into the canvas at each brain
    foreach n {SpaceImage AnatomicalImage FunctionalImage} {
	
	set bf_$n [frame $midpane.viewbuttonsframe_$n -bg $ICbackgroundcolor -borderwidth 2 -relief groove]
	pack $midpane.viewbuttonsframe_$n
	set bftf [frame $midpane.viewbuttonsframe_$n.topfr -bg $ICbackgroundcolor]; pack $bftf -padx 4 -pady {1 3}
	set bfbf [frame $midpane.viewbuttonsframe_$n.bottomfr -bg $ICbackgroundcolor]; pack $bfbf -padx 2 -pady {1 3}
	
	set viewer1but [eval "button $bftf.view1but -image smallviewericon -height 16 -width 24\
			    -command {$this sendSelectionToDisplay 1 $n } "]
	set viewer1butlabel [label $bftf.label1 -text "RF Viewer" -font {helvetica 13 bold} -bg "$ICbackgroundcolor"]
	pack $viewer1but $viewer1butlabel -side left -pady {3 0}
	
	set viewer2but [eval "button $bfbf.view2but -image smallviewericon -height 16 -width 24\
			    -command {$this sendSelectionToDisplay 2 $n } "]
	set viewer2butlabel [label $bfbf.label2 -text "TR Viewer" -font {helvetica 13 bold} -bg "$ICbackgroundcolor"]
	pack $viewer2but $viewer2butlabel -side left -pady {0 2}
	
	
	if {$n != "SpaceImage"} {
	    
	    set REFcheckbox [checkbutton $midpane.viewbuttonsframe_$n.refcheckbut \
				 -text "Ref Space" -variable [ itcl::scope REF_$n ] -bg $ICbackgroundcolor]
	    pack $REFcheckbox -side top -pady {0 3}
	    
	    eval "$viewer1but configure -command {$this sendSelectionToDisplay 1 $n}"
	    
	    eval "$viewer2but configure -command {$this sendSelectionToDisplay 2 $n}"
	    
	    
	};# End "if != SpaceImage
	    
	};# End foreach
	
    
    
    
    
    #**************************************************
    set rbX 165
    set rbY 45
    set refbrainBG [$IC create image $rbX $rbY -image brainbg -anchor nw -tag refAREA]
    set refbrainTITLE [$IC create text [expr $rbX+80] [expr $rbY+130] -text Space \
			   -fill blue -font {times 20 bold} -tag refAREA -anchor e]
    set refbrainTEXT  [$IC create text [expr $rbX+65] [expr $rbY+52] -text "Not Set" \
			   -fill grey61 -activefill yellow -font {helvetica 15 bold} -tag refTEXT]
    
    set refbrainBUTTONS [$IC create window [expr $rbX+145] [expr $rbY+140] -window $bf_SpaceImage]
    #**************************************************
    set abX 25
    set abY 265
    set anatomicalbrainBG [$IC create image $abX $abY -image brainbg -anchor nw -tag anatomAREA]
    set anatomicalbrainTITLE [$IC create text  [expr $abX+90] [expr $abY+130] -text Anatomical \
				  -fill blue -font {times 19 bold} -tag anatomAREA -anchor e]
    set anatomicalbrainTEXT  [$IC create text [expr $abX+65] [expr $abY+52] -text "Not Set" \
				  -fill grey61 -activefill yellow -font {helvetica 15 bold} -tag anatomTEXT]
    
    
    set anatomicalbrainBUTTONS [$IC create window [expr $abX+153] [expr $abY+146] -window $bf_AnatomicalImage]
    #**************************************************
    set fbX 315
    set fbY 265
    set funcbrainBG [$IC create image $fbX $fbY -image brainbg -anchor nw -tag funcAREA]
    set funcbrainTITLE [$IC create text  [expr $fbX+90] [expr $fbY+130] -text Functional \
			    -fill blue -font {times 19 bold} -tag funcAREA -anchor e]
    set funcbrainTEXT  [$IC create text [expr $fbX+65] [expr $fbY+52] -text "Not Set" \
			    -fill grey61 -activefill yellow -font {helvetica 15 bold} -tag funcTEXT]
    
    set funcbrainBUTTONS [$IC create window [expr $fbX+150] [expr $fbY+146] -window $bf_FunctionalImage]
    #**************************************************
    
    drawAnatSpaceArrow grey80
    drawFuncSpaceArrow grey80
      
    #menus associated with the right click binding
    #Space Image
    set rpp_space [menu $IC.spacemenu -tearoff 0]
    eval "$rpp_space add command -label \"Clear\" -command { set \"[itcl::scope SpaceImage]\" -1; $this updateRightCanvasDisplay } -underline 0"

    #Anatomical Image
    set rpp_anat [menu $IC.anatmenu -tearoff 0]
    eval "$rpp_anat add command -label \"Clear\" -command { set \"[itcl::scope AnatomicalImage]\" -1; $this updateRightCanvasDisplay } -underline 0"

    #Functional Image
    set rpp_func [menu $IC.funcmenu -tearoff 0]
    eval "$rpp_func add command -label \"Clear\" -command { set \"[itcl::scope FunctionalImage]\" -1; $this updateRightCanvasDisplay} -underline 0"
    
    #Bind a right click on the pic or text for each of the three to the popup menus just created
    eval "$IC bind refPIC <3> { $this bindxRightPane %W %x %y $rpp_space }"
    eval "$IC bind refTEXT <3> { $this bindxRightPane %W %x %y $rpp_space }"
    eval "$IC bind anatomPIC <3> { $this bindxRightPane %W %x %y $rpp_anat }"
    eval "$IC bind anatomTEXT <3> { $this bindxRightPane %W %x %y $rpp_anat }"
    eval "$IC bind funcPIC <3> { $this bindxRightPane %W %x %y $rpp_func }"
    eval "$IC bind funcTEXT <3> { $this bindxRightPane %W %x %y $rpp_func }"
}   

::itcl::body bis_treegui::OCanvasInitialize { canvas } {
    
    ##########################################################################################
    ###########################                                     ##########################
    ###########################         Overlay Tab Canvas          ##########################
    ###########################                                     ##########################
    ##########################################################################################

    set OCanv $canvas
    
    set OCdispX 15
    set OCdispY 20
    set OC_BG [$OCanv create image $OCdispX $OCdispY -image brainbg -anchor nw -tag ocAREA]
    set OC_TITLE [$OCanv create text [expr $OCdispX+160] [expr $OCdispY+145] -text "Resliced Image" \
		      -fill blue -font {times 20 bold} -tag ocAREA -anchor e]
    set OC_TEXT  [$OCanv create text [expr $OCdispX+65] [expr $OCdispY+52] -text "Empty" \
		      -fill grey61 -font {helvetica 15 bold} -tag ocTEXT]
    set OC_FUNC  [$OCanv create text [expr $OCdispX+375] [expr $OCdispY+20] -text "Functional" \
		      -fill grey61 -font {helvetica 15 bold} -tag ocFUNC]
    set OC_ANAT  [$OCanv create text [expr $OCdispX+375] [expr $OCdispY+110] -text "Anatomical" \
		      -fill grey61 -font {helvetica 15 bold} -tag ocANAT]
    set OC_SPACE  [$OCanv create text [expr $OCdispX+205] [expr $OCdispY+60] -text "Space" \
		       -fill grey61 -font {helvetica 15 bold} -tag ocSPACE]
    
    set doublearrowcolor "LightSteelBlue"
    $OCanv create line [expr $OCdispX + 340] [expr $OCdispY + 40] \
 	[expr $OCdispX + 338] [expr $OCdispY + 50] \
	[expr $OCdispX + 325] [expr $OCdispY + 55] \
 	[expr $OCdispX + 300] [expr $OCdispY + 60] \
	-tag OCtopline -smooth true  -splinesteps 20 -width 12 \
	-arrow none -arrowshape {15 18 8}  -fill "$doublearrowcolor"

    $OCanv create line [expr $OCdispX + 340] [expr $OCdispY + 80] \
 	[expr $OCdispX + 338] [expr $OCdispY + 70] \
	[expr $OCdispX + 325] [expr $OCdispY + 65] \
 	[expr $OCdispX + 300] [expr $OCdispY + 60] \
	-tag OCbotline -smooth true  -splinesteps 20 -width 12 \
	-arrow none -fill "$doublearrowcolor" -arrowshape {15 18 8}
    
     $OCanv create line [expr $OCdispX + 289] [expr $OCdispY + 60] \
 	[expr $OCdispX + 290] [expr $OCdispY + 60] \
 	-tag OCarrow -smooth true  -splinesteps 20 -width 1 \
 	-arrow first -arrowshape {15 18 13}  -fill "$doublearrowcolor"

}


#------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------
#  This is the most important method of bis_treegui - it creates all the frames and widgets
#------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------

::itcl::body bis_treegui::ShowManager {pw surgerygadget0 menubase } {

   
    #Set a variable to hold the top window
    set mdTopWidget $pw
    set surgerygadget $surgerygadget0
    
    #---------------------------------------------------------------------------
    #Create a top frame to hold the panedwindow and the status bar frame
    set top [frame $mdTopWidget.topframe -width 1100 -height 700]
    pack $top -expand 1 -fill both
    pack propagate $top 0
    
    
    #---------------------------------------------------------------------------
    #Show the Status Bar at the Bottom - pack it into the $top frame
    set statusbar [frame $mdTopWidget.status -borderwidth 3 -relief ridge -height 20]
    pack $mdTopWidget.status -in $top -side bottom -fill x
    #Add a label
    
    set statusLabel [label $statusbar.l -text "Status Bar" -fg black -bg [$statusbar cget -bg]]
    pack $statusLabel -side left
    
    #Create a paned window - pack it into the $top frame
    panedwindow $mdTopWidget.mainpane -orient horizontal -showhandle 1 \
	-borderwidth 2 -relief raised -sashwidth 4 -sashpad 1 \
	-handlesize 5 -handlepad 50
    pack $mdTopWidget.mainpane -in $top -expand 1 -fill both


    set LeftPaneColor white
    set MidPaneColor "light steel blue"
    set RightPaneColor "medium sea green"
    
    #Create the three frames in paned window
    set leftpane [frame $mdTopWidget.mainpane.left -bg $LeftPaneColor -width 375]
    set midpane [frame $mdTopWidget.mainpane.middle -bg $MidPaneColor -width 600 -height 50]
    set rightpane [frame $mdTopWidget.mainpane.right -bg $RightPaneColor -width 200]
    
    pack propagate $midpane 0;  #Don't let window shrink to wrap buttons; we'll let the buttons grow
    pack propagate $leftpane 0;
    pack propagate $rightpane 0;
    
    $mdTopWidget.mainpane add $leftpane
    $mdTopWidget.mainpane add $midpane -minsize 300
    #    $mdTopWidget.mainpane add $rightpane
    
    
    ShowTextBox $rightpane
    
    
    
    
    #------------------------------------------------------------------------------------------
    #Left Pane
    #------------------------------------------------------------------------------------------
    #Initialize the Left Pane with tree in it
    #Put a visualization tree in the left frame (Tree name $leftpane.w)
    #Create a labelframe to go around tree
    
    
    set treeframe [ labelframe $leftpane.treeframe -bg $LeftPaneColor -text "Image List"  ]
    pack $treeframe -fill both -expand true -padx 5 -pady 2
    
    #Set a variable "vistree" to hold the tree
    set vistree $treeframe.w
#    focus $treeframe
    #Create the tree and its associated scrollbar and pack into treeframe
    
    eval "Tree::create $vistree -bg $LeftPaneColor -width 170 -yscrollcommand {$treeframe.sb set}"
    
    eval "scrollbar $treeframe.sb -orient vertical -command { $treeframe.w yview }"
    pack $vistree -side left -fill both -expand 1 -padx {4 0} -pady {0 0}
    focus $vistree
    pack $treeframe.sb -side left -fill both -padx {0 3} -pady {0 3}
    
    set grabButton [eval "button $leftpane.gb -text \"Grab an Object from Viewer\" -command { $this showGrabButtonDialog }"]
    pack $grabButton -fill x
    
    #---------------------------------------------------------------------------
    #Create a struct::tree object to hold pointer keys to the image objects
    #This is the heart of the tree -- RealTreex
    set RealTree 0
    set dustin [ [ dsitcltree \#auto new ] GetThisPointer ]
    setUndoList
    set TreeChanged 0
    updateTreeWidget
    setDisplayBox /Data
   
    #------------------------------------------------------------------------------------------
    #---------------------------------------------------------------------------
    #Create a menubar at the top
    #---------------------------------------------------------------------------
    #------------------------------------------------------------------------------------------

    set menucolor "#ede9e3"
    set menuactivebgcolor "#ede9e3"

    catch {
	set menucolor [option get $mdTopWidget background ""]
	if { $menucolor == "" } {
	    set menucolor white
	}
	set menuactivebgcolor [option get $mdTopWidget background ""]
	if { $menuactivebgcolor == "" } {
	    set menuactivebgcolor "#6666cc"
	}
    }

    set mdmenubar $menubase
    # [ $surgerygadget cget -menubase ]
    $mdmenubar configure -background $menucolor
    $mdmenubar configure -activebackground $menuactivebgcolor

    foreach m { File Edit Tools Options } {
	set $m [menu $mdmenubar.m$m -tearoff 0]
	$mdmenubar add cascade -label $m -menu $mdmenubar.m$m -background $menucolor 
    }
    
    makeFileMenu $File
    makeEditMenu $Edit
    makeToolsMenu $Tools
    makeOptionsMenu $Options

#     set imageProcess [menu $menubase.m1 -tearoff 0]
#     $menubase add cascade -label "Image Processing" -menu $menubase.m1 -background "#ede9e3"

#     set imageutility [ bis_guitreeimageutility \#auto ]
#     $imageutility InitializeFromContainer $this
#     set w2 $menubase.$imageutility
    
#     set imageutility [ $imageutility GetThisPointer ]
#     $imageutility CreateGUI $w2 
#     $imageutility AddToMenuButton $imageProcess

#     set surfaceProcess [menu $menubase.m2 -tearoff 0]
#     $menubase add cascade -label "Surface Processing" -menu $menubase.m2 -background "#ede9e3"
    
#     set surfacecontrol [ bis_guisurfaceutility \#auto ] 
#     $surfacecontrol InitializeFromContainer $this
#     set w3 $menubase.$surfacecontrol
    
#     set surfacecontrol [ $surfacecontrol GetThisPointer ]
#     $surfacecontrol CreateGUI $w3 
#     $surfacecontrol AddToMenuButton $surfaceProcess

    #------------------------------------------------------------------------------------------
    #Middle Pane
    #------------------------------------------------------------------------------------------
    #Initialize the Middle Pane with buttons and display space
    #Create frame to hold both buttons next to each other horizontally (tbf = "two-button frame")
    set tbf [frame $midpane.twoButtonFrame -bg $menucolor]
    
    #Create indiv. frame for each button
    set leftBF [frame $tbf.leftButtonFrame]
    pack $leftBF -side left -fill x -expand 1

    
    #Create buttons to occupy their respective frames
    eval "button $leftBF.l1 -text \"Set Space and Anatomical Image\" -command { $this setSelectionSpace; $this setSelectionAnatomical }"
    eval "button $leftBF.l2 -text \"Set Anatomical Image\" -command { $this setSelectionAnatomical }"
    eval "button $leftBF.r3 -text \"Set Functional Image\" -command { $this setSelectionFunctional }"
    pack $leftBF.l1 $leftBF.l2 $leftBF.r3 -fill x -expand 1 -side left
    
    #pack the whole two-bar frame (tbf)
    pack $tbf -side top -fill x -padx {3 3} -pady {2 0}
    
    set rbfr [frame $midpane.reslframe -bg $menucolor]; pack $rbfr -side top -fill x -padx {3 3}
    eval "button $rbfr.big -text \"Reslice Images and Set Overlay Inputs\" -command { $this resliceSetOverlayInputs }"
    pack $rbfr.big -side left -fill x -expand 1
    
    #Interpolation mode menu
    menubutton $rbfr.modemenu -text Mode -menu $rbfr.modemenu.m\
	-underline 0 -background $menucolor -activebackground "$menuactivebgcolor" -relief raised
    pack $rbfr.modemenu -side right -padx {2 0} -pady {0 2}
    
    set modemenu [menu $rbfr.modemenu.m -tearoff 0 ]
    eval "$modemenu add radio -label Linear -variable {[itcl::scope reslmode]} -value Linear"
    eval "$modemenu add radio -label Cubic -variable {[itcl::scope reslmode]} -value Cubic"
    eval "$modemenu add radio -label \"Nearest Neighbor\" -variable {[itcl::scope reslmode]} -value NearestNeighbor"

    #------------------------------------------------------------------------------------------
    #Right Pane
    #------------------------------------------------------------------------------------------
    
    # (Empty)
    
    #------------------------------------------------------------------------------------------
    #Event Bindings
    #Set behavior for events in the tree						 
    #------------------------------------------------------------------------------------------
    set popup [menu $vistree.pop -tearoff 0]
    makeImageMenu $popup
    
    set surfacepopup [menu $vistree.surfpop -tearoff 0]
    makeSurfaceMenu $surfacepopup

    set folderpopup [menu $vistree.folderpop -tearoff 0]
    makeFolderMenu $folderpopup
    
    set electrodepopup [ menu $vistree.elecpop -tearoff 0]
    makeElectrodeMenu $electrodepopup

    set patientpopup [menu $vistree.patientpop -tearoff 0]
    makePatientMenu $patientpopup

    $patientpopup add separator
    eval "$patientpopup add command -label \"Add an Image as Child\" -command { $this addImageToTree }"
    for {set i 0} {$i <= [$patientpopup index end]} {incr i} {
	$patientpopup entryconfigure $i -background $menucolor 
    }


    set rootpopup [menu $vistree.rootpop -tearoff 0]
    makeDataMenu $rootpopup
    
    
    
    
    #Bind button clicks in the tree
    eval "$vistree bind x <1> { $this bindx1 %W %x %y }"
    eval "$vistree bind x <Button1-Motion> { $this bindxmotion1 %W %x %y }"
    eval "$vistree bind x <ButtonRelease-1> { $this bindxrelease1 %W %x %y 1 }"
    eval "$vistree bind x <Control-ButtonRelease-1> { $this bindxrelease1 %W %x %y 0 }"
    eval "$vistree bind x <Control-1> { $this bindxcontrol1 %W %x %y }"
    eval "$vistree bind x <Double-1>  { $this bindxdouble1 %W %x %y }"
    eval "$vistree bind x <3> { $this bindx3 %W %x %y }"	
    update
    
}

::itcl::body bis_treegui::updateTreeWidget { {node ""} } {

    set pathList [ $dustin getPathList ] 

    if { $node != "" } { 
	Tree::delitem $vistree $node
    }

    foreach pathName $pathList {
	if { ![Tree::itemexists $vistree $pathName] } { 
	    if {![ regexp {(/)(.+)(/)} $pathName ]} { 
		Tree::newitem $vistree /Data -image icactus 
	    } else {
		set color [ $this getLineColor $pathName ]
		set icon [ $this getIcon $pathName ]
		Tree::newitem $vistree $pathName -image $icon -linecolor $color
		Tree::open $vistree [ $dustin getNodeParent $pathName ]
	    }
	}
    }
}

::itcl::body bis_treegui::getIcon { path } {

    if { [ $dustin getNodeType $path ] == "Folder" } {
	return idir
    }
    
    if { [ $dustin getNodeFileName $path ] == "" } {
	return ibraingrey
    }

    if { [ $dustin getNodeType $path ] == "Image" } {
	 if { [ $dustin getNodeTransFromParent $path ] == 1 && [ $dustin getNodeTransToParent $path ] == 1 } {
	     return iarrowbrain
	 } else {
	     return ibrainpurple
	 }
    }

    return ibrainyellow
}

::itcl::body bis_treegui::getLineColor { path } {
    if { [ $dustin getNodeTransFromParent $path ] != "" && [ $dustin getNodeTransToParent $path ] != "" } {
	return green
    }
    if { [ $dustin getNodeTransFromParent $path ] == "" && [ $dustin getNodeTransToParent $path ] != "" } {
	return purple
    }
    if { [ $dustin getNodeTransFromParent $path ] != "" && [ $dustin getNodeTransToParent $path ] == "" } {
	return orange
    }
    if { [ $dustin getNodeTransFromParent $path ] == "" && [ $dustin getNodeTransToParent $path ] == "" } {
	return red
    }
}


##########################################################################################
#                             This ends the bis_treegui class                              #
##########################################################################################
#
#
#
#
#
# A couple static procs
#
proc Compute { image_ref image_trn { mode linear } } {
    
    set dim1 [ [ $image_ref GetImage ] GetDimensions ]
    set dim2 [ [ $image_trn GetImage ] GetDimensions ]
    if { [lindex $dim2 0 ] <2 || [ lindex $dim1 0 ] < 2 } { 
	::pxtclutil::Warning "No Images in Memory\n Cannot Compute Registration!"
	return  0
    }
    
    
    if { $mode == "linear" } {
	set swindow "Linear Reg"
    } else {
	set swindow "NonLinear Reg"
    }
    
    $viewer1  SetImageFromObject $image_ref $this
    $viewer2  SetImageFromObject $image_trn $this
    
    $overlaycontrol EnableRegistrationButtons
    $overlaycontrol ShowWindow $swindow
    $overlaycontrol SetAutoSave 0
}

proc GrabRegistration { image_ref image_trn } { 
    
    set n0 [ file dirname [ ${image_ref} cget -filename ] ]
    set n1 [ file tail [ ${image_trn} cget -filename ] ]
    set n2 [ file tail [ file rootname [ ${image_ref}  cget -filename ] ] ]
    set suffix "matr"
    
    if { [ $newtr IsA "vtkGridTransform" ] == 1 } {
	set suffix "grd"
    } elseif { [ $newtr IsA "vtkpxComboTransform" ] == 1 } {
	set suffix "grd"
    } elseif { [ $newtr IsA "vtkThinPlateSplineTransform" ] == 1 } {
	set suffix "tps"
    }
    
    set mname [ file join $n0 "${n1}_${n2}.${suffix}" ]
    set ok 1
    
    
    set newtr [ [pxitcltransform \#auto ] GetThisPointer  ]
    $newtr configure -filename $mname
    set tr [ $overlaycontrol GetTransformation ]
    $newtr  CopyTransformation 
    $newtr  Save ""
    return $newtr
}

# ------------------------------------------------------------------


if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    
    set thisGUI [bis_treegui \#auto]
    wm withdraw .
    
    $thisSPECT configure -IsSolo 1
    $thisSPECT Initialize .[pxvtable::vnewobj] 2
    $thisSPECT ShowTop
    
}
