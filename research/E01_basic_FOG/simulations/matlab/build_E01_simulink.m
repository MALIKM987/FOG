function modelPath = build_E01_simulink()
%BUILD_E01_SIMULINK Generate an EDITABLE Simulink optical FOG model (.slx).
% For MATLAB/Simulink R2023b. Only standard Simulink blocks are required.
% Run in MATLAB: modelPath = build_E01_simulink();
%
% NOTE: a complex scalar ENVELOPE model, not an optical-carrier/OptiSystem
% simulation. LASER and ASE have separate statistical RIN and effective
% Sagnac wavelength. True broadband coherence/backscattering is separate.
%
% Source selection: double-click the MANUAL SWITCH in the model.
% Rotation: change the "Predkosc katowa [deg/s]" Constant value.
% No edits to the historical models FOG_v1 ... FOG_v8_1.

cfg = E01_config();
laser = E01_source(cfg,"LASER");
ase = E01_source(cfg,"ASE");
Klaser = sum(laser.weights .* (2*pi*cfg.L_m*cfg.D_m ./ ...
    (laser.lambda_nm*1e-9*cfg.c_m_s)));
Kase = sum(ase.weights .* (2*pi*cfg.L_m*cfg.D_m ./ ...
    (ase.lambda_nm*1e-9*cfg.c_m_s)));

% Envelope-level approximation: source-dependent relative intensity noise.
% RIN_LASER is a DEMO parameter; ASE RIN is from effective optical width.
Be = cfg.electrical_bandwidth_Hz;
rinLaser = 10^(cfg.laser_rin_dB_Hz/10);
rinASE = source_rin_ase(cfg,ase);
if ~cfg.noise_enabled
    rinLaser=0;
    rinASE=0;
end

dt = 1/(cfg.fm_Hz*cfg.samples_per_period);
Tstop = cfg.n_periods/cfg.fm_Hz;
beta = 2*cfg.phi0_rad*sin(pi*cfg.fm_Hz*cfg.tau_s);
assert(abs(besselj(1,beta))>0.01, ...
    'Modulation index too small to support first-harmonic demodulation.');

folder=fileparts(mfilename('fullpath'));
model='FOG_E01_SIMULINK';
modelPath=fullfile(folder,[model '.slx']);

if bdIsLoaded(model)
    close_system(model,0);
end
if exist(modelPath,'file')
    % The generator only overwrites its own GENERATED FOG_E01_SIMULINK.slx.
    backup=[modelPath '.bak'];
    copyfile(modelPath,backup);
    fprintf('Kopia poprzedniego wygenerowanego schematu: %s\n',backup);
end

new_system(model);
set_param(model, ...
    'SolverType','Fixed-step','Solver','FixedStepDiscrete', ...
    'FixedStep',sprintf('%.17g',dt), ...
    'StopTime',sprintf('%.17g',Tstop), ...
    'ReturnWorkspaceOutputs','on');

% =================== MAIN OPTICAL CHAIN ================================
addSource(model,'LASER - zrodlo', [70 80 245 180], ...
    cfg.input_power_W,Klaser,rinLaser,Be,dt,105);
addSource(model,'ASE - zrodlo', [70 265 245 365], ...
    cfg.input_power_W,Kase,rinASE,Be,dt,210);

put('simulink/Signal Routing/Manual Switch', ...
    [model '/WYBOR ZRODLA - kliknij 2x'],[290 185 380 260], ...
    'sw','1');
put('simulink/Signal Routing/Demux',[model '/Pole i K Sagnaca'], ...
    [415 190 420 265],'Outputs','2');

addCoupler(model,[490 132 650 300]);
addCoil(model,[850 120 1070 470]);
addRecombination(model,[1110 195 1275 375]);
addPhotodiode(model,cfg.responsivity_A_W,[1330 205 1510 335]);

% =================== MODULATION AND SAGNAC ===========================
put('simulink/Sources/Constant', ...
    [model '/Predkosc katowa [deg_s]'],[440 540 565 590], ...
    'Value','1'); % degrees/second, EDITABLE on canvas
put('simulink/Math Operations/Gain',[model '/Stopnie na radiany'], ...
    [600 545 680 585],'Gain','pi/180');
put('simulink/Math Operations/Product',[model '/Faza Sagnaca'], ...
    [735 490 800 560],'Inputs','**');
