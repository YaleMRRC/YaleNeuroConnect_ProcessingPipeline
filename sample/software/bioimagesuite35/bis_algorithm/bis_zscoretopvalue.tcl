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
package require vtkpxcontrib     1.2

package provide bis_zscoretopvalue 1.0


itcl::class bis_zscoretopvalue {

	inherit bis_imagetoimagealgorithm

	 constructor { } {
	 $this Initialize
	 }

	public method Initialize { }
	public method Execute { }
	public method GetGUIName    { } { return "Zmap to pvalue" }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_zscoretopvalue::Initialize { } {

	PrintDebug "bis_zscoretopvalue::Initialize" 
	
	#commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
   
	 set options {
	{ guicmt     "Description of the filter"  "Note"  comment "Zscore to p-value" "Compute zmap to p-value"  400 }
	}

	set defaultsuffix { "_ztopvalue" }
	
	set completionstatus "Done"

	set scriptname bis_zscoretopvalue

	set category "Functional Imaging"
	set description "Converts zmap to pvalue."
	set description2 "Take zmap as input and output it p-value."
	set backwardcompatibility "N/A"
	set authors "isabella.murphy@yale.edu"

	$this InitializeImageToImageAlgorithm

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_zscoretopvalue::Execute {  } {

	PrintDebug "bis_zscoretopvalue::Execute"
	
	set con 0
	catch {set con [ vtkbisZscoretoPvalue New ]    }
	if { $con == 0 } {
	pxtclvtkpxcontrib::LoadLibraries { vtkpxImagingTCL }
	}
	catch { $con Delete }
	
	set image_in    [ $InputsArray(input_image)   GetObject ]
	
	set calp 0
	catch { set calp [ vtkbisZscoretoPvalue New  ] }
	if { $calp == 0 } {
	return 0
	}
	
	$calp SetInput    [ $image_in GetObject ]
	$this SetFilterCallbacks $calp "compute zmap to pvalue"
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
#  This checks if executable is called (in this case bis_zscoretopvalue.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
	# this is essentially the main function

	

	set alg [bis_zscoretopvalue [pxvtable::vnewobj]]
	$alg MainFunction 
}

