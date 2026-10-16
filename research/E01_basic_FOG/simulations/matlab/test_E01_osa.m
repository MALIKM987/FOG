function ok=test_E01_osa()
%TEST_E01_OSA Check that two OSA blocks are physically connected to sources.
% Run in MATLAB R2023b after updating your local repository:
%     assert(test_E01_osa());
%
% This is a structural/software test, not a lab measurement.
model='FOG_E01_SIMULINK';
here=fileparts(mfilename('fullpath'));
if ~bdIsLoaded(model)
    path=fullfile(here,[model '.slx']);
    if isfile(path)
        load_system(path);
    else
        build_E01_simulink();
    end
end
names={'LASER','ASE'};
for k=1:2
    source=[model '/' names{k} ' - zrodlo'];
    osa=[model '/OSA ' names{k} ' - analizator widma'];
    assert(getSimulinkBlockHandle(osa)~=-1, ...
        'Brak analizatora %s.',names{k});
    assert(getSimulinkBlockHandle(source)~=-1, ...
        'Brak zrodla %s.',names{k});
    ph=get_param(source,'PortHandles');
    assert(numel(ph.Outport)==3, ...
        'Zrodlo %s powinno miec 3 porty.',names{k});
    for port=2:3
        line=get_param(ph.Outport(port),'Line');
        assert(line~=-1, ...
            'Port widmowy %d zrodla %s niepodlaczony.',port,names{k});
        dst=get_param(line,'DstPortHandle');
        assert(~isempty(dst), 'Brak celu przewodu widma.');
        target=get_param(dst(1),'Parent');
        assert(strcmp(target,osa), ...
            'Przewod widma nie trafia do odpowiedniego OSA.');
    end
    fig=view_E01_optical_analyzer(names{k},model);
    assert(isgraphics(fig,'figure'), ...
        'Analizator %s nie otworzyl wykresu.',names{k});
    close(fig);
end
set_param(model,'SimulationCommand','update');
fprintf('PASS: dwa OSA podlaczone do zrodel i poprawnie renderuja widmo.\n');
ok=true;
end
