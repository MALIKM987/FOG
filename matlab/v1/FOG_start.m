%% ============================================================
% FOG_start.m
% Interferometric Fiber Optic Gyroscope - model v1
% MATLAB / Simulink R2023b
%
% Omega -> Sagnac -> phase modulation -> interference
%       -> photodiode -> TIA -> lock-in -> Omega_est
%% ============================================================

clc
close all
bdclose('all')

disp("==============================================")
disp(" FOG v1 - MODEL INTERFEROMETRYCZNY")
disp("==============================================")

%% ------------------------------------------------------------
% PARAMETRY FIZYCZNE
%% ------------------------------------------------------------

c = 299792458;           % predkosc swiatla [m/s]

lambda = 1550e-9;        % dlugosc fali [m]
L      = 1000;           % dlugosc cewki [m]
D      = 0.160;          % srednia srednica cewki [m]

ng = 1.4682;             % wspolczynnik grupowy wlokna

%% ------------------------------------------------------------
% EFEKT SAGNACA
%% ------------------------------------------------------------

% Delta_phi = K_sag * Omega_rad_s
K_sag = 2*pi*L*D/(lambda*c);

% czas propagacji przez cewke
tau = ng*L/c;

% charakterystyczna czestotliwosc FOG
f_opt = 1/(2*tau);

%% ------------------------------------------------------------
% MODULACJA FAZY
%% ------------------------------------------------------------

f_mod = 20e3;            % 20 kHz

% efektywna amplituda roznicowej modulacji fazy
beta = 1.84;             % [rad]

% wymagana amplituda pojedynczego przejscia modulatora
phi0 = beta / (2*abs(sin(pi*f_mod*tau)));

%% ------------------------------------------------------------
% TOR OPTYCZNY
%% ------------------------------------------------------------

% Model:
% P(t) = Pscale * (1 + V*cos(phi))
Pscale = 20e-6;          % [W]
visibility = 1.0;        % kontrast interferencji 0...1

%% ------------------------------------------------------------
% FOTODIODA + TIA
%% ------------------------------------------------------------

Rpd  = 0.9;              % responsywnosc fotodiody [A/W]
Rtia = 20e3;             % transimpedancja [V/A]

%% ------------------------------------------------------------
% DEMODULACJA
%% ------------------------------------------------------------

fc_lp = 300;             % filtr LPF [Hz]

J1beta = besselj(1,beta);

% normalizacja wyjscia demodulatora:
% y ~= sin(Delta_phi_S)
K_norm = -1/(Pscale*visibility*Rpd*Rtia*J1beta);

% faza Sagnaca -> predkosc [deg/s]
K_phase_to_deg = (180/pi)/K_sag;

%% ------------------------------------------------------------
% INFORMACJE
%% ------------------------------------------------------------

fprintf("\nPARAMETRY CEWKI FOG\n")
fprintf("---------------------------------\n")
fprintf("lambda           = %.1f nm\n",lambda*1e9)
fprintf("L                = %.0f m\n",L)
fprintf("D                = %.1f mm\n",D*1000)
fprintf("K_sag            = %.6f rad/(rad/s)\n",K_sag)
fprintf("tau              = %.3f us\n",tau*1e6)
fprintf("f_opt            = %.2f kHz\n",f_opt/1e3)

fprintf("\nMODULACJA\n")
fprintf("---------------------------------\n")
fprintf("f_mod            = %.2f kHz\n",f_mod/1e3)
fprintf("beta             = %.3f rad\n",beta)
fprintf("phi0             = %.3f rad\n",phi0)
fprintf("J1(beta)         = %.6f\n",J1beta)

fprintf("\nSAGNAC DLA 1 deg/s\n")
fprintf("---------------------------------\n")

phi_1deg = K_sag*pi/180;
fprintf("Delta_phi        = %.6f rad\n",phi_1deg)

%% ============================================================
% BUDOWA MODELU SIMULINK
%% ============================================================

mdl = 'FOG_v1';

if bdIsLoaded(mdl)
    close_system(mdl,0)
end

if isfile([mdl '.slx'])
    delete([mdl '.slx'])
end

new_system(mdl)
open_system(mdl)

%% WEJSCIE OMEGA

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

%% EFEKT SAGNACA

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Sagnac'], ...
    'Gain','K_sag', ...
    'Position',[280 165 370 215])

%% MODULACJA FAZY

add_block( ...
    'simulink/Sources/Sine Wave', ...
    [mdl '/Phase_Modulation'], ...
    'Amplitude','beta', ...
    'Frequency','2*pi*f_mod', ...
    'Bias','0', ...
    'Phase','0', ...
    'SampleTime','0', ...
    'Position',[280 290 370 330])

%% SUMA FAZ