put('simulink/Math Operations/Gain',[model '/Minus pol fazy'], ...
    [820 555 915 585],'Gain','-0.5');
put('simulink/Math Operations/Gain',[model '/Plus pol fazy'], ...
    [820 620 915 650],'Gain','0.5');

addModulator(model,cfg,[445 705 665 865]);
put('simulink/Math Operations/Sum',[model '/Faza CW'], ...
    [950 565 975 600],'Inputs','++');
put('simulink/Math Operations/Sum',[model '/Faza CCW'], ...
    [950 635 975 670],'Inputs','++');

% ===================== DETECTION AND READOUT ==========================
addDemodulation(model,cfg,dt,beta,[1570 175 1755 345]);
put('simulink/Sinks/Scope',[model '/OSC - prad fotodiody'], ...
    [1560 390 1690 445]);
put('simulink/Sinks/Scope',[model '/OSC - predkosc katowa'], ...
    [1800 235 1920 290]);

% A small intensity-noise term cannot be distinguished from the full
% Sagnac waveform on an auto-scaled scope. Subtract the exact deterministic
% (noise-free) photocurrent for the SAME Omega and modulation settings.
addNoiseDiagnostics(model,cfg,[1580 565 1800 740]);
put('simulink/Sinks/Scope',[model '/OSC - fluktuacje fotodiody [uA]'], ...
    [1845 555 2005 615]);
put('simulink/Sinks/To Workspace',[model '/Fluktuacje fotodiody - dane'], ...
    [1835 670 2000 710], ...
    'VariableName','E01_fluktuacje_fotodiody_uA', ...
    'SaveFormat','Structure with Time');

put('simulink/Sinks/To Workspace',[model '/Prad fotodiody - dane'], ...
    [1560 480 1700 515],'VariableName','E01_prad_fotodiody', ...
    'SaveFormat','Structure with Time');
put('simulink/Sinks/To Workspace',[model '/Predkosc - dane'], ...
    [1810 390 1935 425],'VariableName','E01_predkosc', ...
    'SaveFormat','Structure with Time');

% Return-path wiring: C->D, D->C. This port swap is critical.
join(model,'LASER - zrodlo/1','WYBOR ZRODLA - kliknij 2x/1');
join(model,'ASE - zrodlo/1','WYBOR ZRODLA - kliknij 2x/2');
join(model,'WYBOR ZRODLA - kliknij 2x/1','Pole i K Sagnaca/1');
join(model,'Pole i K Sagnaca/1','Sprzegacz 2x2 - podzial/1');
join(model,'Pole i K Sagnaca/2','Faza Sagnaca/1');
join(model,'Predkosc katowa [deg_s]/1','Stopnie na radiany/1');
join(model,'Stopnie na radiany/1','Faza Sagnaca/2');
join(model,'Faza Sagnaca/1','Minus pol fazy/1');
join(model,'Faza Sagnaca/1','Plus pol fazy/1');
join(model,'Minus pol fazy/1','Faza CW/2');
join(model,'Plus pol fazy/1','Faza CCW/2');
join(model,'Modulator - dwa momenty/1','Faza CW/1');
join(model,'Modulator - dwa momenty/2','Faza CCW/1');
join(model,'Faza CW/1','Cewka SMF - CW i CCW/3');
join(model,'Faza CCW/1','Cewka SMF - CW i CCW/4');
join(model,'Sprzegacz 2x2 - podzial/1','Cewka SMF - CW i CCW/1');
join(model,'Sprzegacz 2x2 - podzial/2','Cewka SMF - CW i CCW/2');
join(model,'Cewka SMF - CW i CCW/1','Sprzegacz 2x2 - powrot/2');
join(model,'Cewka SMF - CW i CCW/2','Sprzegacz 2x2 - powrot/1');
join(model,'Sprzegacz 2x2 - powrot/1','Fotodioda - port B/1');
join(model,'Fotodioda - port B/1','Demodulacja synchroniczna/1');
join(model,'Pole i K Sagnaca/2','Demodulacja synchroniczna/2');
join(model,'Fotodioda - port B/1','OSC - prad fotodiody/1');
join(model,'Fotodioda - port B/1','Prad fotodiody - dane/1');
join(model,'Fotodioda - port B/1','Diagnostyka szumu fotodiody/1');
join(model,'Faza CW/1','Diagnostyka szumu fotodiody/2');
join(model,'Faza CCW/1','Diagnostyka szumu fotodiody/3');
join(model,'Diagnostyka szumu fotodiody/1', ...
    'OSC - fluktuacje fotodiody [uA]/1');
