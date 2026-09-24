%% ============================================================
% FOG_design_v6_2.m
% Interferometryczny zyroskop swiatlowodowy - model v6.2
% MATLAB / Simulink R2023b
%
% CEL:
% - przejsc z fenomenologicznego "depol_residual" do parametrow
%   materialowych rzeczywistego depolaryzatora Lyota,
% - powiazac szerokosc widma SLD, beat length PM fiber, dlugosci
%   sekcji i blad kata spawu z residual proxy,
% - zbudowac wymagania zakupowe do BOM-u,
% - sprawdzic wybrany fizyczny projekt w modelu FOG v6.
%
% Model fizyczny:
% - zrodlo: widmo Gaussa,
% - PM fiber: idealny liniowy retarder,
% - Lyot: dwie sekcje PM, nominalnie L2 = 2*L1,
% - osie drugiej sekcji: 45 deg wzgledem pierwszej,
% - wynik: spectral-averaged Stokes i worst-case DOP po banku SOP.
%
% MOST DO v6:
% depol_residual_proxy = worst-case output DOP.
%
% Jest to CELOWO konserwatywny most modelowy, a nie tozsamosc
% fizyczna. Po pomiarze realnego depolaryzatora trzeba go skalibrowac.
%% ============================================================

clc
close all
bdclose('all')

disp("==============================================")
disp(" FOG v6.2 - FIZYCZNY DEPOLARYZATOR LYOTA")
disp("==============================================")

%% ============================================================
% PARAMETRY CENTRALNE
%% ============================================================

lambda0_m = 1550e-9;

% PM1550-HP / PM1550-XP class:
% konserwatywnie wykorzystujemy maksymalny beat length 5 mm @1550.
beat_length_worst_m = 5.0e-3;

% Progi z v6.1.
residual_point_target = 0.05;
residual_safe_target = 0.025;

% Projekt konserwatywny, inspirowany wariantem dla efektywnego
% komponentu widma ok. 8 nm.
effective_guard_bw_nm = 8.0;

% Wymaganie montazowe, ktore badamy jako realistyczny cel.
assembly_angle_error_deg = 0.50;

% Nominalny Lyot:
axis_nominal_deg = 45;
length_ratio_nominal = 2.0;

% Bank SOP + rozdzielczosc widma.
Nsop = 48;
Nlambda = 1001;

sopBank = buildSOPBank(Nsop);

%% ============================================================
% REFERENCYJNE PROFILE ZRODEL - DO PROJEKTOWANIA BOM
%
% Dane sa benchmarkami katalogowymi, nie deklaracja zakupu.
% Dla projektu uzywamy MINIMALNEJ szerokosci 3-dB, nie typowej.
%% ============================================================

sourceName = [ ...
    "SLD1550S-A40 benchmark"; ...
    "SLD1005S benchmark"; ...
    "SLD1550S-A2 benchmark"; ...
    "SLD1550S-A1 benchmark" ...
    ];

sourceMinBW_nm = [30;45;85;100];
sourceTypBW_nm = [33;50;90;110];
sourceTypPower_mW = [40;22;2.5;1.0];

sourceRefNote = [ ...
    "1550 nm, broad-band high-power reference"; ...
    "1550 nm, 50 nm class"; ...
    "1550 nm, 90 nm class"; ...
    "1550 nm, 1 mW / 110 nm class" ...
    ];

%% ============================================================
% v6.2A - SZYBKI ESTYMATOR DLUGOSCI DEPOLARYZACYJNEJ
%% ============================================================

disp("")
disp("==============================================")
disp(" v6.2A - DEPOLARIZING LENGTH ESTIMATE")
disp("==============================================")

bwEstimate_nm = [ ...
    effective_guard_bw_nm; ...
    sourceMinBW_nm ...
    ];

bwEstimate_nm = unique(bwEstimate_nm,'stable');

Ldc_m = ...
    lambda0_m^2 ./ (bwEstimate_nm*1e-9);

Ldp_m = ...
    lambda0_m*beat_length_worst_m ./ ...
    (bwEstimate_nm*1e-9);

lengthEstimate = table( ...
    bwEstimate_nm, ...
    Ldc_m, ...
    Ldp_m, ...
    'VariableNames', ...
    { ...
    'Effective_bandwidth_nm', ...
    'Decoherence_length_m', ...
    'Depolarizing_length_short_section_m' ...
    });

