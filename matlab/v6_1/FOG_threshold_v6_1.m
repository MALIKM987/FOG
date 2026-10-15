%% ============================================================
% FOG_threshold_v6_1.m
% Interferometryczny zyroskop swiatlowodowy - model v6.1
% MATLAB / Simulink R2023b
%
% CEL:
% - wyznaczyc wymagany poziom kontroli polaryzacji dla zwyklego SMF,
% - wykonac paired Monte Carlo dla tych samych stanow SMF i seedow,
% - znalezc graniczny depol_residual dla detekcji 3-sigma i 4-sigma,
% - zbadac wrazliwosc na fenomenologiczny pol_nr_scale,
% - zbudowac robocze wymaganie eksperymentalne przed BOM-em.
%
% v6.1 nie zmienia topologii v6.
% Pracuje na zweryfikowanym modelu FOG_v6.slx.
%
% WAZNE:
% depol_residual i pol_nr_scale sa parametrami fenomenologicznymi.
% Nie sa bezposrednio DOP, ER ani parametrem katalogowym konkretnego
% depolaryzatora. Wynik v6.1 jest wymaganiem MODELowym do pozniejszej
% kalibracji eksperymentalnej.
%% ============================================================

clc
close all
bdclose('all')

disp("==============================================")
disp(" FOG v6.1 - PROG KONTROLI POLARYZACJI")
disp("==============================================")

%% ============================================================
% MODEL
%% ============================================================

sourceModel = 'FOG_v6';
mdl = 'FOG_v6_1';

if ~isfile([sourceModel '.slx'])
    error([ ...
        "Brak FOG_v6.slx. Najpierw uruchom i zweryfikuj FOG_start_v6.m." ...
        ])
end

if isfile([mdl '.slx'])
    delete([mdl '.slx'])
end

load_system(sourceModel)
save_system(sourceModel,mdl)
close_system(sourceModel,0)
load_system(mdl)

%% ============================================================
% PARAMETRY FIZYCZNE FOG - JAK v6
%% ============================================================

c = 299792458;
lambda = 1550e-9;
L = 1000;
D = 0.160;
ng = 1.4682;

K_sag = 2*pi*L*D/(lambda*c);
tau = ng*L/c;
f_opt = 1/(2*tau);

beta_target = 1.84;
f_mod = 20e3;

phi0 = ...
    beta_target/(2*abs(sin(pi*f_mod*tau)));

beta_eff = ...
    2*phi0*abs(sin(pi*f_mod*tau));

J1beta = besselj(1,beta_eff);
K_ref = 1/beta_eff;
K_phase_to_deg = (180/pi)/K_sag;

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

IL_coil_dB = alpha_fiber_dB_km*(L/1000);
eta_coil = 10^(-IL_coil_dB/10);
eta_PZT = 10^(-IL_PZT_dB/10);

IL_loop_splices_dB = ...
    N_loop_splices*IL_splice_dB;

eta_splices = ...
    10^(-IL_loop_splices_dB/10);

eta_loop = ...
    eta_coil*eta_PZT*eta_splices;

K_front_forward = ...
    K1_launch_ratio * eta_K1 * ...
    eta_conn * eta_pol * eta_dep;

K_sagnac_power = ...
    2*K2_split_ratio*(1-K2_split_ratio) * ...
    eta_K2^2 * eta_loop;

K_front_return = ...
    eta_dep * eta_pol * eta_conn * ...
    K1_detector_ratio * eta_K1;

Pdet_scale_W = ...
    P_source_W * ...
    K_front_forward * ...
    K_sagnac_power * ...
    K_front_return;

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
    Pdet_scale_W * ...
    (1 + besselj(0,beta_eff));

Iphoto_avg_A = ...
    Rpd*Pdet_avg_zero_W;

i_dark_shot_ASD = ...
    sqrt(2*q_e*I_dark_A);

i_johnson_ASD = ...
    sqrt(4*k_B*T_receiver_K/Rf);

i_opamp_current_ASD = ...
    opamp_in_A_sqrtHz;

i_opamp_voltage_eq_ASD = ...
    opamp_en_eq_A_sqrtHz;

%% ============================================================
% ADC / DSP - ROBOCZA SPECYFIKACJA PO v5.1
%% ============================================================

Vadc_min = 0.0;
Vadc_max = 2.0;
Vadc_fs = Vadc_max-Vadc_min;

