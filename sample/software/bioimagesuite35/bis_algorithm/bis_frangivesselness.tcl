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

package provide bis_frangivesselness 1.0
package require bis_imagetoimagealgorithm 1.0
package require vtkmpjcontrib

itcl::class bis_frangivesselness {

    inherit bis_imagetoimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Frangi Vesselness" }

    protected method linspace { x1 x2 n }
    protected method logspace { x1 x2 n }
    protected method ResampleImage { img spacing }
    protected method ComputeResults { input numscales gamma minscale maxscale logmode smoothsigma scalevesselness usegpu }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_frangivesselness::Initialize { } {

    PrintDebug "bis_frangivesselness::Initialize" 
    
    set outputs {
	{ outhessian "Hessian"     pxitclimage  "" 101 }
	{ outscale   "Scale"       pxitclimage  "" 102 }
    }
   
     set options {
 	{ frac            " max intensity in the middle of the vessel (0..1) where 1= max intensity of the image" "Frac Intensity"  real    0.7 { 0.0 1.0 }  0 }
 	{ numscales       "number of scales "                   "Number of Scales"       integer       1 { 1 20 }      1 }
 	{ minscale        "minimum scale in voxels"        "Minimum Scale"        real    1.0 { 0.1 25.0 }  2 }
 	{ maxscale        "maximum scale in voxels"        "Maximum Scale"        real    5.0 { 1.0 25.0 }  3 }
 	{ logarithmic     "use logarithmic scale spacing"  "Logarithmic"    boolean  1 { 0 1}        4 }
 	{ smoothing       "post-process gaussian smoothing" "Sigma"        real    0.0 { 0.0 4.0 }  -10  }
 	{ scalevesselness "scale vesselness"               "Scale Vesselness"  boolean   1 { 0 1 }   -11 }
 	{ forcecpu "Force CPU even if GPU convolution if available"               "Force CPU"  boolean   0 { 0 1 }   -12 }
 	{ debug "Debug Mode -- prints more info as process is running"               "Debug Mode"  boolean   0 { 0 1 }   -5 }
     }


    set defaultsuffix  "_vess" 
    
    set scriptname bis_frangivesselness

    #
    #document
    #

    set category "Vascular Imaging"
    set description " computes the multiscale hessian tensor and associated vesslness and scale images from Frangi 1998."
    set description2 ""
    set backwardcompatibility "Reimplemented from pxmat_vesselutility.tcl."
    set authors "hirohito.okuda@yale.edu,xenophon.papademetris.yale.edu"

    $this InitializeImageToImageAlgorithm
}

#------------------------------------------------------------------------------------------
# Create list of (n-1) equaly divided partial intervals of [x1,x2]
#------------------------------------------------------------------------------------------

itcl::body bis_frangivesselness::linspace { x1 x2 n } {

    set linlist ""
    
    if { $n < 2 } { return $x1 }
    
    set delta [expr ($x2 - $x1) / ($n - 1) ]
    for { set i 0 } { $i <= [expr $n - 2] } { incr i } {
	lappend linlist [expr $x1 + $i*$delta]
    }
    lappend linlist $x2

    return $linlist    
}

################################################################
# Create list of (n-1) log-scale-equaly divided intervals of [x1,x2]
################################################################

itcl::body bis_frangivesselness::logspace { x1 x2 n } {

    set loglist ""

    if { $n < 2 } { return $x1 }
    
    set linlist [ linspace [expr log10($x1)] [expr log10($x2)] $n ]
    
    foreach item $linlist {
	lappend loglist [expr pow(10,$item)]
    }
    
    return $loglist
}

###############################################################
#
###############################################################

itcl::body bis_frangivesselness::ResampleImage { img spacing } {

    puts stdout "Resampling at $spacing x $spacing x $spacing "

    set resamp [ vtkImageResample [ pxvtable::vnewobj ]]
    $resamp SetInput $img
    $resamp SetAxisOutputSpacing 0 $spacing
    $resamp SetAxisOutputSpacing 1 $spacing
    $resamp SetAxisOutputSpacing 2 $spacing
    $resamp Update
    set out [ vtkImageData [ pxvtable::vnewobj ]]
    $out ShallowCopy [ $resamp GetOutput ]
    $resamp Delete

    puts stdout " Dimensions Input [ $img GetDimensions ] --> Output [ $out GetDimensions ] "
    return $out
}

###############################################################
# Compute results
###############################################################

itcl::body bis_frangivesselness::ComputeResults { input numscales gamma minscale maxscale logmode smoothsigma scalevesselness forcecpu } {

    set hessian [ vtkImageData [ pxvtable::vnewobj ]] 
    set vessel [ vtkImageData [ pxvtable::vnewobj ]] 
    set sigma [  vtkImageData [ pxvtable::vnewobj ]] 

    set deb [ $OptionsArray(debug) GetValue ] 

    set scales 0

    ## generate scales
    if { $logmode == 0 } {
	set scales [ linspace $minscale $maxscale $numscales ]
    } else {
	set scales [ logspace $minscale $maxscale $numscales ]
    }
    
    set doresample 0
    set newinput   0
    set newhess    0

    set spa [ lsort [ $input GetSpacing ] ]
    
    if { ([ lindex $spa 2 ] - [ lindex $spa 0 ]) > [ expr 0.05* [lindex $spa 1 ] ] } {
	set doresample 1
	set spx [ expr ( [ lindex $spa 0 ] + [ lindex $spa 1 ] + [ lindex $spa 2 ])/3.0 ]
	
	set newinput [ ResampleImage $input $spx ]
    } else {
	set newinput $input
    }

    set truegamma [ expr [ lindex [ [ [ $newinput GetPointData ] GetScalars ] GetRange ] 1 ] * $gamma ]

    set firsttime 1

    #    puts stdout "Computing scales = \{ $scales \}, gamma=$truegamma"
       
    ## run the filter for all scales
    set n [ llength $scales ]
    for { set sc 0 } { $sc < $n } { incr sc } {
	set sig [ lindex $scales $sc ]

	#puts stdout "\n-------------------------------------\n  Computing at scale $sig ($scales)\n-------------------------------------\n"

	set hess [ vtkxqImageHessian [ pxvtable::vnewobj ] ]
	$hess SetInput $newinput
	$this SetFilterCallbacks $hess "Computing Hessian at $sig"
	set sgmlabel [format "%7.4f" $sig]
	$hess SetSigma $sig
	if { $deb > 0 } {
	    $hess DebugOn 
	}
	if { $forcecpu > 0 } {
	    $hess SetForceCPU 1
	} else {
	    $hess SetForceCPU 0
	}
	$hess Update

	set img [ vtkImageData New ]
	$img ShallowCopy [ $hess GetOutput ]
	$hess Delete

	## vesselness filter
	set vess [ vtkmpjImageVesselEnhancement [ pxvtable::vnewobj ] ]
	$vess SetInput $img
	$vess SetAlpha 0.5
	$vess SetBeta  0.5
	$vess SetGamma $truegamma
	$vess SetStructureType 0
	$this SetFilterCallbacks $vess "Computing Vesselness at $sig"
	$vess SetBrightStructure 1

	if { $scalevesselness == 1 } {
	    $vess SetVesselnessScaleFactor 1000.0
	} else {
	    $vess SetVesselnessScaleFactor 1.0
	}
	
	## compute vesselness measure
	$vess Update
	#	puts -nonewline stdout "Vesselness Done \t"
    
	## store maximum
	if { $firsttime ==1 } {
	    
	    ## store hessian
	    $hessian ShallowCopy $img

	    ## store vesselness
	    $vessel ShallowCopy [ $vess GetOutput ]
	    
	    ## store sigma
	    $sigma CopyStructure  $newinput
	    $sigma SetScalarTypeToFloat 
	     $sigma AllocateScalars
	    [ [ $sigma GetPointData ] GetScalars ] FillComponent 0 $sig
	    set firsttime 0
	} else {
	    $vess UpdateHessianResponse $hessian  $vessel $sigma $img [ $vess GetOutput ] $sig
	    #puts -nonewline stdout "\t Max Done "
	}

	$img Delete
	$vess Delete
	#	puts stdout "\t Cleanup Done"

    }

    puts stdout "\n-------------------------------------\n  Generating Output\n-------------------------------------\n"

    if { $smoothsigma > 0.0 } { 
	
	set s1  [ vtkImageGaussianSmooth [ pxvtable::vnewobj ]  ]
	$s1 SetStandardDeviations $smoothsigma $smoothsigma $smoothsigma
	$s1 SetInput $vessel 
	$s1 Update
	$vessel ShallowCopy [ $s1 GetOutput ]
	$s1 Delete

    	set s2  [ vtkImageGaussianSmooth [ pxvtable::vnewobj ]  ]
	$s2 SetStandardDeviations $smoothsigma $smoothsigma $smoothsigma
	$s2 SetInput $sigma 
	$s2 Update
	$sigma ShallowCopy [ $s2 GetOutput ]
	$s2 Delete
    }

    if { $doresample == 1 } {
	#	puts stdout "Scaling scales by $spx "

	set sc [ vtkImageShiftScale [ pxvtable::vnewobj ]]
	$sc SetInput  $sigma 
	$sc SetShift 0.0
	$sc SetScale $spx
	$sc Update
	$sigma ShallowCopy [ $sc GetOutput ]
	$sc Delete

	catch { $newinput Delete } 
    }

    set outlist [ list $vessel $hessian $sigma ]
    return $outlist
}


# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_frangivesselness::Execute {  } {

    PrintDebug "bis_frangivesselness::Execute"

    set image_in            [ $this GetInput ] 
    set intensity          [ $OptionsArray(frac) GetValue  ]
    set minscale           [ $OptionsArray(minscale) GetValue  ]
    set maxscale           [ $OptionsArray(maxscale) GetValue  ]
    set numscales          [ $OptionsArray(numscales) GetValue ]
    set logarithmic        [ $OptionsArray(logarithmic)      GetValue ]
    set smoothing          [ $OptionsArray(smoothing)      GetValue ]
    set scalevesselness    [ $OptionsArray(scalevesselness)      GetValue ]
    set forcecpu           [ $OptionsArray(forcecpu)      GetValue ]


    set cast [ vtkImageCast [ pxvtable::vnewobj ]]
    $cast SetInput [$image_in GetObject]
    $cast SetOutputScalarTypeToFloat
    $cast Update

    set resultslist [ ComputeResults [ $cast GetOutput ] $numscales $intensity $minscale $maxscale $logarithmic $smoothing $scalevesselness $forcecpu ]


    set outimagelist [ list   [ $this GetOutput ] [ $this GetOutputObject outhessian ] [ $this GetOutputObject outscale ] ]
    set max [ llength $resultslist ]
    for { set i 0 } { $i < $max } { incr i } {
	set outimage [ lindex $outimagelist $i ]
	$outimage ShallowCopyImage [ lindex $resultslist $i ]
	[ lindex $resultslist $i ] Delete
	$outimage CopyImageHeader [ $image_in GetImageHeader ]
	[ $outimage GetImageHeader ] AddComment "[ $this GetCommandLine full  ]" 0
    }

    $cast Delete

    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_frangivesselness.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_frangivesselness [pxvtable::vnewobj]]
    $alg MainFunction 
}





