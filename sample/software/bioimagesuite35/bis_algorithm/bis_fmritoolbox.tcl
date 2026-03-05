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


lappend auto_path [file dirname [ info script ]]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]

package provide bis_fmritoolbox  1.0
package require bis_dualimagealgorithm 1.0

itcl::class bis_fmritoolbox {

    inherit bis_dualimagealgorithm
    
    constructor { } { $this Initialize  }
    
    public method Initialize { }
    public method Execute { }
	public method GetGUIName    { } { return "fMRI Tool Box" }
    public method GetSecondOutput { }
    public method CheckInputObjects {}
    }

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_fmritoolbox::Initialize { } {
    
    PrintDebug " bis_fmritoolbox::Initialize" 
    
    set inputs { 
	{ third_image "ROI Map Image" pxitclimage "" 80 }     
    }
    
    set options {
	{ threshold "Threshold to be count as connected" "Threshold" { real triplescale 100 } 0.3 { 0.0 1.0 } 10 }
    }
    
    #this provide output GUI
    set outputs { 
	{ second_output "Network Measures" pxitclimage  ""  10 }   
    }
    
#    puts stdout "$inputs, $options, $outputs"
    
    set defaultsuffix { "_shortestPath" }
    set category "Functional Imaging"    
    set scriptname bis_fmritoolbox 
    set completionstatus "testing"
    
    #
    #document
    #
    set description "fmri Tool Box. Calculate complex network measures."
    set description2 "This algorithm requires 3 inputs, which are ROI correlation result, functional image and ROI image."
    set backwardcompatibility ""
    set authors "isabella.murphy@yale.edu, xilin.shen@yale.edu."
    
    InitializeDualImageAlgorithm
    RenameInput 0 "ROI Correlation Image"
    RenameInput 1 "Functional Image"
    
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_fmritoolbox::Execute {  } {

    set ok [ pxtclvtkpxcontrib::ConditionalLoadLibrary  vtkbisConnectivityTCL vtkbisROICorrelation 0  ]
    if { $ok == 0 } {
	set errormessage "Failed to load library vtkbisConnectivityTCL"
	return 0
    }
    
    PrintDebug "bis_fmritoolbox::Execute"
    
    set threshold    [ $OptionsArray(threshold)  GetValue ]
    set image_in [ $this GetInput ]
    
    set alg 0
    catch { set alg  [ vtkbisfmriToolBox New  ] }
    if { $alg ==0 } {
	return 0
    }
	
    set f(0) [ $InputsArray(input_image) GetFileName ]
    set l [ ::bis_common::SplitFileNameGZ $f(0) ]
    set f(0) [ file tail [ lindex $l 0 ] ]

    set t [ format "_%.03f" ${threshold} ]

    set textfilename [ file join [ file dirname $f(0) ] "$f(0)${t}_adjMatrixForAlarkViewer.txt" ]
    set textfilename2 [ file join [ file dirname $f(0) ] "$f(0)${t}_networkMeasures.txt" ]
    set textfilename3 [ file join [ file dirname $f(0) ] "$f(0)${t}_roiCorrelationForAlarkViewer.txt" ]
    
    $alg SetInput           [ $image_in GetObject ]	
    $alg SetFunctionalImage [ [ $this GetInputObject second_image ] GetObject ]
    $alg SetroiMap          [ [ $this GetInputObject third_image ] GetObject ]
    $alg SetThreshold       $threshold
    $alg SetFilename        $textfilename
    $alg SetFilename2       $textfilename2
    $alg SetFilename3       $textfilename3
    $this SetFilterCallbacks $alg "Calculate Network Measures"



    $alg Update


    #set brainnetwork [ $alg ComputeBrainNetwork [ [ $this GetSecondInput ] GetObject ] $threshold 1 ]
    #set degrees [ $alg ComputeDegreesUnd $brainnetwork ]
    #$alg ComputeNetworkMeasures [ [ $this GetSecondInput ] GetObject ] [ $image_in GetObject ] [ [ $this GetInputObject third_image ] GetObject ] $textfilename
    #$alg ComputeShortestPath $brainnetwork [ $image_in GetObject ] [ [ $this GetInputObject third_image ] GetObject ] $textfilename 1 $degrees
    #set BC [ $alg ComputeBetweenessCentrality $brainnetwork ]
    #set localE [ $alg ComputeLocalEfficiency $brainnetwork $degrees ]
    #set otherdata [$alg ComputeNetworkMeasures $brainnetwork [ $image_in GetObject ] [ [ $this GetInputObject third_image ] GetObject ] $degrees]
    
    #set oimage1 [ $alg GenerateOutputForAlarkViewer $localE $BC $otherdata $textfilename ]
    #$alg GenerateAdjMatrixOutputForAlarkViewer $brainnetwork $otherdata $textfilename2
	
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $alg GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
	
    set outimage2 [ $OutputsArray(second_output) GetObject ]
    $outimage2 ShallowCopyImage [ $alg GetOutData2 ]
    $outimage2 CopyImageHeader [ $image_in GetImageHeader ]
    
    set text "index x y z label ind.CharPathLength ind.GlobalEffi. ClosenessCentrality #ofTriangles Degrees LocalEffi BetweenessCentrality"
    puts stdout "\nNetwork Measures Output: $text\n"
    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0
    [ $outimage2 GetImageHeader ] AddComment "$comment $Log" 0
    [ $outimage2 GetImageHeader ] AddComment "[ $this GetGUIName ] Log: Column Name: $text" 0

    set fname3 [ $outimage2 cget -filename ]
    if { $fname3 == "" } {
	set f(0) [ $InputsArray(input_image) GetFileName ]
	set l [ ::bis_common::SplitFileNameGZ $f(0) ]
	set f(0) [ file tail [ lindex $l 0 ] ]
	set newname [ file join [ file dirname $f(0) ]  "$f(0)_networkMeasures.nii.gz" ]
	$outimage2 configure -filename $newname
    }
	
    catch {  $alg Delete }
    
    return 1
}
itcl::body bis_fmritoolbox::GetSecondOutput {  } {
	return [ $this GetOutputObject second_output ]
}
itcl::body bis_fmritoolbox::CheckInputObjects { } {


	set image_in    [ $this GetInput ]
	set d [ $image_in GetImageSize ]
	if { $d < 1 } {
	return 0
	}
	
	set image_in    [ $this GetSecondInput ]
	set d [ $image_in GetImageSize ]
	if { $d < 1 } {
	return 0
	}
	
	
	set image_in    [ $this GetInputObject third_image ]
	set d [ $image_in GetImageSize ]
	if { $d < 1 } {
	return 0
	}
	
	return 1

}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_fmritoolbox.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
	# this is essentially the main function

	set alg [bis_fmritoolbox [pxvtable::vnewobj]]
	$alg MainFunction 
}