adc_bits = 16;
fs_adc = 1e6;
Ts_adc = 1/fs_adc;
adc_sample_offset_s = 0;

q_adc = Vadc_fs/(2^adc_bits-1);

aa_order = 4;
f_aa_Hz = 100e3;

fc_digital_lp = 300;
digital_lp_order = 4;

[b_aa,a_aa] = ...
    butter(aa_order,2*pi*f_aa_Hz,'s');

H_aa_fmod = ...
    polyval(b_aa,1j*2*pi*f_mod) / ...
    polyval(a_aa,1j*2*pi*f_mod);

H_tia_fmod = ...
    1/(1+1j*f_mod/f_tia_Hz);

H_analog_fmod = H_tia_fmod*H_aa_fmod;

Hmag_analog_fmod = abs(H_analog_fmod);
analog_phase_lag_rad = -angle(H_analog_fmod);

ref_delay_total_s = ...
    analog_phase_lag_rad/(2*pi*f_mod);

%% ============================================================
% POLARYZACJA - JAK v6
%% ============================================================

polarizer_ER_dB = 25;
polarizer_leakage = 10^(-polarizer_ER_dB/10);

V_cal = ...
    (1-polarizer_leakage)/(1+polarizer_leakage);

pol_enable = 1;

% Wartosci chwilowe nadpisywane w petlach.
depol_residual = 0.05;
pol_nr_scale = 2.0e-4;

pol_theta0_rad = 0;
pol_theta_amp_rad = 0;

pol_delta0_rad = 0;
pol_delta_amp_rad = 0;

pol_theta_freq_Hz = 0;
pol_delta_freq_Hz = 0;
pol_delta_phase_rad = pi/5;

K_norm_digital = ...
    -1/( ...
    Pdet_scale_W * ...
    V_cal * ...
    Rpd * ...
    Rf * ...
    Hmag_analog_fmod * ...
    J1beta);

[b_dlp,a_dlp] = ...
    butter( ...
    digital_lp_order, ...
    fc_digital_lp/(fs_adc/2));

[sos_d,g_d] = tf2sos(b_dlp,a_dlp);
sos_d(1,1:3) = g_d*sos_d(1,1:3);

%% ============================================================
% SZUMY / SOLVER
%% ============================================================

Ts_solver = 0.20e-6;
Ts_noise = Ts_solver;

noise_enable = 1;

seed_photo = 210001;
seed_dark = 210002;
seed_johnson = 210003;
seed_opamp_i = 210004;
seed_opamp_en = 210005;

updateNoiseSampling();

TstopMC = 0.040;
TmeanMC = 0.030;
TavgMC = TstopMC-TmeanMC;

set_param( ...
    mdl, ...
    'SolverType','Fixed-step', ...
    'Solver','ode4', ...
    'FixedStep',sprintf('%.17g',Ts_solver), ...
    'StopTime',sprintf('%.17g',TstopMC), ...
    'ReturnWorkspaceOutputs','on');

%% ============================================================
% TEST TOPOLOGII
%% ============================================================

sagnacSub = [mdl '/Sagnac Interferometer'];

lhSag = get_param(sagnacSub,'LineHandles');

if any(lhSag.Inport == -1) || any(lhSag.Outport == -1)
    error("FOG v6.1 topology error: Sagnac subsystem is disconnected.")
end

disp("Sagnac polarization topology check: OK")

%% ============================================================
% BANK WSPOLNYCH STANOW SMF
%% ============================================================

Npair = 30;

rng(66101);

thetaBank = ...
    (-30 + 60*rand(Npair,1))*pi/180;

deltaBank = ...
    -0.5 + rand(Npair,1);

% Wspolne seedy dla wszystkich residual oraz dla par zero/signal.
baseNoiseSeeds = ...
    2200000 + (1:Npair)'*10;

%% ============================================================
% v6.1A - PAIRED DETECTION SWEEP VS RESIDUAL
%% ============================================================

disp("")
disp("==============================================")
disp(" v6.1A - PAIRED DETECTION VS RESIDUAL")
disp("==============================================")

residualSweep = [0.10 0.075 0.05 0.025 0.00]';
Nr = numel(residualSweep);

OmegaSignal = 1e-4;
pol_nr_scale = 2.0e-4;

zeroMean = zeros(Nr,1);
zeroStd = zeros(Nr,1);
zeroStdDegH = zeros(Nr,1);
zero3SigmaDegH = zeros(Nr,1);

