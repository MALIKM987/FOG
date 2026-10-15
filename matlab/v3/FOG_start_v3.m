%% ============================================================
% FOG_start_v3.m
% Interferometryczny zyroskop swiatlowodowy - model v3
% MATLAB / Simulink R2023b
%
% v3:
% - zachowuje fizyke v2.1,
% - dodaje jawny bilans mocy i straty optyczne,
% - grupuje rownania w wieksze podsystemy odpowiadajace
%   fizycznym blokom rzeczywistego FOG.
%
% TOP LEVEL:
%
% Optical Source
%      |
%      v
% Optical Front End <---------------------------+
% K1 + POL + DEP                                |
%      |                                        |
%      v                                        |
% Sagnac Interferometer                         |
% K2 + 1 km Coil + PZT -------------------------+
%      |
%      +---- reference --------------------+
%                                        |
% Optical Front End -> Photoreceiver -> Lock-In DSP -> Omega
%
% UWAGA:
% Wartosc strat w v3 to NOMINALNE zalozenia modelowe.
% Nie sa jeszcze zatwierdzonym BOM-em. W kolejnych iteracjach
% podstawimy rzeczywiste dane elementow z laboratorium/katalogow.
%% ============================================================

clc
close all
bdclose('all')

disp("==============================================")
disp(" FOG v3 - FIZYCZNA ARCHITEKTURA + BILANS MOCY")
disp("==============================================")

%% ============================================================
% PARAMETRY FIZYCZNE FOG
%% ============================================================

c = 299792458;
lambda = 1550e-9;
L = 1000;
D = 0.160;
ng = 1.4682;

K_sag = 2*pi*L*D/(lambda*c);
tau = ng*L/c;
f_opt = 1/(2*tau);

%% ============================================================
% MODULATOR PZT
%% ============================================================

beta_target = 1.84;
f_mod = 20e3;

phi0 = beta_target / ...
    (2*abs(sin(pi*f_mod*tau)));

beta_eff = 2*phi0*abs(sin(pi*f_mod*tau));

%% ============================================================
% NOMINALNE PARAMETRY MOCY I STRAT
% Wszystkie wartosci ponizej sa parametrami modelu v3.
%% ============================================================

% Zrodlo
P_source_W = 1.0e-3;             % 1 mW

% K1: sprzegacz wejscie/powrot
K1_launch_ratio = 0.50;          % czesc mocy kierowana do interferometru
K1_detector_ratio = 0.50;        % czesc powrotu kierowana do detektora
IL_K1_dB = 0.20;                 % excess/insertion loss na przejscie

% Wspolna optyka
IL_connector_common_dB = 0.20;   % jedno polaczenie na kazdym przejsciu
IL_polarizer_dB = 0.80;          % polaryzator na przejscie
IL_depolarizer_dB = 0.30;        % depolaryzator na przejscie

% K2: sprzegacz petli
K2_split_ratio = 0.50;
IL_K2_dB = 0.20;                 % na kazde przejscie przez K2

% Cewka / petla
alpha_fiber_dB_km = 0.20;        % SMF przy 1550 nm
IL_PZT_dB = 0.50;
N_loop_splices = 6;
IL_splice_dB = 0.05;

% Interferencja
visibility = 1.0;

% Fotodioda / TIA
Rpd = 0.9;                       % A/W
Rtia = 20e3;                     % V/A

% Robocze okno mocy odbiornika, NIE karta katalogowa
Pdet_design_min_W = 1e-6;
Pdet_design_max_W = 100e-6;

%% ============================================================
% KONWERSJA STRAT dB -> TRANSMISJA MOCY
%% ============================================================

eta_K1 = 10^(-IL_K1_dB/10);
eta_conn = 10^(-IL_connector_common_dB/10);
eta_pol = 10^(-IL_polarizer_dB/10);
eta_dep = 10^(-IL_depolarizer_dB/10);

eta_K2 = 10^(-IL_K2_dB/10);

IL_coil_dB = alpha_fiber_dB_km*(L/1000);
eta_coil = 10^(-IL_coil_dB/10);