join(model,'Diagnostyka szumu fotodiody/1', ...
    'Fluktuacje fotodiody - dane/1');
join(model,'Demodulacja synchroniczna/1','OSC - predkosc katowa/1');
join(model,'Demodulacja synchroniczna/1','Predkosc - dane/1');

try
    set_param(model,'ZoomFactor','FitSystem');
catch
    % Display-only property differs across releases; model still functions.
end
try
    set_param(model,'SimulationCommand','update');
catch ME
    % Keep the generated model open for inspection if update is rejected.
    warning('E01:Compile','Model could not be updated: %s',ME.message);
end
save_system(model,modelPath);
open_system(model);

fprintf('\nGotowy schemat Simulink: %s\n',modelPath);
fprintf('Zrodlo: podwojne klikniecie bloku WYBOR ZRODLA.\n');
fprintf('Omega: zmien Constant Predkosc katowa [deg_s].\n');
fprintf('Potem nacisnij Run. Zawartosc to model obwiedni optycznej.\n');
end

% ======================= BLOCK BUILDERS ==============================

function addNoiseDiagnostics(root,cfg,pos)
% Detector-level residual: measured - EXACT analytical ideal Sagnac current.
% This is a time-resolved visualization of source fluctuations, not a
% simulation of optical backscattering, polarization or shot noise.
s=mkSubsystem(root,'Diagnostyka szumu fotodiody',pos);
put('simulink/Sources/In1',[s '/Prad zmierzony [A]'], ...
    [35 60 65 80]);
put('simulink/Sources/In1',[s '/Faza CW [rad]'], ...
    [35 170 65 190]);
put('simulink/Sources/In1',[s '/Faza CCW [rad]'], ...
    [35 275 65 295]);
put('simulink/Math Operations/Sum',[s '/Roznica faz CCW - CW'], ...
    [140 205 175 260],'Inputs','+-');
put('simulink/Math Operations/Trigonometric Function', ...
    [s '/Cosinus roznicy faz'],[235 207 330 255], ...
    'Operator','cos');
put('simulink/Sources/Constant',[s '/Stala 1'], ...
    [235 325 315 355],'Value','1');
put('simulink/Math Operations/Sum',[s '/1 minus cosinus'], ...
    [385 235 420 290],'Inputs','+-');
put('simulink/Math Operations/Gain',[s '/R razy P przez 2'], ...
    [480 238 585 283], ...
    'Gain',sprintf('%.17g',cfg.responsivity_A_W*cfg.input_power_W/2));
put('simulink/Math Operations/Sum',[s '/Prad minus srednia'], ...
    [660 105 695 160],'Inputs','+-');
put('simulink/Math Operations/Gain',[s '/Ampery na mikroampery'], ...
    [750 107 870 155],'Gain','1e6');
put('simulink/Sinks/Out1',[s '/Szum fotodiody [uA]'], ...
    [935 120 970 140]);
join(s,'Faza CCW [rad]/1','Roznica faz CCW - CW/1');
join(s,'Faza CW [rad]/1','Roznica faz CCW - CW/2');
join(s,'Roznica faz CCW - CW/1','Cosinus roznicy faz/1');
join(s,'Stala 1/1','1 minus cosinus/1');
join(s,'Cosinus roznicy faz/1','1 minus cosinus/2');
join(s,'1 minus cosinus/1','R razy P przez 2/1');
join(s,'Prad zmierzony [A]/1','Prad minus srednia/1');
join(s,'R razy P przez 2/1','Prad minus srednia/2');
join(s,'Prad minus srednia/1','Ampery na mikroampery/1');
join(s,'Ampery na mikroampery/1','Szum fotodiody [uA]/1');
end

function addSource(root,label,pos,P,K,rin,Be,dt,seed)
s=mkSubsystem(root,label,pos);
% First output: sqrt(P*(1+N)), i.e. normalized optical field amplitude.
% Second output: K_sagnac for the spectral SOURCE model.
put('simulink/Sources/Constant',[s '/Moc srednia [W]'], ...
    [35 105 115 145],'Value',sprintf('%.17g',P));
