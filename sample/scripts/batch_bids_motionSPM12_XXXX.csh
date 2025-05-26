

matlab -nodesktop -nodisplay  >batch_bids_motionSPM12.out <<EOF

# Modify this to point to where your SPM12 lives
path('/software/',path);
path('/software/spm12',path);

a=pwd;
study_list=a(end-14:end-5);



%nii and hdr/img may have different parameters due to how spm reads the header matrix for nifti vs non-nifti
%old script uses linear interpolation
%naming output of .mat motion parameters is slightly different


% SPMdefaults=0  our old flags=1
use_old_flags=0;

% use 1st run=0  use middle run=1
use_middle_run=1;

basedir = ['/sample/sourcedata'];


    %may need to change the next two lines depending on your needs
    dir=sprintf(['%s/%s/func'],deblank(basedir),deblank(study_list));
    filter_expression=sprintf(['^%s_task-1trmb5ipat2_run-[0-9][0-9]_bold.nii'],deblank(study_list));

    parameter_dir=sprintf('%s/realign/',dir);

    f=spm_select('FPList',deblank(dir),filter_expression);

    if(use_middle_run)
	mid=ceil(size(f,1)/2);
	f=[ f(mid,:) ; f(1:(mid-1),:) ; f((mid+1):end,:) ]
    end

disp(f);

    if ~isempty(f)
        mrrc_motioncorrection_wrapper(f,use_old_flags,parameter_dir);
    end



quit

EOF
