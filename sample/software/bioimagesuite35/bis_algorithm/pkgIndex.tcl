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

#
# px libraries
#
package ifneeded pxitclobject            1.0 [list source [file join [file join [file join $dir ".."] base ] pxitclobject.tcl]] 
package ifneeded vtkpxcontrib            1.2 [list source [file join [file join [file join $dir ".."] base ] vtkpxcontrib.tcl]] 
package ifneeded pxappscommon            1.0 [list source [file join [file join [file join $dir ".."] apps ] pxappscommon.tcl]]  

# -----------
# Core Stuff
# -----------
package ifneeded bis_basealgorithm       1.0 [list source [file join $dir bis_basealgorithm.tcl]] 
package ifneeded bis_algorithm           1.0 [list source [file join $dir bis_algorithm.tcl]] 
package ifneeded bis_algorithmdbaseinterface 1.0 [list source [file join $dir bis_algorithmdbaseinterface.tcl]] 
package ifneeded bis_option              1.0 [list source [file join $dir bis_option.tcl]] 
package ifneeded bis_optiondialog              1.0 [list source [file join $dir bis_optiondialog.tcl]] 
package ifneeded bis_object              1.0 [list source [file join $dir bis_object.tcl]] 
package ifneeded bis_test                1.0 [list source [file join $dir bis_test.tcl]] 
package ifneeded bis_util                1.0 [list source [file join $dir bis_util.tcl]] 
package ifneeded bis_common              1.0 [list source [file join $dir bis_common.tcl]] 
package ifneeded bis_datamanager         1.0 [list source [file join $dir bis_datamanager.tcl]] 
package ifneeded bis_treewidget          1.0 [list source [file join $dir bis_treewidget.tcl]]
package ifneeded bis_viewer          1.0 [list source [file join $dir bis_viewer.tcl]]
package ifneeded bis_polygonaldisplaymanager          1.0 [list source [file join $dir bis_polygonaldisplaymanager.tcl]]
package ifneeded bis_xmlalgorithm          1.0 [list source [file join $dir bis_xmlalgorithm.tcl]]
package ifneeded bis_electrodeeditor          1.0 [list source [file join $dir bis_electrodeeditor.tcl]]
package ifneeded bis_landmarkeditor          1.0 [list source [file join $dir bis_landmarkeditor.tcl]]
package ifneeded bis_basecontrolhelper       1.0 [list source [file join $dir bis_basecontrolhelper.tcl]] 


# Image to Image Algorithms
# -----------------------------------------------------------------------------
# This is the parent class
package ifneeded bis_imagetoimagealgorithm     1.0 [list source [file join $dir bis_imagetoimagealgorithm.tcl ]] 
package ifneeded bis_imagelisttoimagealgorithm  1.0 [list source [file join $dir bis_imagelisttoimagealgorithm.tcl ]]
package ifneeded bis_basethresholdimage        1.0 [list source [file join $dir bis_basethresholdimage.tcl ]] 
package ifneeded bis_imagetosurfacealgorithm   1.0 [list source [file join $dir bis_imagetosurfacealgorithm.tcl ]] 

