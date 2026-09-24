%% ============================================================
% FOG_integrated_v8_1.m
% Interferometryczny zyroskop swiatlowodowy - model v8.1
% MATLAB / Simulink R2023b
%
% CEL:
% - zintegrowac zweryfikowany tor optyczny v6.x z closed-loop v8,
% - pozostawic jawne bloki: source/front-end/Sagnac/RX/ADC/DSP,
% - zamknac petle przez rzeczywisty residual z Digital Lock-In DSP,
% - dodac PI/NCO + equivalent differential feedback phase,
% - logowac phase slope i realna reset frequency wybranego aktuatora,
% - zweryfikowac 1 i 20 deg/s w pelnej sciezce optycznej,
% - sprawdzic 0.0001 deg/s pod pelnym szumem i polaryzacja.
%
% UWAGA FIZYCZNA:
% W Sagnac dodajemy rownowazna ROZNICOWA faze feedback:
%
%   Delta_phi_fb = -K_sag * Omega_fb_rad_s
%
% Jest ona fizycznym skutkiem rampy:
%
%   phi_fb(t)-phi_fb(t-tau) = slope*tau
%
% v8.1 NIE modeluje jeszcze samego ksztaltu impulsu resetu.
% Reset glitch pozostaje laboratoryjnym acceptance testem v8.
% Modeluje natomiast wymagany slope/reset rate oraz dynamike command.
%% ============================================================

clc
close all
bdclose('all')

disp("==============================================")
disp(" FOG v8.1 - INTEGRATED OPTICAL CLOSED LOOP")
disp("==============================================")

%% ============================================================
% WYBOR NAJNOWSZEGO FIZYCZNEGO MODELU
%% ============================================================

sourceCandidates = { ...
    'FOG_v6_3', ...
    'FOG_v6_2', ...
    'FOG_v6_1', ...
    'FOG_v6' ...
    };

sourceModel = "";

for k = 1:numel(sourceCandidates)

    if isfile([sourceCandidates{k} '.slx'])
        sourceModel = sourceCandidates{k};
        break
    end
end

if strlength(sourceModel) == 0
    error([ ...
        "Brak fizycznego modelu FOG_v6.x. " ...
        "Najpierw uruchom zweryfikowany v6/v6.2/v6.3." ...
        ])
end

fprintf("Source physical model = %s\n",sourceModel)

mdl = 'FOG_v8_1';

if isfile([mdl '.slx'])
    delete([mdl '.slx'])
end

load_system(sourceModel)
save_system(sourceModel,mdl)
close_system(sourceModel,0)
load_system(mdl)

set_param(mdl,'Location',[40 60 1750 850]);

%% ============================================================
% PARAMETRY FIZYCZNE
%% ============================================================

c = 299792458;
lambda = 1550e-9;

L = 1000;
D = 159.394500392266e-3;
ng = 1.4682;

K_sag = ...
    2*pi*L*D/(lambda*c);

tau = ...
    ng*L/c;

f_opt = ...
    1/(2*tau);

beta_target = 1.84;
f_mod = 20e3;

phi0 = ...
    beta_target/(2*abs(sin(pi*f_mod*tau)));

beta_eff = ...
    2*phi0*abs(sin(pi*f_mod*tau));

J1beta = ...
    besselj(1,beta_eff);

K_ref = ...
    1/beta_eff;

K_phase_to_deg = ...
    (180/pi)/K_sag;

slope_per_deg_s = ...
    K_sag*(pi/180)/tau;

wrap2pi_per_deg_s_Hz = ...
    slope_per_deg_s/(2*pi);

%% ============================================================
% OPTYKA / BUDZET MOCY
%% ============================================================

P_source_W = 1.0e-3;

K1_launch_ratio = 0.50;
K1_detector_ratio = 0.50;
IL_K1_dB = 0.20;

IL_connector_common_dB = 0.20;
IL_polarizer_dB = 0.80;
IL_depolarizer_dB = 0.30;

K2_split_ratio = 0.50;
IL_K2_dB = 0.20;

alpha_fiber_dB_km = 0.20;
IL_PZT_dB = 0.50;

N_loop_splices = 6;
IL_splice_dB = 0.05;

eta_K1 = 10^(-IL_K1_dB/10);
eta_conn = 10^(-IL_connector_common_dB/10);
eta_pol = 10^(-IL_polarizer_dB/10);
eta_dep = 10^(-IL_depolarizer_dB/10);
eta_K2 = 10^(-IL_K2_dB/10);

eta_coil = ...
    10^(-alpha_fiber_dB_km*(L/1000)/10);

eta_PZT = ...
    10^(-IL_PZT_dB/10);

eta_splices = ...
    10^(-(N_loop_splices*IL_splice_dB)/10);

eta_loop = ...
    eta_coil*eta_PZT*eta_splices;

K_front_forward = ...
    K1_launch_ratio*eta_K1*eta_conn*eta_pol*eta_dep;

K_sagnac_power = ...
    2*K2_split_ratio*(1-K2_split_ratio)* ...
    eta_K2^2*eta_loop;

K_front_return = ...
    eta_dep*eta_pol*eta_conn* ...
    K1_detector_ratio*eta_K1;

Pdet_scale_W = ...
    P_source_W*K_front_forward* ...
    K_sagnac_power*K_front_return;

%% ============================================================
% POLARYZACJA - WYBRANY WARIANT v6.2
%% ============================================================

polarizer_ER_dB = 25;
polarizer_leakage = 10^(-polarizer_ER_dB/10);

V_cal = ...
    (1-polarizer_leakage)/(1+polarizer_leakage);

pol_enable = 1;

% Physical Lyot proxy z v6.2.
depol_residual = 0.017452;

pol_theta0_rad = 15*pi/180;
pol_theta_amp_rad = 0;

pol_delta0_rad = 0.20;
pol_delta_amp_rad = 0;

pol_theta_freq_Hz = 17;
pol_delta_freq_Hz = 23;
pol_delta_phase_rad = pi/5;

pol_nr_scale = 2.0e-4;

%% ============================================================
% PHOTORECEIVER
%% ============================================================

q_e = 1.602176634e-19;
k_B = 1.380649e-23;

Rpd = 0.9;
I_dark_A = 5e-9;

Rf = 20e3;
Rtia = Rf;

T_receiver_K = 300;

f_tia_Hz = 200e3;
w_tia = 2*pi*f_tia_Hz;

opamp_en_V_sqrtHz = 4e-9;
opamp_in_A_sqrtHz = 2e-15;
opamp_en_eq_A_sqrtHz = ...
    opamp_en_V_sqrtHz/Rf;

Pdet_avg_zero_W = ...
    Pdet_scale_W* ...
    (1+V_cal*besselj(0,beta_eff));

Iphoto_avg_A = ...
    Rpd*Pdet_avg_zero_W;

i_photo_shot_ASD = ...
    sqrt(2*q_e*Iphoto_avg_A);

i_dark_shot_ASD = ...
    sqrt(2*q_e*I_dark_A);