eta_PZT = 10^(-IL_PZT_dB/10);

IL_loop_splices_dB = N_loop_splices*IL_splice_dB;
eta_splices = 10^(-IL_loop_splices_dB/10);

eta_loop = eta_coil*eta_PZT*eta_splices;

%% ============================================================
% WSPOLCZYNNIKI PODSYSTEMOW
%% ============================================================

% Forward przez K1 + connector + polarizer + depolarizer.
K_front_forward = ...
    K1_launch_ratio * eta_K1 * eta_conn * eta_pol * eta_dep;

% K2: split + powrot przez ten sam K2.
%
% Dla wybranego portu powrotnego skala srednia interferencji:
% 2*r*(1-r), a K2 jest pokonywany dwa razy.
K_sagnac_power = ...
    2*K2_split_ratio*(1-K2_split_ratio) * eta_K2^2 * eta_loop;

% Powrot przez depolarizer + polarizer + connector + K1.
K_front_return = ...
    eta_dep * eta_pol * eta_conn * ...
    K1_detector_ratio * eta_K1;

% Skala mocy przy fotodiodzie:
% P_det(t) = Pdet_scale * [1 + V*cos(Delta_phi)]
Pdet_scale_W = ...
    P_source_W * K_front_forward * ...
    K_sagnac_power * K_front_return;

%% ============================================================
% DEMODULACJA v2.1
%% ============================================================

fc_lp = 300;
lp_order = 4;
[b_lp,a_lp] = butter(lp_order,2*pi*fc_lp,'s');

K_ref = 1/beta_eff;
J1beta = besselj(1,beta_eff);

K_norm = ...
    -1/(Pdet_scale_W*visibility*Rpd*Rtia*J1beta);

K_phase_to_deg = (180/pi)/K_sag;

%% ============================================================
% PARAMETRY NUMERYCZNE
%% ============================================================

Ts_solver = 2e-7;
Tstop = 0.050;
Tmean_window = 0.010;
Tmean_start = Tstop-Tmean_window;
Tbeta_start = 0.005;

%% ============================================================
% ANALITYCZNY BILANS MOCY
%% ============================================================

P0 = P_source_W;

P1 = P0*K1_launch_ratio*eta_K1;
P2 = P1*eta_conn;
P3 = P2*eta_pol;
P4 = P3*eta_dep;

P5 = P4*K_sagnac_power;

P6 = P5*eta_dep;
P7 = P6*eta_pol;
P8 = P7*eta_conn;
P9 = P8*K1_detector_ratio*eta_K1;

stage = [ ...
    "Source"; ...
    "After_K1_launch"; ...
    "After_common_connector_forward"; ...
    "After_polarizer_forward"; ...
    "After_depolarizer_forward"; ...
    "K2_loop_return_scale"; ...
    "After_depolarizer_return"; ...
    "After_polarizer_return"; ...
    "After_common_connector_return"; ...
    "Detector_interference_scale" ...
    ];

power_W = [P0;P1;P2;P3;P4;P5;P6;P7;P8;P9];
power_uW = power_W*1e6;

cumulative_loss_dB = -10*log10(power_W/P0);

step_loss_dB = zeros(size(power_W));

for k = 2:numel(power_W)
    step_loss_dB(k) = -10*log10(power_W(k)/power_W(k-1));
end

powerBudget = table( ...
    stage, ...
    power_W, ...
    power_uW, ...
    step_loss_dB, ...
    cumulative_loss_dB, ...
    'VariableNames', ...
    { ...
    'Stage', ...
    'Power_W', ...
    'Power_uW', ...
    'Step_loss_dB', ...
    'Cumulative_loss_dB' ...
    });

writetable(powerBudget,'FOG_v3_power_budget.csv');

%% ------------------------------------------------------------
% PRZEWIDYWANA MOC DETEKTORA
%% ------------------------------------------------------------

% Maksimum teoretyczne fringe factor = 2.
Pdet_peak_theory_W = 2*Pdet_scale_W;

% Srednia czasowa dla sinusoidalnej modulacji:
% <cos(phiS + beta*cos)> = J0(beta)*cos(phiS)
Omega_deg_s = 1;
phiS_baseline = K_sag*(Omega_deg_s*pi/180);

