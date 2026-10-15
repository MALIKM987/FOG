%% ============================================================
% FOG_start_v2.m
% Interferometryczny zyroskop swiatlowodowy - model v2
% MATLAB / Simulink R2023b
%
% v2 dodaje fizyczny model modulacji fazy:
%
%   phi_m(t) = phi0*sin(2*pi*f_mod*t)
%
% oraz opoznienie propagacji CW/CCW:
%
%   Delta_phi_m(t) = phi_m(t) - phi_m(t - tau)
%
% Model wykonuje:
% 1. walidacje dla 1 deg/s i 20 kHz,
% 2. sweep czestotliwosci 5, 10, 20, 50, f_opt i 150 kHz,
% 3. porownanie beta z teoria,
% 4. pomiar wymaganej amplitudy phi0 dla beta_target = 1.84 rad,
% 5. zapis CSV i wykresow.
%% ============================================================

clc
close all
bdclose('all')

disp("==============================================")
disp(" FOG v2 - PZT + OPOZNIENIE CW/CCW")
disp("==============================================")

%% ------------------------------------------------------------
% PARAMETRY FIZYCZNE
%% ------------------------------------------------------------

c = 299792458;           % predkosc swiatla [m/s]
lambda = 1550e-9;        % dlugosc fali [m]
L = 1000;                % dlugosc cewki [m]
D = 0.160;               % srednia srednica cewki [m]
ng = 1.4682;             % wspolczynnik grupowy wlokna

K_sag = 2*pi*L*D/(lambda*c);
tau = ng*L/c;
f_opt = 1/(2*tau);

%% ------------------------------------------------------------
% MODULATOR PZT
%% ------------------------------------------------------------

beta_target = 1.84;      % dogodna amplituda roznicowej modulacji [rad]
f_design = 20e3;         % punkt projektowy v1/v2 [Hz]

% phi0 to amplituda fazy wprowadzanej przez PZT przy pojedynczym przejsciu.
% Ustalamy ja tak, aby przy 20 kHz otrzymac beta_target = 1.84 rad.
phi0_fixed = beta_target / ...
    (2*abs(sin(pi*f_design*tau)));

% Zmienne robocze odczytywane przez model Simulinka.
f_mod = f_design;
phi0 = phi0_fixed;

beta_eff = 2*phi0*abs(sin(pi*f_mod*tau));

%% ------------------------------------------------------------
% TOR OPTYCZNY
%% ------------------------------------------------------------

Pscale = 20e-6;          % skala mocy optycznej [W]
visibility = 1.0;        % kontrast interferencji 0...1

%% ------------------------------------------------------------
% FOTODIODA + TIA
%% ------------------------------------------------------------

Rpd = 0.9;               % responsywnosc [A/W]
Rtia = 20e3;             % transimpedancja [V/A]

%% ------------------------------------------------------------
% DEMODULACJA LOCK-IN
%% ------------------------------------------------------------

fc_lp = 300;             % czestotliwosc graniczna LPF [Hz]

% Referencja jest tworzona bezposrednio z Delta_phi_m(t).
% Po podzieleniu przez beta_eff ma amplitude 1 i zachowuje
% poprawna faze modulacji niezaleznie od f_mod.
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

Tstop = 0.020;           % czas symulacji [s]
Ts_solver = 2e-7;        % 0.2 us, ~33 probki/okres przy 150 kHz
Tmean_start = 0.015;     % poczatek okna usredniania [s]
Tbeta_start = 0.002;     % pomijamy transient Transport Delay

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

fprintf("\nPZT - PUNKT PROJEKTOWY\n")
fprintf("---------------------------------\n")
fprintf("f_design         = %.3f kHz\n",f_design/1e3)
fprintf("beta_target      = %.6f rad\n",beta_target)
fprintf("phi0_fixed       = %.6f rad\n",phi0_fixed)
fprintf("beta_eff @20kHz  = %.6f rad\n",beta_eff)
fprintf("J1(beta_eff)     = %.6f\n",J1beta)

fprintf("\nSAGNAC DLA 1 deg/s\n")
fprintf("---------------------------------\n")
fprintf("Delta_phi_S      = %.6f rad\n",K_sag*pi/180)

