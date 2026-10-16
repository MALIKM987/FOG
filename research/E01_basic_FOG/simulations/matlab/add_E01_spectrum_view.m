function blockPath = add_E01_spectrum_view(model,saveAfter)
%ADD_E01_SPECTRUM_VIEW Install a double-click LASER/ASE spectrum viewer.
%
% Existing already-OPEN Simulink model:
%   save_system('FOG_E01_SIMULINK');
%   add_E01_spectrum_view();
%
% During build_E01_simulink(), call with saveAfter=false so the builder
% may add the block before the model is saved.
%
% IMPORTANT: never silently overwrite user edits to a dirty existing
% model. If a user has edits, they must save their model first.

if nargin<1 || isempty(model)
    model='FOG_E01_SIMULINK';
end
if nargin<2
    saveAfter=true;
end
model=char(model);
here=fileparts(mfilename('fullpath'));
if ~bdIsLoaded(model)
    modelFile=fullfile(here,[model '.slx']);
    assert(isfile(modelFile), ...
        'Nie znaleziono modelu .slx: %s',modelFile);
    load_system(modelFile);
end
if saveAfter && strcmp(get_param(model,'Dirty'),'on')
    error('E01:UnsavedChanges', ...
        ['Schemat ma niezapisane zmiany. ', ...
         'Wykonaj najpierw save_system(''%s''); ', ...
         'potem ponow add_E01_spectrum_view().'],model);
end

blockPath=[model '/WIDMA LASER I ASE - kliknij 2x'];
if getSimulinkBlockHandle(blockPath)==-1
    add_block('simulink/Ports & Subsystems/Subsystem',blockPath, ...
        'Position',[70 405 265 495]);
    Simulink.SubSystem.deleteContents(blockPath);
end

% Official Simulink block OpenFcn callback: double click opens plot,
% instead of entering the (empty) subsystem.
% Resolve file folder from currently saved model even in new sessions.
callback=['addpath(fileparts(get_param(bdroot(gcb),', ...
    '''FileName''))); show_E01_spectra();'];
set_param(blockPath,'OpenFcn',callback);

if saveAfter
    save_system(model);
    open_system(model);
end
fprintf('Widma LASER i ASE: kliknij dwa razy blok %s\n',blockPath);
fprintf('Lub wpisz bezposrednio: show_E01_spectra()\n');
end
