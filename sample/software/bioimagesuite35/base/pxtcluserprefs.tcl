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

package provide pxtcluserprefs 1.0

# 	$Id: pxtcluserprefs.tcl,v 1.1 2002/04/29 18:05:15 papad Exp papad $	





package require pxtclutil    1.0
package require pxvtable     1.0
package require vtkpxcontrib 1.0


namespace eval ::pxtcluserprefs {

    proc LoadUserPrefs { } {
	
	global pxtcl_pref_array
	global pxtcl_pref_array_names
	global pxtcl_pref_array_list
	global env


	global env
	set fn ".bioimagesuite3"; catch { set fn $env(BIODBASE) }
	set fn [ file join $env(HOME) $fn ]
	
	set connector [ vtkbisDatabase New ]
	$connector InitializeSQLite "$fn" 
	set dbase_ok [ $connector Connect ]
	
	set usingdbase 0

	if { $dbase_ok > 0 } {
	    set dbase [ vtkbisFilenameTable New ]
	    $dbase SetConnector $connector
	    $dbase CreateTable
	    set lst [ split [ $dbase QueryAll "User_Preferences" ] "|" ]
	    

	    if { [ llength $lst ] > 0 } {
		set usingdbase 1
		for { set i 0 } { $i < [ llength $lst ] } { incr i } {
		    set line [ lindex $lst $i ]
		    set lst2 [  split $line "," ]
		    if { [ llength $lst2 ] == 3 } {
			set key   [string trim   [ lindex $lst2 1 ] ]
			set value [string trim   [ lindex $lst2 2 ] ]
			set pxtcl_pref_array($key) $value
		    }
		}
	    }
	    $dbase Delete
	}
	$connector Delete
	
	# -----------------------------------------------------------------------

	if { $usingdbase == 0 } {
	    # Read from file as before
	    set f [ GetUserPrefName ]
	    if { [ file  exists $f ] !=0 } {
		::pxtclutil::ReadArray $f pxtcl_pref_array "#BioImageSuite_Preferences"
	    }
	}

	set remove_list ""
	foreach { key value } [array get pxtcl_pref_array] {
	    set l2   [ array get pxtcl_pref_array_list $key ]
	    if { [ llength $l2 ] != 2 } {
		set remove_list [ lappend $remove_list  $key ]
	    }
	}
	for { set k 0 } { $k < [ llength $remove_list ] } { incr k } {
	    array unset pxtcl_pref_array [ lindex $remove_list $k ]
	}

	    
	if { $pxtcl_pref_array(FmriMode) == "64" } {
	    set pxtcl_pref_array(FmriMode) F1
	} elseif { $pxtcl_pref_array(FmriMode) == "256" } {
	    set pxtcl_pref_array(FmriMode) F2
	}
	
	if { $pxtcl_pref_array(VolumeTextureMode) == 1 } {
	    set pxtcl_pref_array(VolumeTextureMode) 2
	}

	if { $usingdbase == 0 && $dbase_ok > 0 } {
	    SaveUserPrefs
	}


	# ---------------------------------------------
	#	::pxtclutil::PrintArray pxtcl_pref_array
    }

    # ---------------------------------------------------------------------------------

    proc SaveUserPrefs { } {

	global env
	set fn ".bioimagesuite3"; catch { set fn $env(BIODBASE) }
	set fn [ file join $env(HOME) $fn ]
	global pxtcl_pref_array	

	set connector [ vtkbisDatabase New ]
	$connector InitializeSQLite "$fn" 
	set ok [ $connector Connect ]
	
	set usingdbase 0

	if { $ok > 0 } {
	    set dbase [ vtkbisFilenameTable New ]
	    $dbase SetConnector $connector
	    $dbase DeleteAll "User_Preferences"
	    
	    foreach { key value } [ array get pxtcl_pref_array ] {
		$dbase AddItem "User_Preferences" $key $value 
	    }
	    $dbase Delete
	    set usingdbase 1
	}
	$connector Delete
	
	if { $usingdbase == 0 } {
	    set f [ GetUserPrefName ]
	    ::pxtclutil::SaveArray $f pxtcl_pref_array "#BioImageSuite_Preferences"
	}
    }


    proc GetUserPrefName { } {

	global env
	set fn ".bioimagesuite3"; catch { set fn $env(BIODBASE) }
	set fn [ file join $env(HOME) $fn ]
	
	set a ".bioimagesuite"
	catch { set a $env(BIOIMAGESUITECONF) }
	return [ file join $env(HOME) $a ]
    }