signalMean = zeros(Nr,1);
signalStd = zeros(Nr,1);
signalBias = zeros(Nr,1);

classSeparation = zeros(Nr,1);

pairedDiffMean = zeros(Nr,1);
pairedDiffStd = zeros(Nr,1);
pairedDiffBias = zeros(Nr,1);
pairedSNR = zeros(Nr,1);

meanVisibility = zeros(Nr,1);
p05Visibility = zeros(Nr,1);

rawResidual = zeros(Nr*Npair,1);
rawRun = zeros(Nr*Npair,1);
rawThetaDeg = zeros(Nr*Npair,1);
rawDeltaRad = zeros(Nr*Npair,1);
rawZero = zeros(Nr*Npair,1);
rawSignal = zeros(Nr*Npair,1);
rawDiff = zeros(Nr*Npair,1);
rawV = zeros(Nr*Npair,1);

rawRow = 0;

for kr = 1:Nr

    depol_residual = residualSweep(kr);

    vals0 = zeros(Npair,1);
    vals1 = zeros(Npair,1);
    visVals = zeros(Npair,1);

    fprintf("\nr=%.3f: ",depol_residual)

    for irun = 1:Npair

        pol_theta0_rad = thetaBank(irun);
        pol_delta0_rad = deltaBank(irun);

        % ZERO
        Omega_deg_s = 0;
        setSeeds(baseNoiseSeeds(irun));

        out = sim(mdl);

        omega_ts = out.get('omega_est_ts');
        vpol_ts = out.get('vpol_ts');

        idxO = omega_ts.Time >= TmeanMC;
        idxV = vpol_ts.Time >= TmeanMC;

        vals0(irun) = mean(omega_ts.Data(idxO));
        visVals(irun) = mean(vpol_ts.Data(idxV));

        % SIGNAL: ten sam stan SMF i ten sam szum.
        Omega_deg_s = OmegaSignal;
        setSeeds(baseNoiseSeeds(irun));

        out = sim(mdl);

        omega_ts = out.get('omega_est_ts');

        idxO = omega_ts.Time >= TmeanMC;
        vals1(irun) = mean(omega_ts.Data(idxO));

        rawRow = rawRow+1;

        rawResidual(rawRow) = depol_residual;
        rawRun(rawRow) = irun;
        rawThetaDeg(rawRow) = thetaBank(irun)*180/pi;
        rawDeltaRad(rawRow) = deltaBank(irun);
        rawZero(rawRow) = vals0(irun);
        rawSignal(rawRow) = vals1(irun);
        rawDiff(rawRow) = vals1(irun)-vals0(irun);
        rawV(rawRow) = visVals(irun);

        fprintf(".")
    end

    fprintf(" done")

    zeroMean(kr) = mean(vals0);
    zeroStd(kr) = std(vals0);
    zeroStdDegH(kr) = zeroStd(kr)*3600;
    zero3SigmaDegH(kr) = 3*zeroStdDegH(kr);

    signalMean(kr) = mean(vals1);
    signalStd(kr) = std(vals1);
    signalBias(kr) = signalMean(kr)-OmegaSignal;

    pooledSigma = ...
        sqrt((zeroStd(kr)^2+signalStd(kr)^2)/2);

    classSeparation(kr) = ...
        abs(signalMean(kr)-zeroMean(kr))/pooledSigma;

    pairDiff = vals1-vals0;

    pairedDiffMean(kr) = mean(pairDiff);
    pairedDiffStd(kr) = std(pairDiff);
    pairedDiffBias(kr) = ...
        pairedDiffMean(kr)-OmegaSignal;

    if pairedDiffStd(kr) > 0
        pairedSNR(kr) = ...
            abs(pairedDiffMean(kr))/pairedDiffStd(kr);
    else
        pairedSNR(kr) = Inf;
    end

    meanVisibility(kr) = mean(visVals);
    p05Visibility(kr) = empiricalPercentile(visVals,5);
end

