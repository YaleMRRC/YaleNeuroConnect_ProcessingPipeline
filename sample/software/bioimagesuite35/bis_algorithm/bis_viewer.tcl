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


if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    lappend auto_path [ file dirname [ info script ]]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] main]
}


package provide bis_viewer 1.0
package require vtkpxcontrib 1.0
package require  Itcl
package require bis_option 1.0
package require bis_common 1.0
package require Iwidgets 
package require pxitclimage 1.0
package require pxitclbasecontrol 1.0
package require bis_polygonaldisplaymanager 1.0



# -----------------------------------------------
#
# Master Viewer needs work
# trace on surface vs volume and tolerance issues
# 
# -----------------------------------------------
itcl::class bis_viewer {

    #
    #public
    #
    inherit pxitclbasecontrol

    constructor { { par 0 } } { 
	::pxitclbasecontrol::constructor $par
    } {	$this Initialize }
    destructor { $this CleanAll }

    # Different tools enable/disable
    public    variable enable_animationgadget 1
    public    variable enable_tracegadget 0
    public    variable enable_talaraichoption 1
    public    variable enable_atlastools      1
    public    variable enable_vvlinkgadget  1
    public    variable enable_openigtlinkgadget  1
    public    variable enable_landmarkeditor  0
    public    variable enable_electrodeeditor 0
    public    variable enable_toolbar  1

    # Key Outside Interface
    public method SetImage { img } 
    public method GetImage { } 
    # Legacy mode
    public method SetResultsFromObject { img obj }


    public method SetMask  { msk } 
    public method SetImageColormap { cmap }
    public method SetImageColormapMode { cm }
    public method SetMaskColormap { cmap }

    # This is in mm
    public method GetCursorPoint { }
    # This is in voxels (i,j,k)
    public method GetLastVoxel { } 

    # Observer Interface
    #AddCursorNotifier {    } .. args  $x $y $z $this
    #AddImageNotifier  {    } .. args image $this
    public method AddCursorNotifier { object command }
    public method RemoveCursorNotifier { object command }
    public method AddImageNotifier { object command }
    public method RemoveImageNotifier { object command }

    # Mouse Events
    # ------------
    public method HandleUpdateEvent { args }
    public method HandleMouseEvent { mouse stat x1 x2 widgetname args }
    public method HandleCoordinatesChangeEvent { { mouse -1 } { stat -1 } }


    # Viewer Issues
    public method GetViewer { } { return $vtk_viewer }
    public method GetScreenshotImage  { { magnification 1 } } 
    # md = ortho, simple, singleslice, ortho4d; editor = 0 or 1
    public method SetViewerType {  md { enableedit 0 }} 
    public method CanAcceptMask { }

    # Other Viewers
    public method SetLinkedCursorViewer { vv } { set linked_viewer $vv }
    public method SetMasterViewer { vv } { set master_viewer $vv }
    public method SetAtlasTool { atl } { set atlastool $atl }

    # Data Management sur is electodes/surface/landmarks (actor!)
    public method EditPolygonalObject {  sur datatree node }
    public method AddPolygonalObject {  sur { linked 0 } { attr "" } }
    public method AddOrReplacePolygonalObject {  sur { linked 0 } { attr "" } }
    public method UpdatePolygonalObject {  sur  attr { updisplay 1 } }
    public method RemovePolygonalObject { sur }
    public method GetPolygonalDisplayManager { } { return $bis_polygonalobjectmanager }

    # Final one is GUI
    protected method InitializeViewer { viewerbase }
    protected method InitializeToolbar { toolbase }
    protected method InitializeTools   { toolbase }
    public method CreateGUI { base }
    public method AddToMenu { viewm }

    # Methods for Toolbar
    public method SetSnapshotResolution { factor }

    public method SetTraceMode { enablevolume { size 0 } { weightedfactor 0 } }
    public method SetViewerBackground { }


    # ------------------------------------------------------------------------------
    # Internal Stuff
    # ------------------------------------------------------------------------------

    # protected method
    protected method Initialize { } 
    protected method CleanAll { } 

    # key internal variables
    protected variable vtk_viewer  0
    protected variable master_viewer  0
    protected variable linked_viewer  0
    protected variable vtk_viewertype  "vtkpxGUIOrthogonalViewer"
    protected variable vtk_extratype  ""
    protected variable bis_polygonalobjectmanager 0
    protected variable datamanager 0
    protected variable landmarkeditor 0
    protected variable electrodeeditor 0
    protected variable cursorcallbacklist ""
    protected variable imagecallbacklist ""
    protected variable currentimage 0
    protected variable currentmask 0
    protected variable vvlinkgadget 0
    protected variable openigtlinkgadget 0

    # Animation Gadget
    protected variable animationgadget 0
    protected variable atlastool 0


    # Common Stuff
    protected common guiparam

};

