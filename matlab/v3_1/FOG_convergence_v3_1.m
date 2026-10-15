%% ============================================================
% FOG_convergence_v3_1.m
% Interferometryczny zyroskop swiatlowodowy - test v3.1
% MATLAB / Simulink R2023b
%
% CEL:
% Sprawdzic, czy pozostaly blad przy wysokich f_mod pochodzi
% z dyskretyzacji czasu / Transport Delay.
%
% Testowane kroki:
%   0.20 us, 0.10 us, 0.05 us, 0.02 us
%
% Testowane czestotliwosci:
%   20 kHz, 50 kHz, f_opt ~= 102.095 kHz, 150 kHz
%
% Model fizyczny NIE JEST zmieniany wzgledem v3.
% v3.1 jest testem jakosci numerycznej.
%% ============================================================

clc
close all
bdclose('all')

disp("==============================================")
disp(" FOG v3.1 - TEST ZBIEZNOSCI NUMERYCZNEJ")
disp("==============================================")

%% ============================================================
% PRZYGOTOWANIE MODELU
%% ============================================================

sourceModel = 'FOG_v3';
mdl = 'FOG_v3_1';

if ~isfile([sourceModel '.slx'])

    if isfile('FOG_start_v3.m')
        disp("FOG_v3.slx nie istnieje. Uruchamiam FOG_start_v3.m...")
        run('FOG_start_v3.m')
        bdclose('all')
    else
        error([ ...
            "Brak FOG_v3.slx oraz FOG_start_v3.m w aktualnym folderze. " ...
            "Najpierw uruchom lub pobierz v3." ...
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
% PARAMETRY FIZYCZNE - IDENTYCZNE JAK v3
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
f_design = 20e3;

phi0_fixed = beta_target / ...
    (2*abs(sin(pi*f_design*tau)));

%% ============================================================
% PARAMETRY MOCY - IDENTYCZNE JAK v3
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

Rpd = 0.9;
Rtia = 20e3;

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

K_front_forward = ...
    K1_launch_ratio * eta_K1 * eta_conn * eta_pol * eta_dep;

K_sagnac_power = ...
    2*K2_split_ratio*(1-K2_split_ratio) * eta_K2^2 * eta_loop;

K_front_return = ...
    eta_dep * eta_pol * eta_conn * ...
    K1_detector_ratio * eta_K1;

Pdet_scale_W = ...
    P_source_W * K_front_forward * ...
    K_sagnac_power * K_front_return;

%% ============================================================
% LOCK-IN - IDENTYCZNY JAK v3/v2.1
%% ============================================================

fc_lp = 300;
lp_order = 4;
[b_lp,a_lp] = butter(lp_order,2*pi*fc_lp,'s');

K_phase_to_deg = (180/pi)/K_sag;

%% ============================================================
% DODAJ LOGGER DELTA PHI MOD DO KOPII MODELU
%% ============================================================

sagnacSub = [mdl '/Sagnac Interferometer'];
logger = [sagnacSub '/Save_Delta_Mod_Conv'];

if getSimulinkBlockHandle(logger) == -1

    add_block( ...
        'simulink/Sinks/To Workspace', ...
        logger, ...
        'VariableName','delta_mod_conv_ts', ...
        'SaveFormat','Timeseries', ...
        'Position',[720 390 850 430])

    add_line( ...
        sagnacSub, ...
        'Delta phi mod/1', ...
        'Save_Delta_Mod_Conv/1', ...
        'autorouting','on')
end

%% ============================================================
% MACIERZ TESTOW
%% ============================================================

freqs_Hz = [20e3 50e3 f_opt 150e3];
steps_s = [0.20e-6 0.10e-6 0.05e-6 0.02e-6];

Nf = numel(freqs_Hz);
Ns = numel(steps_s);
N = Nf*Ns;

Omega_deg_s = 1;

% Krotki test, ale z wystarczajacym czasem na ustalenie lock-in.
Tstop = 0.020;
Tmean_start = 0.015;
Tbeta_start = 0.002;

f_col = zeros(N,1);
Ts_col = zeros(N,1);
stepsPerPeriod_col = zeros(N,1);
tauOverTs_col = zeros(N,1);
delayFrac_col = zeros(N,1);

betaTheory_col = zeros(N,1);
betaSim_col = zeros(N,1);
betaAbsErr_col = zeros(N,1);
betaRelErrPct_col = zeros(N,1);

omegaMean_col = zeros(N,1);
omegaErr_col = zeros(N,1);
omegaStd_col = zeros(N,1);

runtime_col = zeros(N,1);

row = 0;

disp("")
disp("Testuje 16 kombinacji f_mod x krok solvera...")
disp("")

%% ============================================================
% TESTY
%% ============================================================

for ifreq = 1:Nf

    f_mod = freqs_Hz(ifreq);
    phi0 = phi0_fixed;

    beta_eff = ...
        2*phi0*abs(sin(pi*f_mod*tau));

    K_ref = 1/beta_eff;

    J1beta = besselj(1,beta_eff);

    if abs(J1beta) < 1e-5
        warning( ...
            "f_mod %.3f kHz: J1(beta) bardzo blisko zera.", ...
            f_mod/1e3)
    end

    K_norm = ...
        -1/(Pdet_scale_W*visibility*Rpd*Rtia*J1beta);

    for istep = 1:Ns

        row = row + 1;
        Ts_solver = steps_s(istep);

        set_param( ...
            mdl, ...
            'SolverType','Fixed-step', ...
            'Solver','ode4', ...
            'FixedStep',sprintf('%.17g',Ts_solver), ...
            'StopTime',sprintf('%.17g',Tstop), ...
            'ReturnWorkspaceOutputs','on')

        fprintf( ...
            "[%2d/%2d] f = %8.3f kHz, Ts = %6.3f us ... ", ...
            row,N,f_mod/1e3,Ts_solver*1e6)

        tStart = tic;
        out = sim(mdl);
        runtime_s = toc(tStart);

        omega_ts = out.get('omega_est_ts');
        delta_ts = out.get('delta_mod_conv_ts');

        idxOmega = omega_ts.Time >= Tmean_start;
        idxBeta = delta_ts.Time >= Tbeta_start;

        omegaMean = mean(omega_ts.Data(idxOmega));
        omegaStd = std(omega_ts.Data(idxOmega));

        betaSim = ...
            (max(delta_ts.Data(idxBeta)) - ...
             min(delta_ts.Data(idxBeta)))/2;

        betaAbsErr = betaSim-beta_eff;
        betaRelErrPct = 100*betaAbsErr/beta_eff;

        delaySamples = tau/Ts_solver;
        delayFraction = ...
            abs(delaySamples-round(delaySamples));

        f_col(row) = f_mod;
        Ts_col(row) = Ts_solver;

        stepsPerPeriod_col(row) = ...
            1/(f_mod*Ts_solver);

        tauOverTs_col(row) = delaySamples;
        delayFrac_col(row) = delayFraction;

        betaTheory_col(row) = beta_eff;
        betaSim_col(row) = betaSim;
        betaAbsErr_col(row) = betaAbsErr;
        betaRelErrPct_col(row) = betaRelErrPct;

        omegaMean_col(row) = omegaMean;
        omegaErr_col(row) = omegaMean-Omega_deg_s;
        omegaStd_col(row) = omegaStd;

        runtime_col(row) = runtime_s;

        fprintf( ...
            "dOmega = %+ .6e deg/s, dBeta = %+ .6e %%\n", ...
            omegaErr_col(row),betaRelErrPct)
    end
end

%% ============================================================
% TABELA PELNA
%% ============================================================

results = table( ...
    f_col/1e3, ...
    Ts_col*1e6, ...
    stepsPerPeriod_col, ...
    tauOverTs_col, ...
    delayFrac_col, ...
    betaTheory_col, ...
    betaSim_col, ...
    betaAbsErr_col, ...
    betaRelErrPct_col, ...
    omegaMean_col, ...
    omegaErr_col, ...
    omegaStd_col, ...
    runtime_col, ...
    'VariableNames', ...
    { ...
    'f_mod_kHz', ...
    'Ts_us', ...
    'Steps_per_period', ...
    'tau_over_Ts', ...
    'Delay_fractional_step', ...
    'beta_teoria_rad', ...
    'beta_symulacja_rad', ...
    'Blad_beta_rad', ...
    'Blad_beta_percent', ...
    'Omega_zmierzone_deg_s', ...
    'Blad_Omega_deg_s', ...
    'STD_Omega_deg_s', ...
    'Runtime_s' ...
    });

disp("")
disp("==============================================")
disp(" WYNIKI v3.1")
disp("==============================================")
disp(results)

writetable(results,'FOG_v3_1_convergence.csv');

%% ============================================================
% POROWNANIE DO NAJMNIEJSZEGO KROKU
%% ============================================================

summary_f = zeros(Nf,1);

omega_coarse = zeros(Nf,1);
omega_fine = zeros(Nf,1);
omega_abs_coarse = zeros(Nf,1);
omega_abs_fine = zeros(Nf,1);
omega_improvement = zeros(Nf,1);

beta_coarse_pct = zeros(Nf,1);
beta_fine_pct = zeros(Nf,1);
beta_improvement = zeros(Nf,1);

for k = 1:Nf

    idx = find(abs(f_col-freqs_Hz(k)) < 1e-6);

    [~,iCoarseLocal] = max(Ts_col(idx));
    [~,iFineLocal] = min(Ts_col(idx));

    iCoarse = idx(iCoarseLocal);
    iFine = idx(iFineLocal);

    summary_f(k) = freqs_Hz(k)/1e3;

    omega_coarse(k) = omegaErr_col(iCoarse);
    omega_fine(k) = omegaErr_col(iFine);

    omega_abs_coarse(k) = abs(omega_coarse(k));
    omega_abs_fine(k) = abs(omega_fine(k));

    if omega_abs_fine(k) > 0
        omega_improvement(k) = ...
            omega_abs_coarse(k)/omega_abs_fine(k);
    else
        omega_improvement(k) = Inf;
    end

    beta_coarse_pct(k) = betaRelErrPct_col(iCoarse);
    beta_fine_pct(k) = betaRelErrPct_col(iFine);

    if abs(beta_fine_pct(k)) > 0
        beta_improvement(k) = ...
            abs(beta_coarse_pct(k))/abs(beta_fine_pct(k));
    else
        beta_improvement(k) = Inf;
    end
end

summary = table( ...
    summary_f, ...
    omega_coarse, ...
    omega_fine, ...
    omega_improvement, ...
    beta_coarse_pct, ...
    beta_fine_pct, ...
    beta_improvement, ...
    'VariableNames', ...
    { ...
    'f_mod_kHz', ...
    'Omega_error_at_0_20us_deg_s', ...
    'Omega_error_at_0_02us_deg_s', ...
    'Omega_error_improvement_factor', ...
    'Beta_error_at_0_20us_percent', ...
    'Beta_error_at_0_02us_percent', ...
    'Beta_error_improvement_factor' ...
    });

disp("")
disp("==============================================")
disp(" PODSUMOWANIE: 0.20 us -> 0.02 us")
disp("==============================================")
disp(summary)

writetable(summary,'FOG_v3_1_summary.csv');

%% ============================================================
% WYKRES 1 - BLAD OMEGA VS KROK
%% ============================================================

figure('Name','FOG v3.1 - zbieznosc Omega');

for k = 1:Nf

    idx = abs(f_col-freqs_Hz(k)) < 1e-6;

    loglog( ...
        Ts_col(idx)*1e6, ...
        max(abs(omegaErr_col(idx)),eps), ...
        'o-', ...
        'LineWidth',1.5, ...
        'DisplayName',sprintf('%.3f kHz',freqs_Hz(k)/1e3));

    hold on
end

grid on
xlabel('Krok solvera T_s [us]')
ylabel('|Blad Omega| [deg/s]')
title('FOG v3.1 - zbieznosc estymacji Omega')
legend('Location','best')

%% ============================================================
% WYKRES 2 - BLAD BETA VS KROK
%% ============================================================

figure('Name','FOG v3.1 - zbieznosc beta');

for k = 1:Nf

    idx = abs(f_col-freqs_Hz(k)) < 1e-6;

    loglog( ...
        Ts_col(idx)*1e6, ...
        max(abs(betaRelErrPct_col(idx)),eps), ...
        'o-', ...
        'LineWidth',1.5, ...
        'DisplayName',sprintf('%.3f kHz',freqs_Hz(k)/1e3));

    hold on
end

grid on
xlabel('Krok solvera T_s [us]')
ylabel('|Blad beta| [%]')
title('FOG v3.1 - zbieznosc Transport Delay')
legend('Location','best')

%% ============================================================
% WYKRES 3 - CZAS OBLICZEN
%% ============================================================

figure('Name','FOG v3.1 - koszt obliczen');

for k = 1:Nf

    idx = abs(f_col-freqs_Hz(k)) < 1e-6;

    loglog( ...
        Ts_col(idx)*1e6, ...
        runtime_col(idx), ...
        'o-', ...
        'LineWidth',1.5, ...
        'DisplayName',sprintf('%.3f kHz',freqs_Hz(k)/1e3));

    hold on
end

grid on
xlabel('Krok solvera T_s [us]')
ylabel('Czas symulacji [s]')
title('FOG v3.1 - koszt zmniejszania kroku')
legend('Location','best')

%% ============================================================
% ZAPIS MODELU
%% ============================================================

save_system(mdl);

disp("")
disp("==============================================")
disp(" FOG v3.1 - TEST ZAKONCZONY")
disp("==============================================")
disp("")
disp("Utworzono:")
disp("  FOG_v3_1.slx")
disp("  FOG_v3_1_convergence.csv")
disp("  FOG_v3_1_summary.csv")
disp("")
disp("Interpretacja:")
disp("  Jesli |blad Omega| i |blad beta| maleja przy zmniejszaniu Ts,")
disp("  potwierdzamy numeryczne zrodlo bledu wysokich f_mod.")
disp("  Najmniejszy krok nie musi byc krokiem docelowym.")
disp("  Wybierzemy kompromis dokladnosc/czas po wynikach.")
disp("")