Pdet_avg_theory_W = ...
    Pdet_scale_W * ...
    (1 + visibility*besselj(0,beta_eff)*cos(phiS_baseline));

fprintf("\nPARAMETRY FOG\n")
fprintf("---------------------------------\n")
fprintf("lambda              = %.1f nm\n",lambda*1e9)
fprintf("L                   = %.0f m\n",L)
fprintf("D                   = %.1f mm\n",D*1000)
fprintf("tau                 = %.6f us\n",tau*1e6)
fprintf("f_opt               = %.3f kHz\n",f_opt/1e3)

fprintf("\nNOMINALNY BILANS MOCY\n")
fprintf("---------------------------------\n")
fprintf("P source            = %.3f mW\n",P_source_W*1e3)
fprintf("P to loop           = %.3f uW\n",P4*1e6)
fprintf("P detector scale    = %.3f uW\n",Pdet_scale_W*1e6)
fprintf("P detector avg est. = %.3f uW\n",Pdet_avg_theory_W*1e6)
fprintf("P detector peak max = %.3f uW\n",Pdet_peak_theory_W*1e6)
fprintf("Total scale loss    = %.3f dB\n",-10*log10(Pdet_scale_W/P_source_W))

if Pdet_peak_theory_W > Pdet_design_max_W
    warning("Teoretyczny peak mocy przekracza roboczy limit odbiornika %.1f uW.", ...
        Pdet_design_max_W*1e6)
end

if Pdet_avg_theory_W < Pdet_design_min_W
    warning("Srednia moc jest ponizej roboczego minimum odbiornika %.1f uW.", ...
        Pdet_design_min_W*1e6)
end

%% ============================================================
% SWEEP MOCY ZRODLA - ANALITYCZNY
%% ============================================================

sourceSweep_mW = [0.5 1.0 2.0 3.0]';
sourceSweep_W = sourceSweep_mW*1e-3;

scaleSweep_W = ...
    sourceSweep_W*K_front_forward*K_sagnac_power*K_front_return;

avgSweep_W = ...
    scaleSweep_W .* ...
    (1 + visibility*besselj(0,beta_eff)*cos(phiS_baseline));

peakSweep_W = 2*scaleSweep_W;

withinDesignPeak = peakSweep_W <= Pdet_design_max_W;

sourcePowerSweep = table( ...
    sourceSweep_mW, ...
    scaleSweep_W*1e6, ...
    avgSweep_W*1e6, ...
    peakSweep_W*1e6, ...
    withinDesignPeak, ...
    'VariableNames', ...
    { ...
    'P_source_mW', ...
    'Pdet_scale_uW', ...
    'Pdet_avg_uW', ...
    'Pdet_peak_theory_uW', ...
    'Peak_within_100uW_design_target' ...
    });

writetable(sourcePowerSweep,'FOG_v3_source_power_sweep.csv');

%% ============================================================
% BUDOWA HIERARCHICZNEGO MODELU SIMULINK
%% ============================================================

mdl = 'FOG_v3';

if bdIsLoaded(mdl)
    close_system(mdl,0)
end

if isfile([mdl '.slx'])
    delete([mdl '.slx'])
end

new_system(mdl);
open_system(mdl);

set_param(mdl,'Location',[40 60 1550 720]);

%% ------------------------------------------------------------
% TOP-LEVEL: FIZYCZNE BLOKI
%% ------------------------------------------------------------

add_block( ...
    'simulink/Sources/Constant', ...
    [mdl '/Rotation Input'], ...
    'Value','Omega_deg_s', ...
    'Position',[450 500 540 540]);

add_block( ...
    'simulink/Ports & Subsystems/Subsystem', ...
    [mdl '/Optical Source'], ...
    'Position',[60 170 190 260]);

add_block( ...
    'simulink/Ports & Subsystems/Subsystem', ...
    [mdl '/Optical Front End'], ...
    'Position',[270 140 440 300]);

