%% ============================================================
% FOG_start_v5.m
% Interferometryczny zyroskop swiatlowodowy - model v5
% MATLAB / Simulink R2023b
%
% v5:
% - zachowuje zweryfikowana optyke i Photoreceiver v4,
% - dodaje fizyczny blok ADC / AFE,
% - dodaje analogowy filtr antyaliasingowy,
% - dodaje sampling i hold,
% - dodaje saturacje zakresu ADC,
% - dodaje kwantyzacje N-bit,
% - przebudowuje Lock-In DSP na tor w pelni cyfrowy,
% - wykonuje sweep rozdzielczosci ADC,
% - wykonuje sweep fs ADC,
% - wykonuje Monte Carlo 12/14/16 bit,
% - porownuje szum ADC z analogowym limitem v4.1.
%
% Nominalna konfiguracja v5:
%   ADC: 16 bit, 0..2 V, 1 MS/s
%   AAF: Butterworth 4 rzedu, fc = 150 kHz
%   Digital LPF: Butterworth 4 rzedu, fc = 300 Hz
%
% UWAGA:
% Parametry ADC sa zalozeniami projektowymi, nie zatwierdzonym BOM-em.
%% ============================================================

clc
close all
bdclose('all')

disp("==============================================")
disp(" FOG v5 - ADC + CYFROWY LOCK-IN")
disp("==============================================")

%% ============================================================
% PRZYGOTOWANIE MODELU v4
%% ============================================================

sourceModel = 'FOG_v4';
mdl = 'FOG_v5';

if ~isfile([sourceModel '.slx'])

    if isfile('FOG_start_v4.m')
        disp("FOG_v4.slx nie istnieje. Uruchamiam FOG_start_v4.m...")
        run('FOG_start_v4.m')
        bdclose('all')
    else
        error([ ...
            "Brak FOG_v4.slx oraz FOG_start_v4.m w aktualnym folderze. " ...
            "Najpierw pobierz i zweryfikuj v4." ...
            ])
    end
end

if isfile([mdl '.slx'])
    delete([mdl '.slx'])
end

load_system(sourceModel)
save_system(sourceModel,mdl)
close_system(sourceModel,0)
load_system(mdl)

%% ============================================================
% PARAMETRY FIZYCZNE FOG - JAK v4
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

phi0 = beta_target / ...
    (2*abs(sin(pi*f_mod*tau)));

beta_eff = ...
    2*phi0*abs(sin(pi*f_mod*tau));

%% ============================================================
% OPTYKA - JAK v4
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

visibility = 1.0;

eta_K1 = 10^(-IL_K1_dB/10);
eta_conn = 10^(-IL_connector_common_dB/10);
eta_pol = 10^(-IL_polarizer_dB/10);
eta_dep = 10^(-IL_depolarizer_dB/10);
eta_K2 = 10^(-IL_K2_dB/10);

IL_coil_dB = ...
    alpha_fiber_dB_km*(L/1000);

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
% PHOTORECEIVER v4 - PARAMETRY
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

%% ============================================================
% SZUMY PHOTORECEIVERA - JAK v4
%% ============================================================

% Do analitycznego budzetu wykorzystujemy srednia moc przy Omega=0.
Pdet_avg_zero_W = ...
    Pdet_scale_W * ...
    (1 + visibility*besselj(0,beta_eff));

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
% ADC / AFE - NOMINALNA KONFIGURACJA
%% ============================================================

adc_bits = 16;
Vadc_min = 0.0;
Vadc_max = 2.0;
Vadc_fs = Vadc_max-Vadc_min;

fs_adc = 1e6;
Ts_adc = 1/fs_adc;

q_adc = ...
    Vadc_fs/(2^adc_bits-1);

% Analog anti-alias filter.
aa_order = 4;
f_aa_Hz = 150e3;

[b_aa,a_aa] = ...
    butter(aa_order,2*pi*f_aa_Hz,'s');

H_aa_fmod = ...
    polyval(b_aa,1j*2*pi*f_mod) / ...
    polyval(a_aa,1j*2*pi*f_mod);

Hmag_aa_fmod = abs(H_aa_fmod);
aa_phase_lag_rad = -angle(H_aa_fmod);

%% ============================================================
% TIA RESPONSE @ f_mod
%% ============================================================

H_tia_fmod = ...
    1/(1+1j*f_mod/f_tia_Hz);

Hmag_tia_fmod = ...
    abs(H_tia_fmod);

tia_phase_lag_rad = ...
    -angle(H_tia_fmod);

