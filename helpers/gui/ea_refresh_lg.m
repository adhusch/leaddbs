function ea_refresh_lg(handles)

ea_busyaction('on',handles.leadfigure,'group');
% get model data
disp('Getting model data...');
M=getappdata(handles.leadfigure,'M');

if strcmp(get(handles.groupdir_choosebox,'String'),'Choose Group Directory') % not set yet.
    ea_busyaction('off',handles.leadfigure,'group');
    return
end
M.root=get(handles.groupdir_choosebox,'String');
if ~isfield(M,'guid') % only done once, legacy support.
    M.guid=datestr(datevec(now), 'yyyymmddHHMMSS' );
end
disp('Refreshing group list...');
% refresh group list
set(handles.grouplist,'String',M.patient.group);
if max(M.ui.listselect) > length(M.patient.group)
    M.ui.listselect = 1;
end
try set(handles.grouplist,'Value',M.ui.listselect); end

disp('Refreshing patient list...');
% refresh patient list
set(handles.patientlist,'String',M.patient.list);
try set(handles.patientlist,'Value',M.ui.listselect); end

disp('Refreshing clinical list...');
% refresh clinical list
set(handles.clinicallist,'String',M.clinical.labels);
try set(handles.clinicallist,'Value',M.ui.clinicallist); end

if get(handles.clinicallist,'Value')>length(get(handles.clinicallist,'String'))
    set(handles.clinicallist,'Value',length(get(handles.clinicallist,'String')));
end

disp('Creating isomatrix from regressor list...');
% set isomatrix from variable in clinical list
try
    M.isomatrix=M.clinical.vars(get(handles.clinicallist,'Value'));
    M.isomatrix_name=M.clinical.labels(get(handles.clinicallist,'Value'));
catch
    M.isomatrix={};
    M.isomatrix_name={};
end

M.ui.groupdir = get(handles.groupdir_choosebox,'String');

disp('Refreshing selections on VI / FC Lists...');
% refresh selections on VI and FC Lists:
try
    vlist = get(handles.vilist,'String');
    if max(M.ui.volumeintersections) > length(vlist) || ...
        (ischar(vlist) && strcmp(vlist, 'subcortical_regions'))
        set(handles.vilist,'Value',1);
    else
        set(handles.vilist,'Value',M.ui.volumeintersections);
    end
end

try
    fclist = get(handles.fclist,'String');
    if M.ui.fibercounts > length(fclist) || ...
        (ischar(fclist) && strcmp(fclist, 'whole-brain_regions'))
        set(handles.fclist,'Value',1);
    else
        set(handles.fclist,'Value',M.ui.fibercounts);
    end
end

M.groups.group=unique(M.patient.group); % STN, GPi, Thalamus, cZi
%groupcolors=squeeze(ind2rgb(round([1:9]*(64/9)),jet));

if ~isfield(M.groups,'color')
    M.groups.color=repmat(0.7,length(M.groups.group),3);
end

if ~isequal(size(M.groups.color),[length(M.groups.group),3])
    M.groups.color=repmat(0.7,length(M.groups.group),3);
end

try set(handles.labelpopup,'Value',M.ui.labelpopup); end

disp('Adding graph metrics to connectome popup...');
% add graph metrics to connectome graph-metrics popup:
thisparc=get(handles.labelpopup,'String');

if get(handles.labelpopup,'Value')>length(get(handles.labelpopup,'String'))
    useparc=length(get(handles.labelpopup,'String'));
else
    useparc=get(handles.labelpopup,'Value');
end

thisparc=thisparc{useparc};

% modalities for VAT metrics:

% dMRI:
cnt=1;
options.prefs=ea_prefs('');
options.earoot=ea_getearoot;
try
    directory=[M.patient.list{1},filesep];
    modlist=ea_genmodlist(directory,thisparc,options);
    modlist(strncmp(modlist, 'Patient''s fMRI', length('Patient''s fMRI'))) = [];
    if ~ismember('Patient''s fiber tracts' ,modlist)
        modlist{end+1}='Patient''s fiber tracts';
    end
    modlist{end+1}='Do not calculate connectivity stats';
    set(handles.fiberspopup,'String',modlist);
    if get(handles.fiberspopup,'Value') > length(modlist)
        set(handles.fiberspopup,'Value',1);
    end
end

% update UI
disp('Updating UI...');

disp('Getting stimulation parameters...');
S=getappdata(handles.leadfigure,'S');
S=ea_checkS(M,S,options,handles);
if ~isempty(S)
    set(handles.setstimparamsbutton,'BackgroundColor',[0.1;0.8;0.1]);
    M.S=S;
    for sp=1:length(M.S) % make sure stimlabel is gs_guid.
       M.S(sp).label=['gs_',M.guid];
    end
    % M.S=ea_activecontacts(M.S);
    M.vatmodel=getappdata(handles.leadfigure,'vatmodel');
else
    set(handles.setstimparamsbutton,'BackgroundColor',[0.93,0.93,0.93]);
end

