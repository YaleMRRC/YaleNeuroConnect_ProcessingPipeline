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

package provide bis_algorithm 1.0

#
# bis_algorithm.tcl
# 
#  Do we want to add
#
#  bis_optionslist class
#  bis_objectlist  class
#
#

package require  Itcl
#package require  biscmdline

package require bis_option 1.0
package require bis_object 1.0
package require bis_common 1.0

package require bis_basealgorithm 1.0
package require bis_algorithmdbaseinterface 1.0

package require Iwidgets 
package require feedbackplus 1.0
package require pxitclobject 1.0
package require pxtclhelp 1.0
package require  labelframe 1.0
package require bis_viewer 1.0
#
# bis_algorithm class
#

itcl::class bis_algorithm {

    inherit bis_basealgorithm

    #
    #public
    #
    constructor { } { set progressbar($this)  0 }

    # --------------------------------------------------------------------
    #  Methods to ovverride 
    # --------------------------------------------------------------------

    # This is the entry point method where the algorithm execution is
    # --------------------------------------------------------------------
    public method  Execute { } {
	puts stdout "Nothing to run .. .this is bis_algorithm "
    }

    # ------------------------------------------------------------------
    # This method is used to create dialog title bars etc.
    public method GetGUIName    { } { return $scriptname }

    # This needs to be redefined by those algorithms  (e.g. surfacetosurface)
    # which need a data control in standalone mode
    public method NeedsCustomDataControl { } { return 0 }
    public method CreateCustomDataControl { w } { return 0 }


    # Check Input Objects before execution -- i.e. ensure images exist etc
    # -------------------------------------------------------------------
    public method CheckInputObjects { } { return 1 }


    # -------------------------------------------------------------------
    # This methods is called by UpdateProgress events on filters properly
    # configured -- using the SetFilterCallbacks method
    # -------------------------------------------------------------------
    public method ProgressCallback   { filter lab } 


    # -------------------------------------------------------------------
    # GUI Stuff -- pack options is probably the first one to look at 
    # -------------------------------------------------------------------

    # Create Input/Output GUI Controls for Objects in standalone mode
    public method CreateGUI { parent { callafter 0 } { callbefore 0 } { testingmode 0 } }
    public method SetMainTabNotebook { nt  } {  set maintabnotebook $nt }
    public method SetMainTabScrollMode { md  } {  set maintabscrollmode $md }


    public method GetBaseWidget { } { return $basewidget }
    public method GetViewerBaseWidget { } { return $viewerbasewidget }
    public method GetGUIBaseWidget { } { return $guibasewidget }
    public method GetParameterBar { } { return $parameterbar }

    protected method CreateStandaloneGUI { { testingmode 0  } }
    protected method CreateManagedGUI { }
    protected method CreateDataTreeGUI { }

    
    # Componet GUIs
    protected method CreateInputGUIInterface { fr }
    protected method CreateOutputGUIInterface { fr }
    protected method CreateOptionsGUIInterface { fr }
    protected method PackOptionsGUIInterface { lst }
    protected method ConfigureOptionsGUICallbacks { } { return 0 }



    # Create applet superstructure -- perhaps this needs to move out
    # --------------------------------------------------------------
    protected method CreateMenuBar { fr }
    protected method CreateViewer { fr }
    public method SetViewer { vtk_vr }
    public method SetBisViewer { bis_vr }



    # This method is used to initialize from the GUI from a container
    public method InitializeFromContainer { container { eventcontainer 0 } }

    # This method is used to initialize for a standalone GUI Application
    public method InitializeStandalone { }
    public method InitializeTesting    { { dogui 0 } }

    # This is called from each derived class's main function
    public method  RunCommandLine { parameterlist commandline }

    # This is function for running ctest with associated help functions
    public method RunRegressionTests { fname args }
    # This reads the custom filename containing all tests
    protected method LoadTestFileName { fname { lineno -1 } }
    protected method DualPrint { line { fout 0 } { usescriptname 1 } }
    protected method ReformatTestLine { line { extra "" } }
    protected method DoTestComparison { alg comparenames { fout 0  }  { ctestcreategold 0 } }
    protected method DoTestGUIComparison { alg comparenames { fout 0  }  { ctestcreategold 0 } }
    protected method RunTest { testline basedir { fout 0  } { extra ""} { ctestcreategold 0 } }
    protected method CreateTempOutputDirectory { inp }
    protected method RemoveTempOutputDirectory { tmp }


    # This method is used to pass arguments as strings
    public method  SetParameterList { parameterlist }

    # This is the Main Function for all scripts
    public method MainFunction {  }

    # Command line processing
    protected method StripDashes { ln }
    protected method ProcessCommandline { argv { debug 0 } }

    #Internal flags as to whether some gui element objects exist
    protected variable hasinputguis  0 
    protected variable hasoutputguis 0 

    
    #Add Default Options -- these are for GUI related issues
    protected method AddDefaultOptions { {addgui 1 } }


    # GUI Stuff
    # 
    # GUI Mode should be one of managed, standalone, commandline (other maps to commandline)
    public method  SetGUIMode { md }
    public method  GetGUIMode { } { return  $guimode   }
    public method  GetViewer  { } 
    public method  GetBisViewer  { } 
    public method  GetBisViewerImage  { { magnification 1 } } 



    # Show Outputs in GUI even if managed
    protected variable showoutputsmode 0
    public method  SetShowOutputsMode { md } { set showoutputsmode [ expr $md > 0 ]}
    public method  GetShowOutputsMode { } { return  $showoutputsmode   }

    # Get Info about Algorithm for use in GUI Container
    public method IsImageToImage { }
    public method SetContainer { cont }  { set containerobject $cont }
    public method GetContainer { }  { return $containerobject }
    public method SetDataTree { cont }  { set datatree $cont ; $this SetGUIMode datatree }
    public method GetDataTree { }  { return $datatree }
    public method UpdateInputsFromContainer { } { return 0 }
    public method UpdateContainerWithOutput { } { return 0 }



    # These methods may not to be changed in derived classes
    public method GetFirstInputObject  { }
    public method GetSecondInputObject  { }
    public method GetThirdInputObject { }
    public method GetFourthInputObject { } 

    public method GetFirstOutputObject { }
    public method GetOutputObjectByIndex { { index 0 } }
    public method GetOutputObjectNameByIndex { { index 0 }}

    
    # Invokation Stuff
    public method InvokeAlgorithmFromGUI { }
    public method ShowCommandLine { }
    public method GetCommandLine { { mode short } }
    public method GetSlicerXMLDescription { }
    public method GetJSONDescription { }
    public method GetJSONParameters { mode }
    public method GetJSONInputs { }
    public method GetJSONOutputs { }

    public method GetLONIXMLDescription { { mode 1 } }
    public method ShowLongDescription { }

    

    protected variable executename "Run Algorithm"
    protected variable callbackafter 0
    protected variable callbackbefore 0
    protected common thisparam
    protected variable aboutdialog 0
    protected variable helpdialog 0
    protected variable basewidget 0
    protected variable viewerbasewidget 0
    protected variable guibasewidget 0
    protected variable parameterbar 0
    protected variable vtk_viewer 0
    protected variable bis_viewer 0
    protected variable bis_viewer_type ortho
    protected variable bis_viewer_edit 1
    protected variable maintabnotebook 0
    protected variable createviewermode 1
    protected common   dbaseinterface 0
    protected variable datatree 0
    protected variable forceguimode 0
    protected variable maintabscrollmode 1

    # More GUI Stuff -- Progress Bar
    public method CreateProgressBar { w } 
    public method ShowProgress       { filter lab } 
    public method ShowProgressVal    { name   val }
    public method SetFilterCallbacks { filter comment } 

    # Dbase Module
    protected method PrintMessage { msg } 
    protected method ErrorMessage { msg { titlemessage "Error Message" } }
    public    method SetParametersFromString { line }
    protected method HandleParameterSetArgument { plist } 

    public method ResetParameters { }
    public method LoadParameters { {fname "" }}
    public method SaveParameters { {fname "" }}
    public method QueryParameters { psetname }
    protected method CreateDatabaseConnector {  }
    public method ShowDatabaseGUI { mode }



    # Method to add logo label to something 
    public proc   AddLogoLabel { w }
    public method ExitCommand { }
    public method AboutCommand { }
    public method HelpCommand { }
    public method SetCurrentDirectory { { newdir ""  } }
    public method WatchOn { } 
    public method WatchOff { } 

    # Enable/Disable pieces of the User Interface
    public proc   DisableWidget { widget  }
    public proc   DisableUI     { widgetlist }
    public proc   EnableWidget { widget }
    public proc   EnableUI     { widgetlist  }
    public proc   SetStateOfWidget { widget mode }
    public proc   SetStateOfUI     { widgetlist mode  }

    # Configure Whole Trees
    public proc   ConfigureWidgetTree { widget optionlist }
    public proc   SetWidgetTreeColors { widget backc forec }



    # Common Variables
    public    variable version 3.0a
    public    variable aboutstring "(c) X. Papademetris, M. Jackowski, D. Scheinost, A.Joshi, H.Okuda, R.T. Constable, L.H. Staib 1995-2011\nSection of Bioimaging Sciences, Department of Diagnostic Radiology, Yale University School of Medicine\n\n\nThis application is intended for research applications only! Use at your OWN RISK. If used for publication please acknowledge, see the webpage for more details. For additional support please visit the BioImage Suite forum at:\n\thttp://research.yale.edu/bioimagesuite/forum/\n " 

    
    # Variables attached to progress bar
    private common progressbar 
    private common progress_lab 
    private common progress_val 
    protected variable progress_status -1

    # --- end method def -----
    protected common ignoreflag { dogui pset ctest ctestgui ctestline ctestcreategold ctestexact ctestthr ctestsave ctestdebug ctesttmpdir slicermode }
    protected common ignoreflagslicer { pset ctest ctestgui ctestline ctestcreategold ctestexact ctestthr ctestsave ctestdebug ctesttmpdir loni }
    protected common ctestextraflags {  ctestexact ctestthr ctestsave ctesttmpdir }


}


#----------------------------------------------------
# GUI Stuff
#----------------------------------------------------
itcl::body bis_algorithm::AddDefaultOptions { { addgui 1 } } {

    if { $addgui == 1 } {

	lappend options [ list dogui "Enable the creation of a graphical user interface" "dogui"   boolean     0 { 0 1 }  -10002 ]
	lappend options [ list pset  "Use Parameter set to set parameters" "pset"   string  "" "" -10000 ]
	lappend options [ list slicermode "This signifies that the algorithm is being invoked by Slicer. It affects default save formats."  "slicermode" boolean 0 { 0 1 }  -10020 ]
	if { $forceguimode == 0 } {
	    lappend options [ list loni "Create xml output  for loni pipeline and exit (1=module group,2=module)"  "loni" integer 0 { 0 2 }  -10021 ]
	    lappend options [ list ctest "Enable the running of ctest automated testing. If argument is specified then the script is invoked in test mode and using the argument as the text file containing the test definitions"  "ctest" { filename readfile } 0 { }  -10003 ]

	    lappend options [ list ctestline "(Use only in software testing mode) If set to a positive integer then the only test that is run corresponds to the appropriate line in the testfile"  "Test LineNo:" integer -1 { -1 9999} -11001 ]
	    lappend options [ list ctestsave "(Use only in software testing mode) If enabled then save results of computation otherwise discard after testing is performed"  "Save Test Results" boolean 0 { 0 1 }  -11002 ]
	    lappend options [ list ctesttmpdir "(Use only in software testing mode) Output directory to save temporary output testing files, if not set default filenames are generated from the input filenames"  "Debug Directory" { filename directory } "" {  } -11003 ]
	    lappend options [ list ctestexact "(Use only in software testing mode) If enabled then comparison is done via subtraction else correlation (images) or correspondence error (surfaces) is used"  "Exact Test" boolean 1 { 0 1 }  -11004 ]
	    lappend options [ list ctestthr   "(Use only in software testing mode) Threshold for subtraction or correlation" "Test Threshold" real 0.002 { 0 100000 }  -11005 ]
	    lappend options [ list ctestdebug "(Use only in software testing mode) If set to non empty then a textfile is created with debug output"  "Debug Filename" { filename writefile } "" { text { .txt } } -11006 ]

	    lappend options [ list ctestcreategold "(Use only in software testing mode) If set to 9999 then the test saves its result as a gold standard. Use with extreme care"  "Test LineNo:" integer 0 { 0 9999} -11007 ]
	    lappend options [ list ctestgui "(Use only in software testing mode) If set to 1 then the testing is done in GUI mode and the comparison is based on the viewer output"  "Test GUI:" integer 0 { 0 1} -11008 ]
	}
    }
    $this CreateOptionsArray
}