put('simulink/Sources/Constant',[s '/Poziom 1'], ...
    [35 35 115 65],'Value','1');
put('simulink/Sources/Random Number',[s '/Szum intensywnosci RIN'], ...
    [25 195 130 240], ...
    'Mean','0','Variance',sprintf('%.17g',rin*Be), ...
    'Seed',num2str(seed),'SampleTime',sprintf('%.17g',dt));
put('simulink/Math Operations/Sum',[s '/1 plus RIN'], ...
    [165 75 190 115],'Inputs','++');
put('simulink/Math Operations/Product',[s '/Moc chwilowa'], ...
    [220 95 250 140],'Inputs','**');
put('simulink/Discontinuities/Saturation',[s '/Bez ujemnej mocy'], ...
    [275 97 340 140], 'LowerLimit','0', 'UpperLimit','inf');
put('simulink/Math Operations/Sqrt',[s '/Pierwiastek mocy'], ...
    [370 93 425 145],'Operator','sqrt');
put('simulink/Sources/Constant',[s '/K Sagnaca dla zrodla'], ...
    [365 195 445 230],'Value',sprintf('%.17g',K));
put('simulink/Signal Routing/Mux',[s '/Pole i K'], ...
    [485 115 490 205],'Inputs','2');
put('simulink/Sinks/Out1',[s '/Wyjscie'],[540 155 570 175]);
join(s,'Poziom 1/1','1 plus RIN/1');
join(s,'Szum intensywnosci RIN/1','1 plus RIN/2');
join(s,'1 plus RIN/1','Moc chwilowa/1');
join(s,'Moc srednia [W]/1','Moc chwilowa/2');
join(s,'Moc chwilowa/1','Bez ujemnej mocy/1');
join(s,'Bez ujemnej mocy/1','Pierwiastek mocy/1');
join(s,'Pierwiastek mocy/1','Pole i K/1');
join(s,'K Sagnaca dla zrodla/1','Pole i K/2');
join(s,'Pole i K/1','Wyjscie/1');
end

function addCoupler(root,pos)
s=mkSubsystem(root,'Sprzegacz 2x2 - podzial',pos);
put('simulink/Sources/In1',[s '/E zrodla'],[40 110 65 130]);
put('simulink/Math Operations/Gain',[s '/t = 1 przez sqrt2'],...
    [130 45 240 90],'Gain','1/sqrt(2)');
put('simulink/Math Operations/Gain',[s '/k = j przez sqrt2'],...
    [130 165 240 210],'Gain','1i/sqrt(2)');
put('simulink/Sinks/Out1',[s '/Do CW - port C'],[300 55 330 75]);
put('simulink/Sinks/Out1',[s '/Do CCW - port D'],[300 170 330 190]);
join(s,'E zrodla/1','t = 1 przez sqrt2/1');
join(s,'E zrodla/1','k = j przez sqrt2/1');
join(s,'t = 1 przez sqrt2/1','Do CW - port C/1');
join(s,'k = j przez sqrt2/1','Do CCW - port D/1');
end

function addCoil(root,pos)
% ONE physical coil subsystem with two reciprocal directions.
% Optical input from C propagates CW -> returns at D.
% Optical input from D propagates CCW -> returns at C.
s=mkSubsystem(root,'Cewka SMF - CW i CCW',pos);
put('simulink/Sources/In1',[s '/Wejscie z C'],[30 48 60 68]);
put('simulink/Sources/In1',[s '/Wejscie z D'],[30 258 60 278]);
put('simulink/Sources/In1',[s '/Faza CW'],[30 128 60 148]);
put('simulink/Sources/In1',[s '/Faza CCW'],[30 338 60 358]);
addPhasePath(s,'Propagacja CW - do D',[130 38 320 178]);
addPhasePath(s,'Propagacja CCW - do C',[130 243 320 383]);
put('simulink/Sinks/Out1',[s '/Wyjscie CW do D'], ...
    [390 88 420 108]);
put('simulink/Sinks/Out1',[s '/Wyjscie CCW do C'], ...
    [390 294 420 314]);
join(s,'Wejscie z C/1','Propagacja CW - do D/1');
join(s,'Faza CW/1','Propagacja CW - do D/2');
join(s,'Wejscie z D/1','Propagacja CCW - do C/1');
join(s,'Faza CCW/1','Propagacja CCW - do C/2');
join(s,'Propagacja CW - do D/1','Wyjscie CW do D/1');
join(s,'Propagacja CCW - do C/1','Wyjscie CCW do C/1');
end

