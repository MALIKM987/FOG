function report=sweep_E01_simulink(nPoints)
%SWEEP_E01_SIMULINK Zmierz I_fotodiody(Omega) z prawdziwych symulacji .slx.
%
%   report = sweep_E01_simulink();    % 21 predkosci katowych (-30..+30 deg/s)
%   report = sweep_E01_simulink(41);  % gestsze probkowanie charakterystyki
%
% FOUR curves: LASER/ASE with and without parasitic optical reflection.
% In each run: actual To Workspace current from SIMULINK, NOT an analytic
% curve. We compute mean current and first lock-in harmonic from that time
% trace. To distinguish source-coherence bias from stochastic laser/ASE
% intensity fluctuations, RIN is TEMPORARILY ZEROED for the sweep.
% All source/switch/omega/stray/RIN block settings are restored on exit.
% Does not save modified .slx or change the experiment's original omega.
%
% Results remain hypothetical: one detector-side stray field, not full
% Rayleigh backscatter, PMD, polarization or thermal electronics.

if nargin<1 || isempty(nPoints)
    nPoints=21;
end
assert(isscalar(nPoints)&&nPoints==floor(nPoints) && ...
    nPoints>=5 && nPoints<=201, ...
    'nPoints musi byc liczba calkowita od 5 do 201.');

here=fileparts(mfilename('fullpath'));
addpath(here,'-begin');
model='FOG_E01_SIMULINK';
if ~bdIsLoaded(model)
    f=fullfile(here,[model '.slx']);
    assert(isfile(f),'Brak schematu .slx. Zbuduj go najpierw.');
    load_system(f);
end
stray=[model '/Tor pasozytniczy - odbicie'];
assert(getSimulinkBlockHandle(stray)~=-1, ...
    ['Model nie zawiera toru pasozytniczego. ', ...
    'Zapisz schemat i wykonaj add_E01_parasitics().']);

cfg=E01_config();
omega=linspace(-30,30,nPoints).';
sourceSwitch=[model '/WYBOR ZRODLA - kliknij 2x'];
rot=[model '/Predkosc katowa [deg_s]'];
strayEnable=[model '/Odbicie 0=wyl 1=wl'];
noiseBlocks={ ...
    [model '/LASER - zrodlo/Szum intensywnosci RIN'], ...
    [model '/ASE - zrodlo/Szum intensywnosci RIN']};
names={'LASER','ASE'};
switchVals={'1','0'};
enableVals={'0','1'};
original=struct();
original.sw=get_param(sourceSwitch,'sw');
original.rotation=get_param(rot,'Value');
original.stray=get_param(strayEnable,'Value');
original.v1=get_param(noiseBlocks{1},'Variance');
original.v2=get_param(noiseBlocks{2},'Variance');
restore=onCleanup(@()restoreOriginal( ...
    sourceSwitch,rot,strayEnable,noiseBlocks,original));

% Temporarily disable source RIN. The comparison then measures the
% deterministic current-voltage (?) optical interference effect only.
set_param(noiseBlocks{1},'Variance','0');
set_param(noiseBlocks{2},'Variance','0');

average_uA=zeros(nPoints,2,2);
firstHarmonic_uA=zeros(nPoints,2,2);
for m=1:2
    set_param(sourceSwitch,'sw',switchVals{m});
    for p=1:2
        set_param(strayEnable,'Value',enableVals{p});
        for j=1:nPoints
            set_param(rot,'Value',sprintf('%.16g',omega(j)));
            result=sim(model);
            sig=result.get('E01_prad_fotodiody');
            tt=sig.time(:);
            ii=sig.signals.values(:);
            assert(numel(ii)>10 && all(isfinite(ii)), ...
                'Niewlasciwy przebieg fotodiody z Simulinka.');
            % Discard the endpoint if exactly at the next period; use
            % time-driven quadrature so changing step count is harmless.
            if numel(tt)>2 && tt(end)>=cfg.n_periods/cfg.fm_Hz - 1e-12
                ii=ii(1:end-1);
                tt=tt(1:end-1);
            end
            average_uA(j,m,p)=mean(ii)*1e6;
            lockinRef=cos(2*pi*cfg.fm_Hz*(tt-cfg.tau_s/2));
            firstHarmonic_uA(j,m,p)=2*mean(ii.*lockinRef)*1e6;
        end
        fprintf('%s | odbicie %s: wykonano %d symulacji.\n', ...
            names{m},enableVals{p},nPoints);
    end