# ------------------------------------------------------------------------------------------------------
#             Implementation
# ------------------------------------------------------------------------------------------------------
itcl::body bis_viewer::Initialize { }  {
    
    set  datamanager 0
    set cursorcallbacklist ""
    set imagecallbacklist ""
    set currentimage [ [ pxitclimage \#auto ] GetThisPointer ]
    set img [ $currentimage GetImage ]

    set currentmask [ [ pxitclimage \#auto ] GetThisPointer ]
    set isdialog 0
    set guiparam($this,snapshotresdlg) 0
    set guiparam($this,tracedialog) 0
}

itcl::body bis_viewer::CleanAll { } {
    
    itcl::delete obj $currentimage
    itcl::delete obj $currentmask
}

# -------------------------------------------------------------------------------------------------
itcl::body bis_viewer::GetScreenshotImage  { { magnification 1 } } {

    if { $vtk_viewer == 0 } {
	return 0
    }
    
    set rw [ $vtk_viewer GetRenderWidgetName ]
    set renwin [ $rw GetRenderWindow ]

    set renSrc [ vtkWindowToImageFilter New ]
    $renSrc SetInput $renwin
    $renSrc SetMagnification $magnification
    $renSrc Update

    set img [ vtkImageData New ]
    $img ShallowCopy [ $renSrc GetOutput ]
    $renSrc Delete

    return $img
}
# -------------------------------------------------------------------------------------------------
itcl::body bis_viewer::CanAcceptMask { } { 

    if { $vtk_viewer == 0 } {
	return 0
    }

    if { [ $vtk_viewer IsA "vtkpxGUIObjectmapOrthogonalViewer"  ] == 0 &&
	 [ $vtk_viewer IsA "vtkpxGUIObjectmapMosaicViewer"  ] == 0 } {
	return 0
    }

    return 1

}

# --------------------------------------------------------------------------
itcl::body bis_viewer::SetResultsFromObject { img obj } {
    puts stderr "Legacy warning set results from object ..... in $this"
    return [ $this SetImage $img ]
}

# ------------------------------------------------------------------------------
itcl::body bis_viewer::GetImage { }  {
    return $currentimage
}
# ------------------------------------------------------------------------------

itcl::body bis_viewer::SetImage { img }  {

    if { [ $img GetImageSize  ] < 2 } {	return 0    }


    # Do I need to clean the surface display?

    set same [ $currentimage IsSameDisplaySize $img ]
    
    $currentimage ShallowCopy $img

    if { $vtk_viewer == 0 } {
	return 0

   }

    set cmap [ $img GetLookupTable ]

    if { $cmap !=0 } {
	$vtk_viewer SetImage [ $img GetImage ] [ $img GetOrientation ]  $cmap
    } else {
	$vtk_viewer SetImage [ $img GetImage ] [ $img GetOrientation ]  
    }

    if { $cmap == 0  } {
	
	global pxtcl_pref_array
	if { $pxtcl_pref_array(NormalizeAnatomical) > 0 } {
	    set normalize_anatomical 1
	}

	set r [ [ [ [ $img GetImage ] GetPointData ] GetScalars ] GetRange ]
	set d [ expr [ lindex $r 1 ]- [ lindex $r 0 ] ]
	if { $normalize_anatomical > 0 && $d > 20 } {
	    $this SetImageColormapMode 0
	} else {
	    $this SetImageColormapMode -1
	}
    }


    if { $same == 0 } {
	$bis_polygonalobjectmanager CleanAll
    }



    foreach cmd $imagecallbacklist {
	if { [ string length $cmd ] > 1 } {
	    set a "$cmd $img"
	    #	    puts stderr "invoking $a"
	    eval $a
	}
    }


    set v [ winfo parent [  $this GetBaseWidget ] ]
    catch { wm deiconify $v }

}

itcl::body bis_viewer::SetMask  { msk }  {

    if { [ $msk GetImageSize  ] < 2 } {	return 0    }
    $currentmask ShallowCopy $msk

    if { [ $currentimage GetImageSize ] < 2 || [ $this CanAcceptMask ] == 0 } {
	return 0
    }

    
    set nc [ [  $currentimage GetImage ] GetNumberOfScalarComponents ]
    set oc [ [  $currentmask  GetImage ] GetNumberOfScalarComponents ]


    # Scenario 1
    if { $oc != $nc } {
	set tmp [ vtkImageData [ pxvtable::vnewobj ]]
	$tmp CopyStructure [ $currentmask GetImage ]
	$tmp SetNumberOfScalarComponents $nc
	$tmp AllocateScalars

	set t_data [ [ $tmp GetPointData ] GetScalars ] 
	set i_data [ [ [ $currentmask GetImage ] GetPointData ] GetScalars ]

	set mval $nc
	if { $oc < $nc } {
	    set mval $oc 
	}

	for { set i 0 } { $i < $mval  } { incr i } {
	    $t_data CopyComponent $i $i_data $i
	}

	if { $nc > $oc } {
	    for { set i $oc } { $i < $nc  } { incr i } {
		$t_data CopyComponent $i $i_data [ expr $oc -1 ]
	    }
	}
    } else {
	set tmp [ $currentmask GetImage ]
    }
	
    if { [ $currentmask GetImageSize ] == [ $currentimage GetImageSize ] } {
	$vtk_viewer SetObjectMapImage $tmp
    } else {
	set resl [ vtkbisImageReslice [ pxvtable::vnewobj ]]
	$resl SetInput $tmp
	$resl SetInterpolationMode 0
	$resl SetInformationInput [ $currentimage GetImage ]
	$resl Update
	$vtk_viewer SetObjectMapImage [ $resl GetOutput ]
	
	$resl Delete
    }

    if { $oc!=$nc } {
	$tmp Delete
    }
}

# ---------------------------------------------------------------------------------------
itcl::body bis_viewer::SetImageColormap { cmap } {

    if { $vtk_viewer != 0 } {
	$vtk_viewer SetLookupTable $cmap
    }
}

itcl::body bis_viewer::SetImageColormapMode { cm } {
    
    if { $vtk_viewer != 0 } {
	$vtk_viewer SetPresetLookupTable $cm
    }
}

itcl::body bis_viewer::SetMaskColormap { cmap } {

    if { [ $this CanAcceptMask ] == 0 } {
	return 0
    }
    $vtk_viewer SetObjectLookupTable $cmap 1
    return 1
}
# ---------------------------------------------------------------------------------------
# This is in mm
itcl::body bis_viewer::GetCursorPoint { } {
    set lv 0
    catch { set lv [ $vtk_viewer GetLastClickedPoint ] }
    return $lv
}

# This is in voxels (i,j,k)
itcl::body bis_viewer::GetLastVoxel { }  {

    set lv [ list -1 -1 -1 ]
    catch { set lv [ $vtk_viewer GetLastClickedPoint ] }
    if { [ llength $lv ] > 1 } {
	if { [ lindex $lv 0 ] > -1 } {
	    return  [ $vtk_viewer GetLastClickedPointScaled ] 
	}
    }

    return 0
}

# -------------------------------------------------------------------------------
# Observer Interface
#AddCursorNotifier {    } .. args  $x $y $z $this
#AddImageNotifier  {    } .. args image $this
# -------------------------------------------------------------------------------
itcl::body bis_viewer::AddCursorNotifier { object command } {

    set ll "$object $command"
    set ind [ lsearch -exact $cursorcallbacklist $ll ]
    if { $ind > -1 } {
	return 0
    }
    lappend cursorcallbacklist $ll

}

itcl::body bis_viewer::RemoveCursorNotifier { object command } {
    set ll "$object $command"
    set ind [ lsearch -exact $cursorcallbacklist $ll ]
    if { $ind > -1 } {
	set cursorcallbacklist [ lreplace $cursorcallbacklist $ind $ind "" ]
    }
}

itcl::body bis_viewer::AddImageNotifier { object command } {

    set ll "$object $command"
    set ind [ lsearch -exact $imagecallbacklist $ll ]
    if { $ind > -1 } {
	return 0
    }
    lappend imagecallbacklist $ll

}

itcl::body bis_viewer::RemoveImageNotifier { object command } {
    set ll "$object $command"
    set ind [ lsearch -exact $imagecallbacklist $ll ]
    if { $ind > -1 } {
	set imagecallbacklist [ lreplace $imagecallbacklist $ind $ind "" ]
    }
}

# -------------------------------------------------------------------------------
# Mouse Events
# -------------------------------------------------------------------------------
itcl::body bis_viewer::HandleMouseEvent { mouse stat x1 x2 widgetname args } {
    if { $vtk_viewer == 0 } {
	return
    }

    # Need to flip y-axis vtk counts from bottom tk counts from top !!!
    set wd [ [ $widgetname GetRenderWindow ] GetSize ]
    set x2 [ expr [lindex $wd 1 ] - $x2 ]
    $vtk_viewer HandleMouseButtonEvent $mouse $stat $x1 $x2
    $this HandleCoordinatesChangeEvent $mouse $stat
}

itcl::body bis_viewer::HandleCoordinatesChangeEvent { { mouse -1 } { stat -1 } } {

    set pt  [ $this GetCursorPoint ]
    set vx [ $this GetLastVoxel   ]

#    if { $stat == 2 } {
#	return
#    }
    
    if { [ llength $pt ] == 3 } {
	foreach cmd $cursorcallbacklist {
	    if { [ string length $cmd ] > 1 } {
		set a "$cmd \[ list $pt \] \[ list $vx \] $mouse $stat"
		#puts stderr "invoking $a"
		eval $a
	    }
	}
    }

    if { $linked_viewer != 0 } {
	set other_viewer [ $linked_viewer GetViewer ]
	if { [ $vtk_viewer IsA "vtkpxGUIOrthogonalViewer" ] && [ $other_viewer IsA "vtkpxGUIOrthogonalViewer" ] } {
	    
	    set upd0 [ $vtk_viewer GetMouseSliceChangeMode ]	
	    set upd1 [ $other_viewer GetMouseSliceChangeMode ]
	    if { $upd0 == 1 && $upd1 == 1 } {
		$other_viewer CopyCamera $vtk_viewer
		if { [ llength $vx ] == 3 } {
		    $other_viewer SetScaledCoordinates [ lindex $vx 0 ] [ lindex $vx 1 ] [ lindex $vx 2 ]
		} else {
		    $other_viewer Update
		}
	    } 
	}
    }
    
    if { [ llength $pt ] == 3  &&  $atlastool != 0 } {
	set tal [ $vtk_viewer GetTalairachTransform ]
	if { $tal != "" } {
	    set md [ $tal GetColinMode ]
	    set ysz [ $tal GetColinYSize ]
	    
	    if { $ysz != 216 } {
		set md 0
	    }

	    set px [ lindex $pt 0 ]
	    set py [ lindex $pt 1 ]
	    set pz [ lindex $pt 2 ]
	    
	    if { $md == 1 } {
		$atlastool IdentifyPoint $px $py $pz
	    } elseif { $md == -1 } {
		$atlastool IdentifyPoint [ expr 180 - $px ] [ expr 216.0 - $py ] $pz
	    } else {
		$atlastool SetError "Image Not in MNI Space, Cannot Identify Point.\n"
	    }
	}
    }
}

#----------------------------------------------------------------------------
itcl::body bis_viewer::SetViewerType {  md { enableedit 0 }}  {

    if { $enableedit == 0 } {
	if { $md == "ortho" } {
	    set vtk_viewertype "vtkpxGUIOrthogonalViewer"
	} elseif { $md == "ortho4d" } {
	    set vtk_viewertype "vtkpxGUI4DOrthogonalViewer"
	} else {
	    set vtk_viewertype "vtkpxGUIMosaicViewer"
	    if { $md == "singleslice" } {
		set vtk_extratype  single
	    }
	}
    } else { 
	if { $md == "ortho" } { 
	    set vtk_viewertype "vtkpxGUIObjectmapOrthogonalViewer"
	} else {
	    set vtk_viewertype "vtkpxGUIObjectmapMosaicViewer"
	}
    }
}
# ---------------------------------------------------------------------
itcl::body bis_viewer::EditPolygonalObject {  sur datatree node } {

    if { [ $sur isa pxitcllandmarks ] ==1 && $landmarkeditor !=0 } {
	catch { $electrodeeditor HideWindow }
	$landmarkeditor ShowWindow	
	$landmarkeditor TreeEditLandmarks $sur $datatree $node
    }

    if { [ $sur isa pxitclelectrodemultigrid ] ==1 && $electrodeeditor !=0 } {
	catch { $landmarkeditor HideWindow }
	$electrodeeditor ShowWindow	
	$electrodeeditor TreeEditGrids $sur $datatree $node
    }
}
# -----------------------------------------------------------------------
# Data Management sur is electodes/surface/landmarks (actor!)
itcl::body bis_viewer::UpdatePolygonalObject {  sur attr { updisplay 1 } } {

    return [ $bis_polygonalobjectmanager UpdateSameObject $sur $attr $updisplay ]
}




itcl::body bis_viewer::AddPolygonalObject {  sur { linked 0 } { attr "" } } {

    set d [ $currentimage GetImageSize ]
    if { $d == 1 } {
	# If we don't have an image, create a simple one and hide it such
	# that the viewer will work ............
	set obj [ $sur GetObject ]
	if { [ $obj IsA "vtkPolyDataSource" ] } {
	    $obj Update
	    set obj [ $obj GetOutput ]
	}
	set bounds [ $obj GetBounds ]
	for { set i 0 } { $i <=2 } { incr i } {
	    set m [ lindex $bounds [ expr 2*$i +1 ]]
	    set s($i) [ expr $m*1.2/10.0 ]
	    if { $s($i) < 1.0 } {
		set s($i) 1.0
	    }
	}

	# Create New base Image
	set itclimg [ [ pxitclimage \#auto ] GetThisPointer ]
	set img  [ $itclimg GetImage ]
	$img SetDimensions 10 10 10
	$img SetSpacing  $s(0) $s(1) $s(2)
	$img AllocateScalars
	[ [ $img GetPointData  ] GetScalars ] FillComponent 0  1.0
	[ [ $img GetPointData  ] GetScalars ] SetComponent 99  0 2.0
	[ [ $img GetPointData  ] GetScalars ] SetComponent 0 0 0.0
	$this SetImage $itclimg
	itcl::delete object $itclimg

	if { [ $vtk_viewer IsA   "vtkpxGUIOrthogonalViewer" ] } {
	    $vtk_viewer SetDisplayMode3DIfNeeded
	    $vtk_viewer SetDisplay3DMode 0
	}
    }

    $bis_polygonalobjectmanager AddObject $sur $linked $attr
    set v [ winfo parent [  $this GetBaseWidget ] ]
    catch { wm deiconify $v }

}

itcl::body bis_viewer::AddOrReplacePolygonalObject {  sur { linked 0 } { attr "" } } {

    set d [ $currentimage GetImageSize ]
    if { $d == 1 } {
	return [ $this AddPolygonalObject $sur $linked $attr ]
    }

    $bis_polygonalobjectmanager AddOrReplaceObject $sur $linked $attr
    set v [ winfo parent [  $this GetBaseWidget ] ]
    catch { wm deiconify $v }

}


# -------------------------------------------------------------------------------------
itcl::body bis_viewer::RemovePolygonalObject { sur } {
    # for later
    $bis_polygonalobjectmanager RemoveObject $sur
}




# -------------------------------------------------------------------------------------
itcl::body bis_viewer::SetSnapshotResolution { mode } {

    if { $vtk_viewer == 0 } {	return 0    }
    if { $mode == -1 } {
	set mode 1
	if { $guiparam($this,snapshotresdlg)  == 0 } { 
	    set tb [ iwidgets::selectiondialog ${basewidget}.[ pxvtable::vnewobj ] \
			 -childsitepos w -title "Set Viewer Snapshot Resolution" \
			 -itemslabel "Resolution Levels" -modality application ]
	    $tb configure -height 250 -width 250

	    $tb insert items end  Low
	    $tb insert items end  Medium
	    $tb insert items end  High
	    $tb insert items end  VeryHigh

	    $tb hide Apply
	    $tb buttonconfigure OK -text "Set Resolution"
	    #	    [ $tb component selectionbox ]  selectitem 0
	    set guiparam($this,snapshotresdlg) $tb
	    update idletasks
	}

	if { [$guiparam($this,snapshotresdlg) activate ] } {
	    set tlist "Low Medium High VeryHigh"
	    set tval  [ $guiparam($this,snapshotresdlg) get ]
	    set mode [ expr 1 + [ lsearch -exact $tlist $tval ] ]
	} 
    }
    set md $mode
    catch {  set md [ expr int($mode) ] }
    if { $md < 1 } { set md 1 } 
    if { $md > 4 } { set md 4 } 

    $vtk_viewer SetMagnificationFactor $md
    puts stderr "Setting Magn = $md"
    return $md
}

# -----------------------------------------------------------------------------
itcl::body bis_viewer::SetTraceMode { enablevolume { size 0 } { weightedfactor 0 } } {

    if { $vtk_viewer == 0 } {	return 0    }
    if { [ $vtk_viewer IsA vtkpxGUIOrthogonalViewer ] == 0 } { return 0 }

    if { $enablevolume == -1 } {
	if { $guiparam($this,tracedialog)  == 0 } { 

	    set tb [ iwidgets::dialog ${basewidget}.[ pxvtable::vnewobj ] \
			 -title "Set 3D Tracing Parameters" \
			 -modality application ]
	    $tb configure -height 200 -width 200

	    set guiparam($this,tracedialog) $tb
	    set guiparam($this,volumetrace) 1
	    set guiparam($this,volumevoi)   0
	    set guiparam($this,volumemode)  0

	    set cs [ $tb childsite ]

	    checkbutton $cs.cb 	-text "Volume Trace" \
		-variable [ itcl::scope guiparam($this,volumetrace) ] -indicatoron 1


	    iwidgets::spinint $cs.cc \
		-labeltext "VOI Size: " \
		-width 4 \
		-range { 0 20 } \
		
	    $cs.cc insert 0 0
	    set guiparam($this,volumevoispin) $cs.cc

	    
	    checkbutton $cs.cd 	-text "Weighted VOI" \
		-variable [ itcl::scope guiparam($this,volumemode) ] -indicatoron 1
	    
	    grid $cs.cb -row 0 -column 0
	    grid $cs.cc -row 1 -column 0
	    grid $cs.cd -row 2 -column 0
	    $tb hide Apply
	    $tb hide Help
	    update idletasks
	}
	
	if { [$guiparam($this,tracedialog) activate ] } {
	    set guiparam($this,volumevoi)   [  $guiparam($this,volumevoispin)  get ]
	}
    } else {
	set guiparam($this,volumetrace) [ expr $enablevolume > 0 ]
	set guiparam($this,volumevoi) $size
	set guiparam($this,volumemode) [ expr $weightedfactor > 0 ]
    }
    
    if { $guiparam($this,volumetrace) == 0 } {
	$vtk_viewer SetTraceGeometry 1
	$vtk_viewer SetTraceVolume   0
    } else {
	$vtk_viewer SetTraceGeometry 0
	$vtk_viewer SetTraceVolume   1
    }
    
    $vtk_viewer SetTraceVolumeVOI $guiparam($this,volumevoi)
    $vtk_viewer SetTraceVolumeWeightedMode $guiparam($this,volumemode)

}

itcl::body bis_viewer::SetViewerBackground {  } {

    if { $vtk_viewer == 0 } {	return 0    }
    set rw [ $vtk_viewer GetRenderWidgetName ]
    set renwin [ $rw GetRenderWindow ]
    $vtk_viewer SetBackgroundColor $renwin
}
 


# ---------------------------------------------------------------------------------
# Create GUI
# ---------------------------------------------------------------------------------
itcl::body bis_viewer::InitializeViewer { viewerbase } {

    set vtk_viewer [ eval "$vtk_viewertype New" ]
    catch { $vtk_viewer  SetCreateInternalEditorOn }
    if { $enable_talaraichoption == 0 } {
	$vtk_viewer DisableTalairachButtons
    } else {
	$vtk_viewer EnableTalairachButtons
	set p2 $::pxtclvtkpxcontrib::imagedir 
	set fname [ file join $p2 colinlookup ]
	set tal [ vtkpxTalairachTransform [ pxvtable::vnewobj ]]
	$tal SetColinLookupFileName $fname 0
	set fname [ file join $p2 colin_talairach_lookup.nii.gz ]
	$tal SetColinLookupFileName $fname 1
	$tal Delete
    }

    if { $vtk_extratype == "single" } {
	$vtk_viewer SetSingleSliceMode 
	$vtk_viewer SetXYSliceOnly 
	$vtk_viewer SetOffset 0
    }

    $vtk_viewer Initialize $viewerbase 1
    $vtk_viewer BindMouseEvents [ $vtk_viewer GetRenderWidgetName ] "$this HandleMouseEvent" "" 
    $vtk_viewer SetCoordinatesChangeCallback "$this HandleCoordinatesChangeEvent" 
    $vtk_viewer SetEnableCoordinatesChangeCallback 1

    if { [ $vtk_viewer IsA "vtkpxGUI4DOrthogonalViewer" ] == 1  } {
	set cn [ $vtk_viewer InitializeMovieControl $w 0 ]
	eval "bind all <Control-m> { wm deiconify $cn} "
    }
    
    return $viewerbase
}

# ---------------------------------------------------------------------------
itcl::body bis_viewer::AddToMenu { viewm } {

    eval "$viewm add command -label \"Surface Manager\" -command { $bis_polygonalobjectmanager ShowWindow Server } "
    $viewm add separator
    eval "$viewm add command -label \"Set Viewer Background\"   -command { $this SetViewerBackground } "
    eval "$viewm add command -label \"Set Viewer Snapshot Resolution\"   -command { $this SetSnapshotResolution -1 } "
    eval "$viewm add command -label \"Set 3D Tracing Parameters\"   -command { $this SetTraceMode -1 } "

    if { $animationgadget != 0 } {
	$viewm add separator
	eval "$viewm add command -label \"Show Viewer Controls Tool\" -command { [ $vtk_viewer GetRenderer 3 ] ShowCameraControls } "
	eval "$viewm add command -label \"Show Animation Tool\" -command { $animationgadget ShowWindow } "
    }

    if { $atlastool != 0 } {
	$viewm add separator
	eval "$viewm add command -label \"Show Yale Brodmann Atlas Tools\" -command { $atlastool ShowGadget yale } "
	eval "$viewm add command -label \"Show WFU Atlas Tool\" -command { $atlastool ShowGadget wfu } "
    }


    if { $landmarkeditor !=0 } {
	eval "$viewm add command -label \"Show Landmark Editor\" -command { catch { $electrodeeditor HideWindow };$landmarkeditor ShowWindow } "
    }

    if { $electrodeeditor !=0 } {
	eval "$viewm add command -label \"Show ElectrodeEditor\" -command { catch { $landmarkeditor HideWindow }; $electrodeeditor ShowWindow } "
    }



    if { $vvlinkgadget !=0 } {
	$viewm add separator
	eval "$viewm add command -label \"VVLink Control\" -command { $vvlinkgadget ShowWindow Server } "
    }

    if { $openigtlinkgadget !=0 } {
	eval "$viewm add command -label \"OpenIGTLink Control\" -command { $openigtlinkgadget ShowWindow Server } "
    }
	
}

# ---------------------------------------------------------------------------
itcl::body bis_viewer::InitializeToolbar { toolbase } {

    set tb [ iwidgets::toolbar $toolbase.[ pxvtable::vnewobj ] \
		 -balloondelay1 500 \
		 -balloondelay2 50 \
		 -orient horizontal \
		 -font { helevetica 9 }]

    pack $tb -side top -expand false -fill x 
    
    eval "$tb add button sur -height 1 -balloonstr \"Surface Manager\" -command { $bis_polygonalobjectmanager ShowWindow Server } -text \"Surfaces\" "
    eval "$tb add button cl -height 1 -balloonstr \"Set Viewer Background Delete\"   -command { $this SetViewerBackground } -text \"ViewerBg\""
    eval "$tb add button cv -height 1 -balloonstr \"Set Viewer Snapshot Resolution\"   -command { $this SetSnapshotResolution -1 } -text \"Resol\""
    eval "$tb add button cvv -height 1 -balloonstr \"Set 3D Tracing Parameters\"   -command { $this SetTraceMode -1 } -text \"3D Trace\""

    if { $animationgadget != 0 } {
	eval "$tb add button vc -height 1 -balloonstr \"Show Viewer Controls Tool\" -command { [ $vtk_viewer GetRenderer 3 ] ShowCameraControls } -text \"3DControls\" "	
	eval "$tb add button an -height 1 -balloonstr \"Show Animation Tool\" -command { $animationgadget ShowWindow } -text \"Animation\" "
    }

    if { $atlastool != 0 } {
	eval "$tb add button atb -height 1 -balloonstr \"Show Yale Brodmann Atlas Tools\" -command { $atlastool ShowGadget yale } -text \"Brodmann\" "
	eval "$tb add button atw -height 1 -balloonstr \"Show WFU Atlas Tool\" -command { $atlastool ShowGadget wfu } -text \"WFU\" "
    }

    if { $landmarkeditor !=0 } {
	eval "$tb add button le -height 1 -balloonstr \"Show Landmark Editor\" -command { catch { $electrodeeditor HideWindow }; $landmarkeditor ShowWindow } -text \"LE\" "
    }

    if { $electrodeeditor !=0 } {
	eval "$tb add button ee -height 1 -balloonstr \"Show Electrode Editor\" -command { catch { $landmarkeditor HideWindow }; $electrodeeditor ShowWindow } -text \"EE\" "
    }

    if { $vvlinkgadget !=0 } {
	eval "$tb add button vvl -height 1 -balloonstr \"VVLink Control\" -command { $vvlinkgadget ShowWindow } -text \"VVLink\" "
    }

    if { $openigtlinkgadget !=0 } {
	eval "$tb add button openigtl -height 1 -balloonstr \"OpenIGTLink Control\" -command { $openigtlinkgadget ShowWindow Server } -text \"OpenIGT\" "
    }
	
}

itcl::body bis_viewer::InitializeTools   { toolbase } {

    global pxtcl_pref_array

    set obj [ [ bis_polygonaldisplaymanager \#auto $this ] GetThisPointer ]
    $obj CreateGUI $toolbase.[pxvtable::vnewobj ] 1 
    set  bis_polygonalobjectmanager $obj


    if { $enable_animationgadget == 1 && [ $vtk_viewer IsA "vtkpxGUIOrthogonalViewer" ] == 1 } {
	package require pxitclanimationgadget 1.0
	set animationgadget [ [ pxitclanimationgadget \#auto $this ] GetThisPointer ]
	$animationgadget Initialize ${toolbase}.[ pxvtable::vnewobj ]
	$animationgadget SetViewer $vtk_viewer
    }


    if { $enable_talaraichoption == 1 && $enable_atlastools == 1 && $atlastool == 0} {
	package require pxitclatlasgadget 1.0
	set atlastool [ pxitclatlasgadget \#auto $this ]
	set w ${toolbase}.${atlastool}
	set atlastool [ $atlastool GetThisPointer ]
	$atlastool Initialize $w
    }


    if { $enable_vvlinkgadget == 1 && $pxtcl_pref_array(VectorVisionLink)=="Enabled" } {
	package require pxitclvvlinkgadget 1.0
	set vvlinkgadget [ pxitclvvlinkgadget  \#auto $this ]
	set w ${toolbase}.${vvlinkgadget}
	set vvlinkgadget [ $vvlinkgadget GetThisPointer ]
	$vvlinkgadget Initialize $w $vtk_viewer
    }


    if { $enable_openigtlinkgadget == 1 &&  $pxtcl_pref_array(OpenIGTLink)=="Enabled" } {
	package require pxitclopenigtlinkgadget 1.0
	set openigtlinkgadget [ pxitclopenigtlinkgadget  \#auto $this ]
	set w ${toolbase}.${openigtlinkgadget}
	set openigtlinkgadget [ $openigtlinkgadget GetThisPointer ]
	$openigtlinkgadget Initialize $w $vtk_viewer
    }

    if { $enable_landmarkeditor == 1 } { 
	package require bis_landmarkeditor 1.0
	set landmarkeditor [ [ bis_landmarkeditor \#auto $this ] GetThisPointer ]
	set w ${toolbase}.[ pxvtable::vnewobj ]
	$landmarkeditor Initialize $w $this
    }


    if { $enable_electrodeeditor == 1 } { 
	package require bis_electrodeeditor 1.0
	set electrodeeditor [ [ bis_electrodeeditor \#auto $this ] GetThisPointer ]
	set w ${toolbase}.[ pxvtable::vnewobj ]
	$electrodeeditor Initialize $w $this
    }



}
# ---------------------------------------------------------------------
itcl::body bis_viewer::CreateGUI { base } {

    if { $basewidget !=0 } { return $basewidget }

    set  basewidget $base.[pxvtable::vnewobj ]

    set btf [ frame $basewidget ]
    pack $basewidget -side top -expand true -fill both

    set viewerbase   [ frame $btf.viewer1 -width 400 -height 300 ] 
    if { $enable_toolbar > 0 } {
	set toolbase      [ frame $btf.toolbar -height 10  ]
	set midbase      [ frame $btf.mid1 -height 2 ]
	pack $toolbase $midbase -side top -expand false -fill x 
    } else {
	set toolbase $viewerbase
    }
    pack $viewerbase -side top -expand true -fill both

    $this InitializeViewer $viewerbase
    $this InitializeTools $toolbase
    if { $enable_toolbar > 0 } {
	$this InitializeToolbar $toolbase
    }

    return $basewidget
}
# ---------------------------------------------------------------------------------------------------------------------
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {

    proc Test { args } {
	puts stdout "args=$args"
    }
 
    package require vtkpxcontrib
    wm geometry . 900x600
    set viewbase  [ frame .v ]
    pack $viewbase -side left -expand true -fill both

    set bis_viewer [ [ bis_viewer \#auto ] GetThisPointer ]
    #    $bis_viewer SetViewerType singleslice
    $bis_viewer configure -enable_openigtlinkgadget 1
    $bis_viewer configure -enable_landmarkeditor 1
    $bis_viewer configure -enable_electrodeeditor 1
    $bis_viewer CreateGUI $viewbase 
    wm title . "Test Viewer"


    set img [ pxitclimage \#auto ]
    $img Load [ lindex $argv 0 ]
    $bis_viewer SetImage $img
    $bis_viewer SetImageColormapMode 0

    
    set dual 2

    if { $dual == 1 } {
	$bis_viewer AddCursorNotifier "Test" "Cursor"
	$bis_viewer AddImageNotifier "Test" "Image"

	set viewbase2  [ frame .v2 ]
	pack  $viewbase2 -side left -expand true -fill both

	set bis_viewer2 [ [ bis_viewer \#auto ] GetThisPointer ]
	$bis_viewer2 CreateGUI $viewbase2 
	$bis_viewer2 SetImage $img
	$bis_viewer2 SetImageColormapMode -1
	$bis_viewer  SetLinkedCursorViewer  $bis_viewer2 
	$bis_viewer2 SetLinkedCursorViewer  $bis_viewer 
    } elseif { $dual == 2 } {
	vtkSphereSource r
	r SetRadius 50
	r Update
	set s1 [ [ pxitclsurface \#auto ] GetThisPointer ]
	$s1 ShallowCopySurface [ r GetOutput ]
	
	set l1 [ [ pxitcllandmarks \#auto ] GetThisPointer ]
	$l1 Load /agrino/xenios/vtk5_src/bioimagesuite/images/seed1.land
		

	$bis_viewer AddPolygonalObject $s1
	$bis_viewer AddPolygonalObject [ [ pxitclsurface \#auto ] GetThisPointer ] 
	$bis_viewer AddPolygonalObject $l1
	$bis_viewer AddPolygonalObject [ [ pxitclelectrodemultigrid \#auto ] GetThisPointer ]
    }

} 

