i_johnson_ASD = ...
    sqrt(4*k_B*T_receiver_K/Rf);

i_opamp_current_ASD = ...
    opamp_in_A_sqrtHz;

i_opamp_voltage_eq_ASD = ...
    opamp_en_eq_A_sqrtHz;

i_total_ASD = sqrt( ...
    i_photo_shot_ASD^2 + ...
    i_dark_shot_ASD^2 + ...
    i_johnson_ASD^2 + ...
    i_opamp_current_ASD^2 + ...
    i_opamp_voltage_eq_ASD^2);

%% ============================================================
% ADC / DIGITAL LOCK-IN
%% ============================================================

Vadc_min = 0;
Vadc_max = 2;
Vadc_fs = 2;

adc_bits = 16;
fs_adc = 1e6;
Ts_adc = 1/fs_adc;
adc_sample_offset_s = 0;

q_adc = ...
    Vadc_fs/(2^adc_bits-1);

aa_order = 4;
f_aa_Hz = 100e3;

fc_digital_lp = 300;
digital_lp_order = 4;

[b_aa,a_aa] = ...
    butter(aa_order,2*pi*f_aa_Hz,'s');

Haa = ...
    polyval(b_aa,1j*2*pi*f_mod) / ...
    polyval(a_aa,1j*2*pi*f_mod);

Htia = ...
    1/(1+1j*f_mod/f_tia_Hz);

Hanalog = ...
    Haa*Htia;

Hmag_aa_fmod = abs(Haa);
Hmag_tia_fmod = abs(Htia);
Hmag_analog_fmod = abs(Hanalog);

analog_phase_lag_rad = ...
    -angle(Hanalog);

ref_delay_total_s = ...
    analog_phase_lag_rad/(2*pi*f_mod);

K_norm_digital = ...
    -1/( ...
    Pdet_scale_W*V_cal*Rpd*Rf* ...
    Hmag_analog_fmod*J1beta);

[b_dlp,a_dlp] = ...
    butter( ...
    digital_lp_order, ...
    fc_digital_lp/(fs_adc/2));

[sos_d,g_d] = ...
    tf2sos(b_dlp,a_dlp);

sos_d(1,1:3) = ...
    g_d*sos_d(1,1:3);

Vanalog_ASD_fmod = ...
    i_total_ASD*Rf*Hmag_analog_fmod;

%% ============================================================
% CLOSED-LOOP DIGITAL CONTROL
%% ============================================================

fs_ctrl = 10e3;
Ts_ctrl = 1/fs_ctrl;

Kp = 0.50;
controller_bw_Hz = 50;

Omega_feedback_limit_deg_s = 23.0;

% v8 selected all-fiber candidate:
actuator_name = ...
    "low-Vpi long-range fiber PZT benchmark";

actuator_Vpi_V = 4.5;
actuator_driver_Vpp = 50;
actuator_cycles_before_reset = 5;
actuator_BW_Hz = 20e3;
actuator_cap_F = 0.18e-6;

reset_fraction = 0.10;

actuator_max_Omega_reset_deg_s = ...
    (reset_fraction*actuator_BW_Hz/0.35) * ...
    actuator_cycles_before_reset / ...
    wrap2pi_per_deg_s_Hz;

actuator_reset_freq_at_20_Hz = ...
    wrap2pi_per_deg_s_Hz*20/ ...
    actuator_cycles_before_reset;

actuator_required_BW_at_20_Hz = ...
    0.35*actuator_reset_freq_at_20_Hz/reset_fraction;

actuator_Vpp_used = ...
    2*actuator_Vpi_V*actuator_cycles_before_reset;

actuator_ramp_current_A = ...
    actuator_cap_F*actuator_Vpp_used* ...
    actuator_reset_freq_at_20_Hz;

actuator_reset_peak_current_A = ...
    actuator_ramp_current_A/reset_fraction;

nco_bits = 32;
nco_fs_Hz = 1e6;

Omega_nco_LSB_deg_s = ...
    nco_fs_Hz / ...
    (2^nco_bits*wrap2pi_per_deg_s_Hz);

updateControllerCoeffs();

% Equivalent actuator command response at controller rate.
alpha_act = ...
    1-exp(-2*pi*actuator_BW_Hz*Ts_ctrl);

b_act = alpha_act;
a_act = [1 -(1-alpha_act)];

%% ============================================================
% SOLVER / NOISE
%% ============================================================

Ts_solver = 0.20e-6;
Ts_noise = Ts_solver;

noise_enable = 0;

seed_photo = 310001;
seed_dark = 310002;
seed_johnson = 310003;
seed_opamp_i = 310004;
seed_opamp_en = 310005;

updateNoiseSampling();

%% ============================================================
% PRZEBUDOWA SAGNAC Z WEJSCIEM FEEDBACK
%% ============================================================

sagnacSub = [mdl '/Sagnac Interferometer'];

% Odpinamy wszystkie linie zwiazane z portami Sagnac.
safeDeleteLine(mdl,'Optical Front End/1','Sagnac Interferometer/1');
safeDeleteLine(mdl,'Rotation Input/1','Sagnac Interferometer/2');
safeDeleteLine(mdl,'Sagnac Interferometer/1','Optical Front End/2');
safeDeleteLine(mdl,'Sagnac Interferometer/2','Digital Lock-In DSP/2');

if getSimulinkBlockHandle([mdl '/Save_Vpol']) ~= -1
    safeDeleteLine(mdl,'Sagnac Interferometer/3','Save_Vpol/1');
end

if getSimulinkBlockHandle([mdl '/Save_PhiPol']) ~= -1
    safeDeleteLine(mdl,'Sagnac Interferometer/4','Save_PhiPol/1');
end

buildSagnacV81(sagnacSub);

set_param( ...
    sagnacSub, ...
    'Position',[520 110 770 350], ...
    'AttributesFormatString', ...
    'K2 + 1 km SMF + 20 kHz dither + polarization + closed-loop feedback');

%% ============================================================
% ROTATION INPUT = STEP
%% ============================================================

if getSimulinkBlockHandle([mdl '/Rotation Input']) ~= -1
    delete_block([mdl '/Rotation Input'])
end

Omega_step_time = 0.020;
Omega_step_final = 20;

add_block( ...
    'simulink/Sources/Step', ...
    [mdl '/Rotation Input'], ...
    'Time','Omega_step_time', ...
    'Before','0', ...
    'After','Omega_step_final', ...
    'SampleTime','0', ...
    'Position',[540 620 640 660]);

%% ============================================================
% CLOSED LOOP CONTROLLER + PHASE ACTUATOR
%% ============================================================

if getSimulinkBlockHandle([mdl '/Closed Loop Controller']) ~= -1
    delete_block([mdl '/Closed Loop Controller'])
end

if getSimulinkBlockHandle([mdl '/Feedback Phase Actuator']) ~= -1
    delete_block([mdl '/Feedback Phase Actuator'])
end

add_block( ...
    'simulink/Ports & Subsystems/Subsystem', ...
    [mdl '/Closed Loop Controller'], ...
    'Position',[1320 390 1510 520]);