%% ============================================================
% BUDOWA MODELU SIMULINK
%% ============================================================

mdl = 'FOG_v2';

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

% Druga fala widzi ten sam modulator po czasie tau.
add_block( ...
    'simulink/Continuous/Transport Delay', ...
    [mdl '/CW_CCW_Delay'], ...
    'DelayTime','tau', ...
    'Position',[310 340 420 380])

% Delta_phi_m(t) = phi_m(t) - phi_m(t-tau)
add_block( ...
    'simulink/Math Operations/Sum', ...
    [mdl '/Delta_phi_mod'], ...
    'Inputs','+-', ...
    'Position',[490 310 525 390])

%% ------------------------------------------------------------
% SUMA FAZY SAGNACA I MODULACJI
%% ------------------------------------------------------------

add_block( ...
    'simulink/Math Operations/Sum', ...
    [mdl '/Total_Phase'], ...
    'Inputs','++', ...
    'Position',[600 180 635 250])

%% ------------------------------------------------------------
% INTERFERENCJA
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
% REFERENCJA LOCK-IN Z RZECZYWISTEJ DELTA_phi_mod
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

add_block( ...
    'simulink/Continuous/Transfer Fcn', ...
    [mdl '/LockIn_LPF'], ...
    'Numerator','2*pi*fc_lp', ...
    'Denominator','[1 2*pi*fc_lp]', ...
    'Position',[1560 215 1680 265])

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Normalize'], ...
    'Gain','K_norm', ...
    'Position',[1730 215 1810 265])

%% ------------------------------------------------------------
% ESTYMACJA OMEGA
%% ------------------------------------------------------------

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Omega_linear'], ...
    'Gain','K_phase_to_deg', ...
    'Position',[1870 110 1970 160])

add_block( ...
    'simulink/Discontinuities/Saturation', ...
    [mdl '/Limit_asin'], ...
    'UpperLimit','0.999999', ...
    'LowerLimit','-0.999999', ...
    'Position',[1870 245 1960 295])

add_block( ...
    'simulink/Math Operations/Trigonometric Function', ...
    [mdl '/asin'], ...
    'Operator','asin', ...
    'Position',[2000 245 2070 295])

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Omega_est'], ...
    'Gain','K_phase_to_deg', ...
    'Position',[2110 245 2210 295])

%% ------------------------------------------------------------
% ZAPIS SYGNALOW
%% ------------------------------------------------------------

add_block( ...
    'simulink/Sinks/To Workspace', ...
    [mdl '/Save_Omega'], ...
    'VariableName','omega_est_ts', ...
    'SaveFormat','Timeseries', ...
    'Position',[2260 240 2370 280])

add_block( ...
    'simulink/Sinks/To Workspace', ...
    [mdl '/Save_Linear'], ...
    'VariableName','omega_linear_ts', ...
    'SaveFormat','Timeseries', ...
    'Position',[2020 110 2130 150])

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
    'Position',[1720 330 1840 370])

%% ------------------------------------------------------------
% DISPLAY + SCOPE
%% ------------------------------------------------------------

add_block( ...
    'simulink/Sinks/Display', ...
    [mdl '/Omega_est_Display'], ...
    'Position',[2260 305 2360 355])

add_block( ...
    'simulink/Signal Routing/Mux', ...
    [mdl '/Mux'], ...
    'Inputs','2', ...
    'Position',[2260 100 2270 170])

add_block( ...
    'simulink/Sinks/Scope', ...
    [mdl '/Scope'], ...
    'Position',[2320 110 2380 170])

%% ============================================================
% POLACZENIA
%% ============================================================

add_line(mdl,'Omega_deg_s/1','deg_to_rad/1','autorouting','on')
add_line(mdl,'deg_to_rad/1','Sagnac/1','autorouting','on')
add_line(mdl,'Sagnac/1','Total_Phase/1','autorouting','on')

% PZT -> bezposrednio
add_line(mdl,'PZT_phi_m/1','Delta_phi_mod/1','autorouting','on')

% PZT -> opoznienie -> drugi kierunek
add_line(mdl,'PZT_phi_m/1','CW_CCW_Delay/1','autorouting','on')
add_line(mdl,'CW_CCW_Delay/1','Delta_phi_mod/2','autorouting','on')

