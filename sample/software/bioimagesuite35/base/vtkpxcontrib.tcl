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

package provide vtkpxcontrib 1.2
package provide vtknrcontrib 1.2

# 	$Id: vtkpxcontrib.tcl,v 1.2 2005/12/01 16:42:14 xenios Exp xenios $	

lappend auto_path [ file dirname [ info script ]]
lappend auto_path [ file join [ file join [ file join  [ file dirname [ info script ]] .. ] extensions ] lib ]

package require pxtclutil

namespace eval ::pxtclvtkpxcontrib {

    variable osmode       unix
    variable libraryprefix     lib
    variable librarysuffix     .so
    variable librarypath       ""
    variable staticsuffix      .a
    variable execsuffix        ""
    variable baselibrarypath [ file normalize [  file join [ file join [ file dirname [ info script ]] .. ] lib ] ]
    variable  imagedir [ file normalize [ file join [ file join [ file dirname [ info script ]] .. ] images ] ]

    variable vtkpxlibrarylist {   vtkpxCommonTCL vtkbisDatabaseTCL vtkpxGraphicsTCL  vtkpxLegacyTCL  vtkpxImagingTCL  vtkpxRegistrationTCL  vtkpxSegmentationTCL vtkbisConnectivityTCL }
    variable vtkpxguilibrarylist { vtkpxGUITCL  vtkpxtklib Vtkpxtklib   }
    variable debugmode 0



    variable versionno   "3.5a1"
    variable versiontag  "35"
    variable versiondate "Feb 12th, 2014"
    variable version  "BioImage Suite ${versionno} $versiondate"
    variable usescuda   0

    variable yalelogo  0
    variable logo      0  
    variable smalllogo 0
    variable fontname  0
    variable betamode  0
    variable bioimagesuiteicon ""

    # -------------------------------------------------------------------------
    # Initialize Logos
    # -------------------------------------------------------------------------


    proc CheckForUpdates { } {

	variable betamode 

	if { $betamode == 0 } {

	    set ok "yes"
	    catch { 	set ok [ tk_messageBox -title "Checking for Updates" -type yesno  -message "May BioImage Suite phone home (connect to www.bioimagesuite.org) to check for updates?\n(This involves downloading the file http://www.bioimagesuite.org/VERSION.txt)"  ] }
	    if { $ok == "no" } {
		return -1 
	    }
	    
	    set ver 0
	    catch {
		set ver [http::data [http::geturl "http://www.bioimagesuite.org/VERSION.txt" ]]
	    }
	    if { $ver == 0 } {
		catch { tk_messageBox -type ok -message "Connection to www.bioimagesuite.org failed\n" -title "Connection Error!" }
		return -1
	    }
	    
	    if { $ver != $::pxtclvtkpxcontrib::version } {
		catch { tk_messageBox -type ok -title "For your information ..." -icon info -message "A Newer version is available:\n$ver\nYour current version is\n$::pxtclvtkpxcontrib::version" }
		return 0
	    } 
	    catch { tk_messageBox -type ok -title "For your information ..." -icon info -message "Your Version of BioImage Suite is up to date\n($::pxtclvtkpxcontrib::version)" }
	    return 1
	} else {
	    catch { tk_messageBox -type ok -title "For your information ..." -icon info -message "You are using a beta version of BioImage Suite (no updates available)\n($::pxtclvtkpxcontrib::version)" }
	    return 1
	}

    }


    
    proc InitializeBioImageSuiteLogos { } {
	variable yalelogo  
	variable logo      
	variable smalllogo 
	variable fontname  
	variable imagedir
	variable betamode
	variable bioimagesuiteicon 
	global tcl_platform

	catch {
	    variable logo [ image create photo -file [ file join $imagedir  bioimagesuite_logo_www.gif ] ]
	    variable smalllogo [ image create photo -file [ file join $imagedir bioimagesuite_logo_small_www.gif ] ]
	    variable fontname { Helvetica 10 bold }
	}

	if { $tcl_platform(platform) == "windows" } { 
	    set bioimagesuiteicon  [ file join $imagedir bioimagesuite.ico ]
	} else {
	    set bioimagesuiteicon  [ file join $imagedir bioimagesuite.xbm ]
	}

	if { $tcl_platform(platform) == "windows" } { 
	    wm iconbitmap . -default $::pxtclvtkpxcontrib::bioimagesuiteicon 
	} 

    }

