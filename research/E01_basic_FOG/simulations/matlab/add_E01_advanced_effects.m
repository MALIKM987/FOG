function blockPath=add_E01_advanced_effects(model,saveAfter)
%ADD_E01_ADVANCED_EFFECTS Rayleigh proxy and Kerr inside existing E01 .slx.
% MATLAB R2023b, standard Simulink blocks.
%
% For an already open, saved schematic:
%   save_system('FOG_E01_SIMULINK');
%   add_E01_advanced_effects();
%
% For a fresh generator use add_E01_advanced_effects(model,false).
% No simulation or angular sweep starts in this function.
% No polarization, no optical insertion losses. Rayleigh is a finite
% effective extra-path proxy; Kerr is effective differential phase.
if nargin<1||isempty(model),model='FOG_E01_SIMULINK';end
if nargin<2,saveAfter=true;end
model=char(model);
here=fileparts(mfilename('fullpath'));
if ~bdIsLoaded(model)
    file=fullfile(here,[model '.slx']);
    assert(isfile(file),'Nie znaleziono modelu: %s',file);
    load_system(file);
end
if saveAfter
    assert(strcmp(get_param(model,'Dirty'),'off'), ...
        'Najpierw zapisz zmiany: save_system(''%s'');',model);
end
blockPath=[model '/Rayleigh - efektywne drogi'];
if getSimulinkBlockHandle(blockPath)~=-1
    fprintf('Rayleigh i Kerr sa juz w modelu. Nie zmieniam schematu.\n');
    return
end
assert(getSimulinkBlockHandle([model '/Tor pasozytniczy - odbicie'])~=-1, ...
    'Najpierw dodaj tor odbicia: add_E01_parasitics().');
if saveAfter
    modelFile=get_param(model,'FileName');
    if ~isempty(modelFile) && isfile(modelFile)
        backup=[modelFile '.' datestr(now,'yyyymmdd_HHMMSS_FFF') '.bak'];
        [copied,msg]=copyfile(modelFile,backup);
        assert(copied,'Blad kopiowania schematu: %s',msg);
        fprintf('Kopia schematu: %s\n',backup);
    end
end

cfg=E01_config();

% Existing source output Mux has: 1 E0, 2 K_Sagnac, 3 reflection gamma.
% Append 4 Re C_ray, 5 Im C_ray, 6 P_incoherent_ray.
for j=1:2
    kinds={'LASER','ASE'};
    srcBlock=[model '/' kinds{j} ' - zrodlo'];
    src=E01_source(cfg,kinds{j});
    ray=E01_rayleigh_coeff(cfg,src);
    set_param([srcBlock '/Pole i K'],'Inputs','6');
    set_param([model '/Pole i K Sagnaca'],'Outputs','6');
    put('simulink/Sources/Constant',[srcBlock '/Rayleigh Re C'], ...
        [355 465 465 495],'Value',sprintf('%.17g',real(ray.coherent)));
    put('simulink/Sources/Constant',[srcBlock '/Rayleigh Im C'], ...
        [355 525 465 555],'Value',sprintf('%.17g',imag(ray.coherent)));
    put('simulink/Sources/Constant',[srcBlock '/Rayleigh moc niespojna'], ...
        [355 585 465 615],'Value', ...
        sprintf('%.17g',ray.incoherent));
    connect(srcBlock,'Rayleigh Re C/1','Pole i K/4');
    connect(srcBlock,'Rayleigh Im C/1','Pole i K/5');
    connect(srcBlock,'Rayleigh moc niespojna/1','Pole i K/6');
    fprintf('%s: Rayleigh Re(C)=%.4g Im(C)=%.4g q=%.4g\n', ...
        kinds{j},real(ray.coherent),imag(ray.coherent),ray.incoherent);
end

put('simulink/Sources/Constant',[model '/Rayleigh 0=wyl 1=wl'], ...
    [1140 680 1290 720],'Value','1');