% roznicowa modulacja -> interferometr
add_line(mdl,'Delta_phi_mod/1','Total_Phase/2','autorouting','on')

% roznicowa modulacja -> referencja lock-in
add_line(mdl,'Delta_phi_mod/1','Reference_Normalize/1','autorouting','on')

% zapis roznicowej modulacji
add_line(mdl,'Delta_phi_mod/1','Save_Delta_Mod/1','autorouting','on')

% interferometr
add_line(mdl,'Total_Phase/1','Interference_cos/1','autorouting','on')
add_line(mdl,'Interference_cos/1','Visibility/1','autorouting','on')
add_line(mdl,'Visibility/1','Optical_DC/1','autorouting','on')
add_line(mdl,'Optical_DC/1','Optical_Power/1','autorouting','on')
add_line(mdl,'Optical_Power/1','Photodiode/1','autorouting','on')
add_line(mdl,'Photodiode/1','TIA/1','autorouting','on')

% lock-in
add_line(mdl,'TIA/1','LockIn_Mixer/1','autorouting','on')
add_line(mdl,'Reference_Normalize/1','LockIn_Mixer/2','autorouting','on')
add_line(mdl,'LockIn_Mixer/1','LockIn_LPF/1','autorouting','on')
add_line(mdl,'LockIn_LPF/1','Normalize/1','autorouting','on')
add_line(mdl,'LockIn_LPF/1','Save_LockIn_LPF/1','autorouting','on')

% estymacja
add_line(mdl,'Normalize/1','Omega_linear/1','autorouting','on')
add_line(mdl,'Normalize/1','Limit_asin/1','autorouting','on')
add_line(mdl,'Limit_asin/1','asin/1','autorouting','on')
add_line(mdl,'asin/1','Omega_est/1','autorouting','on')

% zapis i podglad
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

disp("")
disp("Model FOG_v2.slx zostal utworzony.")

%% ============================================================
% TEST BAZOWY: 1 deg/s, 20 kHz
%% ============================================================

disp("")
disp("==============================================")
disp(" WALIDACJA BAZOWA: 1 deg/s, 20 kHz")
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
beta_sim = ...
    (max(delta_ts.Data(idx_beta)) - min(delta_ts.Data(idx_beta)))/2;

fprintf("Omega zadane       = %.9f deg/s\n",Omega_deg_s)
fprintf("Omega zmierzone    = %.9f deg/s\n",omega_measured)
fprintf("Blad Omega         = %.9f deg/s\n",omega_measured-Omega_deg_s)
fprintf("beta teoria        = %.9f rad\n",beta_eff)
fprintf("beta symulacja     = %.9f rad\n",beta_sim)
fprintf("blad beta          = %.9g rad\n",beta_sim-beta_eff)

%% ============================================================
% SWEEP CZESTOTLIWOSCI MODULACJI
%% ============================================================

disp("")
disp("==============================================")
disp(" SWEEP CZESTOTLIWOSCI MODULACJI")
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

lockin_mean = zeros(N,1);

Omega_deg_s = 1;

for k = 1:N

    f_mod = freqs(k);
    phi0 = phi0_fixed;

    beta_eff = ...
        2*phi0*abs(sin(pi*f_mod*tau));

    delay_efficiency(k) = ...
        abs(sin(pi*f_mod*tau));

    beta_theory(k) = beta_eff;

    phi0_required(k) = ...
        beta_target / ...
        (2*abs(sin(pi*f_mod*tau)));

    K_ref = 1/beta_eff;

    J1beta = besselj(1,beta_eff);

    J1_value(k) = J1beta;
    J1_abs(k) = abs(J1beta);

    if abs(J1beta) < 1e-4
        warning( ...
            "f_mod = %.3f kHz: J1(beta) blisko zera. Wynik Omega moze byc zle uwarunkowany.", ...
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

    omega_measured_f(k) = ...
        mean(omega_ts.Data(idx_omega));

    omega_error_f(k) = ...
        omega_measured_f(k) - Omega_deg_s;

    beta_measured(k) = ...
        (max(delta_ts.Data(idx_beta)) - ...
         min(delta_ts.Data(idx_beta)))/2;

    beta_error(k) = ...
        beta_measured(k) - beta_theory(k);

    lockin_mean(k) = ...
        mean(lock_ts.Data(idx_lock));

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
    lockin_mean, ...
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
    'LockIn_LPF_mean' ...
    });