%% ============================================================
% TOTAL ANALOG GAIN / PHASE @ CARRIER
%% ============================================================

Hmag_analog_fmod = ...
    Hmag_tia_fmod*Hmag_aa_fmod;

analog_phase_lag_rad = ...
    tia_phase_lag_rad + aa_phase_lag_rad;

ref_delay_total_s = ...
    analog_phase_lag_rad/(2*pi*f_mod);

%% ============================================================
% DIGITAL LOCK-IN
%% ============================================================

fc_digital_lp = 300;
digital_lp_order = 4;

[b_dlp,a_dlp] = ...
    butter( ...
    digital_lp_order, ...
    fc_digital_lp/(fs_adc/2));

[sos_d,g_d] = ...
    tf2sos(b_dlp,a_dlp);

sos_d(1,1:3) = ...
    g_d*sos_d(1,1:3);

J1beta = besselj(1,beta_eff);
K_ref = 1/beta_eff;

K_norm_digital = ...
    -1/( ...
    Pdet_scale_W * ...
    visibility * ...
    Rpd * ...
    Rf * ...
    Hmag_analog_fmod * ...
    J1beta);

K_phase_to_deg = ...
    (180/pi)/K_sag;

%% ============================================================
% POLITYKA NUMERYCZNA
%% ============================================================

% Nominalny baseline wykonujemy STANDARD.
Ts_solver = 0.05e-6;
Ts_noise = Ts_solver;

noise_sample_scale = ...
    1/sqrt(2*Ts_noise);

sigma_dark_sample_A = ...
    i_dark_shot_ASD*noise_sample_scale;

sigma_johnson_sample_A = ...
    i_johnson_ASD*noise_sample_scale;

sigma_opamp_current_sample_A = ...
    i_opamp_current_ASD*noise_sample_scale;

sigma_opamp_voltage_sample_A = ...
    i_opamp_voltage_eq_ASD*noise_sample_scale;

noise_enable = 0;

seed_photo = 71001;
seed_dark = 71002;
seed_johnson = 71003;
seed_opamp_i = 71004;
seed_opamp_en = 71005;

%% ============================================================
% ANALITYCZNY BUDZET ADC
%% ============================================================

adcBitsBudget = [8 10 12 14 16]';
NbitsBudget = numel(adcBitsBudget);

lsb_uV = zeros(NbitsBudget,1);
quantRms_uV = zeros(NbitsBudget,1);
quantASD_nV = zeros(NbitsBudget,1);
analogASD_nV = zeros(NbitsBudget,1);
inputNoiseIncrease = zeros(NbitsBudget,1);

Vanalog_ASD_fmod = ...
    i_total_ASD * ...
    Rf * ...
    Hmag_analog_fmod;

for k = 1:NbitsBudget

    qk = ...
        Vadc_fs/(2^adcBitsBudget(k)-1);

    lsb_uV(k) = qk*1e6;
    quantRms_uV(k) = qk/sqrt(12)*1e6;

    % Jednostronna ASD kwantyzacji zakladajaca bialy blad kwantyzacji.
    quantASD = ...
        qk/sqrt(6*fs_adc);

    quantASD_nV(k) = ...
        quantASD*1e9;

    analogASD_nV(k) = ...
        Vanalog_ASD_fmod*1e9;

    inputNoiseIncrease(k) = ...
        sqrt(1+(quantASD/Vanalog_ASD_fmod)^2);
end

adcBudget = table( ...
    adcBitsBudget, ...
    lsb_uV, ...
    quantRms_uV, ...
    quantASD_nV, ...
    analogASD_nV, ...
    inputNoiseIncrease, ...
    'VariableNames', ...
    { ...
    'ADC_bits', ...
    'LSB_uV', ...
    'Quantization_RMS_uV', ...
    'Quantization_ASD_nV_sqrtHz', ...
    'Analog_noise_ASD_at_fmod_nV_sqrtHz', ...
    'Predicted_total_noise_factor' ...
    });

writetable( ...
    adcBudget, ...
    'FOG_v5_adc_noise_budget.csv');

%% ============================================================
% PRZEBUDOWA TOP-LEVEL
%% ============================================================

oldDSP = [mdl '/Lock-In DSP'];

% Odpinamy stary DSP.
try
    delete_line(mdl,'Photoreceiver/1','Lock-In DSP/1');
catch
end

try
    delete_line(mdl,'Sagnac Interferometer/2','Lock-In DSP/2');
catch
end

try
    delete_line(mdl,'Lock-In DSP/1','Omega Display/1');
catch
end

try
    delete_line(mdl,'Lock-In DSP/1','Save_Omega/1');