put('simulink/Sources/Constant',[model '/Kerr 0=wyl 1=wl'], ...
    [650 935 800 980],'Value','1');

% Rayleigh subsystem with coherent and noninterfering optical components.
s=mkSubsystem(model,'Rayleigh - efektywne drogi', ...
    [1540 615 1770 770]);
put('simulink/Sources/In1',[s '/Glowne pole z odbiciem'], ...
    [30 40 60 60]);
put('simulink/Sources/In1',[s '/E0'],[30 130 60 150]);
put('simulink/Sources/In1',[s '/Re C'],[30 220 60 240]);
put('simulink/Sources/In1',[s '/Im C'],[30 300 60 320]);
put('simulink/Sources/In1',[s '/Ray q'],[30 390 60 410]);
put('simulink/Sources/In1',[s '/Wlacz Rayleigh'], ...
    [30 480 60 500]);
put('simulink/Math Operations/Gain',[s '/j razy Im C'], ...
    [135 290 220 330],'Gain','1i');
put('simulink/Math Operations/Sum',[s '/Kompleksowe C'], ...
    [270 220 300 265],'Inputs','++');
put('simulink/Math Operations/Product',[s '/E0 razy C'], ...
    [355 205 390 250],'Inputs','**');
put('simulink/Math Operations/Product',[s '/Wlacz spojnosc'], ...
    [445 190 480 245],'Inputs','**');
put('simulink/Math Operations/Sum',[s '/E z Rayleigh'], ...
    [540 80 570 125],'Inputs','++');
put('simulink/Sinks/Out1',[s '/Pole wynikowe'], ...
    [710 95 740 115]);

put('simulink/Math Operations/Math Function',[s '/E0 kwadrat'], ...
    [145 385 230 430],'Operator','square');
put('simulink/Math Operations/Product',[s '/Dodatkowa moc Ray'], ...
    [365 380 405 450],'Inputs','***');
put('simulink/Sinks/Out1',[s '/Moc niespojna Ray'], ...
    [710 408 740 428]);

connect(s,'Im C/1','j razy Im C/1');
connect(s,'Re C/1','Kompleksowe C/1');
connect(s,'j razy Im C/1','Kompleksowe C/2');
connect(s,'Kompleksowe C/1','E0 razy C/2');
connect(s,'E0/1','E0 razy C/1');
connect(s,'E0 razy C/1','Wlacz spojnosc/1');
connect(s,'Wlacz Rayleigh/1','Wlacz spojnosc/2');
connect(s,'Glowne pole z odbiciem/1','E z Rayleigh/1');
connect(s,'Wlacz spojnosc/1','E z Rayleigh/2');
connect(s,'E z Rayleigh/1','Pole wynikowe/1');
connect(s,'E0/1','E0 kwadrat/1');
connect(s,'E0 kwadrat/1','Dodatkowa moc Ray/1');
connect(s,'Ray q/1','Dodatkowa moc Ray/2');
connect(s,'Wlacz Rayleigh/1','Dodatkowa moc Ray/3');
connect(s,'Dodatkowa moc Ray/1','Moc niespojna Ray/1');

% Route the already mixed reflection field through Rayleigh before diode.
delete_line(model,'Tor pasozytniczy - odbicie/1','Fotodioda - port B/1');
connect(model,'Tor pasozytniczy - odbicie/1', ...
    'Rayleigh - efektywne drogi/1');
connect(model,'Pole i K Sagnaca/1','Rayleigh - efektywne drogi/2');
connect(model,'Pole i K Sagnaca/4','Rayleigh - efektywne drogi/3');
connect(model,'Pole i K Sagnaca/5','Rayleigh - efektywne drogi/4');
connect(model,'Pole i K Sagnaca/6','Rayleigh - efektywne drogi/5');
connect(model,'Rayleigh 0=wyl 1=wl/1','Rayleigh - efektywne drogi/6');
connect(model,'Rayleigh - efektywne drogi/1','Fotodioda - port B/1');

