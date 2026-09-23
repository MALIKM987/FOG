%% ============================================================
% FOG_optimize_v5_1.m
% Interferometryczny zyroskop swiatlowodowy - model v5.1
% MATLAB / Simulink R2023b
%
% CEL:
% - zoptymalizowac tor ADC z v5,
% - sprawdzic detekcje 0.0001 deg/s dla 12/14/16 bit z pelnym szumem,
% - zbadac koherentna kwantyzacje przez sweep fazy zegara ADC,
% - porownac 500 kS/s, 1 MS/s i 2 MS/s pod szumem,
% - porownac AAF 80/100/150 kHz pod szumem,
% - oddzielic fizyczny szum od okresowego biasu cyfrowego.
%
% v5.1 nie zmienia optyki ani Photoreceivera.
% Jest warstwa optymalizacyjna nad zweryfikowanym FOG_v5.slx.
%% ============================================================

clc
close all
bdclose('all')

disp("==============================================")
disp(" FOG v5.1 - OPTYMALIZACJA ADC / DSP")
disp("==============================================")

%% ============================================================
% MODEL
%% ============================================================

sourceModel = 'FOG_v5';
mdl = 'FOG_v5_1';

if ~isfile([sourceModel '.slx'])

    if isfile('FOG_start_v5.m')
        disp("FOG_v5.slx nie istnieje. Uruchamiam FOG_start_v5.m...")
        run('FOG_start_v5.m')
        bdclose('all')
    else
        error([ ...
            "Brak FOG_v5.slx oraz FOG_start_v5.m w aktualnym folderze. " ...
            "Najpierw pobierz i zweryfikuj v5." ...
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
% PARAMETRY FIZYCZNE - JAK v5
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
% OPTYKA - JAK v5
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
% PHOTORECEIVER - JAK v5
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
% CYFROWY TOR - ZMIENNE KONFIGURACYJNE
%% ============================================================

Vadc_min = 0.0;
Vadc_max = 2.0;
Vadc_fs = Vadc_max-Vadc_min;

adc_bits = 16;
fs_adc = 1e6;
adc_sample_offset_s = 0;

aa_order = 4;
f_aa_Hz = 150e3;

fc_digital_lp = 300;
digital_lp_order = 4;

J1beta = besselj(1,beta_eff);
K_ref = 1/beta_eff;
K_phase_to_deg = (180/pi)/K_sag;

% Zmienne zostana wypelnione przez updateConfiguration().
Ts_adc = 1/fs_adc;
q_adc = Vadc_fs/(2^adc_bits-1);

b_aa = 1;
a_aa = 1;

sos_d = [1 0 0 1 0 0; 1 0 0 1 0 0];

Hmag_aa_fmod = 1;
Hmag_tia_fmod = 1;
Hmag_analog_fmod = 1;

analog_phase_lag_rad = 0;
ref_delay_total_s = 0;

K_norm_digital = 1;
Vanalog_ASD_fmod = 1;

%% ============================================================
% POLITYKA NUMERYCZNA / SZUMY
%% ============================================================

Ts_solver = 0.20e-6;
Ts_noise = Ts_solver;

noise_enable = 1;

seed_photo = 91001;
seed_dark = 91002;
seed_johnson = 91003;
seed_opamp_i = 91004;
seed_opamp_en = 91005;

noise_sample_scale = 1;
sigma_dark_sample_A = 0;
sigma_johnson_sample_A = 0;
sigma_opamp_current_sample_A = 0;
sigma_opamp_voltage_sample_A = 0;

updateNoiseSampling();
updateConfiguration();

%% ============================================================
% SAMPLE-OFFSET DLA ADC I REFERENCJI
%% ============================================================

adcSampleBlock = ...
    [mdl '/ADC AFE/Sample and Hold'];

refSampleBlock = ...
    [mdl '/Digital Lock-In DSP/Reference Sampler'];

set_param( ...
    adcSampleBlock, ...
    'SampleTime','[Ts_adc adc_sample_offset_s]');

set_param( ...
    refSampleBlock, ...
    'SampleTime','[Ts_adc adc_sample_offset_s]');

%% ============================================================
% TEST TOPOLOGII
%% ============================================================

adcSub = [mdl '/ADC AFE'];
dspSub = [mdl '/Digital Lock-In DSP'];

lhADC = get_param(adcSub,'LineHandles');
lhDSP = get_param(dspSub,'LineHandles');

if lhADC.Inport(1) == -1 || lhADC.Outport(1) == -1
    error("FOG v5.1 topology error: ADC AFE is disconnected.")
end

if any(lhDSP.Inport == -1) || lhDSP.Outport(1) == -1
    error("FOG v5.1 topology error: Digital Lock-In DSP is disconnected.")
end

disp("ADC/DSP topology check: OK")

%% ============================================================
% PARAMETRY WSPOLNE TESTOW
%% ============================================================

sigmaAnalogReference10ms = ...
    1.99991284499952e-5;

Tstop_mc = 0.040;
Tavg_mc = 0.010;
Tmean_mc = Tstop_mc-Tavg_mc;

set_param( ...
    mdl, ...
    'SolverType','Fixed-step', ...
    'Solver','ode4', ...
    'FixedStep',sprintf('%.17g',Ts_solver), ...
    'StopTime',sprintf('%.17g',Tstop_mc), ...
    'ReturnWorkspaceOutputs','on');

%% ============================================================
% v5.1A - DETEKCJA 0.0001 deg/s VS LICZBA BITOW
%% ============================================================

disp("")
disp("==============================================")
disp(" v5.1A - DETECTION VS ADC BITS")
disp("==============================================")

detectionFile = 'FOG_v5_1_detection_vs_bits.csv';

% Resume:
% Jesli poprawny wynik v5.1A juz istnieje, nie powtarzamy 180
% kosztownych symulacji po hotfixie kolejnych etapow.
if isfile(detectionFile)

    disp("Znaleziono istniejacy FOG_v5_1_detection_vs_bits.csv")
    disp("Pomijam ponowne v5.1A i wczytuje zapisane wyniki.")

    detectResults = readtable(detectionFile);

    bitsDetect = detectResults.ADC_bits;
    Nb = numel(bitsDetect);

    zeroMean = detectResults.Zero_mean_deg_s;
    zeroSigma = detectResults.Zero_sigma_deg_s;

    signalMean = detectResults.Signal_mean_deg_s;
    signalSigma = detectResults.Signal_sigma_deg_s;

    signalBias = detectResults.Signal_bias_deg_s;
    signalRMSE = detectResults.Signal_RMSE_deg_s;

    rateSNR = detectResults.Rate_SNR;
    classSeparation = ...
        detectResults.Zero_signal_separation_sigma;

    threshold3_deg_h = ...
        detectResults.Zero_3sigma_deg_h;

    Omega_signal = 1e-4;

    disp(detectResults)

else

    bitsDetect = [12 14 16]';
    Nb = numel(bitsDetect);

    Nclass = 30;
    Omega_signal = 1e-4;

    zeroMean = zeros(Nb,1);
    zeroSigma = zeros(Nb,1);

    signalMean = zeros(Nb,1);
    signalSigma = zeros(Nb,1);

    signalBias = zeros(Nb,1);
    signalRMSE = zeros(Nb,1);

    rateSNR = zeros(Nb,1);
    classSeparation = zeros(Nb,1);
    threshold3_deg_h = zeros(Nb,1);

    for kb = 1:Nb

        adc_bits = bitsDetect(kb);
        fs_adc = 1e6;
        f_aa_Hz = 150e3;
        adc_sample_offset_s = 0;

        updateConfiguration();

        vals0 = zeros(Nclass,1);
        vals1 = zeros(Nclass,1);

        fprintf("\nADC %d bit, ZERO: ",adc_bits)

        Omega_deg_s = 0;
        noise_enable = 1;

        for irun = 1:Nclass

            setSeeds( ...
                1000000 + 10000*kb + 10*irun);

            out = sim(mdl);
            omega_ts = out.get('omega_est_ts');

            idx = omega_ts.Time >= Tmean_mc;
            vals0(irun) = mean(omega_ts.Data(idx));

            fprintf(".")
        end

        fprintf(" done\nADC %d bit, SIGNAL: ",adc_bits)

        Omega_deg_s = Omega_signal;

        for irun = 1:Nclass

            setSeeds( ...
                1100000 + 10000*kb + 10*irun);

            out = sim(mdl);
            omega_ts = out.get('omega_est_ts');

            idx = omega_ts.Time >= Tmean_mc;
            vals1(irun) = mean(omega_ts.Data(idx));

            fprintf(".")
        end

        fprintf(" done")

        zeroMean(kb) = mean(vals0);
        zeroSigma(kb) = std(vals0);

        signalMean(kb) = mean(vals1);
        signalSigma(kb) = std(vals1);

        signalBias(kb) = ...
            signalMean(kb)-Omega_signal;

        signalRMSE(kb) = ...
            sqrt(mean((vals1-Omega_signal).^2));

        rateSNR(kb) = ...
            abs(Omega_signal)/signalSigma(kb);

        pooled = ...
            sqrt((zeroSigma(kb)^2+signalSigma(kb)^2)/2);

        classSeparation(kb) = ...
            abs(signalMean(kb)-zeroMean(kb))/pooled;

        threshold3_deg_h(kb) = ...
            3*zeroSigma(kb)*3600;
    end

    detectResults = table( ...
        bitsDetect, ...
        repmat(fs_adc/1e6,Nb,1), ...
        zeroMean, ...
        zeroSigma, ...
        zeroSigma*3600, ...
        threshold3_deg_h, ...
        signalMean, ...
        signalSigma, ...
        signalBias, ...
        signalRMSE, ...
        rateSNR, ...
        classSeparation, ...
        'VariableNames', ...
        { ...
        'ADC_bits', ...
        'fs_MSps', ...
        'Zero_mean_deg_s', ...
        'Zero_sigma_deg_s', ...
        'Zero_sigma_deg_h', ...
        'Zero_3sigma_deg_h', ...
        'Signal_mean_deg_s', ...
        'Signal_sigma_deg_s', ...
        'Signal_bias_deg_s', ...
        'Signal_RMSE_deg_s', ...
        'Rate_SNR', ...
        'Zero_signal_separation_sigma' ...
        });

    disp("")
    disp(detectResults)

    writetable( ...
        detectResults, ...
        detectionFile);
end

%% ============================================================
% v5.1B - SWEEP FAZY ZEGARA ADC
%% ============================================================

disp("")
disp("==============================================")
disp(" v5.1B - ADC CLOCK PHASE SWEEP")
disp("==============================================")

clockSweepFile = 'FOG_v5_1_clock_phase_sweep.csv';
clockSummaryFile = 'FOG_v5_1_clock_phase_summary.csv';

% Resume:
% jesli oba pliki z poprawnie zakonczonego v5.1B juz istnieja,
% nie powtarzamy kosztownego sweepu po hotfixie v5.1C.
if isfile(clockSweepFile) && isfile(clockSummaryFile)

    disp("Znaleziono istniejace wyniki v5.1B.")
    disp("Pomijam clock-phase sweep i wczytuje CSV.")

    clockPhaseResults = readtable(clockSweepFile);
    clockPhaseSummary = readtable(clockSummaryFile);

    phase_fs_kSps = clockPhaseResults.fs_kSps;
    phase_fraction = clockPhaseResults.Clock_phase_fraction_of_Ts;
    phase_offset_ns = clockPhaseResults.Clock_offset_ns;

    phase_est_1 = clockPhaseResults.Omega_est_at_1deg_s;
    phase_err_1 = clockPhaseResults.Error_at_1deg_s;

    phase_est_small = clockPhaseResults.Omega_est_at_1e_4deg_s;
    phase_err_small = clockPhaseResults.Error_at_1e_4deg_s;

    phaseSummary_fs = clockPhaseSummary.fs_kSps;
    phaseP2P_1 = clockPhaseSummary.P2P_error_at_1deg_s;
    phaseMaxAbs_1 = clockPhaseSummary.Max_abs_error_at_1deg_s;
    phaseP2P_small = clockPhaseSummary.P2P_error_at_1e_4deg_s;
    phaseMaxAbs_small = clockPhaseSummary.Max_abs_error_at_1e_4deg_s;

    fsPhase = unique(phase_fs_kSps)'*1e3;
    NfsP = numel(fsPhase);

    disp("CLOCK PHASE SUMMARY")
    disp(clockPhaseSummary)

else

    noise_enable = 0;
    adc_bits = 16;
    f_aa_Hz = 150e3;

    fsPhase = [500e3 1e6 2e6];

    % Przy Ts_solver = 0.05 us wszystkie sample-time offsets musza byc
    % calkowita wielokrotnoscia 50 ns. Dla fs = 500k/1M/2M S/s
    % siatka 0:0.1:0.9 daje odpowiednio kroki offsetu
    % 200 ns / 100 ns / 50 ns, czyli zawsze zgodne z fixed-step.
    phaseFrac = (0:0.1:0.9)';

    NfsP = numel(fsPhase);
    Np = numel(phaseFrac);
    Nrows = NfsP*Np;

    phase_fs_kSps = zeros(Nrows,1);
    phase_fraction = zeros(Nrows,1);
    phase_offset_ns = zeros(Nrows,1);

    phase_est_1 = zeros(Nrows,1);
    phase_err_1 = zeros(Nrows,1);

    phase_est_small = zeros(Nrows,1);
    phase_err_small = zeros(Nrows,1);

    % STANDARD do analizy biasu.
    Ts_solver = 0.05e-6;
    updateNoiseSampling();

    Tstop_phase = 0.030;
    Tmean_phase = 0.020;

    set_param( ...
        mdl, ...
        'FixedStep',sprintf('%.17g',Ts_solver), ...
        'StopTime',sprintf('%.17g',Tstop_phase));

    row = 0;

    for kf = 1:NfsP

        fs_adc = fsPhase(kf);

        for kp = 1:Np

            row = row+1;

            adc_sample_offset_s = ...
                phaseFrac(kp)/fs_adc;

            offsetInSolverSteps = ...
                adc_sample_offset_s/Ts_solver;

            if abs(offsetInSolverSteps-round(offsetInSolverSteps)) > 1e-9
                error([ ...
                    "FOG v5.1 internal timing error: ADC sample offset " ...
                    "is not aligned to fixed solver step." ...
                    ])
            end

            updateConfiguration();

            Omega_deg_s = 1;
            out = sim(mdl);
            omega_ts = out.get('omega_est_ts');
            idx = omega_ts.Time >= Tmean_phase;

            est1 = mean(omega_ts.Data(idx));

            Omega_deg_s = 1e-4;
            out = sim(mdl);
            omega_ts = out.get('omega_est_ts');
            idx = omega_ts.Time >= Tmean_phase;

            estSmall = mean(omega_ts.Data(idx));

            phase_fs_kSps(row) = fs_adc/1e3;
            phase_fraction(row) = phaseFrac(kp);
            phase_offset_ns(row) = adc_sample_offset_s*1e9;

            phase_est_1(row) = est1;
            phase_err_1(row) = est1-1;

            phase_est_small(row) = estSmall;
            phase_err_small(row) = estSmall-1e-4;
        end
    end

    clockPhaseResults = table( ...
        phase_fs_kSps, ...
        phase_fraction, ...
        phase_offset_ns, ...
        phase_est_1, ...
        phase_err_1, ...
        phase_est_small, ...
        phase_err_small, ...
        'VariableNames', ...
        { ...
        'fs_kSps', ...
        'Clock_phase_fraction_of_Ts', ...
        'Clock_offset_ns', ...
        'Omega_est_at_1deg_s', ...
        'Error_at_1deg_s', ...
        'Omega_est_at_1e_4deg_s', ...
        'Error_at_1e_4deg_s' ...
        });

    writetable( ...
        clockPhaseResults, ...
        clockSweepFile);

    % Podsumowanie peak-to-peak biasu vs faza.
    phaseSummary_fs = fsPhase(:)/1e3;
    phaseP2P_1 = zeros(NfsP,1);
    phaseP2P_small = zeros(NfsP,1);
    phaseMaxAbs_1 = zeros(NfsP,1);
    phaseMaxAbs_small = zeros(NfsP,1);

    for kf = 1:NfsP

        idx = phase_fs_kSps == fsPhase(kf)/1e3;

        phaseP2P_1(kf) = ...
            max(phase_err_1(idx))-min(phase_err_1(idx));

        phaseP2P_small(kf) = ...
            max(phase_err_small(idx))-min(phase_err_small(idx));

        phaseMaxAbs_1(kf) = ...
            max(abs(phase_err_1(idx)));

        phaseMaxAbs_small(kf) = ...
            max(abs(phase_err_small(idx)));
    end

    clockPhaseSummary = table( ...
        phaseSummary_fs, ...
        phaseP2P_1, ...
        phaseMaxAbs_1, ...
        phaseP2P_small, ...
        phaseMaxAbs_small, ...
        'VariableNames', ...
        { ...
        'fs_kSps', ...
        'P2P_error_at_1deg_s', ...
        'Max_abs_error_at_1deg_s', ...
        'P2P_error_at_1e_4deg_s', ...
        'Max_abs_error_at_1e_4deg_s' ...
        });

    disp("")
    disp("CLOCK PHASE SUMMARY")
    disp(clockPhaseSummary)

    writetable( ...
        clockPhaseSummary, ...
        clockSummaryFile);
end

%% ============================================================
% v5.1C - fs ADC POD SZUMEM
%% ============================================================

disp("")
disp("==============================================")
disp(" v5.1C - fs ADC MONTE CARLO")
disp("==============================================")

fsNoise = [500e3 1e6 2e6]';
NfsN = numel(fsNoise);
Nmc_fs = 20;

adc_bits = 16;
f_aa_Hz = 150e3;
adc_sample_offset_s = 0;

% 0.20 us nie dzieli okresu 0.5 us dla 2 MS/s.
% Uzywamy 0.10 us: 500k -> 20 krokow/probke,
% 1M -> 10 krokow/probke, 2M -> 5 krokow/probke.
Ts_solver = 0.10e-6;
updateNoiseSampling();

set_param( ...
    mdl, ...
    'FixedStep',sprintf('%.17g',Ts_solver), ...
    'StopTime',sprintf('%.17g',Tstop_mc));

noise_enable = 1;
Omega_deg_s = 0;

fsSigma = zeros(NfsN,1);
fsBias = zeros(NfsN,1);
fsSigmaDegH = zeros(NfsN,1);
fsFactorAnalog = zeros(NfsN,1);
fsNyqAtten = zeros(NfsN,1);

for kf = 1:NfsN

    fs_adc = fsNoise(kf);
    updateConfiguration();

    samplePeriodSteps = Ts_adc/Ts_solver;

    if abs(samplePeriodSteps-round(samplePeriodSteps)) > 1e-9
        error([ ...
            "FOG v5.1 timing error: Ts_adc is not an integer " ...
            "multiple of the fixed solver step." ...
            ])
    end

    vals = zeros(Nmc_fs,1);

    HaaNyq = ...
        polyval(b_aa,1j*2*pi*(fs_adc/2)) / ...
        polyval(a_aa,1j*2*pi*(fs_adc/2));

    HtiaNyq = ...
        1/(1+1j*(fs_adc/2)/f_tia_Hz);

    fsNyqAtten(kf) = ...
        20*log10(abs(HaaNyq*HtiaNyq));

    fprintf("\nfs %.0f kS/s: ",fs_adc/1e3)

    for irun = 1:Nmc_fs

        setSeeds( ...
            1200000 + 10000*kf + 10*irun);

        out = sim(mdl);
        omega_ts = out.get('omega_est_ts');

        idx = omega_ts.Time >= Tmean_mc;
        vals(irun) = mean(omega_ts.Data(idx));

        fprintf(".")
    end

    fprintf(" done")

    fsBias(kf) = mean(vals);
    fsSigma(kf) = std(vals);
    fsSigmaDegH(kf) = fsSigma(kf)*3600;
    fsFactorAnalog(kf) = ...
        fsSigma(kf)/sigmaAnalogReference10ms;
end

fsNoiseResults = table( ...
    fsNoise/1e3, ...
    fsNoise/f_mod, ...
    fsNyqAtten, ...
    fsBias, ...
    fsSigma, ...
    fsSigmaDegH, ...
    fsFactorAnalog, ...
    'VariableNames', ...
    { ...
    'fs_kSps', ...
    'Samples_per_carrier', ...
    'TIA_AAF_gain_at_Nyquist_dB', ...
    'Zero_bias_deg_s', ...
    'Zero_sigma_deg_s', ...
    'Zero_sigma_deg_h', ...
    'Sigma_factor_vs_analog_v4_1' ...
    });

disp("")
disp(fsNoiseResults)

writetable( ...
    fsNoiseResults, ...
    'FOG_v5_1_fs_monte_carlo.csv');

%% ============================================================
% v5.1D - AAF SWEEP POD SZUMEM
%% ============================================================

disp("")
disp("==============================================")
disp(" v5.1D - AAF MONTE CARLO")
disp("==============================================")

fAA = [80e3 100e3 150e3]';
Naa = numel(fAA);
Nmc_aa = 20;

adc_bits = 16;
fs_adc = 1e6;
adc_sample_offset_s = 0;

Ts_solver = 0.20e-6;
updateNoiseSampling();

noise_enable = 1;
Omega_deg_s = 0;

aaSigma = zeros(Naa,1);
aaBias = zeros(Naa,1);
aaSigmaDegH = zeros(Naa,1);
aaFactorAnalog = zeros(Naa,1);

aaHmod = zeros(Naa,1);
aaLagDeg = zeros(Naa,1);
aaNyqCombined = zeros(Naa,1);

for ka = 1:Naa

    f_aa_Hz = fAA(ka);
    updateConfiguration();

    vals = zeros(Nmc_aa,1);

    aaHmod(ka) = Hmag_aa_fmod;
    aaLagDeg(ka) = ...
        (analog_phase_lag_rad - atan(f_mod/f_tia_Hz))*180/pi;

    HaaNyq = ...
        polyval(b_aa,1j*2*pi*(fs_adc/2)) / ...
        polyval(a_aa,1j*2*pi*(fs_adc/2));

    HtiaNyq = ...
        1/(1+1j*(fs_adc/2)/f_tia_Hz);

    aaNyqCombined(ka) = ...
        20*log10(abs(HaaNyq*HtiaNyq));

    fprintf("\nAAF %.0f kHz: ",f_aa_Hz/1e3)

    for irun = 1:Nmc_aa

        setSeeds( ...
            1300000 + 10000*ka + 10*irun);

        out = sim(mdl);
        omega_ts = out.get('omega_est_ts');

        idx = omega_ts.Time >= Tmean_mc;
        vals(irun) = mean(omega_ts.Data(idx));

        fprintf(".")
    end

    fprintf(" done")

    aaBias(ka) = mean(vals);
    aaSigma(ka) = std(vals);
    aaSigmaDegH(ka) = aaSigma(ka)*3600;
    aaFactorAnalog(ka) = ...
        aaSigma(ka)/sigmaAnalogReference10ms;
end

aaResults = table( ...
    fAA/1e3, ...
    aaHmod, ...
    aaLagDeg, ...
    aaNyqCombined, ...
    aaBias, ...
    aaSigma, ...
    aaSigmaDegH, ...
    aaFactorAnalog, ...
    'VariableNames', ...
    { ...
    'AAF_fc_kHz', ...
    'AAF_gain_at_20kHz', ...
    'AAF_phase_lag_at_20kHz_deg', ...
    'TIA_AAF_gain_at_Nyquist_dB', ...
    'Zero_bias_deg_s', ...
    'Zero_sigma_deg_s', ...
    'Zero_sigma_deg_h', ...
    'Sigma_factor_vs_analog_v4_1' ...
    });

disp("")
disp(aaResults)

writetable( ...
    aaResults, ...
    'FOG_v5_1_aaf_monte_carlo.csv');

%% ============================================================
% WYKRESY
%% ============================================================

figure('Name','FOG v5.1 - detection vs bits')

plot( ...
    bitsDetect, ...
    classSeparation, ...
    'o-', ...
    'LineWidth',1.5)

hold on

yline(3,'--');

grid on
xlabel('ADC bits')
ylabel('Separacja zero / 0.0001 deg/s [sigma]')
title('FOG v5.1 - detekcja malej predkosci')

figure('Name','FOG v5.1 - clock phase')

for kf = 1:NfsP

    idx = phase_fs_kSps == fsPhase(kf)/1e3;

    plot( ...
        phase_fraction(idx), ...
        phase_err_1(idx), ...
        'o-', ...
        'LineWidth',1.5, ...
        'DisplayName',sprintf('%.0f kS/s',fsPhase(kf)/1e3));

    hold on
end

grid on
xlabel('Offset zegara / T_s')
ylabel('Blad Omega przy 1 deg/s [deg/s]')
legend('Location','best')
title('FOG v5.1 - koherentny bias vs faza zegara')

figure('Name','FOG v5.1 - fs under noise')

semilogx( ...
    fsNoise/1e3, ...
    fsSigmaDegH, ...
    'o-', ...
    'LineWidth',1.5)

grid on
xlabel('fs ADC [kS/s]')
ylabel('Zero-rate sigma [deg/h]')
title('FOG v5.1 - fs ADC pod szumem')

figure('Name','FOG v5.1 - AAF')

plot( ...
    fAA/1e3, ...
    aaSigmaDegH, ...
    'o-', ...
    'LineWidth',1.5)

grid on
xlabel('AAF fc [kHz]')
ylabel('Zero-rate sigma [deg/h]')
title('FOG v5.1 - dobor filtru antyaliasingowego')

%% ============================================================
% STAN KONCOWY = NOMINALNY
%% ============================================================

adc_bits = 16;
fs_adc = 1e6;
f_aa_Hz = 150e3;
adc_sample_offset_s = 0;

Ts_solver = 0.05e-6;
updateNoiseSampling();
updateConfiguration();

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
disp(" FOG v5.1 - OPTYMALIZACJA ZAKONCZONA")
disp("==============================================")
disp("")
disp("Utworzono:")
disp("  FOG_v5_1.slx")
disp("  FOG_v5_1_detection_vs_bits.csv")
disp("  FOG_v5_1_clock_phase_sweep.csv")
disp("  FOG_v5_1_clock_phase_summary.csv")
disp("  FOG_v5_1_fs_monte_carlo.csv")
disp("  FOG_v5_1_aaf_monte_carlo.csv")
disp("")
disp("Do interpretacji:")
disp("  1) czy 14 bit utrzymuje >3 sigma dla 0.0001 deg/s")
disp("  2) jak duzy jest P2P bias od fazy zegara")
disp("  3) czy 2 MS/s nadal ma problem pod szumem")
disp("  4) czy nizsze fc AAF poprawia aliasing bez utraty czulosci")
disp("")

%% ============================================================
% FUNKCJE NESTED
%% ============================================================

function updateConfiguration()

    fs_l = evalin('caller','fs_adc');
    bits_l = evalin('caller','adc_bits');
    Vfs_l = evalin('caller','Vadc_fs');
    faa_l = evalin('caller','f_aa_Hz');
    aaOrder_l = evalin('caller','aa_order');
    fmod_l = evalin('caller','f_mod');
    ftia_l = evalin('caller','f_tia_Hz');
    fcDig_l = evalin('caller','fc_digital_lp');
    digOrder_l = evalin('caller','digital_lp_order');

    Pscale_l = evalin('caller','Pdet_scale_W');
    vis_l = evalin('caller','visibility');
    Rpd_l = evalin('caller','Rpd');
    Rf_l = evalin('caller','Rf');
    J1_l = evalin('caller','J1beta');
    iTotal_l = evalin('caller','i_total_ASD');

    Ts_l = 1/fs_l;
    q_l = Vfs_l/(2^bits_l-1);

    [baa_l,aaa_l] = ...
        butter(aaOrder_l,2*pi*faa_l,'s');

    Haa_l = ...
        polyval(baa_l,1j*2*pi*fmod_l) / ...
        polyval(aaa_l,1j*2*pi*fmod_l);

    Htia_l = ...
        1/(1+1j*fmod_l/ftia_l);

    Hanalog_l = Haa_l*Htia_l;

    Hmag_l = abs(Hanalog_l);
    phaseLag_l = -angle(Hanalog_l);

    refDelay_l = ...
        phaseLag_l/(2*pi*fmod_l);

    Knorm_l = ...
        -1/( ...
        Pscale_l * vis_l * Rpd_l * Rf_l * Hmag_l * J1_l);

    [bd_l,ad_l] = ...
        butter(digOrder_l,fcDig_l/(fs_l/2));

    [sos_l,g_l] = ...
        tf2sos(bd_l,ad_l);

    sos_l(1,1:3) = ...
        g_l*sos_l(1,1:3);

    VanalogASD_l = ...
        iTotal_l*Rf_l*Hmag_l;

    assignin('caller','Ts_adc',Ts_l);
    assignin('caller','q_adc',q_l);

    assignin('caller','b_aa',baa_l);
    assignin('caller','a_aa',aaa_l);

    assignin('caller','Hmag_aa_fmod',abs(Haa_l));
    assignin('caller','Hmag_tia_fmod',abs(Htia_l));
    assignin('caller','Hmag_analog_fmod',Hmag_l);

    assignin('caller','analog_phase_lag_rad',phaseLag_l);
    assignin('caller','ref_delay_total_s',refDelay_l);

    assignin('caller','K_norm_digital',Knorm_l);

    assignin('caller','sos_d',sos_l);
    assignin('caller','Vanalog_ASD_fmod',VanalogASD_l);
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