% make choosecolors button green if chosen.
if isfield(M.groups,'colorschosen')
    set(handles.choosegroupcolors,'BackgroundColor',[0.1;0.8;0.1]);
else
    set(handles.choosegroupcolors,'BackgroundColor',[0.93,0.93,0.93]);
end

% update checkboxes:
try set(handles.showactivecontcheck,'Value',M.ui.showactivecontcheck); end
try set(handles.showpassivecontcheck,'Value',M.ui.showpassivecontcheck); end
try set(handles.highlightactivecontcheck,'Value',M.ui.hlactivecontcheck); end
try set(handles.showisovolumecheck,'Value',M.ui.showisovolumecheck); end
try set(handles.statvatcheck,'Value',M.ui.statvat); end
try set(handles.colorpointcloudcheck,'Value',M.ui.colorpointcloudcheck); end
try set(handles.mirrorsides,'Value',M.ui.mirrorsides); end

% update selectboxes:
try set(handles.elrenderingpopup,'Value',M.ui.elrendering); end
try set(handles.atlassetpopup,'Value',M.ui.atlassetpopup); end

if ~isfield(M.ui,'atlassetpopup')
    M.ui.atlassetpopup=get(handles.atlassetpopup,'Value');
end

if M.ui.atlassetpopup>length(get(handles.atlassetpopup,'String'))
    M.ui.atlassetpopup=length(get(handles.atlassetpopup,'String'));
    set(handles.atlassetpopup,'Value',length(get(handles.atlassetpopup,'String')));
end

fiberspopup = get(handles.fiberspopup,'String');
if ~(ischar(fiberspopup) && strcmp(fiberspopup, 'Fibers'))
    if M.ui.fiberspopup > length(fiberspopup)
        try set(handles.fiberspopup,'Value',length(fiberspopup)); end
    else
        try set(handles.fiberspopup,'Value',M.ui.fiberspopup); end
    end
    try
    M.ui.connectomename = fiberspopup{M.ui.fiberspopup};
    end
end

try set(handles.elmodelselect,'Value',M.ui.elmodelselect); end
try set(handles.normregpopup,'Value',M.ui.normregpopup); end

% update enable-disable-dependencies:
try
    if M.ui.elrendering==3
        try set(handles.colorpointcloudcheck,'Enable','on'); end
    else
        try set(handles.colorpointcloudcheck,'Enable','off'); end
    end
end

% hide detachbutton if already detached:
try
    if M.ui.detached
        set(handles.detachbutton,'Visible','off');
    end
end

t=datetime('now');
t.Format='uuuMMddHHmmss';
t=str2double(char(t));