% Photodiode already had two optical inputs, main field and reflection
% incoherent power; add the third port for Rayleigh incoherent background.
photo=[model '/Fotodioda - port B'];
put('simulink/Sources/In1',[photo '/Moc Rayleigh niespojna [W]'], ...
    [30 265 65 285]);
set_param([photo '/Moc sumaryczna'],'Inputs','+++');
connect(photo,'Moc Rayleigh niespojna [W]/1','Moc sumaryczna/3');
connect(model,'Rayleigh - efektywne drogi/2','Fotodioda - port B/3');

% Kerr: beta_NL L P Delta, a DIFFERENTIAL nonlinear phase due to a
% hypothesized asymmetry of CW/CCW optical powers. Zero for equal powers.
% Tie it to the selected source E0(t)^2, including its modeled source RIN.
kerrCoeff=cfg.kerr_gamma_Wm * cfg.L_m * ...
    cfg.kerr_relative_power_imbalance;
put('simulink/Math Operations/Math Function', ...
    [model '/Kerr E0^2'],[575 855 670 890], ...
    'Operator','square');
put('simulink/Math Operations/Gain',[model '/Kerr gamma L asymetria'], ...
    [710 842 890 895],'Gain',sprintf('%.17g',kerrCoeff));
put('simulink/Math Operations/Product',[model '/Kerr wlacz faze'], ...
    [940 845 985 895],'Inputs','**');
put('simulink/Math Operations/Gain',[model '/Kerr minus pol'], ...
    [1030 850 1110 890],'Gain','-0.5');
put('simulink/Math Operations/Gain',[model '/Kerr plus pol'], ...
    [1030 925 1110 965],'Gain','0.5');
connect(model,'Pole i K Sagnaca/1','Kerr E0^2/1');
connect(model,'Kerr E0^2/1','Kerr gamma L asymetria/1');
connect(model,'Kerr gamma L asymetria/1','Kerr wlacz faze/1');
connect(model,'Kerr 0=wyl 1=wl/1','Kerr wlacz faze/2');
connect(model,'Kerr wlacz faze/1','Kerr minus pol/1');
connect(model,'Kerr wlacz faze/1','Kerr plus pol/1');
set_param([model '/Faza CW'],'Inputs','+++');
set_param([model '/Faza CCW'],'Inputs','+++');
connect(model,'Kerr minus pol/1','Faza CW/3');
connect(model,'Kerr plus pol/1','Faza CCW/3');

% No spectrum or angular curve computation is launched here.
set_param(blockPath,'UserData',struct( ...
    'rayleigh_paths',cfg.rayleigh_path_count, ...
    'rayleigh_eta',cfg.rayleigh_total_power_fraction, ...
    'rayleigh_delays_ps',cfg.rayleigh_excess_delay_ps, ...
    'kerr_gamma_Wm',cfg.kerr_gamma_Wm, ...
    'kerr_power_imbalance',cfg.kerr_relative_power_imbalance), ...
    'UserDataPersistent','on');
if saveAfter
    set_param(model,'SimulationCommand','update');
    save_system(model);
    open_system(model);
end
fprintf(['Dodano Rayleigh i Kerr. Jedna symulacja: przycisk Run.\n', ...
    'Pelna charakterystyka tylko na Twoje polecenie: ', ...
    'E01_current_layers().\n']);
end

function s=mkSubsystem(root,name,pos)
s=[root '/' name];
add_block('simulink/Ports & Subsystems/Subsystem',s,'Position',pos);
Simulink.SubSystem.deleteContents(s);
end
function put(lib,path,pos,varargin)
add_block(lib,path,'Position',pos,varargin{:});
end
function connect(sys,src,dst)
add_line(sys,src,dst,'autorouting','on');
end
