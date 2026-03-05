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

package provide chellyGUI_2 1.0

#---------------------------------------------------------------------------------------------
#Import of required packages and other required initialization defs
#---------------------------------------------------------------------------------------------
# This package sets the required paths
lappend auto_path [file dirname [info script]]
package require pxitclchellypackages 1.0
package require pxitclfilelistmenu 1.0
#package require bis_guitreeimageutility
#------------------------------------------------------------------------------------------


# Chelly's Packages
package require VisTree2;        #This is the "Tcl only" Tree widget that handles the tree display
package require struct;          #This package includes the "struct::tree"
package require chellyDB;        #This is the package that handles saving and loading of patient tree files

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

::itcl::class chellyGUI {
    

    #Note: throughout this class, Image 2 is the Image to Be Resliced into the Space of
    #Image 1, which is sometimes referred to as Base Image
    
    
    #Class Data Members
    
    #----------------------------------------------------
    #---------Module Enable/Disable Options--------------
    public variable enable_atlas 0
    public variable enable_SPECT 1
    public variable enable_AdvancedReg 1
    public variable enable_elec_att 1
    #----------------------------------------------------


    public variable FileManager 0;         #This is the FileManager Object (an instance of a child of chellyDB)
    public variable RelativeFileManager 0; #These are the two options for it 
    public variable AbsoluteFileManager 0

    #Package Variables
    public variable AtlasModule 0;         #This is the Atlas Lookup program 
    public variable AtlasRefFilename -1;   #This is the filename of the reference image for the atlas
    public variable SPECTmodule 0;         #This is the SPECT processing program
    public variable SPECT_initialized 0;   #Has the SPECT tool been initialized?
    public variable REGmodule 0;         #This is the REG processing program
    public variable REG_initialized 0;   #Has the REG tool been initialized?


    public variable ElectAttrModule 0;     #This is the Electrode Attribute Selector Program
    #--------------------------------------------------

    public variable MasterCount;  #This is the counter to ensure all nodes in the tree have a unique ID

    public variable ClipboardTreeArray; #This is the temporary serialized tree, for cutting and pasting

    public variable mdTopWidget
    public variable osmode; # variable to hold which operating system we are on
    public variable menucolor; # color for the top menu
    public variable menuactivebgcolor; # active background for top menu
    public variable leftpane
    public variable midpane
    public variable rightpane
    public variable treeframe 
    public variable descriptionbox
    public variable hasatlastool 1
    #    public variable RecentFilesMenu
    #    public variable recentfileslist ""
    #    public variable recentfilesnames ""
    public variable toolsmenu 0


    public variable TreeChanged 0

    public variable SurgeryMode 0; # Disables some options
    public variable SpaceLocked 0; # Locks SpaceImage

    public variable brainiconchoice "ibrainpurple"
    public variable surfaceiconchoice "ibrainyellow"
    public variable resulticonchoice "ibrainred"
    public variable atlasiconchoice "ibrainrainbow"
    public variable roiiconchoice "ibrainorange"

    public variable reslmode 1

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
    variable patientpopup
    variable rootpopup
    variable rightpanelpopup
    
    variable NodeInfoDialogName -1
    variable nodeDialogBGColor -1
    public variable entrylist
    public variable nodeinfoitemlist

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
    
    variable SpaceControlWidget
    variable AnatomicalControlWidget
    variable FunctionalControlWidget
    variable TransformationControlWidget
    
    public variable viewer1 0
    public variable viewer2 0
    public variable electrodecontrol1 0
    public variable electrodecontrol2 0
    public variable overlaycontrol 0
    public variable myname 0
    
    public variable dragAndDropEnabled 0    
    public variable undoArray
    public variable theNoCursor
    
    # Switch Directory
    public method SwitchDirectory { { newdir ""  } }

    #---------------
    #private methods
    #---------------
    
    public method AddDefaults {realtreename}
    public method AddPatient {realtreename ParentNodeID {title -1}}
    public method AddFolder {realtreename ParentNodeID {title -1}}
    public method AddImage {realtreename ParentNodeID {title -1} {type -1}}
    public method AddSurface { realtreename ParentNodeID {title -1} {type -1}}
    public method AddLandmark { realtreename ParentNodeID {title -1} {type -1}}
    public method AddElectrode { realtreename ParentNodeID {title -1} {type -1}}
    public method AddSubtree {realtreename ParentNodeID {ListedTree -1}}
    public method AddMSBData {  realtreename ParentNodeID {title -1} {ListedTree -1} }
    public method AddCSIPatient { realtreename ParentNodeID {title -1} {ListedTree -1}} 
    public method AddAllCSI { realtreename  ParentNodeID }
    
    private method NodeInitialize {realtreename node}
    private method ImageInitialize {realtreename node}
    private method PatientInitialize {realtreename node}
    private method FolderInitialize {realtreename node}
    private method SurfaceInitialize {realtreename node}
    private method LandmarkInitialize {realtreename node}
    private method ElectrodeInitialize {realtreename node}
    
    public  method findTransforms { realtreename args }
    private method commonAncestor { realtreename node1 node2 }
    private method removeIDnodes { realtreename nodelist } 
    private method makeTransformList { realtreename node1 node2 }
    private method doTransformsExist { realtreename node }
    public  method setNodeFilename { node {filename -1}}
    private method setNodeTransformToParFile { node {filename -1}}
    private method setNodeTransformFromParFile { node {filename -1}}
    public  method toggleIdentity { node {explicitSetting -1}}
    
    private method checkForIllegalCharacters { inputName }
    private method getPath {realtreename ImageID}
    private method nodeName { node }
    private method getNodesOfTransformation { trans }    
    public  method EnsureFileLoaded { node }
    public  method EnsureTransListLoaded { listoftransforms } 
    
    #--------------
    #public methods
    #--------------
    public method GetThisPointer { } { return $this }
    public method GetRealTree { } { return $RealTree }
    public method GetVisTree { } { return $vistree }
    public method GetTransformsCache { } { return [array get TransformsCache] }
    
    public method Debug { }

    public method OnWidgetClose { }

    #This forces an update of the visualization tree with the contents of the real data tree
    public method updateVisTree { vistree RealTree {args}}
    public method AutoSetIcon { realtreename node }
    public method CloseNodes { args }
    public method updateBigTransLines { } 
    public method updateOverlayCanvas { }
    public method updateRightCanvasDisplay { }

    public method setSurgeryMode { }

    #These methods send pxitcl objcets to the various controls 
    public method setSpaceControlWidget { widget }
    public method setAnatomicalControlWidget { widget }
    public method setFunctionalControlWidget { widget } 
    public method setTransformationControlWidget { widget }
    
    #Here are some methods to send/receive surfaces to/from the viewers (surfaces, landmarks, electrodes)
    #------------------------------------------------------------------------------------------
    public method sendSelectionToDisplay { viewerno {ref -1} {node -1}} 
    public method displayImage      { viewerno imageobj { refobj -1 } {background 0} }
    public method displaySurface    { viewerno surfaceobj { refobj -1 }}
    public method displayLandmarks  { viewerno landobj { refobj -1 }}
    public method displayElectrodes { econtrol electrodeobj { refobj -1 }}
    
    
    #These grab the images from the viewers
    public method PutViewerObjectInTree { viewerno objtype }
    
    public method GrabViewerImage { viewerno destinationobj }
    public method GrabViewerSurface { viewer newsur }
    public method GrabViewerLandmarkSet { viewer newsur } 
    public method GrabViewerElectrodes { viewer newelec }

    public method grabElectrodeAttributes { electrodecontrolno }
    
    
    #methods to create the total concatenated transformation and export it
    public method CreateTransformation { listoftransforms }
    public method sureTransLoad { transobjname }
    
    # Reslmode 0=nn, 1=linear 3=cubic
    public method ResliceImage  { baseimage imagetoberesliced listoftransforms {fname auto } {background 0 } }
    public method Reslice { }
    
    
    #User I/O methods
    public method showButtonToolBar {mdTopWidget {args}}
    public method showGrabButtonDialog { }
    public method Single_Entry_Dialog {title msgstring {defstring -1}}
    public method ImageEntryDialog {}
    
    public method GetIDFromSelection { args }
    public method IsNodeImage { node {treename -1} {broad 0}}
    public method IsNodeSurface { node {treename -1} }

    #button click methods and related helper methods
    public method bindxrelease1 { W x y mode }
    public method bindxmotion1 { W x y } 
    public method bindx1 { W x y }
    public method displayFilename {}
    public method isCurrentAChildOfSelection { currentPath selectionPath W }
    public method isCurrentTheParentOfSelection { currentPath selectionPath W }
    public method selectTreeFromBind { W x y } 
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
    public method makeElectrodeMenu { menu0 }
    public method makePatientMenu { menu0 }
    public method makeDataMenu { menu0 }
    public method makeAtlasMenu { menu0 }
    public method makeOptionsMenu { menu0 }
    public method makeViewMenu { menu0 }
    public method makeColorMenu { colormenu icon }
    public method menuActivation { menu menutype }
    
    public method addImageToTree { }
    public method addPatientToTree { }
    public method addFolderToTree { }
    public method addSurfaceToTree { }
    public method addLandmarkToTree { }
    public method addElectrodeToTree { }
    public method addSubtreeAtSelection { {type 1} }
    
    public method mdLoadElectrodeAttributes { }

    public method renameSelected { }
    public method delSelectedFromTree { }
    
    public method setSelectionSpace { realtreename }
    public method setSelectionAnatomical { realtreename }
    public method setSelectionFunctional { realtreename }
    
    public method setSelectedFileName { }
    
    public method setTransToParent { }
    public method setTransFromParent { }

    public method clearTransToParent { }
    public method clearTransFromParent { }
    
    public method setIdentityToggle { }
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
    public method mdCopy { {cut 0} { parentNode -1 } }
    public method mdPaste { { parentNode -1 } }
    public method undo
    #----------------------------------------

    #-----------------------------
    # Added Methods to handle Save/Load with chellyDB
    #------------------------------
    public method mdSaveTree { datatree { updatefiles 0 } }
    public method mdNewTree { };# (Does not call chellyDB)

    public method mdLoadTreeFile { filename } { return [ $this mdLoadTree -1 $filename ] }
    public method mdGetTreeFileName { } {
	array set AddedTreeDefArray $ListedTree
	return $TreeDefArray(ThisFileName)
    }

    public method mdLoadTree { {ListedTree -1} {filename -1} }
    public method mdSaveTypeDefs { }
    public method mdLoadTypeDefs { }
   

    #constructor
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

	set masterpath [file normalize [ file join [ file join [ file dirname [ info script ] ] [ file join ..  images  ]]]]
	set AbsoluteFileManager [chellyDBBasic \#auto]
	set RelativeFileManager [chellyDBRelative \#auto]

	set FileManager $RelativeFileManager
	$FileManager configure -masterpath $masterpath
	$FileManager configure -masterlist [ list "MNI_T1_1mm.nii.gz" "MNI_T1_1mm_stripped.nii.gz" "MNI_T1_colin_1mm_fixed.matr" "ISAS_Mean_Diff_SPECT.nii.gz" "ISAS_SPECT_Mask.nii.gz" "ISAS_SPECT_Template.nii.gz" "ISAS_Standard_Deviation.nii.gz" "ISASHN_Standard_Deviation.nii.gz" "MNI_T1_2mm_stripped.nii.gz" "MNI_T1_2mm.nii.gz" ]

	puts stderr "[ $FileManager cget -masterpath ] [ $FileManager cget -masterlist ]"
	set MasterCount 1

	set myname [ pxvtable::vnewobj ]

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
	unset MasterCount
    }
    
    
};#End chellyGUI class


#------------------------------------------------------------------------------------------
#Method defs for class chellyGUI
#------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------
itcl::body chellyGUI::SwitchDirectory { { dirname "" } } {

    if { [ string length $dirname ] == 0 } {
	set dirname  [tk_chooseDirectory -title "Select Current Directory" ]
    }

    if { [ string length $dirname ] < 1 } {
	return 0
    }

    cd $dirname
    set dirname [ pwd ]
    pxtkprint "Switched directory to $dirname"
}


::itcl::body chellyGUI::OnWidgetClose { } { 
    
    if { $TreeChanged == 0 } {
	pxtkexit
    }

    set ans [ tk_messageBox -type yesnocancel -default yes \
		  -message "The tree has changed since it was last saved.  Would you like to save it before exiting?" -icon question ]

    if { $ans == "cancel"} {
	return
    }
    
    if { $ans == "yes"} {
	if { [ mdSaveTree $RealTree ] < 0 } {
	    return 
	}
    }
    
    pxtkexit

}

#Creates a Toolbar right below main menu to contain a row of buttons
::itcl::body chellyGUI::showButtonToolBar {mdTopWidget {args}} {
    frame $mdTopWidget.buttonTools -borderwidth 1
    pack $mdTopWidget.buttonTools -side top -fill x
    foreach thisButton $args {
	button $mdTopWidget.buttonTools.$thisButton -font fixed -text $thisButton
	pack $mdTopWidget.buttonTools.$thisButton -side left
    }
}


::itcl::body chellyGUI::Single_Entry_Dialog {title msgstring {defstring -1}} {

    #defstring is the default entry in the dialog

    global Single_Entry_Dialog_Result -1

    iwidgets::promptdialog .sed -modality application -title $title -modality application \
	-labeltext $msgstring -labelpos s
    .sed hide Apply

    .sed buttonconfigure OK -command { set Single_Entry_Dialog_Result [.sed get]; .sed deactivate }
    .sed buttonconfigure Cancel -command { set Single_Entry_Dialog_Result -1; .sed deactivate }

    if {$defstring != -1} {
	.sed insert 0 $defstring
	.sed selection range 0 end
    }

    focus [.sed component prompt component entry]
    .sed center
    update idletasks
    .sed activate

    destroy .sed
    
    return $Single_Entry_Dialog_Result

}

::itcl::body chellyGUI::ImageEntryDialog {} {
    
    global ImageDialogEntryResult -1
    
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
    .selbox buttonconfigure Cancel -command {set ImageDialogEntryResult -1; .selbox deactivate }
    
    update idletasks
    .selbox activate
    
    destroy .selbox
    
    return $ImageDialogEntryResult
    
}



#------------------------------------------------------------------------------------------
# Private methods of chellyGUI
#------------------------------------------------------------------------------------------
#InitInit

::itcl::body chellyGUI::NodeInitialize {realtreename node} {
    
    $realtreename set $node title $node
    $realtreename set $node group data
    $realtreename set $node notes ""
    
    $realtreename set $node FileName -1
    $realtreename set $node FileLoaded 0
    
    #this is the transformation object FROM this object TO the parent
    $realtreename set $node TransToParFileName -1
    $realtreename set $node pxitclTransToParent [[pxitcltransform "$myname,$node:[$RealTree parent $node]"] GetThisPointer]
    
    
    #this is the transformation object TO this object FROM the parent
    $realtreename set $node TransFromParFileName -1
    $realtreename set $node pxitclTransFromParent [[pxitcltransform "$myname,[$RealTree parent $node]:$node"] GetThisPointer]

    #Also, we set a key in the visualization array for the new node's expanded status (1, though it has no children yet)
    set ::Tree::Tree($vistree:[getPath $realtreename $node]:open) 1
    $realtreename set $node expanded 1

    #We will force the node's parent to automatically expand in the visualization tree
    set ::Tree::Tree($vistree:[getPath $realtreename [$realtreename parent $node]]:open) 1
    $realtreename set [$realtreename parent $node] expanded 1

    #--------------------------------------------------
    #This sets the key in the reverse array for a lookup
    set pathList [$realtreename rootname]
    set pathListIDs [$realtreename ancestors $node]
    
    for {set y [expr [llength $pathListIDs] - 1]} {$y > -1} {incr y -1} {
	if {[lindex $pathListIDs $y] != [$realtreename rootname]} {
	    lappend pathList [$realtreename get [lindex $pathListIDs $y] title]
	    
	}
    }
    
    set pathName /
    for {set i 0} {$i < [llength $pathList]} {incr i} {
	append pathName [lindex $pathList $i]
	append pathName /
    }
    append pathName [$realtreename get $node title]
    set NodeIDs($pathName) $node
    #--------------------------------------------------
    
    
}


::itcl::body chellyGUI::SurfaceInitialize {realtreename node} {
    
    NodeInitialize $realtreename $node
    
    $realtreename set $node type [list Surface Surface]
    $realtreename set $node pxitclobj [ [pxitclsurface \#auto] GetThisPointer ]
    
    #A couple display properties for the node
    $realtreename set $node icon $surfaceiconchoice
    $realtreename set $node linecolor green
    
    #This node property toggles the "identity" propery for the image - ie, no transformation 
    $realtreename set $node FromParFilenameSet 0
    $realtreename set $node ToParFilenameSet 0
    $realtreename set $node IsIdentity 0;# Initialize it to zero
    
    #Toggle the identity to 1 (with an explicit setting)
    toggleIdentity $node 1
    
}

::itcl::body chellyGUI::LandmarkInitialize {realtreename node} {
    
    NodeInitialize $realtreename $node
    
    $realtreename set $node type [list Surface Landmark]
    $realtreename set $node pxitclobj [ [pxitcllandmarks \#auto] GetThisPointer ]
    
    #A couple display properties for the node
    $realtreename set $node icon $surfaceiconchoice
    $realtreename set $node linecolor green
    
    #This node property toggles the "identity" propery for the image - ie, no transformation 
    $realtreename set $node FromParFilenameSet 0
    $realtreename set $node ToParFilenameSet 0
    $realtreename set $node IsIdentity 0;# Initialize it to zero
    
    #Toggle the identity to 1 (with an explicit setting)
    toggleIdentity $node 1
    
}

::itcl::body chellyGUI::ElectrodeInitialize {realtreename node} {
    
    NodeInitialize $realtreename $node
    
    $realtreename set $node type [list Surface Electrode]
    $realtreename set $node pxitclobj [ [pxitclelectrodemultigrid \#auto] GetThisPointer ]
    
    #A couple display properties for the node
    $realtreename set $node icon $surfaceiconchoice
    $realtreename set $node linecolor green
    
    #An "Attribute" List, which may be optionally set
    $realtreename set $node Attributes -1

    #This node property toggles the "identity" propery for the image - ie, no transformation 
    $realtreename set $node FromParFilenameSet 0
    $realtreename set $node ToParFilenameSet 0
    $realtreename set $node IsIdentity 0;# Initialize it to zero
    
    #Toggle the identity to 1 (with an explicit setting)
    toggleIdentity $node 1
    
}




::itcl::body chellyGUI::PatientInitialize {realtreename node} {
  
    NodeInitialize $realtreename $node

    $realtreename set $node type Patient
    $realtreename set $node pxitclobj [ [pxitclimage \#auto] GetThisPointer ]
    
    #A couple display properties for the node
    $realtreename set $node icon idir
    $realtreename set $node linecolor green

    #This node property toggles the "identity" propery for the image - ie, no transformation 
    $realtreename set $node FromParFilenameSet 1
    $realtreename set $node ToParFilenameSet 1
    $realtreename set $node IsIdentity 1

    set propArray(init) 1
    $realtreename set $node Properties [array get propArray]

    toggleIdentity $node 1

}

::itcl::body chellyGUI::FolderInitialize {realtreename node} {
   
    NodeInitialize $realtreename $node

    $realtreename set $node type Folder
    $realtreename set $node pxitclobj [ [pxitclimage \#auto] GetThisPointer ]

    #A couple display properties for the node
    $realtreename set $node icon idir
    $realtreename set $node linecolor green

    #This node property toggles the "identity" propery for the image - ie, no transformation 
    $realtreename set $node FromParFilenameSet 1
    $realtreename set $node ToParFilenameSet 1
    $realtreename set $node IsIdentity 1

    toggleIdentity $node 1

}


#This method sets all the initial values for the node keys (ie, properties of each image object)
::itcl::body chellyGUI::ImageInitialize {realtreename node} {
 
    NodeInitialize $realtreename $node

    $realtreename set $node type -1
    $realtreename set $node pxitclobj [ [pxitclimage \#auto] GetThisPointer ]

    #A couple display properties for the node
    $realtreename set $node icon ibraingrey
    $realtreename set $node linecolor red

    #This node property toggles the "identity" propery for the image - ie, no transformation 
    $realtreename set $node FromParFilenameSet 0
    $realtreename set $node ToParFilenameSet 0
    $realtreename set $node IsIdentity 0
    
   
}


::itcl::body chellyGUI::IsNodeImage { node {treename -1} {broad 0}} {
    
    if {$treename == -1} {
	set treename $RealTree
    }
    
    if {$node == [$treename rootname]} {return 0}
    
    if {$broad == 0} {
	#Does not Include Atlas and ROI Def Images as "Image"
	switch -exact -- [lindex [$treename get $node type] 0] {
	    
	    "Surface" -
	    "Landmark" -
	    "Electrode" -
	    "Folder" -
	    "Patient" -
	    "Atlas" -
	    "ROIDef" {
		return 0
	    }
	}	
	return 1
    } else {
	# Includes Atlas and ROI Def Images as "Image"
	switch -exact -- [lindex [$treename get $node type] 0] {
	    
	    "Surface" -
	    "Landmark" -
	    "Electrode" -
	    "Folder" -
	    "Patient" {
		return 0
	    }
	}	
	return 1
	
    }
    
}

::itcl::body chellyGUI::IsNodeSurface { node {treename -1} } {
    
    if {$treename == -1} {
	set treename $RealTree
    }
    
    if {$node == [$treename rootname]} {return 0}
    if {[lindex [$treename get $node type] 0]== "Surface"} {
	return 1
    }
    
    return 0
    
}

::itcl::body chellyGUI::AddDefaults {realtreename} {
    
    global datatreebioimagesuitepath
    set masterpath [file normalize [ file join $datatreebioimagesuitepath images ] ]
    
    if {$enable_atlas == 1} {
	#Reference Image for Atlas comparison
	set thisID [lindex [AddAtlasNode $realtreename $NodeIDs(/Data) "Brain_Atlas"] 2]
	set AtlasRefFilename [file join $masterpath MNI_T1_1mm.nii.gz]
	setNodeFilename $thisID $AtlasRefFilename
	
	set thatID [lindex [AddImage $realtreename $thisID "Colin 1mm"] 2]
	set Node2Filename [file join $masterpath  MNI_T1_1mm_stripped.nii.gz]
	setNodeFilename $thatID $Node2Filename
	$realtreename set $thatID type 10
	
	setNodeTransformFromParFile $thatID [file join $masterpath MNI_T1_colin_1mm_fixed.matr ]
    } else {
	#Only add regular base image
	set thatID [lindex [AddImage $realtreename $NodeIDs(/Data) "MNI T1 1mm"] 2]
	set Node2Filename [file join $masterpath MNI_T1_1mm.nii.gz]
	setNodeFilename $thatID $Node2Filename
	$realtreename set $thatID type 10
    }    

    #Select the root node in the tree
    ::Tree::setselection $vistree /[$RealTree rootname]
}

::itcl::body chellyGUI::getPath { realtreename NodeID } {
    
    #returns the pathname back to the root, given the node ID
    set node $NodeID
    set pathList [$realtreename rootname]
    
    set pathListIDs [$realtreename ancestors $node]
    
    for {set y [expr [llength $pathListIDs] - 1]} {$y > -1} {incr y -1} {
	if {[lindex $pathListIDs $y] != [$realtreename rootname]} {
	    lappend pathList [$realtreename get [lindex $pathListIDs $y] title]
	}
    }
    
    set pathName /
    
    for {set i 0} {$i < [llength $pathList]} {incr i} {
	append pathName [lindex $pathList $i]
	append pathName /
    }
    
    if {![string match [$realtreename rootname] $node]} {
	append pathName [$realtreename get $node title]
    } 

    #else { set pathName [string trimright $pathName /] }
    
    
    return $pathName
}




#Updates the visualization tree with the contents of the real tree
::itcl::body chellyGUI::updateVisTree {vistree realtreename {args} } {
    
    if {[llength $args] > 0} {
	for {set i 0} {$i < [llength $args]} {incr i} {
	    lappend roots [lindex $args $i]
  	}
    } else {set roots [$realtreename rootname] }
    
    
    foreach updateroot $roots {
	
	#--------------------------------------------------------------------------------
	# get a path to the node in the tree that needs to be updated
	set updaterootpathname [string trimright [getPath $realtreename $updateroot] /]
	
	#--------------------------------------------------------------------------------
	
	foreach node [$realtreename children -all $updateroot] {
	    if { [lsearch [array names ::Tree::Tree] $vistree:[getPath $realtreename $node]:open ] != -1 } {
		$realtreename set $node expanded $::Tree::Tree($vistree:[getPath $realtreename $node]:open)
	    } else {$realtreename set $node expanded 1}
	}
	
 	#Delete the node in the vis tree (which deletes all children)
 	::Tree::delitem $vistree $updaterootpathname
	
	#Now put the new image in
	AutoSetIcon $realtreename $updateroot

	#If the node is the root node, then just put the right icon in...otherwise, figure out transformations, and
	#put the right color line in also
	if {$updateroot != [$realtreename rootname]} {
	    doTransformsExist $realtreename $updateroot
	    Tree::newitem $vistree $updaterootpathname -image [$realtreename get $updateroot icon]\
		-linecolor [$realtreename get $updateroot linecolor]
	} else { 
	    Tree::newitem $vistree $updaterootpathname -image [$realtreename get $updateroot icon] 
	}

	lappend items $updaterootpathname
	
	#--------------------------------------------------------------------------------
	# Now deal with the children in the same way
	#--------------------------------------------------------------------------------
	if {[llength [$realtreename children $updateroot]] > 0} {
	    foreach node [$realtreename children -all $updateroot] {
		
		set pathName [getPath $realtreename $node]
		
		AutoSetIcon $realtreename $node
		
		#This will update the linecolor of the node based on wheter the transformations exist
		doTransformsExist $realtreename $node
		
		Tree::newitem $vistree $pathName -image [$realtreename get $node icon]\
		    -linecolor [$realtreename get $node linecolor]
		lappend items $pathName
	    }
	    
	} 
	#--------------------------------------------------------------------------------
	
	#open all nodes in the tree
	Tree::open $vistree $updaterootpathname
	foreach item $items {
	    Tree::open $vistree $item
	}
	
	#Reclose any nodes that were closed before updating the tree
	foreach node [$realtreename children -all $updateroot] {
	    if {[$realtreename get $node expanded] != 1} {
		set thisnodepath [getPath $realtreename $node]
		Tree::close $vistree $thisnodepath
	    } 
	}


    }
	
};#End updateVisTree method

::itcl::body chellyGUI::AutoSetIcon { realtreename node } {

    if {$node == [$realtreename rootname]} {	
	$realtreename set $node icon icactus
	return 0
    }
    
    #---Check if it's of type "Image"-----------------------------------------------
    if {[IsNodeImage $node]} {
	if {[$realtreename get $node FileName] != -1} {
	    if {[$realtreename get $node IsIdentity]} {
		$realtreename set $node icon iarrowbrain
	    } else { $realtreename set $node icon $brainiconchoice }
	} else { $realtreename set $node icon ibraingrey }
    }  else { $realtreename set $node icon ibraingrey }
    
    
    #---Check if it's of type "Surface"-----------------------------------------------
    if {[IsNodeSurface $node]} {
	if {[$realtreename get $node FileName] != -1} {
	    $realtreename set $node icon $surfaceiconchoice
	} else {$realtreename set $node icon ibraingrey }
    }
    
    #---Check if it's of type "Result"-----------------------------------------------	    
    if {[$realtreename get $node type] == "Result"} {
	$realtreename set $node icon $resulticonchoice
    }
    
    #---Check if it's of type "Patient"-----------------------------------------------	    
    if {[$realtreename get $node type] == "Patient"} {
	$realtreename set $node icon ipersonicon
    }
    
    #---Check if it's of type "Folder"-----------------------------------------------	    
    if {[$realtreename get $node type] == "Folder"} {
	
	$realtreename set $node icon idir
    }
    
    #---Check if it's of type "Atlas"-----------------------------------------------	    
    if {[$realtreename get $node type] == "Atlas"} {
	if {[$realtreename get $node FileName] != -1} {
	    $realtreename set $node icon $atlasiconchoice 
	} else {$realtreename set $node icon ibraingrey }
    }
    
    #---Check if it's of type "ROIDef"-----------------------------------------------	    
    if {[$realtreename get $node type] == "ROIDef"} {
	if {[$realtreename get $node FileName] != -1} {
	    $realtreename set $node icon $roiiconchoice 
	} else {$realtreename set $node icon ibraingrey }
    }
    
    
    
}


::itcl::body chellyGUI::CloseNodes { args } {

    #If any nodes have been explicitly set to collapse, then do so
    if {[llength $args] > 0} {
	for {set i 0} {$i < [llength $args]} {incr i} {
	    set closelist [lindex $args $i]
	    foreach thisnode $closelist {
		set thisnodepath [getPath $RealTree $thisnode]
		Tree::close $vistree $thisnodepath
	    }
	}
    }
}

::itcl::body chellyGUI::doTransformsExist { realtreename node } {
    
    if {[$realtreename get $node ToParFilenameSet] && [$realtreename get $node FromParFilenameSet]} { set x 2 } else {
	if {[$realtreename get $node ToParFilenameSet]} { set x 1 } else {
	    if {[$realtreename get $node FromParFilenameSet]} { set x -1 } else { set x 0 }    
	}};#End of elses
    
    
    switch -exact -- $x\
	-1 {$RealTree set $node linecolor goldenrod2}\
	0 {$RealTree set $node linecolor red}\
	1 {$RealTree set $node linecolor purple}\
	2 {$RealTree set $node linecolor green}
    
    
    
};#end of doTransformsExist method

::itcl::body chellyGUI::updateBigTransLines { } {

    if {$SpaceLocked == 1} {
	if {$SpaceImage != -1} {
	    set SpaceLockNoticeText [$IC create text [expr $rbX+65] [expr $rbY - 15] -text "(Space Locked)" \
				  -fill red -font {times 16 bold italic} -tag SpaceLockNotice]
	} else { catch {$IC delete SpaceLockNotice} }
    } else { 
	catch {$IC delete SpaceLockNotice}
    }

    catch {$IC delete Anat2Space Func2Space }
    
    #-----Anat --> Space -----------------------------------------------------------------
    if {$SpaceImage != -1 && $AnatomicalImage != -1} {
	
	set GO 1
	findTransforms $RealTree $SpaceImage $AnatomicalImage
	foreach trans $TransformsCache($myname,$SpaceImage:$AnatomicalImage) {

	    if { ![info exists TransformsCache($trans,fileset)] } {
		set GO 0
	    } else {
		if {$TransformsCache($trans,fileset) != 1 } {
		    set GO 0
		}
	    }
	}
	
	if {$GO == 1} {
	    $IC create line [expr $rbX - 13] [expr $rbY + 50] \
		[expr $rbX - 55] [expr $rbY + 55] \
		[expr $abX + 35 ] [expr $abY - 85] \
		[expr $abX + 50 ] [expr $abY - 8] \
		-tag Anat2Space -smooth true  -splinesteps 20 -width 12 \
		-arrow first -arrowshape {15 18 8} -fill green
	} else {
	    $IC create line [expr $rbX - 13] [expr $rbY + 50] \
		[expr $rbX - 55] [expr $rbY + 55] \
		[expr $abX + 35 ] [expr $abY - 85] \
		[expr $abX + 50 ] [expr $abY - 8] \
		-tag Anat2Space -smooth true  -splinesteps 20 -width 12 \
		-arrow first -arrowshape {15 18 8} -fill red
	}
	
    }
    
    
    
    #-----Func --> Space -----------------------------------------------------------------
    
    if {$SpaceImage != -1 && $FunctionalImage != -1} {
	
	set GO 1
	
	findTransforms $RealTree $SpaceImage $FunctionalImage
	foreach trans $TransformsCache($myname,$SpaceImage:$FunctionalImage) {

#	    puts "-------$trans-------------------------------"
#	    puts "Does fileset exist? [info exists TransformsCache($trans,fileset)]"
	    if { [info exists TransformsCache($trans,fileset)] } {
#		puts "What is it? $TransformsCache($trans,fileset)"
	    }

	    if { [info exists TransformsCache($trans,fileset)] != 1 } {
		set GO 0
	    } else {
		if {$TransformsCache($trans,fileset) != 1 } {
		    set GO 0
		}
	    }
	}
	
	
	
	if {$GO == 1} {
	    
	    $IC create line [expr $rbX + 150] [expr $rbY + 50] \
		[expr $rbX + 190] [expr $rbY + 55] \
		[expr $fbX + 95 ] [expr $fbY - 85] \
		[expr $fbX + 80 ] [expr $fbY - 8] \
		-tag Func2Space -smooth true  -splinesteps 20 -width 12 \
		-arrow first -arrowshape {15 18 8} -fill green
	    
	} else {
	    
	    $IC create line [expr $rbX + 150] [expr $rbY + 50] \
		[expr $rbX + 190] [expr $rbY + 55] \
		[expr $fbX + 95 ] [expr $fbY - 85] \
		[expr $fbX + 80 ] [expr $fbY - 8] \
		-tag Func2Space -smooth true  -splinesteps 20 -width 12 \
		-arrow first -arrowshape {15 18 8} -fill red
	}   
	
	
    } ;# End "if both images are set"
    
}; #End method

::itcl::body chellyGUI::updateRightCanvasDisplay { } {

    if {[$RealTree exists $SpaceImage] != 1} {set SpaceImage -1}
    if {[$RealTree exists $AnatomicalImage] != 1} {set AnatomicalImage -1}
    if {[$RealTree exists $FunctionalImage] != 1} {set FunctionalImage -1}

    #Clear all
    catch {$IC delete refPIC}
    catch {$IC delete anatomPIC}
    catch {$IC delete funcPIC}
    $IC delete refTEXT
    $IC delete anatomTEXT
    $IC delete funcTEXT
    
    #--Space Image------------------------------------------------------------------------------
    if {$SpaceImage != -1} {
	if {[$RealTree get $SpaceImage FileName] != -1} {
	    set refcolorbrainPIC [$IC create image $rbX $rbY -image multicolorbrain -anchor nw -tag refPIC]
	    set refbrainTEXT  [$IC create text [expr $rbX+65] [expr $rbY+52] -text "[$RealTree get $SpaceImage title]" \
				   -fill white -activefill yellow -font {helvetica 15 bold} -tag refTEXT -width 150]
	} else {
	    set refbrainTEXT  [$IC create text [expr $rbX+65] [expr $rbY+52] -text "[$RealTree get $SpaceImage title]" \
				   -fill grey61  -activefill yellow -font {helvetica 15 bold} -tag refTEXT]
	}
    } else {
	set refbrainTEXT  [$IC create text [expr $rbX+65] [expr $rbY+52] -text "Not Set" \
			       -fill grey61 -activefill yellow  -font {helvetica 15 bold} -tag refTEXT]
    }
    #------------------------------------------------------------------------------------------------

   
    #--Anatomical Image------------------------------------------------------------------------------
    if {$AnatomicalImage != - 1} {
	if {[$RealTree get $AnatomicalImage FileName] != -1} {
	    
	    set anatomicalcolorbrainPIC [$IC create image $abX $abY -image multicolorbrain -anchor nw -tag anatomPIC]
	    set anatomicalbrainTEXT  [$IC create text [expr $abX+65] [expr $abY+52] -text "[$RealTree get $AnatomicalImage title]" -fill white -activefill yellow -font {helvetica 15 bold} -tag anatomTEXT -width 150]
	} else { 
	    set anatomicalbrainTEXT  [$IC create text [expr $abX+65] [expr $abY+52] -text "[$RealTree get $AnatomicalImage title]" -fill grey61  -activefill yellow -font {helvetica 15 bold} -tag anatomTEXT]
	}
    } else {
	set anatomicalbrainTEXT  [$IC create text [expr $abX+65] [expr $abY+52] -text "Not Set" \
				      -fill grey61 -font {helvetica 15 bold}  -activefill yellow -tag anatomTEXT]
    }
    #-------------------------------------------------------------------------------------------------


    #--Functional Image------------------------------------------------------------------------------
    if {$FunctionalImage != -1} {
	if {[$RealTree get $FunctionalImage FileName] != -1} {
	    set funccolorbrainPIC [$IC create image $fbX $fbY -image multicolorbrain -anchor nw -tag funcPIC]
	    set funcbrainTEXT  [$IC create text [expr $fbX+65] [expr $fbY+52] -text "[$RealTree get $FunctionalImage title]" -fill white -activefill yellow -font {helvetica 15 bold} -tag funcTEXT -width 150]
	    
	} else { 
	    set funcbrainTEXT  [$IC create text [expr $fbX+65] [expr $fbY+52] -text "[$RealTree get $FunctionalImage title]" -fill grey61  -activefill yellow -font {helvetica 15 bold} -tag funcTEXT]
	}
    } else { 
	set funcbrainTEXT  [$IC create text [expr $fbX+65] [expr $fbY+52] -text "Not Set" \
				-fill grey61 -activefill yellow -font {helvetica 15 bold} -tag funcTEXT]
    }
    #-------------------------------------------------------------------------------------------------


    updateBigTransLines

}

::itcl::body chellyGUI::setSurgeryMode { } {

    if {$SpaceImage != -1} {
	set SpaceLocked 1
    }
    
    set SurgeryMode 1

}


::itcl::body chellyGUI::AddSurface {realtreename ParentNodeID {title -1} {type -1}} {
    if {[llength $ParentNodeID] > 0} { 
	if {$title == -1} {
	    set SurfaceTitle [Single_Entry_Dialog "New Surface" "Enter a name for the new surface"]
	} else { set SurfaceTitle $title }
	
	set origTitle $SurfaceTitle
	
	if {[string equal $SurfaceTitle -1] | $SurfaceTitle == "" | [string equal -nocase $SurfaceTitle "Cancel"]} {
	    return 
	} else {


	    #----Input Validation----------------------------------------------------------------------
	    for {set a 0} {$a < [string length $SurfaceTitle]} {incr a} {
		set achar [string range $SurfaceTitle $a $a]
		
		if {![string is wordchar $achar] && ![string is space $achar] \
			&& ![string match {[.]} $achar] && ![string match {[-]} $achar] && ![string match {[^]} $achar] } {
		    	    error "Cannot add surface using character $achar  -- Node names can only can contain the following characters: \n     a-z, A-Z, 0-9, _, -, ., ^, and spaces"
		    
		}
	    }
	    #------------------------------------------------------------------------------------------

	    if {$type == -1} {
		set ThisSurfaceType [list Surface Surface]
	    } else {
		set ThisSurfaceType $type
	    }
	    
	    set ProposedPath [file join [getPath $realtreename $ParentNodeID] $SurfaceTitle]
	    set UniqueSuffix 1
	    set suffixed 0
	    
	    while {[Tree::itemexists $vistree $ProposedPath]} {
		
		if { $suffixed == 1 } {
		    #delete the suffix
		    set SurfaceTitle [string replace $SurfaceTitle [string last _ $SurfaceTitle] end]
		}
		
		append SurfaceTitle _ $UniqueSuffix
		set ProposedPath [file join [getPath $realtreename $ParentNodeID] $SurfaceTitle]
		set suffixed 1
		incr UniqueSuffix
	    }
	    
	    
	    if {![Tree::itemexists $vistree $ProposedPath]} {
		
		#Create a unique identifier for the Surface
		set SurfaceID $MasterCount
		incr MasterCount
		
		$realtreename insert $ParentNodeID end $SurfaceID
		SurfaceInitialize $realtreename $SurfaceID
		nameNode $realtreename $SurfaceID $SurfaceTitle
		
		$realtreename set $SurfaceID type $ThisSurfaceType
		
	    } else { 
		error "Please select a unique surface name"
	    }
	}

	set TreeChanged 1

	return [list $suffixed $origTitle $SurfaceID]
    } else {tk_messageBox -type ok -title "Need Selection" -message "Please select a parent in the tree" -icon info}
};#end of AddSurface method

::itcl::body chellyGUI::AddLandmark {realtreename ParentNodeID {title -1} {type -1}} {
    if {[llength $ParentNodeID] > 0} {
	if {$title == -1} {
	    set LandmarkTitle [Single_Entry_Dialog "New Landmark" "Enter a name for the new landmark surface"]
	} else { set LandmarkTitle $title }
	
	set origTitle $LandmarkTitle
	
	if {[string match $LandmarkTitle -1] | $LandmarkTitle == "" | [string equal -nocase $LandmarkTitle "Cancel"]} { 
	    return
	} else {
	    

	    #----Input Validation----------------------------------------------------------------------
	    for {set a 0} {$a < [string length $LandmarkTitle]} {incr a} {
		set achar [string range $LandmarkTitle $a $a]
		
		if {![string is wordchar $achar] && ![string is space $achar] \
			&& ![string match {[.]} $achar] && ![string match {[-]} $achar] && ![string match {[^]} $achar]} {
		    error "Cannot add landmark using character $achar  -- Node names can only can contain the following characters: \n     a-z, A-Z, 0-9, _, -, ., ^, and spaces"

		    
		}
	    }
	    #------------------------------------------------------------------------------------------


	    
	    if {$type == -1} {
		set ThisLandmarkType [list Surface Landmark]   
	    } else {
		set ThisLandmarkType $type
	    }
	    
	    set ProposedPath [file join [getPath $realtreename $ParentNodeID] $LandmarkTitle]
	    set UniqueSuffix 1
	    set suffixed 0
	    
	    while {[Tree::itemexists $vistree $ProposedPath]} {
		
		if { $suffixed == 1 } {
		    #delete the suffix
		    set LandmarkTitle [string replace $LandmarkTitle [string last _ $LandmarkTitle] end]
		}
		
		append LandmarkTitle _ $UniqueSuffix
		set ProposedPath [file join [getPath $realtreename $ParentNodeID] $LandmarkTitle]
		set suffixed 1
		incr UniqueSuffix
	    }
	    
	    
	    if {![Tree::itemexists $vistree $ProposedPath]} {
		
		#Create a unique identifier for the Landmark
		set LandmarkID $MasterCount
		incr MasterCount
		
		$realtreename insert $ParentNodeID end $LandmarkID
		LandmarkInitialize $realtreename $LandmarkID
		nameNode $realtreename $LandmarkID $LandmarkTitle
		
		$realtreename set $LandmarkID type $ThisLandmarkType
		
		
	    } else { 
		error "Please select a unique landmark name"
	    }
	}
	set TreeChanged 1
	return [list $suffixed $origTitle $LandmarkID]
    } else {tk_messageBox -type ok -title "Need Selection" -message "Please select a parent in the tree" -icon info}         
};#end of AddLandmark method

::itcl::body chellyGUI::AddElectrode {realtreename ParentNodeID {title -1} {type -1}} {
    if {[llength $ParentNodeID] > 0} {
	if {$title == -1} {
	    set ElectrodeTitle [Single_Entry_Dialog "New Electrode" "Enter a name for the new electrode map"]
	} else { set ElectrodeTitle $title }
	
	set origTitle $ElectrodeTitle
	
	if {[string match $ElectrodeTitle -1] | $ElectrodeTitle == "" | [string equal -nocase $ElectrodeTitle "Cancel"]} { 
	    return
	} else {
	    

	    #----Input Validation----------------------------------------------------------------------
	    for {set a 0} {$a < [string length $ElectrodeTitle]} {incr a} {
		set achar [string range $ElectrodeTitle $a $a]
		
		if {![string is wordchar $achar] && ![string is space $achar] \
			&& ![string match {[.]} $achar] && ![string match {[-]} $achar] && ![string match {[^]} $achar]} {
		    		    error "Cannot add electrode using character $achar  -- Node names can only can contain the following characters: \n     a-z, A-Z, 0-9, _, -, ., ^, and spaces"
		   
		    
		}
	    }
	    #------------------------------------------------------------------------------------------

	    
	    if {$type == -1} {
		set ThisElectrodeType [list Surface Electrode]
	    } else {
		set ThisElectrodeType $type
	    }
	    
	    set ProposedPath [file join [getPath $realtreename $ParentNodeID] $ElectrodeTitle]
	    set UniqueSuffix 1
	    set suffixed 0
	    
	    while {[Tree::itemexists $vistree $ProposedPath]} {
		
		if { $suffixed == 1 } {
		    #delete the suffix
		    set ElectrodeTitle [string replace $ElectrodeTitle [string last _ $ElectrodeTitle] end]
		}
		
		append ElectrodeTitle _ $UniqueSuffix
		set ProposedPath [file join [getPath $realtreename $ParentNodeID] $ElectrodeTitle]
		set suffixed 1
		incr UniqueSuffix
	    }
	    
	    
	    if {![Tree::itemexists $vistree $ProposedPath]} {
		
		#Create a unique identifier for the Electrode
		set ElectrodeID $MasterCount
		incr MasterCount
		
		$realtreename insert $ParentNodeID end $ElectrodeID
		ElectrodeInitialize $realtreename $ElectrodeID
		nameNode $realtreename $ElectrodeID $ElectrodeTitle
		
		$realtreename set $ElectrodeID type $ThisElectrodeType
		
		
	    } else { 
		error "Please select a unique electrode map name"
	    }
	}
	set TreeChanged 1	
	return [list $suffixed $origTitle $ElectrodeID]
    } else {tk_messageBox -type ok -title "Need Selection" -message "Please select a parent in the tree" -icon info}
    
};#end of AddElectrode method

::itcl::body chellyGUI::AddPatient {realtreename ParentNodeID {title -1}} {

    if {[llength $ParentNodeID] > 0} {
	if {$title == -1} {
	    set PatientTitle [Single_Entry_Dialog "New Patient" "Enter a name for the new patient"]
	} else { set PatientTitle $title }
	
	set origTitle $PatientTitle
	
	if {[string match $PatientTitle -1] | [string equal -nocase $PatientTitle "Cancel"]} { return } else {


	    #----Input Validation----------------------------------------------------------------------
	    for {set a 0} {$a < [string length $PatientTitle]} {incr a} {
		set achar [string range $PatientTitle $a $a]
		
		if {![string is wordchar $achar] && ![string is space $achar] \
			&& ![string match {[.]} $achar] && ![string match {[-]} $achar] && ![string match {[^]} $achar]} {
		    
		    error "Cannot add patient using character $achar  -- Node names can only can contain the following characters: \n     a-z, A-Z, 0-9, _, -, ., ^, and spaces"
		    
		}
	    }
	    #------------------------------------------------------------------------------------------

	    set ProposedPath [file join [getPath $realtreename $ParentNodeID] $PatientTitle]
	    set UniqueSuffix 1
	    set suffixed 0
	    
	    while {[Tree::itemexists $vistree $ProposedPath]} {
		
		if { $suffixed == 1 } {
		    #delete the suffix
		    set PatientTitle [string replace $PatientTitle [string last _ $PatientTitle] end]
		}
		
		append PatientTitle _ $UniqueSuffix
		set ProposedPath [file join [getPath $realtreename $ParentNodeID] $PatientTitle]
		set suffixed 1
		incr UniqueSuffix
	    }
	    
	    if {![Tree::itemexists $vistree $ProposedPath]} {
		
		#Create a unique identifier for the Patient
		set PatientID $MasterCount
		incr MasterCount
		
		$realtreename insert $ParentNodeID end $PatientID
		PatientInitialize $realtreename $PatientID
		nameNode $realtreename $PatientID $PatientTitle
		
		
	    } else { error "Please select a unique patient name" }
	}
	set TreeChanged 1	
	return [list $suffixed $origTitle $PatientID]
	
    } else {tk_messageBox -type ok -title "Need Selection" -message "Please select a parent in the tree" -icon info}
}

::itcl::body chellyGUI::AddFolder {realtreename ParentNodeID {title -1}} {
    if {[llength $ParentNodeID] > 0} {
	if {$title == -1} {
	    set FolderTitle  [Single_Entry_Dialog "Add Folder" "Enter a name for the new folder"]
	} else { set FolderTitle $title }
	
	set origTitle $FolderTitle
	
	if {[string match $FolderTitle -1] | $FolderTitle == "" | \
		[string equal -nocase $FolderTitle "Cancel"]} { return } else {


	    #----Input Validation----------------------------------------------------------------------
	    for {set a 0} {$a < [string length $FolderTitle]} {incr a} {
		set achar [string range $FolderTitle $a $a]
		
		if {![string is wordchar $achar] && ![string is space $achar] \
			&& ![string match {[.]} $achar] && ![string match {[-]} $achar] && ![string match {[^]} $achar]} {
		    error "Cannot add folder using character $achar  -- Node names can only can contain the following characters: \n     a-z, A-Z, 0-9, _, -, ., ^, and spaces"
		    
		}
	    }
	    #------------------------------------------------------------------------------------------



		    
		    set ProposedPath [file join [getPath $realtreename $ParentNodeID] $FolderTitle]
		    set UniqueSuffix 1
		    set suffixed 0
		    
		    while {[Tree::itemexists $vistree $ProposedPath]} {
			
			if { $suffixed == 1 } {
			    #delete the suffix
			    set FolderTitle [string replace $FolderTitle [string last _ $FolderTitle] end]
			}
			
			append FolderTitle _ $UniqueSuffix
			set ProposedPath [file join [getPath $realtreename $ParentNodeID] $FolderTitle]
			set suffixed 1
			incr UniqueSuffix
		    }
		    
		    
		    if {![Tree::itemexists $vistree $ProposedPath]} {
			
			#Create a unique identifier for the Folder
			set FolderID $MasterCount
			incr MasterCount
			
			$realtreename insert $ParentNodeID end $FolderID
			FolderInitialize $realtreename $FolderID
			nameNode $realtreename $FolderID $FolderTitle
			
						
		    } else { 
			error "Please select a unique image name"
		    }
		}
	set TreeChanged 1	
	return [list $suffixed $origTitle $FolderID]
    } else {tk_messageBox -type ok -title "Need Selection" -message "Please select a parent in the tree" -icon info}
};#end of AddFolder method


::itcl::body chellyGUI::AddImage {realtreename ParentNodeID {title -1} {type -1}} {
    if {[llength $ParentNodeID] > 0} {
	if {$title == -1} {
	    set ImageTitle [ImageEntryDialog]
	} else { set ImageTitle $title }
	
	set origTitle $ImageTitle
	
	if {[string match $ImageTitle -1] | $ImageTitle == ""} { return } else {

	    #----Input Validation----------------------------------------------------------------------
	    for {set a 0} {$a < [string length $ImageTitle]} {incr a} {
		set achar [string range $ImageTitle $a $a]
		
		if {![string is wordchar $achar] && ![string is space $achar] \
			&& ![string match {[.]} $achar] && ![string match {[-]} $achar] && ![string match {[^]} $achar]} {
		    error "Cannot add image using character $achar  -- Node names can only can contain the following characters: \n     a-z, A-Z, 0-9, _, -, ., ^, and spaces"
		    
		}
	    }
	    #------------------------------------------------------------------------------------------

	    
	    set ThisImageType -1
	    if {$type == -1} {
		#set image type if the name corresponds with one of the known types
		foreach {key value} [array get RecognizedTypes] {
		    if { $ImageTitle == $value } {
			set ThisImageType $key
		    }
		}
		
		if {$ThisImageType == -1} {
		    #		puts "Added an image of unrecognized type"
		}
		
	    } else {
		set ThisImageType $type
	    }
	    
	    set ProposedPath [file join [getPath $realtreename $ParentNodeID] $ImageTitle]
	    set UniqueSuffix 1
	    set suffixed 0
	    
	    while {[Tree::itemexists $vistree $ProposedPath]} {
		
		if { $suffixed == 1 } {
		    #delete the suffix
		    set ImageTitle [string replace $ImageTitle [string last _ $ImageTitle] end]
		}
		
		append ImageTitle _ $UniqueSuffix
		set ProposedPath [file join [getPath $realtreename $ParentNodeID] $ImageTitle]
		set suffixed 1
		incr UniqueSuffix
	    }
	    
	    
	    if {![Tree::itemexists $vistree $ProposedPath]} {
		
		#Create a unique identifier for the Image
		set ImageID $MasterCount
		incr MasterCount
		
		$realtreename insert $ParentNodeID end $ImageID
		ImageInitialize $realtreename $ImageID
		nameNode $realtreename $ImageID $ImageTitle
		$realtreename set $ImageID type $ThisImageType
		
		
	    } else { 
		error "Please select a unique image name"
	    }
	}
	set TreeChanged 1	
	return [list $suffixed $origTitle $ImageID]
    } else {tk_messageBox -type ok -title "Need Selection" -message "Please select a parent in the tree" -icon info}
};#end of AddImage method

::itcl::body chellyGUI::undo { } {

    puts "==========================="
    puts $undoArray(previousCutParent)
    puts $undoArray(previousPaste)
    puts "==========================="
#need before cut selectpath parent (call this B)
#need after cut selectpath (call this A)
#cut from A to B
    $this mdCopy 1 $undoArray(previousPaste) 
    $this mdPaste $undoArray(previousCutParent)
#select A
#cut A
#select B
}

::itcl::body chellyGUI::AddSubtree {realtreename ParentNodeID {ListedTree -1}} {

    if {$ListedTree == -1} {
	#Get the list that specifies the tree definition arra
	set ListedTree [$FileManager LoadDatatree]
    }

    if {$ListedTree != -1} {
	$mdTopWidget config -cursor watch;  update idletasks    
	#Rebuild the tree definition array
	array set AddedTreeDefArray $ListedTree
	
	set TempTree [	::struct::tree [pxvtable::vnewobj] deserialize $AddedTreeDefArray(serialized)  ]

	$TempTree set [$TempTree rootname] title [$TempTree rootname]
	foreach node [$TempTree children -all [$TempTree rootname]] {
	    $TempTree set $node title $AddedTreeDefArray($node,title)
	}

	set container 0;# Force no container for now.
	if {$container != 0} {

	    #------------------------------------------------------------------------------------------
	    # Use this part to put in an extra containing folder made from the root node to hold the 
	    # imported tree
	    #------------------------------------------------------------------------------------------
	    
	    set FolderID $MasterCount
	    incr MasterCount
	    $realtreename insert $ParentNodeID end $FolderID
	    FolderInitialize $realtreename $FolderID
	    
	    nameNode $realtreename $FolderID [$TempTree rootname]
	    updateVisTree $vistree $RealTree $FolderID
	    
	    set folderpath [getPath $realtreename [$realtreename parent $FolderID]]
	
	    #------------------------------------------------------------------------------------------
	} else {
	    #make sure that folderpath refers to an existing, initialized node in the tree.  
	    #(it becomes eqivalent to the rootnode in the source tree)
	    set folderpath [getPath $realtreename $ParentNodeID]
	    set folderpath [append folderpath /]
	}
	
	$TempTree walk [$TempTree rootname] node {
	    if {$node != [$TempTree rootname]} {

		if {$container != 0} {
		    set newpath [file join $folderpath [string trimleft [getPath $TempTree [$TempTree parent $node]] / ] ]
		} else {
		    set newpath [file join $folderpath [string trimleft [getPath $TempTree [$TempTree parent $node]] "/[$TempTree rootname]" ] ]
		}

		set ImageTitle [$TempTree get $node title]
		set proposedpath [file join $newpath $ImageTitle]
		set UniqueSuffix 1
		set suffixed 0

		while {[Tree::itemexists $vistree $proposedpath]} {
		    
		    if { $suffixed == 1 } {
			#delete the suffix
			set ImageTitle [string replace $ImageTitle [string last _ $ImageTitle] end]
		    }
		    
		    append ImageTitle _ $UniqueSuffix
		    set proposedpath [file join [getPath $realtreename $ParentNodeID] $ImageTitle]
		    set suffixed 1
		    incr UniqueSuffix
		}
		
		#Rename the node in the def tree, so the walk works
		$TempTree set $node title $ImageTitle
		
		set realparentID [GetIDFromSelection $newpath]

	
		#set the type
		$TempTree set $node type $AddedTreeDefArray($node,type)

		#----------------------------------------
		if {[$TempTree get $node type] == "Patient"} { 
		    set addedpatient [AddPatient $RealTree $realparentID $ImageTitle]
		    if {[lindex $addedpatient 0]} {
			error "Patient [lindex $addedpatient 1] already exists in tree"
		    }
		}
		if {[$TempTree get $node type] == "Atlas"} {
		    AddAtlasNode $RealTree $realparentID $ImageTitle
		}
		if {[$TempTree get $node type] == "ROIDef"} {
		    AddROIDefNode $RealTree $realparentID $ImageTitle
		}
		if {[$TempTree get $node type] == "Folder"}  { 
		    AddFolder $RealTree $realparentID $ImageTitle
		}
		if {[IsNodeImage $node $TempTree]} { 
		    AddImage $RealTree $realparentID $ImageTitle [$TempTree get $node type]
		}
		if {[IsNodeSurface $node $TempTree]} {
		    switch -exact -- [lindex [$TempTree get $node type] 1] {
			"surface" -
			"Surface" {
			    AddSurface $RealTree $realparentID $ImageTitle [$TempTree get $node type]
			}
			"landmark" -
			"Landmark" {
			    AddLandmark $RealTree $realparentID $ImageTitle [$TempTree get $node type]
			}
			"electrode" -
			"Electrode" {
			    AddElectrode $RealTree $realparentID $ImageTitle [$TempTree get $node type]
			}
		    };# End switch
		    
		};#End if (Is it a surface?)
		#----------------------------------------

		#Now that it exists, figure out what ID it has been assigned
		set RealNodeID [GetIDFromSelection [append newpath / $ImageTitle]]
		
		
		#--------------------------------------------------
		#Set the filenames if they are saved
		#--------------------------------------------------
		if { $AddedTreeDefArray($node,filename) != -1 } {
		    setNodeFilename $RealNodeID $AddedTreeDefArray($node,filename)
		}
		if { $AddedTreeDefArray($node,transtoparfilename) != -1 } {
		    setNodeTransformToParFile $RealNodeID $AddedTreeDefArray($node,transtoparfilename)
		}
		if { $AddedTreeDefArray($node,transfromparfilename) != -1 } {
		    setNodeTransformFromParFile $RealNodeID $AddedTreeDefArray($node,transfromparfilename)
		}
		#--------------------------------------------------
		
		
		if {$AddedTreeDefArray($node,isid)} {
		    toggleIdentity $RealNodeID 1
		}
	
		#set the notes for the node
		if { [lsearch [array names AddedTreeDefArray] "${node},notes"] != -1 } {
		    $RealTree set $RealNodeID notes [string map {{\n} \n} $AddedTreeDefArray($node,notes)]
		} else {puts " ${node},notes Not there" }

		
		if {$container != 0} {
		    set folderpath [getPath $realtreename [$realtreename parent $FolderID]]
		} else { set folderpath [getPath $realtreename $ParentNodeID] }

	    };# End if
	}; # End walk

	updateVisTree $vistree $RealTree $ParentNodeID
	$surgerygadget WatchOff
	$mdTopWidget config -cursor ""
	set TreeChanged 1	

    }
}




::itcl::body chellyGUI::AddMSBData { realtreename ParentNodeID {title -1} {ListedTree -1}} {

    if {[llength $ParentNodeID] > 0} {
 	if {$ListedTree == -1} {
 	    #Get the list that specifies the tree definition arra
 	    set ListedTree [$FileManager LoadMSBfile]
 	}

 	if {$ListedTree != -1} {
	    
 	    #Rebuild the tree definition array
 	    array set AddedTreeDefArray $ListedTree
	    
 	    #First, add the reference Image as a child of the selection
 	    set ReferenceImage $AddedTreeDefArray(ReferenceImage)
	    puts stderr "ParentNodeId=$ParentNodeID, $ReferenceImage"
 	    set REFimageID [lindex [AddImage $realtreename $ParentNodeID [file tail $ReferenceImage]] 2]
 	    setNodeFilename $REFimageID $ReferenceImage
	    
	    set suffixlist $AddedTreeDefArray(tasksuffixes)
	    set tasknamelist $AddedTreeDefArray(tasknames)

	    
 	    #Now, add all subjects as children of reference
 	    for {set n 0} {$n < $AddedTreeDefArray(numsubjects)} {incr n} {
		
 		set AnatImage $AddedTreeDefArray($n,Anatomical)
 		set subjname  $AddedTreeDefArray($n,Name)

 		if {[llength $AnatImage] > 0} {

 		    set ANATimageID [lindex [AddImage $realtreename $REFimageID $subjname ] 2]
 		    setNodeFilename $ANATimageID $AnatImage
 		    if {[llength $AddedTreeDefArray($n,ReferenceTrans)] > 0} {
 			setNodeTransformFromParFile $ANATimageID $AddedTreeDefArray($n,ReferenceTrans)
 		    }
 		} else {set ANATimageID [lindex [AddImage $realtreename $REFimageID "Anatomical"] 2]}
		
 		set ConvImage $AddedTreeDefArray($n,Conventional)
 		if {[llength $ConvImage] > 0} {
 		    set CONVimageID [lindex [AddImage $realtreename $ANATimageID "${subjname} Conventional"] 2]
 		    setNodeFilename $CONVimageID $ConvImage
 		    if {[llength $AddedTreeDefArray($n,InternalTrans)] > 0} {
 			setNodeTransformFromParFile $CONVimageID $AddedTreeDefArray($n,InternalTrans)
 		    }
 		} else {set CONVimageID [lindex [AddImage $realtreename $ANATimageID "${subjname} Conventional"] 2]}

		#Add fieldmap image under conventional if it exists
		set FieldMapImage $AddedTreeDefArray($n,FieldMap)
 		if {[llength $FieldMapImage] > 0} {
 		    set FIELDimageID [lindex [AddImage $realtreename $CONVimageID "$subjname Fieldmap"] 2]
 		    setNodeFilename $ECHOimageID $FieldMapImage
 		}

		set NewFolderID [lindex [AddFolder $realtreename $CONVimageID "$subjname Functional Data"] 2]
		toggleIdentity $NewFolderID 0
		setNodeTransformFromParFile $NewFolderID $AddedTreeDefArray($n,DistortionTrans)

		lappend VisCloseList $NewFolderID

		#Add echoplanar image in folder if it exists
		set EchoplanarImage $AddedTreeDefArray($n,Echoplanar)
 		if {[llength $EchoplanarImage] > 0} {
 		    set ECHOimageID [lindex [AddImage $realtreename $NewFolderID "$subjname Echoplanar"] 2]
 		    setNodeFilename $ECHOimageID $EchoplanarImage
 		    toggleIdentity $ECHOimageID 1
 		}

 		#--------------------------------------------------------------------------------
		#Add all tasks in folder
 		for {set g 0} {$g < [llength $suffixlist]} {incr g} {
 		    set suffix [lindex $suffixlist $g]
 		    set ThisTaskImageFile $AddedTreeDefArray($n,Task_$suffix)
 		    if {[llength $ThisTaskImageFile] > 0} {
 			set TASKimageID [lindex [AddImage $realtreename $NewFolderID [lindex $tasknamelist $g]] 2]
 			setNodeFilename $TASKimageID $ThisTaskImageFile
 			toggleIdentity $TASKimageID 1
 		    } 
		};# End of loop that runs for each task
 		#--------------------------------------------------------------------------------
	    
 	    };# End of loop that runs for each subject


	    # Add a folder to include all Average functional data etc.
	    set FolderID [lindex [AddFolder $realtreename $REFimageID "00 Statistics"] 2]
	    lappend VisCloseList $FolderID

	    #--------------------------------------------------------------------------------
	    #Now add the Average Anatomical
	    set AverageAnatImage $AddedTreeDefArray(AverageAnatomical)
	    if {[llength $AverageAnatImage] > 0} {
		set AVGANATimageID [lindex [AddImage $realtreename $FolderID "Average Anatomical"] 2]
		setNodeFilename $AVGANATimageID $AverageAnatImage
		toggleIdentity $AVGANATimageID 1
	    } 
	    #Now add the Anatomical StdDev
	    set StdAnatImage $AddedTreeDefArray(StdAnatomical)
	    if {[llength $StdAnatImage] > 0} {
		set STDANATimageID [lindex [AddImage $realtreename $FolderID "Anatomical Std Dev"] 2]
		setNodeFilename $STDANATimageID $StdAnatImage
		toggleIdentity $STDANATimageID 1
	    } 
		
	    #--------------------------------------------------------------------------------
	    # Functional Averages
	    #--------------------------------------------------------------------------------
	    foreach st {AverageFunctional StdFunctional ZscoreFunctional} {	   
	     	for {set h 0} {$h < [llength $suffixlist]} {incr h} {
	      		    set suffix [lindex $suffixlist $h]
	      		    set ThisImageFile $AddedTreeDefArray($st,Task_$suffix)
	      		    if {[llength $ThisTaskImageFile] > 0} {
	      			set STATimageID [lindex [AddImage $realtreename $FolderID "$st - [lindex $tasknamelist $h]"] 2]
	      			setNodeFilename $STATimageID $ThisImageFile
	      			toggleIdentity $STATimageID 1
	      		    } 
	    	    
		};# End of loop that runs for each task
	    }
	    updateVisTree $vistree $RealTree $ParentNodeID; CloseNodes $VisCloseList
	}
    } else {
	tk_messageBox -type ok -title "Need Selection" -message "Please select a parent in the tree" -icon info
    }
}

::itcl::body chellyGUI::AddCSIPatient { realtreename ParentNodeID {title -1} {ListedTree -1}} {

    
    if {$ListedTree == -1} {
	#Get the list that specifies the tree definition arra
	set ListedTree [$FileManager LoadCSIPatientFile]
    }

    if {$ListedTree != -1} {

	#Rebuild the tree definition array
	array set AddedTreeDefArray $ListedTree

	#First, add the reference Image as a child of the selection
	set CSIAnatomicalImage $AddedTreeDefArray(Anatomical)
	set CSIAnatomicalID [lindex [AddImage $realtreename $ParentNodeID [file tail $CSIAnatomicalImage]] 2]
	setNodeFilename $CSIAnatomicalID $CSIAnatomicalImage
	
	#Then, add the conventional image as a child of the Anatomical Image
	set ConventionalImage $AddedTreeDefArray(Conventional)
	set ConventionalID [lindex [AddImage $realtreename $CSIAnatomicalID [file tail $ConventionalImage]] 2]
	setNodeFilename $ConventionalID $ConventionalImage
	
	#Set the transformation from the CSI Conv. up to the Anatomical
	setNodeTransformFromParFile $ConventionalID $AddedTreeDefArray(TransAnat2CSIConv)


	#Now add the other images as children of the conventional (They will all be identities)
	set RawCSIImage $AddedTreeDefArray(RawCSIImage)
	set RawCSIID [lindex [AddImage $realtreename $ConventionalID "Raw_CSI_Image"] 2]
	setNodeFilename $RawCSIID $RawCSIImage
	toggleIdentity $RawCSIID 1
	#----------------------------------------------------------------------
	set PMAPCSIImage $AddedTreeDefArray(PMAPCSIImage)
	set PMAPCSIID [lindex [AddImage $realtreename $ConventionalID [file tail "PMAP_CSI_Image"]] 2]
	setNodeFilename $PMAPCSIID $PMAPCSIImage
	toggleIdentity $PMAPCSIID 1
	#----------------------------------------------------------------------
	if {[llength $AddedTreeDefArray(NormSmooth1)] > 0} {
	    set NormSmooth1Image $AddedTreeDefArray(NormSmooth1)
	    set NormSmooth1ID [lindex [AddImage $realtreename $ConventionalID "Normalized_Smoothed_1"] 2]
	    setNodeFilename $NormSmooth1ID $NormSmooth1Image
	    toggleIdentity $NormSmooth1ID 1
	}
	#----------------------------------------------------------------------
	if {[llength $AddedTreeDefArray(NormSmooth2)] > 0} {
	    set NormSmooth2Image $AddedTreeDefArray(NormSmooth2)
	    set NormSmooth2ID [lindex [AddImage $realtreename $ConventionalID "Normalized_Smoothed_2"] 2]
	    setNodeFilename $NormSmooth2ID $NormSmooth2Image
	    toggleIdentity $NormSmooth2ID 1
	}
	
	updateVisTree $vistree $RealTree $ParentNodeID
	set TreeChanged 1
	
    }


}

::itcl::body chellyGUI::AddAllCSI { realtreename ParentNodeID } {

    set folderpath [tk_chooseDirectory]
    
    foreach CSIfile [glob -directory $folderpath *.csi] {
	
	set ThisPatientID [lindex [AddPatient $realtreename $ParentNodeID [file tail [file root $CSIfile]]] 2]

	set ThisListedTree [$FileManager LoadCSIPatientFile $CSIfile]
	AddCSIPatient $RealTree $ThisPatientID -1 $ThisListedTree
		
    }

    updateVisTree $vistree $RealTree $ParentNodeID
    set TreeChanged 1

}

######################################################################
######################################################################
######################################################################
######################################################################

::itcl::body chellyGUI::nodeName { node } {
    
    foreach {key value} [array get NodeIDs] {
	#	puts "$value --> $key"
	if {$value == $node} {
	    return [file tail $key]
	}
    }
    
    return -1
    
}

::itcl::body chellyGUI::getNodesOfTransformation { trans } {
    
    set a [string range $trans [expr [string last , $trans] + 1] [expr [string first : $trans] - 1] ]
    set b [string range $trans [expr [string last : $trans] + 1] end]
    
    lappend result $a
    lappend result $b
    
    return $result
    
}


::itcl::body chellyGUI::findTransforms { realtreename args } {
    
    #This method takes in (optionally) sequential pair of nodeIDs, and calculates the transformations between them
    #If no nodes are specified, then all nodes in the tree are assumed, and all possible transformations calculated
    
    if {[llength $args] > 0} {
	if {[expr fmod([llength $args],2)]} {error "findTransforms requires an even number of arguments"}
	
	foreach {n1 n2} $args {
	    lappend nodeones $n1
	    lappend nodetwos $n2
	}
	
    } else {
	
	set nodeones  [$realtreename children -all [$realtreename rootname]]
	set nodetwos  [$realtreename children -all [$realtreename rootname]]
	
    };# End else
    
    #--------------------------------------------------------------------------------
    #This part of the method sets the "Transforms" array variable to
    #contain the possible transformations for the tree nodes specified
    
    foreach node1 $nodeones {
	foreach node2 $nodetwos {
	    set TransformsCache($myname,$node1:$node2) [makeTransformList $realtreename $node1 $node2]
	}
    }
    
    
};# End findTransforms method

::itcl::body chellyGUI::makeTransformList { realtreename node1 node2 } {
    
    #This makes a list of transformations to go from the image at node1
    #to the image at node2.  
    
    #First, get the nearest common ancestor for the two nodes
    set common [commonAncestor $realtreename $node1 $node2]
    
    #-----------------------------------------------------------------------
    #-----------------------------------------------------------------------
    #Get the whole list of ancestors for node2
    
    set twoancestors [$realtreename ancestors $node2]
    set twoparents [linsert $twoancestors 0 $node2]
    
    
    #this yields the number of steps taken from node2 up to the common node
    set num2 [lsearch $twoparents $common]
    
    #this trims the list to avoid overlaps
    if { $node2 != $common } {
	if {[llength $twoparents] > [expr [lsearch $twoparents $common] + 1]} {
	    #set the list of images to go through back from node2 to the common node
	    set twoback [lreplace $twoparents [expr [lsearch $twoparents $common] + 1] end]
	} {set twoback [list $twoparents]} 
    } else {set twoback [list $node2]}
    
    
    #-----------------------------------------------------------------------
    #Now Get the list of ancestors for node1
    
    set oneancestors [$realtreename ancestors $node1];#(this fails to include node1 itself)
    set oneparents [linsert $oneancestors 0 $node1];#so we append it manually
    
    
    #this yields the number of steps taken from node1 up to the common node
    set num1 [lsearch $oneparents $common]
    
    #trim the list
    if { $node1 != $common } {
	if {[llength $oneparents] > [expr [lsearch $oneparents $common] + 1]} {
	    #set the list of images to go through back from node1 to the common node
	    set oneback [lreplace $oneparents [expr [lsearch $oneparents $common] + 1] end]
	} else {set oneback [list $oneparents]}
    } else { set oneback [list $node1]}
    
    
    
    #-----------------------------------------------------------------------
    #-----------------------------------------------------------------------
    
    
    #Create a list out of the connections between each member of oneback and its
    #subsequent entry
    if {[llength $oneback] > 1} {
	for {set y 0} {$y < [expr [llength $oneback] - 1]} {incr y} {
	    lappend TransformList "$myname,[lindex $oneback $y]:[lindex $oneback [expr $y + 1]]"
	}
    } else {lappend TransformList "identity"}
    
    #Now append an inverse list of twoback, forming the total transformation path
    if {[llength $twoback] > 1} {
	for {set x [expr [llength $twoback] - 1]} {$x > 0} {incr x -1} {
	    lappend TransformList "$myname,[lindex $twoback $x]:[lindex $twoback [expr $x - 1]]"
	}
    } else {lappend TransformList "identity"}
    
    
    #Strike out any element in listoftransforms with the value "identity"
    while {[lsearch $TransformList identity] != -1} {
	set z [lsearch $TransformList identity]
	set TransformList [ lreplace $TransformList $z $z ]
    }
    
    return $TransformList
    
}

::itcl::body chellyGUI::commonAncestor { realtreename node1 node2 } {
    
    set oneuppers [$realtreename ancestors $node1] 
    set twouppers [$realtreename ancestors $node2]
    
    set ones [ linsert $oneuppers 0 $node1]
    set twos [ linsert $twouppers 0 $node2]
    
    for {set x 0} {$x < [llength $ones]} {incr x} {
	if {[lsearch $twos [lindex $ones $x]] != -1} {
	    set commonNode [lindex $twos [lsearch $twos [lindex $ones $x]]]
	    if {$commonNode != [$realtreename rootname]} {

		    return $commonNode

	    } else { return $commonNode }
	}
    }
}


::itcl::body chellyGUI::removeIDnodes { realtreename nodelist } {
    
    #This will get rid of any images in the list whose "IsIdentity" property has been set to 1
    #First set up a key list from the values of the key in the tree
    for {set n 0} {$n < [llength $nodelist]} {incr n} {
	lappend ikeylist [$realtreename get [lindex $nodelist $n] IsIdentity]
    }
    
    
    #Now modify the list, to change any node that corresponds to an identity key to a dummy value
    for {set m 0} {$m < [llength $nodelist]} {incr m} {
	if {[lindex $ikeylist $m] == 1} {
	    lappend modlist identity
	} else { lappend modlist [lindex $nodelist $m] }
    }
    
    return $modlist
    
    #now go through and strike out any element in the list with the value "identity"
    while {[lsearch $modlist identity] != -1} {
	set z [lsearch $modlist identity]
	set modlist [ lreplace $modlist $z $z]
    }
    
    
}


::itcl::body chellyGUI::checkForIllegalCharacters { inputName } {
  
    for {set a 0} {$a < [string length $inputName]} {incr a} {
	set achar [string range $inputName $a $a]
	
	if {![string is wordchar $achar] && ![string is space $achar] \
		&& ![string match {[.]} $achar] && ![string match {[-]} $achar] && ![string match {[^]} $achar]} {
	    
	    set warning "Cannot rename node using character $achar  -- Node names can only can contain the following characters: \n     a-z, A-Z, 0-9, _, -, ., ^, and spaces."
	    
	    tk_messageBox -type ok -title "Please choose a new name" -message $warning -icon error
	    return 0
	}
    }   
    return 1
}

::itcl::body chellyGUI::nameNode {realtreename node newtitle  } {
     
    if {0} {
    set selectionPath "[ lindex [ Tree::getselectionpath $vistree ] 0 ]/"
    foreach path [ array names NodeIDs ] {
	if { [ regexp ^$selectionPath $path ] } {
	    #unset NodeIDs($path)
	}   
    }
    #unset NodeIDs([ lindex [ Tree::getselectionpath $vistree ] 0 ])
    }


    if {0} {
	
	set selectionTitle [ $realtreename get $node title ]
	set selectionPath "[ lindex [ Tree::getselectionpath $vistree ] 0 ]/"
	set offset [ expr [ string length $selectionPath ] - [ string length $selectionTitle ] - 2 ]
	
	foreach path [ array names NodeIDs ] {
	    if { [ regexp ^$selectionPath $path ] } {
		puts "-------------------------------"
		puts $path
		set newSelectionPath [ regsub -start $offset -- $selectionTitle $path $newtitle ] ;#figure out
		puts $newSelectionPath
		puts "-------------------------------"
		#set NodeIDs($newSelectionPath) $NodeIDs($path)
		#unset NodeIDs($path)
	    }
	}
	#unset NodeIDs([ lindex [ Tree::getselectionpath $vistree ] 0 ])
	#$realtreename set $node title $newtitle
    }
    







    #--------------------------------------------------
    #This figures out all keys in NodeIDs that will be deleted
    set pathList [$realtreename rootname]
    set pathListIDs [$realtreename ancestors $node]
 
    for {set y [expr [llength $pathListIDs] - 1]} {$y > -1} {incr y -1} {
	if {[lindex $pathListIDs $y] != [$realtreename rootname]} {
	    lappend pathList [$realtreename get [lindex $pathListIDs $y] title]
    	}
    }
    
    set pathName /
    for {set i 0} {$i < [llength $pathList]} {incr i} {
	    append pathName [lindex $pathList $i]
	append pathName /
    }
    
    append pathName [$realtreename get $node title]
    
    lappend PathsToDelete $pathName
    
    unset pathName
    
    #--------------------------------------------------
    
    #We must also delete all the keys for the children 
    foreach child [$realtreename children -all $node] {
	
	#--------------------------------------------------
	#This sets the key in the reverse array for a lookup
	set pathList [$realtreename rootname]
	set pathListIDs [$realtreename ancestors $child]
	
	for {set y [expr [llength $pathListIDs] - 1]} {$y > -1} {incr y -1} {
	    if {[lindex $pathListIDs $y] != [$realtreename rootname]} {
		    lappend pathList [$realtreename get [lindex $pathListIDs $y] title]
		
	    }
	}
	
	set pathName /
	for {set i 0} {$i < [llength $pathList]} {incr i} {
		append pathName [lindex $pathList $i]
	    append pathName /
	}
	
	append pathName [$realtreename get $child title]
	
	lappend PathsToDelete $pathName
	
	    unset pathName
	
	#--------------------------------------------------
    }
    
    
    #Now, for any item in PathsToDelete, we delete the key in NodeIDs

    foreach path $PathsToDelete {
	catch {unset NodeIDs($path)}
    }

    
    #------------------------------------------------------------------------------------------
    
    
    #Now we rename the node and reset all the Lookup keys in NodeIDs
    #####################################################
	
    $realtreename set $node title $newtitle	
   
    #####################################################
    
    #--------------------------------------------------
    #This sets the key in the reverse array for a lookup
    set pathList [$realtreename rootname]
    set pathListIDs [$realtreename ancestors $node]
    
    for {set y [expr [llength $pathListIDs] - 1]} {$y > -1} {incr y -1} {
	if {[lindex $pathListIDs $y] != [$realtreename rootname]} {
	    lappend pathList [$realtreename get [lindex $pathListIDs $y] title]
	    
	}
    }
	
    set pathName /
	for {set i 0} {$i < [llength $pathList]} {incr i} {
	    append pathName [lindex $pathList $i]
	    append pathName /
	}
    append pathName [$realtreename get $node title]
    #puts $pathName
    set NodeIDs($pathName) $node
	
    #--------------------------------------------------
    
    foreach child [$realtreename children -all $node] {
	
	#--------------------------------------------------
	#This sets the key in the reverse array for a lookup
	set pathList [$realtreename rootname]
	set pathListIDs [$realtreename ancestors $child]
	
	for {set y [expr [llength $pathListIDs] - 1]} {$y > -1} {incr y -1} {
		if {[lindex $pathListIDs $y] != [$realtreename rootname]} {
		    lappend pathList [$realtreename get [lindex $pathListIDs $y] title]
		    
		}
	}
	
	    set pathName1 /
	for {set i 0} {$i < [llength $pathList]} {incr i} {
	    append pathName1 [lindex $pathList $i]
	    append pathName1 /
	}
	append pathName1 [$realtreename get $child title]
	
	set NodeIDs($pathName1) $child
	#--------------------------------------------------
	    
    }
    
    set TreeChanged 1
}




#------------------------------------------------------------------------------------------
::itcl::body chellyGUI::setNodeFilename { node {filename -1}} {
    
    if {$node != ""} {
	if {$node == [$RealTree rootname]} { return -1 } 
	if {![$RealTree keyexists $node pxitclobj]} { return -1 }
	
	if {$filename == -1} {
	    
	    if {[IsNodeImage $node -1 1]} {
		set nu  [$FileManager GetImageFileName]
		if {$nu != -1} {
		    $RealTree set $node FileName $nu
		}
	    } else {
		if {[lindex [$RealTree get $node type] 0] == "Surface"} {
		    switch -exact -- [lindex [$RealTree get $node type] 1] {
			"Surface" {
			    set nu  [$FileManager GetSurfaceFileName]
			    if {$nu != -1} {
				$RealTree set $node FileName $nu
			    }
			}
			"Landmark" {
			    set nu  [$FileManager GetLandmarkFileName]
			    if {$nu != -1} {
				$RealTree set $node FileName $nu
			    }
			}
			"Electrode" {
			    set nu [$FileManager GetElectrodeFileName]
			    if {$nu != -1} {
				$RealTree set $node FileName $nu
			    }
			}
		    }
		}
	    }
	} else {
	    $RealTree set $node FileName $filename
	}
	
	$RealTree set $node FileLoaded 0
	
	
	#----------------------------------------------------------------------------------------------------------#
	#Uncomment this for loading of file as soon as filename is set (insted of on-demand)                       #
	# 	if {[IsNodeImage $node -1 1]} {                                                                         #
	# 	    $FileManager LoadFile [$RealTree get $node pxitclobj] [$RealTree get $node FileName] Image     #
	# 	} else {                                                                                           #
	#                                                                                                          #
	#	if {[lindex [$RealTree get $node type] 0] == "Surface"} {                                          #
	#	    switch -exact -- [lindex [$RealTree get $node type] 1] {                                       #
	#		                                                                                           #
	# 		"Surface" {$FileManager LoadFile [$RealTree get $node pxitclobj] \                         #
	# 			       [$RealTree get $node FileName] Surface}                                     #
	# 		"Landmark" {$FileManager LoadFile [$RealTree get $node pxitclobj] \                        #
	# 				[$RealTree get $node FileName] Landmark}                                   #
	# 		"Electrode" {$FileManager LoadFile [$RealTree get $node pxitclobj] \                       #
	# 				 [$RealTree get $node FileName] Electrode}                                 #
	# 	    }                                                                                              #
	#         }                                                                                           #
	#	}                                                                                                  #
	#----------------------------------------------------------------------------------------------------------#
	
	#If the node happens to be the atlas definition node, send the pxitcl object to AtlasProg class
	# and load the Image automatically
	if {[$RealTree get $node type] == "Atlas"} {
	    if { $AtlasModule !=0 } {
		$AtlasModule SetAtlasSpaceDefImage [$RealTree get $node pxitclobj]
	    }
	    $FileManager LoadFile [$RealTree get $node pxitclobj] [$RealTree get $node FileName] Image
	    $RealTree set $node FileLoaded 1
	}
	
	#Set the status bar to read out the filename
	$statusLabel config -text [$RealTree get $node FileName]
	
	if {[$RealTree get $node FileName] != -1} {
	    $RealTree set $node icon $brainiconchoice
	}

	set TreeChanged 1	

    } else {return -1}
}

::itcl::body chellyGUI::setNodeTransformToParFile { node {filename -1}} {
    
    ###Sets the transformation up TO the parent
 
    if {$node != ""} {
	if {$node == [$RealTree rootname]} { return -1 }
	if {![$RealTree keyexists $node pxitclTransToParent]} { return -1 }
	
	if {$filename == -1} {
	    set nutrns [$FileManager GetTransformationFileName]
	    if {$nutrns != -1} {
		$RealTree set $node TransToParFileName $nutrns
	    }

	} else {
	    $RealTree set $node TransToParFileName $filename
	}

	#Set the "filename" "fileset" tags in the TransformsCache Array
	if {[$RealTree get $node TransToParFileName] != -1} {
	    $RealTree set $node ToParFilenameSet 1

	    set TransformsCache($myname,$node:[$RealTree parent $node],fname) [$RealTree get $node TransToParFileName]
	    set TransformsCache($myname,$node:[$RealTree parent $node],fileset) 1

	    #puts "Setting TransformsCache($node:[$RealTree parent $node],fileset) to 1"
	    #puts " --- name:  [$RealTree get $node TransToParFileName]"
	    #puts "-------- extension:  [file extension [$RealTree get $node TransToParFileName]]"

	}

	#----------------------------------------
	#If the transformation is a matrix, it is pretty small, so just load it right away
	if { [file extension [$RealTree get $node TransToParFileName]] == ".matr"} {
	    #puts "Loading $node:$RealTree parent $node automatically"

	    $FileManager LoadTransformationFile [$RealTree get $node pxitclTransToParent] \
		[$RealTree get $node TransToParFileName]
	    
	    #Set the "loaded" property of the Cache Array to 1

	    set TransformsCache($myname,$node:[$RealTree parent $node],loaded) 1
	    
	    
	    set vtk_transform [[$RealTree get $node pxitclTransToParent] GetObject]
	    set forig [ $RealTree get $node TransToParFileName ]
	    
#	    puts "Is Transformation Linear?: [ $vtk_transform IsA "vtkLinearTransform" ]"

	    #If it's linear, we can just load the inverse as well
	    #------------------------------------------------------------


	    if { [ $vtk_transform IsA "vtkLinearTransform" ] == 1 } {

		set tr2 $myname,[$RealTree parent $node]:$node 
		$tr2 CopyTransformation $vtk_transform
		$tr2 configure -filename $forig
		$tr2 Invert
		$tr2 configure -filename "[ $tr2 cget -filename ].donotsave" 

		$RealTree set $node FromParFilenameSet 1

		#set the inverse file name
		$RealTree set $node TransFromParFileName [$tr2 cget -filename]

		

		set TransformsCache($myname,[$RealTree parent $node]:$node,fname) [$tr2 cget -filename]
		set TransformsCache($myname,[$RealTree parent $node]:$node,fileset) 1
		set TransformsCache($myname,[$RealTree parent $node]:$node,loaded) 1
		
	    }
	    #------------------------------------------------------------
	}
	#----------------------------------------
		
	doTransformsExist $RealTree $node
	set TreeChanged 1
    }
     
}

::itcl::body chellyGUI::setNodeTransformFromParFile { node {filename -1}} {
    
    ###Set the transformation down FROM the parent
 

    if {$node != ""} {
	if {$node == [$RealTree rootname]} { return -1 } 
	if {![$RealTree keyexists $node pxitclTransFromParent]} { return -1 }
	
	if {$filename == -1} {
	    set nutrns [$FileManager GetTransformationFileName]
	    if {$nutrns != -1} {
		$RealTree set $node TransFromParFileName $nutrns
	    }
	} else {
	    $RealTree set $node TransFromParFileName $filename
	}

	if {[$RealTree get $node TransFromParFileName] != -1} {
	    $RealTree set $node FromParFilenameSet 1	
	    set TransformsCache($myname,[$RealTree parent $node]:$node,fname) [$RealTree get $node TransFromParFileName]
	    set TransformsCache($myname,[$RealTree parent $node]:$node,fileset) 1

	    #puts "Setting TransformsCache($myname,$node:[$RealTree parent $node],fileset) to 1"
	    #puts "---name: [$RealTree get $node TransFromParFileName]"
	    #puts "extension:  [file extension [$RealTree get $node TransFromParFileName]]"



	}



	#----------------------------------------
	#If the transformation is a matrix, it is pretty small, so just load it right away
	if { [file extension [$RealTree get $node TransFromParFileName]] == ".matr"} {



	    $FileManager LoadTransformationFile [$RealTree get $node pxitclTransFromParent] \
		[$RealTree get $node TransFromParFileName]
	
	    set TransformsCache($myname,[$RealTree parent $node]:$node,loaded) 1

	    set vtk_transform [[$RealTree get $node pxitclTransFromParent] GetObject]
	    set forig [ $RealTree get $node TransFromParFileName ]
	    
	    #If it's linear, we can just load the inverse as well
	    if { [ $vtk_transform IsA "vtkLinearTransform" ] == 1 } {

		set tr2 [$myname,$node:[$RealTree parent $node] GetThisPointer]
		$tr2 CopyTransformation $vtk_transform
		$tr2 configure -filename $forig
		$tr2 Invert
		$tr2 configure -filename "[ $tr2 cget -filename ].donotsave" 
		

		$RealTree set $node ToParFilenameSet 1

		$RealTree set $node TransToParFileName [$tr2 cget -filename]

		set TransformsCache($myname,$node:[$RealTree parent $node],fname) [$tr2 cget -filename]
		set TransformsCache($myname,$node:[$RealTree parent $node],fileset) 1
		set TransformsCache($myname,$node:[$RealTree parent $node],loaded) 1

	    }
	    
	}
	#----------------------------------------
	
    #This sets the Visualization tree linecolors to reflect the presence of transforms
    doTransformsExist $RealTree $node
    set TreeChanged 1

    }

   
    
}


::itcl::body chellyGUI::toggleIdentity { node {explicitSetting -1}} {
      
    if {![$RealTree keyexists $node IsIdentity]} { return -1 }
    set current [$RealTree get $node IsIdentity]
    
        
    if { $current == 1 | $explicitSetting == 0 } { 
	
	####----------------------------------------
	#set the "IsIdentity" property to 0 and set all transformations to and from this node as unloaded
	####----------------------------------------
	
	$RealTree set $node IsIdentity 0
	
	if {[$RealTree get $node FileName] != -1} {
	    $RealTree set $node icon $brainiconchoice
	} else {
	    $RealTree set $node icon ibraingrey
	}
	
	$RealTree set $node ToParFilenameSet 0
	set TransformsCache($myname,$node:[$RealTree parent $node],fileset) 0
	set TransformsCache($myname,$node:[$RealTree parent $node],loaded) 0
	$RealTree set $node FromParFilenameSet 0
	set TransformsCache($myname,[$RealTree parent $node]:$node,fileset) 0
	set TransformsCache($myname,[$RealTree parent $node]:$node,loaded) 0
	
	
	#  	foreach child [$RealTree children $node] {
	#  	    $RealTree set $child ToParFilenameSet 0
	#  	    set TransformsCache($myname,$child:[$RealTree parent $child],fileset) 0
	#  	    set TransformsCache($myname,$child:[$RealTree parent $child],loaded) 0
	#  	    $RealTree set $child FromParFilenameSet 0
	#  	    set TransformsCache($myname,[$RealTree parent $child]:$child,fileset) 0
	#  	    set TransformsCache($myname,[$RealTree parent $child]:$child,loaded) 0
	
	# 	}
	
	set new [$RealTree get $node IsIdentity]

	set TreeChanged 1
	
	if { $explicitSetting != 1} {
	    return $new
	}

    } 
    
    if { $current == 0 | $explicitSetting == 1 } {
	
	#--------------------------------------------------
	#Set as Identity
	#--------------------------------------------------
	
	#Set the tag
	$RealTree set $node IsIdentity 1 
	#Set transformation to and from parent to identity matrix (Clear)
	[$RealTree get $node pxitclTransToParent] Clear
	[$RealTree get $node pxitclTransFromParent] Clear
	
	$RealTree set $node ToParFilenameSet 1
	set TransformsCache($myname,$node:[$RealTree parent $node],fileset) 1
	set TransformsCache($myname,$node:[$RealTree parent $node],loaded) 1
	$RealTree set $node FromParFilenameSet 1
	set TransformsCache($myname,[$RealTree parent $node]:$node,fileset) 1
	set TransformsCache($myname,[$RealTree parent $node]:$node,loaded) 1
	
	# 	#Also set transform objects to Clear for to and from children
	#  	foreach child [$RealTree children $node] {
	#  	    [$RealTree get $child pxitclTransToParent] Clear
	#  	    [$RealTree get $child pxitclTransFromParent] Clear
	
	#  	    $RealTree set $child ToParFilenameSet 1
	#  	    set TransformsCache($myname,$child:[$RealTree parent $child],fileset) 1
	#  	    set TransformsCache($myname,$child:[$RealTree parent $child],loaded) 1
	#  	    $RealTree set $child FromParFilenameSet 1
	#  	    set TransformsCache($myname,[$RealTree parent $child]:$child,fileset) 1
	#  	    set TransformsCache($myname,[$RealTree parent $child]:$child,loaded) 1
	#  	}
	
	#     }
	
	set new [$RealTree get $node IsIdentity]
	set TreeChanged 1
	return $new
	
    }


::itcl::body chellyGUI::GetIDFromSelection {args} {
    
    if {[llength $args] > 0} {
	set nodepath [concat $args]
    } else {
	set nodepath [Tree::getselectionpath $vistree]
    }    

    if {[lindex $nodepath 0] != "" && [lindex $nodepath 0] != "{}" && $nodepath != "{}" && $nodepath != "" } {
	set ID $NodeIDs([lindex $nodepath 0])
	return $ID
    }
}

::itcl::body chellyGUI::EnsureFileLoaded { node } {
    
    set reload 0; #if this is reset to 1 by the FileManager, then the user will be queried to set a new filename
    
    #------------------------------------------------------------------------------------------
    #If the file is known, but not loaded, load it
    if {[$RealTree get $node FileName] != -1 } {
	if {![$RealTree get $node FileLoaded]} {
	    
	    
	    if {[IsNodeImage $node -1 1]} {
		set reload [$FileManager LoadFile [$RealTree get $node pxitclobj] [$RealTree get $node FileName] Image]
	    } else {
		if {[lindex [$RealTree get $node type] 0] == "Surface"} {
		    switch -exact -- [lindex [$RealTree get $node type] 1] {
			"Surface" {set reload [$FileManager LoadFile [$RealTree get $node pxitclobj] \
						   [$RealTree get $node FileName] Surface]}
			"Landmark" {set reload [$FileManager LoadFile [$RealTree get $node pxitclobj] \
						    [$RealTree get $node FileName] Landmark]}
			"Electrode" {set reload [$FileManager LoadFile [$RealTree get $node pxitclobj] \
						     [$RealTree get $node FileName] Electrode]}
		    }
		}
	    }
	    
	    #--------------------------------------------------------------------------------
	    # If reload has been set to 1, then let the user specify the node filename
	    if { $reload == 1 } { 
		setNodeFilename $node 
		EnsureFileLoaded $node
		updateVisTree $vistree $RealTree $node
	    }
	    #--------------------------------------------------------------------------------

	    $RealTree set $node FileLoaded 1
	}
    } else { 

	#--------------------------------------------------------------------------------
	# If the user wants to specify a file here, do it, and update the tree
	if {[tk_messageBox -type yesno -default no \
		 -message "The file that [$RealTree get $node title] points to does not appear to exist.  Would you like to specify a new one?" -icon question] == "yes"} {
	    setNodeFilename $node 
	    EnsureFileLoaded $node	 
	    updateVisTree $vistree $RealTree $node
	}
	#--------------------------------------------------------------------------------
    }
    #------------------------------------------------------------------------------------------
    
    
    
}


::itcl::body chellyGUI::EnsureTransListLoaded { listoftransforms } {
  
    #-----------------------------------------------------------------------
    # make sure all members of listoftransforms have been loaded
    foreach trns $listoftransforms {

	#If the filename of the transformation is known, but it has not been loaded, then load it
	if { [info exists TransformsCache($trns,fileset)] } {
	    if { $TransformsCache($trns,fileset) == 1 } {
		
		if { [info exists TransformsCache($trns,loaded)] } {
		    if { $TransformsCache($trns,loaded) != 1 } {
			$FileManager LoadTransformationFile chellyGUI::$trns $TransformsCache($trns,fname)
		    }
		} else {
		    $FileManager LoadTransformationFile chellyGUI::$trns $TransformsCache($trns,fname)
		}
	    } else { 
		set g [nodeName [lindex [getNodesOfTransformation $trns] 0]]
		set h [nodeName [lindex [getNodesOfTransformation $trns] 1]]
		error "Transformation not specified for $trns -- $g to $h (Error 0)"
	    }
	} else { 
	    set g [nodeName [lindex [getNodesOfTransformation $trns] 0]]
	    set h [nodeName [lindex [getNodesOfTransformation $trns] 1]]
	    error "Transformation not specified for $trns -- $g to $h (Error -1)"
	}


    }
    #---------------------------------------------------------------------------

  
     
    
}






#------------------------------------------------------------------------------------------
# Public Methods of chellyGUI 
#------------------------------------------------------------------------------------------


#Setter methods to let this class know where the image and transformation control objects are
::itcl::body chellyGUI::setSpaceControlWidget { widget } { set SpaceControlWidget $widget }
::itcl::body chellyGUI::setAnatomicalControlWidget { widget } { set AnatomicalControlWidget $widget }
::itcl::body chellyGUI::setFunctionalControlWidget { widget } { set FunctionalControlWidget $widget }
::itcl::body chellyGUI::setTransformationControlWidget { widget } { set TransformationControlWidget $widget }

::itcl::body chellyGUI::sendSelectionToDisplay { viewerno {ref -1} {node -1}} {
    
    set referencenode -1
    switch -exact -- $node {
	
	"SpaceImage" {
	    set node $SpaceImage
	}
	
	"AnatomicalImage" {
	    set node $AnatomicalImage
	}
	
	"FunctionalImage" {
	    set node $FunctionalImage
	}	
	
	-1 {
	    set node [GetIDFromSelection]
	}
    }
    
    if {$node != -1} {
	
	set pxiobj [$RealTree get $node pxitclobj]
	set type [$RealTree get $node type]
	
	#If the "ref" argument is set, then get the reference object from "SpaceImage"
	if {$ref != -1} { 
	    if {$SpaceImage != -1} {
		set referencenode $SpaceImage
	    } else { error "The Space has not been set"; return -1 }
	}
	
	EnsureFileLoaded $node
	
	if {[IsNodeSurface $node]} {
	    set surftype [lindex $type 1]
	    switch -exact -- $surftype {
		"surface" - 
		"Surface" {
		    displaySurface $viewerno $node $referencenode
		}
		"landmark" -
		"Landmark" {
		    displayLandmarks $viewerno $node $referencenode
		}
		"electrode" -
		"Electrode" {
		    displayElectrodes $viewerno $node $referencenode
		}
	    };# End switch
	};# End if IsNodeSurface
	
	if {[IsNodeImage $node -1 1]} {
	    
	    displayImage $viewerno $node $referencenode
	    
	};# end if IsNodeImage
	
    };# end "if $node != -1"
    
};#End sendSelectionToDisplay method

::itcl::body chellyGUI::displayImage { viewerno imagenode { refnode -1} {background 0} } {
    
    EnsureFileLoaded $imagenode
    set imageobj [$RealTree get $imagenode pxitclobj]
    
    set viewer $viewer1; if { $viewerno == 2 && $viewer2 != 0 }  { set viewer $viewer2 }
    if { $viewer == 0 } {	return    }
    
    if {$refnode != -1} {
	puts "sending image to $viewerno in space of $refnode"
	
	findTransforms $RealTree $refnode $imagenode
	set TopDownTransList $TransformsCache($myname,$refnode:$imagenode)
	EnsureTransListLoaded $TopDownTransList
	set gen [ CreateTransformation $TopDownTransList ]
	
	if { $reslmode < 1 } {
	    set reslmode 0 
	} elseif { $reslmode > 1 } {
	    set reslmode 3
	}

	if { $reslmode == 1 } {
	    set range [ [ [ [ $imageobj GetImage ] GetPointData ] GetScalars ] GetRange ]
	    if { [ lindex $range 1 ] < 2.0 } {
		set reslmode 3
		puts stderr "Switching to Cubic Interpolation because intensity range is 0 - 1"
	    }
	}

	
	set baseimage [$RealTree get $refnode pxitclobj]
	set resl [ vtkbisImageReslice [ pxvtable::vnewobj ]]
	
	$resl SetInformationInput [ $baseimage GetImage ]
	$resl SetInput [ $imageobj GetImage ]
	$resl SetResliceTransform $gen
	$resl SetInterpolationMode $reslmode
	
	$resl SetBackgroundLevel $background
	$resl OptimizationOff
	$resl Update
	
	set newimg [ [ pxitclimage \#auto] GetThisPointer ]
	$newimg ShallowCopyImage [ $resl GetOutput ]
	$newimg CopyImageHeader [ $baseimage GetImageHeader ]
	
	$resl Delete
	$gen Delete
	
	$viewer SetImageFromObject $newimg $this
	$viewer ShowWindow
	::itcl::delete object $newimg 
	
	
    } else {
	$viewer SetImageFromObject $imageobj $this  
	$viewer ShowWindow
    }
    
    
    
}

::itcl::body chellyGUI::displaySurface { viewerno surfacenode { refnode -1}} {
    
    EnsureFileLoaded $surfacenode
    set surfaceobj [$RealTree get $surfacenode pxitclobj]
    
    set viewer $viewer1; if { $viewerno == 2 && $viewer2 != 0 }  { set viewer $viewer2 }
    if { $viewer == 0 } {	return    }
    
    if {$refnode != -1} {
	puts "sending surface to $viewerno in space of $refnode"
	
	findTransforms $RealTree $surfacenode $refnode
	set BottomUpTransList $TransformsCache($myname,$surfacenode:$refnode)
	EnsureTransListLoaded $BottomUpTransList
	
	#debuggin
	pxtkprint "List of Transformation nodes for surface [$RealTree get $surfacenode title] to ref [$RealTree get $refnode title]\n"
	pxtkprint "--------------------------------------------------\n$BottomUpTransList\n\n"
	pxtkprint "Associated list of filenames\n--------------------------------------------------\n"
	for {set v 0} {$v < [llength $BottomUpTransList]} {incr v} {
	    pxtkprint "[lindex $BottomUpTransList $v]:  [[lindex $BottomUpTransList $v] cget -filename]\n"
	}
	pxtkprint "\n\n"
	
	set gen [ CreateTransformation $BottomUpTransList ]
	set newsur [ pxitclsurface \#auto]
	$newsur ShallowCopy $surfaceobj
	$newsur Transform $gen
	$newsur Display $viewer
	$gen Delete
	::itcl::delete object $newsur 
    } else {
	$surfaceobj Display $viewer
    }
}

::itcl::body chellyGUI::displayLandmarks { viewerno landnode { refnode -1}} {
    
    EnsureFileLoaded $landnode
    set landobj [$RealTree get $landnode pxitclobj]
    puts "landmarks: [$landobj GetDescription]"
    
    set viewer $viewer1; if { $viewerno == 2 && $viewer2 != 0 }  { set viewer $viewer2 }
    if { $viewer == 0 } {	return    }
    
    
    if {$refnode != -1} {
	
	findTransforms $RealTree $landnode $refnode
	set BottomUpTransList $TransformsCache($myname,$landnode:$refnode)
	EnsureTransListLoaded $BottomUpTransList
	
	set gen [ CreateTransformation $BottomUpTransList ]
	set newland [ pxitcllandmarks \#auto]
	$newland Copy $landobj
	$newland Transform $gen
	$newland Display $viewer
	$gen Delete
	::itcl::delete object $newland
    } else {
	$landobj Display $viewer
    }
}


::itcl::body chellyGUI::displayElectrodes { econtrol electrodenode { refnode -1}} {

    EnsureFileLoaded $electrodenode
    set electrodeobj [$RealTree get $electrodenode pxitclobj]
    
    set electrodecontrol $electrodecontrol1; if { $econtrol == 2 && $electrodecontrol2 != 0 }  { set electrodecontrol $electrodecontrol2 }
    if { $electrodecontrol == 0 } {	return    }

    #    $electrodecontrol DelayedInitialize
    $electrodecontrol ShowWindow
    
    if {$refnode != -1} {
	
	findTransforms $RealTree $electrodenode $refnode
	set BottomUpTransList $TransformsCache($myname,$electrodenode:$refnode)
	EnsureTransListLoaded $BottomUpTransList
	
	set gen [ CreateTransformation $BottomUpTransList ]
	set newelec [ pxitclelectrodemultigrid \#auto]
	puts "Sending $newelec to electrodecontrol: $electrodecontrol"
	$newelec Copy $electrodeobj
	$newelec Transform $gen

	$newelec Display $electrodecontrol
	$gen Delete
	::itcl::delete object $newelec
	puts "Displaying electrodes"
    } else {
	puts "Displaying electrodes in their own space"
	$electrodeobj Display $electrodecontrol
    }
}


::itcl::body chellyGUI::grabElectrodeAttributes { electrodecontrolno } {

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

::itcl::body chellyGUI::PutViewerObjectInTree { viewerno objtype } {
    
    if {[llength [GetIDFromSelection]] > 0} {
	switch -exact -- $objtype {
	    
	    "image" -
	    "Image" {
		
		
		set ObjectID $MasterCount
		incr MasterCount
		$RealTree insert [GetIDFromSelection] end $ObjectID
		ImageInitialize $RealTree $ObjectID
		GrabViewerImage $viewerno [$RealTree get $ObjectID pxitclobj]
		nameNode $RealTree $ObjectID "Grabbed_Image_$ObjectID"
		
	    }
	    
	    "surface" - 
	    "Surface" {
		
		puts "Adding a surface"
		set ObjectID $MasterCount
		incr MasterCount
		$RealTree insert [GetIDFromSelection] end $ObjectID
		SurfaceInitialize $RealTree $ObjectID
		GrabViewerSurface $viewerno [$RealTree get $ObjectID pxitclobj]
		nameNode $RealTree $ObjectID "Grabbed_Surface_$ObjectID"
		
	    }
	    
	    "landmark" -
	    "Landmark" {
		set ObjectID $MasterCount
		incr MasterCount
		$RealTree insert [GetIDFromSelection] end $ObjectID
		LandmarkInitialize $RealTree $ObjectID
		GrabViewerLandmarkSet $viewerno [$RealTree get $ObjectID pxitclobj]
		nameNode $RealTree $ObjectID "Grabbed_Landmarks_$ObjectID"
		
	    }
	    
	    "electrode" -
	    "Electrode" {
	    	set ObjectID $MasterCount
		incr MasterCount
		$RealTree insert [GetIDFromSelection] end $ObjectID
		ElectrodeInitialize $RealTree $ObjectID
		GrabViewerElectrodes $viewerno [$RealTree get $ObjectID pxitclobj]
		nameNode $RealTree $ObjectID "Grabbed_Electrodes_$ObjectID"
		
	    }
	}
	
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

	
    };#End of main if
    
};#End of method

::itcl::body chellyGUI::GrabViewerImage { viewerno destinationobj } {
    
    set viewer $viewer1; if { $viewerno == 2 && $viewer2 != 0 }  { set viewer $viewer2 }
    if { $viewer == 0 } {	return    }
    
    set img [ $viewer GetDisplayedImage ]
    
    $destinationobj ShallowCopy $img
    
}

::itcl::body chellyGUI::GrabViewerSurface { viewerno newsur} {
    
    set viewer $viewer1; if { $viewerno == 2 && $viewer2 != 0 }  { set viewer $viewer2 }
    if { $viewer == 0 } {	return    }
    
    set surface 0
    catch {
	set surface [ [ [ $viewer GetPolyDataControl ] GetPolyDataControl ]  GetSurface  -1 ]
    }
    if { $surface ==0 } {
	return
    }
    
    $newsur ShallowCopySurface $surface
    $newsur configure -filename "grabbed.vtk"
    puts stderr "[ $newsur GetDescription]"
    
    
}

::itcl::body chellyGUI::GrabViewerLandmarkSet { viewerno newsur } {
    
    set viewer $viewer1; if { $viewerno == 2 && $viewer2 != 0 }  { set viewer $viewer2 }
    if { $viewer == 0 } {	return    }
    
    set landmarkset 0
    catch {
	set landmarkset [ [ [ 
    }
    if { $landmarkset ==0 } {
	return
    }
    
    $newsur CopyLandmarks $landmarkset
    $newsur configure -filename "grabbed.land"
    puts stderr "[ $newsur GetDescription]"
    
    
}

::itcl::body chellyGUI::GrabViewerElectrodes { electrodecontrolno newelec} {
    
    set electrodecontrol $electrodecontrol1; if { $electrodecontrolno == 2 && $electrodecontrol2 != 0 }  { set electrodecontrol $electrodecontrol2 }
    if { $electrodecontrol == 0 } {	return    }
    
    $newelec CopyElectrodeMultiGrid [ $electrodecontrol GetMultiGrid ] 
    
}


::itcl::body chellyGUI::mdCopy { {cut 0} { topnode -1 } } {

    if { $topnode == -1 } {
	set topnode  [GetIDFromSelection]
    }
    
    set parentoftop [$RealTree parent $topnode]
    set undoArray(previousCutParent) $parentoftop
    catch {array unset ClipboardTreeArray}
    catch {unset TemporaryTree}
    
    set TemporaryTree [	::struct::tree [pxvtable::vnewobj] deserialize [$RealTree serialize] ]

    set topsiblings [$TemporaryTree children $parentoftop]
    foreach sib $topsiblings {
	if {$sib != $topnode} {$TemporaryTree delete $sib}
    }
    
    set ClipboardTreeArray(serialized) [$TemporaryTree serialize $parentoftop]
    
    if { $parentoftop == [$RealTree rootname] } {
	set ClipboardTreeArray(rootname) [$RealTree rootname]
    } else { set ClipboardTreeArray(rootname) [$RealTree get $parentoftop title] }

    set ClipboardTreeArray(MC) $MasterCount
    set ClipboardTreeArray(IDs) [array get NodeIDs]

    foreach node [$RealTree children -all $parentoftop] {
	set ClipboardTreeArray($node,title)         [$RealTree get $node title]
	set ClipboardTreeArray($node,type)          [$RealTree get $node type]
	set ClipboardTreeArray($node,isid)          [$RealTree get $node IsIdentity]
	set ClipboardTreeArray($node,icon)          [$RealTree get $node icon]
	set ClipboardTreeArray($node,filename)     [$RealTree get $node FileName]
	set ClipboardTreeArray($node,transtoparfilename)    [$RealTree get $node TransToParFileName]
	set ClipboardTreeArray($node,transfromparfilename)  [$RealTree get $node TransFromParFileName]
	set ClipboardTreeArray($node,notes)  [$RealTree get $node notes]

	#This is just a array key that sets whether a node is expanded or not
	set ClipboardTreeArray($node,expanded) $::Tree::Tree($vistree:[getPath $RealTree $node]:open)

	if {[$RealTree get $node type] == {Surface Electrode}} {
	    set ClipboardTreeArray($node,Attributes)  [$RealTree get $node Attributes]
	}
	if {[$RealTree get $node type] == "Patient"} {
	    set ClipboardTreeArray($node,Properties)  [$RealTree get $node Properties]
	}
    }
    

    if {$cut == 1} {
	delSelectedFromTree
    }
}

::itcl::body chellyGUI::mdPaste { { parentNode -1 } } {

    if { $parentNode == -1 } {
	set parentNode [GetIDFromSelection]
    }
   
    set undoArray(previousPaste) $parentNode
    set listedarray [array get ClipboardTreeArray]
    AddSubtree $RealTree $parentNode $listedarray
}


#Save and Load Tree Methods 

::itcl::body chellyGUI::mdSaveTree { datatree { updatefiles 0 } } {
    
    #Wrap the "notes" key of all nodes in braces, to avoid interpreter confusion on loading
    foreach {node val} [$datatree attr notes] {
	set oldvals($node) [$datatree get $node notes]
	set newval [string map {\n {\n}} [$datatree get $node notes]]
	$datatree set $node notes $newval
    }
    
    #Serialize the tree structure for saving to a variable to be sent over a channel
    set SerializedTree [$datatree serialize]
        
    #Initialize an array, and set the "serialized" index to the tree stucture, and record the rootname 
    #This is the "Tree definition array" - it conatains all info needed to rebuild the tree
    set TreeDefArray(serialized) $SerializedTree
    set TreeDefArray(rootname) [$datatree rootname]
    set TreeDefArray(MC) $MasterCount
    set TreeDefArray(IDs) [array get NodeIDs]
    set TreeDefArray(TypeDefArray) [array get RecognizedTypes]
    set TreeDefArray(PatientProps) $PatientProperties
    
    #Save the filenames in the array for the image, and transformations up and down
    foreach node [$datatree children -all [$datatree rootname]] {
	set TreeDefArray($node,title)         [$datatree get $node title]
	set TreeDefArray($node,type)          [$datatree get $node type]
	set TreeDefArray($node,isid)          [$datatree get $node IsIdentity]
	set TreeDefArray($node,icon)          [$datatree get $node icon]
	set TreeDefArray($node,filename)     [$datatree get $node FileName]
	set TreeDefArray($node,transtoparfilename)    [$datatree get $node TransToParFileName]
	set TreeDefArray($node,transfromparfilename)  [$datatree get $node TransFromParFileName]
	set TreeDefArray($node,notes)  [$datatree get $node notes]
	#This is just a array key that sets whether a node is expanded or not
	set TreeDefArray($node,expanded) $::Tree::Tree($vistree:[getPath $RealTree $node]:open)

	if {[$datatree get $node type] == {Surface Electrode}} {
	    set TreeDefArray($node,Attributes)  [$datatree get $node Attributes]
	}
	if {[$datatree get $node type] == "Patient"} {
	    set TreeDefArray($node,Properties)  [$datatree get $node Properties]
	}
    }
    
    foreach {node val} [$datatree attr notes] {
	$datatree set $node notes $oldvals($node)
    }


    puts stderr "Updatefiles =$updatefiles"
    
    switch -exact -- $updatefiles {
	0 {
	    set ok [ $FileManager SaveDatatree [array get TreeDefArray] ]
	    if { $ok < 0 } { return -1 }
	    set TreeChanged 0
	}
	1 {
	    if {$FileManager == $RelativeFileManager} {
		tk_messageBox -type ok  -message "This function will save a new tree file, and copy all files specified in the tree into the folder that contains it, creating subfolders to preserve the organization of the files.  Use it to create a clean record of the tree files, uncluttered by any extranneous files generated by processing."
		set UpdatedTreeList [$FileManager SaveDataTreeClean [array get TreeDefArray]]
		if {$UpdatedTreeList == -1} { return -1 }
		mdLoadTree $UpdatedTreeList 
		
	    } else { 
		error "The Update Files function requires you to use the Relative Pathnaming Option (See Options menu)." 
	    }
	    set TreeChanged 0
	}

	2 {
	    if {$FileManager == $RelativeFileManager} {
		tk_messageBox -type ok  -message "This function will save a new tree file, and copy all files specified in the tree into the folder that contains it, creating subfolders to match the structure of the folders in the tree."
		set UpdatedTreeList [$FileManager SaveDataTreeFilesReorg [array get TreeDefArray]]
		if {$UpdatedTreeList == -1} { return -1 }
		mdLoadTree $UpdatedTreeList 
	    } else { 
		error "The Update Files function requires you to use the Relative Pathnaming Option (See Options menu)." 
	    }
	    set TreeChanged 0
	}
	
    }

    return 1
}

::itcl::body chellyGUI::mdNewTree { } {

    #If the tree has changes in it, offer the option to save, or cancel
    if {$TreeChanged != 0} {
	set saveNowResponse [tk_messageBox -type yesnocancel -default yes \
		 -message "The tree has changed since it was last saved.  Would you like to save it before exiting?" -icon question]

	if { $saveNowResponse == "cancel"} {
	    return -1;
	}
	if { $saveNowResponse == "yes"} {
	    mdSaveTree $RealTree
	}

    }
    

    #----------------------------------------
    
    #Delete all image and transformation objects
    foreach child [$RealTree children -all [$RealTree rootname]] {
	if {[$RealTree keyexists $child pxitclobj]} {
	    set obj [$RealTree get $child pxitclobj]
	    ::itcl::delete object $obj
	}
	if {[$RealTree keyexists $child pxitclTransToParent]} {
	    set obj [$RealTree get $child pxitclTransToParent]
	    ::itcl::delete object $obj
	}
	if {[$RealTree keyexists $child pxitclTransFromParent]} {
	    set obj [$RealTree get $child pxitclTransFromParent]
	    ::itcl::delete object $obj
	}
    }
    
    foreach obj [array names TransformsCache] {
	catch {::itcl::delete object $obj}
    }
    
    #And delete all the nodes
    foreach child [$RealTree children -all [$RealTree rootname]] {
	catch {$RealTree delete $child}
	}
    
    #Also reset the space, anatomical, and functional images, and AtlasImage
    set SpaceImage -1; 	catch {$IC delete refPIC refTEXT};
    set refbrainTEXT  [$IC create text [expr $rbX+65] [expr $rbY+52] -text "Not Set" \
			   -fill grey61 -font {helvetica 15 bold} -activefill yellow  -tag refTEXT]
    
    set AnatomicalImage -1;	catch {$IC delete anatomPIC anatomTEXT}
    set anatomicalbrainTEXT  [$IC create text [expr $abX+65] [expr $abY+52] -text "Not Set" \
				  -fill grey61 -font {helvetica 15 bold} -activefill yellow  -tag anatomTEXT]
    
    set FunctionalImage -1;	catch {$IC delete funcPIC funcTEXT}
    set funcbrainTEXT  [$IC create text [expr $fbX+65] [expr $fbY+52] -text "Not Set" \
			    -fill grey61 -font {helvetica 15 bold} -activefill yellow -tag funcTEXT]
    
    set AtlasImage -1
    
    updateBigTransLines
    
    #Also Clear the Overlay Tab
    updateOverlayCanvas
    #----------------------------------------
    
    set TreeChanged 0
    updateVisTree $vistree $RealTree
    ::Tree::setselection $vistree /[$RealTree rootname]
    
    
    
}

::itcl::body chellyGUI::mdLoadTree { {ListedTree -1} {filename -1} } {
    
    if {$ListedTree == -1} {
	#Get the list that specifies the tree definition array
	if {$filename == -1} {
	    set ListedTree [$FileManager LoadDatatree]
	} else { set ListedTree [$FileManager LoadDatatree $filename] }
	if { $ListedTree == 0 } {
	    set ListedTree -1 
	}
    }



    if {$ListedTree != -1} {    
	
	#----------------------------------------
	
	#Delete all image and transformation objects
	foreach child [$RealTree children -all [$RealTree rootname]] {
	    if {[$RealTree keyexists $child pxitclobj]} {
		set obj [$RealTree get $child pxitclobj]
		::itcl::delete object $obj
	    }
	    if {[$RealTree keyexists $child pxitclTransToParent]} {
		set obj [$RealTree get $child pxitclTransToParent]
		::itcl::delete object $obj
	    }
	    if {[$RealTree keyexists $child pxitclTransFromParent]} {
		set obj [$RealTree get $child pxitclTransFromParent]
		::itcl::delete object $obj
	    }
	}
	
	foreach obj [array names TransformsCache] {
	    catch {::itcl::delete object $obj}
	}
	
	#And delete all the nodes
	foreach child [$RealTree children -all [$RealTree rootname]] {
	    catch {$RealTree delete $child}
	}
	
	#Also reset the space, anatomical, and functional images, and AtlasImage
	set SpaceImage -1; 	catch {$IC delete refPIC refTEXT};
	set refbrainTEXT  [$IC create text [expr $rbX+65] [expr $rbY+52] -text "Not Set" \
			       -fill grey61 -activefill yellow -font {helvetica 15 bold} -tag refTEXT]
	
	set AnatomicalImage -1;	catch {$IC delete anatomPIC anatomTEXT}
	set anatomicalbrainTEXT  [$IC create text [expr $abX+65] [expr $abY+52] -text "Not Set" \
				      -fill grey61 -activefill yellow -font {helvetica 15 bold} -tag anatomTEXT]
	
	set FunctionalImage -1;	catch {$IC delete funcPIC funcTEXT}
	set funcbrainTEXT  [$IC create text [expr $fbX+65] [expr $fbY+52] -text "Not Set" \
				-fill grey61 -activefill yellow -font {helvetica 15 bold} -tag funcTEXT]

	set AtlasImage -1
	
	updateBigTransLines

	#Also Clear the Overlay Tab
	updateOverlayCanvas
	#----------------------------------------
	
	#Rebuild the tree definition array from the loaded listing
	array set TreeDefArray $ListedTree
	
	if { [lsearch [array names TreeDefArray] ChellysTreeFormat] != -1 } {
	    
	    #explicitly delete the tree held by RealTree
	    $RealTree destroy
	    
	    #initialize MasterCount
	    set MasterCount $TreeDefArray(MC)
	    
	    #reset the "NodeIDs"  array
	    array unset NodeIDs;# $TreeDefArray(IDs)
	    
	    #rebuild the "RealTree" data structure from the serialization contained in the array
	    ::struct::tree $RealTree deserialize $TreeDefArray(serialized)
	    set NodeIDs(/Data) [$RealTree rootname]	
	    
	    #Initialize a list that will hold pointers to nodes that should be displayed collapsed
	    set closenodes ""
	    #Set the image object and transformation object properties at each node
	    foreach node [$RealTree children -all [$RealTree rootname]] {
		
		#set the type
		$RealTree set $node type $TreeDefArray($node,type)

		if {[$RealTree get $node type] == "Atlas"} { AtlasInitialize $RealTree $node }
		if {[$RealTree get $node type] == "ROIDef"} { ROIDefInitialize $RealTree $node }
		if {[$RealTree get $node type] == "Patient"} { 
		    #Initialize as a patient node
		    PatientInitialize $RealTree $node 
		    #set the Properties key
		    if { [lsearch [array names TreeDefArray] "$node,Properties" ] != -1 } {
			$RealTree set $node Properties $TreeDefArray($node,Properties)
		    }
		}
		if {[$RealTree get $node type] == "Folder"}  { FolderInitialize $RealTree $node }
		if {[IsNodeImage $node]}                     { ImageInitialize $RealTree $node }
		if {[IsNodeSurface $node]} {
		    switch -exact -- [lindex [$RealTree get $node type] 1] {
			"surface" -
			"Surface" {
			    SurfaceInitialize $RealTree $node
			}
			"landmark" -
			"Landmark" {
			    LandmarkInitialize $RealTree $node
			}
			"electrode" -
			"Electrode" {
			    ElectrodeInitialize $RealTree $node
			    if {[llength [array names TreeDefArray -exact $node,Attributes]] == 1} {
				$RealTree set $node Attributes $TreeDefArray($node,Attributes)
			    }
			}
		    };# End switch
		    
		};#End if (Is it a surface?)
		
		
		#set the title
		nameNode $RealTree $node $TreeDefArray($node,title)
		
		#reset the type (since initialization overwrites it)
		$RealTree set $node type $TreeDefArray($node,type)
		
		#set the notes for the node
		$RealTree set $node notes [string map {{\n} \n} $TreeDefArray($node,notes)]
		
		#--------------------------------------------------
		#Set the filenames if they are saved
		#--------------------------------------------------
		if { $TreeDefArray($node,filename) != -1 } {
		    setNodeFilename $node $TreeDefArray($node,filename)
		}
		if { $TreeDefArray($node,transtoparfilename) != -1 } {
		    setNodeTransformToParFile $node $TreeDefArray($node,transtoparfilename)
		}
		if { $TreeDefArray($node,transfromparfilename) != -1 } {
		    setNodeTransformFromParFile $node $TreeDefArray($node,transfromparfilename)
		}
		#--------------------------------------------------
		
		#if the expanded/collapsed state of the node has been set explicitly, then set it
		
		if { [lsearch [array names TreeDefArray] "$node,expanded"] != -1 } {
		    if {$TreeDefArray($node,expanded) == 0} {
			lappend closenodes $node
		    }
		} 
	    }
	    
	    #set the "IsIdentity" property of each node explicitly, based on the saved data
	    foreach node [$RealTree children -all [$RealTree rootname]] {
		if {[IsNodeImage $node -1 1] && $TreeDefArray($node,isid)} {
		    toggleIdentity $node 1
		}
	    }
	}
	
	if { [lsearch [array names TreeDefArray] MultiSubjectFormat] != -1 } {
	    
	    AddMultiSubjfMRI $RealTree [$RealTree rootname] x $ListedTree
	    
	}
	
	#If the file contains info for setting the type def array, then do so
	if { [lsearch [array names TreeDefArray] TypeDefArray ] != -1 } {
	    catch {unset RecognizedTypes}
	    array set RecognizedTypes $TreeDefArray(TypeDefArray)
	}
	
	#Same for Patient Properties list
	if { [lsearch [array names TreeDefArray] PatientProps ] != -1 } {
	    unset PatientProperties
	    set PatientProperties  $TreeDefArray(PatientProps)
	    
	}


	set TreeChanged 0
	updateVisTree $vistree $RealTree; CloseNodes $closenodes
	::Tree::setselection $vistree /[$RealTree rootname]
	wm title [$surgerygadget GetBaseWidget] "[file tail $TreeDefArray(ThisFileName)] - Data Tree Manager" 
	
	
	#Update the recent files menu to include the loaded tree
# 	if {[lsearch -exact [array names TreeDefArray] ThisFileName] != -1} {
	    
# 	    set Ser [lsearch $recentfileslist $TreeDefArray(ThisFileName)]
# 	    if { $Ser != -1 } {
# 		set recentfileslist [lreplace $recentfileslist $Ser $Ser]
# 		set recentfilesnames [lreplace $recentfilesnames $Ser $Ser]
# 	    }

# 	    set recentfileslist  [linsert $recentfileslist 0 $TreeDefArray(ThisFileName)]
# 	    set recentfilesnames [linsert $recentfilesnames 0 [file tail $TreeDefArray(ThisFileName)]]

# 	    $RecentFilesMenu delete 0 end
# 	    for {set y 0} { $y < [llength $recentfileslist] } { incr y } {
# 		eval "$RecentFilesMenu add command -label [lindex $recentfilesnames $y] \
# -command {$this mdLoadTree -1 [lindex $recentfileslist $y]} -background \"$menucolor\" -activebackground \"$menuactivebgcolor\""
# 	    }
#	}
        
    }
    
};# end method mdLoadTree


::itcl::body chellyGUI::mdSaveTypeDefs { } {
    
    $FileManager SaveTypeDefs [array get RecognizedTypes]
    
}

::itcl::body chellyGUI::mdLoadTypeDefs { } {
    
    catch {array unset RecognizedTypes}
    set loadedtypes [$FileManager LoadTypeDefs]
    if {$loadedtypes != -1} {
	array set RecognizedTypes $loadedtypes
	set RecogTypeDialogName -1
	setRecognizedTypes
    }

}

::itcl::body chellyGUI::EditPatientPropList { } {

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

::itcl::body chellyGUI::PatientPropDialogCallback { command } {

  
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

::itcl::body chellyGUI::showRecognizedTypes { arraylist } {
    
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


::itcl::body chellyGUI::recognizedTypeDialogCallback { dialogname mode } {
    
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


::itcl::body chellyGUI::setRecognizedTypes { } {
    
    set newarray [showRecognizedTypes [array get RecognizedTypes] ]
    if {$newarray != -1} {
	catch {array unset RecognizedTypes}
	array set RecognizedTypes $newarray
    }
    
}



::itcl::body chellyGUI::SearchTree { realtreename startnode key values } {
    
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
#Transformation concatenation methods

::itcl::body chellyGUI::CreateTransformation { listoftransforms } {
    
    # Generates of vtkGeneralTransform from of a list of transforms
    # -------------------------------------------------------------
    
    #Strike out any element in listoftransforms with the value "identity"
    while {[lsearch $listoftransforms identity] != -1} {
	set z [lsearch $listoftransforms identity]
	set listoftransforms [ lreplace $listoftransforms $z $z ]
    }
    
    
#    puts "Concatenating Transforms: $listoftransforms"
    
    set alllinear 1
    
    
    for { set pass 0 } { $pass <=1 } { incr pass } {
	for { set i 0 } { $i < [ llength $listoftransforms ] } { incr i } {
	    
	    
	    set ta chellyGUI::[lindex $listoftransforms $i]
	    set tr [ $ta  GetTransformation ]
	    
	    if { $pass ==1 } { 
		$gen Concatenate $tr
	    } else {
		if { [ $tr IsA "vtkLinearTransform" ] == 0 } {
		    set alllinear 0
		}
	    }
	}
	
	if { $pass == 0 } {
	    if { $alllinear == 0 } {
		set gen [ vtkGeneralTransform [ pxvtable::vnewobj ]]
	    } else {
		set gen [ vtkTransform [ pxvtable::vnewobj ]]
	    }
	    $gen Identity
	    $gen PostMultiply
	    
	    puts stderr "End of $pass = 0 alllinear = $alllinear"
	}
    }
        
    return $gen
}


::itcl::body chellyGUI::ResliceImage { baseimage imagetoberesliced listoftransforms {fname auto } {background 0 } } {
    
    $mdTopWidget config -cursor watch;  update idletasks
    
    #-----------------------------------------------------------------------
    #First, make sure all members of listoftransforms have been loaded
    
    EnsureTransListLoaded $listoftransforms

    puts \n
    puts \n
    puts "*********************Reslicing! (method chellyGUI::ResliceImage)********************"
    puts "* SpaceImage: [$baseimage cget -filename]"
    puts "* Image Being Resliced: [$imagetoberesliced cget -filename]"
    puts "* List of Transformation filenames sent to Reslicer: \n * ----------------------------------------------------------------------------------"
    foreach l $listoftransforms {
	puts "[$l cget -filename]"
    }
    puts "* ----------------------------------------------------------------------------------"
    puts "************************************************************************************"
    puts \n
    puts \n
    
    set gen [ CreateTransformation $listoftransforms ]
    
    
    if { $reslmode < 1 } {
	set reslmode 0 
    } elseif { $reslmode > 1 } {
	set reslmode 3
    }

    if { $reslmode == 1 } {
	set range [ [ [ [ $imagetoberesliced GetImage ] GetPointData ] GetScalars ] GetRange ]
	if { [ lindex $range 1 ] < 2.0 } {
	    set reslmode 3
	    puts stderr "Switching to Cubic Interpolation to avoid 0..1 bug"
	}
    }
    
    set resl [ vtkbisImageReslice [ pxvtable::vnewobj ]]
    $resl SetInformationInput [ $baseimage GetImage ]
    $resl SetInput [ $imagetoberesliced GetImage ]
    $resl SetResliceTransform $gen
    $resl SetInterpolationMode $reslmode
    
    # Have 1 replaced by a variable of values 0,1 or 3  
    # 0=NearestNeighbor for ROI
    # 1 -- is normal -- use this for anatomical images
    # 3 -- is cubic  -- use this for functional images
    
    $resl SetBackgroundLevel $background
    $resl OptimizationOff
    $resl Update
    
    set imgout [ [pxitclimage \#auto] GetThisPointer ]
    $imgout ShallowCopyImage [ $resl GetOutput ]
    $imgout CopyImageHeader [ $baseimage GetImageHeader ]

    # Extensions Addition
    [ $imgout GetImageHeader ] CopyExtensionsOnly  [ $imagetoberesliced GetImageHeader ]
    # Extensions Addition done

    if { $fname != "auto" } {
	$imgout configure -filename $fname
    } else {
	set refname [ file tail [ file root [$baseimage cget -filename] ] ]
	set srcname [ file root [$imagetoberesliced cget -filename]]

	set newname "${srcname}_mappedto_${refname}.hdr"
	$imgout configure -filename $newname
	puts stderr "New name = $newname"
    }

	
    
    $resl Delete
    $gen Delete 
    
    $surgerygadget WatchOff
    
    $mdTopWidget config -cursor ""
    
    return $imgout
}




##########################################################################################


::itcl::body chellyGUI::makeFileMenu { menu0 } {

    eval "$menu0 add command -label \"New Datatree\" -command {$this mdNewTree} -underline 0  -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Load Datatree\" -command {$this mdLoadTree} -underline 0 -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Save Datatree\" -command {$this mdSaveTree $RealTree} -underline 0 -activebackground \"$menuactivebgcolor\""
    $menu0 add separator 
    eval "$menu0 add command -label \"Save Reorganized Copy\" -command {$this mdSaveTree $RealTree 2} -underline 0 -activebackground \"$menuactivebgcolor\""
    $menu0 add separator 
    eval "$menu0 add command -label \"Switch Directory\" -command { $this SwitchDirectory } "
    set thisparam($this,custdirectories)  [ pxitclfilelistmenu \#auto $menu0 "Custom Directories" "$this SwitchDirectory" ]
    $thisparam($this,custdirectories) SetModeToDirectories
    $thisparam($this,custdirectories) InitializeDisplay

    global env
    set thisparam($this,custtrees)  [ pxitclfilelistmenu \#auto $menu0 "Previous Trees" "$this mdLoadTreeFile " "$this mdGetTreeFileName" ]

    $thisparam($this,custtrees) SetModeToCustom "DataTrees" .tre [ file join $env(HOME) .datatrees ] 1 
    $thisparam($this,custtrees) InitializeDisplay



    $menu0 add separator 
    eval "$menu0 add command -label Exit -command {  $this OnWidgetClose; } -underline 1 -activebackground \"$menuactivebgcolor\""
#    $menu0 add separator 
#    $menu0 add cascade -label "Recent" -menu $menu0.recent -background "$menucolor"  -activebackground "$menuactivebgcolor"
#    set RecentFilesMenu [menu $menu0.recent -tearoff 0]
#    $RecentFilesMenu add separator -background $menucolor

    #Set the background for all menu entries
    for {set i 0} {$i < [$menu0 index end]} {incr i} {
	$menu0 entryconfigure $i -background $menucolor 
    }


}

::itcl::body chellyGUI::makeEditMenu { menu0 } {

    eval "$menu0 add command -label \"Cut\" -command {$this mdCopy 1} -underline 1 -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Copy\" -command {$this mdCopy 0} -underline 0 -activebackground \"$menuactivebgcolor\""
   #  eval "$menu0 add command -label \"Undo\" -command {$this undo} -underline 0 -activebackground \"$menuactivebgcolor\""
    $menu0 add separator
    eval "$menu0 add command -label \"Paste\" -command {$this mdPaste} -activebackground \"$menuactivebgcolor\""   
    $menu0 add separator
    eval "$menu0 add checkbutton -label \"Enable Drag and Drop\" -variable {[itcl::scope dragAndDropEnabled]} \
	    -onvalue 1 -offvalue 0 -activebackground \"$menuactivebgcolor\""
    
    #Set the background for all menu entries
    for {set i 0} {$i <= [$menu0 index end]} {incr i} {
	$menu0 entryconfigure $i -background $menucolor 
    }


}


::itcl::body chellyGUI::makeToolsMenu { menu0 } {

    set toolsmenu $menu0

#     #Add any menu entries in the functional menu from pxitclbrainregister
#     set fmenu [$surgerygadget cget -functional_menu]
#     for {set i 0} {$i < [$fmenu index end]} {incr i} {
# 	if {[$fmenu type $i] == "command"} {
# 	    lappend fmenu_labels [$fmenu entrycget $i -label]
# 	    lappend fmenu_commands [$fmenu entrycget $i -command]
# 	}
#     }

#     for {set j 0} {$j < [llength $fmenu_labels]} {incr j} {
	
# 	eval "$menu0 add command -label \"[lindex $fmenu_labels $j]\" -command { [lindex $fmenu_commands $j] } -activebackground \"$menuactivebgcolor\"" 
#     }

#     $menu0 add separator

   eval "$menu0 add command -label \"Multiple Image Calculations\" -command { $this SearchDialog } -activebackground \"$menuactivebgcolor\""   


   #------------------------------------------------------------------------------------------
   # If the SPECT module is loaded, make a menu for it
   if {$enable_SPECT == 1} {
       eval "$menu0 add command -label \"SPECT Processing Tool\" -command { $this ShowSPECTtool } -activebackground \"$menuactivebgcolor\""  
   }

   if {$enable_AdvancedReg == 1 } {
       eval "$menu0 add command -label \"Advanced Registration Tool\" -command { $this ShowREGtool } -activebackground \"$menuactivebgcolor\""  
   }

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

::itcl::body chellyGUI::makeImageMenu { menu0 } {
    #Set the "Node" menu contents (same as tree popup menu contents)
    eval "$menu0 add command -label \"Set Filename\" -command { $this setSelectedFileName } -underline 0 -activebackground \"$menuactivebgcolor\""
    $menu0 add separator
    eval "$menu0 add command -label \"Rename\" -command { $this renameSelected } -underline 0 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label Delete -command { $this delSelectedFromTree } -underline 0 -activebackground \"$menuactivebgcolor\""    
    $menu0 add separator
    eval "$menu0 add command -label \"Add an Image as Child\" -command { $this addImageToTree } -underline 7 -activebackground \"$menuactivebgcolor\""
    $menu0 add separator
    eval "$menu0 add command -label \"Add an ROI Definition\" -command { $this addROIDefToTree } -activebackground \"$menuactivebgcolor\""
    $menu0 add cascade -label "Add a Surface as Child" -menu $menu0.surfsub -activebackground "$menuactivebgcolor"
    set surfsubmenu [menu $menu0.surfsub -tearoff 0]
    eval "$surfsubmenu add command -label \"Surface\" -command { $this addSurfaceToTree } -background \"$menucolor\" -activebackground \"$menuactivebgcolor\""
    eval "$surfsubmenu add command -label \"Landmark\" -command { $this addLandmarkToTree } -background \"$menucolor\" -activebackground \"$menuactivebgcolor\""
    eval "$surfsubmenu add command -label \"Electrode\" -command { $this addElectrodeToTree } -background \"$menucolor\" -activebackground \"$menuactivebgcolor\""
    
    $menu0 add separator
    eval "$menu0 add command -label \"Load Transformation FROM Parent\" -command { $this setTransFromParent } -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Load Transformation TO Parent (if nonlinear)\" -command { $this setTransToParent } -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"(Un)set as Identity\" -command {$this setIdentityToggle} -activebackground \"$menuactivebgcolor\""
 
    $menu0 add separator
    eval "$menu0 add command -label \"Set Space/Anat. & Send to Ref. Viewer\" -command { $this setSelectionSpace $RealTree; $this setSelectionAnatomical $RealTree; $this sendSelectionToDisplay 1 -1 SpaceImage } -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Set Functional & Send to Trans. Viewer in Ref. Space\" -command { $this setSelectionFunctional $RealTree; $this sendSelectionToDisplay 2 1 FunctionalImage; set REF_FunctionalImage 1 } -activebackground \"$menuactivebgcolor\""
  

    #Set the background for all menu entries
    for {set i 0} {$i <= [$menu0 index end]} {incr i} {
	$menu0 entryconfigure $i -background $menucolor 
    }


    
}

#----------------------------------------
#This menu will go with Surfaces and Landmarks
#----------------------------------------

::itcl::body chellyGUI::makeSurfaceMenu { menu0 } {
    #Set the "Node" menu contents (same as tree popup menu contents)
    eval "$menu0 add command -label \"Set Filename\" -command { $this setSelectedFileName } -underline 0 -activebackground \"$menuactivebgcolor\""
    $menu0 add separator
    eval "$menu0 add command -label \"Rename\" -command { $this renameSelected } -underline 0 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label Delete -command { $this delSelectedFromTree } -underline 0 -activebackground \"$menuactivebgcolor\""    
    $menu0 add separator
    eval "$menu0 add command -label \"Send to Left Viewer\" -command { $this sendSelectionToDisplay 1} -underline 9 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label \"Send to Right Viewer\" -command { $this sendSelectionToDisplay 2} -underline 9 -activebackground \"$menuactivebgcolor\"" 
    $menu0 add separator
    eval "$menu0 add command -label \"Send to Left Viewer (in Reference Space)\" -command { $this sendSelectionToDisplay 1 1} -underline 9 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label \"Send to Right Viewer (in Reference Space)\" -command { $this sendSelectionToDisplay 2 1} -underline 9 -activebackground \"$menuactivebgcolor\"" 


    #Set the background for all menu entries
    for {set i 0} {$i <= [$menu0 index end]} {incr i} {
	$menu0 entryconfigure $i -background $menucolor 
    }

    
}

#----------------------------------------
#This menu will go with Electrodes
#----------------------------------------
::itcl::body chellyGUI::makeElectrodeMenu { menu0 } {
    #Set the "Node" menu contents (same as tree popup menu contents)
    eval "$menu0 add command -label \"Set Filename\" -command { $this setSelectedFileName } -underline 0 -activebackground \"$menuactivebgcolor\""
   
    #If the attribute package is loaded, then allow manipulation of attirbutes
    if {$enable_elec_att == 1} {
	$menu0 add separator
	eval "$menu0 add command -label \"Attribute Visualization Control\" -command { $this SendElectrodeToAtrrControl } -underline 0 -activebackground \"$menuactivebgcolor\""
	eval "$menu0 add command -label \"Load Attributes\" -command { $this mdLoadElectrodeAttributes } -underline 0 -activebackground \"$menuactivebgcolor\""
	eval "$menu0 add command -label \"Update Attributes from Viewer Electrodes\" -command { $this grabElectrodeAttributes 1 } -underline 0 -activebackground \"$menuactivebgcolor\""
	
    }
    $menu0 add separator
    eval "$menu0 add command -label \"Rename\" -command { $this renameSelected } -underline 0 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label Delete -command { $this delSelectedFromTree } -underline 0 -activebackground \"$menuactivebgcolor\""    
    $menu0 add separator
    eval "$menu0 add command -label \"Send to Electrode Control 1\" -command { $this sendSelectionToDisplay 1} -underline 9 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label \"Send to Electrode Control 1 (in Reference Space)\" -command { $this sendSelectionToDisplay 1 1} -underline 9 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label \"Send to Electrode Control 2\" -command { $this sendSelectionToDisplay 2} -underline 9 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label \"Send to Electrode Control 2 (in Reference Space)\" -command { $this sendSelectionToDisplay 2 1} -underline 9 -activebackground \"$menuactivebgcolor\""    


    #Set the background for all menu entries
    for {set i 0} {$i <= [$menu0 index end]} {incr i} {
	$menu0 entryconfigure $i -background $menucolor 
    }

    
}


#------------------------------------------------------------------------------------------
# This Menu is associated with Patient nodes
#------------------------------------------------------------------------------------------
::itcl::body chellyGUI::makePatientMenu { menu0 } {
    
    #Set the "Patient" menu contents (same as tree popup menu contents)
    eval "$menu0 add command -label \"Rename\" -command { $this renameSelected } -underline 0 -activebackground \"$menuactivebgcolor\""    
    eval "$menu0 add command -label \"Delete Selected Patient\" -command { $this delSelectedFromTree } -underline 0 -activebackground \"$menuactivebgcolor\""    
    $menu0 add separator
    eval "$menu0 add command -label \"Load Transformation FROM Parent\" -command { $this setTransFromParent } -activebackground \"$menuactivebgcolor\""
    eval "$menu0 add command -label \"Load Transformation TO Parent (if nonlinear)\" -command { $this setTransToParent } -activebackground \"$menuactivebgcolor\""
    $menu0 add separator
    eval "$menu0 add command -label \"Add a Patient to Tree at Selection\" -command { $this addPatientToTree } -underline 0 -activebackground \"$menuactivebgcolor\""    
 

    #Set the background for all menu entries
    for {set i 0} {$i <= [$menu0 index end]} {incr i} {
	$menu0 entryconfigure $i -background $menucolor 
    }
   
}

#------------------------------------------------------------------------------------------
# This Menu is associated with the top Data node
#------------------------------------------------------------------------------------------

::itcl::body chellyGUI::makeDataMenu { menu0 } {
    
    
    $menu0 add cascade -label "Add Subtree" -menu $menu0.subtreesub -activebackground "$menuactivebgcolor"
    set subtreemenu [menu $menu0.subtreesub -tearoff 0]
    eval "$subtreemenu add command -label \"Native Type\" -command { $this addSubtreeAtSelection 1} -activebackground \"$menuactivebgcolor\""        
    eval "$subtreemenu add command -label \"Multisubject Definition (*.msb)\" -command { $this addSubtreeAtSelection 5} -activebackground \"$menuactivebgcolor\""        
    #    eval "$subtreemenu add command -label \"CSI Patient\" -command { $this addSubtreeAtSelection 3} -activebackground \"$menuactivebgcolor\""        
    #    eval "$subtreemenu add command -label \"All CSI Patients in dir...\" -command { $this addSubtreeAtSelection 4} -activebackground \"$menuactivebgcolor\""        

    $menu0 add separator
 
    eval "$menu0 add command -label \"Add a Folder as Child\" -command { $this addFolderToTree } -activebackground \"$menuactivebgcolor\""  

    #Set the background for all menu entries
    for {set i 0} {$i <= [$menu0 index end]} {incr i} {
	$menu0 entryconfigure $i -background $menucolor 
    }
    #Set the background for all subtreemenu menu entries
    for {set i 0} {$i <= [$subtreemenu index end]} {incr i} {
	$subtreemenu entryconfigure $i -background $menucolor 
    }
 
    
}

#------------------------------------------------------------------------------------------
# This Menu is for bringing up and dealing with the Atlas Tool
#------------------------------------------------------------------------------------------

::itcl::body chellyGUI::makeAtlasMenu { menu0 } {
    
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

::itcl::body chellyGUI::makeOptionsMenu { menu0 } {
    
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
    eval "$savemodemenu add radio -label Relative -variable {[itcl::scope FileManager]} -value $RelativeFileManager -activebackground \"$menuactivebgcolor\""
    eval "$savemodemenu add radio -label Absolute -variable {[itcl::scope FileManager]} -value $AbsoluteFileManager -activebackground \"$menuactivebgcolor\""
    
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
    

    #Set the background for all menu entries
    for {set i 0} {$i <= [$menu0 index end]} {incr i} {
	$menu0 entryconfigure $i -background $menucolor 
    }

    #Set the background for all savemodemenu menu entries
    for {set i 0} {$i <= [$savemodemenu index end]} {incr i} {
	$savemodemenu entryconfigure $i -background $menucolor 
}

    #Set the background for all icontypecascade entries
    for {set i 0} {$i <= [$icontypecascade index end]} {incr i} {
	$icontypecascade entryconfigure $i -background $menucolor 
    }

       
}

#------------------------------------------------------------------------------------------
# This is the definition method for the View Menu
#------------------------------------------------------------------------------------------

::itcl::body chellyGUI::makeViewMenu { menu0 } {
    
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
    

    #Set the background for all menu entries
    for {set i 0} {$i <= [$menu0 index end]} {incr i} {
	$menu0 entryconfigure $i -background $menucolor 
    }

    #Set the background for all icontypecascade entries
    for {set i 0} {$i <= [$icontypecascade index end]} {incr i} {
	$icontypecascade entryconfigure $i -background $menucolor 
    }


}

::itcl::body chellyGUI::makeColorMenu { colormenu icon } {
    
    eval "$colormenu add radio -label Red -variable {[itcl::scope $icon]} -value ibrainred -command { $this updateVisTree $vistree $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$colormenu add radio -label Orange -variable {[itcl::scope $icon]} -value ibrainorange -command { $this updateVisTree $vistree $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$colormenu add radio -label Yellow -variable {[itcl::scope $icon]} -value ibrainyellow -command { $this updateVisTree $vistree $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$colormenu add radio -label Green -variable {[itcl::scope $icon]} -value ibraingreen -command { $this updateVisTree $vistree $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$colormenu add radio -label Blue -variable {[itcl::scope $icon]} -value ibrainblue -command { $this updateVisTree $vistree $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$colormenu add radio -label \"Light Blue\" -variable {[itcl::scope $icon]} -value ibrainlightblue -command { $this updateVisTree $vistree $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$colormenu add radio -label Purple -variable {[itcl::scope $icon]} -value ibrainpurple -command { $this updateVisTree $vistree $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$colormenu add radio -label Rainbow -variable {[itcl::scope $icon]} -value ibrainrainbow -command { $this updateVisTree $vistree $RealTree } -activebackground \"$menuactivebgcolor\""


    #Set the background for all menu entries
    for {set i 0} {$i <= [$colormenu index end]} {incr i} {
	$colormenu entryconfigure $i -background $menucolor 
    }

    
}

::itcl::body chellyGUI::menuActivation { menu menutype } {
    
    if {[llength [GetIDFromSelection]]} {

	if { [$RealTree exists [GetIDFromSelection]]} {
	    
	    
	    switch -exact -- $menutype {
		
		"Image" -
		"image" {
		    #--------------------------------------------------
		    if {[GetIDFromSelection] == [$RealTree rootname]} {
			
			for {set q 0} {$q <= [$menu index last]} {incr q} {
			    if {[$menu type $q] == "command"} {
				$menu entryconfigure $q -state disabled
			    }
			}
			$menu entryconfigure 5 -state normal
			
		    } elseif { [$RealTree get [GetIDFromSelection] type] == "Patient" } {
			
			for {set q 0} {$q <= [$menu index last]} {incr q} {
			    if {[$menu type $q] == "command"} {
				$menu entryconfigure $q -state disabled
			    }
			}
			$menu entryconfigure 5 -state normal
		    } else  {
			for {set q 0} {$q <= [$menu index last]} {incr q} {
			    if {[$menu type $q] == "command"} {
				$menu entryconfigure $q -state normal 
			    }
			}
		    }
		    #--------------------------------------------------
		}
		
		"Patient" -
		"patient" {
		    
		    #--------------------------------------------------
		    if {[GetIDFromSelection] == [$RealTree rootname]} {
			
			for {set q 0} {$q <= [$menu index last]} {incr q} {
			    if {[$menu type $q] == "command"} {
				$menu entryconfigure $q -state disabled
			    }
			}
			$menu entryconfigure 6 -state normal
			
		    } elseif { [$RealTree get [GetIDFromSelection] type] != "Patient" } {
			
			for {set q 0} {$q <= [$menu index last]} {incr q} {
			    if {[$menu type $q] == "command"} {
				$menu entryconfigure $q -state disabled
			    }
			}
			$menu entryconfigure 6 -state normal

		    } else  {
			for {set q 0} {$q <= [$menu index last]} {incr q} {
			    if {[$menu type $q] == "command"} {
				$menu entryconfigure $q -state normal 
			    }
			}
		    }
		    #--------------------------------------------------
		}
		
	    }
	} else { 
	    for {set q 0} {$q <= [$menu index last]} {incr q} {
		if {[$menu type $q] == "command"} {
		    $menu entryconfigure $q -state disabled
		}
	    }
	}
    } else {  
	for {set q 0} {$q <= [$menu index last]} {incr q} {
	    if {[$menu type $q] == "command"} {
		$menu entryconfigure $q -state disabled
	    }
	}
    }
}

::itcl::body chellyGUI::addImageToTree { } {
    
    set newnode [lindex [AddImage $RealTree [GetIDFromSelection]] 2]
    
    if {[llength $newnode]} {
	updateVisTree $vistree $RealTree $newnode
    }
}

::itcl::body chellyGUI::addSurfaceToTree { } {
    
    set newnode [lindex [AddSurface $RealTree [GetIDFromSelection]] 2]
    
    if {[llength $newnode]} {
	updateVisTree $vistree $RealTree $newnode
    }
}

::itcl::body chellyGUI::addLandmarkToTree { } {
    
    set newnode [lindex [AddLandmark $RealTree [GetIDFromSelection]] 2]
   
    if {[llength $newnode]} { 
	updateVisTree $vistree $RealTree $newnode
    }
}

::itcl::body chellyGUI::addElectrodeToTree { } {
    
    set newnode [lindex [AddElectrode $RealTree [GetIDFromSelection]] 2]
    
    if {[llength $newnode]} {
	updateVisTree $vistree $RealTree $newnode
    }    

}

::itcl::body chellyGUI::addPatientToTree { } {
    
    set newnode [lindex [AddPatient $RealTree [GetIDFromSelection]] 2]
    
    if {[llength $newnode]} {
	updateVisTree $vistree $RealTree $newnode
    }
}


::itcl::body chellyGUI::addFolderToTree { } {
    
    set newnode [lindex [AddFolder $RealTree [GetIDFromSelection]] 2]
    
    #recalculate the transformation cache
    
    if {[llength $newnode]} {
	updateVisTree $vistree $RealTree $newnode
    }    
}


::itcl::body chellyGUI::addSubtreeAtSelection { {type 1} } {
    
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

::itcl::body chellyGUI::renameSelected { } {
    
    set thisNode [GetIDFromSelection] 
    if {!$thisNode} {return -1}

    set selectionTitle [ $RealTree get $thisNode title ]
    set newTitle [Single_Entry_Dialog "Rename" "Enter the new name for this node" $selectionTitle]
    
    if { $newTitle == -1} {return -1}
    if { $newTitle == [$RealTree get $thisNode title ] } {return -1}  
    if { ![ checkForIllegalCharacters $newTitle ] } {
	renameSelected
    } else {
	
	set selectionPath "[ lindex [ Tree::getselectionpath $vistree ] 0 ]/"
	set offset [ expr [ string length $selectionPath ] - [ string length $selectionTitle ] - 2 ]
	foreach path [ array names NodeIDs ] {
	    if { [ regexp ^$selectionPath $path ] } {
		set newPath [ regsub -start $offset -- $selectionTitle $path $newTitle ] 
		set NodeIDs($newPath) $NodeIDs($path)
		unset NodeIDs($path)
	    }
	}
	 
	unset NodeIDs([ lindex [ Tree::getselectionpath $vistree ] 0 ])
	set newSelectionPath [ regsub $selectionTitle$ [ lindex [ Tree::getselectionpath $vistree ] 0 ] $newTitle ]
	set NodeIDs($newSelectionPath) $thisNode
	$RealTree set $thisNode title $newTitle
	updateVisTree $vistree $RealTree [ $RealTree parent $thisNode ]
		
	set TreeChanged 1
    } 
}


::itcl::body chellyGUI::delSelectedFromTree { } {
    
    if {[$RealTree get [GetIDFromSelection] type] == "Atlas"} {
	set AtlasImage -1
    }

    set killnode [GetIDFromSelection]
    set parentofkillnode [$RealTree parent [GetIDFromSelection]]
    
    foreach child [$RealTree children -all $killnode] {

	if {[$RealTree keyexists $child pxitclobj]} {
	    set obj [$RealTree get $child pxitclobj]
	    ::itcl::delete object $obj
	}
	if {[$RealTree keyexists $child pxitclTransToParent]} {
	    set obj [$RealTree get $child pxitclTransToParent]
	    ::itcl::delete object $obj
	}
	catch { unset TransformsCache($myname,$child:$killnode) }
	catch { unset TransformsCache($myname,$child:$killnode,fname) }
	catch { unset TransformsCache($myname,$child:$killnode,fileset) }
	
	if {[$RealTree keyexists $child pxitclTransFromParent]} {
	    set obj [$RealTree get $child pxitclTransFromParent]
	::itcl::delete object $obj
	}
	catch { unset TransformsCache($myname,$killnode,$child) }
	catch { unset TransformsCache($myname,$killnode,$child,fname) }
	catch { unset TransformsCache($myname,$killnode,$child,fileset) }
	
    }
    
    #Now delete the actual node to be killed
    
    if {[$RealTree keyexists $killnode pxitclobj]} {
	set obj [$RealTree get $killnode pxitclobj]
	::itcl::delete object $obj
    }
    if {[$RealTree keyexists $killnode pxitclTransToParent]} {
	set obj [$RealTree get $killnode pxitclTransToParent]
	::itcl::delete object $obj
    }
    catch { unset TransformsCache($myname,$killnode:$parentofkillnode) }
    catch { unset TransformsCache($myname,$killnode:$parentofkillnode,fname) }
    catch { unset TransformsCache($myname,$killnode:$parentofkillnode,fileset) }
    
    if {[$RealTree keyexists $killnode pxitclTransFromParent]} {
	set obj [$RealTree get $killnode pxitclTransFromParent]
	::itcl::delete object $obj
    }
    catch { unset TransformsCache($myname,$parentofkillnode,$killnode) }
    catch { unset TransformsCache($myname,$parentofkillnode,$killnode,fname) }
    catch { unset TransformsCache($myname,$parentofkillnode,$killnode,fileset) }
    
    
    
    $RealTree delete $killnode
    
    updateVisTree $vistree $RealTree $parentofkillnode

    set TreeChanged 1
    
}

::itcl::body chellyGUI::setSelectedFileName { } {
    
    #Set the image in question to the currently selected tree item
    set node [GetIDFromSelection]
    
    #Set this node's file name
    setNodeFilename $node
    
    #update the visualization tree
    updateVisTree $vistree $RealTree $node
    
}

::itcl::body chellyGUI::setTransToParent { } {
    
    set node [GetIDFromSelection]
    
    setNodeTransformToParFile $node
    
    updateVisTree $vistree $RealTree $node
    
}

::itcl::body chellyGUI::setTransFromParent { } {
    
    set node [GetIDFromSelection]
    
    setNodeTransformFromParFile $node
    
    updateVisTree $vistree $RealTree $node
    
}

# -----------------------------------------------------

::itcl::body chellyGUI::clearTransToParent { } {
    
    set node [GetIDFromSelection]

    $RealTree set $node TransToParFileName -1
    $RealTree set $node ToParFilenameSet 0
    set TransformsCache($myname,$node:[$RealTree parent $node],fileset) 0
    set TransformsCache($myname,$node:[$RealTree parent $node],loaded) 0
    
    doTransformsExist $RealTree $node
    set TreeChanged 1
    updateVisTree $vistree $RealTree $node
    
}

::itcl::body chellyGUI::clearTransFromParent { } {
    
    set node [GetIDFromSelection]
    
    $RealTree set $node TransFromParFileName -1
    $RealTree set $node FromParFilenameSet 0
    set TransformsCache($myname,[$RealTree parent $node]:$node,fileset) 0
    set TransformsCache($myname,[$RealTree parent $node]:$node,loaded) 0

    doTransformsExist $RealTree $node
    set TreeChanged 1
    updateVisTree $vistree $RealTree $node
    
}


::itcl::body chellyGUI::setIdentityToggle { } {
    
    set node [GetIDFromSelection]
    
    toggleIdentity $node
    
    updateVisTree $vistree $RealTree $node
    
}

#------------------------------------------------------------------------------------------
# These are the Atlas Module Integration Methods
#------------------------------------------------------------------------------------------

::itcl::body chellyGUI::addAtlasToTree { } {
    
    set newnode [lindex [AddAtlasNode $RealTree [GetIDFromSelection]] 2]
    
    #recalculate the transformation cache
    
    if {[llength $newnode]} {
	updateVisTree $vistree $RealTree $newnode
    }
}

::itcl::body chellyGUI::AddAtlasNode { realtreename ParentNodeID {title -1}} {
    if {[llength $ParentNodeID] > 0} {
	if {$title == -1} {
	    set AtlasTitle "Brain_Atlas"
	} else { set AtlasTitle $title }
	
	set origTitle $AtlasTitle
	
	if {[string match $AtlasTitle -1] | $AtlasTitle == ""} { return } else {

	    #----Input Validation----------------------------------------------------------------------
	    for {set a 0} {$a < [string length $AtlasTitle]} {incr a} {
		set achar [string range $AtlasTitle $a $a]
		
		if {![string is wordchar $achar] && ![string is space $achar] \
			&& ![string match {[.]} $achar] && ![string match {[-]} $achar] && ![string match {[^]} $achar]} {
		    error "Cannot add atlas using character $achar  -- Node names can only can contain the following characters: \n     a-z, A-Z, 0-9, _, -, ., ^, and spaces"
		    
		}
	    }
	    #------------------------------------------------------------------------------------------

	    
	    set ProposedPath [file join [getPath $realtreename $ParentNodeID] $AtlasTitle]
	    set UniqueSuffix 1
	    set suffixed 0
	    
	    while {[Tree::itemexists $vistree $ProposedPath]} {
		
		if { $suffixed == 1 } {
		    #delete the suffix
		    set AtlasTitle [string replace $AtlasTitle [string last _ $AtlasTitle] end]
		}
		
		append AtlasTitle _ $UniqueSuffix
		set ProposedPath [file join [getPath $realtreename $ParentNodeID] $AtlasTitle]
		set suffixed 1
		incr UniqueSuffix
	    }
	    
	    
	    if {![Tree::itemexists $vistree $ProposedPath]} {
		
		#Create a unique identifier for the Atlas
		set AtlasID $MasterCount
		incr MasterCount
		
		set AtlasImage $AtlasID
		
		$realtreename insert $ParentNodeID end $AtlasID
		AtlasInitialize $realtreename $AtlasID
		nameNode $realtreename $AtlasID $AtlasTitle
		$realtreename set $AtlasID type Atlas
		
	    } else { 
		error "Please select a unique image name"
	    }
	}
	
	set TreeChanged 1
	return [list $suffixed $origTitle $AtlasID]
	
    } else {tk_messageBox -type ok -title "Need Selection" -message "Please select a parent in the tree" -icon info}
}

::itcl::body chellyGUI::AtlasInitialize { realtreename node } {
    
    NodeInitialize $realtreename $node
    
    $realtreename set $node type Atlas
    $realtreename set $node pxitclobj [ [pxitclimage \#auto] GetThisPointer ]
    
    #A couple display properties for the node
    $realtreename set $node icon $atlasiconchoice
    $realtreename set $node linecolor red
    
    #This node property toggles the "identity" propery for the image - ie, no transformation 
    $realtreename set $node FromParFilenameSet 0
    $realtreename set $node ToParFilenameSet 0
    $realtreename set $node IsIdentity 0
    
 
    
};# end AtlasInitialize method



::itcl::body chellyGUI::AtlasShowSelectedNode { } {
    
    set node [GetIDFromSelection]
    
    SendImageToAtlasModule $node 
}

::itcl::body chellyGUI::SendImageToAtlasModule { { nodeID -1} {raise 1}} {


    #Let user choose an atlas from all displayed in tree:
    #------------------------------------------------------------------------------------------
    catch {unset AtlasChoices}
    foreach node [$RealTree children -all [$RealTree rootname]] {
	if {[$RealTree get $node type] == "Atlas"} {
	    lappend AtlasChoices $node
	}
    }
    
    if {[llength $AtlasChoices] > 1} {
	global AtlasSelectDialogEntryResult -1
	
	foreach c $AtlasChoices {
	    set atlaschoicearray([getPath $RealTree $c]) $c
	}
	
	iwidgets::selectiondialog .atlasselbox -borderwidth 2 -height 200\
	    -labelfont -Adobe-Helvetica-Bold-R-Normal--*-140-*-*-*-*-*-* \
	    -title "Choose ATLAS Definition Image" \
	-textbackground ghostwhite -itemslabel "Atlases Available In Tree:" \
	    -selectionon 0
    
	eval .atlasselbox insert items 0 [array names atlaschoicearray]
	.atlasselbox hide Apply
	.atlasselbox center
	.atlasselbox configure -modality application
	.atlasselbox buttonconfigure OK -command {set AtlasSelectDialogEntryResult [.atlasselbox get]; .atlasselbox deactivate }
	.atlasselbox buttonconfigure Cancel -command {set AtlasSelectDialogEntryResult -1; .atlasselbox deactivate }
	
	update idletasks
	.atlasselbox activate
	destroy .atlasselbox
	#------------------------------------------------------------------------------------------
	
	if {[llength $AtlasSelectDialogEntryResult] < 1} {return}
	if {$AtlasSelectDialogEntryResult == -1} {return}
	
	set AtlasImage $atlaschoicearray($AtlasSelectDialogEntryResult)

    } else { set AtlasImage [lindex $AtlasChoices 0] }

#    puts "Atlas Image - $AtlasImage"
    if {$AtlasImage != -1} {

	if {$nodeID == -1} {
	    set node [GetIDFromSelection]
	} else { set node $nodeID }
	
	
	if {$node != -1 && $node != ""} {
	    
	    #--------------------------------------------------
	    # First send the selected node to the atlas program
	    #--------------------------------------------------
	    EnsureFileLoaded $node
	    set pxiobj [$RealTree get $node pxitclobj]
	    set type [$RealTree get $node type]
	    
	    $AtlasModule LoadImage $pxiobj
	    
	    #--------------------------------------------------
	    # Then figure out the transformation, and send it too
	    #--------------------------------------------------
	    
	    findTransforms $RealTree $node $AtlasImage
	    set AtlasTransList $TransformsCache($myname,$node:$AtlasImage)
	    catch {EnsureTransListLoaded $AtlasTransList} 
	    
	    set gen [ CreateTransformation $AtlasTransList ]    
	    $AtlasModule SetTransToAtlasSpace $gen
	    
	}
	
	if {$raise} {
	    $AtlasModule ShowTop
	} 
    } else { error "No atlas has been set for this tree" }
}

::itcl::body chellyGUI::BringUpAtlasModule { } {
    
    $AtlasModule ShowTop
    
};# end BringUpAtlasModule method


#------------------------------------------------------------------------------------------
# This is the end of the Atlas Module Integration Methods
#------------------------------------------------------------------------------------------


#------------------------------------------------------------------------------------------
# These are the SPECT Processing Module Integration Methods
#------------------------------------------------------------------------------------------

::itcl::body chellyGUI::ShowSPECTtool { } {

    if {$SPECT_initialized == 0} {
	$SPECTmodule Initialize .[pxvtable::vnewobj] $this $viewer2
	set SPECT_initialized 1
    }

    $SPECTmodule ShowTop

}

::itcl::body chellyGUI::ShowREGtool { } {

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

::itcl::body chellyGUI::mdLoadElectrodeAttributes { } { 

 
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


::itcl::body chellyGUI::SendElectrodeToAtrrControl { { nodeID -1} {raise 1} } {
    
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

::itcl::body chellyGUI::PutElectrodeAttrControlOutputInTree { } {

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

::itcl::body chellyGUI::addROIDefToTree { } {
    
    set newnode [lindex [AddROIDefNode $RealTree [GetIDFromSelection]] 2]
    
    #recalculate the transformation cache
    if {[llength $newnode]} {
	updateVisTree $vistree $RealTree $newnode
    }
}

::itcl::body chellyGUI::AddROIDefNode { realtreename ParentNodeID {title -1}} {
    
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

::itcl::body chellyGUI::ROIDefInitialize { realtreename node } {
    
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

#------------------------------------------------------------------------------------------
# These are the search Dialog methods 
#------------------------------------------------------------------------------------------
::itcl::body chellyGUI::SearchDialog { } {
    
    update idletasks
    
    if {$SearchDialogName == -1 | ![winfo exists $SearchDialogName]} {
	
	set SearchDialogName .[ pxvtable::vnewobj ]
	toplevel $SearchDialogName -bg "light blue"
	wm title $SearchDialogName "Search the Tree"
	
	set SearchTopFrame [frame $SearchDialogName.topframe -bg "light blue"]
	pack $SearchTopFrame -side top
	
	#--------------------------------------------------
	set modWidgetWrapper [labelframe $SearchTopFrame.wrapper -bg "light blue" -text "Filter by Modality"]
	pack $modWidgetWrapper -side left -fill x -padx 4 -pady 4
	
	set modalitysel [::iwidgets::scrolledlistbox $modWidgetWrapper.modl -selectmode extended -exportselection 0 \
			     -borderwidth 2 -textbackground ghostwhite -visibleitems 25x15]
	
	foreach r [lsort [array names RecognizedTypes]] {
	    lappend ModalityNames $RecognizedTypes($r)
	}
	
	foreach a $ModalityNames {
	    $modalitysel insert end $a
	}
	pack $modalitysel -fill both -expand 1 -padx 5 -pady 5
	
	#--------------------------------------------------
	
	set wrap2 [frame $SearchTopFrame.wrapper2 -bg "light blue"]
	pack $wrap2 -side left -fill both -padx 4 -pady 4
	#--------------------------------------------------
	set titleWidgetWrapper [labelframe $wrap2.titlewrap -bg "light blue" -text "Filter by Title"]
	pack $titleWidgetWrapper -side top -fill x -padx 4 -pady 4
	#
	set titlesel [::iwidgets::entryfield $titleWidgetWrapper.titl]
	pack $titlesel -side top -fill x -padx 5 -pady 5
	#
	#--------------------------------------------------

	#--------------------------------------------------
	set folderWidgetWrapper [labelframe $wrap2.folderwrap -bg "light blue" -text "Specify Folder(s)"]
	pack $folderWidgetWrapper -side top -fill both -padx 4 -pady 4
	#
	set folderbox [::iwidgets::entryfield $folderWidgetWrapper.folder]
	pack $folderbox -side left -fill x -expand 1 -padx 5 -pady 5
	set folderbutton [eval "button $folderWidgetWrapper.[pxvtable::vnewobj] -text ... -command { $this SearchGetFolder } -background \"light blue\" -width 1"]
	pack $folderbutton -side right -padx {0 4} -pady {0 3}
	#
	#--------------------------------------------------

	set clearbutton [eval "button $wrap2.clearbut -bg yellow -text \"Clear Search Fields\" -command { $SearchDialogName.topframe.wrapper2.titlewrap.titl delete 0 end; $SearchDialogName.topframe.wrapper.modl selection clear 0 end; $folderbox delete 0 end; }"]
	pack $clearbutton -side top -fill x -padx 3 -pady 5
	#
	#--------------------------------------------------
	set instructions [message $wrap2.inst -justify center -relief ridge -text "Select the modalities to search for (left), or enter a title to search for (above).  If both are specified, only images matching both parameters will be returned. Results will appear selected in the list at right.  You may deselect unwanted elements to exclude them from analysis.  Operations below will be performed on the selected elements in the Results list"]
	
	pack $instructions -side top -fill both -padx 5 -pady 5 -expand 1
	#
	#
	#--------------------------------------------------
	#--------------------------------------------------
	set resultWidgetWrapper [labelframe $SearchTopFrame.reswrapper -bg "light blue" -text "Results"]
	pack $resultWidgetWrapper -side left -fill x -padx 4 -pady 4
	
	set resultlist [::iwidgets::scrolledlistbox $resultWidgetWrapper.resl -selectmode multiple -exportselection 0 \
			    -borderwidth 2 -textbackground ghostwhite -visibleitems 45x15]
	pack $resultlist -fill both -expand 1 -padx 5 -pady 5
	
	#--------------------------------------------------------------------------------
	set searchbutton [eval "button $SearchDialogName.sbut -bg green -text \"Search!\" -command {$this SearchCallback $SearchDialogName Search}"]
	pack $searchbutton -side top -fill x -padx 5 -pady 4
	#--------------------------------------------------------------------------------
	
	#------------------------------------------------------------------------------------------------------------
	#--------------Here are the functions that can be performed on the result group------------------------------
	#------------------------------------------------------------------------------------------------------------
	#This frame holds all the group operation buttons
	set OperationsFrame [labelframe $SearchDialogName.oper -bg "light blue" -text "Operations"]
	pack $OperationsFrame -side top -fill both -padx 5 -pady 5
	
	#--------------------------------------------------------------------------------
	set SaveButton [eval "button $OperationsFrame.savebut -bg \"bisque\" -text \"Save Images in Reference Space\" -command {$this SearchCallback $SearchDialogName SaveInRef}"]
	pack $SaveButton -side top -fill x -padx 40 -pady 4
	#--------------------------------------------------------------------------------
	set AverageButton [eval "button $OperationsFrame.avgbut -bg \"bisque\" -text \"Average Images in Reference Space\" -command {$this SearchCallback $SearchDialogName Average}"]
	pack $AverageButton -side top -fill x -padx 40 -pady 4
	#--------------------------------------------------------------------------------
	set ROIButton [eval "button $OperationsFrame.roibut -bg \"bisque\" -text \"Compute ROI stats in Reference Space\" -command {$this SearchCallback $SearchDialogName ROI}"]
	pack $ROIButton -side top -fill x -padx 40 -pady 4
	
	
	
    } else {
	#If the dialog already exists, show it
	switch -- [wm state $SearchDialogName] {
	    normal {
		raise $SearchDialogName
	    }
	    withdrawn -
	    iconic {
		wm deiconify $SearchDialogName
	    }
	}
	return 0
	
    }
};# End SearchDialog method

::itcl::body chellyGUI::SearchGetFolder { } {
    
    set FolderChoices ""
    set foldersearchboxlist ""
    foreach node [$RealTree children -all [$RealTree rootname]] {
	if {[$RealTree get $node type] == "Folder"} {
	    lappend FolderChoices $node
	}
    }
    
    foreach c $FolderChoices {
	set folderchoicearray([$RealTree get $c title]) $c
    }
    
    set foldersearchselbox .[ pxvtable::vnewobj ]

    iwidgets::selectiondialog $foldersearchselbox -borderwidth 2 -height 200\
	-labelfont -Adobe-Helvetica-Bold-R-Normal--*-140-*-*-*-*-*-* \
	-title "Choose Folder" \
	-textbackground ghostwhite -itemslabel "Folders In Tree:" \
	-selectionon 0 

    [$foldersearchselbox component selectionbox]  component items configure -selectmode multiple
   
    eval $foldersearchselbox insert items end [lsort [array names folderchoicearray]]
    set foldersearchboxlist [lsort [array names folderchoicearray]]

    $foldersearchselbox hide Apply
    $foldersearchselbox center
    $foldersearchselbox configure -modality application
    eval "$foldersearchselbox buttonconfigure OK -command {$this FolderSelectionInsert; $foldersearchselbox deactivate }"
    eval "$foldersearchselbox buttonconfigure Cancel -command {$foldersearchselbox deactivate }"
    
    update idletasks
    $foldersearchselbox activate
    destroy $foldersearchselbox
    
    
}

::itcl::body chellyGUI::FolderSelectionInsert { } {

    $folderbox delete 0 end
    foreach indx [$foldersearchselbox curselection] {
	lappend result [lindex $foldersearchboxlist $indx]
    }
    $folderbox insert 0 $result
    
}

::itcl::body chellyGUI::SearchCallback { dialog command } {
    
    set ActiveList [ list ]

    switch -exact -- $command {
	
	"search" -
	"Search" {
	    
	    doSearch $dialog
	    
	}
	
	"saveinref" -
	"SaveInRef" {
	    
	    foreach r [$dialog.topframe.reswrapper.resl getcurselection] {
		lappend ActiveList $ResultDisplay($r)
	    }
	    
	    SaveAllInRef $ActiveList
	    
	}
	
	"average" -
	"Average" {
	    
	    foreach r [$dialog.topframe.reswrapper.resl getcurselection] {
		lappend ActiveList $ResultDisplay($r)
	    }
	    
	    if { ![ llength $ActiveList ] } {
		tk_messageBox -type ok -title "Warning" -message "No images selected" -icon info 
		return -1
	    }

	    set ParentDirectory [tk_chooseDirectory -title "Choose directory to save average in"]	    
	    
	    set AvgFileName [file join $ParentDirectory "group_task"]
	    set ResultImages [ComputeAverages [sendAllToCommonSpace $SpaceImage $ActiveList] $AvgFileName]
	    
	    foreach img $ResultImages {
		$img Save
		
		set ThisName [string totitle [string range [$img cget -filename] [expr [string last "_" [$img cget -filename]] + 1] end]]
		set ThisNodeID [lindex [AddImage $RealTree $SpaceImage $ThisName "Result"] 2 ]
		setNodeFilename $ThisNodeID "[$img cget -filename].hdr"
		toggleIdentity $ThisNodeID 1
		
		updateVisTree $vistree $RealTree $ThisNodeID
	    }
	    
	}
	
	"roi" -
	"ROI" {
	    
	    foreach r [$dialog.topframe.reswrapper.resl getcurselection] {
		lappend ActiveList $ResultDisplay($r)
	    }
	    
	    MultipleROI $ActiveList
	    
	}
	
	
    };# End switch
    
}

::itcl::body chellyGUI::doSearch { dialog } {
    
    
    set selectedlist [$dialog.topframe.wrapper.modl getcurselection]
    set titlequery [$dialog.topframe.wrapper2.titlewrap.titl get]
    set folderquery [$folderbox get]

    set FinalResultList ""
    set allfolderlist ""
    set allfoldernamelist ""
    set foldermatches ""
    set Result1 ""
    set Result2 ""
    set Result3 ""
    
    #Clear the result window
    $dialog.topframe.reswrapper.resl delete 0 end

    #--------------------------------------------------------------------------------
    #Make a list of all folder nodes, and a list of all their titles
    set allfolderlist [SearchTree $RealTree [$RealTree rootname] type Folder]
    foreach t $allfolderlist {
	lappend allfoldernamelist [$RealTree get $t title]
    }

    #Now, for each query title, check if it matches one of the folder titles in the tree
    for {set n 0} {$n < [llength $folderquery] } {incr n} {
	set res [lsearch -all -glob $allfoldernamelist [lindex $folderquery $n]]
	if {[llength $res]} {
	    foreach Match $res {
		lappend foldermatches [lindex $allfolderlist $Match]
	    }
	}
    }

    

    #if there are any folder matches, add all children of all matching folders
    if {[llength $foldermatches]} {
	foreach mat1 $foldermatches {
	    foreach child1 [$RealTree children -all $mat1] {
		lappend Result1 $child1
	    }
	}
    } else { 
	#...otherwise, add all nodes
	if {[llength $selectedlist] > 0 | [llength $titlequery] > 0 } {
	    set Result1 [$RealTree children -all [$RealTree rootname]] 
	} 
    }

    set FinalResultList $Result1
    	
    #--------------------------------------------------------------------------------
    #Now check the modality query
    if {[llength $selectedlist] > 0} {
	
	#If a modality has been specified, get a list of all metching nodes
	foreach t [lsort [array names RecognizedTypes]] {
	    
	    lappend ModalityKeys $t
	    lappend ModalityNames $RecognizedTypes($t)
	    
	}
	
	foreach item $selectedlist {
	    lappend selectedkeys [lindex $ModalityKeys [lsearch $ModalityNames $item]]
	};# selected keys is the list of types that the user wants to match
	
	foreach Result1Item $Result1 {
	    set ThisItemType [$RealTree get $Result1Item type]
	    if { [lsearch $selectedkeys $ThisItemType] != -1 } {
		lappend Result2 $Result1Item
	    }
	}

	set FinalResultList $Result2
    } else { 
	#If the modality query has not been specified, just set the results to the same as folder results
	set Result2 $Result1
    }

    if {$titlequery != ""} {
	
	#If a title query has been entered, search the results of the modality search for the title
	foreach node $Result2 {
		if {[$RealTree get $node title] == $titlequery} {
		    lappend Result3 $node
		}
	}
	set FinalResultList $Result3
    }    

    
    foreach d $FinalResultList {
	
	#This translates the node number into a display value for the result list
	set thisresult [getPath $RealTree $d]
	$dialog.topframe.reswrapper.resl insert end $thisresult
	
	#(But we have to keep track of what was displayed, so the user can interact with it)
	set ResultDisplay($thisresult) $d
	
	
    }
    $dialog.topframe.reswrapper.resl selection set 0 end
    
}

::itcl::body chellyGUI::SaveAllInRef { {listofnodes -1} } {
    
    
    if {$listofnodes == -1} {
	return
    } else { set SaveList $listofnodes }
    
    if {[llength $SaveList] > 0} {
	if {$SpaceImage != -1} {
	    
	    set ParDirectory [tk_chooseDirectory -title "Choose parent directory for new folder"]	    
	    set GroupPrefix [Single_Entry_Dialog "Group Folder"  "Enter the Group Folder Name"]
	    if {$GroupPrefix == -1} {return -1}
	    
	    set SaveDirectory [file join $ParDirectory $GroupPrefix]
	    
	    file mkdir $SaveDirectory
	    
	    puts "SaveDirectory: $SaveDirectory\n--------------------------------------------------\n"
	    
	    set count 0
	    foreach node $SaveList {
		
		EnsureFileLoaded $node
		
		incr count
		set thisfilename [nodeName $node]
		set thisfilename [string map {" " _} $thisfilename]
		if {[string first . $thisfilename] != -1} {
		    set thisfilename [string range $thisfilename 0 [expr [string first . $thisfilename] - 1] ]
		}
		append thisfilename _ $count
		
		set filepath [file join $SaveDirectory $thisfilename]
		
		set imageToReslice [$RealTree get $node pxitclobj]
		set baseimage [$RealTree get $SpaceImage pxitclobj]
		
		if {[IsNodeImage $node -1 1]} {
		    findTransforms $RealTree $SpaceImage $node
		    set TransList $TransformsCache($myname,$SpaceImage:$node)
		    
		    puts stdout "Reslicing: [ $imageToReslice GetDescription ] \t [ [ [ [ $imageToReslice GetImage ]  GetPointData ] GetScalars ] GetRange ]"
		    set newreslicedimage [ResliceImage $baseimage $imageToReslice $TransList $filepath]
		    
		    puts stdout "Output: [ $newreslicedimage GetDescription ] \t [ [ [ [ $newreslicedimage GetImage ]  GetPointData ] GetScalars ] GetRange ]"
		    
		    $newreslicedimage Save
		    ::itcl::delete object $newreslicedimage
		}
		
		if {[IsNodeSurface $node]} {
		    findTransforms $RealTree $node $SpaceImage 
		    set TransList $TransformsCache($myname,$node:$SpaceImage)
		    
		    set newreslicedimage [ResliceImage $baseimage $imageToReslice $TransList $filepath]
		    $newreslicedimage Save
		    ::itcl::delete object $newreslicedimage
		}
		
		
	    };# End foreach node
	    
	} else {tk_messageBox -type ok -title "No Space Image Set" -message "The Reference Space image has not been set" -icon info}
    } else {tk_messageBox -type ok -title "No Results to Save" -message "There are no items selected in the results list" -icon info}
    
};# End SaveAllInRef method


::itcl::body chellyGUI::sendAllToCommonSpace { spacenode imagelist } {
    
    set ResList ""
    
    if {$SpaceImage != -1} {
	for {set u 0} {$u < [llength $imagelist]} {incr u} {
	    set node [lindex $imagelist $u]

	    EnsureFileLoaded $node
	    
	    set imageToReslice [$RealTree get $node pxitclobj]
	    set baseimage [$RealTree get $spacenode pxitclobj]
	    
	    
	    if {[IsNodeImage $node -1 1]} {
		findTransforms $RealTree $spacenode $node
		set TransList $TransformsCache($myname,$spacenode:$node)
		
		set newreslicedimage [ResliceImage $baseimage $imageToReslice $TransList]
		
		lappend ResList $newreslicedimage
	    }
	    
	    if {[IsNodeSurface $node]} {
		findTransforms $RealTree $node $spacenode 
		set TransList $TransformsCache($myname,$node:$spacenode)
		
		set newreslicedimage [ResliceImage $baseimage $imageToReslice $TransList $filepath]
		lappend ResList $newreslicedimage
		
	    }
	    
	    
	};# End for u
    } else {tk_messageBox -type ok -title "No Space Image Set" -message "The Reference Space image has not been set" -icon info}
    
    return $ResList
    
}

::itcl::body chellyGUI::ComputeAverages { imagelist filename { background -32767 } } {
    
    set filename [ file root $filename ]
    
    # imagelist is a list of pxitclimages that have been resliced to same space
    
    set num [ llength $imagelist ]
    
    set value     $background   
    # -32767
    set valueout  0.0
    set outputStd 1
    
    set combofmri [  vtkpxAverageImages [ pxvtable::vnewobj ]]
    $combofmri SetMedian 0
    $combofmri SetIgnoreValue $value
    $combofmri SetIgnoreValueOutput $valueout
    $combofmri IgnoreFlagOn
    
    for { set i 0 } { $i < $num } { incr i } {
	
	#ShowProgressVal "Computing Averages image=$i" $progress 
	$combofmri AddInput [ [ lindex $imagelist $i ] GetImage ]
    }
    
    
    #ShowProgressVal  "Computing Averages image=$i" $progress 
    
    $combofmri ComputeStandardDeviationOn
    
    
    $combofmri Update
    #ShowProgressVal "Computed Averages image=$i" $progress 
    
    set baseimage [ lindex $imagelist 0 ]
    
    set meanout [ [pxitclimage \#auto] GetThisPointer ]
    $meanout ShallowCopyImage [ $combofmri GetOutput ]
    $meanout CopyImageHeader [ $baseimage GetImageHeader ]
    $meanout configure -filename "${filename}_average"
    
    set sigmaout [ [pxitclimage \#auto] GetThisPointer ]
    $sigmaout ShallowCopyImage [ $combofmri GetOutputStandardDeviation ]
    $sigmaout CopyImageHeader [ $baseimage GetImageHeader ]
    $sigmaout configure -filename "${filename}_stdev"
    
    $combofmri Delete
    
    set tscoreimage [ ComputeTscoreMap $meanout $sigmaout $num ]
    
    $tscoreimage configure -filename "${filename}_tscore"
    
    return [ list $meanout $sigmaout $tscoreimage ]
    
}


itcl::body chellyGUI::ComputeTscoreMap { immean imvar numsubjects } {
    
    if { [ $immean GetImageSize ] < 2  } {
	::pxtclutil::Warning "No Composite Task In Memory"
	return 0;
    }
    
    if { [ $imvar GetImageSize ] < 2  }  {
	::pxtclutil::Warning "No Composite Task Standard Deviation In Memory"
	return 0;
    }
    
    set cast [ vtkImageCast [ pxvtable::vnewobj ]]
    $cast  SetInput [ $immean GetImage ]
    $cast  SetOutputScalarTypeToFloat
    $cast  Update
    
    set cast2 [ vtkImageCast [ pxvtable::vnewobj ]]
    $cast2 SetInput [ $imvar  GetImage ]
    $cast2 SetOutputScalarTypeToFloat
    $cast2 Update
    
    set tcomp [  vtkpxComputeTmap [ pxvtable::vnewobj ]]
    $tcomp SetInput [ $cast GetOutput ]
    $tcomp SetInputStandardDeviation [ $cast2 GetOutput ]
    $tcomp SetNumberOfInputs 1
    $tcomp SetNumberOfSamples1 $numsubjects
    #SetFilterCallbacks $tcomp  "Computing Composite TMap"
    $tcomp Update
    
    set tscoreout [ [pxitclimage \#auto] GetThisPointer ]
    $tscoreout ShallowCopyImage [ $tcomp GetOutput ]
    $tscoreout CopyImageHeader [ $immean GetImageHeader ]
    $tscoreout configure -filename "tscore_of_group"
    [ $tscoreout GetImage ] SetOrigin 0.0 0.0 0.0
    
    $tcomp Delete 
    $cast Delete
    $cast2 Delete
    return $tscoreout
}

itcl::body chellyGUI::MultipleROI { imagelist } {

    
    
    if {$SpaceImage != -1} {
	
	foreach node [$RealTree children -all [$RealTree rootname]] {
	    if {[$RealTree get $node type] == "ROIDef"} {
		lappend ROIChoices $node
	    }
	}

	#------------------------------------------------------------------------------------------
	global ROIDefDialogEntryResult -1
	
	foreach c $ROIChoices {
	    set roichoicearray([$RealTree get $c title]) $c
	}
	
	iwidgets::selectiondialog .roiselbox -borderwidth 2 -height 200\
	    -labelfont -Adobe-Helvetica-Bold-R-Normal--*-140-*-*-*-*-*-* \
	    -title "Choose ROI Definition Image" \
	    -textbackground ghostwhite -itemslabel "ROI Images In Tree:" \
	    -selectionon 0
        
	eval .roiselbox insert items 0 [array names roichoicearray]
	.roiselbox hide Apply
	.roiselbox center
	.roiselbox configure -modality application
	.roiselbox buttonconfigure OK -command {set ROIDefDialogEntryResult [.roiselbox get]; .roiselbox deactivate }
	.roiselbox buttonconfigure Cancel -command {set ROIDefDialogEntryResult -1; .roiselbox deactivate }
	
	update idletasks
	.roiselbox activate
	destroy .roiselbox
	#------------------------------------------------------------------------------------------
	
	

	#------------------------------------------------------------------------------------------
	# See if user wants to apply a threshold
	#------------------------------------------------------------------------------------------
	set dothresh [tk_messageBox -type yesnocancel -default no \
			  -message "Would you like to run a second round of ROI computations after application of a threshold?" -icon question]

	if {$dothresh == "cancel"} { return -1 }
	if {$dothresh == "yes"} {
	    

	    
	    set threshDialog [iwidgets::promptdialog .[ pxvtable::vnewobj ] -modality application -title "Threshold" \
				  -labeltext "Enter a value to threshold the images at"]
	    
	    $threshDialog hide Apply
	    $threshDialog hide Cancel
	    
	    eval "$threshDialog buttonconfigure OK -command { $this ThresholdLevelDialogCallback }"
	    focus [$threshDialog component prompt component entry]

h
	    
	    $threshDialog center
	    update idletasks
	    $threshDialog activate
	    
	}	    
	#------------------------------------------------------------------------------------------




 	set ROIImageID $roichoicearray($ROIDefDialogEntryResult)

 	#Send the ROI Image to Reference space
 	set ROIinCommonSpace [sendAllToCommonSpace $SpaceImage $ROIImageID] 

 	#Send all images to reference space
 	set commonSpaceImageList [sendAllToCommonSpace $SpaceImage $imagelist] 
	

 	#Do the unthresholded calcs regardless of yes/no
 	foreach image $commonSpaceImageList {
	    
 	    puts "Sending image $image - to ROI Stats"
 	    set UnThreshResult($image) [ComputeROIStatistics $image $ROIinCommonSpace]
 	    # Only do thresholding if dothresh == yes
 	    if {$dothresh == "yes"} {
 		    set threshlist [list $ImageThresholdForROICalcs 10000]
 		    set ThreshResult($image) [ComputeROIStatistics $image $ROIinCommonSpace $threshlist]
 	    }
 	}
	
	#-----Output----------------------------------------------------------------------------
	#Now the data is two arrays - send it to user/file output

	# Fix this to get proper suffix 
	set filename [tk_getSaveFile -title "Saving ROI Output" -initialfile roioutput.txt  -filetypes { {"Text Files" {.txt}} } ]
	if {[llength $filename]} {
	
	    puts "Saving $filename ...."
	    set f [ open $filename w 0666]
	    
	    for {set a 0} {$a < [llength $commonSpaceImageList]} {incr a} {
		
		set image [lindex $commonSpaceImageList $a]
		set imagename [file tail [ file root [[$RealTree get [lindex $imagelist $a] pxitclobj] cget -filename]]]
			
		puts $f     "\#Subject $imagename\n"
		puts $f     "\#Unthresholded"
		foreach line $UnThreshResult($image) {
		    puts $f [string trim $line]
		}
		puts $f "\n"
		if {$dothresh == "yes"} {
		    puts $f \n
		    puts $f "\#Thresholded"
		    puts $f "\#Threshold Level:  $ImageThresholdForROICalcs"
		    foreach line $ThreshResult($image) {
			puts $f [string trim $line]
		    }
		}
		
	    }
	    close $f
	}
		       
	#---------------------------------------------------------------------------------------
			   

		
    } else {tk_messageBox -type ok -title "No Space Image Set" -message "The Reference Space image has not been set" -icon info}
  
   
};# End method MultipleROI

itcl::body chellyGUI::ThresholdLevelDialogCallback { } {
    
    set ImageThresholdForROICalcs [$threshDialog get]
    $threshDialog deactivate 

}

# if ComputerROIStatistics gets threshold: it should be -- set threshold [ list $lower $upper ]
itcl::body chellyGUI::ComputeROIStatistics { functional_input roi_image_input { threshold none } } {

    set ReturnData ""

    set fname [ file tail [ $functional_input cget -filename ]]
    set rname [ file tail [ $roi_image_input  cget -filename ]]
	

    set functional [ vtkImageData [ pxvtable::vnewobj ]]
    $functional ShallowCopy [ $functional_input GetImage ] 

    set roi_image [  ${roi_image_input} GetImage ] 

    set dim1 [ $functional GetDimensions ]
    set dim2 [ $roi_image  GetDimensions ]
    if { [lindex $dim2 0 ] <2 || [ lindex $dim1 0 ] < 2 } { 
	::pxtclutil::Warning "No Image in Memory\n Cannot Reslice!"
	return  0
    }

    
    if { $threshold != "none" } {

	puts "Threshold for ROI: $threshold"

	set thr [ vtkImageThreshold [ pxvtable::vnewobj ]]
	$thr SetInput $functional
	$thr ThresholdBetween [ lindex $threshold 0 ] [ lindex $threshold 1 ]
	#------added stuff here-------
	$thr SetOutputScalarTypeToShort
	$thr SetOutValue   0
	$thr ReplaceOutOn
	#---end added stuff-----------
	$thr Update
	$functional ShallowCopy [ $thr GetOutput ]
	$thr Delete
    }

    #    WatchOn
    
    set tr [ vtkIdentityTransform [ pxvtable::vnewobj ] ]

    set thr [ vtkpxMergeFmriConventional [ pxvtable::vnewobj ]]
    set arr [ vtkFloatArray [ pxvtable::vnewobj ]]
    set nt  [  $thr ComputeROIStatistics $functional $roi_image $tr $arr]


    if { $nt > 0 } {
	# Show Console
	pxtkconsole
	# Print Statement
	pxtkprint "ROI Statistics for $fname\n"
	pxtkprint "ROIimage\tFrame\tLevel\tm\tstddev\tnVox\tVol\tnVox>0\tVolVox>0\n"
	#add this same string to the return list
	lappend ReturnData "\#ROI Statistics for $fname\n"
	lappend ReturnData "\#ROIimage\tFrame\tLevel\tm\tstddev\tnVox\tVol\tnVox>0\tVolVox>0\n"
	set total  0
	set totalv 0 
	
	# runs through all frames
	for { set i 0 } { $i < [ $arr GetNumberOfTuples ] } { incr i } {
	   
	    set a1 [ expr round([ $arr GetComponent $i 0 ])]
	    set a2 [ expr round([ $arr GetComponent $i 1 ])]
	    set a3 [ $arr GetComponent $i 3 ]
	    set a4 [ $arr GetComponent $i 4 ]
	    set n1 [ expr round([ $arr GetComponent $i 2 ])]
	    set v1 [ expr round([ $arr GetComponent $i 6 ])]
	    set n2 [ expr round([ $arr GetComponent $i 5 ])]
	    set v2 [ expr round([ $arr GetComponent $i 7 ])]

	    if { $n1 >  0 } {
		#set output1 [ format "Frame %3d\t Region=%5.0f:\t m=%5.2f s=%5.2f\t\t nvox=%7d (%.1f mm^3) nvox>0=%7d (%.1f mm^3)\n" $a1 $a2 $a3 $a4 $n1 $v1 $n2 $v2 ]
		set output1 "$fname\t$a1\t$a2\t$a3\t$a4\t$n1\t$v1\t$n2\t$v2\n"
		pxtkprint $output1
		lappend ReturnData $output1
	    }

	    if { $a2 > 0 } {
		set total [ expr $total + $n2 ]
		set totalv [ expr $totalv + $v2 ]
	    }
	}
	set output2  [ format "\#Total volume for levels >0  nvox>0 = %d  (%.1f mm^3)\n\n" $total $totalv ]
	pxtkprint $output2
	lappend ReturnData $output2
    }

    $thr Delete
    $arr Delete
    $tr  Delete
    $functional Delete
    #    WatchOff 
    
    return $ReturnData

}



#------------------------------------------------------------------------------------------
# End Search Dialog Methods 
#------------------------------------------------------------------------------------------

    



#----------------------------------------------------------------------
#These methods set the functions for the mouse bindings in the tree
#----------------------------------------------------------------------
::itcl::body chellyGUI::bindx1 { W x y } {
 
    $this setSelection $W $x $y
    $this setCurrent $W $x $y
    displayFilename
}

::itcl::body chellyGUI::setSelection { W x y } {
   
    set lbl [Tree::labelat $W $x $y ]
    if { $lbl == "" } { return }
    Tree::setselection $W $lbl
    if { $lbl == "/Data" } { return }
    set nodeID [GetIDFromSelection]
    if { [$RealTree get $nodeID type] == "Image" } {
	set inputImg [$RealTree get $nodeID pxitclobj]
	$imageutility SetInput $inputImg
    }
} 

::itcl::body chellyGUI::displayFilename {} {   
    
    $descriptionbox configure -state normal
    $descriptionbox delete 1.0 end
    
    ############################
    #Freely defined Item Selection Binding Definitions Go Here
    if {[Tree::getselectionpath $vistree] != "{}"} {
	if {[Tree::getselection $vistree] != [$RealTree rootname]} {
	    if {[IsNodeImage [GetIDFromSelection] -1 1] | [IsNodeSurface [GetIDFromSelection]]} {		
		$statusLabel config -text "Filename: [$RealTree get [GetIDFromSelection] FileName]"
		
		#$statusLabel config -text "Type: [$RealTree get [GetIDFromSelection] type] \n Filename: [$RealTree get [GetIDFromSelection] FileName] \n Transformation TO Parent: [$RealTree get [GetIDFromSelection] TransToParFileName] \n Transformation FROM Parent[$RealTree get [GetIDFromSelection] TransFromParFileName]"
		
		#Debugging reporters:
		set a1  "Image: [[$RealTree get [GetIDFromSelection] pxitclobj] GetDescription]"
		set a1  "$a1\nFromPar:[[$RealTree get [GetIDFromSelection] pxitclTransFromParent] GetDescription]"
		set a1  "$a1\nToPar:[[$RealTree get [GetIDFromSelection] pxitclTransToParent] GetDescription]"
		
	    } else {set a1 "[$RealTree get [GetIDFromSelection] title]"
		$statusLabel config -text $a1
	    }
	} else {set a1 "Datatree: [$RealTree rootname]"
	    $statusLabel config -text $a1
	}
	
	$descriptionbox insert end $a1 
    } else {
	$descriptionbox insert end "Nothing Selected"
	############################
    }
    
    $descriptionbox configure -state disabled
    
}

::itcl::body chellyGUI::bindxControlX { W K N } {
    

    set selectionPath [ Tree::getselectionpath $W ]
    if { $selectionPath != "{}" } {
	$this mdCopy 1
    }
}

::itcl::body chellyGUI::bindxControlC { W K N } {

    puts "here"
    set selectionPath [ Tree::getselectionpath $W ]
    if { $selectionPath != "{}" } {
	$this mdCopy 0
    }
}

::itcl::body chellyGUI::bindxcontrol1 { W x y } { 
    #Control Clicking on the tree adds multiple selections
    if { $dragAndDropEnabled } { return -1 }
    set lbl [Tree::labelat $W $x $y]
    Tree::addselection $W $lbl
    displayFilename    
}



::itcl::body chellyGUI::bindxmotion1 { W x y } {
    
    if { $dragAndDropEnabled == 0 } { return -1 }

    set widget [ winfo containing [winfo pointerx $W] [winfo pointery $W] ]
#    puts "$widget"
    if { $widget == $IC } { 
	displayMarkerOnImageTab $W $x $y
    } elseif { $widget == $vistree } {
	set selectionPath [ Tree::getselectionpath $W ]
	set currentPath   [ Tree::getCurrentPath $W ]
	$this setCurrent $W $x $y
	$this displayFilename
	if { $currentPath != "{}" && $selectionPath != "{}" } {
	    $W configure -cursor plus
	} else { 
	    $W configure -cursor $theNoCursor
	}
    } else {
	$W configure -cursor $theNoCursor
   }
}

::itcl::body chellyGUI::displayMarkerOnImageTab { W x y } {

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

::itcl::body chellyGUI::setCurrent { W x y } {
 
    set lbl [Tree::labelat $W $x $y]
    Tree::setCurrent $W $lbl
}

::itcl::body chellyGUI::bindxrelease1 { W x y mode } {
    
    if { $dragAndDropEnabled == 0 } { return -1 }
  
    set widget [ winfo containing [winfo pointerx $W] [winfo pointery $W] ]
    
    $vistree configure -cursor ""
    . configure -cursor ""

    if { $widget == $IC } { 
	$this releaseOnImagesTab $x $y 
	return -1
    }

    if { $widget == $vistree && $mode } { 
	$this releaseOnTreeCut $W $x $y  
	return -1
    }
    
    if { $widget == $vistree } { 
	$this releaseOnTreeCopy $W $x $y  
	return -1
    }
}

::itcl::body chellyGUI::releaseOnTreeCut { W x y } {
    
    set selectionPath [ Tree::getselectionpath $W ]
    set currentPath   [ Tree::getCurrentPath $W ]
   
    if { $currentPath == "{}" } { return -2 }
	
    if { [ $this isCurrentAChildOfSelection $currentPath $selectionPath $W ] } { 
	tk_messageBox -type ok -title "Warning" -message "Cannot cut a node to its descendant." -icon question
	Tree::eraseCurrentBox $W 
	return -1
    }

    if { [ $this isCurrentTheParentOfSelection $currentPath $selectionPath $W ] } {
	tk_messageBox -type ok -title "Warning" -message "Unnecessary cut to parent node." -icon question
	Tree::eraseCurrentBox $W 	
	return -1
    }

    if { $selectionPath != $currentPath } {
	
	set ok [ tk_messageBox -type okcancel -title "Warning" -message "Cutting from $selectionPath to $currentPath" -icon question ]
	if { $ok == "ok" } {
	    set lbl [Tree::labelat $W $x $y ]
	    $this mdCopy 1 
	    Tree::setselection $W $lbl
	    $this displayFilename
	    $this mdPaste 
	}
    }
    Tree::eraseCurrentBox $W 
}

::itcl::body chellyGUI::releaseOnTreeCopy { W x y } {

    set selectionPath [ Tree::getselectionpath $W ]
    set currentPath   [ Tree::getCurrentPath $W ]
    
    if { $selectionPath != $currentPath && $currentPath != "{}" && $selectionPath != "{}" } {
	
	set ok [ tk_messageBox -type okcancel -title "Warning" -message "Copying from $selectionPath to $currentPath" -icon question ]
	if { $ok == "ok" } {
	    set lbl [Tree::labelat $W $x $y ]
	    $this mdCopy 0 
	    Tree::setselection $W $lbl
	    $this displayFilename
	    $this mdPaste 
	}
    }
    Tree::eraseCurrentBox $W 
}

::itcl::body chellyGUI::releaseOnImagesTab { x y } {

    set width [ winfo width $vistree ]
    catch {$IC delete box}

    if { $x > [expr 63 + $width] && $x < [expr 203 + $width] && $y > 335 && $y < 448 } {
	$this setSelectionAnatomical $RealTree
    }

    if { $x > [expr 203 + $width] && $x < [expr 343 + $width] && $y > 117 && $y < 220 } {
	$this setSelectionSpace $RealTree
    }
    
    if { $x > [expr 353 + $width] && $x < [expr 493 + $width] && $y > 335 && $y < 448 } {
	$this setSelectionFunctional $RealTree
    }
}

::itcl::body chellyGUI::isCurrentAChildOfSelection { currentPath selectionPath W } {
 
    set selectionPath "[ lindex $selectionPath 0 ]/"
    return [ regexp ^$selectionPath [ lindex $currentPath 0 ] ]
}

::itcl::body chellyGUI::isCurrentTheParentOfSelection { currentPath selectionPath W } {
    
    set tmp "[ lindex $currentPath 0 ]/[ Tree::getselection $W ]"
    return [ regexp ^$tmp [ lindex $selectionPath 0 ] ]
}

::itcl::body chellyGUI::bindxdouble1 { W x y } {
    
    $this setSelection $W $x $y
    if { [ Tree::getselectionpath $W ] != "{}" } { $this NodeInfoDialog }
}

::itcl::body chellyGUI::bindx3 { W x y } {
    #This is a right-click - it should open a flyout menu for the item under the mouse
    #First, change the selection to the item right-clicked on
  
    $this setSelection $W $x $y
    $this displayFilename
    #Now retrieve the ID in the real tree that corresponds to the selection
    set Selection [GetIDFromSelection]
    if {$Selection == ""} {return -1}
    #If the user has clicked on the root, post the rootpopup menu
    #The the selected ID corresponds to a node with key "type" set to "Patient", show patient menu
    #if nothing else, show the regular image node menu

    if {$Selection == [$RealTree rootname]} {
	tk_popup $rootpopup [winfo pointerx $vistree] [winfo pointery $vistree]
    } else {
	if { [$RealTree get $Selection type] == "Patient" } {
	    tk_popup $patientpopup [winfo pointerx $vistree] [winfo pointery $vistree]
	} else {
	    if { [lindex [$RealTree get $Selection type] 0] == "Surface" } { 
		if { [lindex [$RealTree get $Selection type] 1] == "Electrode" } { 
		    tk_popup $electrodepopup [winfo pointerx $vistree] [winfo pointery $vistree]
		} else {
		    tk_popup $surfacepopup [winfo pointerx $vistree] [winfo pointery $vistree]
		}
	    } else {
		tk_popup $popup [winfo pointerx $vistree] [winfo pointery $vistree]
	    }; #end else 3
	}; #end else 2
	
    }; #end else 1
    
    
    
};# End method

::itcl::body chellyGUI::bindRightPaneTest { W x y text } {
    
    puts "x:$x y:$y"
}

::itcl::body chellyGUI::bindxRightPane { W x y menu} {

    tk_popup $menu [winfo pointerx $IC] [winfo pointery $IC] 
};# End method




#-------------------------------------------------------------------------
#These are methods bound to the buttons in the middle pane as well as menu entries in node and popup
#-------------------------------------------------------------------------

::itcl::body chellyGUI::NodeInfoDialog { } {

   
    set node [ GetIDFromSelection ]
    if {$node != "" && $node != [$RealTree rootname] } {
	
	update idletasks
	
	if {$NodeInfoDialogName == -1 | ![winfo exists $NodeInfoDialogName]} {
	    
	    set nodeDialogBGColor "Light Cyan"
	    set NodeInfoDialogName .[ pxvtable::vnewobj ]
	    toplevel $NodeInfoDialogName -bg $nodeDialogBGColor
	    wm title $NodeInfoDialogName "Info for [$RealTree get $node title]"
	    wm geometry $NodeInfoDialogName +300+200
	    
	    set icon [ $RealTree get $node icon  ]
	    set infolabelframe [frame $NodeInfoDialogName.labelfr -bg $nodeDialogBGColor]
	    set infolabeltext [label $infolabelframe.labeltxt -text "[$RealTree get $node title]" -bg $nodeDialogBGColor]
	    $infolabeltext config -font -*-times-bold-r-normal-*-18-*-*-*-*-*-iso8859-1
	    set infolabelpicture [label $infolabelframe.labelpict -image $icon -bg $nodeDialogBGColor]
	    pack $infolabelpicture -side left -padx [list 4 0]
	    pack $infolabeltext -side left -padx [list 0 4]
	    
	    set NodeInfoTopFrame [labelframe $NodeInfoDialogName.topframe -bg $nodeDialogBGColor -labelwidget $infolabelframe]
	    pack $NodeInfoTopFrame -side top -ipadx 3 -ipady 7 -padx 10 -pady [list 2 10] -expand true -fill both

	    set entrylist ""
	    #------------------------------------------------------------
	    # Here are all the attributes for the node
	    set fields [list type group FileName TransFromParFileName TransToParFileName]
	    set nodeinfoitemlist $fields
	    set titles [list Type Group Filename  {Transformation from Parent} {Transformation to Parent}]
	    set functions [list -1 -1 setSelectedFileName setTransFromParent setTransToParent]
	    foreach item $fields {
		if {[llength $item] > 0} {
		    set itemframe [frame $NodeInfoTopFrame.[pxvtable::vnewobj] -background $nodeDialogBGColor]
		    set name [lindex $titles [lsearch -exact $fields $item]]
		    set val [$RealTree get $node $item]
		    set entry [ iwidgets::entryfield $itemframe.\#auto -background "$nodeDialogBGColor" -width 75]
		    pack $entry -fill both -padx {10 0} -side left -expand true
		    $entry configure -labeltext $name
		    $entry insert 0 $val
		    lappend entrylist $entry
		    if {[lindex $functions [lsearch -exact $fields $item]] != -1} {
			set button [eval "button $itemframe.[pxvtable::vnewobj] -text ... -command { $this updateNodeDialogField $entry [lindex $functions [lsearch -exact $fields $item]] $node $item; } -background white -width 1"]
			pack $button -side left -padx {0 10}

			set func [lindex $functions [lsearch -exact $fields $item]]

			# XP -- Potential Addition
			#
			if { $func == "setTransFromParent" || $func == "setTransToParent" } {
			    if { $func == "setTransFromParent" } {
				set newfunct "clearTransFromParent"
			    } else {
				set newfunct "clearTransToParent"
			    }
			    
			    set but "button $itemframe.[pxvtable::vnewobj] -text \"Clear\" -command { $this updateNodeDialogField $entry $newfunct $node $item; } -background white -width 2"
			    set button2 [ eval $but ]
			    pack forget $button
			    pack $button -side left -padx {0 2}		    
			    pack $button2 -side left -padx {0 10}
			    
			}
					
		    } else {
			pack $entry -fill both -padx {10 42} -side left -expand true
		    }
		    
		    
		    
		    pack $itemframe -side top -anchor w -expand true -fill x
		    
		}
	    }
	    eval "iwidgets::Labeledwidget::alignlabels $entrylist"

	    #This frame holds the bottom stuff: notes, and properties for subjects, if they are set
	    #---------------------------------------------------------------------------------------
	    set infobottomframe [frame $NodeInfoTopFrame.bottomsection -background "$nodeDialogBGColor"]; pack $infobottomframe -side top -expand 1 -fill both


	    #The notes box
	    #------------------------------------------------------------
	    set notelabel [label $infobottomframe.notelabel -text "Notes" -background "$nodeDialogBGColor"] ; pack $notelabel -side left
	    set notebox [ iwidgets::scrolledtext $infobottomframe.\#auto -wrap none \
			      -vscrollmode static -hscrollmode static \
			      -width 5i -height 2i ]
	    pack $notebox -fill x -padx 10 -pady 10 -expand true -fill both -side left
	    $notebox insert 1.0 [$RealTree get $node notes]
	 	    
	    eval "wm protocol $NodeInfoDialogName WM_DELETE_WINDOW { wm withdraw $NodeInfoDialogName ; $this updateNodeNotes $RealTree $node \[$notebox get 1.0 end\] $NodeInfoDialogName}"

	    #The extras property fields for patient nodes
	    if {[$RealTree get $node type] == "Patient"} {
		set propertyframe [frame $infobottomframe.right -background $nodeDialogBGColor -width 40]
		pack $propertyframe -side left -pady 5
		
		array set propArray [$RealTree get $node Properties] 

		set entrylist ""
		for {set p 0} {$p < [llength $PatientProperties]} {incr p}  {
		    
		    set itemframe [frame $propertyframe.[pxvtable::vnewobj] -background $nodeDialogBGColor]

		    set name [lindex $PatientProperties $p]
	
		    if {[lsearch -exact [array names propArray] $name] != -1} {
			set val $propArray($name)
		    } else {set val "-"}

		    set entry [ iwidgets::entryfield $itemframe.\#auto -background "$nodeDialogBGColor" -width 15]
		    pack $itemframe -side top
		    pack $entry -fill both -padx {0 0} -side left
		    $entry configure -labeltext "$name"
		    $entry insert 0 $val
		    lappend entrylist $entry
		    set button [eval "button $itemframe.[pxvtable::vnewobj] -text > -command { $this setPatientProperty \"$name\" $entry }" ]
		    pack $button -side left -padx {0 10}
		}
		eval "iwidgets::Labeledwidget::alignlabels $entrylist"
	    }

	} else {
	    
	    #--------------------------------------------------------------------------------
	    #--------------------------------------------------------------------------------
	    #--------------------------------------------------------------------------------
	    #--------------------------------------------------------------------------------
	    #--------------------------------------------------------------------------------

	    #If the dialog already exists change all the fields and then show it
	    
	    wm title $NodeInfoDialogName "Info for [$RealTree get $node title]"
	    set icon [ $RealTree get $node icon  ]
	    set infolabeltext $NodeInfoDialogName.labelfr.labeltxt  
	    $infolabeltext config -text "[$RealTree get $node title]"
	    set infolabelpicture $NodeInfoDialogName.labelfr.labelpict
	    $infolabelpicture config -image $icon
	    
	    destroy $NodeInfoDialogName.topframe
	    
	    set NodeInfoTopFrame [labelframe $NodeInfoDialogName.topframe -bg $nodeDialogBGColor -labelwidget $NodeInfoDialogName.labelfr]
	    pack $NodeInfoTopFrame -side top -ipadx 3 -ipady 7 -padx 10 -pady [list 2 10] -expand true -fill both
	    
	    set entrylist ""
	    #------------------------------------------------------------
	    # Here are all the attributes for the node
	    set fields [list type group FileName TransFromParFileName TransToParFileName]
	    set nodeinfoitemlist $fields
	    set titles [list Type Group Filename  {Transformation from Parent} {Transformation to Parent}]
	    set functions [list -1 -1 setSelectedFileName setTransFromParent setTransToParent]
	    foreach item $fields {
		if {[llength $item] > 0} {
		    set itemframe [frame $NodeInfoTopFrame.[pxvtable::vnewobj] -background $nodeDialogBGColor]
		    set name [lindex $titles [lsearch -exact $fields $item]]
		    set val [$RealTree get $node $item]
		    set entry [ iwidgets::entryfield $itemframe.\#auto -background "$nodeDialogBGColor" -width 75]
		    pack $entry -fill both -padx {10 0} -side left -expand true
		    $entry configure -labeltext $name
		    $entry insert 0 $val
		    lappend entrylist $entry
		    if {[lindex $functions [lsearch -exact $fields $item]] != -1} {
			set button [eval "button $itemframe.[pxvtable::vnewobj] -text ... -command { $this updateNodeDialogField $entry [lindex $functions [lsearch -exact $fields $item]] $node $item; } -background white -width 1"]
			pack $button -side left -padx {0 10}
		    } else {
			pack $entry -fill both -padx {10 42} -side left -expand true
		    }
		    
		    
		    
		    pack $itemframe -side top -anchor w -expand true -fill x
		    
		}
	    }
	    eval "iwidgets::Labeledwidget::alignlabels $entrylist"
	    
	    #This frame holds the bottom stuff: notes, and properties for subjects, if they are set
	    #---------------------------------------------------------------------------------------
	    set infobottomframe [frame $NodeInfoTopFrame.bottomsection -background "$nodeDialogBGColor"]; pack $infobottomframe -side top -expand 1 -fill both
	    
	    
	    #The notes box
	    #------------------------------------------------------------
	    set notelabel [label $infobottomframe.notelabel -text "Notes" -background "$nodeDialogBGColor"] ; pack $notelabel -side left
	    set notebox [ iwidgets::scrolledtext $infobottomframe.\#auto -wrap none \
			      -vscrollmode static -hscrollmode static \
			      -width 5i -height 2i ]
	    pack $notebox -fill x -padx 10 -pady 10 -expand true -fill both -side left
	    $notebox insert 1.0 [$RealTree get $node notes]
	    
	    eval "wm protocol $NodeInfoDialogName WM_DELETE_WINDOW { wm withdraw $NodeInfoDialogName ; $this updateNodeNotes $RealTree $node \[$notebox get 1.0 end\] $NodeInfoDialogName}"
	    
	    #The extras property fields for patient nodes
	    if {[$RealTree get $node type] == "Patient"} {
		set propertyframe [frame $infobottomframe.right -background $nodeDialogBGColor -width 40]
		pack $propertyframe -side left -pady 5
		
		array set propArray [$RealTree get $node Properties] 
		
		set entrylist ""
		for {set p 0} {$p < [llength $PatientProperties]} {incr p}  {
		    
		    set itemframe [frame $propertyframe.[pxvtable::vnewobj] -background $nodeDialogBGColor]
		    
		    set name [lindex $PatientProperties $p]
		    
		    if {[lsearch -exact [array names propArray] $name] != -1} {
			set val $propArray($name)
		    } else {set val "-"}
		    
		    set entry [ iwidgets::entryfield $itemframe.\#auto -background "$nodeDialogBGColor" -width 15]
		    pack $itemframe -side top
		    pack $entry -fill both -padx {0 0} -side left
		    $entry configure -labeltext "$name"
		    $entry insert 0 $val
		    lappend entrylist $entry
		    set button [eval "button $itemframe.[pxvtable::vnewobj] -text > -command { $this setPatientProperty \"$name\" $entry }" ]
		    pack $button -side left -padx {0 10}
		}
		eval "iwidgets::Labeledwidget::alignlabels $entrylist"
	    }
	    
	    switch -- [wm state $NodeInfoDialogName] {
		normal {
		    raise $NodeInfoDialogName
		}
		withdrawn -
		iconic {
		    wm deiconify $NodeInfoDialogName
		}
	    }
	    return 0

	    #--------------------------------------------------------------------------------
	    #--------------------------------------------------------------------------------
	    #--------------------------------------------------------------------------------
	    #--------------------------------------------------------------------------------
	    
	}; #End else if dialog already exists

	
	
    };# end "if node != 0"
}

::itcl::body chellyGUI::updateNodeDialogField { entry function node item } {
    
    $function

    $entry clear
    $entry insert 0 [$RealTree get $node $item]
    set TreeChanged 1
    
    updateAllNodeDialogFields $entrylist $node $nodeinfoitemlist


}

::itcl::body chellyGUI::updateAllNodeDialogFields {entries node items} {

    for {set en 0} {$en < [llength $entries]} {incr en} {

	[lindex $entries $en] clear
	[lindex $entries $en] insert 0 [$RealTree get $node [lindex $items $en]]
    }

}

::itcl::body chellyGUI::updateNodeNotes { realtreename node text dialogname } {
    
    $realtreename set $node notes [string trimright $text \n]
    destroy $dialogname
    set TreeChanged 1
    
}

::itcl::body chellyGUI::setPatientProperty { property entryfield } {

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

::itcl::body chellyGUI::setSelectionSpace { realtreename } {

    if { $SpaceLocked == 0 | $SpaceImage == -1} {
	#get the currently selected node
	set node [GetIDFromSelection]
	puts "Space Node: $node"
	if {$node != ""} {
	    
	    EnsureFileLoaded $node
	    set SpaceImage $node

	    updateRightCanvasDisplay
	    
	    if { $SurgeryMode == 1 } { set SpaceLocked 1 } 


	} else { error "Please select an item to set as the Space" }
    } else { error "The Space Image has been Locked (see Options Menu)" }
}


::itcl::body chellyGUI::setSelectionAnatomical { realtreename } {
    
    #get the currently selected node
    set node [GetIDFromSelection]
    puts "Anatomical Node: $node"
    if {$node != ""} {
	
	EnsureFileLoaded $node
	set AnatomicalImage $node

	updateRightCanvasDisplay
	
    } else { 
	error "Please select an item to set as the Anatomical Image" 
    }
    
}



::itcl::body chellyGUI::setSelectionFunctional { realtreename } {
    
    #get the currently selected node
    set node [GetIDFromSelection]
    puts "Functional Node: $node"
    if {$node != ""} {
	
	EnsureFileLoaded $node
	set FunctionalImage $node

	updateRightCanvasDisplay
	
	
    } else { 
	error "Please select an item to set as the Functional Image"
    }
    
}

::itcl::body chellyGUI::updateOverlayCanvas { } {
    
    #--------------------------------------------------------------------------------
    #Update the display in the overlay tab canvas
    #
    #Show image titles that have been resliced

    catch {$OCanv delete presPIC}
    #Check to see if reslicer outputs have been sent to surgery gadget
    if {[$surgerygadget cget -overlayinputbase] != -1 && [$surgerygadget cget -overlayinputfunc] != -1} {
	set OC_reslice_presentPIC [$OCanv create image $OCdispX $OCdispY -image multicolorbrain -anchor nw -tag presPIC]
    } 
    
    #Space Label
    $OCanv delete ocSPACE
    if {$SpaceImage != -1} {
	set OC_SPACE  [$OCanv create text [expr $OCdispX+220] [expr $OCdispY+60] -text "SPACE: [$RealTree get $SpaceImage title]" -fill "darkgreen" -font {helvetica 11 bold} -tag ocSPACE -width 145]
    } else {
	set OC_SPACE  [$OCanv create text [expr $OCdispX+205] [expr $OCdispY+60] -text "Space" \
			   -fill grey61 -font {helvetica 15 bold} -tag ocSPACE]
    }
    
    #Func Label (Change if FunctionalImage has been set)
    $OCanv delete ocFUNC
    if {$FunctionalImage != -1} {
	set OC_FUNC  [$OCanv create text [expr $OCdispX+315] [expr $OCdispY+20] -text "FUNCTIONAL: [$RealTree get $FunctionalImage title]" -fill "darkgreen" -font {helvetica 11 bold} -tag ocFUNC -width 150 -justify left -anchor w]
    } else { 
	set OC_FUNC  [$OCanv create text [expr $OCdispX+375] [expr $OCdispY+20] -text "Functional" \
			  -fill grey61 -font {helvetica 15 bold} -tag ocFUNC]
    }
    
    #Anat Label (Change if AnatomicalImage has been set)
    $OCanv delete ocANAT
    if {$AnatomicalImage != -1} {
	set OC_ANAT  [$OCanv create text [expr $OCdispX+315] [expr $OCdispY+110] -text "ANATOMICAL: [$RealTree get $AnatomicalImage title]" -fill "darkgreen" -font {helvetica 11 bold} -tag ocANAT -width 150 -justify left -anchor w]
    } else { 
	set OC_ANAT  [$OCanv create text [expr $OCdispX+375] [expr $OCdispY+110] -text "Anatomical" \
			  -fill grey61 -font {helvetica 15 bold} -tag ocANAT]
    }

    #--------------------------------------------------------------------------------
        
    
}

::itcl::body chellyGUI::Reslice { } {
    
    
#     puts "SpaceImage: $SpaceImage"
#     puts "AnatomicalImage: $AnatomicalImage"
#     puts "FunctionalImage: $FunctionalImage"
    
    if {$SpaceImage != -1} {

	set FuncOnly [expr ($AnatomicalImage == -1) && ($FunctionalImage != -1)]
	set AnatOnly [expr ($FunctionalImage == -1) && ($AnatomicalImage != -1)]
	set SpaceEqAnat [expr $SpaceImage == $AnatomicalImage]
	set SpaceEqFunc [expr $SpaceImage == $FunctionalImage]

	set ResliceFuncOnly [expr ($FunctionalImage != -1) && ($FuncOnly | $SpaceEqAnat)]
	set ResliceAnatOnly [expr ($AnatomicalImage != -1) && ($AnatOnly | $SpaceEqFunc)]
	
	if {$ResliceFuncOnly} {

	    #This runs if: 
	    # SpaceImage == Anatomical Image
	    # or
	    # Anatomical has not been set, but Functional Has
	    
	    set SpaceImgObj [$RealTree get $SpaceImage pxitclobj]
	    set FunctionalImgObj [$RealTree get $FunctionalImage pxitclobj] 
	    
	    findTransforms $RealTree $SpaceImage $FunctionalImage
	    set TransList $TransformsCache($myname,$SpaceImage:$FunctionalImage)
	    
	    set resliced_image [ ResliceImage $SpaceImgObj $FunctionalImgObj $TransList ]
#	    puts "Resliced $FunctionalImage into $SpaceImage with $TransList"
	    
	    $surgerygadget SetOverlayToolInputs  $SpaceImgObj  $resliced_image
	    catch { itcl::delete object $resliced_image  }
	    
	    updateOverlayCanvas	

	    return
	    
	} else {
	    if {$ResliceAnatOnly} {

		set SpaceImgObj [$RealTree get $SpaceImage pxitclobj]
		set AnatomicalImgObj [$RealTree get $AnatomicalImage pxitclobj] 
		
		findTransforms $RealTree $SpaceImage $AnatomicalImage
		set TransList $TransformsCache($myname,$SpaceImage:$AnatomicalImage)
		
		set resliced_image [ ResliceImage $SpaceImgObj $AnatomicalImgObj $TransList ]
		#		puts "Resliced $AnatomicalImage into $SpaceImage with $TransList"
		$surgerygadget SetOverlayToolInputs $SpaceImgObj $resliced_image
		catch { itcl::delete object $resliced_image  }

		updateOverlayCanvas

	    } else {
	
		set SpaceImgObj [$RealTree get $SpaceImage pxitclobj]
		set AnatomicalImgObj [$RealTree get $AnatomicalImage pxitclobj] 
		set FunctionalImgObj [$RealTree get $FunctionalImage pxitclobj] 

		findTransforms $RealTree $SpaceImage $AnatomicalImage
		set TransListA $TransformsCache($myname,$SpaceImage:$AnatomicalImage)
		set resliced_imageA [ ResliceImage $SpaceImgObj $AnatomicalImgObj $TransListA ]
		puts "Resliced $AnatomicalImage into $SpaceImage with $TransListA"
		
		findTransforms $RealTree $SpaceImage $FunctionalImage
		set TransListF $TransformsCache($myname,$SpaceImage:$FunctionalImage)
		set resliced_imageF [ ResliceImage $SpaceImgObj $FunctionalImgObj $TransListF ]
		puts "Resliced $FunctionalImage into $SpaceImage with $TransListF"
		
		$surgerygadget SetOverlayToolInputs $resliced_imageA $resliced_imageF
		
		catch { itcl::delete object $resliced_imageA; itcl::delete object $resliced_imageF } 

		updateOverlayCanvas
		
	    }
	}
    } else {error "The Space Image has not been set"}	   
    
    
}


::itcl::body chellyGUI::ShowTextBox { parent } {
    
    
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

::itcl::body chellyGUI::showGrabButtonDialog { } {
    
    if {$showGrabButtonDialogName == -1 | ![winfo exists $showGrabButtonDialogName]} {
	
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
	
	return 1
	
    } else {
	
	switch -- [wm state $showGrabButtonDialogName] {
	    normal {
		raise $showGrabButtonDialogName
	    }
	    withdrawn -
	    iconic {
		wm deiconify $showGrabButtonDialogName
	    }
	}
	return 0
	
    }
    
};# End showGrabButtonDialog method


::itcl::body chellyGUI::ShowMidpaneTools { parent } {
    
    
    image create photo smallviewericon -data {
	R0lGODlhHgAaAOf/AAABAAIABQACAAYAAAcAAAABDgEEAAIFAQUHAwYGEgcJ\
	    BQgLBw8JBwsNCgwPCxcLCxIUERUSHw8WHBUWHRYYFRYXHhcYFhkbGBocGRwd\
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
	    ItS3r2O+fBw7Nsy3DyTDkvtGlmyIUmVKhhpjypypkZ8+kx1fgkwJ0iRDnzeD\
	    jnTYkyXHhjSTKqXJb+fLiE1X2kRpMyrIqSSrkjzqMOfEpWDDIrT5kyE/kURT\
	    Pj26ti3Xsi/RjuQnti5Yjh8hily5U6hNn27yefO0AlC9w/XykQ267+9JoTxt\
	    2p2cUe3TtlsZLkK8DQ4cfXCk1Xt3pky1aZ4EBRoDqLC+epIUK3a4+DFEyrgP\
	    Xj4b8qZaON38jMGSqZAfLJuS5Srz7l2ZRJWmeSM3LZkgQ6snRaoT7l0/XnCA\
	    /tpmrFef5Nx11771rc/cO2Kt6MQZU+RLISyH7n8pUwbdummkRGKIINeFEoo5\
	    /p3xiCzlrBPOg+KUw1ZQsxm1U19foaeUSl0tlo8r2BATCx1elBiHcWcUEscV\
	    m0yzDiqkDPjFGTSeAYghY/iDjjN1yCLPg0CKM5tlOKnHUkoa0sSVWkuaJMk1\
	    ULoi5YgkehHHOlh8MQ0hltBYxZdfTgImOv6YEwUhvwyBzINrAhmOJBPSRpJ4\
	    vSWp0UNA+QQHL7HE0kormmiyCi1+ktiDF190Q8gZY1BRRSjorDbGGGKOEQg6\
	    2wSwTi/dSINOj7LIsmY77ZRTjjRGytXSY3TZWdF6/ksGxcs744zDyq103CGH\
	    Jn/G54UTZ3whyBlVjPHopZIGEgggVazjRgBRoGPONujEEAOoyGSLTDngaFOP\
	    NuZ8NCRetanVqqsIqYdhSXD0GQsrdCiiSCqKNNLIG280cscdmqDjwxiMAgxI\
	    HDca0o0hZyB8iI04RuNLFOts88ILMFxbR7biiKONNmDIIMTHQph01VteZYju\
	    QEId1Vc+9cybCh10pKIJvffii28W+MoRXw5xfLnNso544smABALiiCNnKOtJ\
	    MJ5sM8QQMUx8rajiyNKxDGB88gkuWYNijso+fbTWyQJBZpZ5DL1DRyNsrNNI\
	    Kqk0Uu+9UryhhBJvPJHF/hxpeCGFsZYmTKAgjkQSyXVIB/Ll0p7UYQ7UMFQc\
	    AyywIKONx1CAAYYZZqBhRtaSpDQVkzf5dPJ4an1UTzOL+OEF3OvAjo4SWeAs\
	    Be21P0EGvzwU0TMgNBKIcCFHI90zwYIQIggseDwO9QtTyyIDFFD8YAYQuNhh\
	    By7UC8HLSEWF9BK6Rt3ET1P62KFMMJJcEYsfrazjT8TrvJGFEut8kEIKuus+\
	    Bx1ssFIRzuAITAzOEXGIAwEPYQhMoUMQofAEHoYwwSFU7AV1gAUaoPAJKHSj\
	    G7hwBS9sgQvumcIMbbBFN1J3Np2cKzdGks0+4LCLd1DDFbQwh5/8s4511M1u\
	    /kq4XRb0pjs50ME/VfAPOgzxhdQIYkZGa2AP0fHAQVCwG0+zFgzqUAwcZM0M\
	    XDDDM1rxDGZojYNRCEMwVjAnx9wmN7wxWz76oQ9pvCMY1NBFN9aBoHXEAgvd\
	    QEfdnhDEupmjTOiIFoKioAYqHsIRWvhCJg4HwaFFAQBREAQqilEHPDCvWlHD\
	    IBqwhg4gbIMTxnCFLTgBCVBAwg6XsIUdgqEMXXTFNiDBTfma0hSSSMIWNtTF\
	    LYCxi13wwhVqmIIcpFC3+zHzHfhqAxsUwQYWUMEcACgEJShxhCfk4AiWEJo4\
	    3eEJQsiiDp3EwwTXgQ4YQK8OnMAaLoCAgjww4xmx/shENILBCXRAwha22Kcu\
	    dpGYChXJZGHhDZHElbZgRAMdxQQGMXmhBmJsYZl4ywI6WOBDKZhjDrqSAhVy\
	    4LtCFAIASUgCFrAQCU+EghDuGAQ6snFOTzIvYm3wzwtwMAQcyGBrQDBBGJlh\
	    i18ag4qSkEQ01rcLicJJVSepy08w1BCyuOEZwniHOW7xjjzM4ha62EYntsCG\
	    Zmo0BehIwTtyIIUkpCAJOXCCXJ2QBCUkQQwvuEAbCFENWVBOGqGCBTpz6s7I\
	    Vcw/5pie5rhAAhXAARfMEMYupMUMYwgDGMK4xTrycAs4lKwv+wgLeXjSmMbk\
	    ozn1UEUe8sCFHkriq7qQ/sQ6ptCI2+0vb90wRwpYkISIbSOlSiBkcHngzm5E\
	    4RFlKAaCAlSGMMCAihSL7ueoZ44ergMMQCBBCHSgAi6s9hbCqIVqucCFLXRm\
	    Fru4RflWglCZ4Al8+TAHCcjLBa2SAAUQM4cuZoGNTmzjCuZgZhaaQIY5aPQJ\
	    T9htImenBP/UzQvdWEEA7FAJVPwBQX/YwQ5ekAt/yODD08vch6FARTdQEQ0g\
	    KEEHeNABHdC3CyTgow5W8Y5F6EIX9SiL2TakrvM1pR436EEPtuCPRUhCDWqQ\
	    BDpkywtJbGEKPWBDbZWwPyMYIQo2w9kb1tEGdkbBDWYKQBsoVolLoIMDF7gA\
	    /gfWvGYQ48CnIJYBBzRgAxlQEQw/0O4Ngiy/TixCDa5AUFJ5UaZ3cMghScHL\
	    hEjinhKE4AFB4EEP0LGIEX5wHZJ4BTpG0AMAltW2TQh1N5qAhFIjgdRtCAAD\
	    AgAACWzgDzBoQ6i6sQfxquLWtQACDTaw5ii0mQMe44AQNAAFUEQhWuw0UyJ7\
	    0IJO+MIcAbCFLnjhniazJ2XtvQhErgIS75SABCR4wB2kkI4pbEHJ5ljEK7Zw\
	    BCGz4R1sYIM5WFBlIpijG6bONwMAsOpAXiIMlCgHJ4CwjlcY/OCvgMOuNxCF\
	    DWzgBT9Y87BpIANQaOPYUQiAmI/NzClIohPo0MWf/qeAjndEYS8nQUtMfCMb\
	    xfCGF3imAQlAUAEI8EAJ6ZDCpLHQAx74AB1eiHcPq0vF/TWBikhYgtKXjk0G\
	    vGMb69iEJYqRiB28QhSSEIXWRRGLVaziFaPohgEywIEMbCADw9aABoQAClC8\
	    Awe6JsE2Mn67J0jaH0d4h7984IV38GIquMy2QkSSmV6SBAzVo4E5aE4ACLDh\
	    blLgAQ+k0DY5WJ4NmMrBRu/2BCQYwRxEULoVllBqdDBAAj3cRiAzvANVvMIc\
	    H8/FJvrUilXwcQ9jN/sG1M77YncwDzQAAQjMJPlCrqMGUqhBDT4t79qYxySV\
	    cbnhmwIHX0AhHT9QvPAn/lCAdHTgBh2VgiCl0I0crCMH6OdBDuqaAiIQAQnm\
	    ULqplZ5xdDwBCHtYxwrgMAtVwEHJavAKlFAIrbAGibQKo7AHDeBwO2ADGoAO\
	    CqAB6wAF5iAEurZ4IMB9CdABNSAHhfRpNcAD71ADD4FyL5QQZ4EW0wcH6WAD\
	    NkADGpABJbAAC+AAEAABCWAB3tcBGJAAGNCDHcBOPOABPsBWKWAE7ocEAXBq\
	    ezMHStcNXZZIozAK4vV/cKAGUbBNmcAvawAA64CAtdAADZBmG4AOBwAxNpBI\
	    MCiD6NANExABDlAAD5AA6PCD6MCDGHCH6/A9RhEXFoEhH3E+L3EAGaB4NMAP\
	    /jMoDRRwgxagg93QiBZwgw/wABCgAx2QAzxwfu1HBKQWAPUwB3NABm+QdOkQ\
	    BTnlBlywB3lwZFJCCZkQC7yyBmvAR+9AhXnQHGlGJspmDmaiABlgDiVARRTg\
	    ABGQABBQADeIjN0AAZNYiTfAh0YieAOhFS2XEtLQQwZgAAqwjQaAAN0wjDbY\
	    DQ6wDiYwW1MwBebQAwmwgT1QA5iYAynABFbABEsQLfVCBmQQekiASW24A2Zw\
	    TICiCEywDnfABGuQBugQAFN4ChlwASbnBqnGauawAAfgHumgAQqwABTATtUQ\
	    hxMwAS7gAlMQMXe4ji2WDjl2bVE1eKLDS03RDeng/g4DMAACIAA02A0IoJES\
	    YIMqsAXpwE5fEJRahQWPZgE3gA48gA5GwARE4ITmADdzQGpLsA5NkHHR8gJA\
	    IAl3MAdrcAfvkAYHiQjmkFPi1QAIUIb8xgDmQAACcG8CADHpsADbWAEncGzb\
	    oCMq4AKJImZtOAId8AAr0AI5RifmkRA4EYhzYg7pkA81WQ81iZIIgACLsJMQ\
	    0JPpYA4zgjDNgQV/aXM94AFSwARMgA5MYHJ+cAZKQAal1gRZYIpqYA4vYAet\
	    kAZ3IIvmkAaIsAqIkHHmAARiuAEXAG0AcJfoIAAEQAAJaQ5tKZcVQAEbRyaq\
	    dwYrEAUroHfd0AFuYAIW/vAO6SAUIgMTByEn7FIP6XCcBZAYx0kC9RCZFCAB\
	    EQABW6AF5nAG7hAsX7ANM9IDbQAAHdBzNaAjpYkOS8AK68AGb4CPoght22AO\
	    OwAHtYkIEIoOC1kL5hBxF7CACMAApscA6zCTA0AABcBI82OTGWlyvDh3/tFl\
	    YFIE6NAGGLAI1FkPX0Me0GcQpaMYJWET6ZAOA7ACDqCD9TABKBACE0AB3VAB\
	    M3CDO0oj6HAGWKAFkeQIGRcAcNACHNgERFADTGkF6+CKXiAHbzAHUrAOATAA\
	    6LAFmrAGjKAH27AH3VALpTBMHCCGGUCDNDmTUeAPH1oAyOgPlGhdvLgO3RAB\
	    /hHgAkVQBG1QBYc6AkUgDYzqAfe2J4dJFO3lFvsgDTy6p0oqpCFAAhXQAAuQ\
	    pBCwo8BzBkVwBJ3yBYtQptAyAjxQA+4Hq/LIBPcWB+bABn3ACicVAObQCrW5\
	    poxQC6dQC8MEBQdwAGaJADUpAN0QACZGk8hoAeYwiQ/AizYZBQ7gABOADkUw\
	    Bt1QBEWYA9LwJSPwARBgAZUmDZ8xHhxREM+3E1MxAAjAo4NKiRAwARAgAiRA\
	    ASWgADbYBgxwIwPjA8rnBc8CLanWAjUgqAMZBOZQD/MYC37WZYuQKQGADrKo\
	    pnqgB6dQCvkgUcZwAGOXjbzQjQMALQjgAASQANTa/kPUSgBR4A4eOQJf0oYe\
	    wAK5sA39QCMfgAE60ANqdVotsRgFcT5hkw8NEAAIMAB8CgEhYAE2eK/7mg8p\
	    CwEmcAbpcAaL0AkMwACSFwXSEEjQFgUegA5EwARBcAMDWQ9LMJqJtALBCQAX\
	    awWMULd6QIWlUA/CIAwhqwDZaADSMIbQhg4pi4yTyLIEsJYkIADroADbEAEm\
	    QLOH6gEe8AFRsA2NWgSKmQ49wALvUA98qBcEYT49kQ+80AA7yrSSaAETkA/p\
	    MHMQ4AvLCAEtEAc72g+L0LU1YKv1cAR1SKZuwAKkGQRdEAT0aAVuAHWB5AoW\
	    2w11ywgTegvpwLfPcADb/ogOBjCGFyANbRCZ3WC4c5i41ioABoAOxNgCippE\
	    28ACH+AfRcCoH5AOQbajIpBuccQqKDNVHSGGqKu6IRACEbCI+VACJQABBjC7\
	    I+AGO8oP7+ALnbACfvAOhXBE38eLUXC2QRAEaYCQbaCY5sCU79AGEhAAzssI\
	    wypetQAM72AMz6AMHGAO2SiyxxoFDcAAhTuJGPAANAgC6QAC5Pu93cCoRYB+\
	    KfABgcStOfABH9ACN+ADUsACUaADvCAXZTGN06cPnZC9F8AAxggBbnCDNJgB\
	    UaCR6EC7X9YG3vEO0rANvkAHmqAPrWAOW9AC2+AFLAAt/sGbPfQOfOQs+8YA\
	    /lHQDSc8CwM1D2CGDc/QtwvqZdhbw9KQD4vwANiQAAKwjdy4rQUgZkUwUvCY\
	    Av7wdL7AC+mAAT1QhOnwAQWVGTwBnmIzEtuwCAp8AStwgx0AAQ6wDWC8AAhw\
	    g7TrA1/iBp0gDbHwDlegCayQDw/sntLgBaB3sBqXvOnAQy0qAatmYuhQC9h8\
	    C02FDq/QCrzQDQ1gAMeGhVGgAMd6AfzgC5W2jjqckco5AWYit4rqBPC4De/Q\
	    DUqsmB4wAkS4o/UgAlLME2EzEf7QD6TDCzCqAA0QBRFQy7wMAcf50CG5RzQS\
	    C+NAzJ3GMlFQl53gu3dgDmsQBELWBakWBQjiBn/M/gBuAJElpwq1oLfPQEUo\
	    oAi6QHBtgHGLt40HMAAOUGm8wLLGeZyJqwYad7FIvD8Ro8Tr4H0cZwT9AND5\
	    0AOLIBKLEVrcZhJqowlyibrp0AI3GAIMcIMokA5WqwKOKg1OiilusAjucw3p\
	    gNIS4ALx4gvSIA1dcAVX0AIt8A6nd3or7QYjjNPZLAzKcG/oQAs1bSbd4IWx\
	    swoVoAAMEAEWUK05TK3nKi2R6wMYl2zdwAKezQPb0AZYaGUGyblX0AOhyxL/\
	    QLoNwQuaoAiIYM4OsKNWitIhMKRkjQK+4AJ1jdaq981XwAq1wgsnMAMnoAl3\
	    kFvrkNfd0AJXgA4ordJ7/nywjYQpX7UL0WAmtsAL61CRVBTI68Ar5qAA5rsN\
	    0vAAGPC/D9ANQxotKHAFjIpx1rxbLNAN/kBvLLCUQaAD+oDXXcDfOtGupUMW\
	    +9AJXNB1ChAFI8wAJjCkKIACAP3f6aADauxsXxC2nUAJsNgK6uAKf80QW/Bs\
	    sTAFj3wFU9AcO5oI/2ZcU2rS6/AOylByJm0NZVhdpogO0QzdCrAOEkAteyQC\
	    ENANIhAC6yACQ34D/Vkmx9aGvLACSpwP+b2UIrDfU3AFPKcDe4ESq32Y0rAI\
	    W+AGx9aNjWgCOzrhOgAzwY3XJvAOWCAG3eAKlSYGfhLH5kAMr+C6q7DGDSyS\
	    /uugBf4M43z83aYYAFAXDM7QDa1ARXDQQyZ2bLwoLQBAJuhQAEGMDiHQDSGQ\
	    SF5AB0KG5DpQJtCCfofBC5ULB0aQDiIQxVOw0W7QbN0gNqTDJPtQY7RAC6uQ\
	    vRJgASOg1y2QDnidQAm0Dqxw4iYgCmKFZLPCCrFwDW++BdwZC+hQ1/mwDVni\
	    5zsaDdFgC5BwYbxI1Ly6I+6ADiRAdGC2DnU5RQlp3u5pAYHUASHQA1/Gd0fA\
	    6T0Afv7QBjngAyjpbHsWBUxg5lGABVa5CFgwxX0oGwxhR+qmBgsQBRQwASOg\
	    63qdDvJxBPOBBfWABSugAp1wAis9AzMgBgu67JS2/gjnqMbvAKVakPLVdpmL\
	    kAg4ng5aoAbAoXEO1AokcJlu4GXQ8uJ8dLnfGwF+aQ6doANeIC0mwk4+kOn3\
	    Llc5sKP+8LVNDO9RAKX8EElf8D0eIjovYUeoyAViLAEY92W97gZx8GVg3tcq\
	    4Asevw7jIApwLgZiMA7XwAti8AVawB96L587qlWpEAydgAU7LwboYAdwMC2Z\
	    svP+UAJkCgBtAOamCHV8lFPboOsW0AFI5gJHcAQlYiVRUCJBlgPQcmwGewSQ\
	    fwQ7CqX84Q95XwbfAxSyng/SwAsoTQEUQKgd0AE3/fhg/ixYOJ3qutJ1yQuU\
	    EGi+gEzXIArSIAZToPp6/r8OhND3tKAJ1AAJCioGauAGdmAL/rECcotxGuf4\
	    Uzp0ZtIGQt8Bd5j9vGDxXtAHXuAHn+8FPZdIuYUOTnBsctsGR+ACWTIDeq/3\
	    AMFL3759A/UdJHhQWic35qJEGdHBg4cPHqJ48OHlYZw4WKS9e1evU6coIynh\
	    U7NIjShi68S46vauzDZCmGpuS/fHlytXttYFsLPITjdO3datM7ctwNIAbaK0\
	    acO0DTp05px6SIf1w4koko54YePFyTp0YHX4MIduG5V06ZwUORLn4ZczXwQ9\
	    XeEUk698Bw/2RahwkZso2yau8FDjYhQ1N+KkU4PlCkcsU1xcqbdt3The48jy\
	    /rpGyVWnd0a7WSJVExMmVJX+oHuFLoAtZcaMPXuGK+26d+gABACgJm2QtEsL\
	    b3uI80O6GiHbSOvmxKG5Il6oRkFXxAkVPlT8+aPSZ0CUQ4a+RLIEoI1qVAb9\
	    IgRcj9c7N+g+qLHYg3GAiz3SuaGDjo7yuYKVMcbYhpdMjjnGF4ZEySSTRbrJ\
	    ZJhILtwEHdYq6eYPSNRQ4xlqbEFHGWWe4aSq3miJir9HzOEhCyWiaCoKpNxY\
	    J50WrmjBApGkActGL7zooYd1uqHiQHT4KEK77qIAIJBADDFkhQstqamS9wri\
	    0q9tQKrvgyiueCgtNaKowb8oiOSxFSzS8eGITlyQ/gYaaCxxYyQ7peFljHfM\
	    CQSQSMyxpJJBOHQoGDjeoSaYYCCBZB0b13llnW3UM+cRdEYIQo43zuwGHRrd\
	    SAeqNsRo4YMOHmKDjiDQOYIOAJLYxgl0/HnHlxGoSIK7XqngLgopHUGPw78C\
	    e08faRaRNIopHoqCMOSiCCIdubzwoQcvxvDiiCNccAELPwJhxZxMZsiEEmnq\
	    mSSdScyZBBBzHCGFqm5QGWSdR4LhxRwQ1gkGnc+2+OORbeqDpJkppKiBjScc\
	    2i8KSizowAIXom2DDbfM8SEHSbfRzglf3hmhZGL4cIMPPvpQmY9JJnnIEHov\
	    8YvLfPjRB7CPDo5CDDEe/qoqLTTbimIFNqrzw4+OsHAhaT+gKaSQTjLRwg1p\
	    QnH35UlCMSdUdCoB+5FHansFhFZe2aaqVqJ4BAaytoFEGXSkkCKV3iBWr+ge\
	    eODPHIzSSWUsJ/hT8ogJRwApnZal5CcUrV92w5BIMMmncpxrNigfhooD7qlo\
	    zXHDv3T4S7oQSiyhpJ90uxGjEDuhAWmRThgc5h2yaIzCHEG2ac3QQTjBRZgz\
	    2zBqm4KbMWOHP6LA1RwWynLiT6aWCoLGbrCAcZs40PFDVEAyQb0Qfd6ZwYV0\
	    zGFZZWiGYX/9UBx34/1IFkF2IH4S0sfBP7vBDh2n1nFDAHpQg3QwJg7EsoQY\
	    /ii0iGF8gReUsNMKoAG+RUgDgNswhzl+szVBoKM1+Eob6OqTlmLUoRmQ2EHc\
	    lJEWh6yDbmzoAwYDwAAJBKAhMDpCLLrhA3RcwSkIfMchAJGPL1ipEOkYQx/Q\
	    MYljVKMtmMgFKY4xDMeFQhDdAAxC9gGYgjCrE+jAkajQ8SdzBIAHPIiDG+JS\
	    CPRooRvdKEQUviCNSBzDdcNY30MaUg1MbGIbU/lSJHonMMLUJx3ogEQxOgQE\
	    sqAjGI2sD1WkYI4pSGopDaEKVbDAA3QUsBtxOIQlLAEIxtGIfY44kMui0Bo3\
	    9AIVucjFMULhhkUIJDD7uFyyRvaONuDIUjgxhxra/lCkK/TgC+mIRCbqMoNu\
	    OCIKoQDEMAABjXRA4xh/+EMlVlONXGRCKesIhSX0sQ0M/uIRv1hGOpQRsE4s\
	    QhLm0IWjqLEz3myDDVJYxxaEMwAb+oMOAltHD2STOyx8IROOABQ4o8LPpUDl\
	    ZW3phTYfsolIDEMQoVhEl/BXEPeMEyTmOEoG2yKqKBwBC1EgBSkyEYhhOAI6\
	    24DG+/DoiH2kw3bv2MSfSLEORxiiDQygZdrQ8YtfdIMbY/yFOUikCzhwAR1q\
	    UMU6ZtGvAGjGB3RbRxvKyAAAdDJAzTokFiJBilGuQ0qBUAN/QmEIaS4pFKhI\
	    ByYYFAVLVNSihsjZQPrC/lF+ZPEvuQBJGxr5J964waCRIMQmpOkILcxgBvlg\
	    ayiGwQ9+gIQfvcAEKRwhCE9EQhCSYgAD3tiJQXyDG6flhj8yqYtZwGEFXODC\
	    Fl4BUn/wxx8+UAI6OrEOf7jhN21oi6ScYg6xYgmcgaJPKILzPnMYYklXTAcq\
	    HtLZYwhCEMPIRbL68o98cBRZ+xgMSN6xCPG+oxNlKAMhCJEJO+XDElqgozTY\
	    isdoVnYdvSAEKQTh2WNEwhOgU9YguPEN0/rPKdBqJDreOCkagZQHT1DCIhZB\
	    lSm4gQGHrEo61oHe9BIiLW1IWzpC0RTJQgMQouoGcgBwAk94wrqCOIYn3NDR\
	    /u0WZK/JsrE+yFuPegDmEWFYBCEiUQhAlMENbpiBIerhiPK8I5yV6AVZDlUJ\
	    VGiodwD8BToIzA18MA+1UDJOFIwiqrRK7Ao5eMLzyLIIV4CRATZChxb+4Ax0\
	    hAG9SAkEg9wBsygA4h2AaNcKTnDOXwxiEKhQLy07kVeObvcfHcWfe/a6V4I0\
	    YxBhoIQjAKEFMZRBC1+ohyHAOYxjJGMQ3UAnOsHWO0ODzh3fWEY9erOMdZw2\
	    d21gKAAeUua0vrEbSjDHFo5sDp9pMADoKIYs2NEOdhTjD2FAB6CHkQxSvO+Z\
	    gXhfqdxAVKJOGWyd8AWkCfKPf+TSu1w8lkEKcj9e/vhDiG5YQRjs3AYGNXEa\
	    hu6GN9rSG27/IqvTm5RmoAKtoomqN15Tj9W20AlpfGALcJCdJMSwhTJGgR3m\
	    4AY74MGOZkciUExERzJazFlPvGMQbfhFP9Lxi0Tk4hfc4PaMA7NXcpM7WX7p\
	    bhYjPfM+B+ILzJrGMtLJD6RMwx2Vq0c6hC7cZWRwGd6ohCi0bA3UEhViR8lG\
	    1rNBDoe0IX/lq8EV1ACHdYBoG/4ohzOiRQ5ynOMd7YDHJXgK6JB3Qx+VWMY2\
	    vKHvtqxgBSUZBFG/IY3ubmkgNbc5zm+O47y+h8l+UFYAhN6WfeecHzbNalpQ\
	    YRRUrEbL3LCGabkhNmdk/lDr2UAHN45SJhfkCTrogIMatoCOaMD9IQGoRBgG\
	    kQ54wOMPB3WElNAxH0PlYhpObEsY/P6OMLRmGfQr/BYpqw/Ek/tyNt6idtW9\
	    pU444hikJGdPqbIO7+4jEW+uRjVQkYx1pD8Z6ffGN8hhDWtkmRvZaMYzHuGM\
	    bJDlDzc4n7T4jn3oGhfoAS7IA+FIh0WIAmdwg0yIgkhIJ9t5iEMQhHfYBl/Y\
	    Bh6zC8AqAwkIrVyIK0xIv/fAGY6qPsRzj0bLnJzpC7/aIjc4Bn84Bkd4B/bh\
	    rC/hh074u26oht5YDUoQhU1YB0t4B0zoBW7YhXfAhWZoBhLhgRpAhxw4gRZA\
	    /grQ+Y3OETNzaIYZeDiyCANy6IW6Sr52kAdMOoZ1QI96cINP+wJf4LAA8Lv0\
	    Qz6704e+UrwUrD6cKTzMobSB8K6DyIVkeAcGySBS84RjOBjRosNNyAVREMJc\
	    aLlcWAdU+IZ3eAZTKAVg6IY92AMUYIEcCIIWcINwKKAA4CcE64VHaAZ04AI4\
	    YIdBOIc/IAXEagt4kIf+cwRLcARP0J8p2iwtOK8VYIAVoMN0qIbuwsMu0cMU\
	    3BKOyj5Kg8aaeYfKusE0jLEC2gZceodkgMROS4R68IZ1yAU/qoQ2GDBnwIZS\
	    YMc9OIVRIAFcAId4ACm1wB3skIVsIIUPgQN0IAdu/tgEQigDysuHdhgEBIqE\
	    TTCH3SrEC8mHbSgDqCAEZKwGSWjBLuGHZnTGQDS8dpIGwvOr8QmJemOQtEkG\
	    f+AtUnAFLdgGSpgCNRDH48MEMXCDS/wG3jAHeYiH8wEGncyGtDGKchAVEHuE\
	    apAFTFgHLvgDaygGS3iIdqC8tgAEshKFXJAGSeiES6iGTSCGSPCFGEuG96uG\
	    GVu3yukLytJIZ6SxvZIEOPAFXpC1euCTKAiMd/CGaRDHbeiHaJmGqliHdBEY\
	    SiC2MsiFeoAlUWgD0cMEcJAHsliHeIDMIzmKcLAGXGAGoLGGSpCFdSAEF7CD\
	    WtMjeAiu73gHUaoGBzkB/nh7toeoBCd6v+Mrv8rJvoxMy+rrw+yDS2YBCaSQ\
	    sHWQHb/LmcHAkW5YgY94v2RAB0o4nRDSEHmDIlHAjm/whh/MkXSIB52Mhygz\
	    h3fAA8iUB3k4E6rwB1nohRYwA3D4BkxADxiIgRjQsDVYA0SgBWmwBXh7B3cg\
	    jGJchGpIhnRIBky4uZu5nNpMwRzLGVkbDJBqC3MoIKg4iiOjIeDYBmngC3MI\
	    S3TIBHMYskJAim44j5rwhY+5S2/ABZFDB1zQhneQO0t5zHDQyVvggorDIHRo\
	    AUjoGkJIhkQQg1joAqpIG0Z4BW/oBmewg3rwhRWYIZIIg27sB43Kmfs5CAJV\
	    /kvvGi8F1bBO+g8biRYaCq3QCoDv+A7OzIVCsIRMKITtKQx0+AJMuIRE+CPp\
	    RIVlyIaLCoV7+ISdTIdioMd4MENrUIEW2IJucIqqaAFlyIZz6Dy4SgdZyxFG\
	    OApvuAdYowYucAMJiAIH2YZEyCXLoawbk9Lq45KCYNT6eIqgARqvuZsWsaGz\
	    U61NkIRyyYQ4KILtccxqSIQMaYN6+AZPCMuLQocLtBRUwIMxctF2sINgAAdl\
	    YIZeKKMAWAd2eAR4+AbKgwdZe4d0GIVRAAlncAZyeAdeYLgvSbF3wJy/qJw7\
	    /NTqO5Z9sNa26CV0ULl0UC1/cAd3OKS0aAjcASiQ/riCQjiEODiDW0kLqUuE\
	    RMAE5HiHafAGT+iGUEAHh/UEQ6gGWEAHeQgHPi2HFrCDXkCHP4gG/8mdb+g9\
	    eVgEdvCHejCDpGuLfjiKzOCFhVhX+Lgc2UTXdEW8cyWIeqhOyiOVqKQ8d7hW\
	    zDsyzxm/RsKCQyiEDDLYgk0EgXmKqUjTSZiSbjCEFHPRcLjYeOAEOBADbDoB\
	    M3CIZdC4dqgHv5sPdi0vaZA5guiuHLuZnNmit70Zm7XN95C1kfLZqKwHfvAF\
	    ytMHDcMRf9CM3CGMpwCOpTCHQSSFT0OKqhCY60gOgSmGi7XYeGAHywWHZ7CG\
	    eMiGXoiC3juHcniH8hun/m3AosVD3be9nH6gW3UtvHyICc0gSF7ghai8h3UA\
	    xHQ4iJCgjyMDDq7iD6dog/BEB/SahuOtRUPYnapFSbM6g0eAhXKwWIvluHjo\
	    vUG4hDDABGc4B3D4hEXrKL0yPNSF245qXXXdEpDAibbIB599h3sgB4Lc2354\
	    h++ooaXIQqeYlqnAgk0IOnQghP06gyo4gzMwBHPwB4dAB2+oA2TIpKstB8vN\
	    BnM4B45jB22oh/pZvGiENGVstH04X/SFj1zQDHSoB1zK27YwCjVoC1/oho9c\
	    AUu1igByA66AkkxSMKqogh3ehiqQ2h2ugkApDjc4O6ztBqwNh3YIB4EpB3EA\
	    /gdt0Iac+4tzSwiOzJybybkQ1sPGU4iP8lkem4d7IIwtIL+2wAcH+bsyyR1o\
	    KTN/IBpy2ocqOKSpmAQ+COJACJVuUOCjkAVk8GMkTuJyaGJxeAcuOrcXXEEN\
	    pqx96Afq0+KNvKXx2tm8vYd5GAd6SIdxsIdu4I90mNERghYFxgly2saautJt\
	    kJIxAIQgPgPNcIhtwIEXiIE6qANZkAW18ONy4AfC077bFN8uQeRHrs10Kwjz\
	    aqdFYN95qJx0uIdouIZtoAdscAVzIIhqXsh8GBlLyQUHaYNnxodvxgeQAATl\
	    RYeANYRxRodzrgLsKIYYwIEYkOUYeIdw7KXxhcZp/gTEJhVmm80lv1gX3+wE\
	    XLEdlY0GfcCGcRAVawaJfWiDkSAGDDKHfukEbLiGa8CHScCHfUCHfQhYQaAS\
	    QwjYnqqCJUKKZYiBbojlF3iHGOAFdCPmcnXkfT5fLcK5TtCwm06H2jWHm9Gg\
	    WGAFu7EUcxgHdfCHGSAGeOsEnDhqNbCHcciBOAiFb47bX12HDvJoJnuHII4E\
	    Wzi2IRiC9pRladCitoXGLJJpYb5DQJxiC8LSL56HRRiHn06FVPCDuV4HdVCH\
	    aziTKWgLe3gHdegGTWADqMYHr8s+ZQkJGzyDOKiCOAAETwjg3XSHIchgnNuo\
	    wKDNsxbmD0aI3VqHeI1K/n2YB3Tw6VRghdN+h59mg7xmDBMoDXWYhFRQhFYI\
	    Aj/AB3cI0IOoh0Mo4DMYZ0Fwh3WAhSFAAzRwhy5Ja+T2C82WadL1528NrraY\
	    B9FOh3COBXOIhXWoa1Zgg0ZYBza4p954gycgAzmgAy8IZ5ljPI76COW1LmeQ\
	    hm3QYGR5XeY+636uHwvy2TFKB7Nc1HqYazp4g0Z4B/BuhPGuhwO/AylggYw+\
	    N8UzUL+4n/KLNJvZIta177OONMAADMJi0LbQhx7726SrB3Wgg0Y4cClgg21o\
	    hCzIhzd4gzlQBCnIgXDrZcy5bPh4RnPFmQy3b5qWtJzhhX7ohn2Y7nlIh+m2\
	    /imQkgM5IHA2QAc2eAcCbwQ2kIMc0GRIo7HtK1cWFF/KQksfZ+5bkuL3gIN5\
	    WAddMIdZ0AU3Rtt7UgRc6QSgMockyAEWYIFewQf1vsOQjD4t2iLlltl8EHMx\
	    f9s+N7cO1+Pv+O+QSAUCBwl9WIH6yPMkYAE/GIcTNtAHP2xAr+IpPgh+wPBC\
	    93E8bEG1/gtz6IdVz6B9WAd7sIfK1gfSsIcnSIEUyHN84GJATzcdx/FG84fM\
	    JnUx52JB1y7hnDGzvEOQsAd1YHFNXrQbwx9HG/Zqb1217kN1Q+4/dA8bAQm8\
	    1gR6sAcsPtc/t/ZzP99pzKL7mT7D68Nspgd1oAd6qaAfXi9fdMd3ut3yQ55v\
	    fdjO0Z0HewCCMte5nMn3g09XF7Sxfs6xavaLf6/m0QVE0sUlhLf4T73DmbXn\
	    LOKx+znhc/2u5b74kZdSw6vi28TZm1s3aCT5lk/4vsr2mnFS9+irE3T5m7fZ\
	    lH8PDs94XAIMYcf5oE/LmM94v4J5FxT6pCdQKKV5kO+ruAV6pZd6FcS56cOl\
	    msf6qdd6PewHnIF5LD63rd/ngAAAOw==	
	
    }
    
    # ShowMidpaneTools begins here 
    
    set wr $parent
    
    #This stuff ends up on the "Images" tab of the middle window in chellyGUI
    set ICbackgroundcolor "LightSteelBlue1"
    set IC [canvas $wr.imagecanvas -height 500 -bg "$ICbackgroundcolor"];     pack $IC -fill both -expand 1
    
    #This is the button frame window which will pack into the canvas at each brain
    foreach n {SpaceImage AnatomicalImage FunctionalImage} {
	
	set bf_$n [frame $midpane.viewbuttonsframe_$n -bg $ICbackgroundcolor -borderwidth 2 -relief groove]
	pack $midpane.viewbuttonsframe_$n
	set bftf [frame $midpane.viewbuttonsframe_$n.topfr -bg $ICbackgroundcolor]; pack $bftf -padx 4 -pady {1 3}
	set bfbf [frame $midpane.viewbuttonsframe_$n.bottomfr -bg $ICbackgroundcolor]; pack $bfbf -padx 2 -pady {1 3}
	
	set viewer1but [eval "button $bftf.view1but -image smallviewericon -height 16 -width 24\
			    -command {$this sendSelectionToDisplay 1 -1 $n } "]
	set viewer1butlabel [label $bftf.label1 -text "RF Viewer" -font {helvetica 13 bold} -bg "$ICbackgroundcolor"]
	pack $viewer1but $viewer1butlabel -side left -pady {3 0}
	
	set viewer2but [eval "button $bfbf.view2but -image smallviewericon -height 16 -width 24\
			    -command {$this sendSelectionToDisplay 2 -1 $n } "]
	set viewer2butlabel [label $bfbf.label2 -text "TR Viewer" -font {helvetica 13 bold} -bg "$ICbackgroundcolor"]
	pack $viewer2but $viewer2butlabel -side left -pady {0 2}
	
	
	if {$n != "SpaceImage"} {
	    
	    set REFcheckbox [checkbutton $midpane.viewbuttonsframe_$n.refcheckbut \
				 -text "Ref Space" -variable REF_$n -bg $ICbackgroundcolor]
	    pack $REFcheckbox -side top -pady {0 3}
	    
	    eval "$viewer1but configure -command {    if { $[subst REF_$n] } {$this sendSelectionToDisplay 1 1 $n} else {$this sendSelectionToDisplay 1 -1 $n } }   "
	    
	    eval "$viewer2but configure -command {    if { $[subst REF_$n] } {$this sendSelectionToDisplay 2 1 $n} else {$this sendSelectionToDisplay 2 -1 $n } }   "
	    
	    
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
    
    set arrowlinebgcolor grey80
    #-----Func --> Space -----------------------------------------------------------------
    $IC create line [expr $rbX + 145] [expr $rbY + 50] \
	[expr $rbX + 190] [expr $rbY + 55] \
	[expr $fbX + 95 ] [expr $fbY - 85] \
	[expr $fbX + 80 ] [expr $fbY - 6] \
	-tag Func2SpaceBG -smooth true  -splinesteps 20 -width 18 \
	-arrow first -arrowshape {15 28 10} -fill $arrowlinebgcolor
    
    
    
    
    #-----Anat --> Space -----------------------------------------------------------------
    $IC create line [expr $rbX - 10] [expr $rbY + 50] \
	[expr $rbX - 55] [expr $rbY + 55] \
	[expr $abX + 35 ] [expr $abY - 85] \
	[expr $abX + 50 ] [expr $abY - 6] \
	-tag Anat2SpaceBG -smooth true  -splinesteps 20 -width 18 \
	-arrow first -arrowshape {15 25 10} -fill $arrowlinebgcolor
      
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


::itcl::body chellyGUI::OCanvasInitialize { canvas } {
    
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
#  This is the most important method of chellyGUI - it creates all the frames and widgets
#------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------

::itcl::body chellyGUI::ShowManager {pw surgerygadget0 menubase } {

   
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
    
    set RealTree [struct::tree [pxvtable::vnewobj]]
    #Sets a root for the tree
    $RealTree rename root Data
    set NodeIDs(/Data) [$RealTree rootname]
    
    #---------------------------------------------------------------------------
    #Add the default object set to the tree
    AddDefaults $RealTree
    set TreeChanged 0
    
    
    #Update the Visualization Tree with the contents of the real tree
    updateVisTree $vistree $RealTree 
    findTransforms $RealTree
    
    
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

    foreach m {File Edit Tools Datatree Patient Image Options} {
	set $m [menu $mdmenubar.m$m -tearoff 0]
	$mdmenubar add cascade -label $m -menu $mdmenubar.m$m -background $menucolor 
    }
    
    makeFileMenu $File
    makeEditMenu $Edit
    makeToolsMenu $Tools
    makeDataMenu $Datatree
    makePatientMenu $Patient
    
    makeImageMenu $Image
    
    #Add a couple extra options to the "Image" menu
    $Image add separator
    eval "$Image add command -label \"Set As Space/Anatomical Image\" -command { $this setSelectionSpace $RealTree; $this setSelectionAnatomical $RealTree} -activebackground \"$menuactivebgcolor\""
    eval "$Image add command -label \"Set As Functional Image\" -command { $this setSelectionFunctional $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$Image add command -label \"Set As Space ONLY\" -command { $this setSelectionSpace $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$Image add command -label \"Set As Anatomical ONLY\" -command { $this setSelectionAnatomical $RealTree } -activebackground \"$menuactivebgcolor\""
    eval "$Image add command -label \"Set As Space and Functional\" -command { $this setSelectionSpace $RealTree; $this setSelectionFunctional $RealTree } -activebackground \"$menuactivebgcolor\""

    #Set the background for all menu entries
    for {set i 0} {$i <= [$Image index end]} {incr i} {
	$Image entryconfigure $i -background $menucolor 
    }
    #--------------------------------------------------------------------------------
    
#    makeViewMenu $View
    makeOptionsMenu $Options
   
    

    #------------------------------------------------------------------------------------------
    #    Old, frame-based menu
    #------------------------------------------------------------------------------------------
    #    $mdmenubar configure -width 400 -height 50 -relief raised -background $menucolor
    
    
    #     #------------------------------------------------------------------------------------------
    #     menubutton $mdmenubar.file -text File -menu $mdmenubar.file.m -underline 0\
	# 	-background $menucolor -activebackground "$menuactivebgcolor"
    #     pack $mdmenubar.file   -side left
    
    #     makeFileMenu [menu $mdmenubar.file.m -tearoff 0]
    
    #     #------------------------------------------------------------------------------------------
    #     menubutton $mdmenubar.edit -text Edit -menu $mdmenubar.edit.m -underline 0\
	# 	-background $menucolor -activebackground "$menuactivebgcolor"
    #     pack $mdmenubar.edit   -side left
    
    #     makeEditMenu [menu $mdmenubar.edit.m -tearoff 0]
    
    #     #------------------------------------------------------------------------------------------
    #     menubutton $mdmenubar.tools -text Tools -menu $mdmenubar.tools.m -underline 0\
	# 	-background $menucolor -activebackground "$menuactivebgcolor"
    #     pack $mdmenubar.tools  -side left
    
    #     makeToolsMenu [menu $mdmenubar.tools.m -tearoff 0]
    
    #     #------------------------------------------------------------------------------------------
    
    #     menubutton $mdmenubar.datatree -text Datatree -menu $mdmenubar.datatree.m\
	# 	-underline 0 -background $menucolor -activebackground "$menuactivebgcolor"
    #     pack $mdmenubar.datatree   -side left
    
    #     set datatreemenu [ menu $mdmenubar.datatree.m -tearoff 0 ]
    
    #     makeDataMenu $datatreemenu
    
    #     #------------------------------------------------------------------------------------------
    #     menubutton $mdmenubar.patient -text Patient -menu $mdmenubar.patient.m\
	# 	-underline 0 -background $menucolor -activebackground "$menuactivebgcolor"
    #     pack $mdmenubar.patient -side left
    
    #     set patientmenu [eval "menu $mdmenubar.patient.m -tearoff 0 \
	#  -postcommand { $this menuActivation $mdmenubar.patient.m patient}   "]
    #     makePatientMenu $patientmenu
    
    #     #------------------------------------------------------------------------------------------
    #     menubutton $mdmenubar.image0 -text Image -menu $mdmenubar.image0.m\
	# 	-underline 0 -background $menucolor -activebackground "$menuactivebgcolor"
    #     pack $mdmenubar.image0 -side left
    
    #     set imagemenu [eval "menu $mdmenubar.image0.m -tearoff 0 \
	#  -postcommand { $this menuActivation $mdmenubar.image0.m image}   "]
    
    #     makeImageMenu $imagemenu
    
    #     #------------------------------------------------------------------------------------------
    #     menubutton $mdmenubar.view -text View -menu $mdmenubar.view.m -underline 0\
	# 	-background $menucolor -activebackground "$menuactivebgcolor"
    #     pack $mdmenubar.view -side left
    
    #     set viewmenu [menu $mdmenubar.view.m -tearoff 0]
    
    #     makeViewMenu $viewmenu
    
    
    #     #------------------------------------------------------------------------------------------
    #     menubutton $mdmenubar.options -text Options -menu $mdmenubar.options.m -underline 0\
	# 	-background $menucolor -activebackground "$menuactivebgcolor"
    #     pack $mdmenubar.options -side left
    
    #     set optionsmenu [menu $mdmenubar.options.m -tearoff 0]
    
    #     makeOptionsMenu $optionsmenu
    
    #     #------------------------------------------------------------------------------------------
    
 

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
    eval "button $leftBF.l1 -text \"Set Space and Anatomical Image\" -command { $this setSelectionSpace $RealTree; $this setSelectionAnatomical $RealTree }"
    eval "button $leftBF.l2 -text \"Set Anatomical Image\" -command { $this setSelectionAnatomical $RealTree }"
    eval "button $leftBF.r3 -text \"Set Functional Image\" -command { $this setSelectionFunctional $RealTree }"
    pack $leftBF.l1 $leftBF.l2 $leftBF.r3 -fill x -expand 1 -side left
    
    #pack the whole two-bar frame (tbf)
    pack $tbf -side top -fill x -padx {3 3} -pady {2 0}
    
    set rbfr [frame $midpane.reslframe -bg $menucolor]; pack $rbfr -side top -fill x -padx {3 3}
    eval "button $rbfr.big -text \"Reslice Images\" -command { $this Reslice }"
    pack $rbfr.big -side left -fill x -expand 1
    
    #Interpolation mode menu
    menubutton $rbfr.modemenu -text Mode -menu $rbfr.modemenu.m\
	-underline 0 -background $menucolor -activebackground "$menuactivebgcolor" -relief raised
    pack $rbfr.modemenu -side right -padx {2 0} -pady {0 2}
    
    set modemenu [menu $rbfr.modemenu.m -tearoff 0 ]
    eval "$modemenu add radio -label Linear -variable {[itcl::scope reslmode]} -value 1"
    eval "$modemenu add radio -label Cubic -variable {[itcl::scope reslmode]} -value 3"
    eval "$modemenu add radio -label \"Nearest Neighbor\" -variable {[itcl::scope reslmode]} -value 0"

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
    if { 0 } {    
    set imageutility [ bis_guitreeimageutility \#auto ]
    $imageutility InitializeFromContainer $this
    set w $mdTopWidget.$imageutility

    set imageutility [ $imageutility GetThisPointer ]
    $imageutility CreateGUI $w 
    set imageUtilityMenu [menu $mdmenubar.imageutitily -tearoff 0]
    $mdmenubar add cascade -label ImageUtility -menu $imageUtilityMenu -background $menucolor
    $imageutility AddToMenuButton $imageUtilityMenu
    }
    
    #Bind button clicks in the tree
    eval "$vistree bind x <1> { $this bindx1 %W %x %y }"
    eval "$vistree bind x <Button1-Motion> { $this bindxmotion1 %W %x %y }"
    eval "$vistree bind x <ButtonRelease-1> { $this bindxrelease1 %W %x %y 1 }"
    eval "$vistree bind x <Control-ButtonRelease-1> { $this bindxrelease1 %W %x %y 0 }"
    eval "$vistree bind x <Control-1> { $this bindxcontrol1 %W %x %y }"
    eval "$vistree bind x <Double-1>  { $this bindxdouble1 %W %x %y }"
    eval "$vistree bind x <3> { $this bindx3 %W %x %y }"	
    eval "$vistree bind x <Control-Key-x> { $this bindxControlX %W %K %N }"
    eval "$vistree bind x <Control-KeyPress-c> { $this bindxControlC %W %K %N }"
   

    update
    
};#End ShowManager method def

::itcl::body chellyGUI::Debug { } {
    
    
    #     pxtkconsole
    
    #     foreach p [array names NodeIDs] {
    # 	pxtkprint "$p\n"
    #     }
    
    #    pxtkprint "--------------------------------------------------------------------------------\n"
    
}


##########################################################################################
#                             This ends the chellyGUI class                              #
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