catch
end

% Zmieniamy nazwe subsystemu, by top-level odpowiadal architekturze v5.
set_param(oldDSP,'Name','Digital Lock-In DSP');

dspSub = [mdl '/Digital Lock-In DSP'];

% ADC / AFE.
adcSub = [mdl '/ADC AFE'];

if getSimulinkBlockHandle(adcSub) ~= -1
    delete_block(adcSub)
end

add_block( ...
    'simulink/Ports & Subsystems/Subsystem', ...
    adcSub, ...
    'Position',[1040 145 1190 295]);

buildADCAFE(adcSub);

set_param( ...
    adcSub, ...
    'BackgroundColor','lightBlue', ...
    'AttributesFormatString', ...
    'AAF 150 kHz + sample/hold + N-bit ADC');

% Cyfrowy lock-in.
buildDigitalDSP(dspSub);

set_param( ...
    dspSub, ...
    'Position',[1280 140 1460 300], ...
    'BackgroundColor','green', ...
    'AttributesFormatString', ...
    'sampled reference + mixer + digital LPF + asin');

% Przesuwamy wskaznik i logger.
set_param([mdl '/Omega Display'], ...
    'Position',[1540 175 1640 225]);

set_param([mdl '/Save_Omega'], ...
    'Position',[1540 270 1650 310]);

%% ============================================================
% TOP-LEVEL POLACZENIA v5
%% ============================================================

add_line( ...
    mdl, ...
    'Photoreceiver/1', ...
    'ADC AFE/1', ...
    'autorouting','on');

add_line( ...
    mdl, ...
    'ADC AFE/1', ...
    'Digital Lock-In DSP/1', ...
    'autorouting','on');

add_line( ...
    mdl, ...
    'Sagnac Interferometer/2', ...
    'Digital Lock-In DSP/2', ...
    'autorouting','on');

add_line( ...
    mdl, ...
    'Digital Lock-In DSP/1', ...
    'Omega Display/1', ...
    'autorouting','on');

add_line( ...
    mdl, ...
    'Digital Lock-In DSP/1', ...
    'Save_Omega/1', ...
    'autorouting','on');

%% ============================================================
% LOGGery ADC
%% ============================================================

if getSimulinkBlockHandle([mdl '/Save_ADC']) == -1

    add_block( ...
        'simulink/Sinks/To Workspace', ...
        [mdl '/Save_ADC'], ...
        'VariableName','vadc_ts', ...
        'SaveFormat','Timeseries', ...
        'Position',[1220 345 1330 385]);

    add_line( ...
        mdl, ...
        'ADC AFE/1', ...
        'Save_ADC/1', ...
        'autorouting','on');
end

if getSimulinkBlockHandle([mdl '/Save_AAF']) == -1

    add_block( ...
        'simulink/Sinks/To Workspace', ...
        [mdl '/Save_AAF'], ...
        'VariableName','vaaf_ts', ...
        'SaveFormat','Timeseries', ...
        'Position',[1040 345 1150 385]);

    add_line( ...
        mdl, ...
        'ADC AFE/2', ...
        'Save_AAF/1', ...
        'autorouting','on');
end

%% ============================================================
% TEST TOPOLOGII
%% ============================================================

lhADC = get_param(adcSub,'LineHandles');
lhDSP = get_param(dspSub,'LineHandles');

if lhADC.Inport(1) == -1 || lhADC.Outport(1) == -1
    error("FOG v5 topology error: ADC AFE is disconnected.")
end

if any(lhDSP.Inport == -1) || lhDSP.Outport(1) == -1
    error("FOG v5 topology error: Digital Lock-In DSP is disconnected.")
end

disp("ADC/DSP topology check: OK")

%% ============================================================
% INFORMACJE
%% ============================================================

fprintf("\nADC v5 - KONFIGURACJA NOMINALNA\n")
fprintf("---------------------------------\n")
fprintf("ADC bits             = %d\n",adc_bits)
fprintf("ADC range            = %.3f ... %.3f V\n",Vadc_min,Vadc_max)
fprintf("ADC fs               = %.3f MS/s\n",fs_adc/1e6)
fprintf("ADC LSB              = %.3f uV\n",q_adc*1e6)
fprintf("AAF order            = %d\n",aa_order)
fprintf("AAF fc               = %.1f kHz\n",f_aa_Hz/1e3)
fprintf("|H_TIA @20k|         = %.8f\n",Hmag_tia_fmod)
fprintf("|H_AAF @20k|         = %.8f\n",Hmag_aa_fmod)
fprintf("total analog lag     = %.3f deg\n",analog_phase_lag_rad*180/pi)
fprintf("reference delay      = %.3f us\n",ref_delay_total_s*1e6)

