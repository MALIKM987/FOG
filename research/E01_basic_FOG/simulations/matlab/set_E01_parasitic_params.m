function params=set_E01_parasitic_params(delay_ps,eta,phase_rad,model)
%SET_E01_PARASITIC_PARAMS Parameterize the SAME Simulink stray optical path.
%
%   set_E01_parasitic_params(0.2,4e-4,0.8)
%   set_E01_parasitic_params(1.0,4e-4,0.8)
%
% Inputs: excess path delay in ps; parasitic fraction of source power;
%         relative phase at central wavelength in rad.
%
% Recalculates gamma from LASER/ASE spectral samples and updates every
% dependent Simulink block. This changes the current .slx ONLY after a
% backup and after user has saved their own modifications.
%
% NOT full distributed Rayleigh backscatter, PMD or Kerr effect.
if nargin<1 || isempty(delay_ps),delay_ps=1;end
if nargin<2 || isempty(eta),eta=4e-4;end
if nargin<3 || isempty(phase_rad),phase_rad=0.8;end
if nargin<4 || isempty(model),model='FOG_E01_SIMULINK';end
model=char(model);

validateattributes(delay_ps,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
validateattributes(eta,{'numeric'}, ...
    {'scalar','real','finite','>=',0,'<',1});
validateattributes(phase_rad,{'numeric'}, ...
    {'scalar','real','finite'});

here=fileparts(mfilename('fullpath'));
if ~bdIsLoaded(model)
    file=fullfile(here,[model '.slx']);
    assert(isfile(file),'Nie znaleziono pliku modelu %s.',file);
    load_system(file);
end
assert(getSimulinkBlockHandle( ...
    [model '/Tor pasozytniczy - odbicie'])~=-1, ...
    'Brak toru pasozytniczego; dodaj add_E01_parasitics().');
assert(strcmp(get_param(model,'Dirty'),'off'), ...
    ['Zapisz najpierw zmiany w schemacie: ', ...
     'save_system(''%s'').'],model);

modelFile=get_param(model,'FileName');
if ~isempty(modelFile) && isfile(modelFile)
    backup=[modelFile '.' datestr(now,'yyyymmdd_HHMMSS_FFF') '.bak'];
    [copied,msg]=copyfile(modelFile,backup);
    assert(copied,'Nie mozna wykonac kopii modelu: %s',msg);
    fprintf('Kopia sprzed zmiany parametrow: %s\n',backup);
end

cfg=E01_config();
kinds={'LASER','ASE'};
gammas=zeros(1,2);
nu0=cfg.c_m_s/(cfg.lambda0_nm*1e-9);
for k=1:2
    src=E01_source(cfg,kinds{k});
    coherence=sum(src.weights.*exp(1i*2*pi* ...
        (src.nu_Hz-nu0)*delay_ps*1e-12));
    gammas(k)=min(1,abs(coherence));
    srcBlock=[model '/' kinds{k} ' - zrodlo/' ...
        'Spojnosc drogi pasozytniczej'];
    set_param(srcBlock,'Value',sprintf('%.17g',gammas(k)));
end
stray=[model '/Tor pasozytniczy - odbicie'];
complexCoeff=sqrt(eta)*exp(1i*phase_rad);
set_param([stray '/Amplituda odbicia i faza'],'Gain', ...
    sprintf('(%.17g+1i*(%.17g))',real(complexCoeff),imag(complexCoeff)));
set_param([stray '/Eta odbicia'],'Gain',sprintf('%.17g',eta));
set_param(stray,'UserData',struct( ...
    'delay_ps',delay_ps,'power_fraction',eta, ...
    'phase_rad',phase_rad), ...
    'UserDataPersistent','on');
set_param(model,'SimulationCommand','update');
save_system(model);

fprintf('\nTor pasozytniczy: delay %.4g ps, eta %.4g, theta %.4g rad.\n', ...
    delay_ps,eta,phase_rad);
fprintf('Spojnosc LASER %.7g, ASE %.7g.\n',gammas(1),gammas(2));
if gammas(2)>0
    fprintf('Iloraz spojnosci LASER/ASE = %.5g.\n',gammas(1)/gammas(2));
end
params=struct('delay_ps',delay_ps,'eta',eta, ...
    'phase_rad',phase_rad,'coherence_abs',gammas);
end
