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

package provide bis_spectbase 1.0

package require bis_dualimagealgorithm  1.0
package require bis_imagemathoperations 1.0
package require bis_smoothimage         1.0
package require bis_thresholdimage      1.0
package require bis_proportionalscale   1.0 
package require bis_castimage           1.0 

itcl::class bis_spectbase {

    inherit bis_dualimagealgorithm

    constructor { } { }

    public method InitializeBaseSpect { }

    protected method cast            { img type }
    protected method mathops         { img1 img2 op }
    protected method smooth          { image }   
    protected method propScale       { image }
    protected method createBrainMask { img1 img2 img3 } 
    protected method createTmap      { ict int std { mean 0 } }
    protected method delete          { args } 
    protected method loadImage       { fname }

    private variable imgPath        ""
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_spectbase::InitializeBaseSpect { } {

    PrintDebug "bis_basespce::InitializeBaseSpect" 

    set tmp $inputs
    set inputs {
	{ stdimage   "Standard Deviation Spect Image (Optional)"    pxitclimage  "" 300 }
	{ maskimage  "Mask for Analysis (Optional)"             pxitclimage  "" 500 }
    }
    for { set i 0 } { $i < [ llength $tmp ] } { incr i } {
	lappend inputs [ lindex $tmp $i ]
    }

    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ usemask   "Mask used to remove the skull on spect images" "Brain Mask" boolean 1    { 0 1 }      0 }
	{ smoothval "FWHM Gaussian smoothing kernel in mm"          "FWHM"       real    16.0 { 0.0 20.0 } 2 }  

    }

    set defaultsuffix { "_sm" }
    
    set scriptname bis_spectbase
    set completionstatus "Done"

    #
    #document
    #
    
    set description1 "A diff SPECT processing algorithm for epilepsy"
    set category "DiffSPECT"
    set backwardcompatibility "ISAS see http://spect.yale.edu"
    set authors "dustin.scheinost@yale.edu,xenophon.papademetris.yale.edu"

    $this InitializeDualImageAlgorithm

    $this RenameInput 0 "Interictal SPECT"
    $this RenameInput 1 "Ictal SPECT"

    set imgPath [ file join [ file join [ file dirname [ info script ] ] ".." ] images ]
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_spectbase::cast { img1 type } {

    set cast [ bis_castimage [ pxvtable::vnewobj ] ]
    $cast InitializeFromContainer $this

    $cast SetInput       $img1
    $cast SetOptionValue type $type
    $cast Execute
  
    set out [ [ pxitclimage \#auto ] GetThisPointer ]
    $out ShallowCopy  [ $cast GetOutput ] 
    itcl::delete object $cast 

    return $out
 }

itcl::body bis_spectbase::mathops { img1 img2 op } {

    set mathop [ bis_imagemathoperations [ pxvtable::vnewobj ] ]
    $mathop InitializeFromContainer $this

    $mathop SetInput       $img1
    $mathop SetSecondInput $img2
    $mathop SetOptionValue mathoperation $op
    $mathop Execute
  
    set out [ [ pxitclimage \#auto ] GetThisPointer ]
    $out ShallowCopy  [ $mathop GetOutput ] 
    itcl::delete object $mathop 

    return $out
 }

itcl::body bis_spectbase::smooth { image} {

    set smoothingSigma [ expr { [ $OptionsArray(smoothval) GetValue ] / sqrt( 8 * log(2) ) } ]
    
    set spa [ [ $image GetImage ] GetSpacing ]
    
    for { set i 0 } { $i <= 2 } { incr i } {
	set sigma($i) [ expr $smoothingSigma / [ lindex $spa $i ]]             
    }

    set sm  [ vtkImageGaussianSmooth [ pxvtable::vnewobj ]  ]
    $sm SetStandardDeviations $sigma(0) $sigma(1) $sigma(2)
    $sm SetRadiusFactors [ expr round(6*$sigma(0)) ] [ expr round(6*$sigma(1)) ] [ expr round(6*$sigma(2)) ]
    $sm SetInput [ $image GetImage ]
    $sm Update

    set out [ [ pxitclimage \#auto ] GetThisPointer ]
    $out ShallowCopyImage [ $sm GetOutput ] 
    $out CopyImageHeader  $image
    $sm Delete

    return $out
}

itcl::body bis_spectbase::propScale { image} {
 
    set scale [ bis_proportionalscale [ pxvtable::vnewobj ] ]
    $scale InitializeFromContainer $this
        
    $scale SetInput $image
    $scale SetOptionValue threshold 0.8
    $scale SetOptionValue mean 50
    $scale Execute
  
    set out [ [ pxitclimage \#auto ] GetThisPointer ]
    $out ShallowCopy  [ $scale GetOutput ] 
    itcl::delete object $scale

    return $out
}

itcl::body bis_spectbase::createBrainMask { img1 img2 img3 } {
    
    catch { itcl::delete object $thresholdimage }
    
    set thresholdimage [ bis_thresholdimage [ pxvtable::vnewobj ] ]
    $thresholdimage InitializeFromContainer $this
    
    $thresholdimage SetInput [ mathops $img1 [ mathops $img2 $img3 Multiply ] Multiply ]
    $thresholdimage SetOptionValue minth 0.0000001
    $thresholdimage SetOptionValue maxth 1000000000000000000000000
    $thresholdimage SetOptionValue binary On
    $thresholdimage Execute 
   
    set out [ [ pxitclimage \#auto ] GetThisPointer ]
    $out ShallowCopy  [ $thresholdimage GetOutput ] 
    itcl::delete object $thresholdimage

    return $out
}

itcl::body bis_spectbase::createTmap { ict int std { mean 0 } } {

    set sub [ mathops $ict $int Subtract ]

    if { $mean != 0 } {
	set sub [ mathops $sub $mean Subtract ]
    }

    set tmp [ mathops $sub $std Divide ]

    ::itcl::delete object $sub 

    return $tmp
}

itcl::body bis_spectbase::delete { args } { 
 
    foreach item $args {
	catch { itcl::delete object $item } 
    }
}

itcl::body bis_spectbase::loadImage { fname } { 
    
    set fileName [ file join $imgPath $fname ] 
    set img [ [ pxitclimage [ pxvtable::vnewobj ] ] GetThisPointer ]
    
    if { [ file exists $fileName ] } {
	$img Load $fileName
	return $img
    } 
    
    if { [ file exists $fname ] } {
	$img Load $fname
	return $img
    } 

    if { [ GetGUIMode ] != "commandline" } {
	tk_messageBox -type ok -message "Could not find $fileName. Please set load it now." -icon error
	if { [ $img Load "" ] } { 
	    return $img
	} else {
	    itcl::delete object $img; return 0
	}
    }
    
    itcl::delete object $img

    puts stdout "Could not find $fileName. Please now the full path for $fname now or Q to quit.\n" 
    gets stdin  newImage

    if { $newImage == "Q" || $newImage == "q" } {
	return 0
    } else {
	return [ loadImage $newImage ]
    }
}


