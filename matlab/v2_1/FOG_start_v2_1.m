%% ============================================================
% FOG_start_v2_1.m
% Interferometryczny zyroskop swiatlowodowy - model v2.1
% MATLAB / Simulink R2023b
%
% Cel v2.1:
% - zachowac fizyke modelu v2 bez zmian,
% - poprawic tor lock-in,
% - usunac artefakt bledu przy niskiej f_mod (szczegolnie 5 kHz),
% - wydluzyc czas symulacji i uśredniania,
% - zastosowac 4-rzedowy analogowy filtr Butterwortha.
%% ============================================================

clc
close all
bdclose('all')

disp("==============================================")
disp(" FOG v2.1 - POPRAWIONY LOCK-IN")
disp("==============================================")

%% ------------------------------------------------------------
% PARAMETRY FIZYCZNE
%% ------------------------------------------------------------

c = 299792458;
lambda = 1550e-9;
L = 1000;
D = 0.160;
ng = 1.4682;

K_sag = 2*pi*L*D/(lambda*c);
tau = ng*L/c;
f_opt = 1/(2*tau);

%% ------------------------------------------------------------
% MODULATOR PZT
%% ------------------------------------------------------------

beta_target = 1.84;
f_design = 20e3;

phi0_fixed = beta_target / ...
    (2*abs(sin(pi*f_design*tau)));

f_mod = f_design;
phi0 = phi0_fixed;

beta_eff = 2*phi0*abs(sin(pi*f_mod*tau));

%% ------------------------------------------------------------
% TOR OPTYCZNY
%% ------------------------------------------------------------

Pscale = 20e-6;
visibility = 1.0;

%% ------------------------------------------------------------
% FOTODIODA + TIA
%% ------------------------------------------------------------

Rpd = 0.9;
Rtia = 20e3;

%% ------------------------------------------------------------
% LOCK-IN v2.1
%% ------------------------------------------------------------

% Filtr 4-rzedowy Butterwortha.
% Cel: bardzo silne tlumienie skladowej 2*f_mod przy zachowaniu DC.
fc_lp = 300;                 % [Hz]
lp_order = 4;

% Analogowy Butterworth: Wn podajemy w rad/s.
[b_lp, a_lp] = butter(lp_order, 2*pi*fc_lp, 's');

K_ref = 1/beta_eff;

J1beta = besselj(1,beta_eff);

if abs(J1beta) < 1e-6
    error("J1(beta_eff) jest zbyt bliskie zeru dla bezpiecznej demodulacji.")
end

K_norm = -1/(Pscale*visibility*Rpd*Rtia*J1beta);
K_phase_to_deg = (180/pi)/K_sag;

%% ------------------------------------------------------------
% PARAMETRY NUMERYCZNE
%% ------------------------------------------------------------

% Zostawiamy drobny krok z v2, ale wydluzamy symulacje.
Ts_solver = 2e-7;            % 0.2 us
Tstop = 0.050;               % 50 ms

% Ostatnie 10 ms przeznaczamy na estymacje sredniej.
Tmean_window = 0.010;
Tmean_start = Tstop - Tmean_window;

% Okno do pomiaru beta po wygaszeniu transientu Transport Delay.
Tbeta_start = 0.005;

%% ------------------------------------------------------------
% INFORMACJE STARTOWE
%% ------------------------------------------------------------

fprintf("\nPARAMETRY CEWKI FOG\n")
fprintf("---------------------------------\n")
fprintf("lambda           = %.1f nm\n",lambda*1e9)
fprintf("L                = %.0f m\n",L)
fprintf("D                = %.1f mm\n",D*1000)
fprintf("K_sag            = %.6f rad/(rad/s)\n",K_sag)
fprintf("tau              = %.6f us\n",tau*1e6)
fprintf("f_opt            = %.3f kHz\n",f_opt/1e3)

fprintf("\nLOCK-IN v2.1\n")
fprintf("---------------------------------\n")
fprintf("LPF order        = %d\n",lp_order)
fprintf("LPF fc           = %.1f Hz\n",fc_lp)
fprintf("Tstop            = %.1f ms\n",Tstop*1e3)
fprintf("mean window      = %.1f ms\n",Tmean_window*1e3)

%% ============================================================
% BUDOWA MODELU SIMULINK
%% ============================================================

mdl = 'FOG_v2_1';