disp("")
disp("ANALITYCZNY BUDZET ADC")
disp(adcBudget)

%% ============================================================
% v5A - NOMINALNY BASELINE BEZ SZUMU
%% ============================================================

disp("")
disp("==============================================")
disp(" v5A - NOMINALNY ADC 16 bit / 1 MS/s")
disp("==============================================")

Omega_deg_s = 1;
noise_enable = 0;

adc_bits = 16;
fs_adc = 1e6;

updateADCVariables();

Ts_solver = 0.05e-6;
updateNoiseSampling();

Tstop = 0.050;
Tmean_start = 0.040;

set_param( ...
    mdl, ...
    'SolverType','Fixed-step', ...
    'Solver','ode4', ...
    'FixedStep',sprintf('%.17g',Ts_solver), ...
    'StopTime',sprintf('%.17g',Tstop), ...
    'ReturnWorkspaceOutputs','on');

out = sim(mdl);

omega_ts = out.get('omega_est_ts');
vadc_ts = out.get('vadc_ts');
vaaf_ts = out.get('vaaf_ts');

idxOmega = ...
    omega_ts.Time >= Tmean_start;

idxADC = ...
    vadc_ts.Time >= Tmean_start;

idxAAF = ...
    vaaf_ts.Time >= Tmean_start;

omega_nominal = ...
    mean(omega_ts.Data(idxOmega));

omega_nominal_std = ...
    std(omega_ts.Data(idxOmega));

vadc_min = min(vadc_ts.Data(idxADC));
vadc_max = max(vadc_ts.Data(idxADC));

vaaf_min = min(vaaf_ts.Data(idxAAF));
vaaf_max = max(vaaf_ts.Data(idxAAF));

adc_headroom_low = ...
    vaaf_min-Vadc_min;

adc_headroom_high = ...
    Vadc_max-vaaf_max;

fprintf("Omega zadane         = %.9f deg/s\n",Omega_deg_s)
fprintf("Omega ADC            = %.9f deg/s\n",omega_nominal)
fprintf("Blad                 = %+ .9e deg/s\n",omega_nominal-Omega_deg_s)
fprintf("STD                  = %.9e deg/s\n",omega_nominal_std)
fprintf("AAF min/max          = %.6f / %.6f V\n",vaaf_min,vaaf_max)
fprintf("ADC min/max          = %.6f / %.6f V\n",vadc_min,vadc_max)
fprintf("headroom low/high    = %.3f / %.3f mV\n", ...
    adc_headroom_low*1e3,adc_headroom_high*1e3)

baseline = table( ...
    adc_bits, ...
    fs_adc/1e6, ...
    q_adc*1e6, ...
    Omega_deg_s, ...
    omega_nominal, ...
    omega_nominal-Omega_deg_s, ...
    omega_nominal_std, ...
    vaaf_min, ...
    vaaf_max, ...
    adc_headroom_low, ...
    adc_headroom_high, ...
    'VariableNames', ...
    { ...
    'ADC_bits', ...
    'fs_ADC_MSps', ...
    'LSB_uV', ...
    'Omega_zadane_deg_s', ...
    'Omega_zmierzone_deg_s', ...
    'Blad_Omega_deg_s', ...
    'STD_Omega_deg_s', ...
    'AAF_min_V', ...
    'AAF_max_V', ...
    'ADC_headroom_low_V', ...
    'ADC_headroom_high_V' ...
    });

writetable( ...
    baseline, ...
    'FOG_v5_baseline.csv');

%% ============================================================
% v5B - SWEEP ROZDZIELCZOSCI ADC
%% ============================================================

disp("")
disp("==============================================")
disp(" v5B - SWEEP ADC BITS")
disp("==============================================")

bitsSweep = [8 10 12 14 16]';
Nb = numel(bitsSweep);

fs_adc = 1e6;
OmegaLarge = 1;
OmegaSmall = 1e-4;

errLarge = zeros(Nb,1);
errSmall = zeros(Nb,1);
estLarge = zeros(Nb,1);
estSmall = zeros(Nb,1);
lsbSweep_uV = zeros(Nb,1);

