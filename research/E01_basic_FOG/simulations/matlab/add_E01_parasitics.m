function blockName=add_E01_parasitics(model,saveAfter)
%ADD_E01_PARASITICS Add one controlled delayed parasitic DETECTOR-side path.
%
% For an existing FOG_E01_SIMULINK model, save personal edits first:
%   save_system('FOG_E01_SIMULINK');
%   add_E01_parasitics();
%
% The new path models SINGLE parasitic optical leakage with power eta,
% excess delay dt, fixed relative phase and spectral coherence gamma.
% It is a reduced optical source-coherence illustration; NOT a physical
% distributed Rayleigh/birefringence/scattering/energy-conserving network.
%
% P_observed = |E_B + sqrt(eta) E0 gamma exp(j theta)|^2
%                + eta |E0|^2*(1-|gamma|^2).
% Coherent overlap has intensity gamma^2; incoherent background is kept.
% Optical carrier phase at lambda0 is included in theta (set by user).
%
% 0=ideal FOG, 1=single stray field, in top-level Constant.
% Source-specific gamma is selected with the SAME source Manual Switch.
%
% Maintains existing primary source port, spectra analyzer output 2 & 3,
% and signal analysis To Workspace blocks. Does not edit E01_config.m.
if nargin<1 || isempty(model)
    model='FOG_E01_SIMULINK';
end
if nargin<2
    saveAfter=true;
end
model=char(model);
here=fileparts(mfilename('fullpath'));
if ~bdIsLoaded(model)
    file=fullfile(here,[model '.slx']);
    assert(isfile(file),'Brak zapisanego schematu: %s',file);
    load_system(file);
end
if saveAfter && strcmp(get_param(model,'Dirty'),'on')
    error('E01:DirtyModel', ...
        ['Zapisz najpierw swoje zmiany: ', ...
         'save_system(''%s'');'],model);
end

blockName=[model '/Tor pasozytniczy - odbicie'];
if getSimulinkBlockHandle(blockName)~=-1
    fprintf('Tor pasozytniczy juz istnieje w schemacie.\n');
    return;
end
cfg=E01_config();
assert(cfg.parasitic_delay_ps>=0 && ...
    cfg.parasitic_power_fraction>=0 && ...
    cfg.parasitic_power_fraction<1, ...
    'Niepoprawne parametry pojedynczej drogi pasozytniczej.');

% BEFORE modifying a saved existing diagram, preserve user's custom .slx.
if saveAfter
    modelFile=get_param(model,'FileName');
    if ~isempty(modelFile) && isfile(modelFile)
        stamp=datestr(now,'yyyymmdd_HHMMSS_FFF');
        backup=[modelFile '.' stamp '.bak'];
        [ok,msg]=copyfile(modelFile,backup);
        assert(ok,'Nie mozna wykonac kopii schematu: %s',msg);
        fprintf('Kopia bezpieczenstwa schematu: %s\n',backup);
    end
end

% In the source's optical data vector append |gamma(dt)| as the THIRD
% channel; E0 and K remain channels 1 and 2 (real scalar).
kinds={'LASER','ASE'};
for k=1:numel(kinds)
    s=[model '/' kinds{k} ' - zrodlo'];
    assert(getSimulinkBlockHandle(s)~=-1, ...
        'Brak zrodla %s.',kinds{k});
    src=E01_source(cfg,kinds{k});
    nu0=cfg.c_m_s/(cfg.lambda0_nm*1e-9);
    tau=cfg.parasitic_delay_ps*1e-12;
    gamma=sum(src.weights .* ...
        exp(1i*2*pi*(src.nu_Hz-nu0)*tau));
    gammaAbs=min(1,abs(gamma));
    mux=[s '/Pole i K'];
    set_param(mux,'Inputs','3');
    put('simulink/Sources/Constant',[s '/Spojnosc drogi pasozytniczej'], ...
        [355 245 460 275],'Value',sprintf('%.17g',gammaAbs));
    connect(s,'Spojnosc drogi pasozytniczej/1','Pole i K/3');
    fprintf('%s: |gamma(%.3f ps)| = %.8g\n', ...
        kinds{k},cfg.parasitic_delay_ps,gammaAbs);
end

set_param([model '/Pole i K Sagnaca'],'Outputs','3');

% The reference E0 comes from existing Demux/1; gamma from Demux/3.
put('simulink/Sources/Constant',[model '/Odbicie 0=wyl 1=wl'], ...
    [1110 600 1250 640],'Value','1');

s=mkSubsystem(model,'Tor pasozytniczy - odbicie', ...
    [1310 365 1530 540]);
put('simulink/Sources/In1',[s '/Pole glowne E_B'], ...
    [30 45 60 65]);
put('simulink/Sources/In1',[s '/Amplituda E0'], ...
    [30 145 60 165]);
put('simulink/Sources/In1',[s '/Spojnosc gamma'], ...
    [30 245 60 265]);
put('simulink/Sources/In1',[s '/Odbicie wlaczone'], ...
    [30 345 60 365]);

% E_stray,coh = E0 * gamma * ON * sqrt(eta)*exp(j theta)
eta=cfg.parasitic_power_fraction;
theta=cfg.parasitic_phase_rad;
put('simulink/Math Operations/Product',[s '/E0 razy gamma'], ...
    [125 175 160 220],'Inputs','**');