if bdIsLoaded(mdl)
    close_system(mdl,0)
end

if isfile([mdl '.slx'])
    delete([mdl '.slx'])
end

new_system(mdl)
open_system(mdl)

%% ------------------------------------------------------------
% WEJSCIE OMEGA
%% ------------------------------------------------------------

Omega_deg_s = 1;

add_block( ...
    'simulink/Sources/Constant', ...
    [mdl '/Omega_deg_s'], ...
    'Value','Omega_deg_s', ...
    'Position',[40 170 110 210])

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/deg_to_rad'], ...
    'Gain','pi/180', ...
    'Position',[150 165 230 215])

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Sagnac'], ...
    'Gain','K_sag', ...
    'Position',[270 165 360 215])

%% ------------------------------------------------------------
% FIZYCZNY MODULATOR PZT
%% ------------------------------------------------------------

add_block( ...
    'simulink/Sources/Sine Wave', ...
    [mdl '/PZT_phi_m'], ...
    'Amplitude','phi0', ...
    'Frequency','2*pi*f_mod', ...
    'Bias','0', ...
    'Phase','0', ...
    'SampleTime','0', ...
    'Position',[120 330 230 370])

add_block( ...
    'simulink/Continuous/Transport Delay', ...
    [mdl '/CW_CCW_Delay'], ...
    'DelayTime','tau', ...
    'Position',[310 340 420 380])

add_block( ...
    'simulink/Math Operations/Sum', ...
    [mdl '/Delta_phi_mod'], ...
    'Inputs','+-', ...
    'Position',[490 310 525 390])

%% ------------------------------------------------------------
% SUMA FAZ
%% ------------------------------------------------------------

add_block( ...
    'simulink/Math Operations/Sum', ...
    [mdl '/Total_Phase'], ...
    'Inputs','++', ...
    'Position',[600 180 635 250])

%% ------------------------------------------------------------
% INTERFERENCJA + TOR OPTYCZNO-ELEKTRYCZNY
%% ------------------------------------------------------------

add_block( ...
    'simulink/Math Operations/Trigonometric Function', ...
    [mdl '/Interference_cos'], ...
    'Operator','cos', ...
    'Position',[690 190 775 240])

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Visibility'], ...
    'Gain','visibility', ...
    'Position',[820 190 900 240])

add_block( ...
    'simulink/Math Operations/Bias', ...
    [mdl '/Optical_DC'], ...
    'Bias','1', ...
    'Position',[940 190 1020 240])

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Optical_Power'], ...
    'Gain','Pscale', ...
    'Position',[1060 190 1150 240])

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Photodiode'], ...
    'Gain','Rpd', ...
    'Position',[1190 190 1280 240])

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/TIA'], ...
    'Gain','Rtia', ...
    'Position',[1320 190 1400 240])

%% ------------------------------------------------------------
% REFERENCJA LOCK-IN
%% ------------------------------------------------------------

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Reference_Normalize'], ...
    'Gain','K_ref', ...
    'Position',[650 340 750 380])

add_block( ...
    'simulink/Math Operations/Product', ...
    [mdl '/LockIn_Mixer'], ...
    'Position',[1460 210 1510 270])

%% ------------------------------------------------------------
% NOWY FILTR LOCK-IN: 4-RZEDOWY BUTTERWORTH
%% ------------------------------------------------------------

add_block( ...
    'simulink/Continuous/Transfer Fcn', ...
    [mdl '/LockIn_LPF_4th'], ...
    'Numerator','b_lp', ...
    'Denominator','a_lp', ...
    'Position',[1560 205 1710 275])

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Normalize'], ...
    'Gain','K_norm', ...
    'Position',[1760 215 1840 265])

%% ------------------------------------------------------------
% ESTYMACJA
%% ------------------------------------------------------------

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Omega_linear'], ...
    'Gain','K_phase_to_deg', ...
    'Position',[1900 110 2000 160])

add_block( ...
    'simulink/Discontinuities/Saturation', ...
    [mdl '/Limit_asin'], ...
    'UpperLimit','0.999999', ...
    'LowerLimit','-0.999999', ...
    'Position',[1900 245 1990 295])

add_block( ...
    'simulink/Math Operations/Trigonometric Function', ...
    [mdl '/asin'], ...
    'Operator','asin', ...
    'Position',[2030 245 2100 295])

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Omega_est'], ...
    'Gain','K_phase_to_deg', ...
    'Position',[2140 245 2240 295])