buildClosedLoopController([mdl '/Closed Loop Controller']);

set_param( ...
    [mdl '/Closed Loop Controller'], ...
    'BackgroundColor','green', ...
    'AttributesFormatString', ...
    '10 kHz PI + 32-bit NCO command quantization');

add_block( ...
    'simulink/Ports & Subsystems/Subsystem', ...
    [mdl '/Feedback Phase Actuator'], ...
    'Position',[940 390 1170 560]);

buildFeedbackActuator([mdl '/Feedback Phase Actuator']);

set_param( ...
    [mdl '/Feedback Phase Actuator'], ...
    'BackgroundColor','cyan', ...
    'AttributesFormatString', ...
    sprintf('selected: Vpi %.1f V, %.0f cycles, BW %.0f kHz', ...
    actuator_Vpi_V,actuator_cycles_before_reset,actuator_BW_Hz/1e3));

%% ============================================================
% USTAWIENIE FIZYCZNEGO TOP-LEVEL
%% ============================================================

setPositionIfExists(mdl,'Optical Source',[50 170 180 260]);
setPositionIfExists(mdl,'Optical Front End',[260 140 430 300]);
setPositionIfExists(mdl,'Photoreceiver',[850 160 1000 250]);
setPositionIfExists(mdl,'ADC AFE',[1080 140 1220 270]);
setPositionIfExists(mdl,'Digital Lock-In DSP',[1300 130 1500 285]);

%% ============================================================
% RESIDUAL DISPLAY / LOGGER
%% ============================================================

safeDeleteLine(mdl,'Digital Lock-In DSP/1','Omega Display/1');
safeDeleteLine(mdl,'Digital Lock-In DSP/1','Save_Omega/1');

if getSimulinkBlockHandle([mdl '/Omega Display']) ~= -1
    set_param([mdl '/Omega Display'],'Name','Residual Omega Display')
end

if getSimulinkBlockHandle([mdl '/Save_Omega']) ~= -1
    set_param([mdl '/Save_Omega'],'Name','Save Residual Estimate')
end

if getSimulinkBlockHandle([mdl '/Residual Omega Display']) == -1
    add_block( ...
        'simulink/Sinks/Display', ...
        [mdl '/Residual Omega Display'], ...
        'Position',[1540 150 1650 200]);
else
    set_param( ...
        [mdl '/Residual Omega Display'], ...
        'Position',[1540 150 1650 200]);
end

if getSimulinkBlockHandle([mdl '/Save Residual Estimate']) == -1
    add_block( ...
        'simulink/Sinks/To Workspace', ...
        [mdl '/Save Residual Estimate'], ...
        'VariableName','omega_residual_est_ts', ...
        'SaveFormat','Timeseries', ...
        'Position',[1530 230 1660 270]);
else
    set_param( ...
        [mdl '/Save Residual Estimate'], ...
        'VariableName','omega_residual_est_ts', ...
        'SaveFormat','Timeseries', ...
        'Position',[1530 230 1660 270]);
end

%% ============================================================
% NOWE MONITORY CLOSED LOOP
%% ============================================================

addOrReplaceDisplay(mdl,'Closed Loop Omega Display',[1540 400 1660 450]);

addOrReplaceToWorkspace( ...
    mdl,'Save Feedback Omega','omega_feedback_ts',[1200 470 1300 510]);

addOrReplaceToWorkspace( ...
    mdl,'Save True Omega','omega_true_ts',[660 620 760 660]);

addOrReplaceToWorkspace( ...
    mdl,'Save Delta Phi Feedback','delta_phi_feedback_ts',[810 440 920 480]);

addOrReplaceToWorkspace( ...
    mdl,'Save Phase Slope','phase_slope_ts',[810 510 920 550]);

addOrReplaceToWorkspace( ...
    mdl,'Save Reset Frequency','reset_frequency_ts',[810 575 930 615]);

if getSimulinkBlockHandle([mdl '/Closed Loop Estimate']) ~= -1
    delete_block([mdl '/Closed Loop Estimate'])
end

add_block( ...
    'simulink/Math Operations/Sum', ...
    [mdl '/Closed Loop Estimate'], ...
    'Inputs','++', ...
    'Position',[1510 555 1550 615]);

addOrReplaceToWorkspace( ...
    mdl,'Save Closed Loop Estimate','omega_closedloop_est_ts',[1600 560 1720 600]);

%% ============================================================
% TOP-LEVEL POLACZENIA
%% ============================================================

% Ponownie fizyczny Sagnac.
add_line(mdl,'Optical Front End/1','Sagnac Interferometer/1','autorouting','on');
add_line(mdl,'Rotation Input/1','Sagnac Interferometer/2','autorouting','on');
add_line(mdl,'Sagnac Interferometer/1','Optical Front End/2','autorouting','on');
add_line(mdl,'Sagnac Interferometer/2','Digital Lock-In DSP/2','autorouting','on');

if getSimulinkBlockHandle([mdl '/Save_Vpol']) ~= -1
    add_line(mdl,'Sagnac Interferometer/3','Save_Vpol/1','autorouting','on');
end

if getSimulinkBlockHandle([mdl '/Save_PhiPol']) ~= -1
    add_line(mdl,'Sagnac Interferometer/4','Save_PhiPol/1','autorouting','on');
end

% Residual DSP -> display/logger/controller/estimate.
add_line(mdl,'Digital Lock-In DSP/1','Residual Omega Display/1','autorouting','on');
add_line(mdl,'Digital Lock-In DSP/1','Save Residual Estimate/1','autorouting','on');
add_line(mdl,'Digital Lock-In DSP/1','Closed Loop Controller/1','autorouting','on');
add_line(mdl,'Digital Lock-In DSP/1','Closed Loop Estimate/1','autorouting','on');

% PI/NCO -> actuator.
add_line(mdl,'Closed Loop Controller/1','Feedback Phase Actuator/1','autorouting','on');

% Actual feedback rate.
add_line(mdl,'Feedback Phase Actuator/2','Closed Loop Omega Display/1','autorouting','on');
add_line(mdl,'Feedback Phase Actuator/2','Save Feedback Omega/1','autorouting','on');
add_line(mdl,'Feedback Phase Actuator/2','Closed Loop Estimate/2','autorouting','on');

% Equivalent differential optical phase -> Sagnac.
add_line(mdl,'Feedback Phase Actuator/1','Sagnac Interferometer/3','autorouting','on');
add_line(mdl,'Feedback Phase Actuator/1','Save Delta Phi Feedback/1','autorouting','on');

% Diagnostics.
add_line(mdl,'Feedback Phase Actuator/3','Save Phase Slope/1','autorouting','on');
add_line(mdl,'Feedback Phase Actuator/4','Save Reset Frequency/1','autorouting','on');

% True rate logging.
add_line(mdl,'Rotation Input/1','Save True Omega/1','autorouting','on');