disp(lengthEstimate)

writetable( ...
    lengthEstimate, ...
    'FOG_v6_2_depolarizing_length_estimate.csv');

%% ============================================================
% v6.2B - MINIMALNA L1 VS SZEROKOSC WIDMA
%% ============================================================

disp("")
disp("==============================================")
disp(" v6.2B - MINIMUM LYOT LENGTH VS BANDWIDTH")
disp("==============================================")

bwSweep_nm = [8 10 15 20 30 45 50 85 100]';

L1grid_m = (0.10:0.05:2.00)';

Nb = numel(bwSweep_nm);

minL1_point_m = NaN(Nb,1);
minL1_safe_m = NaN(Nb,1);
DOP_at_1m = zeros(Nb,1);

for kb = 1:Nb

    bw_nm = bwSweep_nm(kb);

    % Benchmark 1 m + 2 m przy +0.5 deg.
    DOP_at_1m(kb) = lyotWorstDOP( ...
        lambda0_m,bw_nm,beat_length_worst_m, ...
        1.0,2.0,axis_nominal_deg+assembly_angle_error_deg, ...
        sopBank,Nlambda);

    for kl = 1:numel(L1grid_m)

        L1 = L1grid_m(kl);

        % Worst z +/- error kata i +/- 5% ratio.
        d = worstToleranceDOP( ...
            lambda0_m,bw_nm,beat_length_worst_m, ...
            L1,[1.95 2.00 2.05], ...
            axis_nominal_deg+[-assembly_angle_error_deg assembly_angle_error_deg], ...
            sopBank,Nlambda);

        if isnan(minL1_point_m(kb)) && d <= residual_point_target
            minL1_point_m(kb) = L1;
        end

        if isnan(minL1_safe_m(kb)) && d <= residual_safe_target
            minL1_safe_m(kb) = L1;
        end
    end

    fprintf( ...
        "BW=%5.1f nm: L1@5%%=%s m, L1@2.5%%=%s m\n", ...
        bw_nm,fmtNum(minL1_point_m(kb)),fmtNum(minL1_safe_m(kb)))
end

lengthSweep = table( ...
    bwSweep_nm, ...
    minL1_point_m, ...
    minL1_safe_m, ...
    2*minL1_safe_m, ...
    DOP_at_1m, ...
    'VariableNames', ...
    { ...
    'Effective_bandwidth_nm', ...
    'Min_L1_for_5pct_proxy_m', ...
    'Min_L1_for_2p5pct_proxy_m', ...
    'Nominal_L2_for_2p5pct_proxy_m', ...
    'Worst_DOP_for_1m_2m_at_0p5deg' ...
    });

writetable( ...
    lengthSweep, ...
    'FOG_v6_2_length_vs_bandwidth.csv');

%% ============================================================
% v6.2C - PROFILE REALNYCH KLAS ZRODEL
%% ============================================================

disp("")
disp("==============================================")
disp(" v6.2C - SOURCE BENCHMARKS")
disp("==============================================")

% Kandydat kompaktowy i konserwatywny.
compact_L1_m = 0.50;
compact_L2_m = 1.00;

selected_L1_m = 1.70;
selected_L2_m = 3.40;

Ns = numel(sourceName);

dopCompact = zeros(Ns,1);
dopSelected = zeros(Ns,1);
passSafeCompact = false(Ns,1);
passSafeSelected = false(Ns,1);

LdpSource_m = ...
    lambda0_m*beat_length_worst_m ./ ...
    (sourceMinBW_nm*1e-9);

for ks = 1:Ns

    bw_nm = sourceMinBW_nm(ks);

    dopCompact(ks) = worstToleranceDOP( ...
        lambda0_m,bw_nm,beat_length_worst_m, ...
        compact_L1_m,[1.95 2.00 2.05], ...
        axis_nominal_deg+[-assembly_angle_error_deg assembly_angle_error_deg], ...
        sopBank,Nlambda);

    dopSelected(ks) = worstToleranceDOP( ...
        lambda0_m,bw_nm,beat_length_worst_m, ...
        selected_L1_m,[1.95 2.00 2.05], ...
        axis_nominal_deg+[-assembly_angle_error_deg assembly_angle_error_deg], ...
        sopBank,Nlambda);

    passSafeCompact(ks) = ...
        dopCompact(ks) <= residual_safe_target;

    passSafeSelected(ks) = ...
        dopSelected(ks) <= residual_safe_target;