for k = 1:Nb

    adc_bits = bitsSweep(k);
    updateADCVariables();

    lsbSweep_uV(k) = q_adc*1e6;

    Omega_deg_s = OmegaLarge;
    out = sim(mdl);
    omega_ts = out.get('omega_est_ts');
    idx = omega_ts.Time >= Tmean_start;

    estLarge(k) = mean(omega_ts.Data(idx));
    errLarge(k) = estLarge(k)-OmegaLarge;

    Omega_deg_s = OmegaSmall;
    out = sim(mdl);
    omega_ts = out.get('omega_est_ts');
    idx = omega_ts.Time >= Tmean_start;

    estSmall(k) = mean(omega_ts.Data(idx));
    errSmall(k) = estSmall(k)-OmegaSmall;

    fprintf( ...
        "%2d bit: LSB=%8.3f uV, e@1=%+ .3e, e@1e-4=%+ .3e deg/s\n", ...
        adc_bits,q_adc*1e6,errLarge(k),errSmall(k))
end

bitSweepResults = table( ...
    bitsSweep, ...
    lsbSweep_uV, ...
    estLarge, ...
    errLarge, ...
    estSmall, ...
    errSmall, ...
    'VariableNames', ...
    { ...
    'ADC_bits', ...
    'LSB_uV', ...
    'Omega_est_at_1deg_s', ...
    'Error_at_1deg_s', ...
    'Omega_est_at_1e_4deg_s', ...
    'Error_at_1e_4deg_s' ...
    });

writetable( ...
    bitSweepResults, ...
    'FOG_v5_bit_sweep.csv');

%% ============================================================
% v5C - SWEEP CZESTOTLIWOSCI PROBKOWANIA
%% ============================================================

disp("")
disp("==============================================")
disp(" v5C - SWEEP fs ADC")
disp("==============================================")

fsSweep = [100e3 200e3 500e3 1e6 2e6]';
Nfs = numel(fsSweep);

adc_bits = 16;
Omega_deg_s = 1;

samplesPerCarrier = zeros(Nfs,1);
nyquistAA_dB = zeros(Nfs,1);
nyquistCombined_dB = zeros(Nfs,1);
fsEst = zeros(Nfs,1);
fsErr = zeros(Nfs,1);

for k = 1:Nfs

    fs_adc = fsSweep(k);
    updateADCVariables();

    samplesPerCarrier(k) = ...
        fs_adc/f_mod;

    HaaNyq = ...
        polyval(b_aa,1j*2*pi*(fs_adc/2)) / ...
        polyval(a_aa,1j*2*pi*(fs_adc/2));

    HtiaNyq = ...
        1/(1+1j*(fs_adc/2)/f_tia_Hz);

    nyquistAA_dB(k) = ...
        20*log10(abs(HaaNyq));

    nyquistCombined_dB(k) = ...
        20*log10(abs(HaaNyq*HtiaNyq));

    out = sim(mdl);
    omega_ts = out.get('omega_est_ts');
    idx = omega_ts.Time >= Tmean_start;

    fsEst(k) = mean(omega_ts.Data(idx));
    fsErr(k) = fsEst(k)-Omega_deg_s;

    fprintf( ...
        "fs=%7.0f kS/s, samples/carrier=%6.1f, eOmega=%+ .3e deg/s\n", ...
        fs_adc/1e3,samplesPerCarrier(k),fsErr(k))
end

fsSweepResults = table( ...
    fsSweep/1e3, ...
    samplesPerCarrier, ...
    nyquistAA_dB, ...
    nyquistCombined_dB, ...
    fsEst, ...
    fsErr, ...
    'VariableNames', ...
    { ...
    'fs_ADC_kSps', ...
    'Samples_per_20kHz_period', ...
    'AAF_gain_at_Nyquist_dB', ...
    'TIA_plus_AAF_gain_at_Nyquist_dB', ...
    'Omega_est_deg_s', ...
    'Omega_error_deg_s' ...
    });

writetable( ...
    fsSweepResults, ...
    'FOG_v5_fs_sweep.csv');

%% ============================================================
% v5D - MONTE CARLO: 12 / 14 / 16 bit
%% ============================================================

disp("")
disp("==============================================")
disp(" v5D - ADC MONTE CARLO @ ZERO RATE")
disp("==============================================")

bitsMC = [12 14 16]';
NbitsMC = numel(bitsMC);
Nmc = 30;

% Powrot do nominalnego fs.
fs_adc = 1e6;

% FAST dla Monte Carlo.
Ts_solver = 0.20e-6;
updateNoiseSampling();

noise_enable = 1;
Omega_deg_s = 0;

TstopMC = 0.040;
TavgMC = 0.010;
TmeanMC = TstopMC-TavgMC;

set_param( ...
    mdl, ...
    'FixedStep',sprintf('%.17g',Ts_solver), ...
    'StopTime',sprintf('%.17g',TstopMC));

