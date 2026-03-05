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

package provide bis_ISASHN 1.0
package require bis_spectbase 1.0


itcl::class bis_ISASHN {

    inherit bis_spectbase

    constructor { } { set inputs [ list ] ;
	
	set description2 "The basic idea of ISASHN is to compute the difference between an ictal and interictal \
SPECT scan for a single patient. The differences of the ictal/inter-ictal comparison are checked against a \
healthy normal database to determine the normal expected variation. Significant increases and decreases in CBF \
(cerebral blood flow) between the interictal and ictal SPECT can then be detected to predict seizure localization. \
    All inputs to this algorithm are expected to be registred to the 2mm MNI brain. The user specify the interictal \
    spect as input one and the ictal spect as input two. If the user want to use a custom healthy control poplation, \
    the user can optionally specify a standard deviation spect, and/or a brain mask. Otherwise these image are \
    automaically set to the ISAS health normal database. The user can also specifiy the smoothing kernal use in the \
    algorithm. The default value is 16mm FWHM. See Scheinost et. al 2009 ISBI "

	$this InitializeBaseSpect  }

    public method Execute    { }
    public method GetGUIName { } { return "Diff SPECT with ISASHN" }
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_ISASHN::Execute {  } {

    PrintDebug "bis_ISASHN::Execute"

    set inp1  [ GetInput ]
    set inp2  [ GetSecondInput ]
    set doMask [ $OptionsArray(usemask)   GetValue ]

    set std 0
    if { [ $InputsArray(stdimage) IsFileNameTheDefault ] } { 
	set std [ $this loadImage ISAS_Standard_Deviation.nii.gz ] 
    } else { 
	catch { set std [ $InputsArray(stdimage) GetObject ] }
    } 
    if { $std == 0 } { return 0 }

    set inter [ $this cast $inp1 Float ]
    set ictal [ $this cast $inp2 Float ]

    if { $doMask } { 

	set mask 0
	if { [ $InputsArray(maskimage) IsFileNameTheDefault ] } { 
	    set mask  [ $this loadImage ISAS_SPECT_Mask.nii.gz ]
	} else { 
	    catch { set mask [ $InputsArray(maskimage) GetObject ] }
	} 
	if { $mask == 0 } { return 0 }

	set inter [ $this mathops $inter $mask Multiply ]
	set ictal [ $this mathops $ictal $mask Multiply ]
    }

    set inter_sm [ smooth $inter ]
    set ictal_sm [ smooth $ictal ]

    set inter_pr [ propScale $inter_sm ]
    set ictal_pr [ propScale $ictal_sm ]

    set mask2 [ createBrainMask $inter_pr $ictal_pr $std ] 

    set inter_pre [ $this mathops $inter_pr $mask2 Multiply ]
    set ictal_pre [ $this mathops $ictal_pr $mask2 Multiply ]
    set std_msk   [ $this mathops $std      $mask2 Multiply ]

    set tmap [ createTmap $ictal_pre $inter_pre $std_msk ] 

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $tmap GetObject ]
    $outimage CopyImageHeader  [ $std GetImageHeader ]

    delete $inter_sm $ictal_sm $inter_pre $ictal_pre $inter_pr $ictal_pr $std $std_msk
    if { $doMask } { itcl::delete object $mask } 

    return 1
}

if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [ bis_ISASHN [ pxvtable::vnewobj ] ]
    $alg MainFunction 
}

