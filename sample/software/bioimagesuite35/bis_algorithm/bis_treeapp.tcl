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


lappend auto_path [ file dirname [ info script ]]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] main]

package provide bis_treeapp 1.0
package require bis_treewidget 1.0
package require bis_algorithm 1.0
package require bis_xmlalgorithm
package require pxitclfilelistmenu 1.0
package require pxtcluserprefs 1.0
package require bis_common 1.0
itcl::class bis_treeapp {

    inherit bis_algorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method CreateGUI  { parent { callafter 0 } { callbefore 0 } }
    public method GetGUIName    { } { return "BioImage Suite DataTree" }

    protected method CreateMenu { menubase viewerlist }
    protected method AddComponents { }
    protected method AddPlugins { }
    public method AddSinglePlugin { fname }


    public method LoadTree { args }
    public method GetTreeName {  } { return [ $OptionsArray(treefile) GetValue ] }
    public method SaveTree { mode args }
    public method CheckTree { args }

    public method ShowTool { tool }
    public method SetCurrentViewer { vr }
    public method GrabImageFromViewer { vr }
    public method SetComponentsList { lst } { set componentslist $lst }
    public method SetPlugins { lst } { set pluginslist $lst }
    public method UpdateToolChoiceMenu { }

    protected variable treewidget 0
    protected variable menubase 0
    protected variable compmenu 0
    protected variable viewmenu 0

    protected variable componentlist ""
    protected variable pluginslist  ""
    protected variable toollist ""
    protected variable initializedtools ""
    protected variable toolwidgetarray
    protected variable toolbase 0
    protected variable currenttoolwidget 0
    protected variable currenttool 0
    protected variable toolchoicemenu 0
    protected variable categorychoicemenu 0
    protected variable categorytoolarray 
    protected variable categories "" 
    protected variable pluginmenu 0
    protected variable pref_dialog 0
    protected variable viewerlist ""
    protected variable pluginname "Plugins"
    protected common thisparam
    protected variable helpdialog 0

    public method HelpCommand { }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_treeapp::Initialize { } {

    PrintDebug "bis_treeapp::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
    	{ treefile   "specify the filname for the datatree" "DataTree  File Name" { filename readile } "" { datatree } 1 }
	{ componentfile   "specify the filname of the text file containing the list of components to use" "Component  File Name" { filename readile } "" { textfile } 2 }
	{ pluginfile   "specify the filname of the text file containing the list of executable plugins to use" "Plugin  File Name" { filename readile } "" { textfile } 2 }
    }

    set scriptname "DataTree v2"
    set completionstatus "Done"

    #
    #document
    #
    
    set description "Data Tree Application"
    set description2 ""
    set backwardcompatibility "Replaces old BioImage Suite datatree"
    set forceguimode 1
    set category "GUI"
    set componentlist [ list bis_computeglm bis_ISAS bis_ISASHN bis_biasfield bis_sliceinhomogeneity bis_blendimage bis_castimage bis_checkerboardimage bis_cleansurface bis_clipsurface bis_clusterthresholdimage bis_colorblendimage bis_combineframes bis_combineimages bis_computedisplacementfield bis_computenormals bis_computeoverlap bis_computesimilarity bis_connect bis_convolveimage bis_create4dimage bis_createoverlayimage bis_cropimage bis_csfwmmotioncorr bis_curvatures bis_cylindricalcropimage bis_decimate bis_delaunay3D bis_distancemapimage bis_edgedetectimage bis_extractobjectmap bis_extractsurface bis_fdr bis_fftimage bis_flipimage bis_headerinfo bis_imagecompare bis_imagedilate bis_imagemathoperations bis_imagemedian bis_imageremoveframes bis_interleave  bis_intsegment bis_levelset bis_manualregistration bis_linearintensityregister bis_linearpointregister bis_listthresholdimage bis_makebatch bis_manualreslice bis_maskimage bis_matrixcorrelation bis_mediantemporalsmoothimage bis_nonlineardistortioncorrection bis_nonlinearintensityregister bis_nonlinearpointregister bis_nonlinearsmoothimage bis_piecewiseimagemap bis_preprocessimage bis_proportionalscale bis_relabelimage bis_removeslicemean bis_removetemporaldrift bis_reorientimage bis_resampleimage bis_resliceimage bis_reslicetensor bis_rfftimage bis_roimean bis_rtopvalue bis_rtotmap bis_seedcorrelation bis_serialdemon bis_shiftscaleimage bis_singlejacobian bis_smoothimage bis_smoothsurface bis_spectrf bis_split4dimage bis_stitchimage bis_stripskull bis_subdivide bis_surfaceinfo bis_temporalsmoothimage bis_thresholdimage bis_thresholdpoints bis_tmaptopvalue bis_tmaptozscore bis_transformsurface bis_triangulate bis_ttest bis_visualizetransformation bis_zscoretopvalue bis_smoothlandmarks bis_resamplelandmarks bis_regularizeobjectmap bis_computetensor bis_tensoranalysis bis_frangivesselness ] 

#    set componentlist [ list bis_smoothimage bis_manualregistration bis_nonlinearintensityregister bis_create4dimage ]
#    set pluginslist [ list /usr/local/slicer/Slicer3-build/lib/Slicer3/Plugins/MedianImageFilter /usr/local/slicer/Slicer3-build/lib/Slicer3/Plugins/OtsuThresholdSegmentation  ]

    set thisparam($this,currentviewer) 0
    $this AddDefaultOptions
}
# -----------------------------------------------------------------------------------------
itcl::body bis_treeapp::CheckTree { args } {

    set lst  [ [ $treewidget GetDataManager ] CheckSavedObjects 0 0 ]
    if { [ llength $lst ] == 0 } {
	tk_messageBox -type ok -message "All Objects in the tree are saved" -title "Tree OK" -icon info
	return  1
    }
	
    pxtkconsole
    foreach l $lst {
	if { [ string length $l ] > 0 } {
	    pxtkprint "Item $l not saved\n"
	}
    }

    set msg [ tk_messageBox -type yesno -message "Same Objects in the tree are not saved on disk. Do you want to save them?" -title "Not all nodes are saved" -icon warning ]

    if { $msg == "no" } {
	return 0
    }

    
    set lst  [ [ $treewidget GetDataManager ] CheckSavedObjects 0 1 ]
    if { [ llength $lst ] == 0 } {
	tk_messageBox -type ok -message "All Objects in the tree are saved" -title "Tree OK" -icon info
	return  1
    }

    tk_messageBox -type ok -message "Some Objects in the tree are still not saved. Try to fix manually." -title "Tree Problem" -icon info
    foreach l $lst {
	if { [ string length $l ] > 0 } {
	    pxtkprint "Item $l not saved\n"
	}
    }
	
    
}
# -----------------------------------------------------------------------------------------
itcl::body bis_treeapp::LoadTree { args } {

    if { [ llength $args ] > 0 } {
	set val [ lindex $args 0 ]
    } else {
	set val [ $OptionsArray(treefile) GetValue ]
    }

    if { [ file exists $val ] == 0 } {
	set val ""
    }
    set fname [ $treewidget LoadDataTree  $val ]
    if { [ string length $fname ] > 1 } {
	$OptionsArray(treefile) SetValue $fname
	wm title $basewidget "DataTree Application $fname"
    }
}