end

needsPowerManagement = ...
    sourceTypPower_mW > 1.5;

sourceResults = table( ...
    sourceName, ...
    sourceMinBW_nm, ...
    sourceTypBW_nm, ...
    sourceTypPower_mW, ...
    LdpSource_m, ...
    dopCompact, ...
    passSafeCompact, ...
    dopSelected, ...
    passSafeSelected, ...
    needsPowerManagement, ...
    sourceRefNote, ...
    'VariableNames', ...
    { ...
    'Source_reference', ...
    'Min_3dB_bandwidth_nm', ...
    'Typical_3dB_bandwidth_nm', ...
    'Typical_power_mW', ...
    'Ldp_estimate_m', ...
    'Worst_DOP_compact_0p5m_1m', ...
    'Compact_pass_2p5pct', ...
    'Worst_DOP_selected_1p7m_3p4m', ...
    'Selected_pass_2p5pct', ...
    'Needs_power_management_vs_1mW_model', ...
    'Note' ...
    });

disp(sourceResults)

writetable( ...
    sourceResults, ...
    'FOG_v6_2_source_benchmark.csv');

%% ============================================================
% v6.2D - GUARD 8 nm: POROWNANIE DLUGOSCI
%% ============================================================

disp("")
disp("==============================================")
disp(" v6.2D - EFFECTIVE 8 nm GUARD")
disp("==============================================")

designL1_m = [0.50 1.00 1.20 1.50 1.70]';
Nd = numel(designL1_m);

guardDOPideal = zeros(Nd,1);
guardDOPtol = zeros(Nd,1);

for kd = 1:Nd

    L1 = designL1_m(kd);

    guardDOPideal(kd) = lyotWorstDOP( ...
        lambda0_m,effective_guard_bw_nm,beat_length_worst_m, ...
        L1,2.0,45, ...
        sopBank,Nlambda);

    guardDOPtol(kd) = worstToleranceDOP( ...
        lambda0_m,effective_guard_bw_nm,beat_length_worst_m, ...
        L1,[1.95 2.00 2.05], ...
        axis_nominal_deg+[-assembly_angle_error_deg assembly_angle_error_deg], ...
        sopBank,Nlambda);
end

guardResults = table( ...
    designL1_m, ...
    2*designL1_m, ...
    3*designL1_m, ...
    guardDOPideal, ...
    guardDOPtol, ...
    guardDOPtol <= residual_safe_target, ...
    'VariableNames', ...
    { ...
    'L1_m', ...
    'L2_m', ...
    'Total_PM_fiber_m', ...
    'Worst_DOP_ideal_45deg', ...
    'Worst_DOP_with_0p5deg_and_ratio_tol', ...
    'Pass_2p5pct_proxy' ...
    });

disp(guardResults)

writetable( ...
    guardResults, ...
    'FOG_v6_2_effective8nm_guard.csv');

%% ============================================================
% v6.2E - TOLERANCJA KATA SPAWU 45 DEG
%% ============================================================

disp("")
disp("==============================================")
disp(" v6.2E - 45 DEG SPLICE TOLERANCE")
disp("==============================================")

angleErrorSweep_deg = (0:0.10:2.00)';
Na = numel(angleErrorSweep_deg);

angleDOP = zeros(Na,1);

for ka = 1:Na

    e = angleErrorSweep_deg(ka);

    angleDOP(ka) = max( ...
        lyotWorstDOP( ...
        lambda0_m,effective_guard_bw_nm,beat_length_worst_m, ...
        selected_L1_m,2.0,axis_nominal_deg-e, ...
        sopBank,Nlambda), ...
        lyotWorstDOP( ...
        lambda0_m,effective_guard_bw_nm,beat_length_worst_m, ...
        selected_L1_m,2.0,axis_nominal_deg+e, ...
        sopBank,Nlambda));
end

idxPassSafe = find(angleDOP <= residual_safe_target);

if isempty(idxPassSafe)
    maxAngleSafe_deg = NaN;
else
    maxAngleSafe_deg = ...
        max(angleErrorSweep_deg(idxPassSafe));
end

idxPassPoint = find(angleDOP <= residual_point_target);

if isempty(idxPassPoint)
    maxAnglePoint_deg = NaN;
else
    maxAnglePoint_deg = ...
        max(angleErrorSweep_deg(idxPassPoint));
end