detectionResults = table( ...
    residualSweep, ...
    repmat(Npair,Nr,1), ...
    zeroMean, ...
    zeroStd, ...
    zeroStdDegH, ...
    zero3SigmaDegH, ...
    signalMean, ...
    signalStd, ...
    signalBias, ...
    classSeparation, ...
    pairedDiffMean, ...
    pairedDiffStd, ...
    pairedDiffBias, ...
    pairedSNR, ...
    meanVisibility, ...
    p05Visibility, ...
    'VariableNames', ...
    { ...
    'Depol_residual', ...
    'N_pairs', ...
    'Zero_mean_deg_s', ...
    'Zero_STD_deg_s', ...
    'Zero_STD_deg_h', ...
    'Zero_3sigma_deg_h', ...
    'Signal_mean_deg_s', ...
    'Signal_STD_deg_s', ...
    'Signal_bias_deg_s', ...
    'Unpaired_class_separation_sigma', ...
    'Paired_delta_mean_deg_s', ...
    'Paired_delta_STD_deg_s', ...
    'Paired_delta_bias_deg_s', ...
    'Paired_delta_SNR', ...
    'Mean_visibility', ...
    'P05_visibility' ...
    });

disp("")
disp(detectionResults)

writetable( ...
    detectionResults, ...
    'FOG_v6_1_detection_vs_residual.csv');

rawResults = table( ...
    rawResidual(1:rawRow), ...
    rawRun(1:rawRow), ...
    rawThetaDeg(1:rawRow), ...
    rawDeltaRad(1:rawRow), ...
    rawZero(1:rawRow), ...
    rawSignal(1:rawRow), ...
    rawDiff(1:rawRow), ...
    rawV(1:rawRow), ...
    'VariableNames', ...
    { ...
    'Depol_residual', ...
    'Run', ...
    'Theta_deg', ...
    'Delta_rad', ...
    'Omega_zero_deg_s', ...
    'Omega_signal_deg_s', ...
    'Paired_delta_Omega_deg_s', ...
    'Mean_visibility' ...
    });

writetable( ...
    rawResults, ...
    'FOG_v6_1_paired_raw.csv');

%% ============================================================
% PROG 3-SIGMA / 4-SIGMA
%% ============================================================

[r3,status3] = ...
    estimateResidualThreshold( ...
    residualSweep,classSeparation,3);

[r4,status4] = ...
    estimateResidualThreshold( ...
    residualSweep,classSeparation,4);

fprintf("\nTHRESHOLD ESTIMATE\n")
fprintf("---------------------------------\n")
fprintf("3-sigma residual    = %s\n",formatThreshold(r3,status3))
fprintf("4-sigma residual    = %s\n",formatThreshold(r4,status4))

%% ============================================================
% v6.1B - SWEEP pol_nr_scale
%% ============================================================

disp("")
disp("==============================================")
disp(" v6.1B - POLARIZATION PHASE SCALE SWEEP")
disp("==============================================")

% Badamy kandydat residual = 0.05.
depol_residual = 0.05;
Omega_deg_s = 0;
noise_enable = 1;

nrScaleSweep = [0 0.5e-4 1e-4 2e-4 4e-4 8e-4]';
Ns = numel(nrScaleSweep);

Nnr = 20;

% Ten sam podzbior banku stanow i seedow dla kazdego scale.
thetaNR = thetaBank(1:Nnr);
deltaNR = deltaBank(1:Nnr);
seedNR = baseNoiseSeeds(1:Nnr) + 500000;

nrMean = zeros(Ns,1);
nrStd = zeros(Ns,1);
nrStdDegH = zeros(Ns,1);
nrRMS = zeros(Ns,1);
nrP95Abs = zeros(Ns,1);
nrMaxAbs = zeros(Ns,1);

for ks = 1:Ns

    pol_nr_scale = nrScaleSweep(ks);

    vals = zeros(Nnr,1);

    fprintf("\npol_nr_scale=%.2e: ",pol_nr_scale)

    for irun = 1:Nnr

        pol_theta0_rad = thetaNR(irun);
        pol_delta0_rad = deltaNR(irun);

        setSeeds(seedNR(irun));

        out = sim(mdl);

        omega_ts = out.get('omega_est_ts');

        idxO = omega_ts.Time >= TmeanMC;
        vals(irun) = mean(omega_ts.Data(idxO));

        fprintf(".")
    end

    fprintf(" done")

    nrMean(ks) = mean(vals);
    nrStd(ks) = std(vals);
    nrStdDegH(ks) = nrStd(ks)*3600;
    nrRMS(ks) = sqrt(mean(vals.^2));
    nrP95Abs(ks) = empiricalPercentile(abs(vals),95);
    nrMaxAbs(ks) = max(abs(vals));
end

