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

package require bis_baseintensityregistration 1.0
package provide bis_symmetrifyimage 1.0

#
# register image
#



itcl::class bis_symmetrifyimage {

    inherit bis_baseintensityregistration

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Midline Registration" }


    # Initialize Transformation
    protected method ExtractLinearTransform {  numparam } 

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------



itcl::body bis_symmetrifyimage::Initialize { } {

    PrintDebug "bis_symmetrifyimage::Initialize" 

    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set scriptname bis_symmetrifyimage

    #
    #document
    #

    set category "Registration"
    set description "computes a linear  intensity based registration to rotate a target image so that it is most symmetric about its I-axis."
    set description2 ""
    set backwardcompatibility ""
    set authors "xenophon.papademetris.yale.edu"
    set single_input 1
    set inputs { 
	{ reference_image   "Input Image" pxitclimage  ""  0}    
    }
    
    set outputs { 
	{ output_transform "Output Transformation"  pxitcltransform  "" }
	{ output_image   "Transformed Image" pxitclimage  ""  200 }
    }
    
    lappend options [ list resolution      "resolution "                                   "Resolution (x Native)"     real  1.5   { 0.5 10.0 }  20 ]
    lappend options [ list stepsize       "step size "                                    "Step Size"       real  1.0   { 0.1 5.0 }  -151 ]
    lappend options [ list smoothness       "smoothness "                                    "Smoothness"       real  0.0   { 0.0 5.0 }  -151 ]
    lappend options [ list numberoflevels  "number of multiresolution levels"          "Number of Levels"     int   2    { 1  5 } 2 ]
    lappend options [ list metric  "Similarity Metric"   "Metric"  listofvalues  "CC"    { SSD CC }  -10  ]
    lappend options [ list iterations      "Number of iterations "                                 "Number of Iterations"     int   20    { 1     50 }  -100 ]
    lappend options [ list numberofsteps    "Number of steps/level for the optimization"          "Number Of Steps"     int   4    { -4 5 } -150 ]
    lappend options [ list guiautosave       "AutoSave Result" "Autosave"  boolean  1 { 0 1 }  99 ]
    lappend options [ list reslimage   "Output a resliced image, or  a red-green blend image, or no  resliced image" "Resliced Image"  listofvalues Resliced  { Resliced ColorBlend }  200 ]
    set defaultsuffix { "_xform" }

    set category    "Registration"
    
    if { $authors == "" } {
	set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu."
    }

    $this AddDefaultOptions

}

# -----------------------------------------------------------------------------------------
# Execute. reimplemented from DoNMIAll of pxmat_register.tcl
# ----------------------------------------------------------------------------------------

itcl::body bis_symmetrifyimage::Execute {  } {


    PrintDebug "bis_symmetrifyimage::Execute"

    set image1    [ $this GetReferenceImage  ]

    set resolution     [ $OptionsArray(resolution) GetValue ]
    set iterations     [ $OptionsArray(iterations) GetValue ]
    set numlevels     [ $OptionsArray(numberoflevels) GetValue ]
    set numsteps       [ $OptionsArray(numberofsteps) GetValue ]
    set metric         [ $OptionsArray(metric) GetValue ]
    set usecc 1
    if { $metric == "SSD" } {
	set usecc 0
    }
    set stepsize       [ $OptionsArray(stepsize) GetValue ]
    set smoothness     [ $OptionsArray(smoothness) GetValue ]

    set areg [ vtkbisSymmetryRigidSingleLevelRegistration New ]
    [ $this GetOutputTransformation ] CopyTransformation [ $areg ComputeRegistration [ $image1 GetImage ] $resolution $numlevels $smoothness $usecc $stepsize $numsteps $iterations 1  ]
    $areg Delete

    $this CreateWarpedImage

    return 1
}



# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_symmetrifyimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_symmetrifyimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