    proc EnsureUserPrefs { } {
	global pxtcl_pref_array
	global pxtcl_pref_array_names

	if { $pxtcl_pref_array(VectorVisionLink) == "Enabled" } {
	    set vvl 0
	    catch { 
		set vvl [ vtkpxVVLinkConnectorNew [ pxvtable::vnewobj ] ]
		$vvl Delete
		set vvl 1
	    }

	    if { $vvl == 0 } {
		 set pxtcl_pref_array(VectorVisionLink)  "Disabled"
	     }
	 }

	if { $pxtcl_pref_array(MincImageFormat) == "Enabled" } {
	    set minc 0
	     catch { 
		 set minc [ vtkMINC2ImageReader [ pxvtable::vnewobj ] ]
		 $minc Delete
		 set minc 1
	     }
	     if { $minc == 0 } {
		 set pxtcl_pref_array(MincImageFormat)  "Disabled"
	     } 
	} 

	if { $pxtcl_pref_array(MincImageFormat) == "Disabled" } {	    
	    set pxtcl_pref_array(MincImageFormatDefault) 0
	}
    }

    proc Init { }  {
	global pxtcl_pref_array
	global pxtcl_pref_array_list
	global pxtcl_pref_array_names
	global tcl_platform

	catch { array  unset pxtcl_pref_array }

	# Set Default Values 
	# ------------------

	# -----------------   Set 1 ---------- Look and Feel

	set pxtcl_pref_array(ColorScheme) "System Default"
	set pxtcl_pref_array_list(ColorScheme) [ list "System Default" "BioImage Suite Blue" "Bisque" "High Contrast" ]
	set pxtcl_pref_array(FontSelection) "System Default"
	set pxtcl_pref_array_list(FontSelection) [ list "System Default" "Small" "Medium" "Large" "Extra Large" ]
	set pxtcl_pref_array(MirrorConsole) 0
	set pxtcl_pref_array_list(MirrorConsole) [ list "0" "1" ]

	lappend pxtcl_pref_array_names [ list "Look & Feel" "ColorScheme" "FontSelection" "MirrorConsole" ]

	# -----------------   Set 2 ---------- File Formats etc

	set pxtcl_pref_array(ForceOutputFormat) "Auto" 
	set pxtcl_pref_array_list(ForceOutputFormat) [ list "Auto" "Analyze" "NIFTI" ]

	set pxtcl_pref_array(DefaultImportMode) "Binary"
	set pxtcl_pref_array_list(DefaultImportMode) [ list "Signa LX" "Binary" "Raw MR" "Analyze" "Prism (SPECT)" "DICOM" "Signa Spr" "Nmr47" "TIFF" "PNM" "BMP"  ]

	set pxtcl_pref_array(ForceBISOrientationsOnLoad) "On" 
	set pxtcl_pref_array_list(ForceBISOrientationsOnLoad) [ list "On" "Off" ]

	set pxtcl_pref_array(MincImageFormat) "Enabled"
	set pxtcl_pref_array_list(MincImageFormat) [ list  "Disabled" "Enabled" ]

	lappend pxtcl_pref_array_names [ list "File Formats" "ForceOutputFormat" "DefaultImportMode" "ForceBISOrientationsOnLoad" "MincImageFormat"  ]

	# ----------------- Set 2.5 ------------ Coordinates

	set pxtcl_pref_array(ManualTalairach) "Off"
	set pxtcl_pref_array_list(ManualTalairach)  [ list "On" "Off" ]

	set pxtcl_pref_array(WFUAtlasAutoInitialize) "Disabled" 
	set pxtcl_pref_array_list(WFUAtlasAutoInitialize) [ list  "Disabled" "Enabled"  ]

	set pxtcl_pref_array(YaleAtlasAutoInitialize) "Disabled" 
	set pxtcl_pref_array_list(YaleAtlasAutoInitialize) [ list  "Disabled" "Enabled" ]

	lappend pxtcl_pref_array_names [ list "Coordinates"  "WFUAtlasAutoInitialize" "YaleAtlasAutoInitialize"  "ManualTalairach" ]


	# -----------------   Set 3 ---------- Image Display
	set pxtcl_pref_array(VolumeTextureMode) 2
	set pxtcl_pref_array_list(VolumeTextureMode) [ list "0" "2" "3" ]

	set pxtcl_pref_array(FmriMode) F2
	set pxtcl_pref_array_list(FmriMode) [ list "F1" "F2" "F4" ]
	
	set pxtcl_pref_array(NormalizeAnatomical) 1
	set pxtcl_pref_array_list(NormalizeAnatomical) [ list "0" "1" ]

	set pxtcl_pref_array(ImageColormaps) "0"
	set pxtcl_pref_array_list(ImageColormaps) [ list "0" "1" ]

	set pxtcl_pref_array(Interpolation) "Linear"
	set pxtcl_pref_array_list(Interpolation) [ list "NearestNeighbor" "Linear" "Cubic" ]

	lappend pxtcl_pref_array_names [ list "Image Display" "NormalizeAnatomical" "ImageColormaps" "Interpolation" "VolumeTextureMode" "FmriMode"  ]

	# -----------------   Set 4 ---------- Surface Editor

	set pxtcl_pref_array(SurfaceEditorMaxSurfaces) "4"
	set pxtcl_pref_array_list(SurfaceEditorMaxSurfaces) [ list "2" "4" "8" "12" "20" "30" "45" ]

	set pxtcl_pref_array(SplineEditorControlPointScale) "4"
	set pxtcl_pref_array_list(SplineEditorControlPointScale) [ list "1" "2" "3" "4" "5" "6" "7" "8" ]

	set pxtcl_pref_array(ObjectMapVOIMode) "Normal"
	set pxtcl_pref_array_list(ObjectMapVOIMode) [ list "Normal" "Fat1" "Fat2" "Custom" ]
	
	lappend pxtcl_pref_array_names [ list "Surface Editing" "SurfaceEditorMaxSurfaces" "SplineEditorControlPointScale" "ObjectMapVOIMode" ]


	# -----------------   Set 5 ---------- Advanced Misc

	set pxtcl_pref_array(FSLVersion) "4.0 (or older)"
	set pxtcl_pref_array_list(FSLVersion) [ list "4.0 (or older)" "4.1" ]

	set pxtcl_pref_array(RigidRegistration) "Normal"
	set pxtcl_pref_array_list(RigidRegistration) [ list "Normal" "Stitch" ]

	set pxtcl_pref_array(VectorVisionLink) "Disabled"
	set pxtcl_pref_array_list(VectorVisionLink) [ list "Disabled" "Enabled" ]

	set pxtcl_pref_array(OpenIGTLink) "Disabled"
	set pxtcl_pref_array_list(OpenIGTLink) [ list "Disabled" "Enabled" ]
	
	set pxtcl_pref_array(EnableBetaFeatures) "Disabled"
	set pxtcl_pref_array_list(EnableBetaFeatures)  [ list "Disabled" "Enabled" ]

	lappend pxtcl_pref_array_names [ list "Advanced/Miscelleneous" "FSLVersion" "RigidRegistration" "VectorVisionLink"  "OpenIGTLink" "EnableBetaFeatures" ]

	# Modify for each platform
	# ------------------------
# 	if { $tcl_platform(byteOrder) == "littleEndian" } { 
# 	    set pxtcl_pref_array(SwapOnSave) 1
# 	}

# 	if { $tcl_platform(platform) == "windows" } {
# 	    set pxtcl_pref_array(TextureMode) 0
# 	}
	
    }


