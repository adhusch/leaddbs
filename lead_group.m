function varargout = lead_group(varargin)
% LEAD_GROUP MATLAB code for lead_group.fig
%      LEAD_GROUP, by itself, creates a new LEAD_GROUP or raises the existing
%      singleton*.
%
%      H = LEAD_GROUP returns the handle to a new LEAD_GROUP or the handle to
%      the existing singleton*.
%
%      LEAD_GROUP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LEAD_GROUP.M with the given input arguments.
%
%      LEAD_GROUP('Property','Value',...) creates a new LEAD_GROUP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lead_group_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lead_group_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lead_group

% Last Modified by GUIDE v2.5 16-Mar-2019 14:19:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @lead_group_OpeningFcn, ...
    'gui_OutputFcn',  @lead_group_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before lead_group is made visible.
function lead_group_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lead_group (see VARARGIN)

% add recent groups...
ea_initrecentpatients(handles, 'groups');

% Choose default command line output for lead_group
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes lead_group wait for user response (see UIRESUME)
% uiwait(handles.leadfigure);

options.earoot = ea_getearoot;
options.prefs = ea_prefs('');
setappdata(handles.leadfigure,'earoot',options.earoot);

% Build popup tables:

% atlassets:
atlases = dir(ea_space(options,'atlases'));
atlases = {atlases(cell2mat({atlases.isdir})).name};
atlases = atlases(cellfun(@(x) ~strcmp(x(1),'.'), atlases));
atlases{end+1} = 'Use none';

set(handles.atlassetpopup,'String', atlases);
[~, defix]=ismember(options.prefs.atlases.default, atlases);
if defix
set(handles.atlassetpopup,'Value',defix);
end

% setup vat functions
cnt=1;
ndir=dir([options.earoot,'ea_genvat_*.m']);
for nd=length(ndir):-1:1
    [~,methodf]=fileparts(ndir(nd).name);
    try
        [thisndc]=eval([methodf,'(','''prompt''',')']);
        ndc{cnt}=thisndc;
        genvatfunctions{cnt}=methodf;
        cnt=cnt+1;
    end
end

setappdata(handles.leadfigure,'genvatfunctions',genvatfunctions);
setappdata(handles.leadfigure,'vatfunctionnames',ndc);

% get electrode model specs and place in popup
set(handles.elmodelselect,'String',[{'Patient specified'},ea_resolve_elspec]);

% set background image
set(gcf,'color','w');
im=imread([options.earoot,'icons',filesep,'logo_lead_group.png']);
image(im);
axis off;
axis equal;

try
    priorselection=find(ismember(fiberscell,stimparams.usefiberset)); % retrieve prior selection of fiberset.
    set(handles.fiberspopup,'Value',priorselection);
catch    % reinitialize using third entry.
    set(handles.fiberspopup,'Value',1);
end

if get(handles.fiberspopup,'Value')>length(get(handles.fiberspopup,'String'))
    set(handles.fiberspopup,'Value',length(get(handles.fiberspopup,'String')));
end

% Labels:
labeling = dir([ea_space(options,'labeling'),'*.nii']);
labeling = cellfun(@(x) {strrep(x, '.nii', '')}, {labeling.name});

set(handles.labelpopup,'String', labeling);

try
    priorselection = find(ismember(labeling, stimparams.labelatlas)); % retrieve prior selection of fiberset.
    if length(priorselection) == 1
        set(handles.labelpopup,'Value',priorselection); % set to prior selection
    else % if priorselection was a cell array with more than one entry, set to use all
        set(handles.labelpopup,'Value',lab+1); % set to use all
    end
catch    % reinitialize using third entry.
    set(handles.labelpopup,'Value',1);
end

% set version text:
set(handles.versiontxt,'String',['v',ea_getvsn('local')]);

% make listboxes multiselectable:
set(handles.patientlist,'Max',100,'Min',0);
set(handles.grouplist,'Max',100,'Min',0);
set(handles.vilist,'Max',100,'Min',0);
set(handles.fclist,'Max',100,'Min',0);
set(handles.clinicallist,'Max',100,'Min',0);

if options.prefs.env.dev
    disp('Running in Developer Mode...')
    set(handles.mercheck,'Visible','on')
end

M=getappdata(gcf,'M');
if isempty(M)
    % initialize Model variable M
    M=ea_initializeM;
end
setappdata(gcf,'M',M);
ea_refresh_lg(handles);

handles.prod='group';
ea_firstrun(handles,options);

ea_menu_initmenu(handles,{'prefs','transfer','group'});

ea_processguiargs(handles,varargin)

ea_bind_dragndrop(handles.leadfigure, ...
    @(obj,evt) DropFcn(obj,evt,handles), ...
    @(obj,evt) DropFcn(obj,evt,handles));


% --- Drag and drop callback to load patdirs.
function DropFcn(~, event, handles)

% check if dropping area is in patient listbox
if event.Location.getX < 325 && event.Location.getX > 24 && ...
   event.Location.getY < 322 && event.Location.getY > 137
    target = 'patientList';
else
    target = 'groupDir';
end

switch event.DropType
    case 'file'
        folders = event.Data;
    case 'string'
        folders = {event.Data};
end

if strcmp(target, 'groupDir')
    % Save data for previous selected group folder
    if ~strcmp(get(handles.groupdir_choosebox,'String'),'Choose Group Directory') % group dir still not chosen
        ea_busyaction('on',handles.leadfigure,'group');
        disp('Saving data...');
        % save M
        ea_refresh_lg(handles);
        M=getappdata(handles.leadfigure,'M');
        disp('Saving data to disk...');
        try
            save([get(handles.groupdir_choosebox,'String'),'LEAD_groupanalysis.mat'],'M','-v7.3');
        catch
            warning('Data could not be saved.');
            keyboard
        end
        disp('Done.');
        ea_busyaction('off',handles.leadfigure,'group');
    end

    if length(folders) > 1
        ea_error('To choose the group analysis directory, please drag a single folder into Lead Group!', 'Error', dbstack);
    end
    if ~exist(folders{1}, 'dir')
        [pth,fn,ext]=fileparts(folders{1});

        if strcmp(fn,'LEAD_groupanalysis') && strcmp(ext,'.mat') && exist(pth, 'dir')
            folders{1}=pth;
        else
            ea_error('To choose the group analysis directory, please drag a single folder into Lead Group!', 'Error', dbstack);

        end
    end

    groupdir = [folders{1}, filesep];
    set(handles.groupdir_choosebox, 'String', groupdir);
    set(handles.groupdir_choosebox, 'TooltipString', groupdir);

    ea_busyaction('on',handles.leadfigure,'group');

    M=ea_initializeM;
    M.ui.groupdir = groupdir;

    try % if file already exists, load it (and overwrite M).
        load([groupdir, 'LEAD_groupanalysis.mat']);
    catch % if not, store it saving M.
        save([groupdir, 'LEAD_groupanalysis.mat'],'M','-v7.3');
    end

    setappdata(handles.leadfigure,'M',M);
    try
        setappdata(handles.leadfigure,'S',M.S);
        setappdata(handles.leadfigure,'vatmodel',M.S(1).model);
    end

    ea_busyaction('off',handles.leadfigure,'group');
    ea_refresh_lg(handles);
else
    if strcmp(get(handles.groupdir_choosebox,'String'), 'Choose Group Directory')
        ea_error('Please choose a group directory first to store the group analysis!', 'Error', dbstack)
    end

    nonexist = cellfun(@(x) ~exist(x, 'dir'), folders);
    if any(nonexist)
        fprintf('\nExcluded non-existent/invalid folder:\n');
        cellfun(@disp, folders(nonexist));
        fprintf('\n');
        folders(nonexist) = [];
    end

    if ~isempty(folders)
        M=getappdata(handles.leadfigure,'M');

        M.patient.list=[M.patient.list; folders];
        M.patient.group=[M.patient.group; ones(length(folders),1)];
        options=ea_setopts_local(handles);

        tS=ea_initializeS(['gs_',M.guid],options,handles);
        if isempty(M.S)
            M=rmfield(M,'S');
            M.S(1:length(folders))=tS;
        else
            M.S(end+1:end+length(folders))=tS;
        end
        setappdata(handles.leadfigure, 'M', M);
        ea_refresh_lg(handles);
        % save M
        M=getappdata(handles.leadfigure,'M');
        save([get(handles.groupdir_choosebox,'String'),'LEAD_groupanalysis.mat'],'M','-v7.3');
    end
end


