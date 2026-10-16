function report=E01_current_layers(nPoints)
%E01_CURRENT_LAYERS Jeden interaktywny wykres I_srednie(Omega).
%
% W MATLAB R2023b wpisz, wylacznie na swoje polecenie:
%    raport = E01_current_layers();   % 101 punktow, 10 warstw
%    raport = E01_current_layers(61);
%
% Ten sam uproszczony model E01: Sagnac, sprzegacz, modulator, 1 km SMF,
% dwa zrodla. WARIANTY: idealny, odbicie, Rayleigh (proxy), Kerr, wszystko.
% Krzywe sa OBLICZENIEM WIDMOWYM sredniego pradu w zalozonym modelu,
% a nie wynikami wielu uruchomien solvera .slx ani danymi laboratoryjnymi.
% NIE uruchamia sim(model) i NIE ingeruje w zapisany .slx.
%
% UWAGA: uproszczone rozproszenie Rayleigha jako N efektywnych drog
% pasozytniczych o podanych opoznieniach i losowych fazach. Nie obejmuje
% rozwiazania calkowego rozproszonego Rayleigha w 1000 m wlokna ani
% detekcji wielokrotnego rozpraszania. Kerr to efektywny bias przy
% niesymetrii mocy CW/CCW, nie pelny propagator nieliniowego NLSE.
%
% W jednym oknie jest 10 warstw; klikaj nazwy w legendzie, by je ukryc.
% Dopiero wywolanie tej funkcji liczy dane. Nigdy przez OpenFcn .slx.

cfg=E01_config();
if nargin<1||isempty(nPoints)
    nPoints=cfg.omega_layer_points;
end
validateattributes(nPoints,{'numeric'}, ...
    {'scalar','integer','>=',5,'<=',501});
assert(cfg.rayleigh_path_count>=1 && ...
    cfg.rayleigh_total_power_fraction>=0, ...
    'Niepoprawne parametry efektywnych drog Rayleigha.');
assert(cfg.parasitic_power_fraction>=0 && ...
    cfg.parasitic_power_fraction<1, ...
    'Niepoprawny udzial mocy odbitej.');

omega_deg_s=linspace(-30,30,nPoints).';
modes={'LASER','ASE'};
cases={'idealny','odbicie','Rayleigh','Kerr','wszystkie'};
power_A=zeros(nPoints,2,5);
coherence_ref=zeros(1,2);
kerr_rad=zeros(1,2);
J0=besselj(0,2*cfg.phi0_rad*sin(pi*cfg.fm_Hz*cfg.tau_s));
c=cfg.c_m_s;
P=cfg.input_power_W;
R=cfg.responsivity_A_W;

% Independent, reproducible scatterer phase ensemble. RandStream avoids
% changing user's global MATLAB RNG state.
rs=RandStream('mt19937ar','Seed',cfg.rayleigh_random_seed);
M=cfg.rayleigh_path_count;
theta=2*pi*rand(rs,1,M);
tauRay_ps=linspace(cfg.rayleigh_excess_delay_ps(1), ...
    cfg.rayleigh_excess_delay_ps(2),M);
% Equal power per effective weak path; not a real Rayleigh length density.
ampRay=sqrt(cfg.rayleigh_total_power_fraction/M);