% Closed-loop estimate logger.
add_line(mdl,'Closed Loop Estimate/1','Save Closed Loop Estimate/1','autorouting','on');

%% ============================================================
% SAMPLE TIMES ADC / REFERENCE
%% ============================================================

set_param( ...
    [mdl '/ADC AFE/Sample and Hold'], ...
    'SampleTime','[Ts_adc adc_sample_offset_s]');

set_param( ...
    [mdl '/Digital Lock-In DSP/Reference Sampler'], ...
    'SampleTime','[Ts_adc adc_sample_offset_s]');

%% ============================================================
% TOPOLOGY CHECK
%% ============================================================

lhSag = get_param(sagnacSub,'LineHandles');
lhCtl = get_param([mdl '/Closed Loop Controller'],'LineHandles');
lhAct = get_param([mdl '/Feedback Phase Actuator'],'LineHandles');

if any(lhSag.Inport == -1) || any(lhSag.Outport == -1)
    error("FOG v8.1 topology error: Sagnac disconnected.")
end

if lhCtl.Inport(1) == -1 || lhCtl.Outport(1) == -1
    error("FOG v8.1 topology error: controller disconnected.")
end

if lhAct.Inport(1) == -1 || any(lhAct.Outport == -1)
    error("FOG v8.1 topology error: feedback actuator disconnected.")
end

disp("Integrated optical closed-loop topology check: OK")

%% ============================================================
% MODEL PARAMS
%% ============================================================

set_param( ...
    mdl, ...
    'SolverType','Fixed-step', ...
    'Solver','ode4', ...
    'FixedStep','Ts_solver', ...
    'ReturnWorkspaceOutputs','on');

save_system(mdl);

%% ============================================================
% v8.1A - INTEGRATED CONTROLLER BW CHECK
%% ============================================================

disp("")
disp("==============================================")
disp(" v8.1A - FULL OPTICAL CLOSED-LOOP BW SWEEP")
disp("==============================================")

noise_enable = 0;

pol_theta_amp_rad = 0;
pol_delta_amp_rad = 0;

pol_theta0_rad = 10*pi/180;
pol_delta0_rad = 0.20;

Omega_step_time = 0.020;
Omega_step_final = 20;

Tstop_det = 0.100;
Tsteady_det = 0.075;

controllerSweep_Hz = [30 50 100]';
Nc = numel(controllerSweep_Hz);

fbMean = zeros(Nc,1);
fbError = zeros(Nc,1);
resMean = zeros(Nc,1);
resStd = zeros(Nc,1);
settling_ms = zeros(Nc,1);
resetMean_kHz = zeros(Nc,1);
phaseMean_rad = zeros(Nc,1);

set_param(mdl,'StopTime',sprintf('%.17g',Tstop_det));

for kc = 1:Nc

    controller_bw_Hz = controllerSweep_Hz(kc);
    updateControllerCoeffs();

    fprintf("controller %.0f Hz ... ",controller_bw_Hz)

    out = sim(mdl);

    fb = out.get('omega_feedback_ts');
    re = out.get('omega_residual_est_ts');
    rf = out.get('reset_frequency_ts');
    pf = out.get('delta_phi_feedback_ts');

    idxFb = fb.Time >= Tsteady_det;
    idxRe = re.Time >= Tsteady_det;
    idxRf = rf.Time >= Tsteady_det;
    idxPf = pf.Time >= Tsteady_det;

    fbMean(kc) = mean(fb.Data(idxFb));
    fbError(kc) = fbMean(kc)-Omega_step_final;

    resMean(kc) = mean(re.Data(idxRe));
    resStd(kc) = std(re.Data(idxRe));

    resetMean_kHz(kc) = mean(rf.Data(idxRf))/1e3;
    phaseMean_rad(kc) = mean(pf.Data(idxPf));

    settling_ms(kc) = ...
        measureSettling( ...
        fb.Time,fb.Data, ...
        Omega_step_time,Omega_step_final)*1e3;

    fprintf("done\n")
end

integratedController = table( ...
    controllerSweep_Hz, ...
    repmat(Omega_step_final,Nc,1), ...
    fbMean, ...
    fbError, ...
    resMean, ...
    resStd, ...
    settling_ms, ...
    resetMean_kHz, ...
    phaseMean_rad, ...
    'VariableNames', ...
    { ...
    'Controller_BW_Hz', ...
    'Omega_step_deg_s', ...
    'Feedback_mean_deg_s', ...
    'Feedback_error_deg_s', ...
    'Residual_mean_deg_s', ...
    'Residual_STD_deg_s', ...
    'Settling_2pct_ms', ...
    'Selected_actuator_reset_frequency_kHz', ...
    'Delta_phi_feedback_mean_rad' ...
    });

disp(integratedController)

writetable( ...
    integratedController, ...
    'FOG_v8_1_integrated_controller.csv');

%% ============================================================
% v8.1B - NOMINAL 1 DEG/S / 20 DEG/S
%% ============================================================

disp("")
disp("==============================================")
disp(" v8.1B - FULL OPTICAL STEP TESTS")
disp("==============================================")

controller_bw_Hz = 50;
updateControllerCoeffs();

stepRates = [1 20]';
Ns = numel(stepRates);

sFb = zeros(Ns,1);
sRes = zeros(Ns,1);
sEst = zeros(Ns,1);
sSettle = zeros(Ns,1);
sReset = zeros(Ns,1);
sSlope = zeros(Ns,1);

for ks = 1:Ns

    Omega_step_final = stepRates(ks);

    out = sim(mdl);

    fb = out.get('omega_feedback_ts');
    re = out.get('omega_residual_est_ts');
    ce = out.get('omega_closedloop_est_ts');
    rf = out.get('reset_frequency_ts');
    ps = out.get('phase_slope_ts');

    idx = fb.Time >= Tsteady_det;

    sFb(ks) = mean(fb.Data(idx));
    sRes(ks) = mean(re.Data(re.Time>=Tsteady_det));
    sEst(ks) = mean(ce.Data(ce.Time>=Tsteady_det));
    sReset(ks) = mean(rf.Data(rf.Time>=Tsteady_det))/1e3;
    sSlope(ks) = mean(ps.Data(ps.Time>=Tsteady_det));

    sSettle(ks) = ...
        measureSettling( ...
        fb.Time,fb.Data, ...
        Omega_step_time,Omega_step_final)*1e3;
end

stepResults = table( ...
    stepRates, ...
    sFb, ...
    sFb-stepRates, ...
    sRes, ...
    sEst, ...
    sEst-stepRates, ...
    sSettle, ...
    sReset, ...
    sSlope, ...
    'VariableNames', ...
    { ...
    'Omega_input_deg_s', ...
    'Feedback_mean_deg_s', ...
    'Feedback_error_deg_s', ...
    'Residual_mean_deg_s', ...
    'Closed_loop_estimate_mean_deg_s', ...
    'Estimate_error_deg_s', ...
    'Settling_2pct_ms', ...
    'Reset_frequency_kHz', ...
    'Phase_slope_rad_s' ...
    });

disp(stepResults)