% --- Outputs from this function are returned to the command line.
function varargout = lead_group_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in patientlist.
function patientlist_Callback(hObject, eventdata, handles)
% hObject    handle to patientlist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns patientlist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from patientlist
M=getappdata(gcf,'M');

M.ui.listselect=get(handles.patientlist,'Value');
set(handles.grouplist,'Value',M.ui.listselect);

setappdata(gcf,'M',M);
ea_refresh_lg(handles);



% --- Executes during object creation, after setting all properties.
function patientlist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to patientlist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addptbutton.
function addptbutton_Callback(hObject, eventdata, handles)
% hObject    handle to addptbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(handles.groupdir_choosebox,'String'), 'Choose Group Directory')
    ea_error('Please choose a group directory first to store the group analysis!', 'Error', dbstack)
end

M=getappdata(handles.leadfigure,'M');

folders=ea_uigetdir(ea_startpath,'Select Patient folders..');
M.patient.list=[M.patient.list;folders'];
M.patient.group=[M.patient.group;ones(length(folders),1)];
options=ea_setopts_local(handles);

tS=ea_initializeS(['gs_',M.guid],options,handles);

if isempty(M.S)
    M=rmfield(M,'S');
    M.S(1:length(folders))=tS;
else
    try
    M.S(end+1:end+length(folders))=tS;
    catch
        tS.volume=[0,0];
        tS.sources=[1:4];
            M.S(end+1:end+length(folders))=tS;
    end
end

setappdata(handles.leadfigure,'M',M);
setappdata(handles.leadfigure,'S',M.S);
ea_refresh_lg(handles);
% save M
M=getappdata(handles.leadfigure,'M');
save([get(handles.groupdir_choosebox,'String'),'LEAD_groupanalysis.mat'],'M','-v7.3');


% --- Executes on button press in removeptbutton.
function removeptbutton_Callback(hObject, eventdata, handles)
% hObject    handle to removeptbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
M=getappdata(handles.leadfigure,'M');

deleteentry=get(handles.patientlist,'Value');

M.patient.list(deleteentry)=[];

M.patient.group(deleteentry)=[];

try M.elstruct(deleteentry)=[]; end

for cvar=1:length(M.clinical.vars)
    try
        M.clinical.vars{cvar}(deleteentry,:)=[];
    end
end

if isfield(M,'S')
    try
    M.S(deleteentry)=[];
    end
    setappdata(handles.leadfigure, 'S', M.S);
end

try
    M.stats(deleteentry)=[];
end
setappdata(handles.leadfigure,'M',M);
ea_refresh_lg(handles);


% --- Executes on button press in vizbutton.
function vizbutton_Callback(hObject, eventdata, handles)
% hObject    handle to vizbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clc;
M=getappdata(gcf,'M');
ea_busyaction('on',handles.leadfigure,'group');
% set options
options=ea_setopts_local(handles);
options.leadprod = 'group';
% set pt specific options
options.root=[fileparts(fileparts(get(handles.groupdir_choosebox,'String'))),filesep];
[~,options.patientname]=fileparts(fileparts(get(handles.groupdir_choosebox,'String')));

options.expstatvat.do=M.ui.statvat;
options.native=0;

try
    options.numcontacts=size(M.elstruct(1).coords_mm{1},1);
catch
    warning('Localizations seem not properly defined.');
end

options.elmodel=M.elstruct(1).elmodel;
options=ea_resolve_elspec(options);
options.prefs=ea_prefs(options.patientname);
options.d3.verbose='on';

options.d3.elrendering=M.ui.elrendering;
options.d3.hlactivecontacts=get(handles.highlightactivecontcheck,'Value');
options.d3.showactivecontacts=get(handles.showactivecontcheck,'Value');
options.d3.showpassivecontacts=get(handles.showpassivecontcheck,'Value');
options.d3.mirrorsides=get(handles.mirrorsides,'Value');
try options.d3.isomatrix=M.isomatrix; end
try options.d3.isomatrix_name=M.isomatrix_name; end

options.d2.write=0;

options.d2.atlasopacity=0.15;

options.d3.isovscloud=M.ui.isovscloudpopup;
options.d3.showisovolume=M.ui.showisovolumecheck;

options.d3.colorpointcloud=M.ui.colorpointcloudcheck;
options.d3.exportBB=0;	% don't export brainbrowser struct by default

options.normregressor=M.ui.normregpopup;

% Prepare isomatrix (includes a normalization step if M.ui.normregpopup
% says so:

for reg=1:length(options.d3.isomatrix)
    try options.d3.isomatrix{reg}=ea_reformat_isomatrix(options.d3.isomatrix{reg},M,options); end
end
if ~strcmp(get(handles.groupdir_choosebox,'String'),'Choose Group Directory') % group dir still not chosen
    disp('Saving data...');
    % save M
    save([get(handles.groupdir_choosebox,'String'),'LEAD_groupanalysis.mat'],'M','-v7.3');
    disp('Done.');
end

% export VAT-mapping
if options.expstatvat.do % export to nifti volume
    ea_exportvatmapping(M,options,handles);
end
options.groupmode=1;

% overwrite active contacts information with new one from S (if present).
ptidx=get(handles.patientlist,'Value');
try
    for pt=1:length(M.elstruct)
        M.elstruct(pt).activecontacts=M.S(pt).activecontacts;
    end
end

try
    for pt=1:length(M.elstruct)
        M.elstruct(pt).groupcolors=M.groups.color;
    end
end
options.groupmode=1;
options.modality=3; % use template image
options.patient_list=M.patient.list;

% mer development
vizstruct.elstruct=M.elstruct(ptidx);
uipatdirs=handles.patientlist.String(ptidx);
npts=length(uipatdirs);
if options.prefs.env.dev && get(handles.mercheck,'Value')
    filename=fullfile(options.root,options.patientname,'ea_groupvisdata.mat');
    if exist(filename,'file')
       choice = ea_questdlg(sprintf('Group Data Found. Would you like to load %s now?',filename),...
           'Yes','No');
    end

    % Get vizstruct
    if ~exist('choice','var') || strcmpi(choice,'No')

        for pt=1:length(M.elstruct)
            options.uipatdirs{1}=uipatdirs{pt};
            M.merstruct(pt)=ea_getmerstruct(options);
        end

        for pt=1:length(M.elstruct)
            ea_progress(pt/npts, 'Loading microelectrode recordings from patient %d of %d\n', pt, npts);
            M.merstruct(pt).group=handles.grouplist.String(pt);
            [M.merstruct(pt).root,M.merstruct(pt).name]=fileparts(uipatdirs{pt});
            M.merstruct(pt).root(end+1)=filesep;
            M.merstruct(pt).ptdir=uipatdirs{pt};
            mua=load(fullfile(uipatdirs{pt},'ea_recordings.mat'));

            try
                mua.right=rmfield(mua.right,'CSPK');
                mua.left=rmfield(mua.left,'CSPK');
            catch
                mua.right=rmfield(mua.right,'CElectrode');
                mua.left=rmfield(mua.left,'CElectrode');
            end

            M.merstruct(pt).mua=mua;
        end
        disp('**Done loading')
        options = rmfield(options,'uipatdirs');
        vizstruct.merstruct=M.merstruct(ptidx);

        save(fullfile(options.root,options.patientname,'ea_groupelvisdata.mat'),...
            'options','vizstruct');

    elseif strcmpi(choice,'Yes')

        load(filename,'vizstruct')

    end

end

% amend .pt to identify which patient is selected (needed for isomatrix).
for pt=1:length(ptidx)
    M.elstruct(ptidx(pt)).pt=ptidx(pt);
end

whichelmodel=get(handles.elmodelselect,'String');
whichelmodel=whichelmodel{get(handles.elmodelselect,'Value')};
% account for electrode model specified in lead group
if ~strcmp(whichelmodel,'Patient specified')
    arcell=repmat({whichelmodel},length(ptidx),1);
   [M.elstruct(ptidx).elmodel]=arcell{:};
end

resultfig=ea_elvis(options,M.elstruct(ptidx));

try % zoom on coordinates.
    coords={M.elstruct(:).coords_mm};
    for c=1:length(coords)
        call(c,:)=mean([coords{c}{1};coords{c}{2}]);
    end
    ea_zoomcenter(resultfig.CurrentAxes, mean(call), 5);
catch
    zoom(3);
end

% show VAT-mapping
if options.expstatvat.do % export to nifti volume
    pobj.plotFigureH=resultfig;
    pobj.color=[0.9,0.2,0.3];

    pobj.openedit=1;
    hshid=ea_datahash(M.ui.listselect);
    ea_roi([options.root,options.patientname,filesep,'statvat_results',filesep,'models',filesep,'statvat_',M.clinical.labels{M.ui.clinicallist},'_T_nthresh_',hshid,'.nii'],pobj);
end

if get(handles.showdiscfibers,'Value') % show discriminative fibers
    M.ui.connectomename=get(handles.fiberspopup,'String');
    M.ui.connectomename=M.ui.connectomename{get(handles.fiberspopup,'Value')};
    discfiberssetting = options.prefs.machine.lg.discfibers;
    fibsweighted=ea_discfibers_calcdiscfibers(M,discfiberssetting);
    ea_discfibers_showdiscfibers(M,discfiberssetting,resultfig,fibsweighted);
    set(0, 'CurrentFigure', resultfig);
end

ea_busyaction('off',handles.leadfigure,'group');


% --- Executes on button press in corrbutton_vta.
function corrbutton_vta_Callback(hObject, eventdata, handles)
% hObject    handle to corrbutton_vta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ea_busyaction('on',gcf,'group');

stats=preparedataanalysis_vta(handles);


assignin('base','stats',stats);
M=getappdata(handles.leadfigure,'M');

% perform correlations:


if size(stats.corrcl,2)==1 % one value per patient
    try stats.vicorr.nboth=(stats.vicorr.nboth/2)*100; end
    try stats.vicorr.nright=(stats.vicorr.nright/2)*100; end
    try stats.vicorr.nleft=(stats.vicorr.nleft/2)*100; end

    if ~isempty(stats.vicorr.both)
        %ea_corrplot([stats.corrcl,stats.vicorr.both],'Volume Intersections, both hemispheres',stats.vc_labels);
        %ea_corrplot([stats.corrcl,stats.vicorr.nboth],'VI_BH',stats.vc_labels,handles);
        description='Normalized Volume Impacts, both hemispheres';
        [h,R,p]=ea_corrplot(stats.corrcl,stats.vicorr.nboth,[{description},stats.vc_labels],'permutation',M.patient.group(M.ui.listselect));
        description='Volume Impacts, both hemispheres';
        [h,R,p]=ea_corrplot(stats.corrcl,stats.vicorr.both,[{description},stats.vc_labels],'permutation',M.patient.group(M.ui.listselect));

        odir=get(handles.groupdir_choosebox,'String');
        [~,fn]=fileparts(stats.vc_labels{1+1});
        if strcmp(fn(end-3:end),'.nii')
            [~,fn]=fileparts(fn);
        end
        ofname=[odir,description,'_',fn,'_',stats.vc_labels{1},'.png'];
        ea_screenshot(ofname);
    end
    %     if ~isempty(stats.vicorr.right)
    %         %ea_corrplot([stats.corrcl,stats.vicorr.right],'Volume Intersections, right hemisphere',stats.vc_labels);
    %         ea_corrplot([stats.corrcl,stats.vicorr.nright],'VI_RH',stats.vc_labels,handles);
    %     end
    %     if ~isempty(stats.vicorr.left)
    %         %ea_corrplot([stats.corrcl,stats.vicorr.left],'Volume Intersections, left hemisphere',stats.vc_labels);
    %         ea_corrplot([stats.corrcl,stats.vicorr.nleft],'VI_LH',stats.vc_labels,handles);
    %     end

elseif size(stats.corrcl,2)==2 % one value per hemisphere
    try stats.vicorr.nboth=(stats.vicorr.nboth)*100; end
    try stats.vicorr.nright=(stats.vicorr.nright)*100; end
    try stats.vicorr.nleft=(stats.vicorr.nleft)*100; end
    if ~isempty(stats.vicorr.both)

        ea_corrplot([stats.corrcl(:),[stats.vicorr.right;stats.vicorr.left]],[{'Volume Impacts, both hemispheres'},stats.vc_labels]);
        ea_corrplot(stats.corrcl(:),[stats.vicorr.nright;stats.vicorr.nleft],[{'Normalized Volume Impacts'},stats.vc_labels]);
    end
    %     if ~isempty(stats.vicorr.right)
    %         %ea_corrplot([stats.corrcl(:,1),stats.vicorr.right],'Volume Intersections, right hemisphere',stats.vc_labels);
    %         ea_corrplot([stats.corrcl(:,1),stats.vicorr.nright],'VI_RH',stats.vc_labels,handles);
    %     end
    %     if ~isempty(stats.vicorr.left)
    %         %ea_corrplot([stats.corrcl(:,2),stats.vicorr.left],'Volume Intersections, left hemisphere',stats.vc_labels);
    %         ea_corrplot([stats.corrcl(:,2),stats.vicorr.nleft],'VI_LH',stats.vc_labels,handles);
    %     end

else
    ea_error('Please select a regressor with one value per patient or per hemisphere to perform this correlation.');
end
ea_busyaction('off',gcf,'group');



% --- Executes on selection change in clinicallist.
function clinicallist_Callback(hObject, eventdata, handles)
% hObject    handle to clinicallist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns clinicallist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from clinicallist
M=getappdata(gcf,'M');

M.ui.clinicallist=get(handles.clinicallist,'Value');
setappdata(gcf,'M',M);
ea_refresh_lg(handles);

% --- Executes during object creation, after setting all properties.
function clinicallist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to clinicallist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addvarbutton.
function addvarbutton_Callback(hObject, eventdata, handles)
% hObject    handle to addvarbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
M=getappdata(gcf,'M');
M.ui.clinicallist=length(M.clinical.labels)+1;
[numat,nuvar]=ea_get_clinical(M);
if ~isempty(numat) % user did not press cancel
    M.clinical.vars{end+1}=numat;
    M.clinical.labels{end+1}=nuvar;
end
set(handles.clinicallist,'Value',M.ui.clinicallist);
% store model and refresh UI
setappdata(gcf,'M',M);

ea_refresh_lg(handles);


function [mat,matname]=ea_get_clinical(M)
try
    mat=M.clinical.vars{M.ui.clinicallist};
catch % new variable
    mat=[];
end
try
    matname=M.clinical.labels{M.ui.clinicallist};
catch
    matname='New variable';
end
[numat,nuname]=ea_edit_regressor(M);

if ~isempty(numat) % user did not press cancel
    mat=numat;
    matname=nuname;
end

% --- Executes on button press in removevarbutton.
function removevarbutton_Callback(hObject, eventdata, handles)
% hObject    handle to removevarbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
M=getappdata(gcf,'M');

% delete data
M.clinical.vars(get(handles.clinicallist,'Value'))=[];
M.clinical.labels(get(handles.clinicallist,'Value'))=[];

% store model and refresh UI
setappdata(gcf,'M',M);
ea_refresh_lg(handles);


% --- Executes on selection change in vilist.
function vilist_Callback(hObject, eventdata, handles)
% hObject    handle to vilist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns vilist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from vilist
M=getappdata(gcf,'M');

M.ui.volumeintersections=get(handles.vilist,'Value');

% store model and refresh UI
setappdata(gcf,'M',M);
ea_refresh_lg(handles);


% --- Executes during object creation, after setting all properties.
function vilist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vilist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in fclist.
function fclist_Callback(hObject, eventdata, handles)
% hObject    handle to fclist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns fclist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from fclist
M=getappdata(gcf,'M');


M.ui.fibercounts=get(handles.fclist,'Value');

% store model and refresh UI
setappdata(gcf,'M',M);
ea_refresh_lg(handles);

% --- Executes during object creation, after setting all properties.
function fclist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fclist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function [pathname] = ea_uigetdir(start_path, dialog_title)
% Pick a directory with the Java widgets instead of uigetdir

import javax.swing.JFileChooser;

if nargin == 0 || strcmp(start_path,'') % || start_path == 0 % Allow a null argument.
    start_path = pwd;
end

jchooser = javaObjectEDT('javax.swing.JFileChooser', start_path);

jchooser.setFileSelectionMode(JFileChooser.FILES_AND_DIRECTORIES);
if nargin > 1
    jchooser.setDialogTitle(dialog_title);
end

jchooser.setMultiSelectionEnabled(true);

status = jchooser.showOpenDialog([]);

if status == JFileChooser.APPROVE_OPTION
    jFile = jchooser.getSelectedFiles();
    pathname{size(jFile, 1)}=[];
    for i=1:size(jFile, 1)
        pathname{i} = char(jFile(i).getAbsolutePath);
    end

elseif status == JFileChooser.CANCEL_OPTION
    pathname = [];
else
    error('Error occured while picking file.');
end






% --- Executes on selection change in grouplist.
function grouplist_Callback(hObject, eventdata, handles)
% hObject    handle to grouplist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns grouplist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from grouplist
M=getappdata(gcf,'M');

M.ui.listselect=get(handles.grouplist,'Value');

set(handles.patientlist,'Value',M.ui.listselect);

setappdata(gcf,'M',M);
ea_refresh_lg(handles);




% --- Executes during object creation, after setting all properties.
function grouplist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to grouplist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in plusgroupbutton.
function plusgroupbutton_Callback(hObject, eventdata, handles)
% hObject    handle to plusgroupbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
M=getappdata(gcf,'M');
M.patient.group(get(handles.patientlist,'Value'))=M.patient.group(get(handles.patientlist,'Value'))+1;
setappdata(gcf,'M',M);
ea_refresh_lg(handles);



% --- Executes on button press in minusgroupbutton.
function minusgroupbutton_Callback(hObject, eventdata, handles)
% hObject    handle to minusgroupbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
M=getappdata(gcf,'M');
if M.patient.group(get(handles.patientlist,'Value'))>1
    M.patient.group(get(handles.patientlist,'Value'))=M.patient.group(get(handles.patientlist,'Value'))-1;
end
setappdata(gcf,'M',M);
ea_refresh_lg(handles);


% --- Executes on button press in ttestbutton_vta.
function ttestbutton_vta_Callback(hObject, eventdata, handles)
% hObject    handle to ttestbutton_vta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


stats=preparedataanalysis_vta(handles);

assignin('base','stats',stats);

% perform t-tests:

if ~isempty(stats.vicorr.both)
    ea_ttest(stats.vicorr.both(repmat(logical(stats.corrcl),1,size(stats.vicorr.both,2))),stats.vicorr.both(~repmat(logical(stats.corrcl),1,size(stats.vicorr.both,2))),'Volume Intersections, both hemispheres',stats.vc_labels);
end
if ~isempty(stats.vicorr.right)
    ea_ttest(stats.vicorr.right(repmat(logical(stats.corrcl),1,size(stats.vicorr.right,2))),stats.vicorr.right(~repmat(logical(stats.corrcl),1,size(stats.vicorr.right,2))),'Volume Intersections, right hemisphere',stats.vc_labels);
end
if ~isempty(stats.vicorr.left)
    ea_ttest(stats.vicorr.left(repmat(logical(stats.corrcl),1,size(stats.vicorr.left,2))),stats.vicorr.left(~repmat(logical(stats.corrcl),1,size(stats.vicorr.left,2))),'Volume Intersections, left hemisphere',stats.vc_labels);
end


if ~isempty(stats.vicorr.nboth)
    ea_ttest(stats.vicorr.nboth(repmat(logical(stats.corrcl),1,size(stats.vicorr.both,2))),stats.vicorr.nboth(~repmat(logical(stats.corrcl),1,size(stats.vicorr.both,2))),'Normalized Volume Intersections, both hemispheres',stats.vc_labels);
end
if ~isempty(stats.vicorr.nright)
    ea_ttest(stats.vicorr.nright(repmat(logical(stats.corrcl),1,size(stats.vicorr.right,2))),stats.vicorr.nright(~repmat(logical(stats.corrcl),1,size(stats.vicorr.right,2))),'Normalized Volume Intersections, right hemisphere',stats.vc_labels);
end
if ~isempty(stats.vicorr.nleft)
    ea_ttest(stats.vicorr.nleft(repmat(logical(stats.corrcl),1,size(stats.vicorr.left,2))),stats.vicorr.nleft(~repmat(logical(stats.corrcl),1,size(stats.vicorr.left,2))),'Normalized Volume Intersections, left hemisphere',stats.vc_labels);
end



function [stats]=preparedataanalysis_ft(handles)

M=getappdata(gcf,'M');


%M.stats(get(handles.vilist,'Value'))

% Get volume intersections:
vicnt=1; ptcnt=1;

howmanypts=length(get(handles.patientlist,'Value'));



% Get fibercounts (here first ft is always right hemispheric, second always left hemispheric). There will always be two fts used.:
howmanyfcs=length(get(handles.fclist,'Value'));

fccnt=1; ptcnt=1;
fccorr_right=zeros(howmanypts,howmanyfcs);
nfccorr_right=zeros(howmanypts,howmanyfcs);
fccorr_left=zeros(howmanypts,howmanyfcs);
nfccorr_left=zeros(howmanypts,howmanyfcs);
fccorr_both=zeros(howmanypts,howmanyfcs);
nfccorr_both=zeros(howmanypts,howmanyfcs);
fc_labels={};
for fc=get(handles.fclist,'Value') % get volume interactions for each patient from stats
    for pt=get(handles.patientlist,'Value')
        usewhichstim=length(M.stats(pt).ea_stats.stimulation); % always use last analysis!
        fccorr_right(ptcnt,fccnt)=M.stats(pt).ea_stats.stimulation(usewhichstim).ft(1).fibercounts{1}(fc);
        nfccorr_right(ptcnt,fccnt)=M.stats(pt).ea_stats.stimulation(usewhichstim).ft(1).nfibercounts{1}(fc);
        fccorr_left(ptcnt,fccnt)=M.stats(pt).ea_stats.stimulation(usewhichstim).ft(2).fibercounts{1}(fc);
        nfccorr_left(ptcnt,fccnt)=M.stats(pt).ea_stats.stimulation(usewhichstim).ft(2).nfibercounts{1}(fc);
        fccorr_both(ptcnt,fccnt)=M.stats(pt).ea_stats.stimulation(usewhichstim).ft(1).fibercounts{1}(fc)+M.stats(pt).ea_stats.stimulation(usewhichstim).ft(2).fibercounts{1}(fc);
        nfccorr_both(ptcnt,fccnt)=M.stats(pt).ea_stats.stimulation(usewhichstim).ft(1).nfibercounts{1}(fc)+M.stats(pt).ea_stats.stimulation(usewhichstim).ft(2).nfibercounts{1}(fc);
        ptcnt=ptcnt+1;
    end
    ptcnt=1;
    fccnt=fccnt+1;
    fc_labels{end+1}=M.stats(pt).ea_stats.stimulation(usewhichstim).ft(1).labels{1}{fc};
end

% prepare outputs:

fccorr.both=fccorr_both;
fccorr.nboth=nfccorr_both;
fccorr.right=fccorr_right;
fccorr.nright=nfccorr_right;
fccorr.left=fccorr_left;
fccorr.nleft=nfccorr_left;

% clinical vector:
corrcl=M.clinical.vars{get(handles.clinicallist,'Value')};

corrcl=corrcl(get(handles.patientlist,'Value'),:);

clinstrs=get(handles.clinicallist,'String');
fc_labels=[clinstrs(get(handles.clinicallist,'Value')),fc_labels]; % add name of clinical vector to labels


stats.corrcl=corrcl;
stats.fccorr=fccorr;
stats.fc_labels=fc_labels;
function [stats]=preparedataanalysis_vta(handles)

M=getappdata(gcf,'M');


%M.stats(get(handles.vilist,'Value'))

% Get volume intersections:
vicnt=1; ptcnt=1;

howmanyvis=length(get(handles.vilist,'Value'));
howmanypts=length(get(handles.patientlist,'Value'));

vicorr_right=zeros(howmanypts,howmanyvis); vicorr_left=zeros(howmanypts,howmanyvis); vicorr_both=zeros(howmanypts,howmanyvis);
nvicorr_right=zeros(howmanypts,howmanyvis); nvicorr_left=zeros(howmanypts,howmanyvis); nvicorr_both=zeros(howmanypts,howmanyvis);
vc_labels={};

switch get(handles.VTAvsEfield,'value')
    case 1 % VTA
        vtavsefield='vat';
    case 2 % Efield
        vtavsefield='efield';
end


for vi=get(handles.vilist,'Value') % get volume interactions for each patient from stats
    for pt=get(handles.patientlist,'Value')
        S.label=['gs_',M.guid];
        try
        [ea_stats,usewhichstim]=ea_assignstimcnt(M.stats(pt).ea_stats,S);

        for side=1:size(M.stats(pt).ea_stats.stimulation(usewhichstim).vat,1)
            for vat=1
                if side==1 % right hemisphere
                    vicorr_right(ptcnt,vicnt)=vicorr_right(ptcnt,vicnt)+M.stats(pt).ea_stats.stimulation(usewhichstim).(vtavsefield)(side,vat).AtlasIntersection(vi);
                    nvicorr_right(ptcnt,vicnt)=nvicorr_right(ptcnt,vicnt)+M.stats(pt).ea_stats.stimulation(usewhichstim).(vtavsefield)(side,vat).nAtlasIntersection(vi);

                    elseif side==2 % left hemisphere
                    vicorr_left(ptcnt,vicnt)=vicorr_left(ptcnt,vicnt)+M.stats(pt).ea_stats.stimulation(usewhichstim).(vtavsefield)(side,vat).AtlasIntersection(vi);
                    nvicorr_left(ptcnt,vicnt)=nvicorr_left(ptcnt,vicnt)+M.stats(pt).ea_stats.stimulation(usewhichstim).(vtavsefield)(side,vat).nAtlasIntersection(vi);
                end
                vicorr_both(ptcnt,vicnt)=vicorr_both(ptcnt,vicnt)+M.stats(pt).ea_stats.stimulation(usewhichstim).(vtavsefield)(side,vat).AtlasIntersection(vi);
                nvicorr_both(ptcnt,vicnt)=nvicorr_both(ptcnt,vicnt)+M.stats(pt).ea_stats.stimulation(usewhichstim).(vtavsefield)(side,vat).nAtlasIntersection(vi);

            end
        end
        catch
            ea_error(['DBS stats for patient ',M.patient.list{pt},' need to be calculated.']);
        end

        % check if all three values have been served. if not, set to zero
        % (e.g. if there was no stimulation at all on one hemisphere, this
        % could happen.

        ptcnt=ptcnt+1;

    end
    vc_labels{end+1}=[ea_stripext(M.stats(pt).ea_stats.atlases.names{vi}),': ',vtavsefield,' impact'];

    ptcnt=1;
    vicnt=vicnt+1;
end


% prepare outputs:

vicorr.both=vicorr_both;
vicorr.left=vicorr_left;
vicorr.right=vicorr_right;
vicorr.nboth=nvicorr_both;
vicorr.nleft=nvicorr_left;
vicorr.nright=nvicorr_right;

% clinical vector:
corrcl=M.clinical.vars{get(handles.clinicallist,'Value')};

corrcl=corrcl(get(handles.patientlist,'Value'),:);

clinstrs=get(handles.clinicallist,'String');
vc_labels=[clinstrs(get(handles.clinicallist,'Value')),vc_labels]; % add name of clinical vector to labels

stats.corrcl=corrcl;
stats.vicorr=vicorr;
stats.vc_labels=vc_labels;


% --- Executes on button press in reviewvarbutton.
function reviewvarbutton_Callback(hObject, eventdata, handles)
% hObject    handle to reviewvarbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
M=getappdata(gcf,'M');

% store in model as variables

%M.clinical.vars{get(handles.clinicallist,'Value')}(isnan(M.clinical.vars{get(handles.clinicallist,'Value')}))=0;
[M.clinical.vars{get(handles.clinicallist,'Value')},M.clinical.labels{get(handles.clinicallist,'Value')}]=ea_get_clinical(M);


% store model and refresh UI
setappdata(gcf,'M',M);

ea_refresh_lg(handles);


% --- Executes on button press in moveptupbutton.
function moveptupbutton_Callback(hObject, eventdata, handles)
% hObject    handle to moveptupbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
M=getappdata(gcf,'M');
whichmoved=get(handles.patientlist,'Value');

if whichmoved(1)==1 % first entry anyways
    return
end

ix=1:length(M.patient.list);
ix(whichmoved)=ix(whichmoved)-1;
ix(whichmoved-1)=ix(whichmoved-1)+1;

M.patient.list=M.patient.list(ix);
M.patient.group=M.patient.group(ix);
M.ui.listselect=whichmoved-1;
for c=1:length(M.clinical.vars)
    M.clinical.vars{c} = M.clinical.vars{c}(ix,:);
end
try
    M.S = M.S(ix);
end
try
    M=rmfield(M,'elstruct');
end
try
    M=rmfield(M,'stats');
end
setappdata(gcf,'M',M);

set(handles.patientlist,'Value',whichmoved-1);
ea_refresh_lg(handles);


% --- Executes on button press in moveptdownbutton.
function moveptdownbutton_Callback(hObject, eventdata, handles)
% hObject    handle to moveptdownbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

M=getappdata(gcf,'M');
whichmoved=get(handles.patientlist,'Value');

if whichmoved(end)==length(M.patient.list) % last entry anyways
    return
end

ix=1:length(M.patient.list);
ix(whichmoved)=ix(whichmoved)+1;
ix(whichmoved+1)=ix(whichmoved+1)-1;

M.patient.list=M.patient.list(ix);
M.patient.group=M.patient.group(ix);
M.ui.listselect=whichmoved+1;
for c=1:length(M.clinical.vars)
    M.clinical.vars{c} = M.clinical.vars{c}(ix,:);
end
try
    M.S = M.S(ix);
end
try
    M=rmfield(M,'elstruct');
end
try
    M=rmfield(M,'stats');
end
setappdata(gcf,'M',M);

set(handles.patientlist,'Value',whichmoved+1);
ea_refresh_lg(handles);


% --- Executes on button press in calculatebutton.
function calculatebutton_Callback(hObject, eventdata, handles)
% hObject    handle to calculatebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ea_refresh_lg(handles);

M=getappdata(gcf,'M');

% set options
options=ea_setopts_local(handles);
%stimname=ea_detstimname(options);

options.groupmode = 1;
options.groupid = M.guid;

% determine if fMRI or dMRI
mods=get(handles.fiberspopup,'String');
mod=mods{get(handles.fiberspopup,'Value')};
switch mod
    case {'Patient''s fiber tracts', 'Patient''s fMRI time courses'}
        fibersfile=mod;
    case 'Do not calculate connectivity stats'
    otherwise % load fibertracts once and for all subs here.
        [fibersfile.fibers,fibersfile.fibersidx]=ea_loadfibertracts([ea_getconnectomebase('dmri'),mod,filesep,'data.mat']);
end

[selection]=ea_groupselectorwholelist(M.ui.listselect,M.patient.list);

for pt=selection
    % set pt specific options

    % own fileparts to support windows/mac/linux slashes even if they come
    % from a different OS.
    if ~contains(M.patient.list{pt},'/')
        lookfor='\';
    else
        lookfor='/';
    end

    slashes=strfind(M.patient.list{pt},lookfor);
    if ~isempty(slashes)
        options.patientname=M.patient.list{pt}(slashes(end)+1:end);
        options.root=M.patient.list{pt}(1:slashes(end));
    else
        options.patientname=M.patient.list{pt};
        options.root='';
    end

    fprintf('\nProcessing %s...\n\n', options.patientname);
    try
        options.numcontacts=size(M.elstruct(pt).coords_mm{1},1);
    catch % no localization present or in wrong format.
        ea_error(['Please localize ',options.patientname,' first.']);
    end
    options.elmodel=M.elstruct(pt).elmodel;
    options=ea_resolve_elspec(options);
    options.prefs=ea_prefs(options.patientname);
    options.d3.verbose='off';
    options.d3.elrendering=1;	% hard code to viz electrodes in this setting.
    options.d3.exportBB=0;	% don't export brainbrowser struct by default
    options.d3.colorpointcloud=0;
    options.native=0;

    options.d3.hlactivecontacts=get(handles.highlightactivecontcheck,'Value');
    options.d3.showactivecontacts=get(handles.showactivecontcheck,'Value');
    options.d3.showpassivecontacts=get(handles.showpassivecontcheck,'Value');
    try
        options.d3.isomatrix=M.isomatrix;
    catch
        options.d3.isomatrix={};
    end

    options.d3.isovscloud=M.ui.isovscloudpopup;
    options.d3.showisovolume=M.ui.showisovolumecheck;
    options.d3.exportBB=0;
    options.expstatvat.do=0;
    try
        options.expstatvat.vars=M.clinical.vars(M.ui.clinicallist);
        options.expstatvat.labels=M.clinical.labels(M.ui.clinicallist);
        options.expstatvat.pt=pt;
    end
    options.expstatvat.dir=M.ui.groupdir;
    processlocal=0;

    if M.ui.detached
        processlocal=1;
        mkdir([M.ui.groupdir,options.patientname]);
        options.root=M.ui.groupdir;
        %    options.patientname='tmp';
        try
            ea_stats=M.stats(pt).ea_stats;
        catch
            ea_stats=struct;
        end
        reco.mni.coords_mm=M.elstruct(pt).coords_mm;
        reco.mni.trajectory=M.elstruct(pt).trajectory;
        reco.mni.markers=M.elstruct(pt).markers;
        reco.props.elmodel=M.elstruct(pt).elmodel;
        reco.props.manually_corrected=1;
        save([M.ui.groupdir,options.patientname,filesep,'ea_stats'],'ea_stats');
        save([M.ui.groupdir,options.patientname,filesep,'ea_reconstruction'],'reco');
    end

    if ~exist(options.root,'file') % data is not there. Act as if detached. Process in tmp-dir.
        processlocal=1;
        warning('on');
        warning('Data has been detached from group-directory. Will process locally. Please be aware that you might loose this newly-processed data once you re-attach the single-patient data to the analysis!');
        warning('off');
        mkdir([M.ui.groupdir,options.patientname]);
        options.root=M.ui.groupdir;
        % options.patientname='tmp';
        try
            ea_stats=M.stats(pt).ea_stats;
        catch
            ea_stats=struct;
        end
        reco.mni.coords_mm=M.elstruct(pt).coords_mm;
        reco.mni.trajectory=M.elstruct(pt).trajectory;
        reco.mni.markers=M.elstruct(pt).markers;
        reco.props.elmodel=M.elstruct(pt).elmodel;
        reco.props.manually_corrected=1;
        save([M.ui.groupdir,options.patientname,filesep,'ea_stats'],'ea_stats');
        save([M.ui.groupdir,options.patientname,filesep,'ea_reconstruction'],'reco');
    end

    %delete([options.root,options.patientname,filesep,'ea_stats.mat']);

    % Step 1: Re-calculate closeness to subcortical atlases.
    options.leadprod = 'group';
    options.patient_list=M.patient.list;
    options.d3.mirrorsides=0;
    resultfig=ea_elvis(options,M.elstruct(pt));

    % save scene as matlab figure


    options.modality=ea_checkctmrpresent(M.patient.list{pt});
    if options.modality(1) % prefer MR
        options.modality=1;
    else
        if options.modality(2)
            options.modality=2;
        else
            options.modality=1;
            warning(['No MR or CT volumes found in ',M.patient.list{pt},'.']);
        end
    end

    % Step 2: Re-calculate VAT
    if isfield(M,'S')
        try
            setappdata(resultfig,'curS',M.S(pt));
        catch
            ea_error(['Stimulation parameters for ',M.patient.list{pt},' are missing.']);
        end
        vfnames=getappdata(handles.leadfigure,'vatfunctionnames');

        [~,ix]=ismember(M.vatmodel,vfnames);
        vfs=getappdata(handles.leadfigure,'genvatfunctions');
        try
            ea_genvat=eval(['@',vfs{ix}]);
        catch
            keyboard
        end
        setappdata(handles.leadfigure,'resultfig',resultfig);
        for side=1:2
            setappdata(resultfig,'elstruct',M.elstruct(pt));
            setappdata(resultfig,'elspec',options.elspec);
            try
                [stimparams(1,side).VAT(1).VAT,volume]=feval(ea_genvat,M.elstruct(pt).coords_mm,M.S(pt),side,options,['gs_',M.guid],options.prefs.machine.vatsettings.horn_ethresh,handles.leadfigure);
                     catch
                    msgbox(['Error while creating VTA of ',M.patient.list{pt},'.']);
                    volume=0;
            end
            stimparams(1,side).volume=volume;
        end

        setappdata(resultfig,'stimparams',stimparams(1,:));
    end
    % this will add the volume stats (atlasIntersections) to stats file:
    ea_showfibres_volume(resultfig,options);


    % Step 3: Re-calculate connectivity from VAT to rest of the brain.
    if ~strcmp(mod,'Do not calculate connectivity stats')

        % Convis part:
        parcs=get(handles.labelpopup,'String');
        selectedparc=parcs{get(handles.labelpopup,'Value')};
        directory=[options.root,options.patientname,filesep];
        if ischar(fibersfile)
            switch mod
                case 'Patient''s fMRI time courses'
                    ea_error('Group statistics for fMRI are not yet supported. Sorry, check back later!');
                    pV=spm_vol([ea_space(options,'labeling'),selectedparc,'.nii']);
                    pX=spm_read_vols(pV);
                    ea_cvshowvatfmri(resultfig,pX,directory,filesare,handles,pV,selectedparc,mod,options);
                otherwise
                    ea_cvshowvatdmri(resultfig,directory,{mod,'gs'},selectedparc,options);
            end
        else
            ea_cvshowvatdmri(resultfig,directory,{fibersfile,'gs'},selectedparc,options);
        end
    end
    close(resultfig);

    if processlocal % gather stats and recos to M
        load([M.ui.groupdir,options.patientname,filesep,'ea_stats']);
        load([M.ui.groupdir,options.patientname,filesep,'ea_reconstruction']);

        M.stats(pt).ea_stats=ea_stats;
        M.elstruct(pt).coords_mm=reco.mni.coords_mm;
        M.elstruct(pt).trajectory=reco.mni.trajectory;
        setappdata(gcf,'M',M);

        save([M.ui.groupdir,'LEAD_groupanalysis.mat'],'M','-v7.3');
        try	movefile([options.root,options.patientname,filesep,'LEAD_scene.fig'],[M.ui.groupdir,'LEAD_scene_',num2str(pt),'.fig']); end
        %rmdir([M.ui.groupdir,'tmp'],'s');
    end
end
%% processing done here.

ea_refresh_lg(handles);


% --- Executes on selection change in fiberspopup.
function fiberspopup_Callback(hObject, eventdata, handles)
% hObject    handle to fiberspopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns fiberspopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from fiberspopup
M=getappdata(gcf,'M');
M.ui.fiberspopup=get(handles.fiberspopup,'Value');
M.ui.connectomename=get(handles.fiberspopup,'String');
M.ui.connectomename=M.ui.connectomename{M.ui.fiberspopup};
setappdata(gcf,'M',M);
ea_refresh_lg(handles);


% --- Executes during object creation, after setting all properties.
function fiberspopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fiberspopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in labelpopup.
function labelpopup_Callback(hObject, eventdata, handles)
% hObject    handle to labelpopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns labelpopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from labelpopup
M=getappdata(gcf,'M');
M.ui.labelpopup=get(handles.labelpopup,'Value');
setappdata(gcf,'M',M);
ea_refresh_lg(handles);


% --- Executes during object creation, after setting all properties.
function labelpopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to labelpopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in atlassetpopup.
function atlassetpopup_Callback(hObject, eventdata, handles)
% hObject    handle to atlassetpopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns atlassetpopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from atlassetpopup
M=getappdata(gcf,'M');
M.ui.atlassetpopup=get(handles.atlassetpopup,'Value');
setappdata(gcf,'M',M);
ea_refresh_lg(handles);


% --- Executes during object creation, after setting all properties.
function atlassetpopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to atlassetpopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function options=ea_setopts_local(handles)

options.earoot=ea_getearoot;
options.verbose=3;
options.sides=1:2; % re-check this later..
options.atlasset=get(handles.atlassetpopup,'String');
try
    options.atlasset=options.atlasset{get(handles.atlassetpopup,'Value')};
catch % too many entries..
    set(handles.atlassetpopup,'Value',1);
    options.atlasset=1;
end
options.fiberthresh=1;
options.writeoutstats=1;
options.labelatlas=get(handles.labelpopup,'String');
try
    options.labelatlas=options.labelatlas{get(handles.labelpopup,'Value')};
catch % too many entries..
    set(handles.labelpopup,'Value',1);
    options.labelatlas=1;
end
options.writeoutpm=1;
options.colormap=jet;
options.d3.write=1;
options.d3.prolong_electrode=2;
options.d3.writeatlases=1;
options.macaquemodus=0;


% --- Executes on button press in groupdir_choosebox.
function groupdir_choosebox_Callback(hObject, eventdata, handles)
% hObject    handle to groupdir_choosebox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Save data for previous selected group folder
if ~strcmp(get(handles.groupdir_choosebox,'String'),'Choose Group Directory') % group dir still not chosen
    ea_busyaction('on',handles.leadfigure,'group');
    disp('Saving data...');
    % save M
    ea_refresh_lg(handles);
    M=getappdata(handles.leadfigure,'M');
    disp('Saving data to disk...');
    try
        save([get(handles.groupdir_choosebox,'String'),'LEAD_groupanalysis.mat'],'M','-v7.3');
    catch
        warning('Data could not be saved.');
        keyboard
    end
    disp('Done.');
    ea_busyaction('off',handles.leadfigure,'group');
end

% groupdir=ea_uigetdir(ea_startpath,'Choose Group Directory');
groupdir = uigetdir;

if ~groupdir % user pressed cancel
    return
end
groupdir = [groupdir, filesep];

ea_load_group(handles,groupdir);



% --- Executes on button press in opensubgui.
function opensubgui_Callback(hObject, eventdata, handles)
% hObject    handle to opensubgui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
M=getappdata(gcf,'M');
[selection]=ea_groupselectorwholelist(M.ui.listselect,M.patient.list);

lead_dbs('loadsubs',M.patient.list(selection));


% --- Executes on button press in choosegroupcolors.
function choosegroupcolors_Callback(hObject, eventdata, handles)
% hObject    handle to choosegroupcolors (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

M=getappdata(gcf,'M');

for g=unique(M.patient.group)'
    M.groups.color(ismember(M.groups.group,g),:)=...
        ea_uisetcolor(M.groups.color(ismember(M.groups.group,g),:),['Group ',num2str(g),':']);
end
M.groups.colorschosen=1;

setappdata(gcf,'M',M);
ea_refresh_lg(handles);


% --- Executes on button press in setstimparamsbutton.
function setstimparamsbutton_Callback(hObject, eventdata, handles)
% hObject    handle to setstimparamsbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
M=getappdata(gcf,'M');

% try
%     uicell=inputdlg('Enter Variable name for Voltage-Parameters','Enter Stimulation Settings...',1);
%     uidata.U=evalin('base',uicell{1});
% catch
%     warning('Stim-Params could not be evaluated. Please Try again.');
%     return
% end
% try
%     uicell=inputdlg('Enter Variable name for Impedance-Parameters','Enter Stimulation Settings...',1);
%     uidata.Im=evalin('base',uicell{1});
% catch
%     warning('Stim-Params could not be evaluated. Please Try again.');
%     return
% end

options = ea_setopts_local(handles);
options.leadprod = 'group';
options.groupid = M.guid;

ea_refresh_lg(handles);

ea_stimparams(M.elstruct, handles.leadfigure, options);


% --- Executes on button press in highlightactivecontcheck.
function highlightactivecontcheck_Callback(hObject, eventdata, handles)
% hObject    handle to highlightactivecontcheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of highlightactivecontcheck
M=getappdata(gcf,'M');
M.ui.hlactivecontcheck=get(handles.highlightactivecontcheck,'Value');

setappdata(gcf,'M',M);
ea_refresh_lg(handles);



% --- Executes on selection change in elrenderingpopup.
function elrenderingpopup_Callback(hObject, eventdata, handles)
% hObject    handle to elrenderingpopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns elrenderingpopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from elrenderingpopup

M=getappdata(gcf,'M');
M.ui.elrendering=get(handles.elrenderingpopup,'Value');


setappdata(gcf,'M',M);
ea_refresh_lg(handles);


% --- Executes during object creation, after setting all properties.
function elrenderingpopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to elrenderingpopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in showpassivecontcheck.
function showpassivecontcheck_Callback(hObject, eventdata, handles)
% hObject    handle to showpassivecontcheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showpassivecontcheck

M=getappdata(gcf,'M');
M.ui.showpassivecontcheck=get(handles.showpassivecontcheck,'Value');


setappdata(gcf,'M',M);
ea_refresh_lg(handles);


% --- Executes on button press in showactivecontcheck.
function showactivecontcheck_Callback(hObject, eventdata, handles)
% hObject    handle to showactivecontcheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showactivecontcheck

M=getappdata(gcf,'M');
M.ui.showactivecontcheck=get(handles.showactivecontcheck,'Value');

setappdata(gcf,'M',M);
ea_refresh_lg(handles);


% --- Executes on button press in showisovolumecheck.
function showisovolumecheck_Callback(hObject, eventdata, handles)
% hObject    handle to showisovolumecheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showisovolumecheck
M=getappdata(gcf,'M');
M.ui.showisovolumecheck=get(handles.showisovolumecheck,'Value');

setappdata(gcf,'M',M);
ea_refresh_lg(handles);


% --- Executes on selection change in isovscloudpopup.
function isovscloudpopup_Callback(hObject, eventdata, handles)
% hObject    handle to isovscloudpopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns isovscloudpopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from isovscloudpopup
M=getappdata(gcf,'M');
M.ui.isovscloudpopup=get(handles.isovscloudpopup,'Value');
setappdata(gcf,'M',M);
ea_refresh_lg(handles);

% --- Executes during object creation, after setting all properties.
function isovscloudpopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to isovscloudpopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in statvatcheck.
function statvatcheck_Callback(hObject, eventdata, handles)
% hObject    handle to statvatcheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of statvatcheck
M=getappdata(gcf,'M');

M.ui.statvat=get(handles.statvatcheck,'Value');
setappdata(gcf,'M',M);


% --- Executes on button press in mercheck.
function mercheck_Callback(hObject, eventdata, handles)
% hObject    handle to mercheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of mercheck

M=getappdata(gcf,'M');

M.ui.mer=get(handles.mercheck,'Value');
setappdata(gcf,'M',M);


% --- Executes on selection change in elmodelselect.
function elmodelselect_Callback(hObject, eventdata, handles)
% hObject    handle to elmodelselect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns elmodelselect contents as cell array
%        contents{get(hObject,'Value')} returns selected item from elmodelselect
M=getappdata(gcf,'M');
M.ui.elmodelselect=get(handles.elmodelselect,'Value');
setappdata(gcf,'M',M);
ea_refresh_lg(handles);

% --- Executes during object creation, after setting all properties.
function elmodelselect_CreateFcn(hObject, eventdata, handles)
% hObject    handle to elmodelselect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in detachbutton.
function detachbutton_Callback(hObject, eventdata, handles)
% hObject    handle to detachbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
choice = questdlg('Would you really like to detach the group data from the single-patient data? This means that changes to single-patient reconstructions will not be updated into the group analysis anymore. This should only be done once all patients have been finally localized and an analysis needs to be fixed (e.g. after publication or when working in collaborations). Please be aware that this step cannot be undone!', ...
    'Detach Group data from single patient data...', ...
    'No, abort.','Yes, sure!','Yes and copy localizations/VTAs please.','No, abort.');
% Handle response
switch choice
    case 'No, abort.'
        return
    case {'Yes, sure!','Yes and copy localizations/VTAs please.'}

        M=getappdata(gcf,'M');
        ea_dispercent(0,'Detaching group file');
        for pt=1:length(M.patient.list)
            slashes=strfind(M.patient.list{pt},'/');
            if isempty(slashes)
                slashes=strfind(M.patient.list{pt},'\');
            end
            ptname=M.patient.list{pt}(max(slashes)+1:end);
            if strcmp('Yes and copy localizations/VTAs please.',choice)
                odir=[M.ui.groupdir,ptname,filesep];
                ea_mkdir([odir,'stimulations']);
                copyfile([M.patient.list{pt},filesep,'ea_reconstruction.mat'],[odir,'ea_reconstruction.mat']);
                copyfile([M.patient.list{pt},filesep,'stimulations',filesep,'gs_',M.guid],[odir,'stimulations',filesep,'gs_',M.guid]);
            end

            M.patient.list{pt}=ptname;

            ea_dispercent(pt/length(M.patient.list));
        end
        ea_dispercent(1,'end');
        M.ui.detached=1;

end

setappdata(gcf,'M',M);
ea_refresh_lg(handles);


% --- Executes on button press in colorpointcloudcheck.
function colorpointcloudcheck_Callback(hObject, eventdata, handles)
% hObject    handle to colorpointcloudcheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of colorpointcloudcheck
M=getappdata(gcf,'M');
M.ui.colorpointcloudcheck=get(handles.colorpointcloudcheck,'Value');
setappdata(gcf,'M',M);
ea_refresh_lg(handles);

% --- Executes on selection change in normregpopup.
function normregpopup_Callback(hObject, eventdata, handles)
% hObject    handle to normregpopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns normregpopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from normregpopup
M=getappdata(gcf,'M');
M.ui.normregpopup=get(handles.normregpopup,'Value');
setappdata(gcf,'M',M);
ea_refresh_lg(handles);

% --- Executes during object creation, after setting all properties.
function normregpopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to normregpopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close leadfigure.
function leadfigure_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to leadfigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure

ea_busyaction('on',gcf,'group');
if ~strcmp(get(handles.groupdir_choosebox,'String'),'Choose Group Directory') % group dir still not chosen
    disp('Saving data...');
    % save M
    ea_refresh_lg(handles);
    M=getappdata(hObject,'M');
    disp('Saving data to disk...');
    try
        save([get(handles.groupdir_choosebox,'String'),'LEAD_groupanalysis.mat'],'M','-v7.3');
    catch
        warning('Data could not be saved.');
        keyboard
    end
    disp('Done.');
    disp('Bye for now.');
end
ea_busyaction('off',gcf,'group');
delete(hObject);


% --- Executes on button press in targetreport.
function targetreport_Callback(hObject, eventdata, handles)
% hObject    handle to targetreport (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ea_refresh_lg(handles);
M=getappdata(gcf,'M');
ea_gentargetreport(M);


% --- Executes on button press in viz2dbutton.
function viz2dbutton_Callback(hObject, eventdata, handles)
% hObject    handle to viz2dbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clc;
M=getappdata(gcf,'M');

ea_busyaction('on',gcf,'group');
% set options
options=ea_setopts_local(handles);
% set pt specific options
options.root=[fileparts(fileparts(get(handles.groupdir_choosebox,'String'))),filesep];
[~,options.patientname]=fileparts(fileparts(get(handles.groupdir_choosebox,'String')));

options.numcontacts=size(M.elstruct(1).coords_mm{1},1);
options.elmodel=M.elstruct(1).elmodel;
options=ea_resolve_elspec(options);
options.prefs=ea_prefs(options.patientname);
options.d3.verbose='on';

options.d3.elrendering=M.ui.elrendering;
options.d3.hlactivecontacts=get(handles.highlightactivecontcheck,'Value');
options.d3.showactivecontacts=get(handles.showactivecontcheck,'Value');
options.d3.showpassivecontacts=get(handles.showpassivecontcheck,'Value');
try
    options.d3.isomatrix=M.isomatrix;
catch
    options.d3.isomatrix={};
end
try
    options.d3.isomatrix_name=M.isomatrix_name;
catch
    options.d3.isomatrix_name={};
end

options.expstatvat.do=M.ui.statvat;

options.d2.showlegend=0;

options.d3.isovscloud=M.ui.isovscloudpopup;
options.d3.showisovolume=M.ui.showisovolumecheck;
options.d3.colorpointcloud=M.ui.colorpointcloudcheck;
options.normregressor=M.ui.normregpopup;

options.d2.write=1;

options.d2.atlasopacity=0.15;
options.groupmode=1;
options.groupid=M.guid;
options.modality=3; % use template image
options=ea_amendtoolboxoptions(options);

if strcmp(options.atlasset,'Use none')
    options.d2.writeatlases=1;
else
    options.d2.writeatlases=1;
end

% Prior Results are loaded here inside the function (this way, function
% can be called just by giving the patient directory.

% Prepare isomatrix (includes a normalization step if M.ui.normregpopup
% says so:

if options.d3.showisovolume || options.expstatvat.do % regressors be used - iterate through all
    allisomatrices=options.d3.isomatrix;
    allisonames=options.d3.isomatrix_name;
    for reg=1:length(allisomatrices)
        options.d3.isomatrix=allisomatrices{reg};
        options.d3.isomatrix_name=allisonames{reg};
        M.isomatrix=allisomatrices{reg};
        M.isomatrix_name=allisonames{reg};
        options.shifthalfup=0;
        try
            options.d3.isomatrix=ea_reformat_isomatrix(options.d3.isomatrix,M,options);
            if size(options.d3.isomatrix{1},2)==3 % pairs
                options.shifthalfup=1;
            end
        end

        if ~strcmp(get(handles.groupdir_choosebox,'String'),'Choose Group Directory') % group dir still not chosen
            ea_refresh_lg(handles);
            disp('Saving data...');
            % save M
            save([get(handles.groupdir_choosebox,'String'),'LEAD_groupanalysis.mat'],'M','-v7.3');
            disp('Done.');
        end

        % export coordinate-mapping
        if options.d3.showisovolume % export to nifti volume
            ea_exportisovolume(M.elstruct(get(handles.patientlist,'Value')),options);
        end
        % export VAT-mapping
        if options.expstatvat.do % export to nifti volume
            ea_exportvatmapping(M,options,handles);
        end

        ea_out2d(M,options,handles);
    end
else
    ea_out2d(M,options,handles);
end
ea_busyaction('off',gcf,'group');


function ea_out2d(M,options,handles)

for pt=1:length(M.patient.list)
    for side=1:2
        try
            M.elstruct(pt).activecontacts{side}=M.S(pt).activecontacts{side};
        end
    end
end
cuts=ea_writeplanes(options,M.elstruct(get(handles.patientlist,'Value')));


% --- Executes on button press in specify2doptions.
function specify2doptions_Callback(hObject, eventdata, handles)
% hObject    handle to specify2doptions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
options.prefs=ea_prefs('');
options.groupmode=1;
options.native=0;
ea_spec2dwrite(options);


% --- Executes on button press in mirrorsides.
function mirrorsides_Callback(hObject, eventdata, handles)
% hObject    handle to mirrorsides (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of mirrorsides

M=getappdata(gcf,'M');
M.ui.mirrorsides=get(handles.mirrorsides,'Value');

setappdata(gcf,'M',M);
ea_refresh_lg(handles);


% --- Executes on button press in ttestbutton_ft.
function ttestbutton_ft_Callback(hObject, eventdata, handles)
% hObject    handle to ttestbutton_ft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

stats=preparedataanalysis_ft(handles);

assignin('base','stats',stats);

% perform t-tests:

if ~isempty(stats.fc.fccorr)
    ea_ttest(stats.fc.fccorr(repmat(logical(stats.corrcl),1,size(stats.fc.fccorr,2))),stats.fc.fccorr(~repmat(logical(stats.corrcl),1,size(stats.fc.fccorr,2))),'Fibercounts',stats.vc_labels);
end

if ~isempty(stats.fc.nfccorr)
    ea_ttest(stats.fc.nfccorr(repmat(logical(stats.corrcl),1,size(stats.fc.nfccorr,2))),stats.fc.nfccorr(~repmat(logical(stats.corrcl),1,size(stats.fc.nfccorr,2))),'Normalized Fibercounts',stats.vc_labels);
end


% --- Executes on button press in corrbutton_ft.
function corrbutton_ft_Callback(hObject, eventdata, handles)
% hObject    handle to corrbutton_ft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ea_busyaction('on',gcf,'group');
stats=preparedataanalysis_ft(handles);
assignin('base','stats',stats);

% perform correlations:
if size(stats.corrcl,2)==1 % one value per patient

    if ~isempty(stats.fccorr.both)
        ea_corrplot(stats.corrcl,stats.fccorr.nboth,{'FC_BH',stats.fc_labels(:)});
    end
    if ~isempty(stats.fccorr.right)
        ea_corrplot(stats.corrcl,stats.fccorr.nright,{'FC_RH',stats.fc_labels(:)});
    end
    if ~isempty(stats.fccorr.left)
        ea_corrplot(stats.corrcl,stats.fccorr.nleft,{'FC_LH',stats.fc_labels(:)});
    end

elseif size(stats.corrcl,2)==2 % one value per hemisphere

    if ~isempty(stats.fccorr.both)
        ea_corrplot(stats.corrcl(:),[stats.fccorr.right;stats.fccorr.left],{'FC_BH',stats.fc_labels(:)});
    end
    if ~isempty(stats.fccorr.right)
        ea_corrplot(stats.corrcl(:,1),stats.fccorr.nright,{'FC_RH',stats.fc_labels(:)});
    end
    if ~isempty(stats.fccorr.left)
        ea_corrplot(stats.corrcl(:,2),stats.fccorr.nleft,{'FC_LH',stats.fc_labels(:)});
    end

else
    ea_error('Please select a regressor with one value per patient or per hemisphere to perform this correlation.');
end
ea_busyaction('off',gcf,'group');


% --- Executes on button press in showdiscfibers.
function showdiscfibers_Callback(hObject, eventdata, handles)
% hObject    handle to showdiscfibers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of showdiscfibers


% --- Executes on button press in discfiberssettingpush.
function discfiberssettingpush_Callback(hObject, eventdata, handles)
% hObject    handle to discfiberssettingpush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ea_discfibers_setting;


% --- Executes on selection change in recentpts.
function recentpts_Callback(hObject, eventdata, handles)
% hObject    handle to recentpts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ea_busyaction('on',handles.leadfigure,'group');
ea_rcpatientscallback(handles, 'groups');
ea_busyaction('off',handles.leadfigure,'group');

% Hints: contents = cellstr(get(hObject,'String')) returns recentpts contents as cell array
%        contents{get(hObject,'Value')} returns selected item from recentpts


% --- Executes during object creation, after setting all properties.
function recentpts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to recentpts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in VTAvsEfield.
function VTAvsEfield_Callback(hObject, eventdata, handles)
% hObject    handle to VTAvsEfield (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns VTAvsEfield contents as cell array
%        contents{get(hObject,'Value')} returns selected item from VTAvsEfield


% --- Executes during object creation, after setting all properties.
function VTAvsEfield_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VTAvsEfield (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