#
# These all derive (or should derive from bis_imagetoimagealgorithm)
#
package ifneeded bis_testsurface.tcl       1.0 [list source [file join $dir bis_testsurface.tcl]] 
package ifneeded bis_create4dimage         1.0 [list source [file join $dir bis_create4dimage.tcl]] 
package ifneeded bis_manualregistration         1.0 [list source [file join $dir bis_manualregistration.tcl]] 
package ifneeded bis_split4dimage          1.0 [list source [file join $dir bis_split4dimage.tcl]] 
package ifneeded bis_smoothimage           1.0 [list source [file join $dir bis_smoothimage.tcl]] 
package ifneeded bis_exponentialfitimage           1.0 [list source [file join $dir bis_exponentialfitimage.tcl]] 
package ifneeded bis_exponentialfitt1           1.0 [list source [file join $dir bis_exponentialfitt1.tcl]] 
package ifneeded bis_regularizeobjectmap   1.0 [list source [file join $dir bis_regularizeobjectmap.tcl]] 
package ifneeded bis_convolveimage           1.0 [list source [file join $dir bis_convolveimage.tcl]] 
package ifneeded bis_distancemapimage           1.0 [list source [file join $dir bis_distancemapimage.tcl]] 
package ifneeded bis_skeletonizeimage      1.0 [list source [file join $dir bis_skeletonizeimage.tcl]] 
package ifneeded bis_temporalsmoothimage   1.0 [list source [file join $dir bis_temporalsmoothimage.tcl]] 
package ifneeded bis_nonlinearsmoothimage  1.0 [list source [file join $dir bis_nonlinearsmoothimage.tcl]] 
package ifneeded bis_edgedetectimage       1.0 [list source [file join $dir bis_edgedetectimage.tcl]] 
package ifneeded bis_imagemedian           1.0 [list source [file join $dir bis_imagemedian.tcl]] 
package ifneeded bis_imageremoveframes     1.0 [list source [file join $dir bis_imageremoveframes.tcl]] 
package ifneeded bis_imagedilate           1.0 [list source [file join $dir bis_imagedilate.tcl]] 
package ifneeded bis_cropimage             1.0 [list source [file join $dir bis_cropimage.tcl]] 
package ifneeded bis_cylindricalcropimage  1.0 [list source [file join $dir bis_cylindricalcropimage.tcl]] 
package ifneeded bis_piecewiseimagemap     1.0 [list source [file join $dir bis_piecewiseimagemap.tcl]] 
package ifneeded bis_flipimage             1.0 [list source [file join $dir bis_flipimage.tcl]] 
package ifneeded bis_castimage             1.0 [list source [file join $dir bis_castimage.tcl]] 
package ifneeded bis_shiftscaleimage       1.0 [list source [file join $dir bis_shiftscaleimage.tcl]] 
package ifneeded bis_logimage       1.0 [list source [file join $dir bis_logimage.tcl]] 
package ifneeded bis_rfftimage             1.0 [list source [file join $dir bis_rfftimage.tcl]] 
package ifneeded bis_fftimage              1.0 [list source [file join $dir bis_fftimage.tcl]] 
package ifneeded bis_resampleimage         1.0 [list source [file join $dir bis_resampleimage.tcl]] 
package ifneeded bis_thresholdimage        1.0 [list source [file join $dir bis_thresholdimage.tcl]] 
package ifneeded bis_clusterthresholdimage 1.0 [list source [file join $dir bis_clusterthresholdimage.tcl]] 
package ifneeded bis_listthresholdimage    1.0 [list source [file join $dir bis_listthresholdimage.tcl]] 
package ifneeded bis_reorientimage         1.0 [list source [file join $dir bis_reorientimage.tcl]] 
package ifneeded bis_newreorientimage         1.0 [list source [file join $dir bis_newreorientimage.tcl]] 
package ifneeded bis_relabelimage          1.0 [list source [file join $dir bis_relabelimage.tcl]] 
package ifneeded bis_intsegment            1.0 [list source [file join $dir bis_intsegment.tcl]] 
package ifneeded bis_biasfield            1.0 [list source [file join $dir bis_biasfield.tcl]] 
package ifneeded bis_sliceinhomogeneity   1.0 [list source [file join $dir bis_sliceinhomogeneity.tcl]] 
package ifneeded bis_computedisplacementfield   1.0 [list source [file join $dir bis_computedisplacementfield.tcl]] 
package ifneeded bis_computejointhistogram   1.0 [list source [file join $dir bis_computejointhistogram.tcl]] 
package ifneeded bis_visualizetransformation    1.0 [list source [file join $dir bis_visualizetransformation.tcl]] 

