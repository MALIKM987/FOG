function ok=test_E01_parasitics()
%TEST_E01_PARASITICS Test integrated (not standalone) Simulink stray path.
%
% Run locally after add_E01_parasitics() or build_E01_simulink():
%    assert(test_E01_parasitics());
%
% Does not overwrite schematic or destroy other subsystem settings.
% Experimental coherence suppression test only for the DEFAULT 1ps case.
% The test is NOT hardware validation, Rayleigh model or FOG metrology.
here=fileparts(mfilename('fullpath'));
addpath(here,'-begin');
model='FOG_E01_SIMULINK';
if ~bdIsLoaded(model)
    file=fullfile(here,[model '.slx']);
    assert(isfile(file),'Nie ma lokalnego FOG_E01_SIMULINK.slx.');
    load_system(file);
end
path=[model '/Tor pasozytniczy - odbicie'];
assert(getSimulinkBlockHandle(path)~=-1, ...
    'Nie ma toru odbicia. Wykonaj add_E01_parasitics().');

srcSwitch=[model '/WYBOR ZRODLA - kliknij 2x'];
straySwitch=[model '/Odbicie 0=wyl 1=wl'];
omega=[model '/Predkosc katowa [deg_s]'];
nr1=[model '/LASER - zrodlo/Szum intensywnosci RIN'];
nr2=[model '/ASE - zrodlo/Szum intensywnosci RIN'];
old={get_param(srcSwitch,'sw'), ...
    get_param(straySwitch,'Value'),get_param(omega,'Value'), ...
    get_param(nr1,'Variance'),get_param(nr2,'Variance')};
restore=onCleanup(@()restoreAll( ...
    srcSwitch,straySwitch,omega,nr1,nr2,old));

set_param(model,'SimulationCommand','update');
% Suppress stochastic differences to isolate coherent parasitic effect.
set_param(omega,'Value','0');
set_param(nr1,'Variance','0');
set_param(nr2,'Variance','0');

response=zeros(2,2);
sources={'1','0'}; % 1=LASER,0=ASE
for s=1:2
    set_param(srcSwitch,'sw',sources{s});
    for p=1:2
        set_param(straySwitch,'Value',num2str(p-1));
        out=sim(model);
        pd=out.get('E01_prad_fotodiody');
        i=pd.signals.values(:);
        t=pd.time(:);
        assert(all(isfinite(i))&&all(i>=-1e-10), ...
            'Niepoprawny prad fotodiody.');
        cfg=E01_config();
        if t(end)>=cfg.n_periods/cfg.fm_Hz-1e-12
            t=t(1:end-1);
            i=i(1:end-1);
        end
        ref=cos(2*pi*cfg.fm_Hz*(t-cfg.tau_s/2));
        response(s,p)=2*mean(i.*ref);
    end
end

coherentChange=abs(response(:,2)-response(:,1));
meta=get_param(path,'UserData');
if ~isempty(meta)&&isstruct(meta)&& ...
        isfield(meta,'delay_ps') && ...
        abs(meta.delay_ps-1)<1e-9
    assert(coherentChange(1)>10*coherentChange(2), ...
        'Default 1ps case: LASER parasitic response not stronger than ASE.');
end

fprintf('I1 - roznica od odbicia przy Omega=0:\n');
fprintf('  LASER: %.6g nA\n',coherentChange(1)*1e9);
fprintf('  ASE:   %.6g nA\n',coherentChange(2)*1e9);
fprintf('PASS: cztery symulacje istniejącego modelu poprawne.\n');
ok=true;
end

function restoreAll(sw,st,om,n1,n2,v)
set_param(sw,'sw',v{1});
set_param(st,'Value',v{2});
set_param(om,'Value',v{3});
set_param(n1,'Variance',v{4});
set_param(n2,'Variance',v{5});
end
