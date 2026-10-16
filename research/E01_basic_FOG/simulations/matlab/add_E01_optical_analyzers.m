function blocks = add_E01_optical_analyzers(model,saveAfter)
%ADD_E01_OPTICAL_ANALYZERS Dwa OSA podlaczone do WYJSC obu zrodel.
%
% MATLAB R2023b + standard Simulink; nie wymaga DSP System Toolbox.
% Do istniejacego zapisanego modelu:
%     save_system('FOG_E01_SIMULINK');
%     add_E01_optical_analyzers();
%
% Nie wykonuje ponownej generacji ani nie kasuje schematu. Przekazuje
% DWA SYGNALY SPEKTRALNE z kazdego zrodla: lambda [nm] i S_lambda [W/nm].
% Analizatory sa graficznymi blokami Simulinka z wejsciami sygnalowymi.
% Dwuklik otwiera po polsku zadane widmo z tych dwoch torow.
% UWAGA: to zadane widmo optyczne, nie FFT elektrycznej obwiedni FOG.

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
    assert(isfile(modelFile),'Nie znaleziono schematu: %s',modelFile);
    load_system(modelFile);
end
if saveAfter && strcmp(get_param(model,'Dirty'),'on')
    error('E01:UnsavedChanges', ...
        ['Schemat ma niezapisane zmiany. ', ...
        'Najpierw wykonaj save_system(''%s'').'],model);
end

cfg=E01_config();
kinds={'LASER','ASE'};
sourceNames={'LASER - zrodlo','ASE - zrodlo'};
osaNames={'OSA LASER - analizator widma','OSA ASE - analizator widma'};
positions={[290 48 468 118],[290 315 468 385]};
blocks=cell(1,2);

for k=1:2
    sourcePath=[model '/' sourceNames{k}];
    assert(getSimulinkBlockHandle(sourcePath)~=-1, ...
        'W schemacie nie ma zrodla: %s',sourceNames{k});
    src=E01_source(cfg,kinds{k});
    srcSpectrum=[sourcePath '/Widmo S_lambda [W_nm]'];
    srcLambda=[sourcePath '/Dlugosc fali [nm]'];
    outSpectrum=[sourcePath '/S_lambda na wyjsciu'];
    outLambda=[sourcePath '/Lambda na wyjsciu'];

    % Constant samples describe the optical spectrum represented by each
    % source, not an FFT of the temporal light envelope. Output is a row
    % vector (wavelength and PSD each with their own output line).
    if getSimulinkBlockHandle(srcSpectrum)==-1
        add_block('simulink/Sources/Constant',srcSpectrum, ...
            'Position',[310 280 410 320]);
    end
    if getSimulinkBlockHandle(srcLambda)==-1
        add_block('simulink/Sources/Constant',srcLambda, ...
            'Position',[310 360 410 400]);
    end
    set_param(srcSpectrum,'Value',mat2str(src.S_W_per_nm(:).',16));
    set_param(srcLambda,'Value',mat2str(src.lambda_nm(:).',16));

    if getSimulinkBlockHandle(outSpectrum)==-1
        add_block('simulink/Sinks/Out1',outSpectrum, ...
            'Position',[525 290 555 310],'Port','2');
    end
    if getSimulinkBlockHandle(outLambda)==-1
        add_block('simulink/Sinks/Out1',outLambda, ...
            'Position',[525 370 555 390],'Port','3');
    end
    set_param(outSpectrum,'Port','2');
    set_param(outLambda,'Port','3');

    ensureWire(sourcePath,'Widmo S_lambda [W_nm]/1','S_lambda na wyjsciu/1');
    ensureWire(sourcePath,'Dlugosc fali [nm]/1','Lambda na wyjsciu/1');

    analyzerPath=[model '/' osaNames{k}];
    if getSimulinkBlockHandle(analyzerPath)==-1
        add_block('simulink/Ports & Subsystems/Subsystem', ...
            analyzerPath,'Position',positions{k});
        Simulink.SubSystem.deleteContents(analyzerPath);
        add_block('simulink/Sources/In1',[analyzerPath '/S_lambda [W_nm]'], ...
            'Position',[30 38 60 58]);
        add_block('simulink/Sources/In1',[analyzerPath '/Lambda [nm]'], ...
            'Position',[30 128 60 148]);
        add_block('simulink/Sinks/Terminator',[analyzerPath '/Wejscie widma'], ...
            'Position',[125 40 150 60]);
        add_block('simulink/Sinks/Terminator',[analyzerPath '/Wejscie lambda'], ...
            'Position',[125 130 150 150]);
        add_line(analyzerPath,'S_lambda [W_nm]/1', ...
            'Wejscie widma/1','autorouting','on');
        add_line(analyzerPath,'Lambda [nm]/1', ...
            'Wejscie lambda/1','autorouting','on');
    end

    % The OSA window reads the Constant blocks that DRIVE the input
    % connections. It does not infer an optical spectrum from RIN time
    % samples and does not depend on a DSP license.
    callback=sprintf(['addpath(fileparts(get_param(bdroot(gcb),', ...
        '''FileName''))); view_E01_optical_analyzer(''%s'');'],kinds{k});
    set_param(analyzerPath,'OpenFcn',callback);
    ensureWire(model,[sourceNames{k} '/2'],[osaNames{k} '/1']);
    ensureWire(model,[sourceNames{k} '/3'],[osaNames{k} '/2']);
    blocks{k}=analyzerPath;
end

if saveAfter
    save_system(model);
    open_system(model);
end
fprintf('Dodano analizatory OSA podlaczone do zrodel: LASER i ASE.\n');
fprintf('Kliknij dwukrotnie OSA LASER lub OSA ASE.\n');
end

function ensureWire(system,src,dst)
% Idempotent connection: ignore only an already connected destination.
segments=split(string(dst),'/');
destinationBlock=char(strjoin(segments(1:end-1),'/'));
portIdx=str2double(segments(end));
ph=get_param([system '/' destinationBlock],'PortHandles');
destHandle=ph.Inport(portIdx);
ln=get_param(destHandle,'Line');
if ln==-1
    add_line(system,src,dst,'autorouting','on');
end
end