angleResults = table( ...
    angleErrorSweep_deg, ...
    angleDOP, ...
    angleDOP <= residual_point_target, ...
    angleDOP <= residual_safe_target, ...
    'VariableNames', ...
    { ...
    'Axis_error_deg', ...
    'Worst_DOP_guard8nm', ...
    'Pass_5pct_proxy', ...
    'Pass_2p5pct_proxy' ...
    });

writetable( ...
    angleResults, ...
    'FOG_v6_2_splice_angle_sweep.csv');

fprintf("max angle error for 5%% proxy   = %s deg\n",fmtNum(maxAnglePoint_deg))
fprintf("max angle error for 2.5%% proxy = %s deg\n",fmtNum(maxAngleSafe_deg))

%% ============================================================
% v6.2F - MINIMALNA EFEKTYWNA SZEROKOSC WIDMA
%% ============================================================

disp("")
disp("==============================================")
disp(" v6.2F - MINIMUM EFFECTIVE BANDWIDTH")
disp("==============================================")

bwFine_nm = (2:0.25:30)';

dopBwSelected = zeros(size(bwFine_nm));

for k = 1:numel(bwFine_nm)

    dopBwSelected(k) = worstToleranceDOP( ...
        lambda0_m,bwFine_nm(k),beat_length_worst_m, ...
        selected_L1_m,[1.95 2.00 2.05], ...
        axis_nominal_deg+[-assembly_angle_error_deg assembly_angle_error_deg], ...
        sopBank,Nlambda);
end

idx = find(dopBwSelected <= residual_safe_target,1,'first');

if isempty(idx)
    minEffectiveBW_safe_nm = NaN;
else
    minEffectiveBW_safe_nm = bwFine_nm(idx);
end

bandwidthRequirement = table( ...
    bwFine_nm, ...
    dopBwSelected, ...
    dopBwSelected <= residual_safe_target, ...
    'VariableNames', ...
    { ...
    'Effective_bandwidth_nm', ...
    'Worst_DOP_selected_design', ...
    'Pass_2p5pct_proxy' ...
    });

writetable( ...
    bandwidthRequirement, ...
    'FOG_v6_2_bandwidth_requirement.csv');

fprintf( ...
    "minimum effective BW for selected design = %s nm\n", ...
    fmtNum(minEffectiveBW_safe_nm))

%% ============================================================
% v6.2G - WYBRANY PROJEKT I MOST DO v6
%% ============================================================

disp("")
disp("==============================================")
disp(" v6.2G - SELECTED PHYSICAL DESIGN")
disp("==============================================")

selected_bw_nm = effective_guard_bw_nm;

selected_residual_proxy = worstToleranceDOP( ...
    lambda0_m,selected_bw_nm,beat_length_worst_m, ...
    selected_L1_m,[1.95 2.00 2.05], ...
    axis_nominal_deg+[-assembly_angle_error_deg assembly_angle_error_deg], ...
    sopBank,Nlambda);

fprintf("Selected L1          = %.3f m\n",selected_L1_m)
fprintf("Selected L2          = %.3f m\n",selected_L2_m)
fprintf("PM total active      = %.3f m\n",selected_L1_m+selected_L2_m)
fprintf("Guard BW             = %.2f nm\n",selected_bw_nm)
fprintf("Beat length worst    = %.2f mm\n",beat_length_worst_m*1e3)
fprintf("Assembly angle error = +/- %.2f deg\n",assembly_angle_error_deg)
fprintf("Residual DOP proxy   = %.5f\n",selected_residual_proxy)
fprintf("Safe v6.1 target     = %.5f\n",residual_safe_target)

%% ============================================================
% WERYFIKACJA W FOG v6 - PROXY
%% ============================================================

sourceModel = 'FOG_v6';
mdl = 'FOG_v6_2';

