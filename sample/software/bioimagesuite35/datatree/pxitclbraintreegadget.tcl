#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" "$@"

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

# This used to be pxitclsurgerygadget.tcl --- complete working version


package provide pxitclbraintreegadget 1.0

# 	$Id: pxitclsurgerygadget.tcl,v 1.2 2004/02/03 17:36:31 xenios Exp xenios $	

#This package does nothing but set the required paths
lappend auto_path [file dirname [info script]]
package require pxitclchellypackages 1.0

package require chellyGUI_2
package require bis_treegui 
package require bis_guitreecreate4d 1.0

#package require  vtkpxcontrib 1.1
package require  labelframe   1.0
package require  pxtclutil    1.0
package require  pxvtable     1.0
package require  pxtclhelp    1.0
package require  Itcl         
package require  Iwidgets     4.0
package require  pxitclimage            1.0
package require  pxitcltransform        1.0
package require  pxitclsubjectentry     1.0
package require  pxitclbaseimagecontrol 1.0
package require  pxitclbaseimageviewer  1.0
package require  pxitcloverlaytab      1.0



# ----------------------------------------------------------------------------------------------

itcl::class pxitclsurgerygadget {
    
    inherit pxitclbaseimagecontrol
    
    # Generic Stuff 
    private   common   thisparam        
    
    # New Base Widget
    protected variable basewidgetframe 0
    
    # Subject Specific
    
    protected variable second_viewer      0
    public    variable electrodecontrol   0
    public    variable electrodecontrol2  0
    public    variable overlaycontrol     0
    public    variable functional_menu    0
    
    public variable overlayinputbase -1
    public variable overlayinputfunc -1
    
    protected variable image1_control    0
    protected variable image2_control   0
    protected variable image3_control   0
    protected variable transformation_control    0
    
    public    variable chellyMain
    public    variable menubase 0
    public    variable  overlaytool     0
    public    variable  OCbgcolor 
    public    variable ResliceCanvas -1
    
    public variable useNew 0 ; # use the new style datatree
    
    #public method GetViewer  { } { return $second_viewer }
    public method getTreeGUI { } { return chellyMain } 
    public method SetValueImage { vtkimg  } 

    constructor { par args } {
	pxitclbaseimagecontrol::constructor $par 
    } {
	
	if { [ llength $args] > 0  } {
	    set second_viewer [ lindex $args 0 ]
	}
	InitializeSurgeryGadget
	set OCbgcolor "LightSteelBlue1"	

	set overlaybase     [ [pxitclimage \#auto] GetThisPointer ]
	set overlayfunction [ [pxitclimage \#auto] GetThisPointer ]
	set overlaytool [ [ pxitcloverlaytabGUI \#auto $this ] GetThisPointer ]
	$overlaytool configure -disable_colormapchoice 0
	set appname "BioImage Suite::DataTree Tool"
    }
    
    private method InitializeSurgeryGadget { } 
    public method Initialize { widget }
    public method bindWindowClose { }

    public method AddToMenuButton { mb args } 
    public method AddToMenuButtonLite { mb args } 
    public method SetResultsFromObject { img obj  } 
    public method SetLookupTable       { colormap }
    public method SetLookupTableMode   { index }
    
    public method GetImageControl1 { } { return $image1_control }
    public method GetImageControl2 { } { return $image2_control }
    public method GetImageControl3 { } { return $image3_control }
    
    # ---------------------------
    # Subject Specific Callbacks
    # ---------------------------
    protected method CreateOverlayControl   { widget }
    protected method CreateImageControl     { widget }
    protected method CreateMainControl      { widget menubase }
    
    public    method SetOverlayToolInputs {  base_image functional_image } 
    public    method ProcessResults { filter opname  } 
    public    method ProcessResultsImage { img opname  } 
    public    method SetImageToViewer { img viewer }
    
    public method VerifyRegistrationCallback { mode args }
    public method VerifyRegistration { imgcontrol1 imgcontrol2 xformcontrol }
    
    
}

# ---------------------------------------------------------------------------

itcl::body pxitclsurgerygadget::InitializeSurgeryGadget { } {
    
    set transformation_control [ [  pxitcltransformGUI \#auto ] GetThisPointer ]
    $transformation_control configure -description "Transformation Image1->Image2"
    
    set image1_control [ [ pxitclimageGUI \#auto  ] GetThisPointer ]
    $image1_control configure -description "Reference Space Image (defines coordinate system)"
    
    set image2_control [ [ pxitclimageGUI \#auto  ] GetThisPointer ]
    $image2_control configure -description "Anatomical Image"
    
    set image3_control [ [ pxitclimageGUI \#auto  ] GetThisPointer ]
    $image3_control configure -description "Functional Image"
    
    set thisparam($this,overlayviewer) "Reference"
    if { $second_viewer !=0 } {
	set thisparam($this,overlayviewer) "Transform"
    }
    
}
#--------------------------------------------------------------------------------------------
itcl::body pxitclsurgerygadget::SetValueImage { vtkimg  } {
    if {$thisparam($this,overlayviewer) == "Transform" && $second_viewer !=0 } {
	$second_viewer SetValueImage $vtkimg
    } else {
	$parent SetValueImage $vtkimg
    }
}

itcl::body pxitclsurgerygadget::SetResultsFromObject { img obj  } {
    
    if { [ $img GetImageSize ] < 2 } {	
	return 0    
    }
    
    if { $obj == $overlaytool && $parent !=0 } {
	
	# Edit Stuff Here
	# ---------------
	
	if {$thisparam($this,overlayviewer) == "Transform" && $second_viewer !=0 } {
	    $second_viewer SetResultsFromObject $img $this

	} else {
	    $parent SetResultsFromObject $img $this
	}

    } else {
        SetResults $img
    }
    return 1
}

# ---------------------------------------------------------------------------
#  Lookup Table Stuff 
# ---------------------------------------------------------------------------

itcl::body pxitclsurgerygadget::SetLookupTable { colormap } {
    
    set v $parent
    if {$thisparam($this,overlayviewer) == "Transform" && $second_viewer !=0 } {
	set v $second_viewer
    }
    
    if { $v != 0 } {
	$v SetLookupTable $colormap
    }
}

itcl::body pxitclsurgerygadget::SetLookupTableMode { index } {
    
    set v $parent

    if { $thisparam($this,overlayviewer) == "Atlas" } {

	# 
	#  Needs Editing
	#
	# set vtk_viewer = [ [ chellyMain GetAtlas ] GetViewer ]
	# $vtk_viewer SetLookupTableMode $index 
    }

    if {$thisparam($this,overlayviewer) == "Transform" && $second_viewer !=0 } {
	set v $second_viewer
    }
    
    if { $v != 0 } {
	$v SetLookupTableMode [ expr 0+$index ]
    }
}


#---------------------------------------------------------------------------
#   
# Output Stuff
#
# ---------------------------------------------------------------------------
itcl::body pxitclsurgerygadget::VerifyRegistrationCallback { mode args } { 
    
    if { $mode == 1 } {
	$this VerifyRegistration $image1_control $image2_control  $transformation_control
    } 
}


itcl::body pxitclsurgerygadget::VerifyRegistration { imgcontrol1 imgcontrol2 xformcontrol } {
    
    global pxtcl_pref_array
    
    set image_ref [ $imgcontrol1 GetObject ]
    set image_trn [ $imgcontrol2 GetObject ]
    
    set orient_ref [ $image_ref GetOrientation ]
    set orient_trn [ $image_trn GetOrientation ]
    
    set dim1 [ [ $image_ref GetImage ] GetDimensions ]
    set dim2 [ [ $image_trn GetImage ] GetDimensions ]
    if { [lindex $dim2 0 ] <2 || [ lindex $dim1 0 ] < 2 } { 
	::pxtclutil::Warning "No Image in Memory\n Cannot Verify Transformation!"
	return  0
    }
    
    WatchOn
    
    set ut [ vtkpxUtil [ pxvtable::vnewobj ]]
    set tr [ $xformcontrol GetTransformation ]
    set tmp  [ [  pxitclimage \#auto ] GetThisPointer ]
    $ut ResliceImage [ $tmp GetImage ] [ $image_trn GetImage ] [ $image_ref GetImage ] [ $tr GetTransformation ] 1 0.0
    
    $tmp CopyImageHeader [ $image_ref GetImageHeader ]
    $tmp configure -filename "trn_[$image_trn cget -filename ]"
    
    $parent SetResultsFromObject $image_ref $this
    $second_viewer SetResultsFromObject $tmp $this
    catch { itcl::delete object $tmp }
    
    WatchOff
    return 1
}
#--------------------------------------------------------------------------------------------



itcl::body pxitclsurgerygadget::SetImageToViewer { img viewer } {
    
    # img is a pxitclimage
    # viewer is 
    # viewer ref or trn
    
    set vtk_viewer 0
    
    catch { 	set vtk_viewer [ $parent  GetViewer ]  }
    
    if { $thisparam($this,overlayviewer) == "Transform" } {
	catch { set vtk_viewer [ $second_viewer  GetViewer ]  }
    }
    
    if { $vtk_viewer !=0 } {
	$vtk_viewer SetImage [ $img GetImage ] [ $img GetOrientation ]
    }
    
}

itcl::body pxitclsurgerygadget::SetOverlayToolInputs { base_image functional_image } {
    
    set overlayinputbase $base_image
    set overlayinputfunc $functional_image

    $overlaytool SetImage $overlayinputbase
    $overlaytool SetFunctionalImage $overlayinputfunc
    set tr [ vtkIdentityTransform [ pxvtable::vnewobj ]]
    $overlaytool SetTransformation $tr
    $tr Delete
}

itcl::body pxitclsurgerygadget::CreateImageControl { widget } {
    
    #Obsolete for now (the controls are put in by chellyGUI)
    

}


# ----------------------------------------------------------------------------------------------
itcl::body pxitclsurgerygadget::CreateOverlayControl { widget } {


    
    frame $widget.t3 -background $OCbgcolor
    pack $widget.t3  -side top -expand f -fill x -pady 4
    # --------------------------
    # Visualization Output Stuff
    # --------------------------
    iwidgets::Labeledframe $widget.t3.a -labelpos n -labeltext "Reslice Output" -background $OCbgcolor
    iwidgets::Labeledframe $widget.t3.b -labelpos n -labeltext "Output Overlay" -background $OCbgcolor
    set c2 [$widget.t3.a childsite]
    set c3 [$widget.t3.b childsite]
    $c2 configure -background $OCbgcolor
    $c3 configure -background $OCbgcolor
    pack $widget.t3.a $widget.t3.b -side top -fill both -padx 5 -pady 2
    
    set w2 [ frame $c3.ttop -background $OCbgcolor -padx 8 -pady 2];
    pack $w2 -side bottom -expand 1 -fill x -padx 80
    
    #   if { $second_viewer != 0 } {
    label $w2.ml -text "Output Viewer:" -background $OCbgcolor
    tk_optionMenu $w2.mopt [ itcl::scope thisparam($this,overlayviewer)] "Reference" "Transform" 
    $w2.mopt configure -background "LightBlue3" -activebackground "LightBlue1"
    pack $w2.ml -side left -expand 0 -fill x
    pack  $w2.mopt -side left -expand 1 -fill x
    
    #   }
    
    set ResliceCanvas [$overlaytool CreateResliceControl $c2]
    $overlaytool CreateFunctionalOverlayControl $c3
    

}


# ---------------------------------------------------------------------------
# Main GUI Body 
# ---------------------------------------------------------------------------

itcl::body pxitclsurgerygadget::Initialize { widget } { 

    set basewidget $widget    

    set basewidgetframe [ frame $basewidget.[ pxvtable::vnewobj ] -height 660 -width 960 ]
    pack $basewidgetframe -side top -expand true -fill both

    SetTitle "BioImage Suite - Data Tree Manager"
        

#--------------------------------------------------------------------------------
#    Old, frame-based menu bar
#--------------------------------------------------------------------------------
#    set menubase     [ frame $basewidget.menu    -width 400 -height 50 ]
#    pack $menubase -side top -expand f -fill x -pady 1 
#--------------------------------------------------------------------------------
    set menubase      [ $basewidget cget -menu ]
    #    [ menu $basewidget.mdtopmenu -tearoff 0  ]
    #$basewidget configure -menu $menubase
    set notebook  0
    set fr [ frame $basewidgetframe.notebook -background $OCbgcolor]
    
 
    pack $fr -side top -expand t -fill both -pady 1
    
    # Clean Menus
    #    set childlist [ winfo children $menubase ]
    
    #    set functional_menu [ lindex $childlist 3 ]
    #    puts "functional_menu $functional_menu"
 
    #--------------------------------------------------------------------------------
    #-----Most of Chelly GUI is created right here:----------------------------------
    CreateMainControl $fr $menubase
    #--------------------------------------------------------------------------------

#     $menubase delete 0 3
#     $menubase add cascade -underline 0  -label "Viewers"  -menu [ lindex $childlist 0 ]
#     $menubase add cascade -underline 2  -label "Registration"  -menu [ lindex $childlist 2 ]   
    
#     #Set the background for all menu entries
#     for {set i 0} {$i <= [[lindex $childlist 0 ] index end]} {incr i} {
# 	[lindex $childlist 0] entryconfigure $i -background [ $chellyMain cget -menucolor ]
#     }
#     for {set i 0} {$i <= [[lindex $childlist 2 ] index end]} {incr i} {
# 	[lindex $childlist 2] entryconfigure $i -background [ $chellyMain cget -menucolor ]
#     }

#     set vmenu [ lindex $childlist 0 ]
#     $vmenu delete end
#     $vmenu delete end

    
   
#    $menubase add cascade -underline 3  -label "Functional"  -menu [ lindex $childlist 3 ]
#    $menubase add cascade -underline 1  -label "Transfer"  -menu [ lindex $childlist 1 ]
    
    # critical command 
    eval "wm protocol $basewidget WM_DELETE_WINDOW { $this bindWindowClose }"
    #eval "wm protocol $basewidget WM_DELETE_WINDOW { $this ExitCommand  }"
    $this ShowWindow "Main"
    return $basewidget
    
}

::itcl::body pxitclsurgerygadget::bindWindowClose { } {
    
    $chellyMain OnWidgetClose
}

::itcl::body pxitclsurgerygadget::AddToMenuButton { mb args} {
    
    eval "$mb add command -label \"Overlays\" -command { $this ShowWindow Overlays}"
}

::itcl::body pxitclsurgerygadget::AddToMenuButtonLite { mb args} {
    
    eval "$mb add command -label \"Surgery Tool\" -command {$this ShowWindow \"Overlays\"}"
}


# ---------------------------------------------------------------------------
itcl::body pxitclsurgerygadget::CreateMainControl { widget menubase } {
    
    #show what widget to display the chellyGUI object in
    
    
    set MainControlWidget $widget
    
    #instantiate chellyGUI
    if { $useNew } {
	set chellyMain [ [bis_treegui \#auto] GetThisPointer ]
    } else {
	set chellyMain [ [chellyGUI \#auto] GetThisPointer ]
    }
    #call the ShowManager method in chellyGUI, which does most of the display drawing
    $chellyMain ShowManager $MainControlWidget $this $menubase
    
    #put the image1_control, image2_control, and transformation_control GUI objects in the midpane of chellyGUI
    
    update idletasks
    
    set w [ $chellyMain cget -midpane]
 
    if { $useNew } {

	set bis_menu [menu $menubase.bis -tearoff 0]
	$menubase add cascade -label "BIS Algorithms" -menu $menubase.bis -background "#ede9e3"
    
	$bis_menu add cascade -label "Concatenate Images" -menu $bis_menu.m0 -background "#ede9e3"
	set 4dmenu [menu $bis_menu.m0 -tearoff 0]
	
	set 4d [ bis_guitreecreate4d \#auto ]
	$4d InitializeFromContainer $this
	set w0 $bis_menu.$4d
	
	set 4d [ $4d GetThisPointer ]
	$4d CreateGUI $w0 
	$4d AddToMenuButton $4dmenu
	$4d AddTreeGUI $chellyMain
	
	$bis_menu add cascade -label "Image Processing" -menu $bis_menu.m1 -background "#ede9e3"
	set imageutilmenu [menu $bis_menu.m1 -tearoff 0]
    
	set imageutility [ bis_guitreeimageutility \#auto ]
	$imageutility InitializeFromContainer $this
	set w2 $bis_menu.$imageutility
	
	set imageutility [ $imageutility GetThisPointer ]
	$imageutility CreateGUI $w2 
	$imageutility AddToMenuButton $imageutilmenu
	$imageutility AddTreeGUI $chellyMain
	
	$bis_menu add cascade -label "Connectivity" -menu $bis_menu.m2 -background "#ede9e3"
	set connectivitymenu [menu $bis_menu.m2 -tearoff 0]
                           
	set connectivity [ bis_guitreeimageutility \#auto connectivity ]
	$connectivity InitializeFromContainer $this
	set w3 $bis_menu.$connectivity
	
	set connectivity [ $connectivity GetThisPointer ]
	$connectivity CreateGUI $w3 
	$connectivity AddToMenuButton $connectivitymenu
	$connectivity AddTreeGUI $chellyMain
	
	$bis_menu add cascade -label "Surface Processing" -menu $bis_menu.m3 -background "#ede9e3"
	set surfaceProcess [menu $bis_menu.m3 -tearoff 0]    
	
	set surfacecontrol [ bis_guisurfaceutility \#auto ] 
	$surfacecontrol InitializeFromContainer $this
	set w4 $bis_menu.$surfacecontrol
	
	set surfacecontrol [ $surfacecontrol GetThisPointer ]
	$surfacecontrol CreateGUI $w4 
	$surfacecontrol AddToMenuButton $surfaceProcess
	#$surfacecontrol AddTreeGUI $chellyMain
    }
    
    set nt $w.notebook 
    iwidgets::tabnotebook $nt -tabpos n
    pack $nt -side top -expand 1 -fill both -padx 3 -pady {0 3}
    $nt config -background $OCbgcolor -backdrop "light steel blue"
    set n1 [ $nt add -label "Images" ]
    set n2 [ $nt add -label "Overlays" ] 
    $nt view "Images"



    $chellyMain ShowMidpaneTools  $n1
    CreateOverlayControl    $n2

    #    $w.notebook view "Overlays"
    
    #let chellyGUI know that the above three widgets exist
    #$chellyMain chellyGUI::setSpaceControlWidget $image1_control
    #$chellyMain chellyGUI::setAnatomicalControlWidget $image2_control
    #$chellyMain chellyGUI::setFunctionalControlWidget $image3_control
    
    $chellyMain configure -viewer1 $parent
    $chellyMain configure -viewer2 $second_viewer
    $chellyMain configure -electrodecontrol1 $electrodecontrol
    $chellyMain configure -electrodecontrol2 $electrodecontrol2
    $chellyMain configure -overlaycontrol $overlaycontrol
 
    #Now that the canvas has been created in its space, call the method to fill it
    $chellyMain OCanvasInitialize $ResliceCanvas
    update idletasks

    
}




# ---------------------------------------------------------------------------
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    
    wm withdraw .
    set viewer1 0
    set viewer2 0
    set  surgerytool [ [  pxitclsurgerygadget \#auto $viewer1 $viewer2 ] GetThisPointer ]
    
    $surgerytool Initialize .
    $surgerytool ShowWindow
}



