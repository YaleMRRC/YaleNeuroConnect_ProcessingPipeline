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

package require bis_dualimagereslicetransformationalgorithm 1.0
package require bis_clusterthresholdimage 1.0
package provide bis_createoverlayimage 1.0
package require pxtcluserprefs 1.0
#
# createoverlay image
#

itcl::class bis_createoverlayimage {

    inherit bis_dualimagereslicetransformationalgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Create Image Overlay"}
    protected method PackOptionsGUIInterface { lst }

    protected method ConfigureOptionsGUICallbacks { } 
    public    method ShowScalarBar { args } 

    public method UpdateInputsFromContainer { }
    public method UpdateInputRanges { args }
    public method UpdateContainerWithOutput { } 



    
    protected variable lastrmax ""
    protected variable noguiupdates 0

};

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_createoverlayimage::Initialize { } {

    PrintDebug "bis_createoverlayimage::Initialize" 

    set options {

	{ otype       "Overlay Type, select which part of the functional image is used " "Overlay Type"  listofvalues Both { "Positive" "Negative" "Both" }  1 }
	{ colormap    "Select the colormap needed for this overlay F1 (anat=0.55,func=56.63) F2(anat=0.191, func=192:255), F4=(anat=0.237,func=239:255)" "Colormap"  listofvalues F1 { "F1" "F2" "F4" }  2 }
	{  minth      "Lower Threshold value for functional image" "Low Threshold"   real   0.0 { -100000000.0 100000000.0 }  3 }
	{  maxth      "Upper Threshold value for functional image" "High Threshold"  real 100.0 { -100000000.0 100000000.0 }  4 }
	{  inth       "Intensity Threshold value -- used to mask overlay if base image is lower than this" "Anat Threshold"  real 5.0 { 0.0 255.0 }  -11 }
	{  clustersize "Cluster Threshold Value" "Cluster Size"  integer  0 { 0 100000000 }  7 }
	{  origvoxels  "Use Voxel size in Functional Image (before reslicing) to determine clustersize" "Orig Voxels"  boolean  0 { 0 1 }  6 }
	{  normanat    "Intensity Normalize Anatomical Image prior to overlay" "Normalize Anatomical Image"  boolean  1 { 0 1 }  -10 }
	{ interp      "Interpolation Mode that is used when reslicing the functional image" "Interpolation Mode"  listofvalues Linear { "NearestNeighbor" "Linear" "Cubic" } -12 }
	{  singframe  "Use Single frame from Functional Image to create overlay" "Single Frame"  boolean  1 { 0 1 }  8 }
	{  frame      "Specify frame to use in case of single frame overlay" "frame"  integer 1 { 1 1000 }  9 }
	{ oneconnected  "Use 1-Connected Clustering"  "1-Connected" boolean  1 { 0 1 }  -10 }
	{  guisbar     "Show Scalar Bar below overlay" "Show Color Bar"  boolean  0 { 0 1 }  12 }
	{  guireslice  "Show Reslice Output Only" "Show Resliced Functional"  boolean  0 { 0 1 }  -12 }
	{  guilateral  "Laterality Index" "Laterality"  comment  "         " ""  13 }
	{  guirange  "Functional Range" "Range"  comment  "         " ""  14 }
    }

    set outputs { { resliced_tmap "Resliced Output Image"  pxitclimage  "" 120 }}

    set defaultsuffix { "_createoverlay" }
    
    set scriptname bis_createoverlayimage
    set completionstatus "Done"
    #
    #document
    #

    set category "Image Processing Dual"
    set description "createoverlays an image using one or more transformations."
    set description2 "a useful check of the quality of the transformations"
    set backwardcompatibility "Reimplemented from pxmat_createoverlayimage.tcl."
    set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu."

    $this InitializeDualImageTransformationAlgorithm
    $this SetUseReslicedImageAsInput 1


    global pxtcl_pref_array

    $OptionsArray(colormap) SetValue $pxtcl_pref_array(FmriMode)
    $OptionsArray(normanat) SetValue [ expr $pxtcl_pref_array(NormalizeAnatomical) > 0 ]
}

