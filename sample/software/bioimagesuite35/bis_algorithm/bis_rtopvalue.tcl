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
package provide bis_rtopvalue 1.0


itcl::class bis_rtopvalue {

	inherit bis_imagetoimagealgorithm

	 constructor { } {
	 $this Initialize
	 }

	public method Initialize { }
	public method Execute { }
	public method GetGUIName    { } { return "R-value to 1-p value" }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_rtopvalue::Initialize { } {

	PrintDebug "bis_rtopvalue::Initialize" 
	
	#commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
   
	set options {
	    { subject     "Number of Subjects" "Number of Subjects"   int    0   { 0            100000000   }  0 }
	    { dof         "Degree of Freedom" "DOF"   int    0   { 0            100000000   }  0 }
	    { scaleFactor "Scale factor "     "Scale" float  1.0 { -100000000.0 100000000.0 }  0 }
	}
	
	set defaultsuffix { "_1-pvalue" }
	
	set completionstatus "Done"

	set scriptname bis_rtopvalue


	set description "Converts r value to 1-p value."
	set description2 "Take behavior correlation r value and number of subjects, degree of freedom as input, convert to 1-p value."
	set backwardcompatibility "N/A"
	set authors "isabella.murphy@yale.edu,xilin.shen@yale.edu"
	set category "Functional Imaging"

	$this InitializeImageToImageAlgorithm

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_rtopvalue::Execute {  } {

	PrintDebug "bis_rtopvalue::Execute"
	set con 0
	catch {set con [ vtkbisRtoPvalue New ]    }
	if { $con == 0 } {
	pxtclvtkpxcontrib::LoadLibraries { vtkpxImagingTCL }
	}
	catch { $con Delete }
	
	set subject     [ $OptionsArray(subject)      GetValue  ]
	set dof         [ $OptionsArray(dof)          GetValue  ]
	set scaleFactor [ $OptionsArray(scaleFactor)  GetValue  ]
	set image_in    [ $this GetInput ]
	
	if { $subject==0 || $dof ==0 } {
	    set errormessage "Number of Subjects or DOF is not set"
	    return 0
	}

	# GetOutput = pxitclimage
	# [  GetOutput  ] GetImage = vtkImageData  (GetImage is same as GetObject )
	# ShallowCopy take image from bis_algorithm; ShallowCopyImage take image from vtk class
	#set tmpimg [ pxitclimage \#auto ]
	
	set calp 0
	catch { set calp [ vtkbisRtoPvalue New  ] }
	if { $calp == 0 } {
	    return 0
	}

	set range [ [ [ [ $image_in GetObject ] GetPointData ] GetScalars ] GetRange ]
	if { [ lindex $range 0 ] < -1  || [ lindex $range 1 ] > 1 } {
	    set errormessage "Bad Input Image, Range is outside of -1 to 1 ($range)"
	    return 0
	}
	
	$calp SetInput    [ $image_in GetObject ]
	$calp SetNumSubject $subject
	$calp SetDOF $dof
	$calp SetScaleFactor $scaleFactor
	$this SetFilterCallbacks $calp "compute r to 1-p"
	$calp Update
	
	
	set outimage [ $OutputsArray(output_image) GetObject ]
	$outimage ShallowCopyImage [ $calp GetOutput ]
	$outimage CopyImageHeader [ $image_in GetImageHeader ]
	
	set comment [ format " [ $this GetCommandLine full ]" ]
	[ $outimage GetImageHeader ] AddComment "$comment $Log" 0

	
	$calp Delete
	
	return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_rtopvalue.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
	# this is essentially the main function

	

	set alg [bis_rtopvalue [pxvtable::vnewobj]]
	$alg MainFunction 
}