#package ifneeded bis_fastpostprocess       1.0 [list source [file join $dir bis_fastpostprocess.tcl]] 
package ifneeded bis_interleave            1.0 [list source [file join $dir bis_interleave.tcl]] 
package ifneeded bis_tmaptozscore          1.0 [list source [file join $dir bis_tmaptozscore.tcl]] 
package ifneeded bis_tmaptopvalue          1.0 [list source [file join $dir bis_tmaptopvalue.tcl]] 
package ifneeded bis_imagemathoperations   1.0 [list source [file join $dir bis_imagemathoperations.tcl]]
package ifneeded bis_singleimagemathoperations   1.0 [list source [file join $dir bis_singleimagemathoperations.tcl]]
package ifneeded bis_imagecompare          1.0 [list source [file join $dir bis_imagecompare.tcl]]
package ifneeded bis_image4dnormalize          1.0 [list source [file join $dir bis_image4dnormalize.tcl]]
package ifneeded bis_ttest                 1.0 [list source [file join $dir bis_ttest.tcl]] 
package ifneeded bis_zscoretopvalue        1.0 [list source [file join $dir bis_zscoretopvalue.tcl]] 
package ifneeded bis_fdr                   1.0 [list source [file join $dir bis_fdr.tcl]]
package ifneeded bis_preprocessimage       1.0 [list source [file join $dir bis_preprocessimage.tcl]]
package ifneeded bis_combineframes         1.0 [list source [file join $dir bis_combineframes.tcl]]
package ifneeded bis_combineimages         1.0 [list source [file join $dir bis_combineimages.tcl]]
package ifneeded bis_combinetransformations         1.0 [list source [file join $dir bis_combinetransformations.tcl]]
package ifneeded bis_rtotmap               1.0 [list source [file join $dir bis_rtotmap.tcl]]
package ifneeded bis_rtopvalue             1.0 [list source [file join $dir bis_rtopvalue.tcl]]
#package ifneeded bis_oneminuspvalue        1.0 [list source [file join $dir bis_oneminuspvalue.tcl]]
package ifneeded bis_csfwmmotioncorr       1.0 [list source [file join $dir bis_csfwmmotioncorr.tcl]]
package ifneeded bis_computeglm            1.0 [list source [file join $dir bis_computeglm.tcl]]
package ifneeded bis_imagematrixmultiply           1.0 [list source [file join $dir bis_imagematrixmultiply.tcl]]
#package ifneeded bis_testfmritool          1.0 [list source [file join $dir bis_testfmritool.tcl]]
package ifneeded bis_displayroimean        1.0 [list source [file join $dir bis_displayroimean.tcl]]


#Connectivity
package ifneeded bis_temporalsmoothimage              1.0 [list source [file join $dir bis_temporalsmoothimage.tcl]] 
package ifneeded bis_mediantemporalsmoothimage        1.0 [list source [file join $dir bis_mediantemporalsmoothimage.tcl]] 
package ifneeded bis_removetemporaldrift              1.0 [list source [file join $dir bis_removetemporaldrift.tcl]] 
package ifneeded bis_removeslicemean                  1.0 [list source [file join $dir bis_removeslicemean.tcl]] 
package ifneeded bis_roimean                          1.0 [list source [file join $dir bis_roimean.tcl]]
package ifneeded bis_seedcorrelation                  1.0 [list source [file join $dir bis_seedcorrelation.tcl]]
package ifneeded bis_matrixcorrelation                1.0 [list source [file join $dir bis_matrixcorrelation.tcl]]
package ifneeded bis_intrinsicconnectivity            1.0 [list source [file join $dir bis_intrinsicconnectivity.tcl]] 
package ifneeded bis_computecorrelations              1.0 [list source [file join $dir bis_computecorrelations.tcl]] 
package ifneeded bis_fmritoolboxoptimize              1.0 [list source [file join $dir bis_fmritoolboxoptimize.tcl]]
package ifneeded bis_fmritoolbox                      1.0 [list source [file join $dir bis_fmritoolbox.tcl]]
package ifneeded bis_optionsampling                   1.0 [list source [file join $dir bis_optionsampling.tcl]]
package ifneeded bis_connectivityfit                  1.0 [list source [file join $dir bis_connectivityfit.tcl]]
package ifneeded bis_hott2                            1.0 [list source [file join $dir bis_hott2.tcl]]
package ifneeded bis_ftopvalue                        1.0 [list source [file join $dir bis_ftopvalue.tcl]]
# Surface to Surface Algorithm
# These will populate the new surface control
# --------------------------------------------
# This is the parent class
package ifneeded bis_surfacetosurfacealgorithm     1.0 [list source [file join $dir bis_surfacetosurfacealgorithm.tcl ]] 
package ifneeded bis_imageandsurfacetosurfacealgorithm     1.0 [list source [file join $dir bis_imageandsurfacetosurfacealgorithm.tcl ]] 
#
# derived classes
#
package ifneeded bis_cleansurface          1.0 [list source [file join $dir bis_cleansurface.tcl]] 
package ifneeded bis_clipsurface           1.0 [list source [file join $dir bis_clipsurface.tcl]] 
package ifneeded bis_computenormals        1.0 [list source [file join $dir bis_computenormals.tcl]] 
package ifneeded bis_connect               1.0 [list source [file join $dir bis_connect.tcl]] 
package ifneeded bis_curvatures            1.0 [list source [file join $dir bis_curvatures.tcl]] 
package ifneeded bis_decimate              1.0 [list source [file join $dir bis_decimate.tcl]]
package ifneeded bis_delaunay3D            1.0 [list source [file join $dir bis_delaunay3D.tcl]]
package ifneeded bis_extractobjectmap      1.0 [list source [file join $dir bis_extractobjectmap.tcl]]
package ifneeded bis_extractsurface        1.0 [list source [file join $dir bis_extractsurface.tcl]]
#package ifneeded bis_mapfunctional         1.0 [list source [file join $dir bis_mapfunctional.tcl]]
package ifneeded bis_smoothsurface         1.0 [list source [file join $dir bis_smoothsurface.tcl]]
package ifneeded bis_subdivide		   1.0 [list source [file join $dir bis_subdivide.tcl]]
package ifneeded bis_thresholdpoints       1.0 [list source [file join $dir bis_thresholdpoints.tcl]]
package ifneeded bis_triangulate	   1.0 [list source [file join $dir bis_triangulate.tcl]]