put('simulink/Math Operations/Gain',[s '/Amplituda odbicia i faza'], ...
    [215 175 340 220], ...
    'Gain',sprintf('(%.17g+%.17gi)', ...
        sqrt(eta)*cos(theta),sqrt(eta)*sin(theta)));
put('simulink/Math Operations/Product',[s '/Wlacz pole odbite'], ...
    [390 190 425 235],'Inputs','**');
put('simulink/Math Operations/Sum',[s '/Suma pol w detektorze'], ...
    [480 85 515 135],'Inputs','++');
put('simulink/Sinks/Out1',[s '/Pole z odbiciem'], ...
    [775 98 810 118]);

% Incoherent optical background power:
% P_extra = eta * E0^2 * (1 - gamma^2) * ON
put('simulink/Math Operations/Math Function', ...
    [s '/Kwadrat amplitudy E0'],[125 305 220 350], ...
    'Operator','square');
put('simulink/Math Operations/Math Function', ...
    [s '/Kwadrat spojnosci'],[125 405 220 450], ...
    'Operator','square');
put('simulink/Sources/Constant',[s '/Jednosc'], ...
    [235 505 305 535],'Value','1');
put('simulink/Math Operations/Sum',[s '/1 minus gamma2'], ...
    [325 395 360 450],'Inputs','+-');
put('simulink/Math Operations/Product',[s '/Moc niespojna'], ...
    [425 365 465 425],'Inputs','***');
put('simulink/Math Operations/Gain',[s '/Eta odbicia'], ...
    [535 375 635 425],'Gain',sprintf('%.17g',eta));
put('simulink/Sinks/Out1',[s '/Tlo niespojne [W]'], ...
    [775 390 810 410]);

connect(s,'Amplituda E0/1','E0 razy gamma/1');
connect(s,'Spojnosc gamma/1','E0 razy gamma/2');
connect(s,'E0 razy gamma/1','Amplituda odbicia i faza/1');
connect(s,'Amplituda odbicia i faza/1','Wlacz pole odbite/1');
connect(s,'Odbicie wlaczone/1','Wlacz pole odbite/2');
connect(s,'Pole glowne E_B/1','Suma pol w detektorze/1');
connect(s,'Wlacz pole odbite/1','Suma pol w detektorze/2');
connect(s,'Suma pol w detektorze/1','Pole z odbiciem/1');
connect(s,'Amplituda E0/1','Kwadrat amplitudy E0/1');
connect(s,'Spojnosc gamma/1','Kwadrat spojnosci/1');
connect(s,'Jednosc/1','1 minus gamma2/1');
connect(s,'Kwadrat spojnosci/1','1 minus gamma2/2');
connect(s,'Kwadrat amplitudy E0/1','Moc niespojna/1');
connect(s,'1 minus gamma2/1','Moc niespojna/2');
connect(s,'Odbicie wlaczone/1','Moc niespojna/3');
connect(s,'Moc niespojna/1','Eta odbicia/1');
connect(s,'Eta odbicia/1','Tlo niespojne [W]/1');

% Expand photodiode to measure coherent mixed power + noninterfering power.
photo=[model '/Fotodioda - port B'];
put('simulink/Sources/In1',[photo '/Tlo niespojne [W]'], ...
    [30 190 65 210]);
delete_line(photo,'Modul kwadrat pola/1','Responsywnosc [A na W]/1');
put('simulink/Math Operations/Sum',[photo '/Moc sumaryczna'], ...
    [250 145 285 190],'Inputs','++');
connect(photo,'Modul kwadrat pola/1','Moc sumaryczna/1');
connect(photo,'Tlo niespojne [W]/1','Moc sumaryczna/2');
connect(photo,'Moc sumaryczna/1','Responsywnosc [A na W]/1');

% Redirect the signal from recombination via the parasitic optical path.
delete_line(model,'Sprzegacz 2x2 - powrot/1','Fotodioda - port B/1');
connect(model,'Sprzegacz 2x2 - powrot/1', ...
    'Tor pasozytniczy - odbicie/1');
connect(model,'Pole i K Sagnaca/1', ...
    'Tor pasozytniczy - odbicie/2');
connect(model,'Pole i K Sagnaca/3', ...
    'Tor pasozytniczy - odbicie/3');
connect(model,'Odbicie 0=wyl 1=wl/1', ...
    'Tor pasozytniczy - odbicie/4');
connect(model,'Tor pasozytniczy - odbicie/1', ...
    'Fotodioda - port B/1');
connect(model,'Tor pasozytniczy - odbicie/2', ...
    'Fotodioda - port B/2');

% Reflect actual detector departures from pure Sagnac, including stray field.
% Previous diagnostic is "residual" rather than pure source RIN when ON.
fprintf(['UWAGA: OSC fluktuacji po wlaczeniu odbicia pokazuje tez ', ...
    'zaklocenie koherentne, nie tylko szum RIN.\n']);

if saveAfter
    set_param(model,'SimulationCommand','update');
    save_system(model);
    open_system(model);
end
fprintf('Dodano tor odbicia. Zmien Odbicie 0=wyl 1=wl (0 lub 1).\n');
end

function s=mkSubsystem(root,label,pos)
s=[root '/' label];
add_block('simulink/Ports & Subsystems/Subsystem',s,'Position',pos);
Simulink.SubSystem.deleteContents(s);
end
function put(lib,path,pos,varargin)
add_block(lib,path,'Position',pos,varargin{:});
end
function connect(sys,src,dst)
add_line(sys,src,dst,'autorouting','on');
end