if isfile([sourceModel '.slx'])

    if isfile([mdl '.slx'])
        delete([mdl '.slx'])
    end

    load_system(sourceModel)
    save_system(sourceModel,mdl)
    close_system(sourceModel,0)
    load_system(mdl)

    % Zmienne wymagane przez model v6.
    depol_residual = selected_residual_proxy;
    pol_nr_scale = 2.0e-4;

    polarizer_ER_dB = 25;
    polarizer_leakage = 10^(-polarizer_ER_dB/10);
    V_cal = (1-polarizer_leakage)/(1+polarizer_leakage);

    pol_enable = 1;

    pol_theta0_rad = 0;
    pol_theta_amp_rad = 0;

    pol_delta0_rad = 0;
    pol_delta_amp_rad = 0;

    pol_theta_freq_Hz = 0;
    pol_delta_freq_Hz = 0;
    pol_delta_phase_rad = pi/5;

    % Tor ADC/DSP zgodny z v6.
    P_source_W = 1e-3;
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
    eta_coil = 10^(-alpha_fiber_dB_km*(L/1000)/10);
    eta_PZT = 10^(-IL_PZT_dB/10);
    eta_splices = 10^(-(N_loop_splices*IL_splice_dB)/10);
    eta_loop = eta_coil*eta_PZT*eta_splices;

    K_front_forward = ...
        K1_launch_ratio*eta_K1*eta_conn*eta_pol*eta_dep;

    K_sagnac_power = ...
        2*K2_split_ratio*(1-K2_split_ratio)*eta_K2^2*eta_loop;

    K_front_return = ...
        eta_dep*eta_pol*eta_conn*K1_detector_ratio*eta_K1;

    Pdet_scale_W = ...
        P_source_W*K_front_forward*K_sagnac_power*K_front_return;

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
    opamp_en_eq_A_sqrtHz = opamp_en_V_sqrtHz/Rf;

    i_dark_shot_ASD = sqrt(2*q_e*I_dark_A);
    i_johnson_ASD = sqrt(4*k_B*T_receiver_K/Rf);
    i_opamp_current_ASD = opamp_in_A_sqrtHz;
    i_opamp_voltage_eq_ASD = opamp_en_eq_A_sqrtHz;

    Vadc_min = 0;
    Vadc_max = 2;
    Vadc_fs = 2;
    adc_bits = 16;
    fs_adc = 1e6;
    Ts_adc = 1/fs_adc;
    adc_sample_offset_s = 0;
    q_adc = Vadc_fs/(2^adc_bits-1);

    aa_order = 4;
    f_aa_Hz = 100e3;

    fc_digital_lp = 300;
    digital_lp_order = 4;

    [b_aa,a_aa] = butter(aa_order,2*pi*f_aa_Hz,'s');

    Haa = ...
        polyval(b_aa,1j*2*pi*f_mod)/ ...
        polyval(a_aa,1j*2*pi*f_mod);

    Htia = 1/(1+1j*f_mod/f_tia_Hz);

    Hanalog = Haa*Htia;

    Hmag_analog_fmod = abs(Hanalog);

    analog_phase_lag_rad = -angle(Hanalog);

    ref_delay_total_s = ...
        analog_phase_lag_rad/(2*pi*f_mod);

    K_norm_digital = ...
        -1/( ...
        Pdet_scale_W*V_cal*Rpd*Rf* ...
        Hmag_analog_fmod*J1beta);

    [b_dlp,a_dlp] = ...
        butter(digital_lp_order,fc_digital_lp/(fs_adc/2));

    [sos_d,g_d] = tf2sos(b_dlp,a_dlp);
    sos_d(1,1:3) = g_d*sos_d(1,1:3);

    % Pelny szum, paired bank.
    Ts_solver = 0.20e-6;
    Ts_noise = Ts_solver;
    noise_enable = 1;

    seed_photo = 250001;
    seed_dark = 250002;
    seed_johnson = 250003;
    seed_opamp_i = 250004;
    seed_opamp_en = 250005;

    updateNoiseSampling();

    TstopMC = 0.040;
    TmeanMC = 0.030;

    set_param( ...
        mdl, ...
        'SolverType','Fixed-step', ...
        'Solver','ode4', ...
        'FixedStep',sprintf('%.17g',Ts_solver), ...
        'StopTime',sprintf('%.17g',TstopMC), ...
        'ReturnWorkspaceOutputs','on');

    Nverify = 20;
    OmegaSignal = 1e-4;

    rng(66201);

    thetaBank = ...
        (-30 + 60*rand(Nverify,1))*pi/180;

    deltaBank = ...
        -0.5 + rand(Nverify,1);

    zeroVals = zeros(Nverify,1);
    signalVals = zeros(Nverify,1);

    for irun = 1:Nverify

        pol_theta0_rad = thetaBank(irun);
        pol_delta0_rad = deltaBank(irun);

        baseSeed = 2600000 + 10*irun;

        Omega_deg_s = 0;
        setSeeds(baseSeed);

        out = sim(mdl);
        omega_ts = out.get('omega_est_ts');

        idx = omega_ts.Time >= TmeanMC;
        zeroVals(irun) = mean(omega_ts.Data(idx));

        Omega_deg_s = OmegaSignal;
        setSeeds(baseSeed);

        out = sim(mdl);
        omega_ts = out.get('omega_est_ts');

        idx = omega_ts.Time >= TmeanMC;
        signalVals(irun) = mean(omega_ts.Data(idx));
    end

    zMean = mean(zeroVals);
    zStd = std(zeroVals);

    sMean = mean(signalVals);
    sStd = std(signalVals);

    pooled = sqrt((zStd^2+sStd^2)/2);

    separation = ...
        abs(sMean-zMean)/pooled;

    verification = table( ...
        selected_residual_proxy, ...
        Nverify, ...
        zMean, ...
        zStd, ...
        zStd*3600, ...
        sMean, ...
        sStd, ...
        sMean-OmegaSignal, ...
        separation, ...
        'VariableNames', ...
        { ...
        'Physical_residual_proxy', ...
        'N_pairs', ...
        'Zero_mean_deg_s', ...
        'Zero_STD_deg_s', ...
        'Zero_STD_deg_h', ...
        'Signal_mean_deg_s', ...
        'Signal_STD_deg_s', ...
        'Signal_bias_deg_s', ...
        'Class_separation_sigma' ...
        });

    disp("")
    disp("FOG v6.2 PROXY VERIFICATION")
    disp(verification)

    writetable( ...
        verification, ...
        'FOG_v6_2_fog_verification.csv');

    set_param( ...
        [mdl '/Sagnac Interferometer'], ...
        'AttributesFormatString', ...
        sprintf('K2 + 1 km SMF + PZT + Lyot proxy %.4f', ...
        selected_residual_proxy));

    save_system(mdl);