add_block( ...
    'simulink/Math Operations/Sum', ...
    [mdl '/Total_Phase'], ...
    'Inputs','++', ...
    'Position',[430 185 460 255])

%% INTERFERENCJA

add_block( ...
    'simulink/Math Operations/Trigonometric Function', ...
    [mdl '/Interference_cos'], ...
    'Operator','cos', ...
    'Position',[510 190 590 240])

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Visibility'], ...
    'Gain','visibility', ...
    'Position',[630 190 710 240])

add_block( ...
    'simulink/Math Operations/Bias', ...
    [mdl '/Optical_DC'], ...
    'Bias','1', ...
    'Position',[750 190 830 240])

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Optical_Power'], ...
    'Gain','Pscale', ...
    'Position',[870 190 960 240])

%% FOTODIODA

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Photodiode'], ...
    'Gain','Rpd', ...
    'Position',[1000 190 1090 240])

%% TIA

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/TIA'], ...
    'Gain','Rtia', ...
    'Position',[1130 190 1210 240])

%% REFERENCJA LOCK-IN

add_block( ...
    'simulink/Sources/Sine Wave', ...
    [mdl '/Reference_20kHz'], ...
    'Amplitude','1', ...
    'Frequency','2*pi*f_mod', ...
    'Bias','0', ...
    'Phase','0', ...
    'SampleTime','0', ...
    'Position',[1010 330 1110 370])

%% MNOZENIE SYNCHRONICZNE

add_block( ...
    'simulink/Math Operations/Product', ...
    [mdl '/LockIn_Mixer'], ...
    'Position',[1260 210 1310 270])

%% FILTR LP

add_block( ...
    'simulink/Continuous/Transfer Fcn', ...
    [mdl '/LockIn_LPF'], ...
    'Numerator','2*pi*fc_lp', ...
    'Denominator','[1 2*pi*fc_lp]', ...
    'Position',[1360 215 1470 265])

%% NORMALIZACJA

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Normalize'], ...
    'Gain','K_norm', ...
    'Position',[1510 215 1590 265])

%% ESTYMACJA LINIOWA

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Omega_linear'], ...
    'Gain','K_phase_to_deg', ...
    'Position',[1650 120 1750 170])

%% ESTYMACJA NIELINIOWA

add_block( ...
    'simulink/Discontinuities/Saturation', ...
    [mdl '/Limit_asin'], ...
    'UpperLimit','0.999999', ...
    'LowerLimit','-0.999999', ...
    'Position',[1640 245 1730 295])

add_block( ...
    'simulink/Math Operations/Trigonometric Function', ...
    [mdl '/asin'], ...
    'Operator','asin', ...
    'Position',[1770 245 1840 295])

add_block( ...
    'simulink/Math Operations/Gain', ...
    [mdl '/Omega_est'], ...
    'Gain','K_phase_to_deg', ...
    'Position',[1880 245 1980 295])

%% DISPLAY

add_block( ...
    'simulink/Sinks/Display', ...
    [mdl '/Omega_est_Display'], ...
    'Position',[2040 240 2140 300])

%% ZAPIS DO WORKSPACE

add_block( ...
    'simulink/Sinks/To Workspace', ...
    [mdl '/Save_Omega'], ...
    'VariableName','omega_est_ts', ...
    'SaveFormat','Timeseries', ...
    'Position',[2040 330 2140 370])

add_block( ...
    'simulink/Sinks/To Workspace', ...
    [mdl '/Save_Linear'], ...
    'VariableName','omega_linear_ts', ...
    'SaveFormat','Timeseries', ...
    'Position',[1840 100 1940 140])

%% SCOPE

add_block( ...
    'simulink/Signal Routing/Mux', ...
    [mdl '/Mux'], ...
    'Inputs','2', ...
    'Position',[2040 80 2050 150])

add_block( ...
    'simulink/Sinks/Scope', ...
    [mdl '/Scope'], ...
    'Position',[2100 90 2160 150])

%% ============================================================
% POLACZENIA
%% ============================================================

add_line(mdl,'Omega_deg_s/1','deg_to_rad/1','autorouting','on')
add_line(mdl,'deg_to_rad/1','Sagnac/1','autorouting','on')

add_line(mdl,'Sagnac/1','Total_Phase/1','autorouting','on')
add_line(mdl,'Phase_Modulation/1','Total_Phase/2','autorouting','on')

add_line(mdl,'Total_Phase/1','Interference_cos/1','autorouting','on')
add_line(mdl,'Interference_cos/1','Visibility/1','autorouting','on')
add_line(mdl,'Visibility/1','Optical_DC/1','autorouting','on')
add_line(mdl,'Optical_DC/1','Optical_Power/1','autorouting','on')