sigmaMC = zeros(NbitsMC,1);
biasMC = zeros(NbitsMC,1);
meanMC = zeros(NbitsMC,1);

predFactor = zeros(NbitsMC,1);
mcFactorVsAnalog = zeros(NbitsMC,1);

% Zweryfikowany wynik analogowego v4.1 @ 10 ms.
sigmaAnalogReference = ...
    1.99991284499952e-5;

for kb = 1:NbitsMC

    adc_bits = bitsMC(kb);
    updateADCVariables();

    vals = zeros(Nmc,1);

    qASD = ...
        q_adc/sqrt(6*fs_adc);

    predFactor(kb) = ...
        sqrt(1+(qASD/Vanalog_ASD_fmod)^2);

    fprintf("\nADC %d bit: ",adc_bits)

    for irun = 1:Nmc

        baseSeed = ...
            800000 + 1000*kb + 10*irun;

        seed_photo = baseSeed+1;
        seed_dark = baseSeed+2;
        seed_johnson = baseSeed+3;
        seed_opamp_i = baseSeed+4;
        seed_opamp_en = baseSeed+5;

        out = sim(mdl);

        omega_ts = ...
            out.get('omega_est_ts');

        idx = ...
            omega_ts.Time >= TmeanMC;

        vals(irun) = ...
            mean(omega_ts.Data(idx));

        fprintf(".")
    end

    fprintf(" done")

    meanMC(kb) = mean(vals);
    sigmaMC(kb) = std(vals);
    biasMC(kb) = meanMC(kb);

    mcFactorVsAnalog(kb) = ...
        sigmaMC(kb)/sigmaAnalogReference;
end

mcResults = table( ...
    bitsMC, ...
    repmat(fs_adc/1e6,NbitsMC,1), ...
    sigmaMC, ...
    sigmaMC*3600, ...
    biasMC, ...
    predFactor, ...
    mcFactorVsAnalog, ...
    'VariableNames', ...
    { ...
    'ADC_bits', ...
    'fs_ADC_MSps', ...
    'Zero_rate_sigma_deg_s', ...
    'Zero_rate_sigma_deg_h', ...
    'Zero_rate_bias_deg_s', ...
    'Predicted_noise_factor_vs_analog', ...
    'Measured_sigma_factor_vs_v4_1' ...
    });

disp("")
disp(mcResults)

writetable( ...
    mcResults, ...
    'FOG_v5_adc_monte_carlo.csv');

%% ============================================================
% WYKRESY
%% ============================================================

figure('Name','FOG v5 - ADC bit depth')

semilogy( ...
    bitsSweep, ...
    max(abs(errSmall),eps), ...
    'o-', ...
    'LineWidth',1.5)

hold on

semilogy( ...
    bitsSweep, ...
    max(abs(errLarge),eps), ...
    's-', ...
    'LineWidth',1.5)

grid on
xlabel('Rozdzielczosc ADC [bit]')
ylabel('|blad Omega| [deg/s]')
legend('Omega=1e-4 deg/s','Omega=1 deg/s','Location','best')
title('FOG v5 - blad deterministyczny vs ADC bits')

figure('Name','FOG v5 - ADC sample rate')

semilogx( ...
    fsSweep/1e3, ...
    max(abs(fsErr),eps), ...
    'o-', ...
    'LineWidth',1.5)

grid on
xlabel('fs ADC [kS/s]')
ylabel('|blad Omega| [deg/s]')
title('FOG v5 - blad vs czestotliwosc probkowania')

figure('Name','FOG v5 - ADC Monte Carlo')

plot( ...
    bitsMC, ...
    mcFactorVsAnalog, ...
    'o-', ...
    'LineWidth',1.5)

hold on

plot( ...
    bitsMC, ...
    predFactor, ...
    's--', ...
    'LineWidth',1.5)

grid on
xlabel('ADC bits')
ylabel('Wspolczynnik szumu wzgledem analog v4.1')
legend('Monte Carlo','predykcja ASD','Location','best')
title('FOG v5 - degradacja szumu przez ADC')

%% ============================================================
% STAN KONCOWY MODELU = NOMINALNE 16 bit / 1 MS/s
%% ============================================================

adc_bits = 16;
fs_adc = 1e6;
updateADCVariables();

Ts_solver = 0.05e-6;
updateNoiseSampling();

noise_enable = 1;
Omega_deg_s = 0;

set_param( ...
    mdl, ...
    'FixedStep',sprintf('%.17g',Ts_solver), ...
    'StopTime','0.05');