# --------------------------------------------------
# Set GUI Mode
# --------------------------------------------------

itcl::body bis_algorithm::SetGUIMode { md } {

    set guimode "commandline"

    switch $md { 
	"managed"        { set guimode "managed" }
	"standalone"     { set guimode "standalone" }
	"datatree"       {  set guimode "datatree" }
    }
}



#----------------------------------------------------
# This is called from each derived class's main function
#----------------------------------------------------
itcl::body bis_algorithm::RunCommandLine { parameterlist commandline } {
    
    $this SetGUIMode commandline
    set ret [ $this CreateVTKObjects ]
    set ret [ $this SetArguments $parameterlist $commandline ]

    if { $ret == 1 } {	set ret [ $this LoadObjects ] }
    if { $ret == 1 } {  set ret [ $this CheckInputObjects ] }
    if { $ret == 1 } {	set ret [ $this Execute ]     }
    if { $ret == 1 } {  set ret [ $this SaveObjects ] } 
    if { $ret == 0 }  {  
	PrintUsage; puts stderr "\n\n------------------------------------------------------\nTHE FOLLOWING ERROR HAS OCCURRED:\n\t $errormessage\n"  
    }  else {
	puts stdout "\n $resultmessage"
    }
    $this CleanAll
}


# -------------------------------------------------------------------------------------------
#  
#    Application level GUI Functionality
#
# -------------------------------------------------------------------------------------------

::itcl::body bis_algorithm::SetStateOfWidget { widget state } {
    
    set children [ winfo children $widget ]
    set a [ llength $children ]
    if { $a == 0 } {
	catch { $widget configure -state $state  }
	return 0
    } else {
	for { set i 0 } { $i < $a } { incr i } {
	    SetStateOfWidget [ lindex $children $i ] $state
	}
    }
}
# ----------------------------------------------------------

::itcl::body bis_algorithm::ConfigureWidgetTree { widget optionlist } {

    catch { eval "$widget configure $optionlist" }

    set children [ winfo children $widget ]
    set a [ llength $children ]
    if { $a == 0 } {
	catch { eval " $widget configure $optionlist" }
	return 0
    } else {
	for { set i 0 } { $i < $a } { incr i } {
	    ConfigureWidgetTree [ lindex $children $i ] $optionlist
	}
    }

}
# ----------------------------------------------------------
itcl::body bis_algorithm::SetWidgetTreeColors { widget backc forec } {

    ::bis_algorithm::ConfigureWidgetTree $widget "-bg $backc"
    ::bis_algorithm::ConfigureWidgetTree $widget "-fg $forec"
    ::bis_algorithm::ConfigureWidgetTree $widget "-highlightbackground $backc"
    ::bis_algorithm::ConfigureWidgetTree $widget "-highlightcolor $forec"
}
# ----------------------------------------------------------
::itcl::body bis_algorithm::SetStateOfUI { disablelist state } {
	
    set a [ llength $disablelist ]
    for { set i 0 } { $i < $a } { incr i } {
	SetStateOfWidget [ lindex $disablelist $i ] $state
    }
}
# ----------------------------------------------------------	
::itcl::body bis_algorithm::DisableWidget { widget  }    { ::bis_algorithm::SetStateOfWidget $widget disabled }
::itcl::body bis_algorithm::DisableUI     { widgetlist } { ::bis_algorithm::SetStateOfUI $widgetlist disabled }
::itcl::body bis_algorithm::EnableWidget  { widget }     { ::bis_algorithm::SetStateOfWidget $widget normal   }
::itcl::body bis_algorithm::EnableUI      { widgetlist } { ::bis_algorithm::SetStateOfUI $widgetlist normal   }

# ----------------------------------------------------------
::itcl::body bis_algorithm::WatchOn { } {

    $basewidget config -cursor watch; 
    
    if { $containerobject != 0 } {
	catch { $containerobject WatchOn }
    }
}
# ----------------------------------------------------------
::itcl::body bis_algorithm::WatchOff { } {

    $basewidget config -cursor ""
    ShowProgressVal "Done" 0.0
    if { $containerobject !=0 } {
	catch { 
	    $containerobject WatchOff
	    $containerobject ShowProgressVal "Done" 0.0
	}
    }
}

# -------------------------------------------------------------------------------------------
# Dbase Module
# -------------------------------------------------------------------------------------------
itcl::body bis_algorithm::PrintMessage { msg }  {

    if { $guimode ==  "commandline" } {
	puts -nonewline stdout $msg
    } else {
	pxtkprint $msg
    }

    return 1
}

# -------------------------------------------------------------------------------------------

itcl::body bis_algorithm::ErrorMessage { msg { titlemessage "Error Message" } } {

    
    if { $guimode ==  "commandline" } {
	set errormessage "$msg"
	return 0
    }
    tk_messageBox -type ok -message $msg -title $titlemessage -icon error
    return 1
}

# ------------------------------------------------------------------------------------------
itcl::body bis_algorithm::ResetParameters {  } {

    set names [array names OptionsArray]
    foreach name $names {
	$OptionsArray($name) SetValue [ $OptionsArray($name) GetDefaultValue ]
    }
    return [ $this UpdateInputsFromContainer ]
}

# ------------------------------------------------------------------------------------------
itcl::body bis_algorithm::SetParametersFromString { line } {

    set cmd $scriptname
    if { [ file extension $cmd ] != ".tcl"  } {
	set cmd "${cmd}.tcl"
    }

    if {  [ lindex $line 0 ] != $cmd  } {
	return [ $this ErrorMessage "Bad Parameter String for algorithm $cmd != [ lindex $line 0 ]"  "Bad Parameter File!" ]
    }

    set n [ expr [ llength $line ] -1 ]
    if { [ expr 2*int($n/2) != $n ] } {
	return [ $this ErrorMessage "Need even number of parameters ... ignoring $line" "Bad Parameter File!" ]
    }



    for { set i 1 } { $i < $n } { incr i } {
	set option  [ string range [ lindex $line $i ] 1 end ]

	for { set j 0 } { $j <=1 } { incr j } {
	    set t [ string first "-"  $option  ]
	    if { $t >=0 } {
		set option [ string range $option 1 end ]
	    } 
	}
	

	incr i
	set val    [ lindex $line $i ] 

	set opt [ string range $option 0 2 ]
	if { $opt != "inp" && $opt != "out" } {
	    $this SetOptionValue $option $val
#	    puts stderr "Setting $option =$val"    
	} else {	
#	    puts stderr "Ignoring $option =$val"    
	}    }
    return 1

}
# --------------------------------------------------------------------
itcl::body bis_algorithm::HandleParameterSetArgument { plist }  {

    set found [ lsearch $plist pset ]
    
    if { $found == -1 } {
	puts stderr "pset not found"
	return 0
    }

    set indx [ expr $found +1 ]
    if { $indx < [ llength $plist ] } {
	set pname  [ lindex $plist $indx ]
	if { $pname == "" } {
	    return 1
	}
    }

    if { [ file exists $pname ] == 1 } {
	return [ $this LoadParameters $pname ]
    }  

    set out [ $this QueryParameters $pname ]

    if { [ string length $out ] > 0 } { 
	if { $guimode ==  "commandline" } {
	    puts stdout "Setting Parameters from database, preset=\"$pname\" ($out)"
	}

	return [ $this SetParametersFromString $out ]
    }
    
    return [ $this ErrorMessage "Parameter set $pname (either as file or as database entry) does not exist" ]
}

# --------------------------------------------------------------------

itcl::body bis_algorithm::LoadParameters { {fname "" }} {

    if { $fname == "" || [ file exists $fname ] ==0 } {
	set valuerange { 
	    {"Parameter Files" {.param}} 
	    {"All Files" {*}}}
	
	set fname  [tk_getOpenFile -title "Select Parameter File" -filetypes $valuerange ]
    }

    if { $fname == "" } {
	return 0
    }

    if { [ file readable $fname ] == 0 } {
	return 0
    }


    set fileid [open $fname r]
    gets $fileid line
    if { [string compare $line "#bis_algorithm parameter file" ] !=0 } {
	close $fileid
	return [ $this ErrorMessage "Bad Parameter File $fname"  "Bad Parameter File!" ]
    }
    gets $fileid line
    close $fileid


    if { $guimode ==  "commandline" } {
	puts stdout "Setting Parameters from file=$fname ($line)"
    }

    return [ $this SetParametersFromString $line ]
}

itcl::body bis_algorithm::SaveParameters { {fname "" }} {

    if { $fname == "" || [ file exists $fname ] ==0 } {
	set valuerange { 
	    {"Parameter Files" {.param}} 
	    {"All Files" {*}}}
	
	set fname  [tk_getSaveFile -title "Select Parameter File" -filetypes $valuerange ]
    }

    if { $fname == "" } {
	return 0
    }

    set fout [ open $fname w ]
    puts $fout "#bis_algorithm parameter file"
    puts $fout [ $this GetCommandLine paramset ]
    close $fout
    return 1
}
# -------------------------------------------------------------------------------------------
itcl::body bis_algorithm::QueryParameters { psetname } {

    $this CreateDatabaseConnector
    return [ $dbaseinterface FindPreset $psetname ]
}