    proc CreatePreferenceEditor  { } {

	global pxtcl_pref_array
	global pxtcl_pref_array_list
	global pxtcl_pref_array_names

	set comment "Global Preferences for Ipag BioImageSuite"
	set comment2 "([::pxtcluserprefs::GetUserPrefName])"  
	set comment3 "Changes will take effect when the application is restarted!"
	set loadcommand "::pxtcluserprefs::LoadUserPrefs" 
	set savecommand "::pxtcluserprefs::SaveUserPrefs" 
	set resetcommand "::pxtcluserprefs::Init" 

	set top [ pxvtable::vnewobj]
	set dlg [ toplevel .$top ]
	wm geometry .$top 600x280
	wm withdraw $dlg
	wm title $dlg "BioImage Suite User Preferences"

	label $dlg.o -bg black -fg white -text $comment
	#	label $dlg.o2 -bg black -fg white -text $comment2
	label $dlg.o3 -bg black -fg white -text $comment3
	pack $dlg.o $dlg.o3 -side top -expand f -fill x -pady 0

	frame $dlg.bot  
	pack $dlg.bot -side bottom -pady 5 -expand t -fill x

	frame $dlg.o4 -height 4 -bg black
	pack $dlg.o4 -side bottom -expand t -fill x -pady 2

	set notebook [ iwidgets::tabnotebook $dlg.mid  -tabpos w -gap 2 -margin 2 -raiseselect true]
	pack $notebook -side top -expand t -fill both -pady 2

	set listlen [ llength $pxtcl_pref_array_names ]

	set c 0

	set defname ""

	for { set i 0 } { $i < $listlen } { incr i } {

	    set keylist [ lindex $pxtcl_pref_array_names $i ]
	    set len     [ llength $keylist ]
	    set nname   [ lindex $keylist 0 ]

	    set fr [ $notebook add -label $nname ]

	    if { $i == 0 } {
		set defname $nname 
	    }

	    for { set k 1 } { $k < $len } { incr k } {
		set name [ lindex $keylist  $k ] 
		frame $fr.$c
		pack $fr.$c -side top -expand t -fill x
		
		label $fr.$c.l -text $name -width 25
		eval "tk_optionMenu $fr.$c.e  pxtcl_pref_array($name) $pxtcl_pref_array_list($name)"
		pack $fr.$c.l $fr.$c.e -side left -expand f -padx 2 -fill x -pady 0
		incr c
	    }
	}
	
	eval "button $dlg.bot.close -text Close -command { wm withdraw $dlg }"
        eval "button $dlg.bot.load -text ReLoad -command { $loadcommand }"
        eval "button $dlg.bot.save -text Save   -command { $savecommand }"
        eval "button $dlg.bot.def -text Defaults   -command { $resetcommand }"
	
	pack $dlg.bot.load $dlg.bot.save $dlg.bot.def $dlg.bot.close -side left -expand t -padx 20 -fill x
	eval "wm protocol $dlg WM_DELETE_WINDOW { wm withdraw $dlg }"

	$notebook view $defname
	return $dlg


    }