itcl::body bis_createoverlayimage::PackOptionsGUIInterface { lst } { 


    if { $guimode == "standalone" } {
	return [ bis_algorithm::PackOptionsGUIInterface $lst ]
    }

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


	if { $tab == 1 } {
	    for { set j 0 } { $j < [ llength $wlist ] } { incr j } {
		set pair [ lindex $wlist $j ]
		set name [ lindex $pair 2 ]
		set widg [ lindex $pair 3 ]
		pack $widg -side top -expand false -fill x -padx 1
	    }
	} else {
	    set row 0
	    set col 0

	    for { set j 0 } { $j < [ llength $wlist ] } { incr j } {
		set pair [ lindex $wlist $j ]
		set name [ lindex $pair 2 ]
		set widg [ lindex $pair 3 ]
		grid $widg -row $row -column [ expr 2*$col ] -sticky new
		incr col
		if { $col == 2 } {
		    set col 0
		    incr row
		}
	    }

	    set v  [ file rootname  [ $OptionsArray(otype) GetBaseWidget ] ]
	    grid rowconfigure $v 10 -weight 100
	}
    }
    update idletasks


}
# -----------------------------------------------------------------------------------------
itcl::body bis_createoverlayimage::UpdateInputsFromContainer { } {

    bis_dualimagetransformationalgorithm::UpdateInputsFromContainer 

    set img1  [ $this GetSecondInput ] 
    set img2 [  $this GetInput ]
    
    set sp1 [ [  $img1 GetImage ] GetSpacing ] 
    set sp2 [ [  $img2  GetImage ]  GetSpacing ]
    
    set vox1 [ expr [ lindex $sp1 0 ] *  [ lindex $sp1 1 ] *  [ lindex $sp1 2 ]  ]
    set vox2 [ expr [ lindex $sp2 0 ] *  [ lindex $sp2 1 ] *  [ lindex $sp2 2 ]  ]
    set scale [ expr $vox1 / $vox2 ]
    set w [ $OptionsArray(origvoxels) GetBaseWidget ] 
    if { [ expr abs($scale -1.0) < 0.0001 ] } {
	$OptionsArray(origvoxels) SetValue 0
	if { [ winfo exists $w ] } {
	    ::bis_algorithm::DisableUI [ $OptionsArray(origvoxels) GetBaseWidget ]
	}
    } else {
	if { [ winfo exists $w ] } {
	    ::bis_algorithm::EnableUI [ $OptionsArray(origvoxels) GetBaseWidget ]
	}
    }
    

    if { $noguiupdates == 0 } {
	return [ $this UpdateInputRanges  ]
    }
}
# ----------------------------------------------------------------------------------------

itcl::body bis_createoverlayimage::UpdateInputRanges { args } {


    # This happens when image has changed 
    set currentimage  [ $this GetSecondInput ] 

    set np [ [ $currentimage GetImage ] GetNumberOfPoints ]
    if { $np < 4 } { 
	return 
    }

    set internal 0
    if { [ llength $args ] > 0 } {
	set internal 1
	if { $noguiupdates == 1 } {
#	    puts stdout "Currently Executing"
	    return
	}
    }

    set noguiupdates 1
#    puts stderr "Update Input Ranges ($args) ................"
    set clustersize [ $OptionsArray(clustersize) GetValue ]
    if { $clustersize > 0 } {
	 $OptionsArray(singframe) SetValue 1
    }

    set fr 0
    set maxfr [ [ $currentimage GetImage ] GetNumberOfScalarComponents ]
    if { [ $OptionsArray(singframe) GetValue ] > 0 } {
	set fr [ expr [ $OptionsArray(frame) GetValue ] -1 ]

	if { $fr >= $maxfr } {
	    set fr [ expr $maxfr -1 ]
	}
	set r [ [ [ [ $currentimage GetImage ] GetPointData ] GetScalars ] GetRange $fr ]
	set rmin [ lindex $r 0 ]
	set rmax [ lindex $r 1 ]
    } else {
	for { set i 0 } { $i < $maxfr } { incr i } {
	    set r [ [ [ [ $currentimage GetImage ] GetPointData ] GetScalars ] GetRange $fr ]
	    set r0 [ lindex $r 0 ]
	    set r1 [ lindex $r 1 ]

	    if { $i == 0 } {
		set rmin $r0
		set rmax $r1
	    } else {
		if { $rmin > $r0 } {
		    set rmin $r0
		}
		if { $rmax < $r1 } {
		    set rmax $r1
		}
	    }
	}
    }
    set rmin  [ expr  abs ($rmin) ]
    set rmax  [ expr  abs ($rmax) ] 
    
    if { $rmax<$rmin } {
	set rmax $rmin
    }
    
    set rmin [ expr $rmin -1.0 ]
    if { $rmin < 0.0 } {
	set rmin 0.0
    }
    set rmax [ expr $rmax +1.0 ]


    if { $rmax == 0 } {
	set rmax 1
    }

    set n [ [ $currentimage GetImage ] GetNumberOfScalarComponents ]

    $OptionsArray(minth) SetValueRange [ list 0 $rmax ]
    $OptionsArray(maxth) SetValueRange [ list 0 $rmax ]
    $OptionsArray(frame) SetValueRange [ list 1 $n ]

#    puts stdout "internal=$internal rmax=$rmax ([$currentimage cget -filename]) oldrmax=$lastrmax "

    if { $internal == 0 } {
	if { $rmax != $lastrmax } {
	    if { $rmax > 2000 } {
		$OptionsArray(minth) SetValue 2000
		$OptionsArray(maxth) SetValue $rmax
	    } elseif { $rmax > 1000 } {
		$OptionsArray(minth) SetValue 1000
		$OptionsArray(maxth) SetValue $rmax
	    } else {
		$OptionsArray(minth) SetValue [ expr $rmax/2.0 ]
		$OptionsArray(maxth) SetValue $rmax
	    } 	
	    set lastrmax $rmax
	}
	$OptionsArray(frame) SetValueIfCurrentIsTheDefault 1
    }

    set noguiupdates 0
#    puts stdout "Done with Update Input Ranges\n"
}