disp("")
disp(results)

%% ------------------------------------------------------------
% ZAPIS WYNIKOW
%% ------------------------------------------------------------

writetable(results,'FOG_v2_frequency_sweep.csv')

baseline = table( ...
    f_design/1e3, ...
    phi0_fixed, ...
    beta_target, ...
    beta_sim, ...
    Omega_deg_s, ...
    omega_measured, ...
    omega_measured-Omega_deg_s, ...
    'VariableNames', ...
    { ...
    'f_mod_kHz', ...
    'phi0_rad', ...
    'beta_target_rad', ...
    'beta_symulacja_rad', ...
    'Omega_zadane_deg_s', ...
    'Omega_zmierzone_deg_s', ...
    'Blad_Omega_deg_s' ...
    });

writetable(baseline,'FOG_v2_baseline.csv')

%% ------------------------------------------------------------
% WYKRES 1 - BETA VS CZESTOTLIWOSC
%% ------------------------------------------------------------

figure('Name','FOG v2 - beta vs f_mod')

plot( ...
    freqs/1e3, ...
    beta_theory, ...
    'o-', ...
    'LineWidth',1.5)

hold on

plot( ...
    freqs/1e3, ...
    beta_measured, ...
    's--', ...
    'LineWidth',1.5)

grid on

xlabel('f_{mod} [kHz]')
ylabel('\beta [rad]')

legend( ...
    'teoria', ...
    'symulacja', ...
    'Location','best')

title('FOG v2 - roznicowa amplituda modulacji')

%% ------------------------------------------------------------
% WYKRES 2 - WYMAGANE PHI0
%% ------------------------------------------------------------

figure('Name','FOG v2 - wymagane phi0')

plot( ...
    freqs/1e3, ...
    phi0_required, ...
    'o-', ...
    'LineWidth',1.5)

grid on

xlabel('f_{mod} [kHz]')
ylabel('\phi_0 wymagane [rad]')

title('Amplituda PZT potrzebna dla \beta = 1.84 rad')

%% ------------------------------------------------------------
% WYKRES 3 - CZULOSC PIERWSZEJ HARMONICZNEJ
%% ------------------------------------------------------------

figure('Name','FOG v2 - J1(beta)')

plot( ...
    freqs/1e3, ...
    J1_abs, ...
    'o-', ...
    'LineWidth',1.5)

grid on

xlabel('f_{mod} [kHz]')
ylabel('|J_1(\beta)|')

title('FOG v2 - wzgledna czulosc demodulacji 1. harmonicznej')

%% ------------------------------------------------------------
% WYKRES 4 - BLAD OMEGA
%% ------------------------------------------------------------

figure('Name','FOG v2 - blad Omega')

plot( ...
    freqs/1e3, ...
    omega_error_f, ...
    'o-', ...
    'LineWidth',1.5)

grid on

xlabel('f_{mod} [kHz]')
ylabel('Blad \Omega [deg/s]')

title('FOG v2 - blad estymacji dla \Omega = 1 deg/s')

%% ------------------------------------------------------------
% PODSUMOWANIE
%% ------------------------------------------------------------

save_system(mdl)
open_system(mdl)

disp("")
disp("==============================================")
disp(" FOG v2 - SYMULACJA ZAKONCZONA")
disp("==============================================")
disp("")
disp("Utworzono:")
disp("  FOG_v2.slx")
disp("  FOG_v2_baseline.csv")
disp("  FOG_v2_frequency_sweep.csv")
disp("")
disp("Kluczowa interpretacja:")
disp("  f_opt maksymalizuje amplitudowy czynnik opoznienia")
disp("  |sin(pi*f_mod*tau)|, ale nie musi maksymalizowac")
disp("  czulosci lock-in, bo ta zalezy rowniez od J1(beta).")
disp("")