writetable( ...
    stepResults, ...
    'FOG_v8_1_step_tests.csv');

%% ============================================================
% v8.1C - FULL NOISE SMALL-SIGNAL MONTE CARLO
%% ============================================================

disp("")
disp("==============================================")
disp(" v8.1C - CLOSED-LOOP SMALL SIGNAL MONTE CARLO")
disp("==============================================")

noise_enable = 1;

controller_bw_Hz = 50;
updateControllerCoeffs();

Omega_step_time = 0;

Tstop_mc = 0.120;
Tmean_mc = 0.100;

set_param(mdl,'StopTime',sprintf('%.17g',Tstop_mc));

Nmc = 20;
Omega_small = 1e-4;

vals0 = zeros(Nmc,1);
vals1 = zeros(Nmc,1);

res0 = zeros(Nmc,1);
res1 = zeros(Nmc,1);

rng(88101);

fprintf("ZERO: ")

for irun = 1:Nmc

    pol_theta0_rad = ...
        (-30+60*rand())*pi/180;

    pol_delta0_rad = ...
        -0.5+rand();

    Omega_step_final = 0;

    setSeeds( ...
        3300000+10*irun);

    out = sim(mdl);

    fb = out.get('omega_feedback_ts');
    re = out.get('omega_residual_est_ts');

    vals0(irun) = ...
        mean(fb.Data(fb.Time>=Tmean_mc));

    res0(irun) = ...
        mean(re.Data(re.Time>=Tmean_mc));

    fprintf(".")
end

fprintf(" done\nSIGNAL: ")

for irun = 1:Nmc

    pol_theta0_rad = ...
        (-30+60*rand())*pi/180;

    pol_delta0_rad = ...
        -0.5+rand();

    Omega_step_final = Omega_small;

    setSeeds( ...
        3400000+10*irun);

    out = sim(mdl);

    fb = out.get('omega_feedback_ts');
    re = out.get('omega_residual_est_ts');

    vals1(irun) = ...
        mean(fb.Data(fb.Time>=Tmean_mc));

    res1(irun) = ...
        mean(re.Data(re.Time>=Tmean_mc));

    fprintf(".")
end

fprintf(" done\n")

zeroMean = mean(vals0);
zeroStd = std(vals0);

signalMean = mean(vals1);
signalStd = std(vals1);

signalBias = ...
    signalMean-Omega_small;

pooled = ...
    sqrt((zeroStd^2+signalStd^2)/2);

classSeparation = ...
    abs(signalMean-zeroMean)/pooled;

smallSignalResults = table( ...
    Nmc, ...
    Omega_small, ...
    zeroMean, ...
    zeroStd, ...
    zeroStd*3600, ...
    signalMean, ...
    signalStd, ...
    signalBias, ...
    classSeparation, ...
    mean(res0), ...
    std(res0), ...
    mean(res1), ...
    std(res1), ...
    'VariableNames', ...
    { ...
    'N_per_class', ...
    'Omega_signal_deg_s', ...
    'Zero_feedback_mean_deg_s', ...
    'Zero_feedback_STD_deg_s', ...
    'Zero_feedback_STD_deg_h', ...
    'Signal_feedback_mean_deg_s', ...
    'Signal_feedback_STD_deg_s', ...
    'Signal_feedback_bias_deg_s', ...
    'Zero_signal_separation_sigma', ...
    'Zero_residual_mean_deg_s', ...
    'Zero_residual_STD_deg_s', ...
    'Signal_residual_mean_deg_s', ...
    'Signal_residual_STD_deg_s' ...
    });

disp(smallSignalResults)

writetable( ...
    smallSignalResults, ...
    'FOG_v8_1_small_signal_mc.csv');

%% ============================================================
% v8.1D - SELECTED ACTUATOR BRIDGE
%% ============================================================

selectedActuator = table( ...
    actuator_name, ...
    actuator_Vpi_V, ...
    actuator_driver_Vpp, ...
    actuator_cycles_before_reset, ...
    actuator_BW_Hz/1e3, ...
    actuator_max_Omega_reset_deg_s, ...
    actuator_reset_freq_at_20_Hz/1e3, ...
    actuator_required_BW_at_20_Hz/1e3, ...
    actuator_cap_F*1e6, ...
    actuator_ramp_current_A, ...
    actuator_reset_peak_current_A, ...
    nco_bits, ...
    Omega_nco_LSB_deg_s, ...
    'VariableNames', ...
    { ...
    'Actuator_candidate', ...
    'Vpi_V', ...
    'Driver_Vpp', ...
    'Usable_2pi_cycles', ...
    'Actuator_BW_kHz', ...
    'Ideal_reset_limited_Omega_max_deg_s', ...
    'Reset_frequency_at_20deg_s_kHz', ...
    'Required_BW_at_20deg_s_kHz', ...
    'Piezo_capacitance_uF', ...
    'Linear_ramp_current_A', ...
    'Approx_reset_peak_current_A', ...
    'NCO_bits', ...
    'NCO_rate_LSB_deg_s' ...
    });

disp("")
disp("SELECTED ACTUATOR BRIDGE")
disp(selectedActuator)

writetable( ...
    selectedActuator, ...
    'FOG_v8_1_selected_actuator.csv');

%% ============================================================
% STAN KONCOWY
%% ============================================================

noise_enable = 1;

controller_bw_Hz = 50;
updateControllerCoeffs();

Omega_step_time = 0.020;
Omega_step_final = 1;

pol_theta0_rad = 15*pi/180;
pol_theta_amp_rad = 20*pi/180;

pol_delta0_rad = 0.20;
pol_delta_amp_rad = 0.30;

set_param( ...
    mdl, ...
    'FixedStep','Ts_solver', ...
    'StopTime','0.12');

save_system(mdl);
open_system(mdl);

disp("")
disp("==============================================")
disp(" FOG v8.1 - INTEGRACJA ZAKONCZONA")
disp("==============================================")
disp("Utworzono:")
disp("  FOG_v8_1.slx")
disp("  FOG_v8_1_integrated_controller.csv")
disp("  FOG_v8_1_step_tests.csv")
disp("  FOG_v8_1_small_signal_mc.csv")
disp("  FOG_v8_1_selected_actuator.csv")
disp("")
disp("Top-level powinien teraz pokazywac caly tor:")
disp("SOURCE -> FRONT END -> SAGNAC -> RX -> ADC -> DSP -> PI/NCO")
disp("                                      ^                 |")
disp("                                      +-- PHASE ACTUATOR+")
disp("")

%% ============================================================
% FUNKCJE BUDUJACE
%% ============================================================