end
clear restore

labels={'LASER bez odbicia','LASER z odbiciem', ...
    'ASE bez odbicia','ASE z odbiciem'};
fig1=figure('Color','w','Name','FOG: sredni prad fotodiody od predkosci katowej');
hold on;grid on;
plot(omega,average_uA(:,1,1),'LineWidth',1.5, ...
    'DisplayName',labels{1});
plot(omega,average_uA(:,1,2),'LineWidth',1.5, ...
    'DisplayName',labels{2});
plot(omega,average_uA(:,2,1),'LineWidth',1.5, ...
    'DisplayName',labels{3});
plot(omega,average_uA(:,2,2),'LineWidth',1.5, ...
    'DisplayName',labels{4});
xlabel('Prędkość kątowa \Omega [°/s]');
ylabel('Średni prąd fotodiody [µA]');
title('FOG: prąd fotodiody od prędkości kątowej, LASER i ASE');
legend('show','Location','best');

fig2=figure('Color','w','Name','FOG: sygnal po demodulacji od predkosci katowej');
hold on;grid on;
plot(omega,firstHarmonic_uA(:,1,1),'LineWidth',1.5, ...
    'DisplayName',labels{1});
plot(omega,firstHarmonic_uA(:,1,2),'LineWidth',1.5, ...
    'DisplayName',labels{2});
plot(omega,firstHarmonic_uA(:,2,1),'LineWidth',1.5, ...
    'DisplayName',labels{3});
plot(omega,firstHarmonic_uA(:,2,2),'LineWidth',1.5, ...
    'DisplayName',labels{4});
xlabel('Prędkość kątowa \Omega [°/s]');
ylabel('Pierwsza harmoniczna prądu I_1 [µA]');
title('FOG: sygnał po demodulacji rozróżnia znak obrotu');
legend('show','Location','best');

% Use a unique output directory rather than overwriting previous results.
resDir=fullfile(here,'..','..','results', ...
    ['EXP_E01_sweep_Simulink_' datestr(now,'yyyymmdd_HHMMSS_FFF')]);
mkdir(resDir);
T=table(omega,average_uA(:,1,1),average_uA(:,1,2), ...
    average_uA(:,2,1),average_uA(:,2,2), ...
    firstHarmonic_uA(:,1,1),firstHarmonic_uA(:,1,2), ...
    firstHarmonic_uA(:,2,1),firstHarmonic_uA(:,2,2), ...
    'VariableNames',{'omega_deg_s', ...
    'LASER_ideal_mean_uA','LASER_stray_mean_uA', ...
    'ASE_ideal_mean_uA','ASE_stray_mean_uA', ...
    'LASER_ideal_I1_uA','LASER_stray_I1_uA', ...
    'ASE_ideal_I1_uA','ASE_stray_I1_uA'});
writetable(T,fullfile(resDir,'prad_od_predkosci_katowej.csv'));
savefig(fig1,fullfile(resDir,'prad_sredni_od_Omega.fig'));
savefig(fig2,fullfile(resDir,'pierwsza_harmoniczna_od_Omega.fig'));
fprintf('\nWyniki w formacie CSV oraz edytowalne wykresy FIG:\n%s\n',resDir);
fprintf('Sredni prad jest zasadniczo parzysty wzgledem obrotu.\n');
fprintf('I1 po demodulacji zmienia znak wraz z obrotem.\n');
fprintf('UWAGA: odbicie to pojedyncza droga DEMO, a nie model Rayleigha.\n');

report=struct('omega_deg_s',omega,'source_names',{names}, ...
    'mean_current_uA',average_uA, ...
    'first_harmonic_uA',firstHarmonic_uA, ...
    'results_folder',resDir,'mean_figure',fig1, ...
    'lockin_figure',fig2,'table',T);
end

function restoreOriginal(s,rot,strayEnable,noiseBlocks,old)
set_param(s,'sw',old.sw);
set_param(rot,'Value',old.rotation);
set_param(strayEnable,'Value',old.stray);
set_param(noiseBlocks{1},'Variance',old.v1);
set_param(noiseBlocks{2},'Variance',old.v2);
end