function addPhasePath(root,label,pos)
s=mkSubsystem(root,label,pos);
put('simulink/Sources/In1',[s '/Amplituda wejsciowa'],[30 45 60 65]);
put('simulink/Sources/In1',[s '/Faza po obiegu'],[30 165 60 185]);
put('simulink/Math Operations/Gain',[s '/j razy faza'], ...
    [105 145 190 190],'Gain','1i');
put('simulink/Math Operations/Math Function',[s '/Exp(j faza)'], ...
    [240 145 330 190],'Operator','exp');
put('simulink/Math Operations/Product',[s '/E razy Exp(j faza)'], ...
    [385 78 430 145],'Inputs','**');
put('simulink/Sinks/Out1',[s '/Pole po obiegu'],[485 110 520 130]);
join(s,'Faza po obiegu/1','j razy faza/1');
join(s,'j razy faza/1','Exp(j faza)/1');
join(s,'Exp(j faza)/1','E razy Exp(j faza)/2');
join(s,'Amplituda wejsciowa/1','E razy Exp(j faza)/1');
join(s,'E razy Exp(j faza)/1','Pole po obiegu/1');
end

function addRecombination(root,pos)
s=mkSubsystem(root,'Sprzegacz 2x2 - powrot',pos);
put('simulink/Sources/In1',[s '/Pole CCW - wraca do C'], ...
    [35 55 65 75]);
put('simulink/Sources/In1',[s '/Pole CW - wraca do D'], ...
    [35 190 65 210]);
put('simulink/Math Operations/Gain',[s '/j przez sqrt2'], ...
    [130 50 240 95],'Gain','1i/sqrt(2)');
put('simulink/Math Operations/Gain',[s '/1 przez sqrt2'], ...
    [130 175 240 220],'Gain','1/sqrt(2)');
put('simulink/Math Operations/Sum',[s '/E_B = suma pol'], ...
    [295 112 320 155],'Inputs','++');
put('simulink/Sinks/Out1',[s '/Pole na porcie B'], ...
    [390 125 425 145]);
join(s,'Pole CCW - wraca do C/1','j przez sqrt2/1');
join(s,'Pole CW - wraca do D/1','1 przez sqrt2/1');
join(s,'j przez sqrt2/1','E_B = suma pol/1');
join(s,'1 przez sqrt2/1','E_B = suma pol/2');
join(s,'E_B = suma pol/1','Pole na porcie B/1');
end

function addPhotodiode(root,R,pos)
s=mkSubsystem(root,'Fotodioda - port B',pos);
put('simulink/Sources/In1',[s '/Pole E_B'],[30 85 65 105]);
put('simulink/Math Operations/Math Function', ...
    [s '/Modul kwadrat pola'],[110 75 230 120], ...
    'Operator','magnitude^2');
put('simulink/Math Operations/Gain', ...
    [s '/Responsywnosc [A na W]'],[260 75 375 120], ...
    'Gain',sprintf('%.17g',R));
put('simulink/Sinks/Out1',[s '/Prad fotodiody [A]'], ...
    [435 88 470 108]);
join(s,'Pole E_B/1','Modul kwadrat pola/1');
join(s,'Modul kwadrat pola/1','Responsywnosc [A na W]/1');
join(s,'Responsywnosc [A na W]/1','Prad fotodiody [A]/1');
end

function addModulator(root,cfg,pos)
s=mkSubsystem(root,'Modulator - dwa momenty',pos);
w=2*pi*cfg.fm_Hz;
dt=1/(cfg.fm_Hz*cfg.samples_per_period);
put('simulink/Sources/Sine Wave',[s '/Faza CW: t minus tau'], ...
    [50 48 170 98], ...
    'Amplitude',sprintf('%.17g',cfg.phi0_rad), ...
    'Frequency',sprintf('%.17g',w), ...
    'Phase',sprintf('%.17g',-w*cfg.tau_s), ...
    'SampleTime',sprintf('%.17g',dt));
put('simulink/Sources/Sine Wave',[s '/Faza CCW: t'], ...
    [50 178 170 228], ...
    'Amplitude',sprintf('%.17g',cfg.phi0_rad), ...
    'Frequency',sprintf('%.17g',w), ...
    'Phase','0','SampleTime',sprintf('%.17g',dt));