%% ------------------------------------------------------------
% ZAPIS
%% ------------------------------------------------------------

add_block( ...
    'simulink/Sinks/To Workspace', ...
    [mdl '/Save_Omega'], ...
    'VariableName','omega_est_ts', ...
    'SaveFormat','Timeseries', ...
    'Position',[2290 240 2400 280])

add_block( ...
    'simulink/Sinks/To Workspace', ...
    [mdl '/Save_Linear'], ...
    'VariableName','omega_linear_ts', ...
    'SaveFormat','Timeseries', ...
    'Position',[2050 110 2160 150])

add_block( ...
    'simulink/Sinks/To Workspace', ...
    [mdl '/Save_Delta_Mod'], ...
    'VariableName','delta_mod_ts', ...
    'SaveFormat','Timeseries', ...
    'Position',[650 430 770 470])

add_block( ...
    'simulink/Sinks/To Workspace', ...
    [mdl '/Save_LockIn_LPF'], ...
    'VariableName','lockin_lp_ts', ...
    'SaveFormat','Timeseries', ...
    'Position',[1750 330 1870 370])

add_block( ...
    'simulink/Sinks/Display', ...
    [mdl '/Omega_est_Display'], ...
    'Position',[2290 305 2390 355])

add_block( ...
    'simulink/Signal Routing/Mux', ...
    [mdl '/Mux'], ...
    'Inputs','2', ...
    'Position',[2290 100 2300 170])

add_block( ...
    'simulink/Sinks/Scope', ...
    [mdl '/Scope'], ...
    'Position',[2350 110 2410 170])

%% ============================================================
% POLACZENIA
%% ============================================================

add_line(mdl,'Omega_deg_s/1','deg_to_rad/1','autorouting','on')
add_line(mdl,'deg_to_rad/1','Sagnac/1','autorouting','on')
add_line(mdl,'Sagnac/1','Total_Phase/1','autorouting','on')

add_line(mdl,'PZT_phi_m/1','Delta_phi_mod/1','autorouting','on')
add_line(mdl,'PZT_phi_m/1','CW_CCW_Delay/1','autorouting','on')
add_line(mdl,'CW_CCW_Delay/1','Delta_phi_mod/2','autorouting','on')

add_line(mdl,'Delta_phi_mod/1','Total_Phase/2','autorouting','on')
add_line(mdl,'Delta_phi_mod/1','Reference_Normalize/1','autorouting','on')
add_line(mdl,'Delta_phi_mod/1','Save_Delta_Mod/1','autorouting','on')

add_line(mdl,'Total_Phase/1','Interference_cos/1','autorouting','on')
add_line(mdl,'Interference_cos/1','Visibility/1','autorouting','on')
add_line(mdl,'Visibility/1','Optical_DC/1','autorouting','on')
add_line(mdl,'Optical_DC/1','Optical_Power/1','autorouting','on')
add_line(mdl,'Optical_Power/1','Photodiode/1','autorouting','on')
add_line(mdl,'Photodiode/1','TIA/1','autorouting','on')

add_line(mdl,'TIA/1','LockIn_Mixer/1','autorouting','on')
add_line(mdl,'Reference_Normalize/1','LockIn_Mixer/2','autorouting','on')
add_line(mdl,'LockIn_Mixer/1','LockIn_LPF_4th/1','autorouting','on')
add_line(mdl,'LockIn_LPF_4th/1','Normalize/1','autorouting','on')
add_line(mdl,'LockIn_LPF_4th/1','Save_LockIn_LPF/1','autorouting','on')

add_line(mdl,'Normalize/1','Omega_linear/1','autorouting','on')
add_line(mdl,'Normalize/1','Limit_asin/1','autorouting','on')
add_line(mdl,'Limit_asin/1','asin/1','autorouting','on')
add_line(mdl,'asin/1','Omega_est/1','autorouting','on')

add_line(mdl,'Omega_est/1','Save_Omega/1','autorouting','on')
add_line(mdl,'Omega_linear/1','Save_Linear/1','autorouting','on')
add_line(mdl,'Omega_est/1','Omega_est_Display/1','autorouting','on')

add_line(mdl,'Omega_deg_s/1','Mux/1','autorouting','on')
add_line(mdl,'Omega_est/1','Mux/2','autorouting','on')
add_line(mdl,'Mux/1','Scope/1','autorouting','on')