    # -------------------------------------------------------------------------
    # Initialize Color Schemes 
    # -------------------------------------------------------------------------
    
    proc InitializeBioImageSuiteColorAndFontScheme { } {

	global pxtcl_pref_array
	option clear



	switch -exact  $pxtcl_pref_array(ColorScheme) {
	    "BioImage Suite Blue"  {
		option add *foreground  "\#400000"
		option add *selectColor  "\#d00000"
		option add *disabledForeground  black
		option add *activeForeground   "\#d00000"

		option add *background  "\#cccdf8"
		option add *textBackground  "\#cccdf8"
		option add *scaleBackground  "\#cccdf8"
		option add *backdrop    "\#cccdf8"
		option add *activeBackground "\#cccdf8"
		option add *highlightBackground "\#cccdf7"

		option add *disabledBackground  "\#bbbce7"
		option add *highlightColor  "\#bbbce7"
		option add *selectBackground  "\#bbbce7"
		
		option add *readonlybackground  "\#8197c5"
		option add *tabBackground  "\#8197c5"
		option add *troughColor  "\#8197c5"
		option add *highlightColor      "\#8197c5"
		
	    } "Bisque" {
	    
		tk_bisque
		option add *background  "#ffe4c4"
		option add *tabBackground  "#ccb4a4"
		option add *textBackground "#ffe4c4"
		option add *scaleBackground "#ffe4c4"
		option add *backdrop "#ffe4c4"
		option add *activeBackground "#ffe4c4"
		option add *highlightBackground "#ffe4c4"
		
		option add *disabledBackground  "\#eed4b4"
		option add *disabledForeground  darkgray

	    } "High Contrast" { 
	    
		option add *background  "#ffffff"
		option add *tabBackgrod  "#ffffff"
		option add *textBackground "#ffffff"
		option add *scaleBackground "#ffffff"
		option add *backdrop "#ffffff"
		option add *activeBackground "#ffffff"
		option add *highlightBackground "#ffffff"
		
		option add *selectColor  "\#d00000"
		option add *disabledForeground  "\#505050"
		option add *activeForeground   "\#202020"
		
		option add *disabledBackground  "\#bbbbbb"
		option add *highlightColor  "\#bbbbbb"
		option add *selectBackground  "\#bbbbbb"
		
		option add *readonlybackground  "\#cccccc"
		option add *tabBackground       "\#cccccc"
		option add *troughColor         "\#cccccc"
		option add *highlightColor      "\#cccccc"
	    } 
	}
	
	switch -exact $pxtcl_pref_array(FontSelection) {
	    "Small"  {  option add *font { Helvetica 8 bold } }
	    "Medium" {  option add *font { Helvetica 9 bold } }
	    "Large"  {  option add *font { Helvetica 10 bold } }
	    "Extra Large" { option add *font { Helvetica 12 bold } }
	}
    }
}

::pxtcluserprefs::Init
::pxtcluserprefs::LoadUserPrefs
::pxtcluserprefs::EnsureUserPrefs
::pxtcluserprefs::InitializeBioImageSuiteColorAndFontScheme



