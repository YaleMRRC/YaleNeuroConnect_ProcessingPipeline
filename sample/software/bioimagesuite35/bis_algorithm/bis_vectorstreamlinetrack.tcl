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
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] mjack ]

package provide bis_vectorstreamlinetrack 1.0
package require bis_imagetosurfacealgorithm 1.0
package require vtkmpjcontrib 

itcl::class bis_vectorstreamlinetrack {

    inherit bis_imagetosurfacealgorithm

    constructor { } {	 $this Initialize  }
    destructor { $this CleanCachedStreamer }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Vector Streamline Track" }

    protected method CreateStreamer { tensor solution { track_map 1 }  }
    protected method TrackFiber { streamer seedx seedy seedz index { minspeed 0.01 } { maxdist 1000.0 } { integration 0 } {  steplen 0.5 } { fitspline 0 } { uniformcolor 0 } }

    # Cache Stuff
    protected method CleanCachedStreamer { }
    protected method IsStreamerValid { }
    protected variable old_streamer 0
    protected variable old_streamer_mode -1
    protected variable old_solution_dimensions { 0 0 0 }

    # Seed Initialization
    protected method ConfigureOptionsGUICallbacks { } 
    public    method AutoSeed { args } 

    protected variable added_cursor_notifier 0
}


# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_vectorstreamlinetrack::Initialize { } {

    PrintDebug "bis_vectorstreamlinetrack::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ minspeed "Minimum speed from Front Evolution" "Minimum Speed"   real 0.01 { 0.00001 100.0 }  -10 }
	{ maxdist "Maxmimum tracking distance (in mm)" "Max Distance"   real 1000.0 { 1.0 10000.0 }  -11 }
	{ integrationmode "Integradion Mode 0=RungeKutta2, 1=RungeKutte4" "Runge-Kutta 4" boolean 0 { 0 1 } -12 }
	{ steplen "Integration Step Length" "Step Length" real 0.5 { 0.1 5.0 } 1 }
	{ fitspline "Smooth fibers by fitting spline" "Fit Spline" boolean  0 { 0 1 } -14 }
	{ usechar "Use Characteristics of Potential Field instead of Gradient" "Use Characteristics" boolean 0 { 0 1 } -15 }
	{ colorbyseed "Use a different color for each seed" "Seed Color" boolean 0 { 0 1 } 5 }
	{ cachemode "Reuse initial solution if available (and possible). Only useful for GUI/multiple invokations" "Reuse Initial Solution " boolean 1 { 0 1 } 10 }
	{ manualseed "Use seed coordinates as specified using seedx, seedy, seedz instead of landmark file (inp3)" "Manual Seed " boolean 0 { 0 1 } 11 }
	{ usevalueimage "Use value image to generate stats" "Use Value Image " boolean 0 { 0 1 } 13 }
	{ guiautoupdate  "Update seed from GUI Cross-Hairs" "Auto Seed"  { boolean } 0 { 0 1 }  15 }
	{ seedx   "X Coordinate of seed location in mm" "Seed X"  { real default   } 64 { 0 1999 }  -1 }
	{ seedy   "Y Coordinate of seed location in mm" "Seed Y"  { real default   } 73 { 0 1999 }  -2 }
	{ seedz   "Z Coordinate of seed location in mm" "Seed Z"  { real default   } 20 { 0 1999 }  -3 }
    }

    
    set inputs {
	{ tensor      "Tensor Image" pxitclimage "" 9 }
	{ seeds   "Landmarks for tracking" pxitcllandmarks "" 200 }
	{ valueimage  "Map for Value e.g. fa map (optional)"             pxitclimage  "" 500 }
    }

    
    set scriptname bis_vectorstreamlinetrack
    set completionstatus "Done"

    #
    #document
    #

    set category "Diffusion Tensor"    
    set description "Computes trajectories from a set of landmarks back to seed given an input solution map based on fast marching tractography"
    set description2 ""
    set backwardcompatibility "None"
    set authors "xenophon.papademetris@yale.edu based on some original code by Marcel Jackowski."

    $this InitializeImageToSurfaceAlgorithm

}
# ---------------------------------------------------------------------------------------

itcl::body bis_vectorstreamlinetrack::ConfigureOptionsGUICallbacks { } {

    eval "$OptionsArray(guiautoupdate) SetGUICallbackFunction { $this AutoSeed }"
}

