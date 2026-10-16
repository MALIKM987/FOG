function changed=disable_E01_auto_sweep(model)
%DISABLE_E01_AUTO_SWEEP Stop 84 simulations launching on model doubleclick.
% MATLAB R2023b + Simulink. Does NOT run the long measurement.
% For a loaded existing model:
%   save_system('FOG_E01_SIMULINK');
%   disable_E01_auto_sweep();
%
% New models generated from build_E01_simulink() do not create such a
% callback. The old empty measurement icon stays present but is renamed.
% Nothing in the actual optical chain is changed.
if nargin<1 || isempty(model)
    model='FOG_E01_SIMULINK';
end
model=char(model);
here=fileparts(mfilename('fullpath'));
if ~bdIsLoaded(model)
    file=fullfile(here,[model '.slx']);
    assert(isfile(file),'Nie znaleziono modelu: %s',file);
    load_system(file);
end
assert(strcmp(get_param(model,'Dirty'),'off'), ...
    ['Masz niezapisane zmiany w schemacie. Wykonaj ', ...
     'save_system(''%s'') przed ta komenda.'],model);

oldPath=[model '/POMIAR prad od Omega - kliknij 2x'];
safePath=[model '/POMIAR Omega - tylko komenda MATLAB'];
oldPresent=getSimulinkBlockHandle(oldPath)~=-1;
newPresent=getSimulinkBlockHandle(safePath)~=-1;

if ~oldPresent && ~newPresent
    fprintf(['Schemat nie zawiera automatycznego przycisku. ', ...
        'Pomiar uruchamiaj wylacznie komenda: ', ...
        'sweep_E01_simulink(21)\n']);
    changed=false;
    return
end
if oldPresent
    target=oldPath;
else
    target=safePath;
end
oldCallback=get_param(target,'OpenFcn');
changed=oldPresent||~isempty(strtrim(oldCallback));

if ~changed
    fprintf('Automatyczny sweep jest juz wylaczony.\n');
    return
end

% Do not overwrite the last good .slx: create a timestamped local backup.
savedFile=get_param(model,'FileName');
if ~isempty(savedFile) && isfile(savedFile)
    stamp=datestr(now,'yyyymmdd_HHMMSS_FFF');
    backup=[savedFile '.' stamp '.bak'];
    [ok,msg]=copyfile(savedFile,backup);
    assert(ok,'Nie mozna zapisac kopii .slx: %s',msg);
    fprintf('Kopia poprzedniego modelu: %s\n',backup);
end

% Delete only the callback that launched the measurement.
set_param(target,'OpenFcn','');
if oldPresent
    set_param(oldPath,'Name','POMIAR Omega - tylko komenda MATLAB');
end
save_system(model);
fprintf(['Wylaczono automatyczne uruchamianie pomiaru. ', ...
    'Ani otwarcie modelu, ani dwuklik nie wykona serii symulacji.\n']);
fprintf(['Aby uruchomic pomiar NA WLASNE POLECENIE wpisz: ', ...
    'wyniki = sweep_E01_simulink(21);\n']);
end
