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

package require bis_imagetoimagealgorithm 1.0
package require bis_castimage 1.0

package provide bis_qianvesselness 1.0


itcl::class bis_qianvesselness {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Qian Vesselness" }
    public method UpdateOutputFilenames { } 
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_qianvesselness::Initialize { } {

    PrintDebug "bis_qianvesselness::Initialize" 

    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ beta "Beta factor" "Beta"  float  800.0 { 1.0 10000.0 }  0 }
	{ mode "Sphere Subdivision (Original=theta,phi), New = barycentric, NewWedges=barycentric wegdes" "Mode"  listofvalues New { Orig New NewWedges }  1 }
	{ subdivide "Subvidide Sphere (New Sphere), if on use adds more" "Subdivide"  integer  1 { 0 3 }  3 }
	{ radius  "Sphere Radius" "Radius" real 8 { 1 100 } 4 }
	{ forcecpu "Force Execution on CPU" "ForceCPU"  boolean  0 { 0 1 }  -20 }
 	{ debug "Debug Mode -- prints more info as process is running"               "Debug Mode"  boolean   0 { 0 1 }   -5 }

    }

    set outputs { 
	{ outdeviation "Deviation"  pxitclimage  ""  100 }   
	{ outmean      "Mean"  pxitclimage  ""  101 }   
	{ outtight     "Tightness"  pxitclimage  ""  104 }   
	{ outbright    "Brightness" pxitclimage  ""  103 }   
	{ wedges       "Wedges" pxitclimage  ""  102 }   
    }


    set defaultsuffix { "_vesselness" "_deviation" "_mean" "_tight" "_bright" "_wedges" }
    
    set scriptname bis_qianvesselness
    set completionstatus "Done"
    set category "Vascular Imaging"

    set description " computes the non-parameteric vesselness measure from Qian et al, MedIA 2009."
    set description2 ""
    set authors "Levent Alpoge: levent.alpoge@gmail.com, xenophon.papademetris@yale.edu"
    set backwardcompatibility "N/A."

    $this InitializeImageToImageAlgorithm

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_qianvesselness::Execute {  } {
#    $this UpdateOutputFilenames 

    PrintDebug "bis_qianvesselness::Execute"


    set beta   [ $OptionsArray(beta) GetValue ]
    set usenewsphere 0
    set usenewwedges 0
    if {   [  $OptionsArray(mode) GetValue ] != "Orig" } {
	set usenewsphere 1
    }
    if {  [ $OptionsArray(mode) GetValue ] == "NewWedges" } {
	set usenewwedges 1
    }
    
    set radius    [ $OptionsArray(radius) GetValue ]
    set forcecpu  [ expr  [ $OptionsArray(forcecpu) GetValue ] > 0 ]
    set subdiv  [ expr  [ $OptionsArray(subdivide) GetValue ] > 0 ]
    set image_in [ $InputsArray(input_image) GetObject ]

    # ------------------------------------------------------------------------------------
    # Beginning of Levent's code

    set timer [clock seconds]
    
    set range [ [ [ [ $image_in GetImage ] GetPointData ] GetScalars ] GetRange ]
    set K [expr 1.0/([lindex $range 1]-[lindex $range 0])]

    # -------------------------------------------------------------------

    set conv [ vtkxqImageFourierConvolution [ pxvtable::vnewobj ] ]

    set filtertimer [clock seconds]
    if { $usenewsphere == 0 } {
	set filterbank [ $conv qVesselFilter 30.0 [ expr int($radius) ] 0.0 0.0 ]
    } else {
	# Replace old style filterbank with new code below
	set sph [ vtkjoColoredSphereSource  New ]
	$sph SetRadius [ expr int($radius) ]
	$sph SetColorValue 1
	$sph SetSubdivisionLevels $subdiv
	$sph SetUseNewWedges $usenewwedges
	$sph Update
	set filterbank [ vtkImageData New ]
	$filterbank ShallowCopy [ $sph GetOutput ]
	$sph Delete
    }

    puts stdout "Filters done in [expr ([clock seconds] - $filtertimer)/1.0] seconds."
    set deb [ $OptionsArray(debug) GetValue ] 

    set convtimer [clock seconds]

    set castspheres [vtkImageCast New]
    $castspheres SetOutputScalarTypeToDouble
    $castspheres SetInput $filterbank
    $castspheres Update

    $conv SetInput  [  $image_in GetImage ]
    $conv SetFilterBank [ $castspheres GetOutput]
    $conv SetMode 2
    $conv SetDoublePrecision 1
    if { $deb > 0 } {
	$conv DebugOn 
    }

    $conv SetForceCPU $forcecpu
    $this SetFilterCallbacks $conv "Computing Filters [ $filterbank GetNumberOfScalarComponents ]"

    set wedges [ $OutputsArray(wedges) GetObject ]
    $wedges CopyImageHeader [ $image_in GetImageHeader ]
    $wedges ShallowCopyImage [ $conv GetFilterBank ]

    set start [ clock clicks -milliseconds ]
    $conv Update
    puts "Setup in conv update takes [ expr [ clock clicks -milliseconds ] - $start ]"    
#puts stdout "Convolutions done in [expr ([clock seconds] - $convtimer)/1.0] seconds."

    puts stdout "Spacing = [  [$conv GetOutput] GetSpacing ]"

    # Store outputs of convolution first
    set outimage [ $OutputsArray(outdeviation) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
    $outimage ShallowCopyImage [ $conv GetOutput ]

    set outimage [ $OutputsArray(outmean) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
    $outimage ShallowCopyImage [ $conv GetSecondOutput ]
    

    puts stdout "\nStarting v(x) calculations."

    set ttimer [clock seconds]

    set tightness [ vtkxqImageODFVesselnessFilter [ pxvtable::vnewobj ] ]
    $tightness SetInput [ $conv GetOutput ]
    $tightness SetBeta [ expr $beta/1.0]
    $tightness SetDebug 0
    $tightness Update

    set tightnesstodouble [vtkImageCast [pxvtable::vnewobj]]
    $tightnesstodouble SetInput [$tightness GetOutput]
    $tightnesstodouble SetOutputScalarTypeToDouble
    $tightnesstodouble Update

    set outimage [ $OutputsArray(outtight) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
    $outimage ShallowCopyImage [ $tightnesstodouble GetOutput ]

    puts stdout "v(x) saved."
    puts stdout "v(x) done in [expr ([clock seconds] - $ttimer)/1.0] seconds."
    puts stdout "\nStarting b(x) calculations."

    set btimer [clock seconds]

    set castimage [vtkImageCast [pxvtable::vnewobj]]
    $castimage SetInput [ $image_in GetImage ]
    $castimage SetOutputScalarTypeToDouble
    $castimage Update
    
    set normalizedimage [vtkImageMathematics [pxvtable::vnewobj]]
    $normalizedimage SetInput [$castimage GetOutput]
    $normalizedimage SetOperationToMultiplyByK
    $normalizedimage SetConstantK $K
    $normalizedimage Update

    set brightness [vtkImageGaussianSmooth [pxvtable::vnewobj]]
    $brightness SetInput [$normalizedimage GetOutput]
    $brightness Update
    #note: $brightness GetOutput is now an image consisting of our newly-defined b(x).

    puts stdout "Saving b(x)..."

    set outimage [ $OutputsArray(outbright) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
    $outimage ShallowCopyImage [ $brightness GetOutput ]

    puts stdout "b(x) saved."
    puts stdout "b(x) done in [expr ([clock seconds] - $btimer)/1.0] seconds."

    puts stdout "\nStarting PPV(x) calculations..."

    set ppvtimer [clock seconds]

    set ppv [vtkImageMathematics [ pxvtable::vnewobj ]]
    $ppv SetInput1 [$tightnesstodouble GetOutput]
    $ppv SetInput2 [$brightness GetOutput] 
    $ppv SetOperationToMultiply
    $ppv Update
    #note: $ppv GetOutput is now an image consisting of PPV(x)=v(x)*b(x), as defined in the paper.
    
    puts stdout "PPV(x) done in [expr ([clock seconds] - $ppvtimer)/1.0] seconds."

    puts stdout "Everything done in [expr ([clock seconds] - $timer)/1.0] seconds."

    set outimage [ $this GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
    $outimage ShallowCopyImage [ $ppv GetOutput ]
    [ $outimage GetImageHeader ] AddComment "[ $this GetCommandLine full ]"

    $tightness Delete;    $tightnesstodouble Delete;
    $castimage Delete;    $normalizedimage Delete;    $brightness Delete
    $ppv Delete;          $castspheres Delete;        $conv Delete

    return 1
}

# -----------------------------------------------------------------------------------------

itcl::body bis_qianvesselness::UpdateOutputFilenames { } {

    set fn [ $InputsArray(input_image) GetFileName ]
    set outlist [ $this CreateDefaultOutputFileList $fn ]

    set l [ ::bis_common::SplitFileNameGZ $fn ]
    set ext [ lindex $l 1 ]
    set m [ lindex $outlist 0 ]

    set beta   [ $OptionsArray(beta) GetValue ]
    set mode   [ $OptionsArray(mode) GetValue ]

    set forcecpu  [ expr  [ $OptionsArray(forcecpu) GetValue ] > 0 ]
    set radius    [ $OptionsArray(radius) GetValue ]
    set subdivide    [ $OptionsArray(subdivide) GetValue ]

    set extrastring ""
    set extrastring [ format "_b%.1f_%s_fc%d_r%.1f" $beta $mode $forcecpu $radius ]

    set force 0;    if { $guimode == "managed" } {	set force 1    }    

    set namelist { output_image outdeviation  outmean  outtight   outbright    wedges    }
    for { set i 0 } { $i < [ llength $namelist ] } { incr i } {
	set m [ lindex $outlist $i ]
	set n [ lindex $namelist $i ]
	$OutputsArray($n) SetFileName "${m}${extrastring}${ext}" $force
    }
    

    return 1

}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_qianvesselness.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_qianvesselness [pxvtable::vnewobj]]
    $alg MainFunction 
}