if 1    % ~isfield(M.ui,'lastupdated') || t-M.ui.lastupdated>240 % 4 mins time limit
    % patient specific part:
    if ~isempty(M.patient.list)
        disp('Loading localizations...');
        for pt=1:length(M.patient.list)
            % set stimparams based on values provided by user
            for side=1:2

                if M.ui.labelpopup>length(get(handles.labelpopup,'String'))
                    M.ui.labelpopup=length(get(handles.labelpopup,'String'));
                end
            end
            if isfield(M,'stimparams') % deprecated.
                M=rmfield(M,'stimparams');
            end
            % load localization
            [~,pats{pt}]=fileparts(M.patient.list{pt});

            M.elstruct(pt).group=M.patient.group(pt);
            M.elstruct(pt).groupcolors=M.groups.color;
            M.elstruct(pt).groups=M.groups.group;

            options.sides=1:2;
            options.native=0;
            try
                [options.root,options.patientname]=fileparts(M.patient.list{pt});
                options.root=[options.root,filesep];
                options = ea_resolve_elspec(options);
                if exist([options.root,options.patientname,filesep,'ea_reconstruction.mat'],'file')
                    [coords_mm,trajectory,markers,elmodel,manually_corrected,coords_acpc]=ea_load_reconstruction(options);

                    if M.ui.elmodelselect==1 % use patient specific elmodel
                        if exist('elmodel','var')
                            M.elstruct(pt).elmodel=elmodel;
                        else
                            M.elstruct(pt).elmodel='Medtronic 3389'; % use default for older reconstructions that did not store elmodel.
                        end
                    else
                        elmodels=get(handles.elmodelselect,'String');
                        M.elstruct(pt).elmodel=elmodels{get(handles.elmodelselect,'Value')};

                    end

                    % make sure coords_mm is congruent to coded electrode
                    % model:
                    poptions=options;
                    poptions.native=0;
                    poptions.elmodel=M.elstruct(pt).elmodel;
                    poptions=ea_resolve_elspec(poptions);
                    [coords_mm,trajectory,markers]=ea_resolvecoords(markers,poptions,0);

                    M.elstruct(pt).coords_mm=coords_mm;
                    M.elstruct(pt).coords_acpc=coords_acpc;
                    M.elstruct(pt).trajectory=trajectory;

                    M.elstruct(pt).name=[pats{pt}];
                    if ~exist('markers','var') % backward compatibility to old recon format

                        for side=1:2
                            markers(side).head=coords_mm{side}(1,:);
                            markers(side).tail=coords_mm{side}(4,:);
                            normtrajvector=(markers(side).tail-markers(side).head)./norm(markers(side).tail-markers(side).head);
                            orth=null(normtrajvector)*(options.elspec.lead_diameter/2);
                            markers(side).x=coords_mm{side}(1,:)+orth(:,1)';
                            markers(side).y=coords_mm{side}(1,:)+orth(:,2)'; % corresponding points in reality
                        end
                    end
                    M.elstruct(pt).markers=markers;
                end
            catch
                if pt>1 % first patient has worked but some other patient seems not to have worked.
                    try
                        if ~M.ui.detached
                        M.elstruct(1).coords_mm; % probe if error happens in pt. 1 ? if not show warning
                        warning(['No reconstruction present for ',pats{pt},'. Please check.']);
                        end
                    end
                end
            end
        end

        % load stats for group
        disp('Loading stats for group...');
        for pt=1:length(M.patient.list)
            % (re-)load stats
            try
                load([M.patient.list{pt},filesep,'ea_stats']);
                ea_stats=ea_rmssstimulations(ea_stats,M); % only preserve stimulations with label 'gs_groupid'.
                M.stats(pt).ea_stats=ea_stats;
                if isfield(M.stats(pt).ea_stats.atlases,'rebuild') % old stats format with complete atlas table - delete, will lead to large M file
                   M.stats(pt).ea_stats=rmfield(M.stats(pt).ea_stats,'atlases');
                   M.stats(pt).ea_stats.atlases.names=ea_stats.atlases.names;
                   M.stats(pt).ea_stats.atlases.types=ea_stats.atlases.types;

                   % also correct single subject file:
                   load([M.patient.list{pt},filesep,'ea_stats']);
                   ea_stats.atlases=M.stats(pt).ea_stats.atlases;
                   save([M.patient.list{pt},filesep,'ea_stats'],'ea_stats','-v7.3');
                end
            end

            if ~isfield(M,'stats')
                % if no stats  present yet, return.
                setappdata(handles.leadfigure,'M',M);
                set(handles.leadfigure,'name','Lead-Group Analysis');
                break
            end

            priorvilist=M.vilist;
            try % try using stats from patient folder.
                M.vilist=ea_stats.atlases.names;
            catch
                try % try using stats from M-file.
                    M.vilist=M.stats(pt).ea_stats.atlases.names;
                catch
                    M.vilist={};
                end
            end

            %disp('Comparing stats with prior atlas intersection list...');
            % check and compare with prior atlas intersection list.

            if ~isempty(priorvilist) && ~isequal(priorvilist,M.vilist)

                warning('Patient stats are inhomogeneous. Please re-run group analysis (Section Prepare DBS stats).');
            end

            priorfclist=M.fclist;
            try % try using stats from patient folder.
                M.fclist=ea_stats.stimulation(1).ft(1).labels{1};
                fcdone=1;
            catch
                try % try using stats from M-file.
                    M.fclist=M.stats(pt).ea_stats.stimulation(1).ft(1).labels{1};
                    fcdone=1;
                catch
                    M.fclist={};
                    fcdone=0;
                end
            end

            % check and compare with prior fibertracking list.
            if fcdone
                if ~isempty(priorfclist) && ~isequal(priorfclist,M.fclist)
                    warning('Trying to analyse inhomogeneous patient group. Please re-run single subject lead analysis with patients using always the same labeling atlas.');
                end
            end
        end

        try
            setappdata(handles.leadfigure,'elstruct',elstruct);
        end
    else
        M.vilist={};
        M.fclist={};
    end
end

% store everything in Model
disp('Storing everything in model...');
if ~isempty(M.patient.list)
t=datetime('now');
t.Format='uuuMMddHHmmss';
M.ui.lastupdated=str2double(char(t));
setappdata(handles.leadfigure,'M',M);
end
% refresh UI
if ~isempty(M.vilist)
    set(handles.vilist,'String',M.vilist);
end

if ~isempty(M.fclist)
    set(handles.fclist,'String',M.fclist);
end

disp('Done.');

ea_busyaction('off',handles.leadfigure,'group');


function S=ea_checkS(M,S,options,handles) % helper to check that S has equally many entries as M.patient.list
if ~(length(S)==length(M.patient.list))
    if isempty(S)    % will init a blank S struct
        S=ea_initializeS(['gs_',M.guid],options,handles);
        S(1:length(M.patient.list))=S(1);
    else
        %ea_error('Stimulation parameter struct not matching patient list. Lead group file potentially corrupted.');
    end
end


function ea_stats=ea_rmssstimulations(ea_stats,M)
% function that will remove all stimulations not labeled 'gs'
todel=[];
for s=1:length(ea_stats.stimulation)
    if ~strcmp(ea_stats.stimulation(s).label,['gs_',M.guid])
        todel=[todel,s];
    end
end
ea_stats.stimulation(todel)=[];