itcl::body bis_treeapp::SaveTree { mode args } {

    if { $mode == 1 } {
	set val [ $OptionsArray(treefile) GetValue ]
    } else {
	set val ""
    }

    set fname [ $treewidget SaveDataTree  $val ]
    if { [ string length $fname ] > 1 } {
	$OptionsArray(treefile) SetValue $fname
	wm title $basewidget "DataTree Application $fname"
    }
}

# --------------------------------------------------------------

itcl::body bis_treeapp::CreateMenu { menubase viewerlist } {
    global env
    global pxtcl_pref_array

    set filem [ menu $menubase.file -tearoff 0  ]
    $menubase add cascade -underline 0  -label "File" -menu $filem

    eval "$filem add command -label Load -command { $this LoadTree \"\" }  "
    eval "$filem add command -label Save -command { $this SaveTree 1 \"\" }  "
    eval "$filem add command -label SaveAs -command { $this SaveTree 0 \"\" }  "
    $filem add separator
    eval "$filem add command -label \"Check Tree\" -command { $this CheckTree }"
    eval "$filem add command -label \"Switch Directory\" -command { $this SetCurrentDirectory } "
    $filem add separator

    set thisparam($this,custdirectories)  [ pxitclfilelistmenu \#auto $filem "Custom Directories" "$this SetCurrentDirectory" ]
    $thisparam($this,custdirectories) SetModeToDirectories
    $thisparam($this,custdirectories) InitializeDisplay
    global env

    set tthis [ itcl::scope $this ]
    set thisparam($this,custsetups)  [ pxitclfilelistmenu \#auto $filem "Tree Files" "$tthis LoadTree" "$tthis GetTreeName" ]
    $thisparam($this,custsetups) SetModeToCustom "DataTree Files" .xmltree [ file join $env(HOME) .xmltreefiles ] 1 
    $thisparam($this,custsetups) InitializeDisplay
    $filem add separator

    eval "$filem add command -label Exit -command {  $this ExitCommand } -underline 1"


    set viewmenu [ menu $menubase.vmenu -tearoff 0 ]
    $menubase add cascade -underline 0  -label "Viewer" -menu $viewmenu

    set n [ llength $viewerlist ]
    set vm2 [ menu $viewmenu.s -tearoff 0 ]
    $viewmenu add cascade -underline 0  -label "Select Current Viewer" -menu $vm2
    $viewmenu add separator
    for { set i 1 } { $i <= $n } { incr i } {
        eval "$vm2 add radio -variable [ itcl::scope thisparam($this,currentviewer) ]  -value [ expr $i -1 ] -label \"Viewer $i\" -command { $this SetCurrentViewer [ expr $i -1 ] } "
    }

    set compmenu [ menu $menubase.comp -tearoff 0 ]
    $menubase add cascade -underline 0  -label "Algorithms" -menu $compmenu


    set helpm [ menu $menubase.help -tearoff 0  ]
    $menubase add cascade -underline 0  -label "Help" -menu $helpm 
    
    eval "$helpm add command -label \"Help Index\" -command { $this HelpCommand }"
    eval "$helpm add separator"

    eval "$helpm add command -label Preferences -command { wm deiconify $pref_dialog}"
    $helpm add command -label Console -command { pxtkconsole }
    eval "$helpm add separator"
    eval "$helpm add command -label About -command { $this AboutCommand }"

}

itcl::body bis_treeapp::HelpCommand { } {

    if { $helpdialog != 0 } {
	::pxtclutil::ShowWindow $helpdialog
	return
    }

    set bname [ file normalize [ file join $::pxtclvtkpxcontrib::baselibrarypath  .. ] ]

    set b(1) [ file join $bname html ]
    set b(2) [ file join [ file join $bname .. ] build/html ]
    set b(3) [ file join [ file join $bname .. ] build64/html ]

    set i 1
    set rootname 0
    while { $i < 3 } {
	set f [ file normalize [ file join $b($i) index.html ] ]
	puts stdout "Looking for $f"
	if { [ file exists $f ] > 0 } {
	    set i 4
	    set rootname $f
	}
	incr i
    }
    
    set w .
    if { [ string length $basewidget ] > 2 } { set w $basewidget }
    
    set helpdialog  [ toplevel $w.[ pxvtable::vnewobj ]] 
    wm geometry $helpdialog 800x600
    
    wm title $helpdialog "BioImage Suite Tools Manual Pages"
    
    set scr [ iwidgets::scrolledhtml $helpdialog.t  -labeltext "" \
		  -width 6i -height 3i \
		  -wrap word -padx 2 ]
    $scr configure -fontsize large
    
    pack $scr -side top -expand true -fill both
    ::bis_algorithm::SetWidgetTreeColors $scr "\#8197c5" white    
       
    if { $rootname != 0 } {
	$scr import $rootname
    } else {
	$scr insert end "No Man Pages Found"
    }
    
    ::pxtclutil::ShowWindow $helpdialog
}


itcl::body bis_treeapp::AddComponents {  } {

    #set componentlist { bis_smoothimage bis_cropimage }

    set val [ $OptionsArray(componentfile) GetValue ]
    if { [ file exists $val ]  > 0 } {
	set componentlist ""
	set fin [ open $val r ]
	while { [ gets $fin line ] >=0 } {
	    if { [ string first "\#" $line ]  == -1 } {
		lappend componentlist [ file rootname [ string trim $line ] ]
	    }
	}
	close $fin
    }
    puts stderr "New Components = $componentlist"
    
    set qlist [lsort -ascii  $componentlist ]
    set componentlist ""
    set index 0
    set num [ llength $qlist ]

    foreach tool $qlist {
	set ok 0 
	catch { package require $tool ; set ok 1 }
	if { $ok == 1 } {
	    lappend componentlist $tool
	    set cmt "Loading"
	}  else {
	    set cmt "Ignoring"
	} 
	incr index
	set per [ expr double($index)/double($num) ]
	$treewidget ShowProgressVal "Loading Components" $per
	update idletasks
    }
    $treewidget ShowProgressVal "Done" 1.0

    set categories [ ::bis_common::GetCategories ]
    set toollist ""

    eval "iwidgets::optionmenu $toolbase.0 -labeltext \"Grp:\" -labelpos w -command { $this UpdateToolChoiceMenu } "
    eval "iwidgets::optionmenu $toolbase.1 -labeltext \"Alg:\" -labelpos w -command { $this ShowTool 0 } "
    pack $toolbase.0 $toolbase.1 -side top -expand false -fill x
    set toolchoicemenu  $toolbase.1
    set categorychoicemenu  $toolbase.0

    foreach tool $componentlist {
	set alg [ [ $tool [pxvtable::vnewobj] ] GetThisPointer ]
	$alg InitializeFromContainer 0 $treewidget
	$alg SetBisViewer $bis_viewer
	$alg SetDataTree $treewidget

	set categ  [$alg GetCategory]
	if { $categ == "" } {
	    set categ "Other"
	}
	if { $categ != "GUI" } {
	    set componentcat($alg) $categ
	    if { [ lsearch -exact $categories $categ ] == -1 } {
		lappend categories $categ
	    }
	    
	    lappend toollist $alg
	}
    }
    
    for { set i 0 } { $i < [ llength $categories ] } { incr i } {
	set grp [ lindex $categories $i ]

	set num 0
	foreach alg $toollist {
	    set categ  $componentcat($alg)
	    if { $categ == "" } {
		set categ "Other"
	    }
	    if { $grp==$categ } {
		set n [ $alg GetGUIName ]
		
		if { $num == 0 } {
		    set disp [ menu $compmenu.[ pxvtable::vnewobj ] -tearoff 0 ]
		    $compmenu add cascade -label "$grp" -menu $disp
		}

		eval "$disp add command -label \"$n\" -command { $this ShowTool $alg  } "
		lappend categorytoolarray($categ) $alg
		incr num
	    }
	}
	if { $num > 0 } {
	    $categorychoicemenu insert end "$grp"
	}
    }

}
# ----------------------------------------------------------------------------------------

itcl::body bis_treeapp::AddPlugins {  } {

    set val [ $OptionsArray(pluginfile) GetValue ]
    if { [ file exists $val ]  } {
	set pluginslist ""
	set fin [ open $val r ]
	while { [ gets $fin line ] >=0 } {
	    if { [ string first "\#" $line ]  == -1 } {
		lappend pluginslist  [ string trim $line ]
	    }
	}
	close $fin
	puts stderr "New Plugins = $pluginslist"
    }


    if { [ llength $pluginslist ] == 0 } {
	return
    }

    set tmpname [ file join /tmp [pid].xml ]
    set pluginmenu [ menu $compmenu.[ pxvtable::vnewobj ] -tearoff 0 ]
    $compmenu add cascade -label "$pluginname" -menu $pluginmenu
    $categorychoicemenu insert end "$pluginname"
    set categorytoolarray($pluginname) ""

    eval "$pluginmenu add command -label \"Add Plugin\" -command { $this AddSinglePlugin \"\" }"
    $pluginmenu add separator

    foreach tool $pluginslist {
	set alg [ $this AddSinglePlugin $tool ]
	if { $alg ==0 } {
	    puts stderr "Bad plugin $tool"
	}
    }
}

# -------------------------------------------------------------------------------------------------------------
itcl::body bis_treeapp::AddSinglePlugin { tool } { 

    if { [ string length $tool ] < 2 } {
	set typelist { {"Plugin Executable Files" { *}}}
	set fname  [tk_getOpenFile -title "Find Plugin" -filetypes $typelist ]
	if { [ string length $fname ] < 1 } {
	    return 0
	}
	set tool $fname
    }
	

    set tmpname [ file join /tmp [pid].xml ]
    set a ""
    puts stderr "Fishing for $tool"
    catch { set a [ exec $tool --xml  ] }
    puts stderr "a=$a"
    if { [ string length $a ] < 30 } {
	return 0
    }
	
    set fout [ open  $tmpname w ]
    puts $fout $a
    close $fout

    set alg [ [ bis_xmlalgorithm \#auto $tmpname ] GetThisPointer ]
    $alg SetOptionValue cmd $tool
    file delete -force $tmpname
    
    $alg InitializeFromContainer 0 $treewidget
    $alg SetBisViewer $bis_viewer
    $alg SetDataTree $treewidget
    $alg SetCategory $pluginname
    set componentcat($alg) $pluginname
    lappend categorytoolarray($pluginname) $alg

    set n [ $alg GetGUIName ]
    set v "$pluginmenu add command -label \"$n\" -command { $this ShowTool $alg  } "
    eval $v

    lappend toollist $alg

    return $alg
}
# -------------------------------------------------------------------------------------------------------------

itcl::body bis_treeapp::UpdateToolChoiceMenu { } {

    $toolchoicemenu delete 0 end
    set categ [ $categorychoicemenu get ]
    
    foreach alg $categorytoolarray($categ) {
	$toolchoicemenu insert end [ $alg GetGUIName ]
    }
}

# --------------------------------------------------------------------------------------------------------------

itcl::body bis_treeapp::ShowTool { tool } {

#    puts stderr "Tool is $tool"
    if { $tool == 0 } {
	set toolname [ $toolchoicemenu get ]
	#	puts stderr "$tool is really name of tool $toolname"
	set tool 0
	foreach t $toollist {
	    if { [ $t GetGUIName ] == "$toolname" } {
		set tool $t
	    }
	}
#	puts stderr "Found tool $tool"
	if { $tool == 0 } {
	    return 0
	}
    } else {
	
	set categ  [ $tool GetCategory]
#	puts stderr "Category of tool $tool = $categ"
	if { $categ == "" } {
	    set categ "Other"
	} elseif { $categ == "Plugin" } {
	    set categ "Slicer Plugin"
	}
#	puts stderr "Looking for $categ"
	set c [ $categorychoicemenu index $categ ]
#	puts stderr "categ=$categ,c"
	catch { $categorychoicemenu select $c }
	$this UpdateToolChoiceMenu
	set d [ $toolchoicemenu index [ $tool GetGUIName ] ]
#	puts stderr "tool=[ $tool GetGUIName] , $d"
	catch { $toolchoicemenu select $d }
    }

    set ind [ lsearch -exact $initializedtools $tool ]
    if { $ind == -1 } {
	set tp [ frame $toolbase.[pxvtable::vnewobj ]]
	$tool CreateGUI $tp
	lappend initializedtools $tool
	set toolwidgetarray($tool) $tp
    }
    
    catch { wm deiconify $toolbase }
    
    if { $currenttoolwidget ==  $toolwidgetarray($tool) } {
	return 1
    }

    if { $currenttoolwidget != 0 } {
	pack forget $currenttoolwidget
    }
    # Unload stuff in currenttool -- maybe
    if { $currenttool != 0 } {
	$currenttool ClearOutputs
    }
    #
    pack $toolwidgetarray($tool) -side top -expand true -fill both
    set currenttoolwidget $toolwidgetarray($tool)
    set currenttool $tool
    $currenttool SetBisViewer $bis_viewer
    return 1
}


# -----------------------------------------------------------------------------------------
itcl::body bis_treeapp::SetCurrentViewer { vr } {

    set bis_viewer [ lindex $viewerlist $vr ]
    set vtk_viewer [ $bis_viewer GetViewer ]
    $treewidget SetBisViewer $bis_viewer
    if { $currenttool !=0 } {
	$currenttool SetBisViewer $bis_viewer
    }
}

# -----------------------------------------------------------------------------------------
itcl::body bis_treeapp::GrabImageFromViewer { vr } {

    set v [ lindex $viewerlist $vr ]
    set img [ $v GetImage ]
    #    puts stderr "img=[ $img GetShortDescription ]"

    set elem [ $treewidget AddNewNode Image ]
    if { $elem == "" || $elem == "0" } {
	puts stdout "Failed to add element $elem"
	return 0
    }

    set datamanager [ $treewidget GetDataManager ]
    [ $elem GetAttribute PointerObject ] ShallowCopy $img
    $elem SetAttribute Filename [ $img cget -filename ]
    $elem SetAttribute Title [ file tail [ file rootname [ $img cget -filename ]] ]
    $elem SetAttribute ObjectLoaded 1
    $datamanager UpdateAttributesByList $elem { "ObjectLoaded" Filename Title }
    $treewidget  UpdateVisTree  [ $elem GetParent ]
    $treewidget  UpdateStatus 
    return 1
}

# -----------------------------------------------------------------------------------------
# CreateGUI
# ----------------------------------------------------------------------------------------

itcl::body bis_treeapp::CreateGUI { basew { callafter 0 } { callbefore 0 } } {

    set basewidget $basew
    wm geometry $basewidget 930x900
    set callbackbefore $callbefore
    set callbackafter  $callafter
    set progressbar($this) 0
    set progress_lab($this) "Status"
    set progress_val($this) 0
    set guimode "standalone"
    
    set tp $basewidget
    #    set tp [ toplevel $basewidget ];  wm withdraw $tp
    set menubase [ menu $tp.menubar -tearoff 0  ]
    $tp configure -menu $menubase
    set toolbar [ frame $tp.[ pxvtable::vnewobj ] ]
    set toolbar2 [ frame $tp.[ pxvtable::vnewobj ] -height 2 -bg black]
    pack $toolbar $toolbar2 -side top -expand false -fill x

    set nt [ panedwindow $basew.1 -orient horizontal -showhandle 1 \
		 -borderwidth 4 -relief raised -sashwidth 4 -sashpad 4 \
		 -handlesize 5 -handlepad 50  ]
    pack $nt -side top -expand true -fill both 

    set guibase  [ frame $nt.c  -width   500 ]
    set toolbase  [ frame $nt.v -width   400 ]
    $nt add $guibase -minsize  300
    $nt add $toolbase -minsize 300

    set numv 2
    for { set i 1 } { $i<= $numv } { incr i } {
	set viewbase($i)  [ toplevel $nt.c$i ]
	wm withdraw $viewbase($i)
	wm title $viewbase($i) "Viewer $i"
	wm geometry $viewbase($i) 700x700

	set bv [ [ bis_viewer \#auto ] GetThisPointer ]
	$bv configure -enable_toolbar  1
	$bv configure -enable_landmarkeditor  1
	$bv configure -enable_electrodeeditor  1
	$bv CreateGUI $viewbase($i)
	lappend viewerlist  $bv 
    }
    # Link Viewers
    for { set i 0 } { $i <= 1 } { incr i } {
	for { set j 0 } { $j <= 1 } { incr j } {
	    if { $i != $j } {
		[ lindex $viewerlist $i ]   SetLinkedCursorViewer  [ lindex $viewerlist $j ]
	    }
	}
    }

    set bis_viewer [ lindex $viewerlist 0 ]
    set vtk_viewer [ $bis_viewer GetViewer ]

    set treewidget [ [ bis_treewidget \#auto ] GetThisPointer ]
    $treewidget SetBisViewer $bis_viewer
    $treewidget configure -createtransformcontrol 1
    $treewidget CreateGUI $guibase 1  0 1

    set pref_dialog [ ::pxtcluserprefs::CreatePreferenceEditor ]

    $this CreateMenu $menubase $viewerlist 
    label $toolbar.0 -text "Current Viewer:"; pack $toolbar.0 -side left -padx 3 -expand false
    for { set i 1 } { $i <= [ llength $viewerlist ] } { incr i } {
	eval "$viewmenu add command -label \"Show Viewer $i\" -command { wm deiconify $viewbase($i)}"
	eval "radiobutton $toolbar.$i -variable  [ itcl::scope thisparam($this,currentviewer) ]  -value [ expr $i -1 ] -text \"Viewer $i\" -command { $this SetCurrentViewer [ expr $i -1 ] } "
	pack $toolbar.$i -side left -padx 2 -expand false
    }

    $viewmenu add separator
    for { set i 1 } { $i <= [ llength $viewerlist ] } { incr i } {
        eval "$viewmenu add command  -label \"Grab Image From Viewer $i\" -command { $this GrabImageFromViewer [ expr $i -1 ] } "
    }



    update
    $this AddComponents 
    $this UpdateToolChoiceMenu
    $this AddPlugins
    $this UpdateToolChoiceMenu

    if { [ string length [ $OptionsArray(treefile) GetValue  ] ] > 0  } {
	$this LoadTree [ $OptionsArray(treefile) GetValue  ]
    }


    
    eval "bind all <Control-d>  { $this ExitCommand }"
    eval "wm protocol . WM_DELETE_WINDOW { $this ExitCommand } "
    eval "wm protocol $basewidget WM_DELETE_WINDOW { $this ExitCommand  }"


    $this ShowTool 0

}




# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_treeapp.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_treeapp [pxvtable::vnewobj]]
    $alg MainFunction 
}