add_block( ...
    'simulink/Ports & Subsystems/Subsystem', ...
    [mdl '/Sagnac Interferometer'], ...
    'Position',[540 130 750 330]);

add_block( ...
    'simulink/Ports & Subsystems/Subsystem', ...
    [mdl '/Photoreceiver'], ...
    'Position',[850 170 1000 260]);

add_block( ...
    'simulink/Ports & Subsystems/Subsystem', ...
    [mdl '/Lock-In DSP'], ...
    'Position',[1090 140 1260 300]);

add_block( ...
    'simulink/Sinks/Display', ...
    [mdl '/Omega Display'], ...
    'Position',[1340 175 1440 225]);

% Monitory do workspace.
add_block( ...
    'simulink/Sinks/To Workspace', ...
    [mdl '/Save_Pdet'], ...
    'VariableName','pdet_ts', ...
    'SaveFormat','Timeseries', ...
    'Position',[860 340 970 380]);

add_block( ...
    'simulink/Sinks/To Workspace', ...
    [mdl '/Save_Omega'], ...
    'VariableName','omega_est_ts', ...
    'SaveFormat','Timeseries', ...
    'Position',[1340 270 1450 310]);

%% ------------------------------------------------------------
% WNETRZA PODSYSTEMOW
%% ------------------------------------------------------------

buildOpticalSource([mdl '/Optical Source']);
buildOpticalFrontEnd([mdl '/Optical Front End']);
buildSagnac([mdl '/Sagnac Interferometer']);
buildPhotoreceiver([mdl '/Photoreceiver']);
buildDSP([mdl '/Lock-In DSP']);

%% ------------------------------------------------------------
% OPISY BLOKOW
%% ------------------------------------------------------------

set_param([mdl '/Optical Source'], ...
    'BackgroundColor','yellow', ...
    'AttributesFormatString','SLD/ASE nominal: 1 mW');

set_param([mdl '/Optical Front End'], ...
    'BackgroundColor','cyan', ...
    'AttributesFormatString','K1 + connector + polarizer + depolarizer');

set_param([mdl '/Sagnac Interferometer'], ...
    'BackgroundColor','cyan', ...
    'AttributesFormatString','K2 + 1000 m SMF + PZT');

set_param([mdl '/Photoreceiver'], ...
    'BackgroundColor','green', ...
    'AttributesFormatString','InGaAs 0.9 A/W + TIA 20 kOhm');

set_param([mdl '/Lock-In DSP'], ...
    'BackgroundColor','green', ...
    'AttributesFormatString','Mixer + Butterworth LPF + asin');

%% ------------------------------------------------------------
% TOP-LEVEL POLACZENIA
%% ------------------------------------------------------------

% Source -> Front End input 1.
add_line(mdl,'Optical Source/1','Optical Front End/1','autorouting','on');

% Forward optical path -> Sagnac input 1.
add_line(mdl,'Optical Front End/1','Sagnac Interferometer/1','autorouting','on');

% Rotation -> Sagnac input 2.
add_line(mdl,'Rotation Input/1','Sagnac Interferometer/2','autorouting','on');

% Sagnac optical return -> Front End return input 2.
add_line(mdl,'Sagnac Interferometer/1','Optical Front End/2','autorouting','on');

% Front End detector output -> Photoreceiver.
add_line(mdl,'Optical Front End/2','Photoreceiver/1','autorouting','on');

% Branch optical detector power to logger.
add_line(mdl,'Optical Front End/2','Save_Pdet/1','autorouting','on');

% Photoreceiver voltage -> DSP input 1.
add_line(mdl,'Photoreceiver/1','Lock-In DSP/1','autorouting','on');

% Sagnac modulation reference -> DSP input 2.
add_line(mdl,'Sagnac Interferometer/2','Lock-In DSP/2','autorouting','on');

% DSP -> display/logger.
add_line(mdl,'Lock-In DSP/1','Omega Display/1','autorouting','on');
add_line(mdl,'Lock-In DSP/1','Save_Omega/1','autorouting','on');

%% ============================================================
% PARAMETRY SYMULACJI
%% ============================================================

