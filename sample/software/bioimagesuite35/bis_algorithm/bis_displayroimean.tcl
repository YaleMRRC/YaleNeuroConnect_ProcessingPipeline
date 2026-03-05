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

package provide  bis_displayroimean  1.0
package require bis_dualimagealgorithm 1.0


itcl::class bis_displayroimean {

	inherit bis_dualimagealgorithm

	 constructor { } {	 $this Initialize  }

	public method Initialize { }
	public method Execute { }
	public method GetGUIName    { } { return "Display ROI Mean" }
	public method CheckInputObjects {}
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_displayroimean::Initialize { } {

	PrintDebug " bis_displayroimean::Initialize" 
	
	set inputs { 
		{ third_image "ROI Mean" pxitclimage "" 80 }     
	}
	
	set options {
		{ guicmt "Display ROI Mean"  "Note"  comment "Takes in 3 images as input" "The output will be the same size as the functional image"  400 }
	}

	set defaultsuffix { "_drm" }
	
	set scriptname bis_displayroimean 
	set completionstatus "Debugging"
	
	#
	#document
	#
	
	set description "Display ROI Mean as an image"
	set description2 "This algorithm requires 3 inputs, one is a brain 4D image, the other is the ROI 3D image for this brain image, the third is the roi mean 4D image. This algorithm returns a 4D image of ROI mean looks like original brain. "
	set backwardcompatibility ""
	set authors "isabella.murphy@yale.edu"
	
	$this InitializeDualImageAlgorithm

	$this RenameInput 0 "Functional Image"
	$this RenameInput 1 "VOI Image"
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_displayroimean::Execute {  } {

	PrintDebug "bis_displayroimean::Execute"
	set ok [ pxtclvtkpxcontrib::ConditionalLoadLibrary  vtkbisConnectivityTCL vtkbisROICorrelation 0  ]
	if { $ok == 0 } {
	set errormessage "Failed to load library vtkbisConnectivityTCL"
	return 0
	}

   
	PrintDebug "bis_displayroimean::Execute"
	
	set image_in [ $this GetInput ]

	set calMean [ vtkbisDisplayROIMean [ pxvtable::vnewobj ]  ] 
	$calMean SetInput    [ $image_in GetObject ]	
	$calMean SetImageROI [ [ $this GetInputObject second_image ] GetObject ]
	$calMean SetAverageROI [ [ $this GetInputObject third_image ] GetObject ]
	$this SetFilterCallbacks $calMean "Display ROI Mean"
	$calMean Update

	set outimage [ $OutputsArray(output_image) GetObject ]
	$outimage ShallowCopyImage [ $calMean GetOutput ]
	$outimage CopyImageHeader [ $image_in GetImageHeader ]

	set comment [ format " [ $this GetCommandLine full ]" ]
	[ $outimage GetImageHeader ] AddComment "$comment $Log" 0

	$calMean Delete

	return 1
}

itcl::body bis_displayroimean::CheckInputObjects { } {


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
#  This checks if executable is called (in this case bis_displayroimean.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
	# this is essentially the main function

	set alg [bis_displayroimean [pxvtable::vnewobj]]
	$alg MainFunction 
}





