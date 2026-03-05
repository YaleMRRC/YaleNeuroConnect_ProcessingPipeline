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

package provide bis_baselevelset 1.0
package require bis_imagetoimagealgorithm 1.0


#
# strip skull
#

itcl::class bis_baselevelset {

    inherit bis_imagetoimagealgorithm

    constructor { } {  }
    public method InitializeBaseLevelset { }
    protected method SetLevelsetParameters { filter }

    # This is the update callback
    public method ProgressCallback   { filter lab }  

    # add some "global" variables
    protected variable levelset    0
    protected variable surf_actor     
    protected variable has_surface_actors 0
    protected variable original_x 0
    protected variable padding_x  0
    protected variable dual_mode  0

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_baselevelset::InitializeBaseLevelset { } {

    PrintDebug "bis_baselevelset::InitializeBaseLevelset" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set inputs { 
	{ initial_levelset "Initial Levelset" pxitclimage  ""  101 }   
	{ seed_points      "Seed Points" pxitcllandmarks  ""  102 }   
    }

    lappend options [ list initial_mode "Initialization Mode" "Init Mode"  listofvalues seedpoint { seedpoint landmarks levelset  }  0 ]
    lappend options [ list edgestrength "Strength of Edge" "Edge Weight"  real 0.0 { 0.0 10.0  }  1 ]
    lappend options [ list propagationstrength "Strength of Propagation" "Propagation Weight"  real 1.0 { 0.0 10.0  }  2 ]
    lappend options [ list smoothnessstrength " Smoothness Factor" "Smoothness Weight"  real 0.2 { 0.0 10.0  }    3 ]
    lappend options [ list iterations "Number of Iterations for Updates" "Iterations"  { integer }  50 { 1 2000 }  4 ]
    lappend options [ list radius "Radius of Initial Ball" "Radius"  { real }  3.0 { 1.0 10.0 }  5 ]

    lappend options [ list seedx "Seed position x" "Seedx"  { integer }  91 { 0 255 }  -2 ]
    lappend options [ list seedy "Seed position y" "Seedy"  { integer }  91 { 0 255 }  -3 ]
    lappend options [ list seedz "Seed position z" "Seedz"  { integer }  91 { 0 255 }  -4 ]
    lappend options [ list updatepercentage "Update Percentage" "Update Rate"  real 0.1 { 0.0 1.0  } -5 ]
    lappend options [ list tolerance "Tolerance for Convergenece in mm" "Tolerance"  { real }  0.00001 { 0.0 1.0 }   -6 ]
    
    set defaultsuffix { "_levelset" }

    set category "Segmentation"

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Update Progress
# ----------------------------------------------------------------------------------------


itcl::body bis_baselevelset::ProgressCallback   { filter lab }  {

    if { $levelset == 0 } {  return 0    }
    ::bis_algorithm::ProgressCallback $filter $lab

    set ortho [ $this GetViewer ]
    if { $ortho == 0 } {
	return 0
    }


    if { [ $ortho IsA "vtkpxGUIOrthogonalViewer"  ] == 0 } {
	return 0
    }

    set maxj 1
    if { $dual_mode == 0 } {
	set maxj 0
    }

    # Initialization Phase
    if { $has_surface_actors == 0 } {
	for { set i 0 } { $i <=3 } { incr i } {
	    for { set j 0 } { $j <= $maxj } { incr j } {
		set map [ vtkPolyDataMapper New ]
		set surf_actor($i,$j) [ vtkActor New ]
		$surf_actor($i,$j) SetMapper $map
		$map Delete
		
		[ [ $ortho GetRenderer $i ] GetRenderer ] AddActor $surf_actor($i,$j)
		#		puts stderr "Creating Actor $i $j $surf_actor($i,$j)"
		set prop [ $surf_actor($i,$j) GetProperty ]
		if { $j == 1 } {
		    $prop SetColor 1.0 0.0 0.0
		} else {
		    $prop SetColor 0.0 1.0 0.0
		    if { $i == 3 } {
			$prop SetOpacity 0.8
		    }
		}
		
		if { $i !=3 } {
		    $prop SetRepresentationToWireframe
		    $prop SetAmbient 1.0
		    $prop SetDiffuse 0.0
		    $prop SetSpecular 0.0
		    $prop SetLineWidth 2.0
		}
	    }
	}
	set has_surface_actors 1
	return 0
    }


    puts stderr "Status = [ $levelset GetOutputStatus ]\n"

    for { set j 0 } { $j <= $maxj } { incr j } {
	
	set pd [ vtkImageData New ] 
	
	if { $j ==  1 } {
	    $pd ShallowCopy [  $levelset GetOutput2 ]  
	} else {
	    $pd ShallowCopy [  $levelset GetOutput ]  
	}

	puts stderr "Extracting $j dims = [ $pd GetDimensions ]"
	    
	set skinExtractor [ vtkContourFilter [ pxvtable::vnewobj ] ]
	$skinExtractor SetUseScalarTree 0
	$skinExtractor ComputeScalarsOff
	$skinExtractor ComputeGradientsOff
	$skinExtractor SetInput $pd
	$skinExtractor SetValue 0 0.0
	$skinExtractor Update
		
	puts stderr "this far updating $j"
	for { set i 0 } { $i <=3 } { incr i } {
	    [ $surf_actor($i,$j) GetMapper ] SetInput [ $skinExtractor GetOutput ]
	}
	$skinExtractor Delete
	$pd Delete
    }
    $ortho UpdateDisplay
    update idletasks
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_baselevelset::SetLevelsetParameters { filter  } {

    set edge         [ $OptionsArray(edgestrength)    GetValue ]
    set smoothness   [ $OptionsArray(smoothnessstrength)    GetValue ]
    set propagation    [ $OptionsArray(propagationstrength) GetValue ]
    set iterations  [ $OptionsArray(iterations) GetValue ]
    set tolerance  [ $OptionsArray(tolerance) GetValue ]
    set radius      [ $OptionsArray(radius) GetValue ]
    set updateper   [ $OptionsArray(updatepercentage) GetValue ]
    set initmode    [ $OptionsArray(initial_mode) GetValue ]
    set image_in      [ $this GetInput ]

    
    $filter SetInput [ $image_in GetImage]
    $filter SetPropagationWeight $propagation
    $filter SetCurvatureWeight $smoothness
    $filter SetAdvectionWeight   $edge
    $filter SetInitialDistance $radius
    $filter SetRMSError $tolerance
    $filter SetLevelsetIterations $iterations
    $filter SetUpdatePercentage $updateper


    if { $initmode == "seedpoint" } {
	set seedx      [ $OptionsArray(seedx) GetValue ]
	set seedy      [ $OptionsArray(seedy) GetValue ]
	set seedz      [ $OptionsArray(seedz) GetValue ]
	set pt [ vtkPoints New ]
	$pt SetNumberOfPoints 1
	$pt SetPoint 0 $seedx $seedy $seedz
	$filter SetInitialPoints $pt
	$pt Delete
    } elseif { $initmode == "landmarks" } {

	set land [ [ $this GetInputObject seed_points ] GetLandmarks ]
	if { [ [ $land GetPoints ] GetNumberOfPoints ] < 1 } {
	    return 0
	}

	set baseCurve [ vtkpxBaseCurve New ]
	$baseCurve Copy $land 
	$baseCurve SetSpacing 1.0 1.0 1.0
	$baseCurve SetOrigin 0.0 0.0 0.0
	$baseCurve Compact
	
	$filter SetInitialPoints [ $baseCurve GetPoints ]
	$baseCurve Delete
    } else {
	set img1 [ $image_in GetImage]
	set img2 [ $this GetInputObject initial_levelset ] 
	set d1 [ $img1 GetImageSize ]
	set d2 [ $img2 GetImageSize ]
	if { $d1 != $d2 } {
	    return 0
	}

	$filter SetInitialLevelSet [ $img2 GetImage ]
    }

    return 1
}