set_param(mdl, ...
    'SolverType','Fixed-step', ...
    'Solver','ode4', ...
    'FixedStep','Ts_solver', ...
    'StopTime','Tstop', ...
    'ReturnWorkspaceOutputs','on');

save_system(mdl);

%% ============================================================
% WALIDACJA v3
%% ============================================================

disp("")
disp("==============================================")
disp(" WALIDACJA v3: 1 deg/s")
disp("==============================================")

Omega_deg_s = 1;

out = sim(mdl);

omega_ts = out.get('omega_est_ts');
pdet_ts = out.get('pdet_ts');

idxOmega = omega_ts.Time >= Tmean_start;
idxP = pdet_ts.Time >= Tmean_start;

Omega_mean = mean(omega_ts.Data(idxOmega));
Omega_std = std(omega_ts.Data(idxOmega));

Pdet_mean_sim_W = mean(pdet_ts.Data(idxP));
Pdet_min_sim_W = min(pdet_ts.Data(idxP));
Pdet_max_sim_W = max(pdet_ts.Data(idxP));

fprintf("Omega zadane       = %.9f deg/s\n",Omega_deg_s)
fprintf("Omega zmierzone    = %.9f deg/s\n",Omega_mean)
fprintf("Blad Omega         = %.9f deg/s\n",Omega_mean-Omega_deg_s)
fprintf("STD Omega          = %.9f deg/s\n",Omega_std)

fprintf("\nMOC NA FOTODIODZIE\n")
fprintf("---------------------------------\n")
fprintf("teoria avg         = %.6f uW\n",Pdet_avg_theory_W*1e6)
fprintf("symulacja avg      = %.6f uW\n",Pdet_mean_sim_W*1e6)
fprintf("symulacja min      = %.6f uW\n",Pdet_min_sim_W*1e6)
fprintf("symulacja max      = %.6f uW\n",Pdet_max_sim_W*1e6)
fprintf("teoria peak limit  = %.6f uW\n",Pdet_peak_theory_W*1e6)

powerErrorPct = ...
    100*(Pdet_mean_sim_W-Pdet_avg_theory_W)/Pdet_avg_theory_W;

fprintf("blad avg teoria/sim= %.6f %%\n",powerErrorPct)

%% ------------------------------------------------------------
% WYNIK BASELINE
%% ------------------------------------------------------------

baseline = table( ...
    Omega_deg_s, ...
    Omega_mean, ...
    Omega_mean-Omega_deg_s, ...
    Omega_std, ...
    P_source_W*1e3, ...
    Pdet_scale_W*1e6, ...
    Pdet_avg_theory_W*1e6, ...
    Pdet_mean_sim_W*1e6, ...
    Pdet_min_sim_W*1e6, ...
    Pdet_max_sim_W*1e6, ...
    Pdet_peak_theory_W*1e6, ...
    powerErrorPct, ...
    'VariableNames', ...
    { ...
    'Omega_zadane_deg_s', ...
    'Omega_zmierzone_deg_s', ...
    'Blad_Omega_deg_s', ...
    'STD_Omega_deg_s', ...
    'P_source_mW', ...
    'Pdet_scale_uW', ...
    'Pdet_avg_teoria_uW', ...
    'Pdet_avg_symulacja_uW', ...
    'Pdet_min_symulacja_uW', ...
    'Pdet_max_symulacja_uW', ...
    'Pdet_peak_theory_uW', ...
    'Blad_mocy_avg_percent' ...
    });

writetable(baseline,'FOG_v3_baseline.csv');

%% ------------------------------------------------------------
% WYKRES BUDZETU MOCY
%% ------------------------------------------------------------

figure('Name','FOG v3 - power budget');

plot( ...
    1:numel(power_uW), ...
    power_uW, ...
    'o-', ...
    'LineWidth',1.5);

grid on
set(gca,'XTick',1:numel(stage));
set(gca,'XTickLabel',stage);
xtickangle(35);

ylabel('Moc / skala mocy [uW]');
title('FOG v3 - nominalny bilans mocy');

%% ------------------------------------------------------------
% WYKRES SWEEP ZRODLA
%% ------------------------------------------------------------

