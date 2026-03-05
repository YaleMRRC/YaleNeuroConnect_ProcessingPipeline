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

package provide  bis_roimean  1.0
package require bis_dualimagealgorithm 1.0
package require bis_displayroimean 1.0

itcl::class bis_roimean {

    inherit bis_dualimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "ROI Mean" }
    public method CheckInputObjects {}
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_roimean::Initialize { } {

    PrintDebug " bis_roimean::Initialize" 
	
    #set inputs { 
    #	{ third_image "Mask Image" pxitclimage "" 102}     
    #}
	
    set options {
	{ dotextfile "Generate output text file" "Generate Text File" boolean 1 { 0 1 } 20 }
	{ filename   "specify the filname for the output text file" "Text File Name" { filename writefile } "" { text { .txt } } 30 }
	{ filename2   "specify the filname for the output XYZ coordinate" "Text File Name" { filename writefile } "" { text { .txt } } -30 }
	{ addregion "Add extra roi region" "Add Region" double 0 { 0 100 } -20 }
	{ fullsizeoutput "Generate Full Size Output Image" "Full Size" boolean 0 { 0 1 } 31 }
    }

    set defaultsuffix { "_rm" }
    
    set scriptname bis_roimean 
    set completionstatus "Done"
    
    #
    #document
    #
    
    set description "Calculate the mean time course of each ROI defined by ROI mask."
    set description2 "This algorithm requires two inputs, one is a brain 4D image, the other is the ROI 3D image for this brain image. This algorithm returns a 4D image of ROI mean and can also output a text file. "
    set backwardcompatibility ""
    set authors "isabella.murphy@yale.edu, xilin.shen@yale.edu."
    
    $this InitializeDualImageAlgorithm

    $this RenameInput 0 "Functional Image"
    $this RenameInput 1 "ROI Image"
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_roimean::Execute {  } {

    set ok [ pxtclvtkpxcontrib::ConditionalLoadLibrary  vtkbisConnectivityTCL vtkbisROICorrelation 0  ]
    if { $ok == 0 } {
	set errormessage "Failed to load library vtkbisConnectivityTCL"
	return 0
    }

   
    PrintDebug "bis_roimean::Execute"
	
    set dotext       [ $OptionsArray(dotextfile) GetValue ]
    set textfilename [ $OptionsArray(filename)   GetValue ]
    set textfilename2 [ $OptionsArray(filename2)   GetValue ]
    set addregion    [ $OptionsArray(addregion)  GetValue ]
    set image_in [ $this GetInput ]

    set outimage [ $OutputsArray(output_image) GetObject ]
    set oname [ $outimage GetFileName ]
    if { $textfilename == "" } {
	set textfilename "${oname}_voi.txt" 
    }
    if { $textfilename2 == "" } {
	set textfilename2 "${oname}_xyz.txt" 
    }

    set calMean [ vtkbisROIMean [ pxvtable::vnewobj ]  ] 
    $calMean SetInput    [ $image_in GetObject ]	
    $calMean SetImageROI [ [ $this GetInputObject second_image ] GetObject ]

    $calMean SetDoText $dotext


    if { $dotext == "1" && [ string length $textfilename ] > 0 } {
	$calMean SetFileName $textfilename
	if { $textfilename2 != "" } {
	    $calMean SetFileName2 $textfilename2
	} else {
	    $calMean SetFileName2 "[ file rootname $textfilename]_coord.txt"
	}
    } else {
	$calMean SetDoText 0
    }
    $calMean SetAddRegion $addregion
    $this SetFilterCallbacks $calMean "Calculate ROI Mean"
    $calMean Update


    $outimage ShallowCopyImage [ $calMean GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    if { [ $OptionsArray(fullsizeoutput) GetValue ] > 0 } {
	set alg [ [ bis_displayroimean \#auto ] GetThisPointer ]
	$alg InitializeFromContainer $this
	$alg SetInput [ $this GetInput ]
	$alg SetSecondInput [ $this GetSecondInput ]
	$alg SetInputObject third_image $outimage
	$alg Execute
	$outimage ShallowCopy [ $alg GetOutput ]
	itcl::delete object $alg
    }

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $calMean Delete

    return 1
}

itcl::body bis_roimean::CheckInputObjects { } {


    set image_in    [ $this GetInput ]
    set d [ $image_in GetImageSize ]
    if { $d < 2 } {
	return 0
    }
	
	set image_in    [ $this GetSecondInput ]
    set d [ $image_in GetImageSize ]
    if { $d < 2 } {
	return 0
    }
	
	#set msk [ $OptionsArray(usemask) GetValue ]
	#if { $msk == "1" } {
	#	set image_in    [ $this GetThirdInput ]
    #    set d [ $image_in GetImageSize ]
    #    if { $d < 2 } {
	#    return 0
    #	}
	#}
	
    return 1

}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_ROIMean.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_roimean [pxvtable::vnewobj]]
    $alg MainFunction 
}