#
package ifneeded bis_landmarkstolandmarksalgorithm     1.0 [list source [file join $dir bis_landmarkstolandmarksalgorithm.tcl ]] 

#
# these need to be "reparented"
#
package ifneeded bis_transformsurface     1.0 [list source [file join $dir bis_transformsurface.tcl]] 
package ifneeded bis_computedistance       1.0 [list source [file join $dir bis_computedistance.tcl]] 

# Transformation Manipulation
# ---------------------------

# Image and transformation combo algorithms
#     -- some of this will come from pxitcloverlaytool
# ----------------------------------------------------
# parent class
package ifneeded bis_dualimagealgorithm     1.0 [list source [file join $dir bis_dualimagealgorithm.tcl ]] 
package ifneeded bis_dualimagetransformationalgorithm     1.0 [list source [file join $dir bis_dualimagetransformationalgorithm.tcl ]] 
package ifneeded bis_dualimagereslicetransformationalgorithm     1.0 [list source [file join $dir bis_dualimagereslicetransformationalgorithm.tcl ]] 

#
# derived classes
#
package ifneeded bis_resliceimage          1.0 [list source [file join $dir bis_resliceimage.tcl]] 
package ifneeded bis_reslicetensor          1.0 [list source [file join $dir bis_reslicetensor.tcl]] 
package ifneeded bis_manualreslice          1.0 [list source [file join $dir bis_manualreslice.tcl]] 
package ifneeded bis_checkerboardimage	           1.0 [list source [file join $dir bis_checkerboardimage.tcl]] 
package ifneeded bis_colorblendimage	           1.0 [list source [file join $dir bis_colorblendimage.tcl]] 
package ifneeded bis_createoverlayimage	           1.0 [list source [file join $dir bis_createoverlayimage.tcl]] 
package ifneeded bis_maskimage	           1.0 [list source [file join $dir bis_maskimage.tcl]] 
package ifneeded bis_blendimage          1.0 [list source [file join $dir bis_blendimage.tcl]] 
package ifneeded bis_stitchimage         1.0 [list source [file join $dir bis_stitchimage.tcl]] 
package ifneeded bis_computeoverlap         1.0 [list source [file join $dir bis_computeoverlap.tcl]] 
package ifneeded bis_computesimilarity      1.0 [list source [file join $dir bis_computesimilarity.tcl]] 
package ifneeded bis_singlejacobian        1.0 [list source [file join $dir bis_singlejacobian.tcl]] 
package ifneeded bis_stripskull        1.0 [list source [file join $dir bis_stripskull.tcl]] 


# Registration Stuff
# ------------------
# parent class
package ifneeded bis_baseintensityregistration     1.0 [list source [file join $dir bis_baseintensityregistration.tcl ]] 
# derived classes
package ifneeded bis_linearintensityregister       1.0 [list source [file join $dir    bis_linearintensityregister.tcl ]] 
package ifneeded bis_nonlinearintensityregister    1.0 [list source [file join $dir bis_nonlinearintensityregister.tcl ]] 
package ifneeded bis_nonlineardistortioncorrection 1.0 [list source [file join $dir bis_nonlineardistortioncorrection.tcl ]] 
#package ifneeded bis_labelregister                 1.0 [list source [file join $dir bis_labelregister.tcl ]]
# parent class
package ifneeded bis_basepointbasedregistration     1.0 [list source [file join $dir bis_basepointbasedregistration.tcl ]] 
package ifneeded bis_pointbasedregistrationviewer     1.0 [list source [file join $dir bis_pointbasedregistrationviewer.tcl ]] 
package ifneeded bis_linearpointregister         1.0 [list source [file join $dir bis_linearpointregister.tcl]] 
package ifneeded bis_nonlinearpointregister         1.0 [list source [file join $dir bis_nonlinearpointregister.tcl]] 
#package ifneeded bis_integrated_registration    1.0 [list source [file join $dir bis_integrated_registration.tcl]] 
package ifneeded bis_integratedintensityregister 1.0 [ list source [ file join $dir bis_integratedintensityregister.tcl ]]]
package ifneeded bis_serialdemonmousereg 1.0 [ list source [ file join $dir bis_serialdemonmousereg.tcl ]]