figure('Name','FOG v3 - source power sweep');

plot(sourceSweep_mW,avgSweep_W*1e6,'o-','LineWidth',1.5);
hold on
plot(sourceSweep_mW,peakSweep_W*1e6,'s--','LineWidth',1.5);

grid on
xlabel('Moc zrodla [mW]');
ylabel('Moc na fotodiodzie [uW]');
legend('srednia przy 1 deg/s','teoretyczny peak','Location','best');
title('FOG v3 - wplyw mocy zrodla na odbiornik');

%% ------------------------------------------------------------
% KONIEC
%% ------------------------------------------------------------

save_system(mdl);
open_system(mdl);

disp("")
disp("==============================================")
disp(" FOG v3 - SYMULACJA ZAKONCZONA")
disp("==============================================")
disp("")
disp("Utworzono:")
disp("  FOG_v3.slx")
disp("  FOG_v3_power_budget.csv")
disp("  FOG_v3_source_power_sweep.csv")
disp("  FOG_v3_baseline.csv")
disp("")
disp("Na poziomie glownym model pokazuje fizyczne bloki FOG.")
disp("Dwuklik na subsystem otwiera jego model matematyczny.")
disp("")

%% ============================================================
% FUNKCJE BUDUJACE FIZYCZNE PODSYSTEMY
%% ============================================================

function buildOpticalSource(sub)

    Simulink.SubSystem.deleteContents(sub);

    add_block( ...
        'simulink/Sources/Constant', ...
        [sub '/Optical Power'], ...
        'Value','P_source_W', ...
        'Position',[70 60 150 100]);

    add_block( ...
        'simulink/Ports & Subsystems/Out1', ...
        [sub '/P_source'], ...
        'Port','1', ...
        'Position',[230 68 260 92]);

    add_line(sub,'Optical Power/1','P_source/1','autorouting','on');
end

function buildOpticalFrontEnd(sub)

    Simulink.SubSystem.deleteContents(sub);

    % Ports
    add_block('simulink/Ports & Subsystems/In1', ...
        [sub '/Source_Input'], ...
        'Port','1', ...
        'Position',[25 60 55 80]);

    add_block('simulink/Ports & Subsystems/In1', ...
        [sub '/Loop_Return'], ...
        'Port','2', ...
        'Position',[25 250 55 270]);

    add_block('simulink/Ports & Subsystems/Out1', ...
        [sub '/To_Loop'], ...
        'Port','1', ...
        'Position',[650 65 680 85]);

    add_block('simulink/Ports & Subsystems/Out1', ...
        [sub '/To_Detector'], ...
        'Port','2', ...
        'Position',[650 255 680 275]);

    % Forward
    add_block('simulink/Math Operations/Gain', ...
        [sub '/K1 Launch'], ...
        'Gain','K1_launch_ratio*eta_K1', ...
        'Position',[100 45 190 95]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/Connector FWD'], ...
        'Gain','eta_conn', ...
        'Position',[230 45 320 95]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/Polarizer FWD'], ...
        'Gain','eta_pol', ...
        'Position',[360 45 450 95]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/Depolarizer FWD'], ...
        'Gain','eta_dep', ...
        'Position',[490 45 590 95]);

    % Return
    add_block('simulink/Math Operations/Gain', ...
        [sub '/Depolarizer RET'], ...
        'Gain','eta_dep', ...
        'Position',[100 235 200 285]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/Polarizer RET'], ...
        'Gain','eta_pol', ...
        'Position',[240 235 330 285]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/Connector RET'], ...
        'Gain','eta_conn', ...
        'Position',[370 235 460 285]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/K1 Detector'], ...
        'Gain','K1_detector_ratio*eta_K1', ...
        'Position',[500 235 600 285]);

    % Lines
    add_line(sub,'Source_Input/1','K1 Launch/1','autorouting','on');
    add_line(sub,'K1 Launch/1','Connector FWD/1','autorouting','on');
    add_line(sub,'Connector FWD/1','Polarizer FWD/1','autorouting','on');
    add_line(sub,'Polarizer FWD/1','Depolarizer FWD/1','autorouting','on');
    add_line(sub,'Depolarizer FWD/1','To_Loop/1','autorouting','on');

    add_line(sub,'Loop_Return/1','Depolarizer RET/1','autorouting','on');
    add_line(sub,'Depolarizer RET/1','Polarizer RET/1','autorouting','on');
    add_line(sub,'Polarizer RET/1','Connector RET/1','autorouting','on');
    add_line(sub,'Connector RET/1','K1 Detector/1','autorouting','on');
    add_line(sub,'K1 Detector/1','To_Detector/1','autorouting','on');