put('simulink/Sinks/Out1',[s '/Faza CW'],[245 60 275 80]);
put('simulink/Sinks/Out1',[s '/Faza CCW'],[245 188 275 208]);
join(s,'Faza CW: t minus tau/1','Faza CW/1');
join(s,'Faza CCW: t/1','Faza CCW/1');
end

function addDemodulation(root,cfg,dt,beta,pos)
s=mkSubsystem(root,'Demodulacja synchroniczna',pos);
w=2*pi*cfg.fm_Hz;
a=exp(-dt/(4/cfg.fm_Hz));  % four-period low-pass time constant
% Reference sin(w*t+pi/2-w*tau/2) = cos(w*(t-tau/2)).
put('simulink/Sources/In1',[s '/Prad fotodiody [A]'], ...
    [30 38 60 58]);
put('simulink/Sources/In1',[s '/K Sagnaca wybranego zrodla'], ...
    [30 280 60 300]);
put('simulink/Sources/Sine Wave',[s '/Odniesienie lock-in'], ...
    [25 160 160 210], ...
    'Amplitude','1','Frequency',sprintf('%.17g',w), ...
    'Phase',sprintf('%.17g',pi/2-w*cfg.tau_s/2), ...
    'SampleTime',sprintf('%.17g',dt));
put('simulink/Math Operations/Product',[s '/Mnozenie synchroniczne'], ...
    [220 70 260 120],'Inputs','**');
put('simulink/Math Operations/Gain',[s '/Razy 2'], ...
    [305 78 365 115],'Gain','2');
put('simulink/Discrete/Discrete Transfer Fcn',[s '/Filtr dolnoprzepustowy'], ...
    [420 77 545 125], ...
    'Numerator',sprintf('[%.17g]',1-a), ...
    'Denominator',sprintf('[1 %.17g]',-a), ...
    'SampleTime',sprintf('%.17g',dt));
% For small Omega, sin(K*Omega) ~= K*Omega. Source-specific
% Sagnac scale is selected with the SAME manual switch as optical input.
Kbase = cfg.responsivity_A_W*cfg.input_power_W* ...
    besselj(1,beta);
put('simulink/Math Operations/Divide',[s '/Dziel przez K zrodla'], ...
    [585 70 625 135]);
put('simulink/Math Operations/Gain',[s '/Na stopnie na sekunde'], ...
    [655 76 775 125], ...
    'Gain',sprintf('%.17g',180/(pi*Kbase)));
put('simulink/Sinks/Out1',[s '/Omega oszacowane [deg_s]'], ...
    [835 88 865 110]);
join(s,'Prad fotodiody [A]/1','Mnozenie synchroniczne/1');
join(s,'Odniesienie lock-in/1','Mnozenie synchroniczne/2');
join(s,'Mnozenie synchroniczne/1','Razy 2/1');
join(s,'Razy 2/1','Filtr dolnoprzepustowy/1');
join(s,'Filtr dolnoprzepustowy/1','Dziel przez K zrodla/1');
join(s,'K Sagnaca wybranego zrodla/1','Dziel przez K zrodla/2');
join(s,'Dziel przez K zrodla/1','Na stopnie na sekunde/1');
join(s,'Na stopnie na sekunde/1','Omega oszacowane [deg_s]/1');
end

function rin = source_rin_ase(cfg,src)
% Effective optical noise bandwidth from power spectral density.
lambda=src.lambda_nm(:)*1e-9;
s=src.S_W_per_nm(:);
d_nm=src.lambda_nm(2)-src.lambda_nm(1);
q=ones(size(lambda));q([1 end])=0.5;
den=sum(q.*s.^2.*(1e9*lambda.^2/cfg.c_m_s))*d_nm;
Beff=cfg.input_power_W^2/den;
rin=2/(cfg.ase_effective_mode_count*Beff);
end

function s=mkSubsystem(root,name,pos)
s=[root '/' name];
add_block('simulink/Ports & Subsystems/Subsystem',s,'Position',pos);
Simulink.SubSystem.deleteContents(s);
end

function put(lib,path,pos,varargin)
add_block(lib,path,'Position',pos,varargin{:});
end

function join(sub,source,dest)
add_line(sub,source,dest,'autorouting','on');
end