nrResults = table( ...
    nrScaleSweep, ...
    repmat(depol_residual,Ns,1), ...
    repmat(Nnr,Ns,1), ...
    nrMean, ...
    nrStd, ...
    nrStdDegH, ...
    nrRMS, ...
    nrP95Abs, ...
    nrMaxAbs, ...
    'VariableNames', ...
    { ...
    'pol_nr_scale', ...
    'Depol_residual', ...
    'N_runs', ...
    'Zero_mean_deg_s', ...
    'Zero_STD_deg_s', ...
    'Zero_STD_deg_h', ...
    'Zero_RMS_deg_s', ...
    'P95_abs_Omega_deg_s', ...
    'Max_abs_Omega_deg_s' ...
    });

disp("")
disp(nrResults)

writetable( ...
    nrResults, ...
    'FOG_v6_1_pol_nr_scale_sweep.csv');

%% ============================================================
% v6.1C - MODEL REQUIREMENT
%% ============================================================

disp("")
disp("==============================================")
disp(" v6.1C - MODEL REQUIREMENT")
disp("==============================================")

testedResidual3 = ...
    maxResidualMeeting(residualSweep,classSeparation,3);

testedResidual4 = ...
    maxResidualMeeting(residualSweep,classSeparation,4);

requirement = [ ...
    "fiber_type"; ...
    "fiber_length_m"; ...
    "target_rate_deg_s"; ...
    "polarizer_ER_dB"; ...
    "pol_nr_scale_reference"; ...
    "largest_tested_residual_for_3sigma"; ...
    "largest_tested_residual_for_4sigma"; ...
    "interpolated_residual_3sigma"; ...
    "interpolated_residual_4sigma"; ...
    "ADC_bits"; ...
    "ADC_fs_MSps"; ...
    "AAF_kHz" ...
    ];

value = [ ...
    "standard SMF"; ...
    string(L); ...
    string(OmegaSignal); ...
    string(polarizer_ER_dB); ...
    "2e-4"; ...
    string(testedResidual3); ...
    string(testedResidual4); ...
    thresholdString(r3,status3); ...
    thresholdString(r4,status4); ...
    string(adc_bits); ...
    string(fs_adc/1e6); ...
    string(f_aa_Hz/1e3) ...
    ];

note = [ ...
    "non-PM coil"; ...
    "model"; ...
    "0.36 deg/h"; ...
    "assumption, not BOM"; ...
    "phenomenological"; ...
    "tested grid, robust class separation"; ...
    "tested grid, robust class separation"; ...
    "linear interpolation, model only"; ...
    "linear interpolation, model only"; ...
    "v5.1 preferred"; ...
    "v5.1 nominal"; ...
    "v5.1 working candidate" ...
    ];

requirementTable = table(requirement,value,note);

disp(requirementTable)

writetable( ...
    requirementTable, ...
    'FOG_v6_1_requirement.csv');

%% ============================================================
% WYKRESY
%% ============================================================

figure('Name','FOG v6.1 - detection threshold')

plot( ...
    residualSweep, ...
    classSeparation, ...
    'o-', ...
    'LineWidth',1.5)

hold on
yline(3,'--')
yline(4,':')

grid on
xlabel('depol residual')
ylabel('Zero / signal separation [sigma]')
title('FOG v6.1 - wymagany poziom kontroli polaryzacji')

figure('Name','FOG v6.1 - zero sigma')

plot( ...
    residualSweep, ...
    zeroStdDegH, ...
    'o-', ...
    'LineWidth',1.5)

grid on
xlabel('depol residual')
ylabel('Zero-rate sigma [deg/h]')
title('FOG v6.1 - zero-rate noise vs polarization residual')

figure('Name','FOG v6.1 - pol NR scale')

semilogx( ...
    max(nrScaleSweep,1e-8), ...
    nrStdDegH, ...
    'o-', ...
    'LineWidth',1.5)

grid on
xlabel('pol nr scale')
ylabel('Zero-rate sigma [deg/h]')
title('FOG v6.1 - wrazliwosc na polarization phase scale')

%% ============================================================
% STAN KONCOWY MODELU
%% ============================================================

pol_enable = 1;
depol_residual = 0.05;
pol_nr_scale = 2.0e-4;

pol_theta0_rad = 15*pi/180;
pol_theta_amp_rad = 20*pi/180;

pol_delta0_rad = 0.20;
pol_delta_amp_rad = 0.30;

pol_theta_freq_Hz = 17;
pol_delta_freq_Hz = 23;