end

function buildSagnac(sub)

    Simulink.SubSystem.deleteContents(sub);

    % Inputs
    add_block('simulink/Ports & Subsystems/In1', ...
        [sub '/P_in'], ...
        'Port','1', ...
        'Position',[25 75 55 95]);

    add_block('simulink/Ports & Subsystems/In1', ...
        [sub '/Omega_deg_s'], ...
        'Port','2', ...
        'Position',[25 285 55 305]);

    % Outputs
    add_block('simulink/Ports & Subsystems/Out1', ...
        [sub '/P_return'], ...
        'Port','1', ...
        'Position',[950 80 980 100]);

    add_block('simulink/Ports & Subsystems/Out1', ...
        [sub '/Reference'], ...
        'Port','2', ...
        'Position',[950 330 980 350]);

    % Optical power scale from K2 + loop losses
    add_block('simulink/Math Operations/Gain', ...
        [sub '/K2 + Loop Loss'], ...
        'Gain','K_sagnac_power', ...
        'Position',[100 55 220 105]);

    % Sagnac rotation phase
    add_block('simulink/Math Operations/Gain', ...
        [sub '/deg_to_rad'], ...
        'Gain','pi/180', ...
        'Position',[100 270 180 320]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/Sagnac Phase'], ...
        'Gain','K_sag', ...
        'Position',[220 270 310 320]);

    % PZT
    add_block('simulink/Sources/Sine Wave', ...
        [sub '/PZT phi_m'], ...
        'Amplitude','phi0', ...
        'Frequency','2*pi*f_mod', ...
        'Bias','0', ...
        'Phase','0', ...
        'SampleTime','0', ...
        'Position',[100 390 200 430]);

    add_block('simulink/Continuous/Transport Delay', ...
        [sub '/CW-CCW Delay'], ...
        'DelayTime','tau', ...
        'Position',[270 410 380 450]);

    add_block('simulink/Math Operations/Sum', ...
        [sub '/Delta phi mod'], ...
        'Inputs','+-', ...
        'Position',[440 365 475 445]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/Reference Normalize'], ...
        'Gain','K_ref', ...
        'Position',[550 405 660 455]);

    % Total phase
    add_block('simulink/Math Operations/Sum', ...
        [sub '/Total Phase'], ...
        'Inputs','++', ...
        'Position',[390 245 425 325]);

    add_block('simulink/Math Operations/Trigonometric Function', ...
        [sub '/Interference cos'], ...
        'Operator','cos', ...
        'Position',[500 250 590 300]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/Visibility'], ...
        'Gain','visibility', ...
        'Position',[640 250 720 300]);

    add_block('simulink/Math Operations/Bias', ...
        [sub '/Fringe +1'], ...
        'Bias','1', ...
        'Position',[760 250 840 300]);

    add_block('simulink/Math Operations/Product', ...
        [sub '/Optical Interference'], ...
        'Position',[860 70 910 130]);

    % Lines power
    add_line(sub,'P_in/1','K2 + Loop Loss/1','autorouting','on');
    add_line(sub,'K2 + Loop Loss/1','Optical Interference/1','autorouting','on');

    % Sagnac
    add_line(sub,'Omega_deg_s/1','deg_to_rad/1','autorouting','on');
    add_line(sub,'deg_to_rad/1','Sagnac Phase/1','autorouting','on');
    add_line(sub,'Sagnac Phase/1','Total Phase/1','autorouting','on');

    % PZT split
    add_line(sub,'PZT phi_m/1','Delta phi mod/1','autorouting','on');
    add_line(sub,'PZT phi_m/1','CW-CCW Delay/1','autorouting','on');
    add_line(sub,'CW-CCW Delay/1','Delta phi mod/2','autorouting','on');

    add_line(sub,'Delta phi mod/1','Total Phase/2','autorouting','on');
    add_line(sub,'Delta phi mod/1','Reference Normalize/1','autorouting','on');

    % Fringe
    add_line(sub,'Total Phase/1','Interference cos/1','autorouting','on');
    add_line(sub,'Interference cos/1','Visibility/1','autorouting','on');
    add_line(sub,'Visibility/1','Fringe +1/1','autorouting','on');
    add_line(sub,'Fringe +1/1','Optical Interference/2','autorouting','on');

    % Outputs
    add_line(sub,'Optical Interference/1','P_return/1','autorouting','on');
    add_line(sub,'Reference Normalize/1','Reference/1','autorouting','on');