add_line(mdl,'Optical_Power/1','Photodiode/1','autorouting','on')
add_line(mdl,'Photodiode/1','TIA/1','autorouting','on')

add_line(mdl,'TIA/1','LockIn_Mixer/1','autorouting','on')
add_line(mdl,'Reference_20kHz/1','LockIn_Mixer/2','autorouting','on')

add_line(mdl,'LockIn_Mixer/1','LockIn_LPF/1','autorouting','on')
add_line(mdl,'LockIn_LPF/1','Normalize/1','autorouting','on')

add_line(mdl,'Normalize/1','Omega_linear/1','autorouting','on')

add_line(mdl,'Normalize/1','Limit_asin/1','autorouting','on')
add_line(mdl,'Limit_asin/1','asin/1','autorouting','on')
add_line(mdl,'asin/1','Omega_est/1','autorouting','on')

add_line(mdl,'Omega_est/1','Omega_est_Display/1','autorouting','on')
add_line(mdl,'Omega_est/1','Save_Omega/1','autorouting','on')

add_line(mdl,'Omega_linear/1','Save_Linear/1','autorouting','on')

add_line(mdl,'Omega_deg_s/1','Mux/1','autorouting','on')
add_line(mdl,'Omega_est/1','Mux/2','autorouting','on')
add_line(mdl,'Mux/1','Scope/1','autorouting','on')

%% ============================================================
% PARAMETRY SYMULACJI
%% ============================================================

set_param(mdl, ...
    'SolverType','Fixed-step', ...
    'Solver','ode4', ...
    'FixedStep','1e-6', ...
    'StopTime','0.05', ...
    'ReturnWorkspaceOutputs','on')

save_system(mdl)

disp("")
disp("Model FOG_v1.slx zostal utworzony.")
disp("Uruchamiam test dla Omega = 1 deg/s...")

%% ============================================================
% TEST 1 deg/s
%% ============================================================

Omega_deg_s = 1;

out = sim(mdl);

omega_ts = out.get('omega_est_ts');

idx = omega_ts.Time > 0.04;
omega_final = mean(omega_ts.Data(idx));

fprintf("\nWYNIK DLA 1 deg/s\n")
fprintf("---------------------------------\n")
fprintf("zadane       = %.6f deg/s\n",Omega_deg_s)
fprintf("zmierzone    = %.6f deg/s\n",omega_final)
fprintf("blad         = %.6f deg/s\n",omega_final-Omega_deg_s)

%% ============================================================
% AUTOMATYCZNA SERIA TESTOW
%% ============================================================

disp("")
disp("==============================================")
disp(" AUTOMATYCZNE TESTY FOG")
disp("==============================================")

testOmega = [-20 -5 -1 -0.1 0 0.1 1 5 20];

N = numel(testOmega);

measured = zeros(N,1);
linear   = zeros(N,1);

for k = 1:N

    Omega_deg_s = testOmega(k);

    out = sim(mdl);

    omega_ts  = out.get('omega_est_ts');
    linear_ts = out.get('omega_linear_ts');

    idx1 = omega_ts.Time > 0.04;
    idx2 = linear_ts.Time > 0.04;

    measured(k) = mean(omega_ts.Data(idx1));
    linear(k)   = mean(linear_ts.Data(idx2));

end

error_nonlinear = measured - testOmega(:);
error_linear    = linear   - testOmega(:);

results = table( ...
    testOmega(:), ...
    linear, ...
    measured, ...
    error_linear, ...
    error_nonlinear, ...
    'VariableNames', ...
    { ...
    'Omega_zadane_deg_s', ...
    'Omega_liniowe_deg_s', ...
    'Omega_asin_deg_s', ...
    'Blad_liniowy_deg_s', ...
    'Blad_asin_deg_s' ...
    });

disp("")
disp(results)

%% ZAPIS CSV

writetable(results,'FOG_v1_results.csv')

%% WYKRES

figure('Name','FOG v1 - charakterystyka')

plot(testOmega,testOmega,'--','LineWidth',1.5)
hold on
plot(testOmega,linear,'o-','LineWidth',1.5)
plot(testOmega,measured,'s-','LineWidth',1.5)

grid on

xlabel('Zadana predkosc [deg/s]')
ylabel('Zmierzona predkosc [deg/s]')

legend( ...
    'idealna', ...
    'demodulacja liniowa', ...
    'demodulacja asin', ...
    'Location','best')

title('FOG v1 - charakterystyka pomiarowa')

%% KONIEC

save_system(mdl)
open_system(mdl)

disp("")
disp("==============================================")
disp(" FOG v1 - SYMULACJA ZAKONCZONA")
disp("==============================================")
disp("")
disp("Utworzono:")
disp("  FOG_v1.slx")
disp("  FOG_v1_results.csv")
disp("")