for k=1:2
    src=E01_source(cfg,modes{k});
    nu0=c/(cfg.lambda0_nm*1e-9);
    nuDiff=src.nu_Hz(:)-nu0;
    w=src.weights(:).';
    K=2*pi*cfg.L_m*cfg.D_m./(src.lambda_nm(:)*1e-9*c);
    phiS=(omega_deg_s*pi/180)*K(:).';

    % Reference reflector with an extra optical path and phase.
    delay_s=cfg.parasitic_delay_ps*1e-12;
    Eref=sqrt(cfg.parasitic_power_fraction) * ...
        exp(1i*cfg.parasitic_phase_rad) * ...
        exp(1i*2*pi*nuDiff*delay_s);
    coherence_ref(k)=abs(sum(src.weights(:).* ...
        exp(1i*2*pi*nuDiff*delay_s)));

    % A finite ensemble of weak, independently phased parasitic paths
    % standing in for the *effective* Rayleigh contribution to the port.
    RayleighPhases=exp(1i*2*pi*(nuDiff*tauRay_ps*1e-12));
    Eray=ampRay*(RayleighPhases*exp(1i*theta(:)));

    % Simple nonlinear differential phase from imbalanced reciprocal powers.
    % With balanced CW/CCW, this Kerr contribution must vanish.
    if cfg.kerr_enabled
        phiK=cfg.kerr_gamma_Wm * cfg.L_m * ...
            P * cfg.kerr_relative_power_imbalance;
    else
        phiK=0;
    end
    kerr_rad(k)=phiK;

    for v=1:5
        % Layer selection is independent of the default E01 config switch.
        useRef=(v==2||v==5);
        useRay=(v==3||v==5) && cfg.rayleigh_enabled;
        useKerr=(v==4||v==5) && cfg.kerr_enabled;
        phi=phiS+double(useKerr)*phiK;
        stray=zeros(size(nuDiff));
        if useRef, stray=stray+Eref; end
        if useRay, stray=stray+Eray; end
        % Exact time averaging over sinusoidal DIFFERENTIAL modulation:
        % <| (1-exp(i*(phi+beta*cos(wt))))/2 |^2>
        %         = [1-J0(beta)*cos(phi)]/2;
        % <E_main>= [1-J0(beta)*exp(i*phi)]/2.
        idealMeanPower=(1-J0*cos(phi))/2;
        idealMeanField=(1-J0*exp(1i*phi))/2;
        % Include ALL cross-beatings between main field and parasitic paths
        % and between the parasitic paths, BEFORE spectral integration.
        parasiticPower=abs(stray.').^2;
        spectralPower=idealMeanPower + ...
            2*real(idealMeanField.*conj(stray.'))+ ...
            parasiticPower;
        current=R*P*(spectralPower*w.')*1e6;
        power_A(:,k,v)=current;
    end
end
assert(all(isfinite(power_A),'all') && ...
    all(power_A>-1e-9,'all'), ...
    'Model widmowy zwrocil niefinitywne lub ujemne moce.');

% ONE FIGURE ONLY. 10 clickable, independently enabled/disabled layers.
fig=figure('Name','IFOG | Prąd fotodiody od prędkości kątowej', ...
    'NumberTitle','off','Color','w');
ax=axes('Parent',fig);
hold(ax,'on');grid(ax,'on');box(ax,'on');
% Colors identify LASER/ASE; line styles identify physical cases.
colors=[0.0 0.37 0.72;0.75 0.25 0.16];
styles={':','--','-.','-','-'};
widths=[1 1.2 1.2 1.2 2.2];
lines=gobjects(2,5);
for k=1:2
    for v=1:5
        lines(k,v)=plot(ax,omega_deg_s,power_A(:,k,v), ...
            'Color',colors(k,:), ...
            'LineStyle',styles{v},'LineWidth',widths(v), ...
            'DisplayName',[modes{k} ' | ' cases{v}]);
        if v~=1 && v~=5
            lines(k,v).Visible='off'; % keep optional layers in legend
        end
    end
end
xlabel(ax,'Prędkość kątowa \Omega [°/s]');
ylabel(ax,'Średni prąd fotodiody [µA]');
title(ax,'IFOG: wpływ odbić, Rayleigha i efektu Kerra');
lgd=legend(ax,lines(:),'Location','eastoutside');
lgd.ItemHitFcn=@E01_toggle_layer;

% Save reusable numerical results and the ONE interactive .fig.
resultDir=fullfile(fileparts(mfilename('fullpath')),'..','..', ...
    'results',['EXP_E01_I_vs_Omega_' ...
    datestr(now,'yyyymmdd_HHMMSS_FFF')]);
[isMade,msg]=mkdir(resultDir);
assert(isMade,'Nie mozna utworzyc katalogu wynikow: %s',msg);
tableData=table(omega_deg_s,'VariableNames',{'Omega_deg_s'});
for k=1:2
    for v=1:5
        code={'ideal','reflection','rayleigh','kerr','all'};
        tableData.([modes{k} '_' code{v} '_uA'])=power_A(:,k,v);
    end
end
writetable(tableData,fullfile(resultDir,'prad_od_predkosci_katowej.csv'));
savefig(fig,fullfile(resultDir,'prad_od_predkosci_katowej_warstwy.fig'));

fprintf('\nIFOG: jeden wykres, 10 przelaczanych warstw. Klikaj LEGENDE.\n');
fprintf('Wyniki: %s\n',resultDir);
fprintf('Odbicie |gamma|: LASER %.5g, ASE %.5g.\n', ...
    coherence_ref(1),coherence_ref(2));
fprintf('Kerr: delta_phi ~ %.4g rad (przy asymetrii mocy %.3f).\n', ...
    kerr_rad(1),cfg.kerr_relative_power_imbalance);
fprintf('Rayleigh: %d efektywnych drog, łączny udzial mocy %.3g.\n', ...
    M,cfg.rayleigh_total_power_fraction);
fprintf(['To DEMO: bez polaryzacji, bez strat, bez pelnego ', ...
    'rozproszonego Rayleigha.\n']);

report=struct('omega_deg_s',omega_deg_s, ...
    'current_uA',power_A,'sources',{modes}, ...
    'cases',{cases},'figure',fig,'lines',lines, ...
    'csv',fullfile(resultDir,'prad_od_predkosci_katowej.csv'), ...
    'figure_file',fullfile(resultDir, ...
    'prad_od_predkosci_katowej_warstwy.fig'), ...
    'coherence_ref',coherence_ref,'kerr_rad',kerr_rad);
end
