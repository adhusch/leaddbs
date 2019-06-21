function ea_itksnap_greedy(varargin)
% This function uses ITK-SNAPs greedy binary to do an automatic very fast
% rigid registration between post-op MRIs.
%
% Some exhaustive search for a good initial configuration is carried out
% before optimsation thus it should perform robust also on heavily tilted
% data (up to 90 degree tilt).
%
% The transformation is stored in ITK .txt format and converted to the
% newer ITK .mat format used by ANTs. Thus all further operations can
% threat it as an ANTs transform.
%
% Note that we assume a RIGID registratrion model here and hot AFFINE!
% __________________________________________________________________________________
% Copyright (C) 2019 University of Luxembourg, Interventional Neuroscience
% Group
% Andreas Husch
%%%

fixedimage = varargin{1};
movingimage = varargin{2};
outputimage = varargin{3};


disp('Running ITK-SNAP greedy rigid registration...');
%% Get itksnap binary (should be in path by following ITKSNAP / Help / Install Comand Line Tools)
if ispc
    greedy = 'greedy.exe';
else
    greedy = '/usr/local/bin/greedy';
end

% name of the output transformation
[~, mov] = ea_niifileparts(movingimage);
[~, fix] = ea_niifileparts(fixedimage);

xfm = [mov, '2', fix, '_ants1'];
runs = dir([volumedir, xfm, '*.mat']);
if isempty(runs)
    runs = 0;
else
    runs = str2double(runs(end).name(length(xfm)+1:end-4)); % suppose runs<10
end
xfm = ea_path_helper([volumedir, xfm, num2str(runs)]);

cmd = [greedy ' '...
   '-d 3 '...
   '-a -dof 6 '...
   '-search 100 90 5 '...
   '-ia-image-centers '...
   '-m MI '...
   '-i ' fixedimage ' ' ...
   movingimage ...
   '-o ' xfm '.txt -n 100x50x10'];
   
   

try
    if ~ispc
        system(['bash -c ''' cmd '''']); 
    else
        system(cmd);
    end
catch
    warning('Could not run greedy successfully! Make sure itksnap is available in your path (Launch ITK-SNAP and see in Help / Install Command Line Tools)');
end

%% Save ITK .txt also as ANTS .mat
disp('Generating .mat version of transform to be re-read by LeadDBS for internal use later...');
ea_convertANTsITKTransforms([options.root,options.patientname,filesep,xfm '.txt'], ...
    [options.root,options.patientname,filesep,xfm '.mat']);
ea_convertANTsITKTransforms([options.root,options.patientname,filesep,xfm '.txt'], ...
    [options.root,options.patientname,filesep,xfm '.mat'], 1); % generate inverse
disp('Generating .mat done.');

%% Apply registration to generate transformed CT file
disp('Generating image by applying transform...')
ea_apply_coregistration(fixedimage, movingimage, outputimage);
disp('Coregistration done.');


%% add methods dump:
cits={
    'Yushkevich, P.A., Pluta, J., Wang, H., Wisse, L.E., Das, S. and Wolk, D., 2016. Fast Automatic Segmentation of Hippocampal Subfields and Medial Temporal Lobe Subregions in 3 Tesla and 7 Tesla MRI. Alzheimer`s & Dementia: The Journal of the Alzheimers Association, 12(7), pp.P126-P127.'
};

ea_methods(volumedir,[mov,' was co-registered to ',fix,' using a rigid registration as implemented in the ITK-SNAP greedy tool (Yushkevich et al, https://github.com/pyushkevich/greedy)'],...
    cits);