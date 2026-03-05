#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" -- "$@"

lappend auto_path [ file dirname [ info script ]]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]

package require bis_algorithm 1.0
package require bis_dualimagetransformationalgorithm 1.0
package require bis_shiftscaleimage 1.0
package require bis_maskimage 1.0
package require bis_thresholdimage 1.0
package provide bis_newjacobian 1.0

#
# compute overlap
#

itcl::class bis_newjacobian {

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

itcl::body bis_newjacobian::Initialize { } {

    PrintDebug "bis_newjacobian::Initialize" 

    set options {
	{ resolution "resolution" "resolution"  real    3.0 { 0.1 10.0 }  0 }
	{ threshold  "jacobian image threshold  " "threshold"  real    0.05 { 0.0 1.0 }  0 }
	{ offset     "image offset value " "offset"  real    1.0 { 0.0 1.0 }  -1 }
	{ scale      "image scale value " "scale"  real    100.0 { 0.0 10000.0 }  -2 }
	{ mode       "which change in volume to report" "mode"   { listofvalues radiobuttons }  both { affine both nonlinear }  0 }
	{ shiftmode  "switches how jacobians are normalized " "mode"   { listofvalues radiobuttons }  new { old new }  0 }
    }

    set defaultsuffix  { "_jacobian" }
    
    set scriptname bis_newjacobian

    #
    #document
    #

    set category "Registration"
    set description "computes either the determinant of the jacobian or the full tensor for a transformation."
    set description2 ""
    set backwardcompatibility "Reimplemented from pxnewjacobian.tcl"
    set authors "hirohito.okuda@yale.edu,xenophon.papademetris.yale.edu"

    $this InitializeDualImageTransformationAlgorithm

    $this RenameInput 1 "(Not used)" 101  
}

itcl::body bis_newjacobian::Execute {  } {

    PrintDebug "bis_newjacobian::Execute"

    set resolution   [ $OptionsArray(resolution) GetValue ]
    set threshold    [ $OptionsArray(threshold) GetValue ]
    set mode         [ $OptionsArray(mode) GetValue ]
    set shiftmode    [ $OptionsArray(shiftmode) GetValue ]
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

    if { $mode == "both" } {
	$reg ComputeSimpleJacobianImage $newimg [ $outimage GetObject ] [ $transform GetObject ] 1 0 $threshold 
    } else {
	#calculate affine jac
	#at some point write simple function to do this for a single voxel
	#instead of doing jacobian for all of them 
	$reg ComputeSimpleJacobianImage $newimg [ $outimage GetObject ] [ [ $transform GetObject ] GetLinearTransform ] 1 0 $threshold 
    }

    [ [ [ $outimage GetImage ] GetPointData ] GetScalars ] Modified

    if { $mode == "nonlinear" } {
	set r [ [ [ [ $outimage GetObject ] GetPointData ] GetScalars  ] GetRange ]
	set affinescale [ expr 1.0 / [ lindex $r 1 ] ]

	$reg ComputeSimpleJacobianImage $newimg [ $outimage GetObject ] [ $transform GetObject ] $affinescale 0 $threshold 
	[ [ [ $outimage GetImage ] GetPointData ] GetScalars ] Modified
    }

    set shiftscale [bis_shiftscaleimage [pxvtable::vnewobj]]    
    set maskimage  [bis_maskimage [pxvtable::vnewobj]]    
    set thrimage  [bis_thresholdimage [pxvtable::vnewobj]]    

    if { $shiftmode == "old" } {
	$shiftscale InitializeFromContainer $this
	$shiftscale SetInput $outimage 
	$shiftscale SetOptionValue scale $scale
	$shiftscale SetOptionValue shift [ expr -1 * $offset ]
	$shiftscale Execute

	$thrimage InitializeFromContainer $this
	$thrimage SetInput $outimage 
	$thrimage SetOptionValue minth 0.000001
	$thrimage SetOptionValue binary On
	$thrimage Execute

	$maskimage InitializeFromContainer $this
	$maskimage SetInput [ $shiftscale GetOutput ] 
	$maskimage SetSecondInput [ $thrimage GetOutput ]
	$maskimage Execute

	[ $outimage GetImage ] ShallowCopy [ [ $maskimage GetOutput ] GetImage ]

    } else {
	set tmpimg [ vtkImageData      [ pxvtable::vnewobj ] ]
	$tmpimg ShallowCopy [ $outimage GetObject ]
	$reg NewNormalizeJacobian $tmpimg [ $outimage GetObject ] $scale $offset
	[ [ [ $outimage GetImage ] GetPointData ] GetScalars ] Modified
	$tmpimg Delete
    }
        
    $outimage CopyImageHeader [ $refimage GetImageHeader ]

    $reg    Delete
    $newimg Delete
    $imcast Delete
    itcl::delete obj $shiftscale
    itcl::delete obj $maskimage

    return 1
}

# -----------------------------------------------------------------------------------------
#  You may need not modify this method
# ----------------------------------------------------------------------------------------


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_newjacobian.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 

if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_newjacobian [pxvtable::vnewobj]]
    $alg MainFunction 
}
