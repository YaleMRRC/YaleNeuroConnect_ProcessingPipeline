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

package require bis_algorithm 1.0
package require bis_dualimagetransformationalgorithm 1.0
package provide bis_singlejacobian 1.0

#
# compute overlap
#


itcl::class bis_singlejacobian {

    inherit bis_dualimagetransformationalgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Compute Jacobian"}
    #
    #protected
    #

    protected variable outputs1
    protected variable outputs2
    protected variable defaultsuffix1
    protected variable defaultsuffix2
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_singlejacobian::Initialize { } {

    PrintDebug "bis_singlejacobian::Initialize" 

    set options {
	{ resolution "resolution" "resolution"  real    3.0 { 0.1 10.0 }  0 }
	{ threshold  "jacobian image threshold  " "threshold"  real    0.05 { 0.0 1.0 }  0 }
	{ mode       "switch output files" "mode"   { listofvalues radiobuttons }  jacobian {jacobian tensor strains  }  0 }
	{ offset     "image offset value " "offset"  real    1.0 { 0.0 1.0 }  -1 }
	{ scale      "image scale value " "scale"  real    100.0 { 0.0 10000.0 }  -2 }
    }

    set defaultsuffix  { "jacobian" }
    set defaultsuffix1 { "_raw" }
    set defaultsuffix2 { "_combined" "_nonlinear" }
    
    set scriptname bis_singlejacobian

    #
    #document
    #

    set category "Registration"
    set description "computes either the determinant of the jacobian or the full tensor for a transformation."
    set description2 ""
    set backwardcompatibility "Reimplemented from pxsinglejacobian.tcl"
    set authors "hirohito.okuda@yale.edu,xenophon.papademetris.yale.edu"

    $this InitializeDualImageTransformationAlgorithm

    $this RenameInput 1 "(Not used)" 101  
}

itcl::body bis_singlejacobian::Execute {  } {

    PrintDebug "bis_singlejacobian::Execute"

    set resolution   [ $OptionsArray(resolution) GetValue ]
    set threshold    [ $OptionsArray(threshold) GetValue ]
    set mode         [ $OptionsArray(mode) GetValue ]
    set offset       [ $OptionsArray(offset) GetValue ]
    set scale        [ $OptionsArray(scale) GetValue ]

    set refimage  [ $this GetInput ] 
    set transform [ $this GetTransformation ]
    set outimage  [ $this GetOutput ]

    set spa  [ lindex [[ $refimage GetObject ] GetSpacing ] 0 ]

    set reg    [ vtkpxRegistration [ pxvtable::vnewobj ] ]
    set newimg [ vtkImageData      [ pxvtable::vnewobj ] ]
 
    set imcast [ vtkImageCast [ pxvtable::vnewobj ]]
    $imcast SetInput  [ $refimage GetObject ]
    $imcast SetOutputScalarTypeToFloat
    $imcast Update

    
    set resl [ vtkImageResample [ pxvtable::vnewobj ] ]
    $resl SetAxisOutputSpacing 0 $resolution
    $resl SetAxisOutputSpacing 1 $resolution
    $resl SetAxisOutputSpacing 2 $resolution
    $resl InterpolateOff
    $resl SetDimensionality 3
    $resl SetInput [ $imcast GetOutput ]
    $resl Update
    $newimg ShallowCopy [ $resl GetOutput ]
    $resl Delete

    $outimage ShallowCopyImage $newimg

    switch -exact $mode { 
	"tensor"   { $reg ComputeJacobianImage       $newimg [ $outimage GetObject ] [ $transform GetObject ] 1 1.0 $threshold }
	"strains"  { $reg ComputePrincipalStrains    $newimg [ $outimage GetObject ] [ $transform GetObject ] $threshold }
	"jacobian" { $reg ComputeSimpleJacobianImage $newimg [ $outimage GetObject ] [ $transform GetObject ] $scale $offset $threshold }
    }

    
    [ [ [ $outimage GetImage ] GetPointData ] GetScalars ] Modified
    $outimage CopyImageHeader [ $refimage GetImageHeader ]

    $reg    Delete
    $newimg Delete
    $imcast Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  You may need not modify this method
# ----------------------------------------------------------------------------------------


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_singlejacobian.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 

if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_singlejacobian [pxvtable::vnewobj]]
    $alg MainFunction 
}

