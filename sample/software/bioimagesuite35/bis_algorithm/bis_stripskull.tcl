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

package provide bis_stripskull 1.0
package require bis_imagetoimagealgorithm 1.0


#
# strip skull
#

itcl::class bis_stripskull {

    inherit bis_imagetoimagealgorithm

    constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method UpdateOutputFilenames { }
    public method Execute { }
    public method GetGUIName    { } { return "Strip Skull" }
    public method CreateGUI { parent { callafter 0 } { callbefore 0 } }
    public method HandleCoordinateChangeEvent { args }

    protected variable chain_viewer_callback ""
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_stripskull::Initialize { } {

    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ radiusfactor "Scale Factor for the Radius" "Radius Scale Factor"  { real triplescale 100 }  0.5 { 0.2 1.0 }  0 }
	{ subdivisions "Number of Subvidisions for Icosahedron" "Subvidisions"  { integer }  4 { 0 8 }  1 }
	{ iterations "Number of Iterations for Updates" "Iterations"  { integer }  1000 { 1 2000 }  2 }
	{ tolerance "Tolerance for Convergenece in mm" "Tolerance"  { real }  0.1 { 0.0 2.0 }  -110 }
	{ smoothing "Use Increased Smoothing" "Smoothing"  boolean  1 { 0 1 } -111 }
	{ numpasses "Number Passes Made To Smooth the Surface" "Passes"  { integer }  10 { 1 10 } -112 }
	{ initMethod "Set the Center of Gravity and Radius Automatically, Manually, or Using the Crosshairs" "Manual Init."  { listofvalues radiobuttons } auto { auto manual crosshair } -113 }
	{ manRadius "Set the Initial Surface Radius Manually" "Radius"  { real }  1.0 { 0.01 1000.0 } -114 }
	{ manX "Set the Initial Surface Center x-coord Manually (Using Display Coordinates)" "X"  { real }  0.0 { 0.0 1000.0 } -115 }
	{ manY "Set the Initial Surface Center y-coord Manually (Using Display Coordinates)" "Y"  { real }  0.0 { 0.0 1000.0 } -116 }
	{ manZ "Set the Initial Surface Center z-coord Manually (Using Display Coordinates)" "Z"  { real }  0.0 { 0.0 1000.0 } -117 }
	{ numbins "Number of Bins for Histogram Fitting" "Bins"  { integer }  1000 { 32 1024 } -118 }
	{ minPercent "Cummulative Histogram Lower Threshold Percent" "MinPercent"  { real }  0.02 { 0.0 0.5 } -119 }
	{ maxPercent "Cummulative Histogram Upper Threshold Percent" "MaxPercent"  { real }  0.98 { 0.5 1.0 } -120 }
	{ minIntenSearchDist "Distance Searched for Minimum Intensity" "Min Intensity Search"  { real }  7.0 { 1.0 20.0 } -123 }
	{ maxIntenSearchDist "Distance Searched for Maximum Intensity" "Max Intensity Search"  { real }  3.0 { 0.5 10.0 } -124 }
	{ rMin "Minimum Local Radius Used for Smoothing" "rMin"  { real }  3.33 { 0.1 100.0 } -125 }
	{ rMax "Maximum Local Radius Used for Smoothing" "rMax"  { real }  10.0 { 0.1 100.0 } -126 }
	{ localThreshConst "Local Fractional Constant" "Local Threshold"  { real }  0.5 { 0.01 1.0 } -127 }
	{ selfIntersectThresh "Threshold for Surface Self-Intersections" "Self-Intersection"  { real }  3000 { 0 10000 } -128 }
    }
	#{ manual "Use Manual Center of Gravity and Radius" "Manual Init."  boolean  0 { 0 1 } -113 }

    set outputs {
    { output_mask "Output Mask" pxitclimage "" 2 }   
    { output_surface "Output Surface" pxitclsurface "" 3 }   
    }
    
    
    set defaultsuffix "_stripped"

    set scriptname bis_stripskull
    set completionstatus "To be tested"

    #
    #document
    #
	
    set description "Performs skull stripping" 
    set description2 "a reimplementation of the BET algorithm"
    set backwardcompatibility "None"
    set authors "john.onofrey@yale.edu"
    set category "Segmentation"

    $this InitializeImageToImageAlgorithm
}


