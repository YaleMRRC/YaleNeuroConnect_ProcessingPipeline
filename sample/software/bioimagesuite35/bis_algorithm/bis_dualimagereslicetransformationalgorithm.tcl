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

package require bis_dualimagetransformationalgorithm 1.0
package require bis_resliceimage 1.0
package provide bis_dualimagereslicetransformationalgorithm 1.0

#
# blend image
#

itcl::class bis_dualimagereslicetransformationalgorithm {

    inherit bis_dualimagetransformationalgorithm

     constructor { } {
	 $this SetUseReslicedImageAsInput 1
     }

    public method ResliceImageIfNeeded { }
    public method DeleteResliceAlgorithmIfNeeded { lst }

    public method SetResliceAlgorithm { alg } { set reslice_algorithm $alg    }
    protected variable reslice_algorithm 0

}

# -----------------------------------------------------------------------------------------
# A messy routine that uses a pre-specified bis_resliceimage if available ....
# If transformation is identity skips this altogether
# ----------------------------------------------------------------------------------------
itcl::body bis_dualimagereslicetransformationalgorithm::ResliceImageIfNeeded { } {

    set delete_reslice_alg 0

    if {  [ [ $this GetTransformation ] IsIdentity ] == 1 } { 
	set reslimage [  [ $this GetSecondInput ] GetImage ]
	
	scan [ [ [ $this GetInput ] GetImage ] GetDimensions ] "%d %d %d" dx1 dy1 dz1
	scan [ [ [ $this GetSecondInput ] GetImage ]  GetDimensions ] "%d %d %d" dx2 dy2 dz2
	
	if { $dx1==$dx2 && $dy1==$dy2 && $dz1 == $dz2 } {
	    #	    puts stderr "No need to reslice same size, identity transform"
	    return $reslimage
	}
    }


    
    if { $reslice_algorithm !=0 } {
	set reslice_alg $reslice_algorithm
    } else {
	set reslice_alg [bis_resliceimage [pxvtable::vnewobj]]
	$reslice_alg InitializeFromContainer $this
	set delete_reslice_alg 1
    }
    $reslice_alg SetInput [ $this GetInput ] 
    $reslice_alg SetSecondInput [ $this GetSecondInput ] 
    $reslice_alg SetTransformation [ $this GetTransformation ] 
    catch { $reslice_alg SetOptionValue interp     [ $OptionsArray(interp) GetValue ] }
    $reslice_alg Execute
    
    if { $delete_reslice_alg == 0 } {
	$reslice_alg UpdateContainerWithOutput
    }
    
    set reslimage [  [ $reslice_alg GetOutput ] GetImage ]

    if { $delete_reslice_alg == 1 } {
	return [ list $reslimage  $reslice_alg ]
    } else {
	return $reslimage
    }
}
# -----------------------------------------------------------------------------------------

itcl::body bis_dualimagereslicetransformationalgorithm::DeleteResliceAlgorithmIfNeeded { lst } {

    if { [ llength $lst ] < 2 } {
	return 0
    }

    itcl::delete object [ lindex $lst 1 ] 
    return 1

}

