%% ============================================================
% FOG_statistics_v4_1.m
% Interferometryczny zyroskop swiatlowodowy - model v4.1
% MATLAB / Simulink R2023b
%
% CEL:
% - rozszerzyc Monte Carlo modelu v4,
% - wyznaczyc sigma_Omega(Tavg),
% - sprawdzic skalowanie szumu z czasem usredniania,
% - wyznaczyc stabilniejszy prog 1-sigma / 3-sigma,
% - sprawdzic wykrywanie 0.0001 deg/s,
% - oddzielic losowy szum od malego biasu numerycznego.
%
% v4.1 NIE zmienia fizyki Photoreceivera.
% Jest warstwa statystyczna nad zweryfikowanym FOG_v4.slx.
%% ============================================================

clc
close all
bdclose('all')

disp("==============================================")
disp(" FOG v4.1 - ROZSZERZONE MONTE CARLO")
disp("==============================================")

%% ============================================================
% MODEL
%% ============================================================

sourceModel = 'FOG_v4';
mdl = 'FOG_v4_1';

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
% PARAMETRY FIZYCZNE FOG - IDENTYCZNE JAK v4
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
% OPTYKA - IDENTYCZNA JAK v4
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
% PHOTORECEIVER - IDENTYCZNY JAK v4
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
% POLITYKA NUMERYCZNA
%% ============================================================

% Monte Carlo: tryb FAST zatwierdzony przez v3.1 dla 20 kHz.
Ts_solver = 0.20e-6;
Ts_noise = Ts_solver;

noise_sample_scale = ...
    1/sqrt(2*Ts_noise);

%% ============================================================
% SZUMY STALE
%% ============================================================

i_dark_shot_ASD = ...
    sqrt(2*q_e*I_dark_A);

i_johnson_ASD = ...
    sqrt(4*k_B*T_receiver_K/Rf);

i_opamp_current_ASD = ...
    opamp_in_A_sqrtHz;

i_opamp_voltage_eq_ASD = ...
    opamp_en_eq_A_sqrtHz;

sigma_dark_sample_A = ...
    i_dark_shot_ASD*noise_sample_scale;

sigma_johnson_sample_A = ...
    i_johnson_ASD*noise_sample_scale;

sigma_opamp_current_sample_A = ...
    i_opamp_current_ASD*noise_sample_scale;

sigma_opamp_voltage_sample_A = ...
    i_opamp_voltage_eq_ASD*noise_sample_scale;

%% ============================================================
% LOCK-IN / TIA
%% ============================================================

fc_lp = 300;
lp_order = 4;

[b_lp,a_lp] = ...
    butter(lp_order,2*pi*fc_lp,'s');

J1beta = besselj(1,beta_eff);
K_ref = 1/beta_eff;

Hmag_tia_fmod = ...
    1/sqrt(1+(f_mod/f_tia_Hz)^2);

tia_phase_lag_rad = ...
    atan(f_mod/f_tia_Hz);

ref_delay_tia_s = ...
    tia_phase_lag_rad/(2*pi*f_mod);

K_norm = ...
    -1/( ...
    Pdet_scale_W * ...
    visibility * ...
    Rpd * ...
    Rf * ...
    Hmag_tia_fmod * ...
    J1beta);

K_phase_to_deg = ...
    (180/pi)/K_sag;

%% ============================================================
% ZMIENNE SZUMOWE
%% ============================================================

noise_enable = 1;

seed_photo = 31001;
seed_dark = 31002;
seed_johnson = 31003;
seed_opamp_i = 31004;
seed_opamp_en = 31005;

%% ============================================================
% PLAN MONTE CARLO
%% ============================================================

% Domyslnie 100 realizacji. Po pierwszym poprawnym przebiegu
% mozna zmienic na 200 bez zmiany pozostalej czesci skryptu.
Nmc = 100;

% Czasy usredniania badane w tej samej realizacji.
Tavg_s = [ ...
    1e-3 ...
    2e-3 ...
    5e-3 ...
    10e-3 ...
    20e-3 ...
    ];

Tavg_ms = Tavg_s*1e3;
Navg = numel(Tavg_s);

% Pozwalamy lock-in ustalic sie przed oknami statystycznymi.
Tsettle = 20e-3;

% Jedna symulacja wystarcza dla wszystkich Tavg:
Tstop_mc = ...
    Tsettle + max(Tavg_s);

Omega_deg_s = 0;