itcl::body bis_vectorstreamlinetrack::AutoSeed {  args } {

    if { [ $OptionsArray(guiautoupdate) GetValue ] ==0 } {
	return
    }

    if { $added_cursor_notifier == 0 } {
	set bv [ $this GetBisViewer ]
	if { $bv !=0 } {
	    if { [ $bv isa bis_viewer ] } {
		set added_cursor_notifier 1
		$bv AddCursorNotifier $this AutoSeed 
	    }
	}
    }

    if { [ $this GetViewer ] != 0 } {
	set lv [ $vtk_viewer GetLastClickedPointScaled ] 
	set px [ lindex $lv 0 ]
	set py [ lindex $lv 1 ]
	set pz [ lindex $lv 2 ]
	if { $px>0 || $py>0 || $pz>0 } {
	    $OptionsArray(seedx) SetValue $px
	    $OptionsArray(seedy) SetValue $py
	    $OptionsArray(seedz) SetValue $pz
	}
    }
}


# ---------------------------------------------------------------------------------------
itcl::body bis_vectorstreamlinetrack::CreateStreamer { tensor solution { track_map 1 } } {

    puts "Num Components  [ [ $solution GetImage ] GetNumberOfScalarComponents ]"

    set extr [ vtkImageExtractComponents New ]
    $extr SetInput [ $solution GetImage ]
    $extr SetComponents 0
    $extr Update

    ## calculate gradient
    set imgrad [ vtkmpjLevelSetNormal [ pxvtable::vnewobj ] ]
    $imgrad SetInput [ $extr GetOutput ]
    $this SetFilterCallbacks $imgrad "Calculating gradient..."
    $imgrad Update
    $extr Delete
    
    set gradient [ pxitclimage \#auto ]
    $gradient ShallowCopyImage [ $imgrad GetOutput ]  
    
    ## calculate characteristics
    set imchar [ vtkmpjImageCharacteristics [ pxvtable::vnewobj ] ]
    $imchar SetInput [ $tensor GetImage ]
    $imchar SetGradient [ $imgrad GetOutput ]
    
    set global_list(solution_a) 3
    set global_list(solution_b) 2
    set global_list(solution_c) 1
    
    $imchar SetCoefficientA $global_list(solution_a)
    $imchar SetCoefficientB $global_list(solution_b) 
    $imchar SetCoefficientC $global_list(solution_c)
    $this SetFilterCallbacks $imchar "Calculating characteristics..."
    $imchar Update
    
    set character [ pxitclimage \#auto ]
    $character ShallowCopyImage [ $imchar GetOutput ]  
    $imchar Delete
    $imgrad Delete


    ## get eigenvalues
    set eigen [ vtkmpjImageTensorEigenAnalysis [ pxvtable::vnewobj ] ]
    $this SetFilterCallbacks $eigen "Computing eigenvalues and eigenvectors..."
    $eigen SetInput [ $tensor GetImage ]
    $eigen SetOutputTypeToEigenvectors
    $eigen Update
    
    set imdot [ vtkmpjImageDotProduct [ pxvtable::vnewobj ] ]
    $this SetFilterCallbacks $imdot "Computing angle..."
    $imdot SetInput1 [ $eigen GetInput ]
    $imdot SetInput2 [ $character GetImage ]
    $imdot Update

    set dot [ pxitclimage \#auto ]
    $dot ShallowCopyImage [ $imdot GetOutput ]  
    $imdot Delete

    set imdot [ vtkmpjImageDotProduct [ pxvtable::vnewobj ] ]
    $this SetFilterCallbacks $imdot "Computing angle2..."
    $imdot SetInput1 [ $eigen GetInput ]
    $imdot SetInput2 [ $gradient GetImage ]
    $imdot Update
    $eigen Delete
    set converge [ pxitclimage \#auto ]
    $converge ShallowCopyImage [ $imdot GetOutput ]  
    $imdot Delete


    set imtovec [ vtkmpjImageToVectors [ pxvtable::vnewobj ] ]

    if { $track_map == 0 } {
	## convert into vector field
	$imtovec SetInput [ $gradient GetImage ]
	$imtovec Update
    } else {
	$imtovec SetInput [ $character GetImage ]
	$imtovec Update
    }
    
    set merge [ vtkMergeFilter [ pxvtable::vnewobj ] ]
    $merge SetGeometry [ $dot GetImage ]
    $merge SetVectors  [ $imtovec GetOutput ]
    if { $track_map == 0 } {
	$merge SetScalars [ $converge GetImage ]
    } else {
	$merge SetScalars [ $dot GetImage ]
    }
    $merge Update
    


    $imtovec Delete

    ## initialize streamer ##
    set streamer [ vtkmpjVectorStreamline [ pxvtable::vnewobj ] ]
    $this SetFilterCallbacks $streamer "Fiber tracking..."
    $streamer SetInput [ $merge GetOutput ]

    itcl::delete obj $gradient
    itcl::delete obj $character
    itcl::delete obj $dot
    itcl::delete obj $converge


#    $merge Delete
    return $streamer
}

itcl::body bis_vectorstreamlinetrack::TrackFiber { streamer seedx seedy seedz index { minspeed 0.01 } { maxdist 1000.0 } { integration 0 } {  steplen 0.5 } { fitspline 0 } { uniformcolor 0 } } {

    set source [ vtkPolyData [ pxvtable::vnewobj ] ] 
    set points [ vtkPoints [ pxvtable::vnewobj ] ]
    
    $points InsertNextPoint $seedx $seedy $seedz 
    $source SetPoints $points
    $points Delete
    ## assign source point
    $streamer SetSource $source
    
    $source Delete
    
    #    puts "num seed points: [ [ [ $streamer GetSource ] GetPoints ] GetNumberOfPoints ]"
    #    puts "min speed = $minspeed, maxdist=$maxdist "
    
    $streamer SetTerminalSpeed $minspeed
    $streamer SetIntegrationDirectionToBackward
    $streamer SetMaximumPropagationTime $maxdist

    if { $integration == 0 } { 
	$streamer SetIntegrator [ vtkRungeKutta2 [ pxvtable::vnewobj ] ]
    } else {
	$streamer SetIntegrator [ vtkRungeKutta4 [ pxvtable::vnewobj ] ]
    }
    
    $streamer SetIntegrationStepLength $steplen
    $streamer SetStepLength $steplen
    $streamer Update

    

    
    set new_fiber [ vtkPolyData [ pxvtable::vnewobj ] ]
    
    ## create new fiber set
    set np [ $new_fiber GetNumberOfPoints ]
    if { $fitspline > 0 && $np > 0 } {
	set spline [ vtkSplineFilter [ pxvtable::vnewobj ] ]
	$this SetFilterCallbacks $spline "Spline fitting..."
	$spline SetInput [ $streamer GetOutput ]
	$spline SetSubdivide 0
	$spline SetLength 0.1
	$spline SetNumberOfSubdivisions 100
	$spline Update
	$new_fiber ShallowCopy [ $spline GetOutput ]
	$spline Delete
    } else {	
	$new_fiber ShallowCopy [ $streamer GetOutput ]
    }
    
    set np [ $new_fiber GetNumberOfPoints ]
    if { $uniformcolor > 0 && $np > 0 } {
	set arr [ vtkShortArray New ]
	$arr SetNumberOfTuples $np
	$arr FillComponent 0 [ expr $index  +1 ]
 	[ $new_fiber GetPointData ] SetScalars $arr
	$arr Delete
    }
    return $new_fiber

}

# ------------------------------------------------------------------------------------
itcl::body bis_vectorstreamlinetrack::IsStreamerValid { } {
    if { $old_streamer == 0 } {
	#	puts stdout "No old_streamer in memory"
	return 0
    }

    if { [ $OptionsArray(usechar) GetValue ]  != $old_streamer_mode  } {
	#puts stdout "Bad usechar mode"
	return 0
    }
    
    set img [ [ $this GetInput ] GetImage ]
    scan [ $img GetDimensions ] "%d %d %d" x1 y1 z1

    if { $x1 != [ lindex $old_solution_dimensions 0 ] ||
	 $y1 != [ lindex $old_solution_dimensions 1 ] ||
	 $z1 != [ lindex $old_solution_dimensions 2 ] } {
	#puts stdout "Bad Dimensions [ $img GetDimensions ] , $old_solution_dimensions"
	return 0
    }

    return 1
}

itcl::body bis_vectorstreamlinetrack::CleanCachedStreamer { } {

    if { $old_streamer != 0 }  {
	$old_streamer Delete
	set old_streamer 0
    }
    
    set old_streamer_mode -1
    set old_solution_dimensions { 0 0 0 }
}

itcl::body bis_vectorstreamlinetrack::Execute {  } {

    PrintDebug "bis_vectorstreamlinetrack::Execute"
    set solution [ $this GetInput ]
    set tensor    [ $this GetInputObject tensor ] 
    set landmarks [ [ $this GetInputObject seeds ] GetLandmarks ]

    set minspeed [ $OptionsArray(minspeed) GetValue ]
    set maxdist  [ $OptionsArray(maxdist)  GetValue ]
    set intmode  [ $OptionsArray(integrationmode)  GetValue ]
    set steplen   [ $OptionsArray(steplen)  GetValue ]
    set fitspline  [ $OptionsArray(fitspline)  GetValue ]
    set colormode [ $OptionsArray(colorbyseed) GetValue ]
    set usexhairs [ $OptionsArray(manualseed) GetValue ]

    #    puts stdout "Solution = [ $solution GetDescription ]\n\n\n"

    if { [ $landmarks GetNumPoints  ] < 1 && $usexhairs == 0 } {
	set errormessage "Not enough seeds specified"
	return 0
    }

    if { [ [ $tensor GetImage ]  GetNumberOfScalarComponents ] !=6 } {
	set errormessage "Error: Bad input image (not a tensor, nc!=6 )"
	return 0
    }

    if {  [ $tensor GetImageSize ] != [ $solution GetImageSize ] } {
	set errormessage "Tensor and Solution must have same number of voxels\n"
	return 0
    }

    set usecache [ $OptionsArray(cachemode) GetValue ]
    set usingcache 0
    set streamer 0
    if { $usecache > 0 } {
	set isvalid [ $this IsStreamerValid ]
	if { $isvalid > 0 } {
	    set streamer $old_streamer
	    set usingcache 1
	}
	#puts stdout "IsValid = $isvalid Using Cache=$usingcache"
    }

    if { $streamer == 0 } {
	puts stdout "Creating Streamer"
	set streamer [ $this CreateStreamer $tensor $solution [ $OptionsArray(usechar) GetValue ] ]
	set usingcache 0
    } else {
	puts stdout "Using Cached streamer ($usingcache)"
    }

    set b1 [ vtkpxBaseCurve New ]

    $this AutoSeed

    if { $usexhairs > 0 } {
	set px [ $OptionsArray(seedx) GetValue ] 
	set py [ $OptionsArray(seedy) GetValue ] 
	set pz [ $OptionsArray(seedz) GetValue ] 

	if { $px>0 || $py>0 || $pz>0 } {
	    puts stdout "Adding $px $py $pz"
	    $b1 AddPoint $px $py $pz
	} else {
	    set errormessage "Bad Manual Seed/Viewer Cross Hairs"
	    return 0
	}
    } else {
	$b1 Copy $landmarks
    }
    $b1 Compact
    
    
    set seeds [ $b1 GetPoints ]

    set b2 [ vtkpxBaseCurve New ]
    
    set append [ vtkAppendPolyData New ]
    
    for { set i 0 } { $i < [ $seeds GetNumberOfPoints ] } { incr i } {
	set pt [ $seeds GetPoint $i ]
	set x [ lindex $pt 0 ]
	set y [ lindex $pt 1 ]
	set z [ lindex $pt 2 ]
	puts  stdout "Tracking From ($x $y $z) colormode=$colormode\n"
	set result   [ $this TrackFiber $streamer $x $y $z [ expr $i +1 ] $minspeed $maxdist $intmode $steplen $fitspline $colormode ]
	$append AddInput  $result

	$b2 SetFromPoints [ $result GetPoints ]
	$b2 SetClosedCurve 0
	set l [ $b2 GetLength ]
	puts stdout "\t\t\t ... fiber has [ $result GetNumberOfPoints ] points and length = $l mm"
	$result Delete
    }
    $b2 Delete

    $append Update
    [ $OutputsArray(output_surface) GetObject ] DeepCopySurface [ $append GetOutput ]
    
    if { $colormode > 0 } {
	set ut [ vtkpxSurfaceUtil New ]
	$ut AddObjectMapLookupTableToSurface  [  [ $OutputsArray(output_surface) GetObject ]  GetSurface ]
	$ut Delete
    }
    $append Delete

    if { $usingcache == 0 } {
	set old_streamer $streamer 
	set old_streamer_mode [ $OptionsArray(usechar) GetValue ] 
	set old_solution_dimensions [ [ $solution GetImage ] GetDimensions ]
	puts stdout "Caching done $old_streamer, $old_streamer_mode $old_solution_dimensions"
    }
    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_vectorstreamlinetrack.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_vectorstreamlinetrack [pxvtable::vnewobj]]
    $alg MainFunction 
}