%% ============================================================
% PARAMETRY SYMULACJI
%% ============================================================

set_param(mdl, ...
    'SolverType','Fixed-step', ...
    'Solver','ode4', ...
    'FixedStep','Ts_solver', ...
    'StopTime','Tstop', ...
    'ReturnWorkspaceOutputs','on')

save_system(mdl)

%% ============================================================
% WALIDACJA BAZOWA: 1 deg/s, 20 kHz
%% ============================================================

disp("")
disp("==============================================")
disp(" WALIDACJA BAZOWA v2.1: 1 deg/s, 20 kHz")
disp("==============================================")

Omega_deg_s = 1;
f_mod = f_design;
phi0 = phi0_fixed;

beta_eff = 2*phi0*abs(sin(pi*f_mod*tau));
K_ref = 1/beta_eff;

J1beta = besselj(1,beta_eff);
K_norm = -1/(Pscale*visibility*Rpd*Rtia*J1beta);

out = sim(mdl);

omega_ts = out.get('omega_est_ts');
delta_ts = out.get('delta_mod_ts');

idx_omega = omega_ts.Time >= Tmean_start;
idx_beta = delta_ts.Time >= Tbeta_start;

omega_measured = mean(omega_ts.Data(idx_omega));
omega_std = std(omega_ts.Data(idx_omega));

beta_sim = ...
    (max(delta_ts.Data(idx_beta)) - min(delta_ts.Data(idx_beta)))/2;

fprintf("Omega zadane       = %.9f deg/s\n",Omega_deg_s)
fprintf("Omega srednia      = %.9f deg/s\n",omega_measured)
fprintf("Blad Omega         = %.9f deg/s\n",omega_measured-Omega_deg_s)
fprintf("STD w oknie        = %.9f deg/s\n",omega_std)
fprintf("beta teoria        = %.9f rad\n",beta_eff)
fprintf("beta symulacja     = %.9f rad\n",beta_sim)

%% ============================================================
% SWEEP CZESTOTLIWOSCI
%% ============================================================

disp("")
disp("==============================================")
disp(" SWEEP v2.1 - POPRAWIONY LOCK-IN")
disp("==============================================")

freqs = [5e3 10e3 20e3 50e3 f_opt 150e3];
N = numel(freqs);

beta_theory = zeros(N,1);
beta_measured = zeros(N,1);
beta_error = zeros(N,1);

delay_efficiency = zeros(N,1);
J1_value = zeros(N,1);
J1_abs = zeros(N,1);

phi0_required = zeros(N,1);

omega_measured_f = zeros(N,1);
omega_error_f = zeros(N,1);
omega_std_f = zeros(N,1);

lockin_mean = zeros(N,1);
lockin_std = zeros(N,1);

Omega_deg_s = 1;

for k = 1:N

    f_mod = freqs(k);
    phi0 = phi0_fixed;

    beta_eff = 2*phi0*abs(sin(pi*f_mod*tau));
    beta_theory(k) = beta_eff;

    delay_efficiency(k) = abs(sin(pi*f_mod*tau));

    phi0_required(k) = ...
        beta_target / (2*abs(sin(pi*f_mod*tau)));

    K_ref = 1/beta_eff;

    J1beta = besselj(1,beta_eff);
    J1_value(k) = J1beta;
    J1_abs(k) = abs(J1beta);

    if abs(J1beta) < 1e-4
        warning( ...
            "f_mod = %.3f kHz: J1(beta) blisko zera.", ...
            f_mod/1e3)
    end

    K_norm = ...
        -1/(Pscale*visibility*Rpd*Rtia*J1beta);

    out = sim(mdl);

    omega_ts = out.get('omega_est_ts');
    delta_ts = out.get('delta_mod_ts');
    lock_ts = out.get('lockin_lp_ts');

    idx_omega = omega_ts.Time >= Tmean_start;
    idx_beta = delta_ts.Time >= Tbeta_start;
    idx_lock = lock_ts.Time >= Tmean_start;

    omega_measured_f(k) = mean(omega_ts.Data(idx_omega));
    omega_error_f(k) = omega_measured_f(k) - Omega_deg_s;
    omega_std_f(k) = std(omega_ts.Data(idx_omega));

    beta_measured(k) = ...
        (max(delta_ts.Data(idx_beta)) - ...
         min(delta_ts.Data(idx_beta)))/2;

    beta_error(k) = beta_measured(k) - beta_theory(k);

    lockin_mean(k) = mean(lock_ts.Data(idx_lock));
    lockin_std(k) = std(lock_ts.Data(idx_lock));