    # -------------------------------------------------------------------------

    proc CheckVisualStudioVersion { } {

	variable libraryprefix
	variable librarysuffix
	variable baselibrarypath
	variable librarypath
	variable debugmode
	variable osmode
	variable vtkpxlibrarylist

	set path3    [ file normalize $baselibrarypath ]
	set libraryname [ lindex $vtkpxlibrarylist 0 ]
	set libname5 [ file join $path3 "lib/Release/${libraryprefix}${libraryname}${librarysuffix}" ]
	set libname1 [ file join $path3 "Release/${libraryprefix}${libraryname}${librarysuffix}" ]
	set libname2 [ file join $path3 "Debug/${libraryprefix}${libraryname}${librarysuffix}" ]
	set libname3 [ file join $path3 "${libraryprefix}${libraryname}${librarysuffix}" ]
	set libname4 [ file join $path3 "lib${libraryname}${librarysuffix}" ]

	set tm5 -3; catch { set tm5 [ file mtime $libname5 ] }
	set tm1 -2; catch { set tm1 [ file mtime $libname1 ] }
	set tm2 -3; catch { set tm2 [ file mtime $libname2 ] }
	set tm3 -1; catch { set tm3 [ file mtime $libname3 ] }
	set tm4 -1; catch { set tm4 [ file mtime $libname4 ] }

	if { $debugmode > 0 } {
	    puts stderr "File Times:\n\t $libname1 ($tm1), $libname2 ($tm2), $libname3 ($tm3)\n\t $libname4 ($tm4)\n"
	}

	set domsys 0

	if { $tm1 < 0 && $tm2 < 0 && $tm3 < 0 && $tm5 < 0 && $tm4 >= 0 } {
	    set domsys 1
	} elseif { $tm4 == -1 && ($tm1 >= 0 || $tm2 >= 0 || $tm3 >= 0 || $tm5 > 0 ) } {
	    set domsys 0
	}  else {
	    global env
	    set a ""
	    catch { set a $env(MSYSTEM) }
	    if { $a == "MINGW32" } {
		set domsys 1
	    }
	}
	 
	# Returning ....
	
	set extra ""

	if { $domsys == 1 } {
	    # msys
	    set libraryprefix "lib"
	} elseif { $tm3 > $tm2 && $tm3 > $tm1 && $tm3 > $tm5 } {
	    set extra ""
	} elseif { $tm2 > $tm1 && $tm2 > $tm5 } {
	    set extra "Debug"
	} elseif { $tm5 > $tm1 } {
	    set extra "lib/Release"
	} else {
	    set extra "Release"
	}
	    
		
	if { $debugmode > 0 } {
	    puts stdout "msys=$domsys, libraryprefix=*$libraryprefix*, extra=$extra"
	}
	return $extra
    }