itcl::body bis_createoverlayimage::ConfigureOptionsGUICallbacks { } {

    eval "$OptionsArray(guisbar) SetGUICallbackFunction { $this ShowScalarBar }"
    eval "$OptionsArray(singframe) SetGUICallbackFunction { $this UpdateInputRanges }"
    eval "$OptionsArray(frame) SetGUICallbackFunction { $this UpdateInputRanges }"
}

itcl::body bis_createoverlayimage::ShowScalarBar {  args } {

    set vv [ $this GetViewer ]
    if  { $vv == 0 } {
	return 0
    }

    set outimage2 [ $this GetOutputObject resliced_tmap ]
    set np [ [ $outimage2 GetImage ] GetNumberOfPoints ]
    if { $np < 2 } {
	return 0
    }

    if { [ $OptionsArray(guisbar) GetValue ] == 0 } {
	if { [ $vv GetShowKeyRenderer ] == 1 } {
	    $vv ToggleKeyRenderer
	}
	return 
    }


    set md 0;
    switch -exact -- [ $OptionsArray(colormap) GetValue ]  {
	"F1"  {  $vv SetPresetLookupTable 1 ; set md 0} 
	"F2"  {  $vv SetPresetLookupTable 2 ; set md 1} 
	"F4"  {  $vv SetPresetLookupTable 6 ; set md 5} 
    }

    set scalarbar [ $vv GetScalarBar ]
    set scalarbar2 [ $vv GetScalarBar2 ]

    set mode [  $OptionsArray(otype) GetValue ]
    #puts stdout "Bars = $scalarbar, $scalarbar2, mode= $mode, np=$np"


    if { $mode == "Positive" || $mode == "Both" } {
	set pcmap [ vtkLookupTable [ pxvtable::vnewobj ]] 
	set cutil [ vtkpxColorMapUtil [ pxvtable::vnewobj ]] 
	$cutil SetScalarBarColormap $pcmap $md [ $OptionsArray(minth) GetValue ] [ $OptionsArray(maxth) GetValue ] 1
	$scalarbar SetTitle ""
	$scalarbar SetLookupTable $pcmap
	$pcmap Delete ; $cutil Delete
    }

    if { $mode == "Negative" || $mode == "Both" } {
	set pcmap [ vtkLookupTable [ pxvtable::vnewobj ]] 
	set cutil [ vtkpxColorMapUtil [ pxvtable::vnewobj ]] 
	$cutil SetScalarBarColormap $pcmap $md [ expr -1.0*[$OptionsArray(maxth) GetValue ]] [ expr -1.0*[$OptionsArray(minth) GetValue ]] 0
	$scalarbar2 SetTitle ""
	$scalarbar2 SetLookupTable $pcmap
	$pcmap Delete ; $cutil Delete
    }

    if { $mode == "Negative" } {	
	#puts stdout "Negative"
	[$scalarbar2 GetPositionCoordinate] SetCoordinateSystemToNormalizedViewport
	[$scalarbar2 GetPositionCoordinate] SetValue 0.1 0.1
	$scalarbar2 SetOrientationToHorizontal
	$scalarbar2 SetWidth 0.8
	$scalarbar2 SetHeight 0.9
	$scalarbar2 VisibilityOn
	$scalarbar VisibilityOff
    } elseif { $mode == "Positive" } {
	#puts stdout "Positive"
	[$scalarbar GetPositionCoordinate] SetCoordinateSystemToNormalizedViewport
	[$scalarbar GetPositionCoordinate] SetValue 0.1 0.1
	$scalarbar SetOrientationToHorizontal
	$scalarbar SetWidth 0.8
	$scalarbar SetHeight 0.9
	$scalarbar VisibilityOn
	$scalarbar2 VisibilityOff
    } else {
	#	puts stdout "Both"
	[$scalarbar2 GetPositionCoordinate] SetCoordinateSystemToNormalizedViewport
	[$scalarbar2 GetPositionCoordinate] SetValue 0.05 0.1
	$scalarbar2 SetOrientationToHorizontal
	$scalarbar2 SetWidth 0.4
	$scalarbar2 SetHeight 0.9
	$scalarbar2 VisibilityOn

	[$scalarbar GetPositionCoordinate] SetCoordinateSystemToNormalizedViewport
	[$scalarbar GetPositionCoordinate] SetValue 0.55 0.1
	$scalarbar SetOrientationToHorizontal
	$scalarbar SetWidth 0.4
	$scalarbar SetHeight 0.9
	$scalarbar VisibilityOn
    }

    if { [ $vv GetShowKeyRenderer ] == 0 } {
	$vv ToggleKeyRenderer
    }

}