itcl::body bis_algorithm::CreateDatabaseConnector { } {

    if { $dbaseinterface ==0 } {
	set dbaseinterface  [ [ bis_algorithmdbaseinterface \#auto ] GetThisPointer ]
    }
    if { [ $dbaseinterface GetAlgorithm ]  != $this  } {
	$dbaseinterface SetAlgorithm $this
    }
    return $dbaseinterface
}

itcl::body bis_algorithm::ShowDatabaseGUI { mode } {

    $this CreateDatabaseConnector 
    $dbaseinterface CreateGUI $basewidget 1
    $dbaseinterface ShowWindow $mode
    $dbaseinterface UpdateFromAlgorithm
    

}


# -------------------------------------------------------------------------------------------
#  
#    Progress Bar Stuff  and other common application level GUI Functionality
#
# -------------------------------------------------------------------------------------------

itcl::body bis_algorithm::AboutCommand { } {

    if { $aboutdialog == 0 } {
	
	set w .
	if { [ string length $basewidget ] > 2 } { set w $basewidget }
    
	set aboutdialog  [ toplevel $w.[ pxvtable::vnewobj ]] 
	wm geometry $aboutdialog 600x300
    
	::pxtclhelp::HelpDialog $aboutdialog
	wm title $aboutdialog "About This Application"
    

	set extra "Open Source Edition\n"

	set opt [ vtkpxOptimizer [ pxvtable::vnewobj ]]
	if { [ $opt UsesNumericalRecipes ] == 1 } {
	    set extra "Uses a small amount of code from Numerical Recipes in C\n"
	}
	$opt Delete

	set line "[ $this GetSynopsis text ]\n\nVersion: $version\n$aboutstring \n$extra\n------------------------------------\n System Information\n------------------------------------\n[ ::pxtclutil::GetAllInfo ]"
	                                                
	::pxtclhelp::HelpDialogAddText $aboutdialog $line

	set logoframe [ ::pxtclhelp::GetLogoFrame  $aboutdialog ]
	set imgname [ file join $::pxtclvtkpxcontrib::imagedir  bioimagesuite_logo.gif ]

	label $logoframe.b -image $::pxtclvtkpxcontrib::logo -width 581
	pack  $logoframe.b -side left -expand t -fill x 

 	set textbox [  ::pxtclhelp::GetTextBox  $aboutdialog ]

	$textbox configure -font "$::pxtclvtkpxcontrib::fontname"
	::bis_algorithm::SetWidgetTreeColors $aboutdialog "\#8197c5" white
    } 

    ::pxtclutil::ShowWindow $aboutdialog

    #    option clear
    #    global pxtcl_pref_array
    #    set pxtcl_pref_array(ColorScheme)  "Suite Blue"
    #    ::pxtcluserprefs::InitializeBioImageSuiteColorScheme

}


itcl::body bis_algorithm::HelpCommand { } {

    if { $helpdialog == 0 } {
	
	set w .
	if { [ string length $basewidget ] > 2 } { set w $basewidget }
    
	set helpdialog  [ toplevel $w.[ pxvtable::vnewobj ]] 
	wm geometry $helpdialog 800x600
    
	wm title $helpdialog "BioImage Suite Tool Manual Page"
    
	set scr [ iwidgets::scrolledhtml $helpdialog.t  -labeltext "" \
		      -width 6i -height 3i \
		      -wrap word -padx 2 ]

	$scr configure -fontsize large

	pack $scr -side top -expand true -fill both

	
	::bis_algorithm::SetWidgetTreeColors $scr "\#8197c5" white	
	set alg $this
	set ok [$alg GetCmdLineOptionsList]	
	set tool [ $this GetGUIName ]

	set fname ${scriptname}.tcl
	$scr render "<HTML><HEAD><TITLE>BioImage Suite - ${tool} </TITLE></HEAD><BODY><font size=\"2\" face=\"Verdana\"><H3>NAME</H3>${fname} --[$alg GetDescription]<br> <br><H3>SYNOPSIS</H3></font><font size=\"3\" face=\"Verdana\">[$alg GetSynopsis html]</font><font size=\"2\" face=\"Verdana\"><br> <br><H3>DESCRIPTION</H3>${tool}.tcl [$alg GetDetailDescription html] <br> <br><H3>BACKWARD COMPATIBILITY ISSUES</H3>[$alg GetBackwardCompatibility]<br> <br><H3>Authors</H3>[$alg GetAuthors]<br></font></BODY></HTML>"


    } 

    ::pxtclutil::ShowWindow $helpdialog


}


itcl::body bis_algorithm::ExitCommand { } {
    set ok [ tk_messageBox -title "Exiting this Application" -type yesno  -message "Are you sure you want to close $scriptname. Any unsaved work will be lost."  ]
    if { $ok == "yes" } {
	after 10 exit
    }
    return 0
}

itcl::body bis_algorithm::SetCurrentDirectory { { dirname "" } } {

    if { [ string length $dirname ] == 0 } {
	set dirname  [tk_chooseDirectory -title "Select Current Directory" ]
    }

    if { [ string length $dirname ] < 1 } {
	return 0
    }

    cd $dirname
    set dirname [ pwd ]
    #    pxtkprint "Switched directory to $dirname"
}


::itcl::body bis_algorithm::AddLogoLabel { w } {

    set l [ label $w.[ pxvtable::vnewobj ] -image  $::pxtclvtkpxcontrib::smalllogo ]
    return $l
}

::itcl::body bis_algorithm::CreateProgressBar { w } {
    
    set l [ AddLogoLabel $w  ]
    pack $l -side left -expand f -padx 1

    set progressbar($this) $w.pbar
    set progress_lab($this)  0.0
    iwidgets::feedbackplus $w.pbar -steps 100  -barheight 10  -labelpos w -labeltext $progress_lab($this)  
    pack $w.pbar -side left -expand true -fill x

    #    [ $w.pbar component trough ] configure  -bg  "gra"
    [ $w.pbar component bar ] configure  -bg  "blue"



}
# ----------------------------------------------------------
::itcl::body bis_algorithm::ProgressCallback { filter label } {

    if { $progressbar($this) != 0 } {
	$this ShowProgress $filter $label
    }

    if { [ $OptionsArray(slicermode) GetValue ] > 0 } {
	set p 0.5
	catch { set p  [$filter GetProgress] }
	if { $p==0 && $progress_status == -1 } {
	    puts stdout "<filter-start>"
	    puts stdout "<filter-name>[ $this GetGUIName]</filter-name>"
	    puts stdout "<filter-comment>$label</filter-comment>"
	    puts stdout "</filter-start>"
	    set progress_status 0
	} elseif { $p < 1.0 && $progress_status == 0 } { 
	    puts stdout "<filter-progress>$p</filter-progress>"
	} elseif { $progress_status == 0 } {
	    puts stdout "<filter-end>"
	    puts stdout "<filter-name>[ $this GetGUIName]</filter-name>"
	    puts stdout "</filter-end>"
	    set progress_status -1
	} else {
	    set progress_status -1
	}
	flush stdout
    }

    return 0

}
# ----------------------------------------------------------
::itcl::body bis_algorithm::ShowProgress { filter lab } {
	
    if { $progressbar($this) == 0 } {
	return
    }

    set progress_val($this) 50
    catch { set progress_val($this)  [expr [$filter GetProgress]*100] }
    set progress_lab($this) $lab
    
    if {$lab == "Done" } { 
	set progress_val($this) 0
    }
    
    $progressbar($this) configure  -labeltext $progress_lab($this)
    $progressbar($this) setval [ expr round($progress_val($this)) ]

    update idletasks
}
# ----------------------------------------------------------
::itcl::body bis_algorithm::ShowProgressVal { name val } {
	
    if { $progressbar($this) == 0 } {
	return
    }
	
    set progress_val($this) [expr $val*100.0]
    set progress_lab($this) "$name"
	
    if {$name == "Done" } { 
	set progress_val($this) 0
    }

    $progressbar($this) configure  -labeltext $progress_lab($this)
    $progressbar($this) setval [ expr round($progress_val($this)) ]

    #    update idletasks
}
# ----------------------------------------------------------
itcl::body bis_algorithm::GetViewer  { }  {

    if { $containerobject == 0 } {
	return $vtk_viewer
    }

    return [ $containerobject GetViewer ]
}
# ----------------------------------------------------------
itcl::body bis_algorithm::GetBisViewer  { }  {

    if { $bis_viewer !=0 ||  $containerobject == 0 } {
	return $bis_viewer
    }

    set bv 0
    catch { set bv  [ $containerobject GetBisViewer ] }
    return $bv
}
# ----------------------------------------------------------
itcl::body bis_algorithm::GetBisViewerImage  { { magn 1 }}  {

    set bv [ $this GetBisViewer ]
    if { $bv == 0 } {
	return 0
    }

    set vr [ $bv GetViewer ]
    set rw [ $vr GetRenderWidgetName ]
    set renwin [ $rw GetRenderWindow ]

    set renSrc [ vtkWindowToImageFilter New ]
    $renSrc SetInput $renwin
    $renSrc SetMagnification $magn
    $renSrc Update

    set img [ vtkImageData New ]
    $img ShallowCopy [ $renSrc GetOutput ]
    $renSrc Delete

    return $img
}


# ----------------------------------------------------------
itcl::body bis_algorithm::SetFilterCallbacks { filter comment } {
    
    set t [ itcl::scope $this ]

    eval "$filter AddObserver ProgressEvent { $t ProgressCallback $filter \"$comment\"}"
    eval "$filter AddObserver EndEvent      { $t ProgressCallback $filter Done}"

    # Also notify container ...
    if { $containerobject != 0 } { 
	$containerobject SetFilterCallbacks $filter $comment
    }

    if { $eventcontainerobject !=0 } { 
	$eventcontainerobject SetFilterCallbacks $filter $comment
    }
}



# ----------------------------------------------------------
itcl::body bis_algorithm::IsImageToImage { } {

    set n [ array names InputsArray ]
    if { [ llength $n ] != 1  } {
	return 0
    }
    set obj $InputsArray([lindex $n 0 ])
    if { [ $obj GetObjectType ] != "pxitclimage" } {
	return 0
    }

    set count 0
    foreach  n [ array names OutputsArray ] {
	set obj $OutputsArray($n) 
	if { [ $obj GetObjectType ] == "pxitclimage" } {
	    incr count
	}
    }
    
    return $count
}

# ----------------------------------------------------------
#
#  Inputs and Outputs
#
# ----------------------------------------------------------
itcl::body bis_algorithm::GetFirstInputObject  { } {

    set n [ lindex [ lindex $inputs 0 ] 0 ]
    set obj [ $InputsArray($n) GetObject ]
    return $obj

}

itcl::body bis_algorithm::GetSecondInputObject  { } {

    set n [ lindex [ lindex $inputs 1 ] 0 ]
    set obj [ $InputsArray($n) GetObject ]
    return $obj

}

itcl::body bis_algorithm::GetThirdInputObject  { } {

    set n [ lindex [ lindex $inputs 2 ] 0 ]
    set obj [ $InputsArray($n) GetObject ]
    return $obj

}

itcl::body bis_algorithm::GetFourthInputObject  { } {

    set n [ lindex [ lindex $inputs 3 ] 0 ]
    set obj [ $InputsArray($n) GetObject ]
    return $obj

}


itcl::body bis_algorithm::GetFirstOutputObject { } {
    set n [ lindex [ lindex $outputs 0 ] 0 ]
    set obj [ $OutputsArray($n) GetObject ]
    return $obj
}

# index starts at zero !!!!
itcl::body bis_algorithm::GetOutputObjectByIndex { { index 0 } } {
    
#    puts stderr "Names = [ array names OutputsArray]"
    set n [ lindex [ lindex $outputs $index ] 0 ]
    set obj [ $OutputsArray($n) GetObject ]
    return $obj
}

itcl::body bis_algorithm::GetOutputObjectNameByIndex { { index 0 } } {
    set n [ lindex [ lindex $outputs $index ] 0 ]
    return $n
}

#----------------------------------------------------
# GUI Construction
#----------------------------------------------------




itcl::body bis_algorithm::CreateGUI { basew { callafter 0 } { callbefore 0 } { testingmode 0 } } {


    set basewidget $basew

    # First Store the Callbacks
    set callbackbefore $callbefore
    set callbackafter  $callafter
    set progressbar($this) 0
    set progress_lab($this) "Status"
    set progress_val($this) 0


    if { $guimode == "standalone" } {
	return [ $this CreateStandaloneGUI $testingmode ]
    } elseif { $guimode == "datatree" && $datatree !=0 } {
	return [ $this CreateDataTreeGUI ]
    }

    return [ $this CreateManagedGUI ]
}


#----------------------------------------------------
itcl::body bis_algorithm::CreateStandaloneGUI { { testingmode 0 } } {


    # Now Create Main GUI View
    # If main application then menubase, viewbase, guibase and pbar all created
    # Else only viewbase

    set viewbase 0
    set noviewer 0
    set showoutputsmode 1

    set doviewer 1
    if { [ llength $inputs ] == 0 && [ llength $outputs ] == 0 } {
	set showoutputsmode 0
	set noviewer 1
    } elseif { $createviewermode  == 0 } {
	set noviewer 1
    }

    set buttonbar 0

    set menubase     [ menu $basewidget.top -tearoff 0  ]
    $basewidget configure -menu $menubase
    set pbar         [ frame $basewidget.pbar    -width 500 -height 20 ]
    
    CreateProgressBar  $pbar
    
    pack $pbar -side bottom -expand false -fill x
    
    eval "bind all <Control-d>  { $this ExitCommand }"
    eval "wm protocol . WM_DELETE_WINDOW { $this ExitCommand } "
    eval "wm protocol $basewidget WM_DELETE_WINDOW { $this ExitCommand  }"
    bind all <F1>  { pxtkconsole }
    
    set w $basewidget.v
    
    if { $noviewer == 0 } {
	if { $testingmode == 0 } {
	    set nt [ panedwindow $w -orient horizontal -showhandle 1 \
			 -borderwidth 10 -relief raised -sashwidth 4 -sashpad 4 \
			 -handlesize 5 -handlepad 50  ]
	    set guibase  [ frame $nt.c  -width 500 -bg red ]
	    set viewbase  [ frame $nt.v -width 450 ]
	    
	    $nt add $guibase -minsize  300 -sticky nse
	    $nt add $viewbase -minsize 400 -sticky nsew
	} else {
	    set nt [ frame $w ]
	    set guibase  [ frame $nt.c  -width 500 ]
	    set viewbase  [ frame $nt.v -width 450 ]
	    pack $viewbase -side right -expand false -fill y
	}
	set guibasewidget $guibase
	CreateViewer  $viewbase
	if { $testingmode > 0 } {
	    $vtk_viewer SetShowControls 0
	}
    } else {
	set nt [ frame $w ]
	set guibase $nt
    }

    set buttonbar [ frame $guibase.bot ]
    pack $buttonbar -side bottom -expand false -fill x
    CreateMenuBar $menubase
    pack $nt -side top -expand true -fill both 
    
    set inbase 0
    set outbase 0
    set numout [ llength $outputs ]
    set numint [ llength $inputs  ]
    set needsdc 0
    if { $noviewer == 0 } {
	set needsdc [ $this NeedsCustomDataControl ]
    }

    if { [ expr $numout + $numint + $needsdc ] > 0 } {
	set w $guibase
	set guibase [  iwidgets::tabnotebook $guibase.0 -tabpos n  -angle 45 -margin 2 -backdrop gray -raiseselect true  ]
	pack $guibase -side top -expand true -fill both

	if { $needsdc } {
	    $this CreateCustomDataControl  $guibase 
	}
	
	if { [ llength $inputs ] > 0 } {
	    set inbase  [ $guibase add -label Inputs ]
	}
	set optbase [ $guibase add -label Options ]
	$optbase configure -bg red
	if { [ llength $outputs ] > 0 } {
	    set outbase [ $guibase add -label Outputs ]
	}
	$guibase view "Options"
	update idletasks
    } else {
	set optbase $guibase
    }

    if { $inbase !=0 } { 
	CreateInputGUIInterface $inbase 
    }

    CreateOptionsGUIInterface $optbase
    
    if { $buttonbar == 0 } {
	set buttonbar     [ frame $optbase.2    -width 500 -height 20 ]
	pack $buttonbar -side bottom -expand true -fill x
    }


    eval "button $buttonbar.a -text \"$executename\" -command { $this InvokeAlgorithmFromGUI } -padx 5"
    eval "button $buttonbar.b -text \"Show Command\" -command { $this ShowCommandLine } -padx 5"
    pack $buttonbar.b -side right -expand false
    pack $buttonbar.a -side left -expand true -fill x


    if { $outbase !=0 &&  $showoutputsmode == 1 } {
	$this CreateOutputGUIInterface $outbase 
    }
    return $basewidget
}
#----------------------------------------------------
itcl::body bis_algorithm::CreateDataTreeGUI { } {

    #    puts stderr "Creating Data tree GUI"

    if { [ llength $inputs ] == 0 && [ llength $outputs ] == 0 } {
	set showoutputsmode 0
    }
    set buttonbar 0
#    set n [ $this GetGUIName ]
#    label $basewidget.o -text "$n" -bg black -fg white
#    pack $basewidget.o -side top -expand false -fill x

    set buttonbar [ frame  $basewidget.bot2 ]
    pack $buttonbar -side bottom -expand false -fill x

    set nt [ panedwindow $basewidget.top -orient vertical -showhandle 1 \
		 -borderwidth 10 -relief raised -sashwidth 4 -sashpad 4 \
		 -handlesize 5 -handlepad 50  ]
    pack $nt -side top -expand true -fill both 
    set base $nt

    set top [ [ iwidgets::labeledframe $base.top  -labeltext "Parameters" ] childsite ]
    set bot [ [ iwidgets::labeledframe $base.bot  -labeltext "Inputs+Outputs" ] childsite ]

    $nt add $base.top -minsize 200 -height 350
    $nt add $base.bot -minsize 200 -height 350

    set guibase [  iwidgets::tabnotebook $bot.0 -tabpos n  -angle 45 -margin 2 -backdrop gray -raiseselect true ]
    pack $guibase -side top -expand true -fill both
    
    if { [ llength $inputs ] > 0 } {
	set inbase  [ $guibase add -label Inputs ]
	CreateInputGUIInterface $inbase
	$guibase view "Inputs"
    }
    if { [ llength $outputs ] > 0 } {
	set outbase [ $guibase add -label Outputs ]
	$this CreateOutputGUIInterface $outbase 
	if { [ llength $inputs ] == 0 } {
	    $guibase view "Outputs"
	}
    }

    CreateOptionsGUIInterface $top
    
    eval "button $buttonbar.a -text \"$executename\" -command { $this InvokeAlgorithmFromGUI } -padx 5"
    eval "button $buttonbar.b -text \"Show Command\" -command { $this ShowCommandLine } -padx 5"
    pack $buttonbar.b -side right -expand false
    pack $buttonbar.a -side left -expand true -fill x


    return $basewidget
}
#----------------------------------------------------

itcl::body bis_algorithm::CreateManagedGUI { } {


    if { [ llength $inputs ] == 0 && [ llength $outputs ] == 0 } {
	set showoutputsmode 0
	set noviewer 1
    }

    set inbase 0
    set outbase 0
    set numout [ llength $outputs ]
    set numint [ llength $inputs  ]



    if { [ expr $numout + $numint ] > 0 && ( $showoutputsmode == 1 ) } {
	set guibase [  iwidgets::tabnotebook $basewidget.1 -tabpos w  -angle 45 -margin 2 -backdrop gray -raiseselect true ]
	pack $guibase -side top -expand true -fill both

	if { [ llength $inputs ] > 0 } {
	    set inbase  [ $guibase add -label Inputs ]
	}
	set optbase [ $guibase add -label Options ]
	if { [ llength $outputs ] > 0 } {
	    set outbase [ $guibase add -label Outputs ]
	}
	$guibase view "Options"
    } else {
	set optbase $basewidget
    }

    
    set buttonbar     [ frame $optbase.2    -width 500 -height 20 ]
    pack $buttonbar -side bottom -expand false -fill x
    frame $optbase.1; pack $optbase.1 -side top -expand true -fill both
    
    frame $buttonbar.1 
    frame $buttonbar.2 -bg black -height 2
    frame $buttonbar.3 
    pack $buttonbar.1 $buttonbar.2 $buttonbar.3 -side top -expand false -fill x

    set parameterbar $buttonbar.1

    label $buttonbar.1.0 -text "Parameters:" 
    eval "button $buttonbar.1.a -text \"Load\" -command { $this LoadParameters }"
    eval "button $buttonbar.1.b -text \"Save\" -command { $this SaveParameters }"
    eval "button $buttonbar.1.c -text \"Query\" -command { $this ShowDatabaseGUI query }"
    eval "button $buttonbar.1.d -text \"Store\" -command { $this ShowDatabaseGUI store }"
    eval "button $buttonbar.1.e -text \"Reset\" -command { $this ResetParameters }"
    pack $buttonbar.1.0 $buttonbar.1.a $buttonbar.1.b $buttonbar.1.c $buttonbar.1.d $buttonbar.1.e -side left -expand false -padx 1
    
    eval "button $buttonbar.3.a -text \"$executename\" -command { $this InvokeAlgorithmFromGUI } -padx 5"
    eval "button $buttonbar.3.b -text \"Show Command\" -command { $this ShowCommandLine } -padx 5"
    pack $buttonbar.3.b -side right -expand false
    pack $buttonbar.3.a -side left -expand true -fill x


    if { $outbase !=0 } {
	if { $showoutputsmode == 1 } {
	    iwidgets::scrolledframe $outbase.sf  -labeltext ""  -hscrollmode dynamic -vscrollmode dynamic
	    pack $outbase.sf -side top -expand true -fill both
	    $this CreateOutputGUIInterface [ $outbase.sf childsite ]
	}
    }


    CreateOptionsGUIInterface $optbase.1

    return $basewidget
}



#----------------------------------------------------
#  Create Input GUIInterface
#----------------------------------------------------
itcl::body bis_algorithm::CreateInputGUIInterface { bar } {

    if { $hasinputguis == 1 } {
	return
    }

    set c [ iwidgets::scrolledframe $bar.[pxvtable::vnewobj ] -width 12i -height 12i -hscrollmode dynamic -vscrollmode dynamic  -labelpos nw -labeltext "" -relief ridge ]
    pack $c -side top -expand true -fill both
    set bar [ $c childsite ]

    set count 0
    set nlist ""
    foreach name [ array names InputsArray ] {
	lappend nlist [ list $name [ expr abs([  $InputsArray($name) GetPriority ]) ] ]
    }
    set nlist [ lsort -integer  -index 1 $nlist ]

    set dograb 1
    for { set i 0 } { $i < [ llength $nlist ] } { incr i } {
	if { [ $InputsArray($name) GetObjectType ] != "pxitcltransform" } {
	    set dograb 2
	}
    }

    for { set i 0 } { $i < [ llength $nlist ] } { incr i } {

	set name [ lindex [ lindex $nlist $i ] 0 ]
	if { [ $InputsArray($name) GetDescription ] != "" } { 
	    set n $bar.$name$count
	    if { $guimode == "datatree" } {
		$InputsArray($name) CreateDataTreeObjectGUI $n $dograb 0 $this $datatree
		pack $n -side top -expand false -fill x -pady 0
	    } else {
		$InputsArray($name) CreateObjectGUI $n 0 "" $this
		pack $n -side top -expand false -fill x 
	    }

	}
	incr count
    }
    set hasinputguis 1
    PrintDebug "Done Creating Inputs"
}


itcl::body bis_algorithm::CreateOutputGUIInterface { bar } {

    if { $hasoutputguis == 1 } {
	return
    }

    set c [ iwidgets::scrolledframe $bar.[pxvtable::vnewobj ] -width 12i -height 12i -hscrollmode dynamic -vscrollmode dynamic  -labelpos nw -labeltext "" -relief ridge ]
    pack $c -side top -expand true -fill both
    set bar [ $c childsite ]

    set count 0
    set nlist ""
    foreach name [ array names OutputsArray ] {
	lappend nlist [ list $name [ expr abs([  $OutputsArray($name) GetPriority ]) ] ]
    }
    set nlist [ lsort -integer  -index 1 $nlist ]

    for { set i 0 } { $i < [ llength $nlist ] } { incr i } {

	set name [ lindex [ lindex $nlist $i ] 0 ]
	set ln "Creating a GUI for output $name"

	set n $bar.$name$count
	if { $guimode == "datatree" } {
	    $OutputsArray($name) CreateDataTreeObjectGUI $n 0 1 $this $datatree
	} else {
	    $OutputsArray($name) CreateObjectGUI $n 1 "" $this
	}
	pack $n -side top -expand false -fill x
	incr count
    }
    set hasoutputguis 1
}

itcl::body bis_algorithm::CreateOptionsGUIInterface { optbase } { 

    # Step 1 number -- determine number of experimental parameters
    # Priority < 0 experimental
    # Priority >=0 normal
    # Priority = -1000 do not show (-dogui)
    set numexp 0
   set names [array names OptionsArray]
    foreach name $names {
	set opt $OptionsArray($name)

	set pr [ $opt GetPriority ]
	if { $pr < 0 && $pr > -1000 } {
	    incr numexp
	}
    }

    # If we have experimental then create tabbed notebook
    # Else simple frame
    if { $numexp > 0 } {
	set nt [ iwidgets::tabnotebook $optbase.nt -tabpos n -angle 45 -margin 2 -backdrop gray -raiseselect true   ]
	pack $nt -side top -expand true  -fill both
	set t(0)  [ $nt add -label Standard   ]
	set t(1)  [ $nt add -label Advanced ]

	for { set i 0 } { $i <=1 } { incr i } {
	    if { $maintabscrollmode > 0 } {
		set c [ iwidgets::scrolledframe $t($i).[pxvtable::vnewobj ] -width 12i -height 12i -hscrollmode dynamic -vscrollmode dynamic  -labelpos nw -labeltext "" -relief ridge ]
		pack $c -side top -expand true -fill both
		set topbar($i)  [ $c childsite ]
	    } else {
		set topbar($i) $t($i)
	    }
	}

	$nt view "Standard"

	for { set i 0 } { $i <=1 } { incr i } {
	    set w [ frame $topbar($i).sf  ]
	    set topbar($i) $w
	    pack $w -side top -expand true -fill both

	}
    } else {
	if { $maintabscrollmode > 0 } {
	    set c [ iwidgets::scrolledframe $optbase.[pxvtable::vnewobj ] -width 12i -height 12i -hscrollmode dynamic -vscrollmode dynamic  -labelpos nw -labeltext "" -relief ridge ]
	    pack $c -side top -expand true -fill both
	    set w [ $c childsite ]
	} else {
	    set w [ frame $optbase.sf ]
	    pack $w -side top -expand true -fill both 
	}
	set topbar(0) $w
	set topbar(1) $w

    }


    # For each element in options create GUI element

    set nlist [ concat $StandardOptionsList $AdvancedOptionsList ]
    set elemlist ""

    for { set i 0 } { $i < [ llength $nlist ] } { incr i } {

	set name  [ lindex $nlist $i ]
	set opt $OptionsArray($name)
	set ind 0
	set pr [ $opt GetPriority ]
	if { $pr > -1000 } {
	    if { $pr < 0 } {
		set ind 1
	    }
	    set w  $topbar($ind).[pxvtable::vnewobj ] 
	    $opt CreateGUIElement $w ""
	    lappend elemlist [ list [ expr abs($pr)] $ind $name $w ]
	}
    }

    if { [ llength $elemlist ] > 0 } {
	$this PackOptionsGUIInterface $elemlist
	$this ConfigureOptionsGUICallbacks
    }

}

# lst is a list of lists !, each sublist has two elements, the name and the widget
itcl::body bis_algorithm::PackOptionsGUIInterface { lst } {

    set n [ llength $lst ]
    PrintDebug "\n\n Length of list = $n"

    for { set tab 0 } { $tab <= 1 } { incr tab } {
	set wlist ""
	for { set i 0 } { $i < $n } { incr i } {
	    
		set pair [ lindex $lst $i ]
		set ind  [ lindex $pair 1 ]
		if { $ind == $tab } {
		    lappend wlist $pair
		}
	    }

	set wlist [ lsort -integer  -index 0 $wlist ]

	set nlist ""
	for { set j 0 } { $j < [ llength $wlist ] } { incr j } {

	    set pair [ lindex $wlist $j ]
	    set name [ lindex $pair 2 ]
	    set widg [ lindex $pair 3 ]

	    #PrintDebug "Packing $name"
	    #puts stderr "Packing $name ---> $widg, [ lindex $pair 0 ]"
	    pack $widg -side top -expand false -fill x -padx 1
	    lappend nlist  $widg.lab
	}
	update idletasks
	eval "iwidgets::Labeledwidget::alignlabels $nlist"
    }

}


# ----------------------------------------------------------------------


itcl::body bis_algorithm::CreateMenuBar { menubase } {

    set filem [ menu $menubase.file -tearoff 0  ]
    $menubase add cascade -underline 0  -label "File" -menu $filem

    eval "$filem add command -label \"Load Parameters\" -command { $this LoadParameters }"
    eval "$filem add command -label \"Save Parameters\" -command { $this SaveParameters }"
    $filem add separator
    eval "$filem add command -label \"Query Parameters from Database\" -command { $this ShowDatabaseGUI query } "
    eval "$filem add command -label \"Store Parameters in Database\" -command { $this ShowDatabaseGUI store } "
    $filem add separator
    eval "$filem add command -label \"Reset Parameters\" -command { $this ResetParameters }"

    $filem add separator
    eval "$filem add command -label \"Switch Directory\" -command { $this SetCurrentDirectory } "
    $filem add separator
    eval "$filem add command -label Exit -command {  $this ExitCommand } -underline 1"

    set runm [ menu $menubase.run -tearoff 0  ]
    $menubase add cascade -underline 0  -label "Run" -menu $runm
    eval "$runm add command -label \"$executename\" -command {$this InvokeAlgorithmFromGUI }"


    set viewm [ menu $menubase.viewm -tearoff 0  ]
    $menubase add cascade -underline 0  -label "Viewer" -menu $viewm
    if { $bis_viewer !=0 } {
	$bis_viewer AddToMenu $viewm
    }

    
    set helpm [ menu $menubase.help -tearoff 0  ]
    $menubase add cascade -underline 0  -label "Help" -menu $helpm 

    eval "$helpm add command -label \"Tool Manual Page\" -command { $this HelpCommand }"
    eval "$helpm add separator"
    eval "$helpm add command -label \"Show Command Line\" -command {$this ShowCommandLine }"    
    eval "$helpm add command -label \"Show Long  Description\" -command {$this ShowLongDescription }"    
    $helpm add separator
    $helpm add command -label "Show Console" -command { pxtkconsole }
    eval "$helpm add separator"
    eval "$helpm add command -label About -command { $this AboutCommand }"
}

# --------------------------------------------------------------------

itcl::body bis_algorithm::CreateViewer { fr } {

    set viewerbasewidget $fr
    set bis_viewer [ [ bis_viewer \#auto ] GetThisPointer ]
    $bis_viewer configure -enable_toolbar  0
    $bis_viewer SetViewerType $bis_viewer_type $bis_viewer_edit 
    $bis_viewer CreateGUI $fr 
    set vtk_viewer [ $bis_viewer GetViewer ]


}
# --------------------------------------------------------------------
itcl::body bis_algorithm::SetViewer { vr } {
    set vtk_viewer $vr
}

itcl::body bis_algorithm::SetBisViewer { vr } {
    set bis_viewer $vr
    set vtk_viewer [ $bis_viewer GetViewer ]
}

#----------------------------------------------------
# Invoke algorithm from GUI
#----------------------------------------------------

itcl::body bis_algorithm::GetCommandLine { { mode short } } {

    set cmd $scriptname
    if { [ file extension $cmd ] != ".tcl"  } {
	set cmd "${cmd}.tcl"
    }

    set nlist [ concat $StandardOptionsList $AdvancedOptionsList ]
    for { set i 0 } { $i < [ llength $nlist ] } { incr i } {
	set name [ lindex $nlist $i ]
	if {  [ lsearch -exact $ignoreflag $name  ] == -1 } {
	    if { [ string compare -length 3 $name "gui" ] != 0 && 
		 $name != "loni" } {
		
		set opt $OptionsArray($name)
		$opt UpdateFromGUI
		set v [ string trim [ $opt GetValue ] ]

		
		if { [ string first " " $v ] > 0 || [ string first ";" $v ] > 0   || [ string first "\t" $v ] > 0 } {
		    set v "\"$v\""
		}

		if { [ string length $v ] > 0 } {
		    if { $mode == "short" } {
			if { $v != [ $opt GetDefaultValue ] } {
			    set cmd "$cmd --[ $opt GetCommandSwitch ] $v"
			}
		    } else {
			set cmd "$cmd --[ $opt GetCommandSwitch ] $v"
		    }
		}
	    }
	}
    }

    if { $mode != "paramset" } {
	
	for { set i 0 } { $i < [ llength $outputs ] } { incr i } {
	    set elem [ lindex $outputs $i ]
	    set name  [ lindex $elem  0 ]
	    set fname [ $OutputsArray($name) GetFileName ]
	    set v [ $OutputsArray($name) IsFileNameTheDefault ]
	    if { [ string length $fname ] > 0 } {
		if { $v==0 || $mode !="short" } {
		    set cmd "$cmd --[ $OutputsArray($name) GetCommandSwitch ] $fname"
		}
	    }
	}
	
	for { set i 0 } { $i < [ llength $inputs ] } { incr i } {
	    set elem [ lindex $inputs $i ]
	    set name  [ lindex $elem  0 ]
	    if { $name != $directinputs } {
		set fname [ $InputsArray($name) GetFileName ]
		set v [ $InputsArray($name) IsFileNameTheDefault ]
		if { [ string length $fname ] > 0 } {
		    if { $v==0 || $mode !="short" } {
			set cmd "$cmd --[ $InputsArray($name) GetCommandSwitch ] $fname"
		    }
		}
	    }
	}

	if { $directinputs != "" } {
	    set v " [ $InputsArray($directinputs) GetFileName ] [ $InputsArray($directinputs) GetFileNameList ]"
	    #	    puts stdout "directs = $v"
	    append cmd $v
	}
    }

    return $cmd
}
# ----------------------------------------------------------------------------------------------------------------
itcl::body bis_algorithm::GetSlicerXMLDescription {  } {

    set cmd $scriptname
    if { [ file extension $cmd ] != ".tcl"  } {
	set cmd "${cmd}.tcl"
    }

    set names [ concat $StandardOptionsList $AdvancedOptionsList ]

    set normal "<parameters>\n<label>Standard</label>\n<description>Standard Parameters</description>"
    set advanced "<parameters advanced=\"true\">\n<label>Advanced</label>\n<description>Advanced Parameters</description>"
    set debug "<parameters advanced=\"true\">\n<label>Debug</label>\n<description>Debug Parameters</description>"
    set inp "<parameters>\n<label>Inputs</label>\n<description>Input Objects</description>"
    set outp "<parameters>\n<label>Outputs</label>\n<description>Output Objects</description>"
    set numnormal 0
    set numadvanced 0
    set numinp 0
    set numout 0



    for { set i 0 } { $i < [ llength $names ] } { incr i } {
	set name [ lindex $names $i ]
	if {  [ lsearch -exact $ignoreflagslicer $name  ] == -1 &&  [ string compare -length 3 $name "gui" ] !=0 } {
	    
	    #	    puts stderr "Using $name"
	    set opt $OptionsArray($name)

	    set desc [ $opt GetSlicerXMLDescription ]
	    set pri  [ $opt GetPriority ]

	    if { $name == "dogui" || $name =="slicermode" } {
		if { $name == "slicermode" } {
		    $opt SetDefaultValue 1
		    $opt SetValue 1
		}
		set desc [ $opt GetSlicerXMLDescription ]

		if { $forceguimode == 0 || $name !="dogui" } {
		    set debug "$debug\n$desc"
		}
	    } elseif { $pri >= 0 } {
		set normal "$normal\n$desc"
		set numnormal 1
	    } else {
		set advanced "$advanced\n$desc"
		set numadvanced 1
	    }
	}
    }
 
     for { set i 0 } { $i < [ llength $inputs ] } { incr i } {
	 set n [ lindex [ lindex $inputs $i ] 0 ]
	 if { $n != $directinputs } {
	     set desc [ bis_object::GetSlicerListXMLDescription [ lindex $inputs $i ] 1 [expr $i +1 ]  ]
	     if { $desc != "" } {
		 set inp "$inp\n$desc"
		 incr numinp
	     }
	 }
     }

    if { $directinputs != "" } {
	set j 0; set found -1
	while { $j < [ llength $inputs ] } {
	    if { [ lindex [ lindex $inputs $j ] 0 ] == $directinputs } {
		set found $j
		set j 10000
	    }  
	    incr j
	}
	if { $found != -1 } {
	    for { set i 0 } { $i <= 8 } { incr i } {
		set desc [ bis_object::GetSlicerListXMLDescription [ lindex $inputs $found ] 1 [expr $i +1 ] $i ]
		if { $desc != "" } {
		    set inp "$inp\n$desc"
		incr numinp
		}
	    }
	}
    }

     for { set i 0 } { $i < [ llength $outputs ] } { incr i } {
	 set desc [ bis_object::GetSlicerListXMLDescription [ lindex $outputs $i ]  0 [ expr $i +1 ] ]
	 if { $desc != "" } {
	     set outp "$outp\n$desc"
	     incr numout
	 }

     }

    set cmdline "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
    set cmdline "$cmdline\n<executable>"
    set cmdline "$cmdline\n<category>Yale BioImage Suite-${category}</category>"
    set cmdline "$cmdline\n<title>BioImage Suite-[ $this GetGUIName]</title>"
    set cmdline "$cmdline\n<description>$description\n$description2</description>"
    set cmdline "$cmdline\n<version>$::pxtclvtkpxcontrib::versionno</version>"
    set cmdline "$cmdline\n<documentation-url>www.bioimagesuite.org</documentation-url>"
    set cmdline "$cmdline\n<license>GPL v2</license>"
    set cmdline "$cmdline\n<contributor>$authors</contributor>\n"

     if { $numnormal > 0 } { set cmdline "$cmdline\n$normal\n</parameters>\n" }
     if { $numadvanced > 0 } { set cmdline "$cmdline\n$advanced\n</parameters>\n" }
     set cmdline "$cmdline\n$debug\n</parameters>\n" 
     if { $numinp > 0 } { set cmdline "$cmdline\n$inp\n</parameters>\n" }
     if { $numout > 0 } { set cmdline "$cmdline\n$outp\n</parameters>\n" }

    set cmdline "$cmdline\n</executable>\n"

    return $cmdline
}
# ---------------------------------------------------------------------
# mode 0 = normal, 1 =advanced 2 =debug
itcl::body bis_algorithm::GetJSONParameters { mode } {

    set num 0
    set out ""
    set names [ concat $StandardOptionsList $AdvancedOptionsList ]
    for { set i 0 } { $i < [ llength $names ] } { incr i } {
	set name [ lindex $names $i ]
	set opt $OptionsArray($name)
	set desc [ $opt GetJSONString ]
	set pri  [ $opt GetPriority ]
	if { ( ($pri >= 0 && $mode==0) || ($pri > -9999 && $pri < 0 && $mode == 1) || ($pri < -9999 && $mode == 2 ) ) } {
	    if { $num > 0 } {
		append out ","
	    }
	    append out "\n$desc"
	    incr num
	}
    }
    return $out
}

itcl::body bis_algorithm::GetJSONInputs { } {

    set inp ""
    set numinp 0
    for { set i 0 } { $i < [ llength $inputs ] } { incr i } {
	set n [ lindex [ lindex $inputs $i ] 0 ]
	if { $n != $directinputs } {
	    set desc [ bis_object::GetJSONString [ lindex $inputs $i ] 1 [expr $i +1 ]  ]
	    if { $desc != "" } {
		if { $numinp > 0 } {
		    append inp ","
		}
		append inp "\n$desc"
		incr numinp
	    }
	}
    }
    return $inp

}

itcl::body bis_algorithm::GetJSONOutputs { } {
    set outp ""
    set numout 0
    for { set i 0 } { $i < [ llength $outputs ] } { incr i } {
	set desc [ bis_object::GetJSONString [ lindex $outputs $i ]  0 [ expr $i +1 ] ]
	if { $desc != "" } {
	    if { $numout > 0 } {
		append outp ","
	    }
	    append outp "\n$desc"
	    incr numout
	}
    }
    return $outp

}

itcl::body bis_algorithm::GetJSONDescription {  } {

    set cmd $scriptname
    if { [ file extension $cmd ] != ".tcl"  } {
	set cmd "${cmd}.tcl"
    }


    set names [ concat $StandardOptionsList $AdvancedOptionsList ]

    set numnormal 0
    set numadvanced 0
    set numdebug 0
    set numinp 0
    set numout 0
    set normal   " \"Standard\": \{"
    set advanced   " \"Advanced\": \{"
    set debug   " \"Debug\": \{"
    set inp   " \"Inputs\": \{"
    set outp   " \"Outputs\": \{"


    

    set    outtxt  "\{\n"
    append outtxt  " \"Header\": \{"
    append outtxt "\t\"commandname\": [ ::bis_common::CleanString $cmd],\n"
    append outtxt "\t\"category\": [ ::bis_common::CleanString ${category}],\n"
    append outtxt "\t\"title\":  [ ::bis_common::CleanString [ $this GetGUIName]],\n"
    append outtxt "\t\"description\": [ ::bis_common::CleanString $description],\n"
    append outtxt "\t\"description2\": [ ::bis_common::CleanString $description2],\n"
    append outtxt "\t\"authors\": [ ::bis_common::CleanString $authors]"
    append outtxt "\n\t\},\n"

    append normal [ $this GetJSONParameters 0 ]
    append advanced [ $this GetJSONParameters 1 ]
    append debug  [ $this GetJSONParameters 2 ]
    append inp [ $this GetJSONInputs ]
    append outp [ $this GetJSONOutputs ]
 
    

    append outtxt "$normal\n\t\},\n"
    append outtxt "$advanced\n\t\},\n"
    append outtxt "$debug\n\t\},\n"
    append outtxt "$inp\n\t\},\n"
    append outtxt "$outp\n\t\}\n"
    append outtxt "\}\n"
    
    return $outtxt
}
# ----------------------------------------------------------------------------------------------------------------
itcl::body bis_algorithm::GetLONIXMLDescription { { mode 1 } } {

    set cmd $scriptname
    if { [ file extension $cmd ] != ".tcl"  } {
	set cmd "${cmd}.tcl"
    }

    set names [ concat $StandardOptionsList $AdvancedOptionsList ]
    if { [ llength $names ] > 0 } {
	set parameters "\n"
	set inp ""
	set outp ""
	set numparam [ llength $names ]
	
	for { set i 0 } { $i < [ llength $names ] } { incr i } {
	    set name [ lindex $names $i ]
	    if { $name != "testlog"  && $name !="pset" && [ string compare -length 3 $name "gui" ] !=0 } {
		
		set opt $OptionsArray($name)
		
		set desc [ $opt GetLONIXMLDescription ]
		set pri  [ $opt GetPriority ]
		
		if { $pri > -1000 } {
		    append parameters "$desc\n"
		}
	    }
	}
    }
 
    set numinp 0
    set names [ array names InputsArray ]
    if { [ llength $names ] > 0 } {
	foreach name $names {
	    lappend nlist [ list $name [ expr abs([  $InputsArray($name) GetPriority ]) ] ]
	}
	set nlist [ lsort -integer  -index 1 $nlist ]
	
	for { set i 0 } { $i < [ llength $nlist ] } { incr i } {
	    set name [ lindex [ lindex $nlist $i ] 0 ]
	    set desc [ $InputsArray($name) GetLONIXMLDescription  1  ]
	    if { $desc != "" } {
		append inp "$desc\n"
		incr numinp
	    }
	}
    }

    set numout 0
    set nlist ""
    set names [ array names OutputsArray ]
    if { [ llength $names ] > 0 } {
	foreach name $names {
	    lappend nlist [ list $name [ expr abs([  $OutputsArray($name) GetPriority ]) ] ]
	}
	set nlist [ lsort -integer  -index 1 $nlist ]
	for { set i 0 } { $i < [ llength $nlist ] } { incr i } {
	    set name [ lindex [ lindex $nlist $i ] 0 ]
	    set desc [ $OutputsArray($name) GetLONIXMLDescription 0 ]
	    if { $desc != "" } {
		append outp "$desc\n"
		incr numout
	    }
	}
    }

    
    set fname [ info script ]
    set tname [ file tail $fname ]
    set fname2 [ file dirname [ file dirname $fname ] ]
    set ftail [ file rootname [ file tail $fname ] ]
    set newname "${fname2}/bin/${ftail}"

    set cmdline "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    if { $mode <2 } {
	append cmdline "<pipeline version=\".1\">\n"
	append cmdline "\t<moduleGroup id=\"id_$tname\" name=\"$tname\">\n"
    }
    append cmdline "\t\t<module name=\"[ $this GetGUIName]\" "
    append cmdline "description=\"$description$description2\" "
    append cmdline "location=\"pipeline://localhost/$newname\" "
    append cmdline "package=\"BioImage Suite\" "
    append cmdline "icon=\"/9j/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAx&#xA;NDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIy&#xA;MjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAAUCAAwADAEASIAAhEBAxEBBCIA/8QAHwAAAQUB&#xA;AQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEG&#xA;E1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVW&#xA;V1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLD&#xA;xMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAA&#xA;AAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKR&#xA;obHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hp&#xA;anN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU&#xA;1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADgQBAAIRAxEEAAA/AOXoor0LwAPD2ryQaPfaJHJd&#xA;7XY3LOTvwSeR244/Cvr61X2UOe1z42hS9rPkva57/RRRXntFet663gnQNSeyufD6s6gHcrHByM+v&#xA;vVC3v/h1qE6wTaQ1tvOBJvYBfrhq54428eZQdvl/mdEsDaXK6kb/AD/yCiiivM6K7jxz4ETw6iX1&#xA;hI8ljI20q5y0bdRz3FcPXTSqwqx54bHNWozoz5J7hRRRRXY/DD/kd7f/AK5Sf+g1x1dj8MP+R3t/&#xA;+uUn/oNRi/4E/Rl4T+PD1QUUUVtfELw3rOp+JJLiy06eeIqoDouR90Vg6X8OfEV/dxxz2TWkBI3y&#xA;ykDaPYZyTXQeP/EuraV4llgs72aKLapCq5AHyiuctPiH4htZlf7a8oB5WX5gfzrjofWfYR5LbeZ2&#xA;1/qvt5e0vv5BRRRXafEjXbJdHTR7eQSOrDeQc7cDAGfWvIa9n8VadZ+KvA8WvCBYbwQrMrDrjupP&#xA;cdcV4yRgkVpl3KqTit09fUzzLmdVSezWnoFFFFJXo/w20aK2vYNeuNVsY4/LdRAZQJAeV5B6ev5V&#xA;5xT0lkjGEcj6GuqvTdWDgna5yYerGlUU2r2CiiivW/FvhO18R6w19F4gsIQygbGYHoMevtWPbfDj&#xA;SYZVk1DxRaNCDlkhKgsPQEsf5V599pm/56t+dIbiY9ZG/OuaGGrQioKpp6I6Z4qhObnKnq/NhRRR&#xA;XqfjDxhpsOiDRdIwYQgjJAwAo6KO/Yc15STkk0EknJOaSt8Ph40I8sTDEYiVeXNIKKKK/9k=\" "
    append cmdline "version=\"$::pxtclvtkpxcontrib::versionno\">"

    append cmdline "executableVersion=\"$::pxtclvtkpxcontrib::versionno\">\n"
    append cmdline "\t\t\t<executableAuthors>\n"
    append cmdline "\t\t\t\t<author fullName=\"BioImage Suite Team\" email=\"\" website=\"www.bioimagesuite.org\" />\n"
    append cmdline "\t\t\t</executableAuthors>\n"
    append cmdline "\t\t\t<tag />\n"
    append cmdline "\t\t\t<uri>www.bioimagesuite.org</uri>"


    set endcmdline "\t\t</module>\n"
    if { $mode <2 } {
	append endcmdline "\t</moduleGroup>\n"
	append endcmdline "</pipeline>\n"
    }


    if { $numparam > 0 } { append cmdline "$parameters\n" }
    if { $numinp > 0 } { append cmdline "$inp\n" }
    if { $numout > 0 } { append cmdline "$outp\n" }

    append cmdline $endcmdline

    return $cmdline
}
# ----------------------------------------------------------------------------------------------------------------
itcl::body bis_algorithm::ShowCommandLine { } {

    pxtkconsole

    pxtkprint "\n--------------------------------------------\n\nCOMMAND LINE PROCEDURE\n---------------------- \n"
    pxtkprint "To perform this procedure on the command line type:\n\n"

    set cmdlong [ $this GetCommandLine full ]
    set cmdshort [ $this GetCommandLine short ]

    pxtkprint "\nFull Version\n\t $cmdlong\n\n"

    pxtkprint "\nShort Version (not setting default arguments)\n\t $cmdshort\n\n"

    pxtkprint "\n\n"

}

itcl::body bis_algorithm::ShowLongDescription { } {

    pxtkconsole

    pxtkprint "\n--------------------------------------------\n\n\n\nLONG Description\n---------------------- \n"

    pxtkprint "[ $this GetSynopsis 0]\n\n "
    pxtkprint "[ $this GetDetailDescription 0 ]\n "
    pxtkprint "\n"

}


itcl::body bis_algorithm::InvokeAlgorithmFromGUI { } {

    if { $callbackbefore !=0 } {
	# this is a hook from master object to set filenames  if needed
	eval $callbackbefore
    }

    # Update Values from GUI
    set names [array names OptionsArray]
    foreach name $names {
	set opt $OptionsArray($name)
	$opt UpdateFromGUI
    }

    $this UpdateOutputFilenames
    if { $directinputs != "" } {
	$InputsArray($directinputs) UpdateObjectListFromGUI
    }


    set ret [ $this CheckInputObjects ] 
    if { $ret == 0 } {
	tk_messageBox -type ok -message "Failed to execute [ $this GetGUIName ] ... bad inputs" -title "Error!" -icon error
	return 0
    }
    
    $this WatchOn
    set ret [ $this Execute ]
    $this WatchOff
    if { $ret == 0 } {
	tk_messageBox -type ok -message "Failed to execute [ $this GetGUIName ] ... something is wrong with the options" -title "Error!" -icon error
	return 0
    }

    $this UpdateContainerWithOutput
    if { $callbackafter !=0 } {
	eval $callbackafter 
    }

    if { [ $OptionsArray(slicermode) GetValue ] > 0 } {
	puts stderr "Slicermode is not zero ... [ $OptionsArray(slicermode) GetValue ] saving\n"
	$this SaveObjects 
    }

    PrintDebug "\n\n\n\n Done Callback After $this"

    if { $hasoutputguis == 1 } {
	PrintDebug "Updating Outputs" 

	foreach name [ array names OutputsArray ] {
	    
	    $OutputsArray($name) UpdateInternalGUI 
#	    set gui [ $OutputsArray($name) GetObjectGUI ]
#	    if { $gui !=0  } {
#		set obj [ $OutputsArray($name) GetObject ]
#		$gui SetObject $obj
#		$gui Update
#	    } else 
	}
    }
    PrintDebug "\n\n\n\n Done Invoke Algorithm From GUI $this"
    return 1
}

itcl::body bis_algorithm::InitializeFromContainer { cont { eventcont 0 } } {

    $this SetGUIMode managed
    $this SetContainer $cont

    set ok [ $this CreateVTKObjects  ]
    #    puts stderr "[ $this info class ] Initializing from Container $cont, $ok"

    PrintDebug "Outputs Ok=$ok"

    set eventcontainerobject $eventcont
    PrintDebug "Inputs Ok=$ok"



}

itcl::body bis_algorithm::InitializeStandalone { } {

    $this SetGUIMode standalone
    set ok [ $this CreateVTKObjects  ]    
    PrintDebug "Inputs Ok=$ok ($ok)"
    return $ok
}

itcl::body bis_algorithm::InitializeTesting { { dogui 0 }  } {

    if { $dogui == 0 } {
	$this SetGUIMode commandline
	set ok [ $this CreateVTKObjects  ]    
	return $ok
    } 

    set ok [ $this InitializeStandalone ]
    return $ok
}

#-------------------------------------------------------------------------
# Stuff for testing
#-------------------------------------------------------------------------

itcl::body bis_algorithm::LoadTestFileName { fname { lineno -1 } } {

    if { [ file  exists $fname ] ==0 } {
	puts stderr "$fname not found"
	return 0
    }

    set myclassname [ string range  [ $this info class ] 2 end ]
    #    puts stderr "Myclassname is $myclassname "

    set outlist ""

    set fileid [open $fname r]
    set lcount 0
    while { [ gets $fileid line ] >=0 } {
	if { [ string first "#" $line ] !=0 } {
	    
	    set lst  [ split $line : ]
	    set n    [ llength $lst ]
	    if { $n == 4 } {
		set nlist [ list  [ string trim [ lindex $lst 1 ]] [ string trim [ lindex $lst 2 ]] [ string trim [ lindex $lst 3 ] ] "([file tail $fname]:L$lcount)" ]
		set algname [ string trim [ lindex $lst 0 ] ]

		if { ( $lineno < 0 ) || ( $lineno == $lcount ) } {
		    if { $algname ==  $myclassname } {
			lappend outlist $nlist
		    } elseif { [ file rootname $algname ]  ==  $myclassname } {
			lappend outlist $nlist
		    }
		}
	    } else {
		puts stderr "Bad Line *$line*, $n !=4 parts, line number=$lcount"
	    }
	}
	incr lcount
    }
    close $fileid
    return $outlist
}

# ---------------------------------------------------
itcl::body bis_algorithm::DualPrint { line { fout 0 } { usescriptname 1 } } {

    if { $usescriptname > 0 } {
	puts stdout "${scriptname}:$line"
    } else {
	puts stdout "$line"
    }
    if { $fout !=0 } {
	puts $fout $line
    }
}
# ---------------------------------------------------
itcl::body bis_algorithm::ReformatTestLine { line { extra "" } } {
    set ttline ""
    for { set i 0 } { $i < [ llength $line ] }  { incr i } {
	append ttline [ lindex $line $i ]
	if { $i == 0 && [ string length $extra ] > 1 } {
	    append ttline "($extra)"
	}
	if { $i < [ expr [ llength $line ] -2 ] } {
	    append ttline " : "
	} else {
	    append ttline " "
	}
    }
    return $ttline
}

# ---------------------------------------------------------------------------------------------------------------
itcl::body bis_algorithm::DoTestComparison { alg comparenames { fout 0  }  { ctestcreategold 0 } } {

    set finalstatus 1

    for { set i 0 } { $i < [ llength $comparenames ] } { incr i } {
	
	set obj [ $alg GetOutputObjectByIndex $i ]
	set n   [ $alg GetOutputObjectNameByIndex $i ]
	set outputobj [ lindex $comparenames $i ]
	if { [ $obj isa pxitclimage ] || [ $obj isa pxitclsurface ] } {
	    if { [ $alg GetOptionValue ctestexact ] ==1 } {
		set ok [ $obj  CompareTo $outputobj  [ $alg GetOptionValue ctestthr ] ]
	    } else {
		set ok [ $obj  CorrelateWith $outputobj  [ $alg GetOptionValue ctestthr ] ]
	    }
	} else {
	    set ok [ $obj  CompareTo $outputobj [ $alg GetOptionValue ctestthr ] ]
	}
	
	set textst ""
	if { [ llength $ok ] > 1 } {
	    set textst [ lindex $ok 1 ]
	    set ok [ lindex $ok 0 ]
	}
	
	if { $ok == 0 } {
	    $this DualPrint "-\t Failed comparison of output $n with  [ lindex $comparenames $i ] ($textst)" $fout
	    if { $ctestcreategold > 0 } {
		$this DualPrint "\t\t ****************** Overwriting [ lindex $comparenames $i ] with output"
		$obj SetFileName  [ lindex $comparenames $i ] 
		set okk [ $obj Save "" "Saving Fixed Result" ]
		$this DualPrint "\t\t ****************** Overwriting [ lindex $comparenames $i ] with output done=$okk"
	    }
	    set i [ llength $comparenames ]
	    set finalstatus 0
	} else {
	    if { [ file tail [ lindex $comparenames $i ] ] != "do_not_use" } {
		$this DualPrint "+\t Succesful comparison of output $n with  [ lindex $comparenames $i ] ($textst)" $fout
	    }
	}

	if { [ $alg GetOptionValue ctestsave  ] > 0 } {
           $this DualPrint "+ Saving outputs ....." $fout
           set ok [ $alg SaveObjects [ $alg GetOptionValue ctesttmpdir ] ]
           if { $ok == 1 } {
               $this DualPrint "+ [ $alg GetResultsMessage ]"
           } else {
               $this DualPrint "+ [ $alg GetErrorMessage ]"
           }
	}
    }
    
    $this DualPrint "+"
    return $finalstatus
}
# ---------------------------------------------------------------------------------------------------------------
itcl::body bis_algorithm::DoTestGUIComparison { alg comparenames { fout 0  }  { ctestcreategold 0 } } {

    set finalstatus 1

    set img [ $alg GetBisViewerImage ]
    if { $img == "0" } {
	return 0
    }

    set obj [ [ pxitclimage \#auto ] GetThisPointer ]
    $obj ShallowCopyImage $img
    $img Delete
    set compimagename [ lindex $comparenames 0 ]
	
    if { [ $alg GetOptionValue ctestexact ] ==1 } {
	set ok [ $obj  CompareTo $compimagename  [ $alg GetOptionValue ctestthr ] ]
    } else {
	set ok [ $obj  CorrelateWith $compimagename  [ $alg GetOptionValue ctestthr ] ]
    }

    set textst ""
    if { [ llength $ok ] > 1 } {
	set textst [ lindex $ok 1 ]
	set ok [ lindex $ok 0 ]
    }
    
    if { $ok == 0 } {
	$this DualPrint "-\t Failed comparison of viewer image with  $compimagename ($textst)" $fout
	if { $ctestcreategold > 0 } {
	    $this DualPrint "\t\t ****************** Overwriting $compimagename with viewer image"
	    set tplist { {"PNG Images" { .png }} }
	    set fname  [tk_getSaveFile -title "Saving $compimagename " -filetypes $tplist -initialfile [ file tail $compimagename ]  -initialdir [ file dirname $compimagename  ]  ]
	    if { [ string length $fname ] > 0 } {
		set w [ vtkPNGWriter New ]
		$w SetInput [ $obj GetImage ]
		$w SetFileName $compimagename
		$w Write
		$w Delete
	    } 
	    $this DualPrint "\t\t ****************** Overwriting $compimagename with viewer image done=[ file size $compimagename ]"
	}
	set finalstatus 0
    } else {
	$this DualPrint "+\t Succesful comparison of viewer output with  [ lindex $comparenames 0 ] ($textst)" $fout
    }
    
    if { [ $alg GetOptionValue ctestsave  ] > 0 } {
	set dr  [ $alg GetOptionValue ctesttmpdir ] 
	set fn  [ file join $dr [ pid ].png ]
	set w [ vtkPNGWriter New ]
	$w SetInput [ $obj GetImage ]
	$w SetFileName $fn
	$w Write
	$w Delete
	$this DualPrint "\t\t ****************** Saving Viewer Output in $fn done=[ file size $compimagename ]"
    }

    itcl::delete obj $obj
    return $finalstatus
}

# ---------------------------------------------------------------------------------------------------------------
itcl::body bis_algorithm::RemoveTempOutputDirectory { odir } {

    set ok 0
    catch { 
	file delete -force $odir 
	set ok 1
    }
    return $ok

}

# ---------------------------------------------------------------------------------------------------------------

itcl::body bis_algorithm::CreateTempOutputDirectory { odir } {

    set tmpdir $odir

    if { [ file tail $tmpdir ] == "BIOIMAGESUITE3_TESTING_TEMPDIR-NOTFOUND" } {
	set tmpdir ""
    }
    
    set processid [ pid ]
    if { [ string length $tmpdir ] > 1 } {
	if { [ file exists $tmpdir ] == 0 } {
	    set tmpdir ""
	} elseif { [ file writable [ file join $tmpdir $processid ] ] == 0 } { 
	    set tmpdir ""
	}
    }

    #    puts stdout "sofar =  $tmpdir"

    if { [ string length $tmpdir ] <  1 } {
	global env
	catch { set tmpdir $env(BISTEMP) }
	set ot [ file tail $tmpdir ]

	#puts stdout "sofar tmpdir=*${tmpdir}* ot=*${ot}*"
	if { $ot == "" || $ot == "\"\"" } {
	    global tcl_platform
	    puts stdout "Using default output directory ..... as *$ot* *$tmpdir*"
	    if { $tcl_platform(platform) == "windows" } { 
		set tmpdir c:/temp
	    } else {
		set tmpdir /tmp
	    }
	}
    }

    set tmpdir [ file normalize [ file join $tmpdir tmp_$processid ] ]
    catch { file mkdir $tmpdir }
    puts stdout "Using temp tmpdir=$tmpdir\n\n\n"
    return $tmpdir
}

# ------------------------------------------------------------------------------------------------------------------------

itcl::body bis_algorithm::RunTest { testline basedir { fout 0 } { extra "" } { ctestcreategold 0 } } {

    cd $basedir

    $this DualPrint  "\#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n+" $fout

    global tcl_platform
    
    set m0 $tcl_platform(user)
    set m1 $tcl_platform(os)
    set m2 $tcl_platform(osVersion)
    set m3 [ file normalize  [ info nameofexecutable ] ]

    $this DualPrint "+" $fout
    $this DualPrint  "+ $m0 on [ info hostname ] $m1, $m2 using $m3" $fout
    $this DualPrint "+" $fout
    $this DualPrint "+ I n v o k i n g   T e s t = [ $this ReformatTestLine $testline $extra]"  $fout
    $this DualPrint "+" $fout
    set myclassname [ string range  [ $this info class ] 2 end ]
    set alg [ $myclassname \#auto ]
    #    $this DualPrint "+Created $alg of type [ $alg info class  ]" $fout

    set paramnames [ lindex $testline 0 ]
    set inputnames ""
    set tmp [  lindex $testline 1 ]
    for { set i 0 } { $i < [ llength $tmp ] } { incr i } {
	lappend inputnames [ file normalize [ file join $basedir [ lindex $tmp $i ] ] ]
    }
    set tmp [  lindex $testline 2 ]
    set comparenames ""
    for { set i 0 } { $i < [ llength $tmp ] } { incr i } {
	lappend comparenames [ file normalize [ file join $basedir [ lindex $tmp $i ] ] ]
#	puts stdout "Adding   $basedir, [ lindex $tmp $i ] "
    }
    
    set paramnames [ concat $paramnames $extra ]
    $this DualPrint "+Inputs=*$inputnames*\tCompare=*$comparenames*\t+params=*$paramnames* (extra=$extra)" $fout
    $this DualPrint "+" $fout
    set fnd [ lsearch -regexp $paramnames "-*ctestgui" ]
    set dogui 0
    if { $fnd > -1 } {
	set dogui [ expr [ lindex $paramnames [ expr $fnd +1 ] ] > 0 ]
	#	puts stdout "Testing in GUI Mode! $dogui, $fnd"
	if { $dogui > 0 } {
	    $this SetOptionValue ctestgui 1
	}
    }

    

    $alg InitializeTesting $dogui
    set tp 0

    for { set i 0 } { $i < [ llength $paramnames ] } { incr i } {
	
	set pn [ lindex $paramnames $i ]
	if { [ string first "--"  $pn  ] == 0 } {
	    set pn [ string range $pn 2 end ]
	} elseif { [ string first "-"  $pn  ] == 0 } {
	    set pn [ string range $pn 1 end ]
	}

	set optionname $pn
	incr i 
	set optionvalue [ lindex $paramnames $i ]
	set tp [ lindex [ $alg GetOptionType $optionname ] 0 ]
	if { $tp == "filename" } {
	    set optionvalue [ file normalize [ file join $basedir $optionvalue ]]
	}
	$alg SetOptionValue $optionname $optionvalue
    }
    $alg SetInputArrayFilenames  $inputnames

    


    $alg LoadObjects
    set temptoplevel 0 
    if { $dogui == 1 } {
	set temptoplevel [ toplevel .[ pxvtable::vnewobj ] ]
	$alg CreateGUI $temptoplevel 0 0 1
	wm geometry $temptoplevel 600x600
	wm title $temptoplevel "BioImage Suite::[ $alg GetGUIName ] Applet Running in Testing Mode"
    }

    $this DualPrint "+ [ $alg GetCommandLine full ]" $fout
    $this DualPrint "+" $fout

    set tstart [ clock clicks -milliseconds ]

    if { $dogui == 1 } {
	set ok [ $alg InvokeAlgorithmFromGUI ]
    } else {
	set ok [ $alg Execute ]
    }
    set tend [ clock clicks -milliseconds ]

    $this DualPrint "+ Algorithm execution = $ok ([ expr 0.001*($tend-$tstart) ]s)" $fout
    $this DualPrint "+" $fout

    if { $dogui == 1 } {
	update idletasks
	after 1000
    }

    # Modify this to compare multiple outputs if need be
    set finalstatus 1

    if { $ok == 1 } {
	if { $dogui == 0 } {
	    set finalstatus [ $this DoTestComparison $alg $comparenames $fout $ctestcreategold ]
	} else {
	    set finalstatus [ $this DoTestGUIComparison $alg $comparenames $fout $ctestcreategold ]
	}
    } else {
	set finalstatus 0
    }

    
    if { $temptoplevel > 0 } {
	wm withdraw $temptoplevel
	destroy $temptoplevel
    }
    itcl::delete object $alg 
    
    return [ list $finalstatus [ expr $tend-$tstart ]]

}
# ---------------------------------------------------

itcl::body bis_algorithm::RunRegressionTests { messyfname args } {

    set extraparams ""
    set debug 0
    set debugname ""
    set ctestline -1
    set ctestcreategold 0

    if { $args != "" } {
	set tmp [ lindex $args 0 ]
#	puts stdout "Scanning $tmp"
	set l [ expr [ llength $tmp ] -1 ]
	for { set i 0 } { $i < $l } { set i [ expr $i+2 ] } {
	    set pn [ lindex $tmp $i ]
	    set v  [ lindex $tmp [ expr $i +1 ] ]

	    if { [ string first "--"  $pn  ] == 0 } {
		set pn [ string range $pn 2 end ]
	    } elseif { [ string first "-"  $pn  ] == 0 } {
		set pn [ string range $pn 1 end ]
	    }
	    
	    set ind  [ lsearch -exact $ctestextraflags $pn ] 
	#    puts stdout "Looking for $pn in $ctestextraflags, ind=$ind"
	    if { $ind > -1 } {
		if { [ $OptionsArray($pn) GetDefaultValue ] != $v  } {
		    lappend extraparams $pn
		    lappend extraparams $v
		    #puts stdout "Appending $pn $v"
		}
	    } elseif { $pn == "ctestdebug" } {
		if { [ string length $v ] > 1 } {
		    set debug 1
		    set debugname $v
		}
	    } elseif { $pn == "ctestline" } {
		if { [ string length $v ] > 0 } {
		    set ctestline $v
		}
	    } elseif { $pn == "ctestcreategold" } {
		if { [ string length $v ] > 0 } {
		    if { $v == "9999" } {
			set ctestcreategold 1
		    }
		}
	    }
	}
    }

    if { $ctestline ==-1 } {
	set ctestcreategold 0
    }
#    puts stdout "CtestLine = $ctestline "

    # Keep this 0


    set fname [ file rootname $messyfname ]
    set ext   [ file extension $messyfname ]

    if { $ext == "." } {
	set ext ".OFF"
    } elseif { $ext != ".ON" && $ext != ".OFF" } {
	set fname $messyfname
	set ext ".OFF"
    }

    set tlist [ $this LoadTestFileName $fname $ctestline ]
    if { $tlist == 0 } {
	return 0
    } 

    # Switch to the directory of the tests to allow for more non-absolute paths
    set basedirectory [ file normalize  [ file dirname $fname ] ]
#    puts stdout "Tests loaded from $fname, base=$basedirectory"
  

    set oklist ""
    if { $debug == 1 } {
	set fout [ open $debugname a ]
	$this DualPrint "*\n*\n*\n\#-------------------------------------------------------------------------------------------\n\#" $fout
	$this DualPrint "\# S T A R T I N G    N E W   M O D U L E    T E S T : $scriptname\n\#" $fout
	set f  [ clock format [ clock seconds ] -format "%d %b %Y at %H:%M:%S" ]
	$this DualPrint  "\#Debug output from  [ string range  [ $this info class ] 2 end ], [  info script ] ($f) ctestline=$ctestline" $fout
    } else {
	set fout 0
    }

    set allok 1

    set statuslist ""

    if { [ llength $tlist ] == 0 } {
	$this DualPrint "No tests for me" $fout
	if { $ext == ".ON" } {
	    set allok 0
	}
    } else  {
	for { set i 0 } { $i < [ llength $tlist ] } { incr i } {

	    set passlist [ $this RunTest [ lindex $tlist $i ] $basedirectory $fout $extraparams $ctestcreategold ]
	    set pass [ lindex $passlist 0 ]
	    set passtime [ lindex $passlist 1 ]
	    if { $pass > 0 } {
		append statuslist "++ [ $this ReformatTestLine [ lindex $tlist $i ] $extraparams ]  ... status = passed ($passtime ms)\n"
	    } else {
		append statuslist "-- [ $this ReformatTestLine [ lindex $tlist $i ] $extraparams ]  ... status = failed ($passtime ms)\n"
	    }
		
	    if { $pass == 0 } {
		set allok 0
	    }
	}
    }


    if { $ctestline == -1 } {
	if { $allok == 1 } {
	    $this DualPrint "+\n+\n+++++++++++++++++++++++++++++++ All Tests for $scriptname Passed +++++++++++++++++++++++++++++++ " $fout
	} else {
	    $this DualPrint "-\n-\n------------------------------- Some Tests for $scriptname Failed ------------------------------- " $fout
	}
	
	$this DualPrint "$statuslist*" $fout 0
    }
    if { $fout !=0 } {
	close $fout 
    }
    

    return $allok

}

#-------------------------------------------------------------------------
# Main Function
#-------------------------------------------------------------------------
itcl::body bis_algorithm::StripDashes { val } {

    if { [ string first "--"  $val  ] == 0 } {
	return [ string range $val 2 end ]
    }

    if { [ string first "-"  $val  ] == 0 } {
	return [ string range $val 1 end ]
    }

    return 0
}

itcl::body bis_algorithm::ProcessCommandline { argv { debug 0 } } {

    set lst [$this GetCmdLineOptionsList]

    set knownlist ""
    set errormessage ""
    foreach it $lst { 
	set sw [ file rootname [ lindex $it 0 ] ]
	set value($sw) [ lindex $it 1 ]
	set default($sw) [ lindex $it 1 ]
	lappend knownlist $sw
    }


    set len [ llength $argv ] 
    set lenm [ expr $len -1 ]
    set i 0
    set done 0 
    while { $i < $lenm && $done == 0 } {
	set opt [ $this StripDashes [ lindex $argv $i ] ]
	set found -1
	if { $opt !=0 } {
	    set found [ lsearch $knownlist $opt ]
	    if { $found > -1 } {
		
		# Increase i and get argument
		incr i
		set val [ lindex $argv $i ]
		set value($opt) $val

		if { $debug > 0 } {
		    puts stdout "\t\t value($opt) = $val"
		}
		
		# Increase i again and see if there is anything to be found (multi length args)
		incr i
	    } else {
		set errormessage "unknown option $opt"
		set done -1
	    }
	} else {
	    set done 1
	}
    }


    if { $done !=- 1 } {
	if { $debug > 0 } {
	    foreach q $knownlist {
		puts stdout "option $q, val= ( $value($q) ), default=( $default($q) )"
	    }
	}
	set extra [ lrange $argv $i end ]
	set f [ list [ array get value ] $extra ]
	if { $debug > 0 } {
	    puts stdout "f(0) = [ lindex $f 0 ]"
	    puts stdout "f(1) = [ lindex $f 1 ]"
	}
	return $f
    }

    return [ list 0 $errormessage ]
}

#-------------------------------------------------------------------------
# Define the error function
#----------------------------------------------------

itcl::body bis_algorithm::MainFunction { } {

    global argv
    package require vtkpxcontrib

    set n [ llength $argv ]
    if { $argv == "-help" || $argv == "--help" || $argv == "-h" || $argv == "--h" } {
	set n 0
	set forceguimode 0
    }
    if { $n == 0 && $forceguimode == 0 } {
	set ok [$this GetCmdLineOptionsList]
	$this PrintUsage
	exit
    }

    if {  [ lsearch $argv --xml ] > -1 } {
	set a "[ $this GetSlicerXMLDescription ]"
	puts stdout $a
	exit
    }
    

    if {  [ lsearch $argv --logo ] > -1 } {
	puts stdout [ ::bis_common::GetSlicerXMLLogo ]
	exit
    }

    if {  [ lsearch $argv --json ] > -1 } {
	set a "[ $this GetJSONDescription ]"
	puts stdout "$a"
	exit
    }
    

    set lst [ $this ProcessCommandline $argv ]
    set v [ lindex $lst 0 ]
    if { $v == 0 } {
	$this PrintUsage
	puts stderr "\n parameter parsing error = [ lindex $lst 1 ]"
	exit
    }
    set parameterlist [ lindex $lst 0 ]
    set extrafilenames [ lindex $lst 1 ]

    set dogui 0;    set doctest 0 ;    set doloni 0

    if { $forceguimode > 0 } {
	set dogui 1
    } else {
        set found [ lsearch $parameterlist dogui ]
	if { $found > -1 } {
	    set indx [ expr $found +1 ]
	    if { $indx < [ llength $parameterlist ] } {
		set dogui [ expr [ lindex $parameterlist $indx ] > 0 ]
	    }
	} 
    }


    if { $dogui == 0 } {
	set found [ lsearch $parameterlist loni ]
	if { $found > -1 } {
	    set indx [ expr $found +1 ]
	    if { $indx < [ llength $parameterlist ] } {
		set doloni [ lindex $parameterlist $indx ] 
		if { $doloni != 1 && $doloni !=2 } {
		    set doloni 0
		}
	    }
	}
    }
    
    if { $dogui == 0 && $doloni == 0 } {
	set found [ lsearch -exact $parameterlist ctest ]
	if { $found > -1 } {
	    set indx [ expr $found +1 ]
	    if { $indx < [ llength $parameterlist ] } {
		set ctestfname [  lindex $parameterlist $indx ]
		if { $ctestfname != 0 } {
		    set doctest 1
		}
	    }
	}
    }


    package require pxtcluserprefs 1.0
    set version $::pxtclvtkpxcontrib::version


    
    if { $dogui == 0 && $doctest == 0 && $doloni == 0 } {
	if { [ $OptionsArray(slicermode) GetValue ] > 0 } {
	    puts stdout "Called from slicer [ $this GetCommandLine full ]"
	}
	wm withdraw .
	$this RunCommandLine $parameterlist  $extrafilenames
	pxtkexit
    } elseif { $doloni > 0 } {
	puts stdout "[ $this GetLONIXMLDescription $doloni ]"
	pxtkexit
    } elseif { $doctest == 1 }  {
	wm withdraw .
	set ok [ $this RunRegressionTests $ctestfname $parameterlist ]
	# our codes and unix codes are inverted!
	set ctestgui [ $this GetOptionValue ctestgui ]
	puts stdout "${scriptname}:+\n${scriptname}:+ Test finished ok=$ok ctestgui=$ctestgui"

	if { $ok == 0 } {
	    if { $ctestgui == 0 } {
		exit 1
	    } else {
		update idletasks
		destroy .
		after idle exit 1
	    }
	} elseif { $ctestgui == 0 } {
	    exit 0
	} else {
	    update idletasks
	    destroy .
	    after idle exit 0
	}
    } else {
	package require pxappscommon 
	set tp [ toplevel .[ pxvtable::vnewobj ] ]
	$this InitializeStandalone 
	set ret [ $this SetParameters $parameterlist ]
	if { $ret == 0 } {
	    $this PrintUsage; 
	    puts stderr "\n\n The following error has occurred: $errormessage\n"  
	    exit 1
	}

	set ret [ $this SetInputArrayFilenames  $extrafilenames ] 

	$this LoadObjects 
	$this CreateGUI $tp
	$this UpdateInputsFromContainer 


	if { [ $OptionsArray(slicermode) GetValue ] == 0 } {
	    wm title $tp "BioImage Suite::[ $this GetGUIName ] Applet"
	} else {
	    wm title $tp "BioImage Suite::[ $this GetGUIName ] Applet -- called from Slicer"
	}

	if { [ $this GetViewer ] ==0 } {
	    wm geometry $tp 500x600
	} elseif { $forceguimode == 0 } { 
	    wm geometry $tp 1024x600
	}
	update idletasks
    }
}
