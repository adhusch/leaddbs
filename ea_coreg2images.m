function affinefile = ea_coreg2images(options,moving,fixed,ofile,otherfiles,writeoutmat,msks,interp)
% Generic function for image coregistration
%
% 1. Moving image will keep untouched unless the output points to the same
%    image.
% 2. Use 'ea_backuprestore' before this function in case you want to
%    backup/restore the moving image to/from the 'raw_' prefixed image.
% 3. 'otherfiles' will always be overwritten. If you don't want them to be
%    overwritten, use 'ea_apply_coregistration' afterwards to apply the
%    returned forward transform ('affinefile{1}') to 'otherfiles' rather
%    than supply 'otherfiles' parameter here.


if ~exist('otherfiles','var')
    otherfiles = {};
elseif isempty(otherfiles) % [] or {} or ''
    otherfiles = {};
elseif ischar(otherfiles) % single file, make it to cell string
    otherfiles = {otherfiles};
end

if ~exist('writeoutmat','var') || isempty(writeoutmat)
    writeoutmat = 0;
end

if ~exist('affinefile','var') || isempty(affinefile)
    affinefile = {};
end

if ~exist('msks','var') || isempty(msks)
    msks={};
end

if ~exist('interp','var') || isempty(interp)
    interp=4;
end

switch options.coregmr.method
    case 'SPM' % SPM
        affinefile = ea_spm_coreg(options,moving,fixed,'nmi',1,otherfiles,writeoutmat,interp);

        [fpth, fname, ext] = ea_niifileparts(moving);
        spmoutput = [fileparts(fpth), filesep, 'r', fname, ext];
        if ~strcmp(spmoutput, ofile)
            movefile(spmoutput, ofile);
        end

        for ofi=1:length(otherfiles)
            [fpth, fname, ext] = ea_niifileparts(otherfiles{ofi});
            spmoutput = [fileparts(fpth), filesep, 'r', fname, ext];
            movefile(spmoutput, [fpth, ext]);
        end

    case 'FSL FLIRT' % FSL FLIRT
        affinefile = ea_flirt(fixed,...
            moving,...
            ofile,writeoutmat,otherfiles);
    case 'FSL BBR' % FSL BBR
        affinefile = ea_flirt_bbr(fixed,...
            moving,...
            ofile,writeoutmat,otherfiles);
    case 'ANTs' % ANTs
        affinefile = ea_ants(fixed,...
            moving,...
            ofile,writeoutmat,otherfiles,msks);
    case 'BRAINSFIT' % BRAINSFit
        affinefile = ea_brainsfit(fixed,...
            moving,...
            ofile,writeoutmat,otherfiles);
    case 'Hybrid SPM & ANTs' % Hybrid SPM -> ANTs
        ea_spm_coreg(options,moving,fixed,'nmi',0,otherfiles,writeoutmat)
        affinefile = ea_ants(fixed,...
            moving,...
            ofile,writeoutmat,otherfiles);
    case 'Hybrid SPM & FSL' % Hybrid SPM -> FSL
        ea_spm_coreg(options,moving,fixed,'nmi',0,otherfiles,writeoutmat)
        affinefile = ea_flirt(fixed,...
            moving,...
            ofile,writeoutmat,otherfiles);
    case 'Hybrid SPM & BRAINSFIT' % Hybrid SPM -> Brainsfit
        ea_spm_coreg(options,moving,fixed,'nmi',0,otherfiles,writeoutmat)
        affinefile = ea_brainsfit(fixed,...
            moving,...
            ofile,writeoutmat,otherfiles);
end

% ea_conformspaceto(fixed, ofile); % fix qform/sform issues.