noise_enable = 1;
Omega_deg_s = 0;

Ts_solver = 0.05e-6;
updateNoiseSampling();

set_param( ...
    mdl, ...
    'FixedStep',sprintf('%.17g',Ts_solver), ...
    'StopTime','0.05');

save_system(mdl)
open_system(mdl)

disp("")
disp("==============================================")
disp(" FOG v6.1 - ANALIZA ZAKONCZONA")
disp("==============================================")
disp("")
disp("Utworzono:")
disp("  FOG_v6_1.slx")
disp("  FOG_v6_1_detection_vs_residual.csv")
disp("  FOG_v6_1_paired_raw.csv")
disp("  FOG_v6_1_pol_nr_scale_sweep.csv")
disp("  FOG_v6_1_requirement.csv")
disp("")
disp("Interpretacja:")
disp("  separation >= 3 sigma -> roboczy prog detekcji")
disp("  separation >= 4 sigma -> konserwatywniejszy prog")
disp("")
disp("UWAGA: residual jest parametrem modelowym.")
disp("Nie wolno utozsamiac go 1:1 z katalogowym DOP.")
disp("")

%% ============================================================
% FUNKCJE
%% ============================================================

function updateNoiseSampling()

    Ts_l = evalin('caller','Ts_solver');

    i_dark_l = evalin('caller','i_dark_shot_ASD');
    i_johnson_l = evalin('caller','i_johnson_ASD');
    i_opampi_l = evalin('caller','i_opamp_current_ASD');
    i_opampe_l = evalin('caller','i_opamp_voltage_eq_ASD');

    scale_l = 1/sqrt(2*Ts_l);

    assignin('caller','Ts_noise',Ts_l);
    assignin('caller','noise_sample_scale',scale_l);

    assignin( ...
        'caller','sigma_dark_sample_A', ...
        i_dark_l*scale_l);

    assignin( ...
        'caller','sigma_johnson_sample_A', ...
        i_johnson_l*scale_l);

    assignin( ...
        'caller','sigma_opamp_current_sample_A', ...
        i_opampi_l*scale_l);

    assignin( ...
        'caller','sigma_opamp_voltage_sample_A', ...
        i_opampe_l*scale_l);
end

function setSeeds(baseSeed)

    assignin('caller','seed_photo',baseSeed+1);
    assignin('caller','seed_dark',baseSeed+2);
    assignin('caller','seed_johnson',baseSeed+3);
    assignin('caller','seed_opamp_i',baseSeed+4);
    assignin('caller','seed_opamp_en',baseSeed+5);
end

function q = empiricalPercentile(x,p)

    x = sort(x(:));
    n = numel(x);

    if n == 0
        q = NaN;
        return
    end

    if n == 1
        q = x(1);
        return
    end

    pos = 1 + (n-1)*(p/100);
    i0 = floor(pos);
    i1 = ceil(pos);

    if i0 == i1
        q = x(i0);
    else
        w = pos-i0;
        q = (1-w)*x(i0) + w*x(i1);
    end
end

function r = maxResidualMeeting(residual,separation,target)

    ok = separation >= target;

    if any(ok)
        r = max(residual(ok));
    else
        r = NaN;
    end
end

function [r,status] = estimateResidualThreshold(residual,separation,target)

    [rSort,idx] = sort(residual(:));
    sSort = separation(idx);

    good = sSort >= target;

    if all(good)
        r = max(rSort);
        status = "at_or_above_max_tested";
        return
    end

    if ~any(good)
        r = NaN;
        status = "below_min_tested";
        return
    end

    % Najwiekszy residual, ktory jeszcze przechodzi.
    iGood = find(good,1,'last');

    if iGood == numel(rSort)
        r = rSort(iGood);
        status = "at_or_above_max_tested";
        return
    end

    r1 = rSort(iGood);
    s1 = sSort(iGood);

    r2 = rSort(iGood+1);
    s2 = sSort(iGood+1);

    if s2 == s1
        r = r1;
    else
        r = ...
            r1 + (target-s1)*(r2-r1)/(s2-s1);
    end

    status = "interpolated";
end

function s = thresholdString(r,status)

    if isnan(r)
        s = status;
    else
        s = string(r);
    end
end

function s = formatThreshold(r,status)

    if isnan(r)
        s = char(status);
    else
        s = sprintf('%.5f (%s)',r,char(status));
    end
end
