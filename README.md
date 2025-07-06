# YaleNeuroConnect_ProcessingPipeline

This repository contains the fMRI data processing pipeline utilized by the YaleNeuroConnect study. The shell scripts provided will only function properly if you have installed FSL (6.0.1), BioImage Suite (35), and SPM12, and have each of those softwares added to your path. These scripts are located in the '/sample/scripts/' folder provided in this repository. Additionally, we have provided one subjects' data from each step in the preprocessing pipeline that can be used as a reference/example. This data can be downloaded here: https://yaleedu-my.sharepoint.com/:f:/g/personal/todd_constable_yale_edu/EiXzzatu-MVGgkqlTyWXj_gBEFCKpNKpNoFy5sa1BZXU1Q?e=sAWwgF .
The raw dicoms were uploaded as .tgz files to save storage space. This is normally accomplished in step 2 of the pipeline. Once downloaded, you should move the sample raw dicom.tgz to the /sample/rawdicoms/ folder, and move the folder '/sub-pa5347/' to '/sample/sourcedata/'. To ensure that the pipeline functions smoothly, the folder/file structure that you use should mirror this example subjects'.  

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Written by Alexander J. Simon (aj.simon@yale.edu).

Below is the order in which you should run the scripts, a description of which preprocessing steps they accomplish, and a step-by-step guide on how to set them up and run them. 
1. convert_dicom_to_bids.csh -- converts your DICOM files to BIDS.  
  
   Steps:  
       a. Edit the script by typing "gedit convert_dicom_to_bids.csh" in your terminal.  
       b. Edit the dicom names of subjects you want to preprocess. Be sure that your input/output directories are correct.  
       c. Run it by typing "tcsh -c ./convert_dicom_to_bids.csh" in your terminal.
  

2. tar_zip.csh -- zips your original DICOM files to save space.
  
   Steps:  
       a. Edit the script by typing "gedit tar_zip.csh" in your terminal.
       b. Edit the file names of subjects you want to preprocess. Be sure that your input/output directories are correct. 
       c. Run it by typing "tcsh -c ./tar_zip.csh" in your terminal.  
       d. After it has completed, you can rm -rf the original dicom file (but keep the tgz file!) from the input directory to save disk space (make sure this is done only after the file is completely tar zipped).  
       ** Run this step after converting to bids since that requires an untarred file.

4. strip_brain.csh -- runs skull stripping by calling on to FSL optimized brain extraction tool (optiBET) to skull strip the T1 weighted MPRAGE.
  
   Steps:  
       a. Edit the script by typing "strip_brain.csh" in your terminal.  
       b. Edit the file names of subjects you want to preprocess. Be sure that your input/output directories are correctly pointing to the directory where the T1 scans are located.  
       c. Run it by typing "tcsh -c ./strip_brain.csh" in your terminal.  
       ** Visual inspection should be performed using the BioImage Suite GUI to ensure that the skull stripping worked properly.  

5. batch_bids_unzip_motion_zip.csh -- performs motion correction along 6 dimensions (24 parameters total) by calling SPM12 functions.  
  
   Steps:  
       a. Edit the script by typing "gedit batch_bids_unzip_motion_zip.csh" in your terminal.  
       b. Edit the file names of subjects you want to preprocess. Be sure that your input/output directories are correct.  
       c. Run it by typing "tcsh -c ./batch_bids_unzip_motion_zip.csh" in your terminal.  
       ** Outputs will be stored in with the file prefix 'R_*', and will be saved in /{subj}/func/realign and /{subj}/func/mean.  
       ** To check motion, examine *frametoframe.txt. The second number is your average ftf displacement in mm.  
   
