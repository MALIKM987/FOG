function report = compare_E01_simulink()
%COMPARE_E01_SIMULINK Compare LASER/ASE current and noise in the SAME FOG.
%
% For MATLAB R2023b + Simulink:
%   addpath('research/E01_basic_FOG/simulations/matlab')
%   report = compare_E01_simulink();
%
% Plot 1: full diode currents, nearly indistinguishable (correct physics).
% Plot 2: current minus noiseless Sagnac current, for fixed Omega.
% Plot 3: RMS of this residual in uA for both sources.
%
% DEMO ONLY: detector residual reflects the source-intensity RIN assumed
% by the Simulink generator. Not a comparison of real lab devices.
here=fileparts(mfilename('fullpath'));
addpath(here,'-begin');
model='FOG_E01_SIMULINK';
if ~bdIsLoaded(model)
    modelFile=fullfile(here,[model '.slx']);
    if isfile(modelFile)
        load_system(modelFile);
    else
        build_E01_simulink();
    end
end

switchPath=[model '/WYBOR ZRODLA - kliknij 2x'];
savedState=get_param(switchPath,'sw');
straySwitch=[model '/Odbicie 0=wyl 1=wl'];
hasStray=(getSimulinkBlockHandle(straySwitch)~=-1);
if hasStray
    oldStray=get_param(straySwitch,'Value');
    restoreState=onCleanup(@()restoreModes( ...
        switchPath,savedState,straySwitch,oldStray));
    % Isolate the SOURCE intensity RIN comparison from reflection bias.
    set_param(straySwitch,'Value','0');
else
    restoreState=onCleanup(@()set_param(switchPath,'sw',savedState));
end

extraEffects=E01_disable_effects_for_test(model,false);
cfg=E01_config();
modes=["LASER","ASE"];
runData=cell(1,2);
rms_uA=zeros(1,2);
for k=1:2
    if k==1
        set_param(switchPath,'sw','1');
    else
        set_param(switchPath,'sw','0');
    end
    simOut=sim(model);
    pd=simOut.get('E01_prad_fotodiody');
    residual=simOut.get('E01_fluktuacje_fotodiody_uA');

    pd_t=pd.time(:);
    pd_A=pd.signals.values(:);
    residual_t=residual.time(:);
    residual_uA=residual.signals.values(:);
    assert(all(isfinite(pd_A)) && all(isfinite(residual_uA)), ...
        'Model zwrocil niefinitywne dane.');
    assert(numel(pd_t)==numel(residual_t), ...
        'Niezgodne probkowanie sygnalow diagnostycznych.');
    runData{k}=struct('time_s',pd_t,'photodiode_A',pd_A, ...
        'residual_uA',residual_uA);
    rms_uA(k)=sqrt(mean(residual_uA.^2));
end
clear restoreState

% The full current is dominated by phase modulation; zoom to 4 periods.
fig=figure('Name','FOG E01: Porównanie LASER i ASE','Color','w');
tiledlayout(fig,3,1,'TileSpacing','compact');

nexttile;hold on;grid on;
for k=1:2
    q=runData{k};
    plot(q.time_s*1e6,q.photodiode_A*1e6, ...
        'LineWidth',1.0,'DisplayName',char(modes(k)));
end
xlim([0,4/cfg.fm_Hz*1e6]);
ylabel('Prąd fotodiody [µA]');
title('Pełny sygnał Sagnaca: średnia prawie identyczna');
legend('show');

nexttile;hold on;grid on;
for k=1:2
    q=runData{k};
    plot(q.time_s*1e6,q.residual_uA, ...
        'LineWidth',1.0,'DisplayName',char(modes(k)));
end
xlim([0,4/cfg.fm_Hz*1e6]);
ylabel('Fluktuacje fotodiody [µA]');
title('Szum: prąd zaszumiony minus sygnał idealny');
legend('show');

nexttile;grid on;
bar(rms_uA);
set(gca,'XTick',1:2,'XTickLabel',{'LASER','ASE'});
ylabel('RMS szumu [µA]');
title('Porównanie RMS fluktuacji dla tej samej cewki');

fprintf('\nPorownanie LASER / ASE (DEMO, identyczna geometria):\n');
fprintf(' LASER: RMS szumu fotodiody = %.6g uA\n',rms_uA(1));
fprintf(' ASE:   RMS szumu fotodiody = %.6g uA\n',rms_uA(2));
if rms_uA(1)>0
    fprintf(' ASE / LASER: %.1f razy wieksze RMS przy DEMO RIN\n', ...
        rms_uA(2)/rms_uA(1));
end
fprintf('To porownanie przykladowych parametrow, nie pomiar.\n');
report=struct('sources',modes,'rms_noise_uA',rms_uA, ...
    'laser',runData{1},'ase',runData{2},'figure',fig);
end

function restoreModes(sw,oldSource,stray,oldStray)
set_param(sw,'sw',oldSource);
set_param(stray,'Value',oldStray);
end