# Generic Utilities
# -----------------
package ifneeded bis_headerinfo            1.0 [list source [file join $dir bis_headerinfo.tcl]] 
package ifneeded bis_surfaceinfo           1.0 [list source [file join $dir bis_surfaceinfo.tcl]] 
#package ifneeded bis_imageaccumulate     1.0 [list source [file join $dir bis_imageaccumulate.tcl]] 

# Larger Things for group input (i.e. setup driven)
# ------------------------------------------------
#package ifneeded bis_multiregister_int          1.0 [list source [file join $dir bis_multiregister_int.tcl]] 
#package ifneeded bis_pairwiseregister           1.0 [list source [file join $dir bis_pairwiseregister.tcl]] 
#package ifneeded bis_mnnnultijacobian              1.0 [list source [file join $dir bis_multijacobian.tcl]] 
#package ifneeded bis_multisegment              1.0 [list source [file join $dir bis_multisegment.tcl]] 


# More Complex Things (i.e. DTI/Vascular)
# ---------------------------------------
#package ifneeded bis_tensoranalysis        1.0 [list source [file join $dir bis_tensoranalysis.tcl]] 
#package ifneeded bis_vesselprop            1.0 [list source [file join $dir bis_vesselprop.tcl]] 
#package ifneeded bis_vesselregion          1.0 [list source [file join $dir bis_vesselregion.tcl]] 
#package ifneeded bis_vesselutility         1.0 [list source [file join $dir bis_vesselutility.tcl]] 
#package ifneeded bis_vesseltrack           1.0 [list source [file join $dir bis_vesseltrack.tcl]] 

# Levelset Algorithms
package ifneeded bis_baselevelset        1.0 [list source [file join $dir bis_baselevelset.tcl]] 
package ifneeded bis_levelset        1.0 [list source [file join $dir bis_levelset.tcl]] 
package ifneeded bis_coupledlevelset        1.0 [list source [file join $dir bis_coupledlevelset.tcl]] 

# GUI Stuff
# ---------------------------------------
package ifneeded bis_guicontainer          1.0 [list source [file join $dir bis_guicontainer.tcl       ]] 
package ifneeded bis_guiimageutility       1.0 [list source [file join $dir bis_guiimageutility.tcl    ]] 
package ifneeded bis_guitreeimageutility   1.0 [list source [file join $dir bis_guitreeimageutility.tcl]] 
package ifneeded bis_guitreecreate4d       1.0 [list source [file join $dir bis_guitreecreate4d.tcl    ]]
package ifneeded bis_guisurfacecontrol     1.0 [list source [file join $dir bis_guisurfacecontrol.tcl  ]] 
package ifneeded bis_guisurfaceutility     1.0 [list source [file join $dir bis_guisurfaceutility.tcl  ]] 
package ifneeded bis_guioverlayutility     1.0 [list source [file join $dir bis_guioverlayutility.tcl  ]] 
package ifneeded bis_guirpmcontainer     1.0 [list source [file join $dir bis_guirpmcontainer.tcl  ]]
package ifneeded bis_guicompareutility     1.0 [list source [file join $dir bis_guicompareutility.tcl  ]] 

#spect stuff
package ifneeded bis_proportionalscale 1.0 [list source [file join $dir bis_proportionalscale.tcl ]] 
package ifneeded bis_spectbase         1.0 [list source [file join $dir bis_spectbase.tcl         ]] 
package ifneeded bis_ISAS              1.0 [list source [file join $dir bis_ISAS.tcl              ]] 
package ifneeded bis_ISASHN            1.0 [list source [file join $dir bis_ISASHN.tcl            ]] 
package ifneeded bis_spectrf           1.0 [list source [file join $dir bis_spectrf.tcl           ]] 
package ifneeded bis_spectapp          1.0 [list source [file join $dir bis_spectapp.tcl          ]] 