itcl::body bis_createoverlayimage::UpdateContainerWithOutput { } {

    set r [ bis_dualimagetransformationalgorithm::UpdateContainerWithOutput  ]	
    set vv [ $this GetViewer ]
    if  { $vv == 0 } {
	return $r
    }

    if { [ $OptionsArray(guireslice) GetValue ] == 0 } {
	switch -exact -- [ $OptionsArray(colormap) GetValue ]  {
	    "F1"  {  $vv SetPresetLookupTable 1 } 
	    "F2"  {  $vv SetPresetLookupTable 2 } 
	    "F4"  {  $vv SetPresetLookupTable 6 } 
	}

	set outimage2 [ $this GetOutputObject resliced_tmap ]
	$vv SetEnableRendering 0
	$vv SetValueImage [ $outimage2 GetImage ]
	$vv SetEnableRendering 1
    }
}
# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_createoverlayimage::Execute {  } {

    set noguiupdates 1
    set lst [ $this ResliceImageIfNeeded ]
    set resliced_tmap [ lindex $lst 0 ]
    set tmap [  $this GetSecondInput ]  

    if { [ $OptionsArray(guireslice) GetValue ] == 1 } {
	set outimage [ $this GetOutput ]
	$outimage ShallowCopyImage $resliced_tmap
	$outimage CopyImageHeader  [ $tmap GetImageHeader ]
	$this DeleteResliceAlgorithmIfNeeded $lst 
	set noguiupdates 0
	return 1
    }


    set currentimage  [ $InputsArray(input_image) GetObject ]
    set clustersize [ $OptionsArray(clustersize) GetValue ]
    set clusterscale [ $OptionsArray(origvoxels) GetValue ]


    set fmriOverlayCreator [ vtkpxMergeFmriConventional New ]
    $fmriOverlayCreator SetConventional [ $currentimage GetImage ]
    
    if { $clustersize > 0 } {

	set clustthr $clustersize

	if { $clusterscale  == 1 } {

	    set sp1 [ [ $tmap GetImage ] GetSpacing ] 
	    set sp2 [  $resliced_tmap  GetSpacing ]
	    
	    set vox1 [ expr [ lindex $sp1 0 ] *  [ lindex $sp1 1 ] *  [ lindex $sp1 2 ]  ]
	    set vox2 [ expr [ lindex $sp2 0 ] *  [ lindex $sp2 1 ] *  [ lindex $sp2 2 ]  ]
	    set scale [ expr $vox1 / $vox2 ]
	    if { [ expr abs($scale -1.0) < 0.0001 ] } {
		$OptionsArray(origvoxels) SetValue 0
		::bis_algorithm::DisableUI [ $OptionsArray(origvoxels) GetBaseWidget ]
	    } else {
		set clustthr [ expr round($scale*$clustthr) ]
		::bis_algorithm::EnableUI [ $OptionsArray(origvoxels) GetBaseWidget ]
	    }
	} 

	set img [ pxitclimage \#auto ]
	$img ShallowCopyImage $resliced_tmap

	set clust_alg [bis_clusterthresholdimage [pxvtable::vnewobj]]
	$clust_alg InitializeFromContainer 0
	$clust_alg SetInput [ $img GetThisPointer ]
	$clust_alg SetOptionValue frame [ $OptionsArray(frame) GetValue ]
	$OptionsArray(singframe) SetValue  1
	$clust_alg SetOptionValue minth [ $OptionsArray(minth) GetValue ]
	set r [ $OptionsArray(minth) GetValueRange ]
	$clust_alg SetOptionValue maxth [ lindex $r 1 ]

	pxtkprint "Using Cluster Size = $clustthr [ $OptionsArray(minth) GetValue ], [ lindex $r 1 ]\n"
	puts stderr "Using Cluster Size = $clustthr, \n"
	$clust_alg SetOptionValue clustersize $clustthr
	$clust_alg SetOptionValue outputclustno 0
	$clust_alg SetOptionValue binary    Off
	$clust_alg SetOptionValue oneconnected  [ $OptionsArray(oneconnected) GetValue ]
	$clust_alg SetOptionValue absolutevalue 1
	$clust_alg SetOptionValue inverse   Off
	$clust_alg Execute

	$OptionsArray(singframe) SetValue 1

	itcl::delete obj $img

	$fmriOverlayCreator SetFmriInput [ [ $clust_alg GetOutput ] GetImage ]

    } else {
	$fmriOverlayCreator SetFmriInput     $resliced_tmap 
    }

    $fmriOverlayCreator SetSingleFrameMode [ expr [ $OptionsArray(singframe) GetValue ] > 0 ]
    $fmriOverlayCreator SetCurrentFrame    [ expr int([ $OptionsArray(frame) GetValue ])  -1 ]
    $fmriOverlayCreator SetIntensityThreshold [expr round([$OptionsArray(inth) GetValue ])  ]
    $fmriOverlayCreator SetMinimumThreshold   [ $OptionsArray(minth) GetValue ]
    $fmriOverlayCreator SetMaximumThreshold   [ $OptionsArray(maxth) GetValue ]
    switch -exact -- [ $OptionsArray(colormap) GetValue ]  {
	"F1"  {  $fmriOverlayCreator SetOutputMode 0 }
	"F2"  {  $fmriOverlayCreator SetOutputMode 1 }
	"F4"  {  $fmriOverlayCreator SetOutputMode 2 }
    }
	    
    $fmriOverlayCreator SetNormalizeAnatomical [ expr [ $OptionsArray(normanat) GetValue ] > 0 ] 
    
    switch -exact -- [ $OptionsArray(otype) GetValue ] { 
	"Positive" { $fmriOverlayCreator SetThresholdMode 1}
	"Both"     { $fmriOverlayCreator SetThresholdMode 3}
	"Negative" { $fmriOverlayCreator SetThresholdMode 2}
    }
    $this SetFilterCallbacks $fmriOverlayCreator "Creating Overlays"
    $fmriOverlayCreator Update


    pxtkprint "\n\nPositive Laterality = [ $fmriOverlayCreator GetPositiveLaterality ]\nNegative Laterality = [ $fmriOverlayCreator GetNegativeLaterality ]\n"

    set r [ lindex [ [ [  [ $fmriOverlayCreator GetOutput ]  GetPointData ] GetScalars ] GetRange ] 1 ]

    $OptionsArray(guilateral) SetValue [ format "P = %.2f, N=%.2f, ($r)" [ $fmriOverlayCreator GetPositiveLaterality ] [ $fmriOverlayCreator GetNegativeLaterality ]]


    set outimage [ $this GetOutput ]



    $outimage ShallowCopyImage [ $fmriOverlayCreator GetOutput ] 
    $outimage CopyImageHeader  [ $tmap GetImageHeader ]
    
    set outimage2 [ $this GetOutputObject resliced_tmap ]
    $outimage2 ShallowCopyImage $resliced_tmap
    $outimage2 CopyImageHeader  [ $tmap GetImageHeader ]

    set r [ [ [ [ $outimage2 GetImage ] GetPointData ] GetScalars ] GetRange ]
    $OptionsArray(guirange) SetValue [ format "Range %.3f:%.3f" [ lindex $r 0 ] [ lindex $r 1 ] ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0
    [ $outimage2 GetImageHeader ] AddComment "$comment $Log" 0
    
    $fmriOverlayCreator Delete
    
    $this DeleteResliceAlgorithmIfNeeded $lst 
    set noguiupdates 0
    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_createoverlayimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function
    set alg [bis_createoverlayimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