function buildClosedLoopController(sub)

    Simulink.SubSystem.deleteContents(sub);

    add_block( ...
        'simulink/Ports & Subsystems/In1', ...
        [sub '/Residual Omega'], ...
        'Port','1', ...
        'Position',[30 80 60 100]);

    add_block( ...
        'simulink/Discrete/Zero-Order Hold', ...
        [sub '/Controller Sampler'], ...
        'SampleTime','Ts_ctrl', ...
        'Position',[110 65 220 115]);

    add_block( ...
        'simulink/Discrete/Discrete Transfer Fcn', ...
        [sub '/PI'], ...
        'Numerator','b_pi', ...
        'Denominator','a_pi', ...
        'SampleTime','Ts_ctrl', ...
        'Position',[280 60 410 120]);

    add_block( ...
        'simulink/Discontinuities/Saturation', ...
        [sub '/Feedback Rate Limit'], ...
        'UpperLimit','Omega_feedback_limit_deg_s', ...
        'LowerLimit','-Omega_feedback_limit_deg_s', ...
        'Position',[470 65 590 115]);

    add_block( ...
        'simulink/Discontinuities/Quantizer', ...
        [sub '/NCO Rate Word'], ...
        'QuantizationInterval','Omega_nco_LSB_deg_s', ...
        'Position',[650 65 760 115]);

    add_block( ...
        'simulink/Ports & Subsystems/Out1', ...
        [sub '/Omega Feedback Command'], ...
        'Port','1', ...
        'Position',[830 78 860 102]);

    add_line(sub,'Residual Omega/1','Controller Sampler/1','autorouting','on');
    add_line(sub,'Controller Sampler/1','PI/1','autorouting','on');
    add_line(sub,'PI/1','Feedback Rate Limit/1','autorouting','on');
    add_line(sub,'Feedback Rate Limit/1','NCO Rate Word/1','autorouting','on');
    add_line(sub,'NCO Rate Word/1','Omega Feedback Command/1','autorouting','on');
end

function buildFeedbackActuator(sub)

    Simulink.SubSystem.deleteContents(sub);

    add_block( ...
        'simulink/Ports & Subsystems/In1', ...
        [sub '/Omega Command'], ...
        'Port','1', ...
        'Position',[30 80 60 100]);

    add_block( ...
        'simulink/Discrete/Discrete Transfer Fcn', ...
        [sub '/Actuator Command Dynamics'], ...
        'Numerator','b_act', ...
        'Denominator','a_act', ...
        'SampleTime','Ts_ctrl', ...
        'Position',[120 60 270 120]);

    add_block( ...
        'simulink/Math Operations/Gain', ...
        [sub '/Equivalent Differential Phase'], ...
        'Gain','-K_sag*pi/180', ...
        'Position',[340 40 500 100]);

    add_block( ...
        'simulink/Math Operations/Gain', ...
        [sub '/Phase Ramp Slope'], ...
        'Gain','-slope_per_deg_s', ...
        'Position',[340 135 500 195]);

    add_block( ...
        'simulink/Math Operations/Gain', ...
        [sub '/Selected Reset Frequency'], ...
        'Gain','wrap2pi_per_deg_s_Hz/actuator_cycles_before_reset', ...
        'Position',[340 230 530 290]);

    add_block( ...
        'simulink/Math Operations/Abs', ...
        [sub '/Abs Reset Frequency'], ...
        'Position',[590 235 650 285]);

    add_block( ...
        'simulink/Ports & Subsystems/Out1', ...
        [sub '/Delta Phi Feedback'], ...
        'Port','1', ...
        'Position',[730 48 760 72]);

    add_block( ...
        'simulink/Ports & Subsystems/Out1', ...
        [sub '/Omega Feedback Actual'], ...
        'Port','2', ...
        'Position',[730 103 760 127]);

    add_block( ...
        'simulink/Ports & Subsystems/Out1', ...
        [sub '/Phase Slope'], ...
        'Port','3', ...
        'Position',[730 163 760 187]);

    add_block( ...
        'simulink/Ports & Subsystems/Out1', ...
        [sub '/Reset Frequency'], ...
        'Port','4', ...
        'Position',[730 248 760 272]);

    add_line(sub,'Omega Command/1','Actuator Command Dynamics/1','autorouting','on');

    add_line(sub,'Actuator Command Dynamics/1','Equivalent Differential Phase/1','autorouting','on');
    add_line(sub,'Actuator Command Dynamics/1','Omega Feedback Actual/1','autorouting','on');
    add_line(sub,'Actuator Command Dynamics/1','Phase Ramp Slope/1','autorouting','on');
    add_line(sub,'Actuator Command Dynamics/1','Selected Reset Frequency/1','autorouting','on');

    add_line(sub,'Equivalent Differential Phase/1','Delta Phi Feedback/1','autorouting','on');
    add_line(sub,'Phase Ramp Slope/1','Phase Slope/1','autorouting','on');
    add_line(sub,'Selected Reset Frequency/1','Abs Reset Frequency/1','autorouting','on');
    add_line(sub,'Abs Reset Frequency/1','Reset Frequency/1','autorouting','on');
end