else

    warning("FOG_v6.slx not found - physical Lyot design completed without FOG verification.")
end

%% ============================================================
% BOM REQUIREMENTS
%% ============================================================

disp("")
disp("==============================================")
disp(" v6.2H - BOM REQUIREMENTS")
disp("==============================================")

% Dla aktywnej dlugosci 5.1 m kupujemy 6 m PM fiber,
% aby zostawic margines na cleave/splice/test.
purchase_pm_fiber_m = 6.0;

component = [ ...
    "Broadband source"; ...
    "PM fiber for Lyot"; ...
    "Lyot short section"; ...
    "Lyot long section"; ...
    "45-deg PM splice"; ...
    "PM fiber purchase length"; ...
    "Polarizer"; ...
    "SMF gyro coil" ...
    ];

minimumRequirement = [ ...
    "1550 nm; effective spectrum above computed threshold"; ...
    "Beat length <=5 mm @1550 nm"; ...
    sprintf("%.2f m nominal",selected_L1_m); ...
    sprintf("%.2f m nominal",selected_L2_m); ...
    sprintf("45 deg; model safe error <= +/- %.2f deg",maxAngleSafe_deg); ...
    sprintf("%.1f m bare PM fiber",purchase_pm_fiber_m); ...
    "ER >=25 dB model assumption"; ...
    "1000 m standard SMF, ~0.2 dB/km class" ...
    ];

preferred = [ ...
    "Broad smooth SLD/ASE, measured spectrum >=30 nm; verify narrow sub-peaks"; ...
    "PM1550-HP / PM1550-XP class, PANDA"; ...
    "1.7 m"; ...
    "3.4 m"; ...
    "PM axis alignment capability; target +/-0.5 deg"; ...
    "6 m gives handling/splice margin"; ...
    "Low IL, FC/APC or fusion-spliced implementation"; ...
    "G.652.D / SMF-28 class for first prototype" ...
    ];

reason = [ ...
    "Source coherence sets required depolarizer length"; ...
    "Worst beat length is used in design"; ...
    "Conservative for ~8 nm effective spectral component"; ...
    "Lyot 1:2 length ratio"; ...
    "Angle error dominates residual after spectral decoherence"; ...
    "5.1 m active + fabrication reserve"; ...
    "Defines launched polarization and supports reciprocity"; ...
    "Low-cost non-PM coil hypothesis under test" ...
    ];