end

function buildPhotoreceiver(sub)

    Simulink.SubSystem.deleteContents(sub);

    add_block('simulink/Ports & Subsystems/In1', ...
        [sub '/P_detector'], ...
        'Port','1', ...
        'Position',[25 80 55 100]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/InGaAs Photodiode'], ...
        'Gain','Rpd', ...
        'Position',[120 65 240 115]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/TIA'], ...
        'Gain','Rtia', ...
        'Position',[300 65 390 115]);

    add_block('simulink/Ports & Subsystems/Out1', ...
        [sub '/V_TIA'], ...
        'Port','1', ...
        'Position',[470 78 500 102]);

    add_line(sub,'P_detector/1','InGaAs Photodiode/1','autorouting','on');
    add_line(sub,'InGaAs Photodiode/1','TIA/1','autorouting','on');
    add_line(sub,'TIA/1','V_TIA/1','autorouting','on');
end

function buildDSP(sub)

    Simulink.SubSystem.deleteContents(sub);

    add_block('simulink/Ports & Subsystems/In1', ...
        [sub '/V_TIA'], ...
        'Port','1', ...
        'Position',[25 70 55 90]);

    add_block('simulink/Ports & Subsystems/In1', ...
        [sub '/Reference'], ...
        'Port','2', ...
        'Position',[25 180 55 200]);

    add_block('simulink/Math Operations/Product', ...
        [sub '/LockIn Mixer'], ...
        'Position',[120 90 170 150]);

    add_block('simulink/Continuous/Transfer Fcn', ...
        [sub '/Butterworth LPF'], ...
        'Numerator','b_lp', ...
        'Denominator','a_lp', ...
        'Position',[230 90 350 150]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/Normalize'], ...
        'Gain','K_norm', ...
        'Position',[410 95 490 145]);

    add_block('simulink/Discontinuities/Saturation', ...
        [sub '/Limit asin'], ...
        'UpperLimit','0.999999', ...
        'LowerLimit','-0.999999', ...
        'Position',[550 95 640 145]);

    add_block('simulink/Math Operations/Trigonometric Function', ...
        [sub '/asin'], ...
        'Operator','asin', ...
        'Position',[700 95 770 145]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/Phase to deg-s'], ...
        'Gain','K_phase_to_deg', ...
        'Position',[830 90 940 150]);

    add_block('simulink/Ports & Subsystems/Out1', ...
        [sub '/Omega_est'], ...
        'Port','1', ...
        'Position',[1010 108 1040 132]);

    add_line(sub,'V_TIA/1','LockIn Mixer/1','autorouting','on');
    add_line(sub,'Reference/1','LockIn Mixer/2','autorouting','on');
    add_line(sub,'LockIn Mixer/1','Butterworth LPF/1','autorouting','on');
    add_line(sub,'Butterworth LPF/1','Normalize/1','autorouting','on');
    add_line(sub,'Normalize/1','Limit asin/1','autorouting','on');
    add_line(sub,'Limit asin/1','asin/1','autorouting','on');
    add_line(sub,'asin/1','Phase to deg-s/1','autorouting','on');
    add_line(sub,'Phase to deg-s/1','Omega_est/1','autorouting','on');
end