function buildSagnacV81(sub)

    Simulink.SubSystem.deleteContents(sub);

    add_block('simulink/Ports & Subsystems/In1', ...
        [sub '/P_in'], ...
        'Port','1', ...
        'Position',[25 65 55 85]);

    add_block('simulink/Ports & Subsystems/In1', ...
        [sub '/Omega_deg_s'], ...
        'Port','2', ...
        'Position',[25 255 55 275]);

    add_block('simulink/Ports & Subsystems/In1', ...
        [sub '/Delta_phi_feedback'], ...
        'Port','3', ...
        'Position',[25 335 55 355]);

    add_block('simulink/Ports & Subsystems/Out1', ...
        [sub '/P_return'], ...
        'Port','1', ...
        'Position',[1090 75 1120 95]);

    add_block('simulink/Ports & Subsystems/Out1', ...
        [sub '/Reference'], ...
        'Port','2', ...
        'Position',[1090 300 1120 320]);

    add_block('simulink/Ports & Subsystems/Out1', ...
        [sub '/V_pol'], ...
        'Port','3', ...
        'Position',[1090 420 1120 440]);

    add_block('simulink/Ports & Subsystems/Out1', ...
        [sub '/Phi_pol'], ...
        'Port','4', ...
        'Position',[1090 500 1120 520]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/K2 + Loop Loss'], ...
        'Gain','K_sagnac_power', ...
        'Position',[100 45 220 95]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/deg_to_rad'], ...
        'Gain','pi/180', ...
        'Position',[100 235 180 285]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/Sagnac Phase'], ...
        'Gain','K_sag', ...
        'Position',[220 235 310 285]);

    add_block('simulink/Sources/Sine Wave', ...
        [sub '/PZT dither phi_m'], ...
        'Amplitude','phi0', ...
        'Frequency','2*pi*f_mod', ...
        'Bias','0', ...
        'Phase','0', ...
        'SampleTime','0', ...
        'Position',[100 390 210 430]);

    add_block('simulink/Continuous/Transport Delay', ...
        [sub '/CW-CCW Dither Delay'], ...
        'DelayTime','tau', ...
        'Position',[280 410 390 450]);

    add_block('simulink/Math Operations/Sum', ...
        [sub '/Delta phi dither'], ...
        'Inputs','+-', ...
        'Position',[450 365 490 445]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/Reference Normalize'], ...
        'Gain','K_ref', ...
        'Position',[560 400 680 450]);

    add_block('simulink/Ports & Subsystems/Subsystem', ...
        [sub '/SMF Polarization'], ...
        'Position',[350 500 570 610]);

    buildPolarizationModelV81([sub '/SMF Polarization']);

    add_block('simulink/Math Operations/Sum', ...
        [sub '/Total Phase'], ...
        'Inputs','++++', ...
        'Position',[650 210 690 330]);

    add_block('simulink/Math Operations/Trigonometric Function', ...
        [sub '/Interference cos'], ...
        'Operator','cos', ...
        'Position',[740 245 830 295]);

    add_block('simulink/Math Operations/Product', ...
        [sub '/Polarization Visibility'], ...
        'Position',[860 235 910 305]);

    add_block('simulink/Math Operations/Bias', ...
        [sub '/Fringe +1'], ...
        'Bias','1', ...
        'Position',[940 245 1010 295]);

    add_block('simulink/Math Operations/Product', ...
        [sub '/Optical Interference'], ...
        'Position',[1020 65 1070 125]);

    add_line(sub,'P_in/1','K2 + Loop Loss/1','autorouting','on');
    add_line(sub,'K2 + Loop Loss/1','Optical Interference/1','autorouting','on');

    add_line(sub,'Omega_deg_s/1','deg_to_rad/1','autorouting','on');
    add_line(sub,'deg_to_rad/1','Sagnac Phase/1','autorouting','on');
    add_line(sub,'Sagnac Phase/1','Total Phase/1','autorouting','on');

    add_line(sub,'PZT dither phi_m/1','Delta phi dither/1','autorouting','on');
    add_line(sub,'PZT dither phi_m/1','CW-CCW Dither Delay/1','autorouting','on');
    add_line(sub,'CW-CCW Dither Delay/1','Delta phi dither/2','autorouting','on');

    add_line(sub,'Delta phi dither/1','Total Phase/2','autorouting','on');
    add_line(sub,'Delta phi dither/1','Reference Normalize/1','autorouting','on');

    add_line(sub,'SMF Polarization/2','Total Phase/3','autorouting','on');
    add_line(sub,'Delta_phi_feedback/1','Total Phase/4','autorouting','on');

    add_line(sub,'Total Phase/1','Interference cos/1','autorouting','on');
    add_line(sub,'Interference cos/1','Polarization Visibility/1','autorouting','on');
    add_line(sub,'SMF Polarization/1','Polarization Visibility/2','autorouting','on');
    add_line(sub,'Polarization Visibility/1','Fringe +1/1','autorouting','on');
    add_line(sub,'Fringe +1/1','Optical Interference/2','autorouting','on');

    add_line(sub,'Optical Interference/1','P_return/1','autorouting','on');
    add_line(sub,'Reference Normalize/1','Reference/1','autorouting','on');

    add_line(sub,'SMF Polarization/1','V_pol/1','autorouting','on');
    add_line(sub,'SMF Polarization/2','Phi_pol/1','autorouting','on');
end

function buildPolarizationModelV81(sub)

    Simulink.SubSystem.deleteContents(sub);

    add_block('simulink/Sources/Sine Wave', ...
        [sub '/SMF Axis Coupling theta'], ...
        'Amplitude','pol_theta_amp_rad', ...
        'Frequency','2*pi*pol_theta_freq_Hz', ...
        'Bias','pol_theta0_rad', ...
        'Phase','0', ...
        'SampleTime','0', ...
        'Position',[40 55 160 95]);

    add_block('simulink/Sources/Sine Wave', ...
        [sub '/SMF Birefringence delta'], ...
        'Amplitude','pol_delta_amp_rad', ...
        'Frequency','2*pi*pol_delta_freq_Hz', ...
        'Bias','pol_delta0_rad', ...
        'Phase','pol_delta_phase_rad', ...
        'SampleTime','0', ...
        'Position',[40 220 160 260]);

    add_block('simulink/Math Operations/Trigonometric Function', ...
        [sub '/cos theta'], ...
        'Operator','cos', ...
        'Position',[220 25 290 65]);

    add_block('simulink/Math Operations/Trigonometric Function', ...
        [sub '/sin theta'], ...
        'Operator','sin', ...
        'Position',[220 95 290 135]);

    add_block('simulink/Math Operations/Product', ...
        [sub '/cos2 theta'], ...
        'Position',[340 25 390 75]);

    add_block('simulink/Math Operations/Product', ...
        [sub '/sin2 theta'], ...
        'Position',[340 95 390 145]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/2 delta'], ...
        'Gain','2', ...
        'Position',[220 215 290 265]);

    add_block('simulink/Math Operations/Trigonometric Function', ...
        [sub '/cos 2delta'], ...
        'Operator','cos', ...
        'Position',[340 195 420 235]);

    add_block('simulink/Math Operations/Trigonometric Function', ...
        [sub '/sin 2delta'], ...
        'Operator','sin', ...
        'Position',[340 255 420 295]);

    add_block('simulink/Math Operations/Product', ...
        [sub '/s2 cos2d'], ...
        'Position',[480 155 530 205]);

    add_block('simulink/Math Operations/Sum', ...
        [sub '/Gamma real'], ...
        'Inputs','++', ...
        'Position',[590 80 630 155]);

    add_block('simulink/Math Operations/Product', ...
        [sub '/Gamma imag'], ...
        'Position',[480 245 530 295]);

    add_block('simulink/Math Operations/Product', ...
        [sub '/real squared'], ...
        'Position',[680 60 730 110]);

    add_block('simulink/Math Operations/Product', ...
        [sub '/imag squared'], ...
        'Position',[680 145 730 195]);

    add_block('simulink/Math Operations/Sum', ...
        [sub '/Gamma abs squared'], ...
        'Inputs','++', ...
        'Position',[775 85 815 165]);

    add_block('simulink/Math Operations/Math Function', ...
        [sub '/Gamma magnitude'], ...
        'Operator','sqrt', ...
        'Position',[860 100 950 150]);

    add_block('simulink/Math Operations/Product', ...
        [sub '/imag over real'], ...
        'Inputs','*/', ...
        'Position',[680 245 730 295]);

    add_block('simulink/Math Operations/Trigonometric Function', ...
        [sub '/Gamma phase'], ...
        'Operator','atan', ...
        'Position',[780 250 850 290]);

    add_block('simulink/Sources/Constant', ...
        [sub '/One V'], ...
        'Value','1', ...
        'Position',[1000 20 1040 50]);

    add_block('simulink/Math Operations/Sum', ...
        [sub '/1 minus Gamma magnitude'], ...
        'Inputs','+-', ...
        'Position',[1010 85 1050 145]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/Residual Visibility'], ...
        'Gain','pol_enable*depol_residual', ...
        'Position',[1100 90 1210 140]);

    add_block('simulink/Math Operations/Sum', ...
        [sub '/Visibility suppression'], ...
        'Inputs','+-', ...
        'Position',[1260 55 1300 125]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/Polarizer calibration visibility'], ...
        'Gain','V_cal', ...
        'Position',[1350 65 1480 115]);

    add_block('simulink/Math Operations/Gain', ...
        [sub '/Polarization NR Scale'], ...
        'Gain','pol_enable*depol_residual*pol_nr_scale', ...
        'Position',[940 245 1110 295]);

    add_block('simulink/Ports & Subsystems/Out1', ...
        [sub '/V_pol'], ...
        'Port','1', ...
        'Position',[1550 78 1580 102]);

    add_block('simulink/Ports & Subsystems/Out1', ...
        [sub '/Phi_pol'], ...
        'Port','2', ...
        'Position',[1180 258 1210 282]);

    add_line(sub,'SMF Axis Coupling theta/1','cos theta/1','autorouting','on');
    add_line(sub,'SMF Axis Coupling theta/1','sin theta/1','autorouting','on');

    add_line(sub,'cos theta/1','cos2 theta/1','autorouting','on');
    add_line(sub,'cos theta/1','cos2 theta/2','autorouting','on');

    add_line(sub,'sin theta/1','sin2 theta/1','autorouting','on');
    add_line(sub,'sin theta/1','sin2 theta/2','autorouting','on');

    add_line(sub,'SMF Birefringence delta/1','2 delta/1','autorouting','on');
    add_line(sub,'2 delta/1','cos 2delta/1','autorouting','on');
    add_line(sub,'2 delta/1','sin 2delta/1','autorouting','on');

    add_line(sub,'sin2 theta/1','s2 cos2d/1','autorouting','on');
    add_line(sub,'cos 2delta/1','s2 cos2d/2','autorouting','on');

    add_line(sub,'cos2 theta/1','Gamma real/1','autorouting','on');
    add_line(sub,'s2 cos2d/1','Gamma real/2','autorouting','on');

    add_line(sub,'sin2 theta/1','Gamma imag/1','autorouting','on');
    add_line(sub,'sin 2delta/1','Gamma imag/2','autorouting','on');

    add_line(sub,'Gamma real/1','real squared/1','autorouting','on');
    add_line(sub,'Gamma real/1','real squared/2','autorouting','on');

    add_line(sub,'Gamma imag/1','imag squared/1','autorouting','on');
    add_line(sub,'Gamma imag/1','imag squared/2','autorouting','on');

    add_line(sub,'real squared/1','Gamma abs squared/1','autorouting','on');
    add_line(sub,'imag squared/1','Gamma abs squared/2','autorouting','on');

    add_line(sub,'Gamma abs squared/1','Gamma magnitude/1','autorouting','on');

    add_line(sub,'Gamma imag/1','imag over real/1','autorouting','on');
    add_line(sub,'Gamma real/1','imag over real/2','autorouting','on');
    add_line(sub,'imag over real/1','Gamma phase/1','autorouting','on');
    add_line(sub,'Gamma phase/1','Polarization NR Scale/1','autorouting','on');

    add_line(sub,'One V/1','1 minus Gamma magnitude/1','autorouting','on');
    add_line(sub,'Gamma magnitude/1','1 minus Gamma magnitude/2','autorouting','on');

    add_line(sub,'1 minus Gamma magnitude/1','Residual Visibility/1','autorouting','on');

    add_line(sub,'One V/1','Visibility suppression/1','autorouting','on');
    add_line(sub,'Residual Visibility/1','Visibility suppression/2','autorouting','on');

    add_line(sub,'Visibility suppression/1','Polarizer calibration visibility/1','autorouting','on');
    add_line(sub,'Polarizer calibration visibility/1','V_pol/1','autorouting','on');

    add_line(sub,'Polarization NR Scale/1','Phi_pol/1','autorouting','on');