# -----------------------------------------------------------------------------------------
itcl::body bis_stripskull::UpdateOutputFilenames { } {
#    puts stderr "Updating output filenames!"
    
    set f [ $InputsArray(input_image) GetFileName ]
    
    set l [ ::bis_common::SplitFileNameGZ $f ]
    set f [ file tail [ lindex $l 0 ] ]
    set ext [ lindex $l 1 ]

    $OutputsArray(output_image) SetFileName "$f${defaultsuffix}$ext"
    $OutputsArray(output_mask) SetFileName "$f${defaultsuffix}_mask$ext"
    $OutputsArray(output_surface) SetFileName "$f${defaultsuffix}_surface.vtk"
}


# -----------------------------------------------------------------------------------------
itcl::body bis_stripskull::HandleCoordinateChangeEvent { args } {

    #puts "In Handle Mouse Event $args"
    if { [ $this GetBisViewer ] ==0 } {
	   set lv [ [ $this GetViewer ] GetLastClickedPointScaled ] 
    } else {
	   set lv [ lindex $args 1]
    }
    set px [ lindex $lv 0 ]
    set py [ lindex $lv 1 ]
    set pz [ lindex $lv 2 ]
    #puts stderr "Setting bet cog to $px $py $pz"
    
    
    $OptionsArray(manX) SetValue $px
    $OptionsArray(manY) SetValue $py
    $OptionsArray(manZ) SetValue $pz
    
    if { [ $this GetBisViewer ] ==0  && $chain_viewer_callback !="" } {
	catch { eval $chain_viewer_callback }
    }
}

# ------------------------------------------------------------------------------------------

itcl::body bis_stripskull::CreateGUI { parent { callafter 0 } { callbefore 0 } } {


    set r [ bis_algorithm::CreateGUI $parent $callafter $callbefore ]
    
    if { [ $this GetBisViewer ] !=0 } {
	$bis_viewer AddCursorNotifier $this "HandleCoordinateChangeEvent"
	set chain_viewer_callback ""
    } else {

	# Legacy to put it mildly 
	set vv [ $this GetViewer ]
	if { $vv !=0 } {
	    if { [ $vv IsA "vtkpxGUIOrthogonalViewer" ] == 0 } {
		  set vv 0
	    }
	}
    
	if { $vv !=0 } {
	    set a "$this HandleCoordinateChangeEvent"
	    set chain_viewer_callback [ $vv GetCoordinateChangeCallback ]
	    $vv SetCoordinatesChangeCallback $a
	    #	puts stderr "Callbacks $a, $chain_viewer_callback"
	    $vv SetEnableCoordinatesChangeCallback 1
	}
    }
    return $r
}


# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_stripskull::Execute {  } {

    set radiusscale   [ $OptionsArray(radiusfactor) GetValue ]
    set initMethod    [ $OptionsArray(initMethod)   GetValue ]
    set radius	      [ $OptionsArray(manRadius)    GetValue ]
    set manX	      [ $OptionsArray(manX)         GetValue ]
    set manY	      [ $OptionsArray(manY)	    GetValue ]
    set manZ	      [ $OptionsArray(manZ)	    GetValue ]
    set tolerance     [ $OptionsArray(tolerance)    GetValue ]
    set res           [ $OptionsArray(subdivisions) GetValue ]
    set smooth        [ $OptionsArray(smoothing)    GetValue ]
    set bins          [ $OptionsArray(numbins)      GetValue ]
    set minT          [ $OptionsArray(minPercent)   GetValue ]
    set maxT          [ $OptionsArray(maxPercent)   GetValue ]
    set numiter       [ $OptionsArray(iterations)   GetValue ]
    set passes	      [ $OptionsArray(numpasses)    GetValue ]
    set minSearch     [ $OptionsArray(minIntenSearchDist)    GetValue ]
    set maxSearch     [ $OptionsArray(maxIntenSearchDist)    GetValue ]
    set rMin	      [ $OptionsArray(rMin)         GetValue ]
    set rMax	      [ $OptionsArray(rMax)         GetValue ]
    set localT	      [ $OptionsArray(localThreshConst)      GetValue ]
    set selfIntersectT  [ $OptionsArray(selfIntersectThresh) GetValue ]
	
    # image_in is a pxitclimage which is a wrapper around vtkImageData
    set image_in      [ $this GetInput ]
	
    # Get spacing and origin of the image for use during manual initialization
    set spa [ [ $image_in GetImage ] GetSpacing ]
    set ori [ [ $image_in GetImage ] GetOrigin ]

    set bet [ vtkjoBETImageFilter New ]
    $bet SetInput [ $image_in GetImage]
    $bet SetBins $bins
    $bet SetMinIntensityPercent $minT
    $bet SetMaxIntensityPercent $maxT
    
    if { $initMethod != "auto" } {
	   puts stderr "Setting manual radius and CoG"
	   $bet ManualRadiusAndCOGOn
	   $bet SetRadius $radius

        set px $manX
        set py $manY
        set pz $manZ

        # Check if a viewer exists for crosshair mode
        if { [ $this GetViewer ] == 0 } {
            puts stderr "No viewer - disabling crosshair method, and using manual cog"
        }
        
        if { $initMethod == "crosshair" && [ $this GetViewer ] != 0 } {
            puts stderr "Using crosshair method..."

		    set lv [ $vtk_viewer GetLastClickedPointScaled ] 
            set px [ lindex $lv 0 ]
            set py [ lindex $lv 1 ]
            set pz [ lindex $lv 2 ]
	   }
       puts stderr "Setting bet cog to $px $py $pz"
       $bet SetCenterOfGravity $px $py $pz
    }
    
    $bet SetRadiusScaleFactor $radiusscale
    $bet SetMaxIterations $numiter
    $bet SetMaxPasses $passes
    $bet SetSurfaceResolution $res
    $bet SetMinChangeTolerance $tolerance
    $bet SetMinIntensitySearchDist $minSearch
    $bet SetMaxIntensitySearchDist $maxSearch
    $bet SetRMin $rMin
    $bet SetRMax $rMax
    $bet SetLocalThresholdConst $localT
    $bet SetSelfIntersectionThreshold $selfIntersectT
    $bet SetIncreasedSmoothing $smooth

    # This sets the callbacks for updating the interface
    $this SetFilterCallbacks $bet "Stripping Skull"

    # Run The Algorithm
    $bet Update
	
    # Compute Stripped Image
    set img [ $bet GetOutput ]

    # Copy output image into proper structure
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
    $outimage ShallowCopyImage $img

    # Add a comment to image header
    set comment [ format "BIS::bis_stripskull.tcl skull stripped" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    # Copy the output image mask into the proper structure
    set outmask [ $OutputsArray(output_mask) GetObject ]
    $outmask CopyImageHeader [ $image_in GetImageHeader ]
    $outmask ShallowCopyImage [ $bet GetOutputMask ]
    [ $outmask GetImageHeader ] AddComment "$comment $Log" 0

    # Copy the output surface to the output object structure
    set outsurf [ $OutputsArray(output_surface) GetObject ]
    $outsurf ShallowCopySurface [ $bet GetSurface ]
    $outsurf AddComment "$comment $Log"
    
    # Clean up
    $img Delete
    $bet Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_stripskull.tcl) if it is execute
# ----------------------------------------------------------------------------------------

if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_stripskull [pxvtable::vnewobj]]
    $alg MainFunction 
}





