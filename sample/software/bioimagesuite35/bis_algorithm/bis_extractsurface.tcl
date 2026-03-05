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

package require bis_imagetosurfacealgorithm 1.0                
package provide bis_extractsurface 1.0

#
# compute curvatures of polydata
#

itcl::class bis_extractsurface {

    inherit bis_imagetosurfacealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Extract Surface" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_extractsurface::Initialize { } {

    PrintDebug "bis_extractsurface::Initialize" 
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
		{ smoothing "Pick smoothing On/Off. " "Smoothing" { boolean}  1 { 0 1 }   0}
		{ smoothscale "Smoothing scale" "Smoothing scale"  { real triplescale 100 }    1.0 { 0.25 6.0 }  1 }
        { resample "Resample On/Off" "Resampling" { boolean}  1 { 0 1 }   2}
		{ resamplescale "Resample scale" "Resample scale"  { real triplescale 100 }    2.0 { 1.0 6.0 }  3 }
        { thresholding "Perform Thresholding" "Thresholding" { boolean }  1 { 0 1 }   4}
		{ extractLevel "Extract Level" "Extract Level"  { real triplescale 100 }    128.0 { 0.0 255.0 }  5 }
		{ lowthreshold "Low Threshold" "Low Threshold"  { real triplescale 100 }    0.0 { 0.0 255.0 }  6 }
		{ highthreshold "High Threshold" "High Threshold"  { real triplescale 100 }    255.0 { 0.0 255.0 }  7 }
    }

    set defaultsuffix { "_extractsurface" }
    
    set scriptname bis_extractsurface

    #
    #document
    #
    set category "Surface Processing"
    set description  "Extract a surface from an image"
    set description2 ""
    set backwardcompaibitlity "Newly added."
    set authors "alark.joshi@yale.edu"

    $this InitializeImageToSurfaceAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_extractsurface::Execute {  } {

    PrintDebug "bis_extractsurface::Execute"

    # Get Inputs
    set image_in [ $this GetInput ]


    # GetOptions
    
    set smoothing [ $OptionsArray(smoothing) GetValue ]
    set smoothscale [ $OptionsArray(smoothscale) GetValue ]
    set resample [ $OptionsArray(resample)      GetValue ]
    set resamplescale [ $OptionsArray(resamplescale)      GetValue ]
    set thresholding [ $OptionsArray(thresholding)      GetValue ]
    set extractLevel [ $OptionsArray(extractLevel)      GetValue ]
    set lowthreshold [ $OptionsArray(lowthreshold) GetValue ]
    set highthreshold [ $OptionsArray(highthreshold)      GetValue ]

    set lastoutput [ vtkImageData [ pxvtable::vnewobj ] ]
    $lastoutput ShallowCopy [ $image_in GetObject] 
    
    
    if { $smoothing == "1"} {
	    set smrad [ expr { int( $smoothscale * 2.0 + 1.5 ) } ]
	    set smoothFilter [ vtkImageGaussianSmooth [ pxvtable::vnewobj ] ]
	    $smoothFilter SetInput $lastoutput 
	    $smoothFilter SetStandardDeviations $smoothscale $smoothscale $smoothscale
	    $smoothFilter SetRadiusFactors $smoothscale $smoothscale $smoothscale
	    $smoothFilter Update 
	    
	    $lastoutput ShallowCopy [ $smoothFilter GetOutput ]
	    
	    $smoothFilter Delete 
    }
	
    if { $resample == "1" } {
	    set scalefact [ expr { 1.0 / $resamplescale } ]
  	    set resl [ vtkbisImageResample [ pxvtable::vnewobj ] ]
	    $resl SetInput $lastoutput
	    $resl SetInterpolate 1 
	    $resl SetAxisMagnificationFactor 0 $scalefact
	    $resl SetAxisMagnificationFactor 1 $scalefact
	    $resl SetAxisMagnificationFactor 2 $scalefact
	    $resl Update 
	    
	    $lastoutput ShallowCopy [ $resl GetOutput ] 
	    $resl Delete 
    }
	    
    if { $thresholding == "1" } { 
	    if { $lowthreshold > $highthreshold } {
		    set t $highthreshold
		    set highthreshold $lowthreshold
		    set lowthreshold $t		      
		    puts "Low threshold higher than high threshold. Values have been swapped"
		}
		
		set thrFilter [ vtkImageThreshold [ pxvtable::vnewobj ] ]
		$thrFilter SetInput $lastoutput 

		if  { $smoothing == "1" } { 
				$thrFilter ThresholdByUpper $highthreshold  
		    } else {
				$thrFilter ThresholdBetween $lowthreshold $highthreshold
		    }
		    
		    $thrFilter SetOutValue 0.0
		    $thrFilter ReplaceInOff
		    $thrFilter Update 
		    $lastoutput ShallowCopy [ $thrFilter GetOutput ]
		    
		    $thrFilter Delete
	}
	
	set skinExtractor  [ vtkContourFilter [ pxvtable::vnewobj ] ]
	$skinExtractor SetInput $lastoutput 
	$skinExtractor SetUseScalarTree 0 
	$skinExtractor SetNumberOfContours 1 
	$skinExtractor SetValue 0 $extractLevel
	$skinExtractor ComputeScalarsOff
	$skinExtractor ComputeNormalsOff
	$skinExtractor Update
	
	set surface_out [$skinExtractor GetOutput ]
		
    # Store Results in output
    [ $OutputsArray(output_surface) GetObject ] DeepCopySurface $surface_out 

    # Clean up
     #  $filter Delete
       
       return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_extractsurface.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_extractsurface [pxvtable::vnewobj]]
    $alg MainFunction 
}