end

%% ============================================================
% FUNKCJE UZYTKOWE
%% ============================================================

function updateControllerCoeffs()

    Kp_l = evalin('caller','Kp');
    bw_l = evalin('caller','controller_bw_Hz');
    Ts_l = evalin('caller','Ts_ctrl');

    Ki_l = 2*pi*bw_l;

    Cpi = ...
        tf([Kp_l Ki_l],[1 0]);

    Cpi_d = ...
        c2d(Cpi,Ts_l,'tustin');

    [b_l,a_l] = ...
        tfdata(Cpi_d,'v');

    assignin('caller','Ki_controller',Ki_l);
    assignin('caller','b_pi',b_l);
    assignin('caller','a_pi',a_l);
end

function updateNoiseSampling()

    Ts_l = evalin('caller','Ts_solver');

    i_dark_l = evalin('caller','i_dark_shot_ASD');
    i_johnson_l = evalin('caller','i_johnson_ASD');
    i_opampi_l = evalin('caller','i_opamp_current_ASD');
    i_opampe_l = evalin('caller','i_opamp_voltage_eq_ASD');

    scale_l = 1/sqrt(2*Ts_l);

    assignin('caller','Ts_noise',Ts_l);
    assignin('caller','noise_sample_scale',scale_l);

    assignin('caller','sigma_dark_sample_A',i_dark_l*scale_l);
    assignin('caller','sigma_johnson_sample_A',i_johnson_l*scale_l);
    assignin('caller','sigma_opamp_current_sample_A',i_opampi_l*scale_l);
    assignin('caller','sigma_opamp_voltage_sample_A',i_opampe_l*scale_l);
end

function setSeeds(baseSeed)

    assignin('caller','seed_photo',baseSeed+1);
    assignin('caller','seed_dark',baseSeed+2);
    assignin('caller','seed_johnson',baseSeed+3);
    assignin('caller','seed_opamp_i',baseSeed+4);
    assignin('caller','seed_opamp_en',baseSeed+5);
end

function safeDeleteLine(mdl,src,dst)

    try
        delete_line(mdl,src,dst);
    catch
    end
end

function setPositionIfExists(mdl,name,pos)

    path = [mdl '/' name];

    if getSimulinkBlockHandle(path) ~= -1
        set_param(path,'Position',pos);
    end
end

function addOrReplaceDisplay(mdl,name,pos)

    path = [mdl '/' name];

    if getSimulinkBlockHandle(path) ~= -1
        delete_block(path)
    end

    add_block( ...
        'simulink/Sinks/Display', ...
        path, ...
        'Position',pos);
end

function addOrReplaceToWorkspace(mdl,name,varName,pos)

    path = [mdl '/' name];

    if getSimulinkBlockHandle(path) ~= -1
        delete_block(path)
    end

    add_block( ...
        'simulink/Sinks/To Workspace', ...
        path, ...
        'VariableName',varName, ...
        'SaveFormat','Timeseries', ...
        'Position',pos);
end

function settling_s = measureSettling(t,y,tStep,target)

    tol = max(0.02*abs(target),1e-6);

    idxStart = find(t>=tStep,1,'first');

    settling_s = NaN;

    for k = idxStart:numel(t)

        if all(abs(y(k:end)-target)<=tol)
            settling_s = t(k)-tStep;
            break
        end
    end
end