    proc InitializePlatform { } {

	global tcl_platform
	variable osmode
	variable libraryprefix
	variable librarypath
	variable librarysuffix
	variable debugmode
	variable staticsuffix
	variable baselibrarypath
	variable execsuffix

	global env
	catch {
	    set bpath $env(BIOIMAGESUITE3_BINARY_DIR)
	    if { $bpath != "" } {
		set baselibrarypath [ file normalize [ file join $bpath "lib" ]]
		eval { after 2000 puts stdout \"BioImage Suite::using baselibrarypath =$bpath\" }
	    }
	}


	if { $tcl_platform(os) == "Darwin" } {
	    if { [ file dirname [ info nameofexecutable ] ] == "/usr/local/vtk44_carbon_yale/bin" } {
		set extraname "carbon"
		set osmode  macos
	    } else {
		set osmode macosx11
	    }
	} elseif { $tcl_platform(platform) == "windows" } { 
	    catch {
		set exename [ info nameofexecutable ]
		
		if { [ string first cygwin $exename ] > 0 } {
		    set osmode windowscygwin
		}
	    }
	    
	    if { $osmode != "windowscygwin" } {
		set osmode windows
	    }
	    set execsuffix ".exe"
	}

	switch -exact -- $osmode { 
	    "unix" {
		set libraryprefix "lib"
		set librarysuffix ".so"
		set librarypath    ""
	    }
	    "windowscygwin" {
		set libraryprefix "lib"
		set librarysuffix ".dll" 
		set librarypath "cygwin"
	    }
	    "windows" {
		set libraryprefix ""
		set librarysuffix ".dll" 
		set staticsuffix  ".lib"
		set librarypath [ CheckVisualStudioVersion ] 
		# test release vs debug
	    }
	    "macos" {
		set libraryprefix "lib"
		set librarysuffix ".dylib"
		set librarypath   "carbon"
	    } 
	    "macosx11" {
		set libraryprefix "lib"
		set librarysuffix ".dylib"
		set librarypath   ""
	    }
	}

    }


    # -------------------------------------------------------------------------

    proc LoadVTKLibraries { } {


	global env
	global tcl_platform	
	global auto_path
	variable debugmode

	set fname [ string range [ file root [ file tail [ info nameofexecutable] ]] 0 2]
	
	if { $fname != "vtk"} {
	    if { $tcl_platform(platform) == "windows"} {
		set suffix ".exe"
		set divider ";"
	    } else {
		set suffix ""
		set divider ":"
	    }
	
	    set newpath "[ file dirname [ info nameofexecutable ]]${divider}$env(PATH)"

	    set plist [ split $newpath $divider ]
	    set ppath ""
	    set flag 0
	    set len [ llength $plist ]
	    set i 0
	    while { $i < $len && $flag == 0 } {
		set ppath [ lindex $plist $i ]
		
		if { [ file exists [ file join $ppath vtk$suffix ]] == 1 } {
		    set flag 1
		}
		incr i
	    }
	    
	    
	    if { $flag == 1 } {
		if { $tcl_platform(platform) == "windows"} {
		    lappend auto_path [ file join $ppath "../Wrapping/Tcl" ]
		}
		lappend auto_path [ file join $ppath "../lib/vtk/tcl" ]

		if { $fname == "tcl" } {
		    catch {		   
			package require vtkbase
			package require vtkcommon
			package require vtkfiltering
			package require vtkgraphics
			package require vtkhybrid
			package require vtkimaging
			package require vtkio
			package require vtkparallel
			package require vtkpatented
			package require vtkrendering
			package require infovis
			package require volumerendering
		    }
		} else {
		    package require vtk 
		}
	    } else {
		tk_messageBox -type ok -message "Cannot find vtk.exe in your path!     [ info nameofexecutable ]" -title "Error!" -icon error
		exit
	    }
	}
    }

    # -------------------------------------------------------------------------
    proc LoadLibrary { libraryname initialcommand { dbmode 0 } } { 

	variable libraryprefix
	variable librarysuffix
	variable baselibrarypath
	variable librarypath
	variable osmode
	
	#	puts stdout "Loading $libraryname $dbmode"
	set path    [ file join $baselibrarypath $librarypath ]
	set libname [ file join $path "${libraryprefix}${libraryname}${librarysuffix}" ]

	if { [ file exists $libname ] } {
	    global env
	    global tcl_platform	
	    if { $tcl_platform(platform) == "windows"} {
		if { [ lsearch -exact [ split $env(PATH) ";" ] [ file normalize $path ] ] == -1 } {
		    set env(PATH) "$env(PATH);[ file normalize $path ]"
		    set dbmode 1
		    #		    puts stdout "Adding $path to PATH"
		}
	    } else { 
		set envname "LD_LIBRARY_PATH"
		if { $tcl_platform(os) != "Darwin" } {
		    set envname DYLD_LIBRARY_PATH
		}
		
		set ld ""
		set ind -1
		catch { 
		    set ld $env($envname) 
		    set ind [ lsearch -exact [ split $ld ":" ] [ file normalize $path ] ]
		}

		#		puts stdout "\n ++++++++++ ind=$ind ld=$ld"

		if { $ld == "" } {
		    set env($envname) [ file normalize $path ]
		    set dbmode 1
		    #  puts stdout "***************** Setting  $envname to $path, $env($envname)"
		} elseif { $ind == -1 } {
		    set env($envname) "$env($envname):[ file normalize $path ]"
		    set dbmode 1
		    #  puts stdout "Adding $path to $envname"
		} 
	    }


	    if { $dbmode > 0 } {
		eval { after 2000 puts stderr \"BioImage Suite::loading $osmode $libname\" }
	    }
	    
	    if { $dbmode > 0  } {
		puts stdout "Loading $libname "
	    }
	    
	    if { $initialcommand == "" } {
		return [ load $libname  ]
	    } else {
		return [ load $libname $initialcommand  ]
	    }
	} else {
	    eval { after 2000 puts stderr \"$libname does not exist\" }
	}
	return 0
    }

    # -------------------------------------------------------------------------
    proc ConditionalLoadLibrary { libraryname classname { dbmode 0 } } { 

	variable libraryprefix
	variable librarysuffix
	variable baselibrarypath
	variable librarypath
	variable osmode
	set dbmode 0
	
	set cl 0
	catch { 
	    set cl [ eval "$classname New" ]; 
	    $cl Delete
	    puts stdout "Library $libraryname exists"
	    set cl 1
	}

	if { $cl == 1 } {
	    if { $dbmode > 0 } {
		puts stdout "Library $libraryname already loaded, class=$classname exists"
	    }
	    return 1
	}

	set path    [ file join $baselibrarypath $librarypath ]
	set libname [ file join $path "${libraryprefix}${libraryname}${librarysuffix}" ]

	if { [ file exists $libname ] } {
	    
	    if { $dbmode > 0 } {
		puts  stdout "Loading $osmode $libname $dbmode"
	    }
	    return [ load $libname  ]
	} else {
	    puts stderr "$libname does not exist"
	}
	return 0
    }
    # -------------------------------------------------------------------------
    proc LoadGUILibraries { librarylist } {

	LoadLibrary [ lindex $librarylist 0 ] [ lindex $librarylist 1 ]
    }

    # -------------------------------------------------------------------------
    proc LoadLibraries { librarylist } {


	for { set i 0 } { $i < [ llength $librarylist ] } { incr i  } {
	    set flag 0
	    if { $i == 0 } {
		set flag 1
	    }
	    LoadLibrary [ lindex $librarylist $i ] "" $flag
	}
    }
    # -------------------------------------------------------------------------
    proc LoadAll { } {

	variable vtkpxlibrarylist
	variable vtkpxguilibrarylist
	
	global vtkpxcontrib_no_gui
	LoadLibraries $vtkpxlibrarylist

	set dogui 1

	catch { 
	    if { $vtkpxcontrib_no_gui == 1 } {
		set dogui 0
	    }
	}

	if { $dogui == 1 } {
	    LoadGUILibraries $vtkpxguilibrarylist
	}
    }
    # -------------------------------------------------------------------------
}

catch {
    rename toplevel tk_toplevel
}
 
# A Safer toplevel command with icons and DELETE_WINDOW protocol by default

proc toplevel { args } {
    global tcl_platform
    set ok [ eval "tk_toplevel $args" ]
    if { $tcl_platform(platform) != "windows" } { 
	wm iconbitmap $ok  @$::pxtclvtkpxcontrib::bioimagesuiteicon 
    }
    eval "wm protocol $ok WM_DELETE_WINDOW {  wm withdraw $ok }"
    return $ok
}

#proc pxtkexit { } {
#
#    update idletasks
#    destroy .
#    exit
#}



set doload 1
catch { 
    if { $vtkpxcontrib_no_load == 1 } {
	set doload 0
    }
}

if { $doload == 1 } {
    ::pxtclvtkpxcontrib::LoadVTKLibraries
}

::pxtclvtkpxcontrib::InitializePlatform
::pxtclvtkpxcontrib::InitializeBioImageSuiteLogos
 
if { $doload == 1 } {
    ::pxtclvtkpxcontrib::LoadAll
}

catch { 
    set dv [ vtkbisCUDAUtil New ]
    set ::pxtclvtkpxcontrib::usescuda  1
    $dv Delete
}





unset doload