set_param( ...
    mdl, ...
    'SolverType','Fixed-step', ...
    'Solver','ode4', ...
    'FixedStep',sprintf('%.17g',Ts_solver), ...
    'StopTime',sprintf('%.17g',Tstop_mc), ...
    'ReturnWorkspaceOutputs','on');

%% ============================================================
% TEST TOPOLOGII
%% ============================================================

photoSub = [mdl '/Photoreceiver'];
lh_photo = get_param(photoSub,'LineHandles');

if lh_photo.Inport(1) == -1
    error("FOG v4.1 topology error: Photoreceiver input is disconnected.")
end

if lh_photo.Outport(1) == -1
    error("FOG v4.1 topology error: Photoreceiver V_TIA output is disconnected.")
end

disp("Photoreceiver topology check: OK")

%% ============================================================
% MONTE CARLO ZERO-RATE
%% ============================================================

disp("")
disp("==============================================")
disp(" v4.1A - ZERO-RATE MONTE CARLO")
disp("==============================================")

fprintf("Nmc              = %d\n",Nmc)
fprintf("Tstop/run        = %.1f ms\n",Tstop_mc*1e3)
fprintf("Tavg             = ")
fprintf("%.1f ",Tavg_ms)
fprintf("ms\n")

zeroEst = zeros(Nmc,Navg);
runtime_s = zeros(Nmc,1);

for irun = 1:Nmc

    baseSeed = ...
        400000 + 10*irun;

    seed_photo = baseSeed+1;
    seed_dark = baseSeed+2;
    seed_johnson = baseSeed+3;
    seed_opamp_i = baseSeed+4;
    seed_opamp_en = baseSeed+5;

    tRun = tic;
    out = sim(mdl);
    runtime_s(irun) = toc(tRun);

    omega_ts = ...
        out.get('omega_est_ts');

    for ia = 1:Navg

        tStart = ...
            Tstop_mc-Tavg_s(ia);

        idx = ...
            omega_ts.Time >= tStart;

        zeroEst(irun,ia) = ...
            mean(omega_ts.Data(idx));
    end

    if mod(irun,10) == 0 || irun == 1
        fprintf( ...
            "run %3d/%3d, elapsed %.1f s\n", ...
            irun,Nmc,sum(runtime_s(1:irun)))
    end
end

%% ============================================================
% STATYSTYKA ZERO-RATE
%% ============================================================

zeroMean = mean(zeroEst,1)';
zeroSigma = std(zeroEst,0,1)';
zeroRMSE = sqrt(mean(zeroEst.^2,1))';

threshold1 = zeroSigma;
threshold3 = 3*zeroSigma;

sigma_deg_h = zeroSigma*3600;
threshold3_deg_h = threshold3*3600;

sigmaTimesSqrtT = ...
    zeroSigma.*sqrt(Tavg_s(:));

% Dopasowanie:
% log10(sigma) = slope*log10(Tavg) + intercept
p = polyfit( ...
    log10(Tavg_s(:)), ...
    log10(zeroSigma), ...
    1);

whiteNoiseSlope = p(1);

zeroSummary = table( ...
    Tavg_ms(:), ...
    zeroMean, ...
    zeroSigma, ...
    sigma_deg_h, ...
    threshold1, ...
    threshold3, ...
    threshold3_deg_h, ...
    sigmaTimesSqrtT, ...
    'VariableNames', ...
    { ...
    'Tavg_ms', ...
    'Zero_rate_mean_deg_s', ...
    'Zero_rate_sigma_deg_s', ...
    'Zero_rate_sigma_deg_h', ...
    'Threshold_1sigma_deg_s', ...
    'Threshold_3sigma_deg_s', ...
    'Threshold_3sigma_deg_h', ...
    'Sigma_times_sqrt_T' ...
    });

disp("")
disp(zeroSummary)

fprintf("\nlog-log slope sigma(Tavg) = %.4f\n",whiteNoiseSlope)
fprintf("Ideal white-noise slope   = -0.5000\n")
fprintf("Mean runtime/run          = %.3f s\n",mean(runtime_s))

writetable( ...
    zeroSummary, ...
    'FOG_v4_1_zero_rate_vs_Tavg.csv');

%% ============================================================
% RAW ZERO-RATE
%% ============================================================