status = [ ...
    "MEASURE LAB SOURCE BEFORE PURCHASE"; ...
    "PURCHASE / ORGANIZE"; ...
    "CUT FROM PM FIBER"; ...
    "CUT FROM PM FIBER"; ...
    "REQUIRES PM SPLICE PROCESS"; ...
    "PROCUREMENT TARGET"; ...
    "PURCHASE / ORGANIZE IF NOT IN LAB"; ...
    "PURCHASE / ORGANIZE" ...
    ];

bomRequirements = table( ...
    component, ...
    minimumRequirement, ...
    preferred, ...
    reason, ...
    status, ...
    'VariableNames', ...
    { ...
    'Component_or_process', ...
    'Minimum_requirement', ...
    'Preferred_spec', ...
    'Reason_from_simulation', ...
    'Status' ...
    });

disp(bomRequirements)

writetable( ...
    bomRequirements, ...
    'FOG_v6_2_bom_requirements.csv');

%% ============================================================
% PODSUMOWANIE PROJEKTU
%% ============================================================

selectedDesign = table( ...
    selected_L1_m, ...
    selected_L2_m, ...
    selected_L1_m+selected_L2_m, ...
    purchase_pm_fiber_m, ...
    effective_guard_bw_nm, ...
    beat_length_worst_m*1e3, ...
    assembly_angle_error_deg, ...
    selected_residual_proxy, ...
    residual_point_target, ...
    residual_safe_target, ...
    minEffectiveBW_safe_nm, ...
    maxAngleSafe_deg, ...
    'VariableNames', ...
    { ...
    'L1_m', ...
    'L2_m', ...
    'Active_PM_total_m', ...
    'Recommended_purchase_PM_m', ...
    'Effective_guard_bandwidth_nm', ...
    'Beat_length_worst_mm', ...
    'Design_axis_error_deg', ...
    'Worst_DOP_residual_proxy', ...
    'V6_1_point_target', ...
    'V6_1_safe_target', ...
    'Min_effective_BW_for_safe_proxy_nm', ...
    'Max_axis_error_for_safe_proxy_deg' ...
    });

disp("")
disp("SELECTED DESIGN")
disp(selectedDesign)

writetable( ...
    selectedDesign, ...
    'FOG_v6_2_selected_design.csv');

%% ============================================================
% WYKRESY
%% ============================================================

figure('Name','FOG v6.2 - length vs bandwidth')

plot( ...
    bwSweep_nm, ...
    minL1_safe_m, ...
    'o-', ...
    'LineWidth',1.5)

grid on
xlabel('Effective source bandwidth [nm]')
ylabel('Minimum L1 for 2.5% proxy [m]')
title('FOG v6.2 - Lyot short-section length requirement')

figure('Name','FOG v6.2 - splice angle')

plot( ...
    angleErrorSweep_deg, ...
    100*angleDOP, ...
    'o-', ...
    'LineWidth',1.5)

hold on
yline(100*residual_safe_target,'--')

grid on
xlabel('|45 deg splice error| [deg]')
ylabel('Worst-case DOP proxy [%]')
title('FOG v6.2 - splice alignment sensitivity')

figure('Name','FOG v6.2 - bandwidth guard')

semilogy( ...
    bwFine_nm, ...
    max(dopBwSelected,eps), ...
    '-', ...
    'LineWidth',1.5)

hold on
yline(residual_safe_target,'--')

grid on
xlabel('Effective bandwidth [nm]')
ylabel('Worst-case DOP proxy')
title('FOG v6.2 - selected Lyot design vs source bandwidth')

%% ============================================================
% KONIEC
%% ============================================================

if bdIsLoaded(mdl)
    open_system(mdl)
end

disp("")
disp("==============================================")
disp(" FOG v6.2 - PROJEKTOWANIE ZAKONCZONE")
disp("==============================================")
disp("")
disp("Utworzono:")
disp("  FOG_v6_2_depolarizing_length_estimate.csv")
disp("  FOG_v6_2_length_vs_bandwidth.csv")
disp("  FOG_v6_2_source_benchmark.csv")
disp("  FOG_v6_2_effective8nm_guard.csv")
disp("  FOG_v6_2_splice_angle_sweep.csv")
disp("  FOG_v6_2_bandwidth_requirement.csv")
disp("  FOG_v6_2_bom_requirements.csv")
disp("  FOG_v6_2_selected_design.csv")
disp("  opcjonalnie FOG_v6_2.slx + FOG_v6_2_fog_verification.csv")
disp("")
disp("Najwazniejsze: przed zakupem SLD zmierz realne widmo zrodla w labie.")
disp("Szerokosc 3-dB nie zawsze opisuje najwezszy koherentny komponent.")
disp("")