end

results = table( ...
    freqs(:)/1e3, ...
    beta_theory, ...
    beta_measured, ...
    beta_error, ...
    delay_efficiency, ...
    J1_value, ...
    J1_abs, ...
    phi0_required, ...
    omega_measured_f, ...
    omega_error_f, ...
    omega_std_f, ...
    lockin_mean, ...
    lockin_std, ...
    'VariableNames', ...
    { ...
    'f_mod_kHz', ...
    'beta_teoria_rad', ...
    'beta_symulacja_rad', ...
    'blad_beta_rad', ...
    'delay_efficiency', ...
    'J1_beta', ...
    'abs_J1_beta', ...
    'phi0_dla_beta_1_84_rad', ...
    'Omega_zmierzone_deg_s', ...
    'Blad_Omega_deg_s', ...
    'STD_Omega_deg_s', ...
    'LockIn_LPF_mean', ...
    'LockIn_LPF_std' ...
    });

disp("")
disp(results)

%% ------------------------------------------------------------
% ZAPIS CSV
%% ------------------------------------------------------------

writetable(results,'FOG_v2_1_frequency_sweep.csv')

baseline = table( ...
    f_design/1e3, ...
    phi0_fixed, ...
    beta_target, ...
    beta_sim, ...
    Omega_deg_s, ...
    omega_measured, ...
    omega_measured-Omega_deg_s, ...
    omega_std, ...
    'VariableNames', ...
    { ...
    'f_mod_kHz', ...
    'phi0_rad', ...
    'beta_target_rad', ...
    'beta_symulacja_rad', ...
    'Omega_zadane_deg_s', ...
    'Omega_zmierzone_deg_s', ...
    'Blad_Omega_deg_s', ...
    'STD_Omega_deg_s' ...
    });

writetable(baseline,'FOG_v2_1_baseline.csv')

%% ------------------------------------------------------------
% WYKRES 1 - BLAD OMEGA
%% ------------------------------------------------------------

figure('Name','FOG v2.1 - blad Omega')

plot( ...
    freqs/1e3, ...
    omega_error_f, ...
    'o-', ...
    'LineWidth',1.5)

grid on
xlabel('f_{mod} [kHz]')
ylabel('Blad \Omega [deg/s]')
title('FOG v2.1 - blad estymacji po poprawie lock-in')

%% ------------------------------------------------------------
% WYKRES 2 - TETNIENIE OMEGA
%% ------------------------------------------------------------

figure('Name','FOG v2.1 - STD Omega')

semilogy( ...
    freqs/1e3, ...
    max(omega_std_f,eps), ...
    'o-', ...
    'LineWidth',1.5)

grid on
xlabel('f_{mod} [kHz]')
ylabel('STD \Omega [deg/s]')
title('FOG v2.1 - pozostale tetnienie w oknie pomiarowym')

%% ------------------------------------------------------------
% WYKRES 3 - BETA
%% ------------------------------------------------------------

figure('Name','FOG v2.1 - beta')

plot(freqs/1e3,beta_theory,'o-','LineWidth',1.5)
hold on
plot(freqs/1e3,beta_measured,'s--','LineWidth',1.5)

grid on
xlabel('f_{mod} [kHz]')
ylabel('\beta [rad]')
legend('teoria','symulacja','Location','best')
title('FOG v2.1 - walidacja modulacji')

%% ------------------------------------------------------------
% KONIEC
%% ------------------------------------------------------------

save_system(mdl)
open_system(mdl)

disp("")
disp("==============================================")
disp(" FOG v2.1 - SYMULACJA ZAKONCZONA")
disp("==============================================")
disp("")
disp("Utworzono:")
disp("  FOG_v2_1.slx")
disp("  FOG_v2_1_baseline.csv")
disp("  FOG_v2_1_frequency_sweep.csv")
disp("")
disp("Najwazniejszy test:")
disp("  sprawdz, czy blad dla 5 kHz spadl wzgledem v2")
disp("  z ok. +0.0757 deg/s do wartosci bliskiej zera.")
disp("")