rawRun = repelem((1:Nmc)',Navg);
rawTavg = repmat(Tavg_ms(:),Nmc,1);
rawEstimate = reshape(zeroEst.',[],1);

zeroRaw = table( ...
    rawRun, ...
    rawTavg, ...
    rawEstimate, ...
    'VariableNames', ...
    { ...
    'Run', ...
    'Tavg_ms', ...
    'Omega_est_deg_s' ...
    });

writetable( ...
    zeroRaw, ...
    'FOG_v4_1_zero_rate_raw.csv');

%% ============================================================
% v4.1B - POWTORZENIE PUNKTU 0.0001 deg/s
%% ============================================================

disp("")
disp("==============================================")
disp(" v4.1B - DETECTION CHECK @ 0.0001 deg/s")
disp("==============================================")

Omega_test_deg_s = 1e-4;
Ndetect = 50;
Tavg_detect = 10e-3;

Omega_deg_s = Omega_test_deg_s;

detEst = zeros(Ndetect,1);

for irun = 1:Ndetect

    baseSeed = ...
        600000 + 10*irun;

    seed_photo = baseSeed+1;
    seed_dark = baseSeed+2;
    seed_johnson = baseSeed+3;
    seed_opamp_i = baseSeed+4;
    seed_opamp_en = baseSeed+5;

    out = sim(mdl);

    omega_ts = ...
        out.get('omega_est_ts');

    idx = ...
        omega_ts.Time >= ...
        (Tstop_mc-Tavg_detect);

    detEst(irun) = ...
        mean(omega_ts.Data(idx));

    if mod(irun,10) == 0 || irun == 1
        fprintf("run %3d/%3d\n",irun,Ndetect)
    end
end

detMean = mean(detEst);
detSigma = std(detEst);
detBias = detMean-Omega_test_deg_s;
detRMSE = sqrt(mean((detEst-Omega_test_deg_s).^2));

detSNR = ...
    abs(Omega_test_deg_s)/detSigma;

% Separacja srednich klasy zero i klasy 0.0001 deg/s
[~,idx10ms] = ...
    min(abs(Tavg_s-Tavg_detect));

zeroSigma10 = ...
    zeroSigma(idx10ms);

pooledSigma = ...
    sqrt((zeroSigma10^2 + detSigma^2)/2);

classSeparationSigma = ...
    abs(detMean-zeroMean(idx10ms))/pooledSigma;

detectSummary = table( ...
    Omega_test_deg_s, ...
    Tavg_detect*1e3, ...
    Ndetect, ...
    detMean, ...
    detSigma, ...
    detBias, ...
    detRMSE, ...
    detSNR, ...
    classSeparationSigma, ...
    'VariableNames', ...
    { ...
    'Omega_test_deg_s', ...
    'Tavg_ms', ...
    'N_runs', ...
    'Mean_deg_s', ...
    'STD_deg_s', ...
    'Bias_deg_s', ...
    'RMSE_deg_s', ...
    'SNR_rate_over_STD', ...
    'Zero_vs_signal_separation_sigma' ...
    });

disp(detectSummary)

writetable( ...
    detectSummary, ...
    'FOG_v4_1_detection_check.csv');

detectRaw = table( ...
    (1:Ndetect)', ...
    repmat(Omega_test_deg_s,Ndetect,1), ...
    detEst, ...
    detEst-Omega_test_deg_s, ...
    'VariableNames', ...
    { ...
    'Run', ...
    'Omega_zadane_deg_s', ...
    'Omega_zmierzone_deg_s', ...
    'Blad_deg_s' ...
    });

writetable( ...
    detectRaw, ...
    'FOG_v4_1_detection_raw.csv');

%% ============================================================
% v4.1C - SPRAWDZENIE BIASU NUMERYCZNEGO 1 deg/s
%% ============================================================

disp("")
disp("==============================================")
disp(" v4.1C - NUMERICAL BASELINE CHECK")
disp("==============================================")

noise_enable = 0;
Omega_deg_s = 1;

TsCheck = [0.20e-6 0.05e-6];
Ncheck = numel(TsCheck);

checkOmega = zeros(Ncheck,1);
checkError = zeros(Ncheck,1);
checkStd = zeros(Ncheck,1);
checkRuntime = zeros(Ncheck,1);

Tstop_check = 0.050;
Tmean_check = 0.040;

for k = 1:Ncheck

    Ts_solver = TsCheck(k);

    set_param( ...
        mdl, ...
        'FixedStep',sprintf('%.17g',Ts_solver), ...
        'StopTime',sprintf('%.17g',Tstop_check));

    tRun = tic;
    out = sim(mdl);
    checkRuntime(k) = toc(tRun);

    omega_ts = ...
        out.get('omega_est_ts');

    idx = ...
        omega_ts.Time >= Tmean_check;

    checkOmega(k) = ...
        mean(omega_ts.Data(idx));

    checkError(k) = ...
        checkOmega(k)-Omega_deg_s;

    checkStd(k) = ...
        std(omega_ts.Data(idx));
end

baselineCheck = table( ...
    TsCheck(:)*1e6, ...
    checkOmega, ...
    checkError, ...
    checkStd, ...
    checkRuntime, ...
    'VariableNames', ...
    { ...
    'Ts_us', ...
    'Omega_measured_deg_s', ...
    'Omega_error_deg_s', ...
    'STD_deg_s', ...
    'Runtime_s' ...
    });

disp(baselineCheck)

writetable( ...
    baselineCheck, ...
    'FOG_v4_1_numerical_baseline.csv');

%% ============================================================
% WYKRES 1 - SIGMA VS TAVG
%% ============================================================

figure('Name','FOG v4.1 - sigma vs Tavg')

loglog( ...
    Tavg_ms, ...
    zeroSigma, ...
    'o-', ...
    'LineWidth',1.5)

hold on

% Referencja 1/sqrt(T), zakotwiczona w pierwszym punkcie.
whiteRef = ...
    zeroSigma(1)*sqrt(Tavg_s(1)./Tavg_s);

loglog( ...
    Tavg_ms, ...
    whiteRef, ...
    '--', ...
    'LineWidth',1.2)

grid on
xlabel('Czas usredniania T_{avg} [ms]')
ylabel('\sigma_\Omega [deg/s]')
legend('Monte Carlo','1/sqrt(T) reference','Location','best')
title('FOG v4.1 - redukcja szumu przez usrednianie')

%% ============================================================
% WYKRES 2 - 3 SIGMA
%% ============================================================

figure('Name','FOG v4.1 - detection threshold')

loglog( ...
    Tavg_ms, ...
    threshold3_deg_h, ...
    'o-', ...
    'LineWidth',1.5)

grid on
xlabel('Czas usredniania T_{avg} [ms]')
ylabel('3\sigma [deg/h]')
title('FOG v4.1 - roboczy prog 3-sigma')

%% ============================================================
% WYKRES 3 - HISTOGRAM 10 ms
%% ============================================================

figure('Name','FOG v4.1 - zero-rate histogram')

histogram( ...
    zeroEst(:,idx10ms), ...
    20)

grid on
xlabel('Omega est [deg/s]')
ylabel('Liczba realizacji')
title('FOG v4.1 - zero-rate, Tavg = 10 ms')

%% ============================================================
% WYKRES 4 - ZERO VS 0.0001 deg/s
%% ============================================================

figure('Name','FOG v4.1 - detection comparison')

histogram( ...
    zeroEst(:,idx10ms), ...
    20, ...
    'Normalization','pdf')

hold on

histogram( ...
    detEst, ...
    20, ...
    'Normalization','pdf')

grid on
xlabel('Omega est [deg/s]')
ylabel('PDF')
legend('0 deg/s','0.0001 deg/s','Location','best')
title('FOG v4.1 - separacja sygnalu od zera')

%% ============================================================
% KONIEC
%% ============================================================

% Przywroc FAST + noise on jako stan roboczy modelu.
Ts_solver = 0.20e-6;
noise_enable = 1;
Omega_deg_s = 0;

set_param( ...
    mdl, ...
    'FixedStep',sprintf('%.17g',Ts_solver), ...
    'StopTime',sprintf('%.17g',Tstop_mc));

save_system(mdl)
open_system(mdl)

disp("")
disp("==============================================")
disp(" FOG v4.1 - ANALIZA ZAKONCZONA")
disp("==============================================")
disp("")
disp("Utworzono:")
disp("  FOG_v4_1.slx")
disp("  FOG_v4_1_zero_rate_vs_Tavg.csv")
disp("  FOG_v4_1_zero_rate_raw.csv")
disp("  FOG_v4_1_detection_check.csv")
disp("  FOG_v4_1_detection_raw.csv")
disp("  FOG_v4_1_numerical_baseline.csv")
disp("")
disp("Najwazniejsze do oceny:")
disp("  1) slope sigma(Tavg), oczekiwanie ~ -0.5 dla bialego szumu")
disp("  2) prog 3-sigma vs Tavg")
disp("  3) separacja 0 od 0.0001 deg/s")
disp("  4) bias 1 deg/s FAST vs STANDARD")
disp("")