6. Non-linear registration of the individuals' structural MRIs to a template brain.
  
   Steps:  
       a. Edit this file by typing: 'gedit 3DRef_HiResRegister_1st_to_3rd_pass.txt'. Edit the subject numbers and save it and be sure that your input/output directories are correct.  
       b. In your terminal run these commands:  
           1. bis_makebatch.tcl -odir registrations -setup 3DRef_HiResRegister_1st_to_3rd_pass.txt -makefile makefile_3DRef_HiResRegister_1st_to_3rd_pass.batch  
           2. make -f makefile_3DRef_HiResRegister_1st_to_3rd_pass.batch -j5  
       c. In the BioImage Suite GUI, visually inspect using the 3rd pass.grd file.  
       d. Copy the file to the participant's 'anat' directory, and then move all the preprocessed files to the '/registrations/' folder located in the folder where the scripts are stored.  

7. bislinearregister.csh -- performs linear registration of the functional scans to the structural MRIs.  
  
    Steps:  
       a. Edit the script by typing "gedit bislinearregister.csh.csh" in your terminal.
       b. Edit the file names of subjects you want to preprocess. Be sure that your input/output directories are correct. 
       c. Run it by typing "tcsh -c ./bislinearregister.csh.csh" in your terminal.  
       ** Visual inspection should be performed using the BioImage Suite GUI to ensure that the functional scans are aligned to the structural images.  

8. create_xmlgfiles_matrix_byrun.csh -- creates the setup files for making the functional connectivity matrices.  
  
   Steps:  
        a. Navigate to /sample/Matrix_Connectivity/indiv_setups/ in your terminal.  
        b. Make sure there is a .txt file in /sample/Matrix_Connectivity/indiv_setups/text_files/ called 'SubjList.txt' in that contains a list of the subject IDs that you want to make matrices for.  
        c. Run it by typing "tcsh -c ./create_xmlgfiles_matrix_byrun.csh" in your terminal.  
        ** This will function best if these are stored (along with this script) in a separate folder from the rest of the files.  
  
9. Create the functional connectivity matrices. This will compute a 268x268 functional connectivity matrix from your voxel level time series data using the Shen268 node atlas. It will also regress mean time courses in white matter, cerebrospinal fluid, and grey matter; high-pass filter to correct linear, quadratic, and cubic drift; regression of 24 motion parameters; and low-pass filter (Gaussian filter, σ = 1.55) the data.  
  
    Steps:  
        a. For each the subject that you are processing, move all files containing "MNI" in the filename in the folder containing their anatomical data to the /registrations folder where the scripts are stored. Then, copy everything from the registrations folder for that subject, and put it in their anatomy folder.  
        b. In the terminal, navigate to where the setup files are located.  
        c. Run this step by typing into the terminal: bis_fmrisetup.tcl sub-XXXX_matrix_shen268.xmlg matrix.  

10. batch_uniformsmoothing.csh -- uniform smoothing using a 6mm FWHM Gaussian kernel.
  
    Steps:  
        a. Make sure there is a .txt file called 'SubjList.txt' in the scripts folder that contains a list of the subject IDs that you are processing currently.  
        b. Run it by typing "tcsh -c ./batch_uniformsmoothing.csh" in your terminal.  

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  

**Visual inspection for quality control using BioImage Suite:**  
In the terminal, type: bis.tcl -> GUI pops us -> Click on Brain Register  

**Skull stripping:**  
File -> Load -> T1w *_optiBET.nii.gz image. 
Check that no major chunks of brain cut off, no major portions of skull unstripped.  

**Non linear registration:**   
Reference Viewer: File -> Standard images -> load the MNI_1mm_stripped.  
Transform Viewer: load the T1w skull stripped image.  
Brain register panel -> Transformations -> load *_3rdpass.grd file -> Click image reslice  
Check if all the crosshairs align between template and transformed image. Check all anatomical landmarks ventricles, subcortical structures, cerebellum, line up.  

**Linear registration:**  
Reference Viewer: load the T1w skull stripped image of the participant.  
Transform Viewer: load the mean*.nii.gz mean functional image of the participant.  
Brain register panel -> Transformations -> load * _FCTto3Depireg_converted.matr of the same participant -> Click image reslice  
Check if all the crosshairs align between anatomical and transformed mean functional image. Check all anatomical landmarks ventricles, subcortical structures, cerebellum, line up. 