# Landmark stuff
package ifneeded bis_smoothlandmarks          1.0 [list source [file join $dir bis_smoothlandmarks.tcl          ]] 
package ifneeded bis_resamplelandmarks          1.0 [list source [file join $dir bis_resamplelandmarks.tcl          ]] 

# Batch File Generator
package ifneeded bis_makebatch               1.0 [list source [file join $dir bis_makebatch.tcl          ]] 

# DTI Stuff
package ifneeded bis_tensoranalysis               1.0 [list source [file join $dir bis_tensoranalysis.tcl          ]] 
package ifneeded bis_computetensor               1.0 [list source [file join $dir bis_computetensor.tcl          ]] 
package ifneeded bis_tensorproperties   1.0 [list source [file join $dir bis_tensorproperties.tcl          ]] 
package ifneeded bis_tensordistancemap     1.0 [list source [file join $dir bis_tensordistancemap.tcl]] 
package ifneeded bis_vectorstreamlinetrack     1.0 [list source [file join $dir bis_vectorstreamlinetrack.tcl]] 


#Vascular Stuff
package ifneeded bis_frangivesselness 1.0 [ list source [ file join $dir bis_frangivesselness.tcl ]]
package ifneeded bis_qianvesselness 1.0 [ list source [ file join $dir bis_qianvesselness.tcl ]]

# fMRI Test
package ifneeded bis_multisubjectfmri 1.0 [ list source [ file join $dir bis_multisubjectfmri.tcl ]]
package ifneeded bis_singlesubjectfmri 1.0 [ list source [ file join $dir bis_singlesubjectfmri.tcl ]]

package ifneeded bis_graphvis       1.0 [list source [file join $dir bis_graphvis.tcl]] 

# DICOM
package ifneeded bis_dicom2nifti 1.0 [ list source [ file join $dir bis_dicom2nifti.tcl ]]
package ifneeded bis_varian2nifti 1.0 [ list source [ file join $dir bis_varian2nifti.tcl ]]

#icd stuff
package ifneeded bis_cudaintrinsicconnectivity 1.0 [ list source [ file join $dir  bis_cudaintrinsicconnectivity.tcl ]]
package ifneeded bis_histogramsurvival 1.0 [ list source [ file join $dir  bis_histogramsurvival.tcl ]]
package ifneeded bis_histogramtocdf 1.0 [ list source [ file join $dir  bis_histogramtocdf.tcl ]]
package ifneeded bis_connectivityfit 1.0 [ list source [ file join $dir  bis_connectivityfit.tcl ]]
package ifneeded bis_centerofgravity 1.0 [ list source [ file join $dir  bis_centerofgravitiy.tcl ]]
package ifneeded bis_normalizeicd 1.0 [ list source [ file join $dir  bis_normalizeicd.tcl ]]
package ifneeded bis_connectivityhistogram 1.0 [ list source [ file join $dir  bis_connectivityhistogram.tcl ]]
package ifneeded bis_pairedconnectivityhistogram 1.0 [ list source [ file join $dir  bis_pairedconnectivityhistogram.tcl ]]
package ifneeded bis_ipsicontrahistogram 1.0 [ list source [ file join $dir  bis_ipsicontrahistogram.tcl ]]

# Connectivity
package ifneeded bis_matvis_computecentroids 1.0 [ list source [ file join $dir bis_matvis_computecentroids.tcl ]]
package ifneeded bis_matvis_reordernodes 1.0 [ list source [ file join $dir bis_matvis_reordernodes.tcl ]]
package ifneeded bis_matvis_reordermatrix 1.0 [ list source [ file join $dir bis_matvis_reordermatrix.tcl ]]
package ifneeded bis_matvis_reorderparcellation 1.0 [ list source [ file join $dir bis_matvis_reorderparcellation.tcl ]]
package ifneeded bis_matvis_reorderparcellationsurface 1.0 [ list source [ file join $dir bis_matvis_reorderparcellationsurface.tcl ]]
package ifneeded bis_matvis2d 1.0 [ list source [ file join $dir bis_matvis2d.tcl ]]
package ifneeded bis_matvis3d 1.0 [ list source [ file join $dir bis_matvis3d.tcl ]]