%% ============================================================
% FUNKCJE
%% ============================================================

function sopBank = buildSOPBank(N)

    % Fibonacci points on Poincare sphere.
    sopBank = zeros(2,N+6);

    golden = pi*(3-sqrt(5));

    for k = 0:N-1

        z = 1 - 2*(k+0.5)/N;
        t = acos(z);
        p = golden*k;

        sopBank(:,k+1) = [ ...
            cos(t/2); ...
            exp(1j*p)*sin(t/2) ...
            ];
    end

    % Canonical states H,V,+45,-45,R,L.
    sopBank(:,N+1) = [1;0];
    sopBank(:,N+2) = [0;1];
    sopBank(:,N+3) = [1;1]/sqrt(2);
    sopBank(:,N+4) = [1;-1]/sqrt(2);
    sopBank(:,N+5) = [1;1j]/sqrt(2);
    sopBank(:,N+6) = [1;-1j]/sqrt(2);
end

function DOPworst = lyotWorstDOP( ...
    lambda0_m,bw_nm,beatLength_m, ...
    L1_m,ratio,axis2_deg, ...
    sopBank,Nlambda)

    bw_m = bw_nm*1e-9;

    sigmaLambda = ...
        bw_m/(2*sqrt(2*log(2)));

    lambda = linspace( ...
        lambda0_m-4*sigmaLambda, ...
        lambda0_m+4*sigmaLambda, ...
        Nlambda);

    if lambda(1) <= 0
        error("Invalid wavelength grid.")
    end

    W = exp( ...
        -0.5*((lambda-lambda0_m)/sigmaLambda).^2);

    Wnorm = trapz(lambda,W);

    deltaN = lambda0_m/beatLength_m;

    L2_m = ratio*L1_m;

    phi1 = ...
        2*pi*deltaN*L1_m./lambda;

    phi2 = ...
        2*pi*deltaN*L2_m./lambda;

    % First PM section: axes = x/y.
    a1 = exp(1j*phi1/2);
    b1 = exp(-1j*phi1/2);

    % Second PM section rotated by axis2.
    alpha = axis2_deg*pi/180;
    c = cos(alpha);
    s = sin(alpha);

    a2 = exp(1j*phi2/2);
    b2 = exp(-1j*phi2/2);

    J11 = c^2*a2 + s^2*b2;
    J22 = s^2*a2 + c^2*b2;
    J12 = c*s*(a2-b2);
    J21 = J12;

    DOPworst = 0;

    for ks = 1:size(sopBank,2)

        Ex0 = sopBank(1,ks);
        Ey0 = sopBank(2,ks);

        % Section 1.
        Ex1 = a1*Ex0;
        Ey1 = b1*Ey0;

        % Section 2.
        Ex = J11.*Ex1 + J12.*Ey1;
        Ey = J21.*Ex1 + J22.*Ey1;

        S0 = abs(Ex).^2 + abs(Ey).^2;
        S1 = abs(Ex).^2 - abs(Ey).^2;
        S2 = 2*real(Ex.*conj(Ey));
        S3 = -2*imag(Ex.*conj(Ey));

        s0 = trapz(lambda,W.*S0)/Wnorm;
        s1 = trapz(lambda,W.*S1)/Wnorm;
        s2 = trapz(lambda,W.*S2)/Wnorm;
        s3 = trapz(lambda,W.*S3)/Wnorm;

        DOP = ...
            sqrt(s1^2+s2^2+s3^2)/s0;

        DOPworst = max(DOPworst,DOP);
    end
end

function d = worstToleranceDOP( ...
    lambda0_m,bw_nm,beatLength_m,L1_m,ratios,angles, ...
    sopBank,Nlambda)

    d = 0;

    for kr = 1:numel(ratios)
        for ka = 1:numel(angles)

            dt = lyotWorstDOP( ...
                lambda0_m,bw_nm,beatLength_m, ...
                L1_m,ratios(kr),angles(ka), ...
                sopBank,Nlambda);

            d = max(d,dt);
        end
    end
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

function s = fmtNum(x)

    if isnan(x)
        s = "NaN";
    else
        s = sprintf('%.3f',x);
    end
end