save_system(mdl)
open_system(mdl)

disp("")
disp("==============================================")
disp(" FOG v5 - SYMULACJA ZAKONCZONA")
disp("==============================================")
disp("")
disp("Utworzono:")
disp("  FOG_v5.slx")
disp("  FOG_v5_baseline.csv")
disp("  FOG_v5_adc_noise_budget.csv")
disp("  FOG_v5_bit_sweep.csv")
disp("  FOG_v5_fs_sweep.csv")
disp("  FOG_v5_adc_monte_carlo.csv")
disp("")
disp("Top-level:")
disp("  Photoreceiver -> ADC AFE -> Digital Lock-In DSP")
disp("")
disp("Nominalnie:")
disp("  16 bit, 1 MS/s, 0..2 V, AAF 150 kHz")
disp("")

%% ============================================================
% FUNKCJE NESTED
%% ============================================================

function updateADCVariables()

    % Funkcja aktualizuje zmienne w workspace skryptu przez assignin
    % do workspace wywolujacego. Jest wywolywana tylko z tego skryptu.

    adc_bits_l = evalin('caller','adc_bits');
    Vadc_fs_l = evalin('caller','Vadc_fs');
    fs_adc_l = evalin('caller','fs_adc');
    fc_l = evalin('caller','fc_digital_lp');
    order_l = evalin('caller','digital_lp_order');

    Ts_adc_l = 1/fs_adc_l;
    q_adc_l = Vadc_fs_l/(2^adc_bits_l-1);

    [b_l,a_l] = ...
        butter(order_l,fc_l/(fs_adc_l/2));

    [sos_l,g_l] = ...
        tf2sos(b_l,a_l);

    sos_l(1,1:3) = ...
        g_l*sos_l(1,1:3);

    assignin('caller','Ts_adc',Ts_adc_l);
    assignin('caller','q_adc',q_adc_l);
    assignin('caller','b_dlp',b_l);
    assignin('caller','a_dlp',a_l);
    assignin('caller','sos_d',sos_l);
end

function updateNoiseSampling()

    Ts_noise_l = evalin('caller','Ts_solver');

    i_dark_l = evalin('caller','i_dark_shot_ASD');
    i_johnson_l = evalin('caller','i_johnson_ASD');
    i_opampi_l = evalin('caller','i_opamp_current_ASD');
    i_opampe_l = evalin('caller','i_opamp_voltage_eq_ASD');

    scale_l = ...
        1/sqrt(2*Ts_noise_l);

    assignin('caller','Ts_noise',Ts_noise_l);
    assignin('caller','noise_sample_scale',scale_l);

    assignin( ...
        'caller', ...
        'sigma_dark_sample_A', ...
        i_dark_l*scale_l);

    assignin( ...
        'caller', ...
        'sigma_johnson_sample_A', ...
        i_johnson_l*scale_l);

    assignin( ...
        'caller', ...
        'sigma_opamp_current_sample_A', ...
        i_opampi_l*scale_l);

    assignin( ...
        'caller', ...
        'sigma_opamp_voltage_sample_A', ...
        i_opampe_l*scale_l);
end

function buildADCAFE(sub)

    Simulink.SubSystem.deleteContents(sub);

    add_block( ...
        'simulink/Ports & Subsystems/In1', ...
        [sub '/V_TIA'], ...
        'Port','1', ...
        'Position',[25 135 55 155]);

    add_block( ...
        'simulink/Continuous/Transfer Fcn', ...
        [sub '/Anti Alias LPF'], ...
        'Numerator','b_aa', ...
        'Denominator','a_aa', ...
        'Position',[110 115 250 175]);

    add_block( ...
        'simulink/Discontinuities/Saturation', ...
        [sub '/ADC Input Clamp'], ...
        'UpperLimit','Vadc_max', ...
        'LowerLimit','Vadc_min', ...
        'Position',[310 115 410 175]);

    add_block( ...
        'simulink/Discrete/Zero-Order Hold', ...
        [sub '/Sample and Hold'], ...
        'SampleTime','Ts_adc', ...
        'Position',[470 120 580 170]);

    add_block( ...
        'simulink/Discontinuities/Quantizer', ...
        [sub '/ADC Quantizer'], ...
        'QuantizationInterval','q_adc', ...
        'Position',[640 120 750 170]);

    add_block( ...
        'simulink/Ports & Subsystems/Out1', ...
        [sub '/V_ADC'], ...
        'Port','1', ...
        'Position',[840 128 870 152]);

    add_block( ...
        'simulink/Ports & Subsystems/Out1', ...
        [sub '/V_AAF'], ...
        'Port','2', ...
        'Position',[840 228 870 252]);

    add_line(sub,'V_TIA/1','Anti Alias LPF/1','autorouting','on');
    add_line(sub,'Anti Alias LPF/1','ADC Input Clamp/1','autorouting','on');
    add_line(sub,'ADC Input Clamp/1','Sample and Hold/1','autorouting','on');
    add_line(sub,'Sample and Hold/1','ADC Quantizer/1','autorouting','on');
    add_line(sub,'ADC Quantizer/1','V_ADC/1','autorouting','on');

    add_line(sub,'Anti Alias LPF/1','V_AAF/1','autorouting','on');
