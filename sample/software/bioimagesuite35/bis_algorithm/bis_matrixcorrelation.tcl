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

package provide bis_matrixcorrelation 1.0
package require bis_imagetoimagealgorithm 1.0


itcl::class bis_matrixcorrelation {

    inherit bis_imagetoimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Matrix Correlation" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_matrixcorrelation::Initialize { } {

    PrintDebug "bis_matrixcorrelation::Initialize" 
    
    set options {
	{ guicmt     "Description of the filter"  "Note"  comment "Matrix Correlation. Take ROI Mean as input." "Calculate the correlation to itself. Output dimension is voxel*voxel*1*1."  400 }
    	{ dotextfile "Generate output text file" "Generate Text File" boolean 0 { 0 1 } 20 }
    	{ filename   "specify the filname for the output text file" "Text File Name" { filename writefile } "bismatrix_result.txt" { text { .txt } } 30 }
	{ filename2  "specify the filname for the output text file for Viewer" "Text File Name" { filename writefile } "outputForConnectivityViewer.txt" { text { .txt } } -30 }
	{ raw   "Raw Correlation"  "Compute Raw Correlations"  boolean   0  { 0 1  }  -10  }
	
	}
    
    set defaultsuffix { "_mc" }
    
    set scriptname bis_matrixcorrelation
    set completionstatus "Done"

    #
    #document
    #
    
    set description "Calculate correlation among time series."
    set description2 "Calculate correlation between pairs of voxels. Usually input image is a ROI mean image. Can use ROI Mean algorithm to generate such image."
    set backwardcompatibility ""
    set authors "isabella.murphy@yale.edu, xilin.shen@yale.edu"
    
    set category "Functional Imaging"

    $this InitializeImageToImageAlgorithm
	
    $this RenameInput 0 "ROI Mean"
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_matrixcorrelation::Execute {  } {
    
    set ok [ pxtclvtkpxcontrib::ConditionalLoadLibrary  vtkbisConnectivityTCL vtkbisROICorrelation 0  ]
    if { $ok == 0 } {
	set errormessage "Failed to load library vtkbisConnectivityTCL"
	return 0
    }
	
    set dotext       [ $OptionsArray(dotextfile) GetValue ]
    set textfilename [ $OptionsArray(filename)   GetValue ]
	set textfilename2 [ $OptionsArray(filename2)   GetValue ]
    set doraw        [ $OptionsArray(raw)   GetValue ]
    
    if { $textfilename != "" } {
	set extrafilenames $textfilename
    }
	if { $textfilename2 != "" } {
	set extrafilenames2 $textfilename2
	}
	set name [ file normalize  $extrafilenames   ]
	set name2 [ file normalize $extrafilenames2 ]
    set image_in    [ $this GetInput ]


    set crr  [ vtkbisTimeSeriesCorrelation [ pxvtable::vnewobj ] ]


    $crr SetInput [ $image_in GetObject ]
	$crr SetDoText $dotext
	$crr SetOutputRaw  [ expr $doraw > 0 ]
	if { $dotext == "1" } {
		$crr SetFileName $name
		$crr SetFileName2 $name2
	}
    $this SetFilterCallbacks $crr "Time Series Correlation"
    $crr Update

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $crr GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $crr Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_temporalsmoothimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_matrixcorrelation [pxvtable::vnewobj]]
    $alg MainFunction 
}