end

function buildDigitalDSP(sub)

    Simulink.SubSystem.deleteContents(sub);

    add_block( ...
        'simulink/Ports & Subsystems/In1', ...
        [sub '/V_ADC'], ...
        'Port','1', ...
        'Position',[25 80 55 100]);

    add_block( ...
        'simulink/Ports & Subsystems/In1', ...
        [sub '/Reference'], ...
        'Port','2', ...
        'Position',[25 210 55 230]);

    add_block( ...
        'simulink/Continuous/Transport Delay', ...
        [sub '/Analog Phase Match'], ...
        'DelayTime','ref_delay_total_s', ...
        'Position',[100 195 220 235]);

    add_block( ...
        'simulink/Discrete/Zero-Order Hold', ...
        [sub '/Reference Sampler'], ...
        'SampleTime','Ts_adc', ...
        'Position',[270 195 390 235]);

    add_block( ...
        'simulink/Math Operations/Product', ...
        [sub '/Digital Mixer'], ...
        'Position',[450 100 500 160]);

    % Dwa biquady zamiast jednego filtra 4-rzedowego dla lepszej
    % kondycji numerycznej przy fc << fs.
    add_block( ...
        'simulink/Discrete/Discrete Transfer Fcn', ...
        [sub '/Digital LPF SOS1'], ...
        'Numerator','sos_d(1,1:3)', ...
        'Denominator','sos_d(1,4:6)', ...
        'SampleTime','Ts_adc', ...
        'Position',[560 100 700 160]);

    add_block( ...
        'simulink/Discrete/Discrete Transfer Fcn', ...
        [sub '/Digital LPF SOS2'], ...
        'Numerator','sos_d(2,1:3)', ...
        'Denominator','sos_d(2,4:6)', ...
        'SampleTime','Ts_adc', ...
        'Position',[750 100 890 160]);

    add_block( ...
        'simulink/Math Operations/Gain', ...
        [sub '/Normalize'], ...
        'Gain','K_norm_digital', ...
        'Position',[940 105 1020 155]);

    add_block( ...
        'simulink/Discontinuities/Saturation', ...
        [sub '/Limit asin'], ...
        'UpperLimit','0.999999', ...
        'LowerLimit','-0.999999', ...
        'Position',[1070 105 1160 155]);

    add_block( ...
        'simulink/Math Operations/Trigonometric Function', ...
        [sub '/asin'], ...
        'Operator','asin', ...
        'Position',[1210 105 1280 155]);

    add_block( ...
        'simulink/Math Operations/Gain', ...
        [sub '/Phase to deg-s'], ...
        'Gain','K_phase_to_deg', ...
        'Position',[1330 100 1440 160]);

    add_block( ...
        'simulink/Ports & Subsystems/Out1', ...
        [sub '/Omega_est'], ...
        'Port','1', ...
        'Position',[1510 118 1540 142]);

    add_line(sub,'V_ADC/1','Digital Mixer/1','autorouting','on');

    add_line(sub,'Reference/1','Analog Phase Match/1','autorouting','on');
    add_line(sub,'Analog Phase Match/1','Reference Sampler/1','autorouting','on');
    add_line(sub,'Reference Sampler/1','Digital Mixer/2','autorouting','on');

    add_line(sub,'Digital Mixer/1','Digital LPF SOS1/1','autorouting','on');
    add_line(sub,'Digital LPF SOS1/1','Digital LPF SOS2/1','autorouting','on');
    add_line(sub,'Digital LPF SOS2/1','Normalize/1','autorouting','on');
    add_line(sub,'Normalize/1','Limit asin/1','autorouting','on');
    add_line(sub,'Limit asin/1','asin/1','autorouting','on');
    add_line(sub,'asin/1','Phase to deg-s/1','autorouting','on');
    add_line(sub,'Phase to deg-s/1','Omega_est/1','autorouting','on');
end
