function out = run_E01(sourceType, outputDir)
%RUN_E01 Explore the isolated FOG-E01-MIS in MATLAB R2023b.
%
% out = run_E01();          read source from E01_config.m
% out = run_E01("BOTH");   compare source variants without changing FOG
% out = run_E01("LASER");   laser only
% out = run_E01("ASE");     broadband source only
% out = run_E01("BOTH", "C:\FOG_results");   custom output folder
%
% Run from the repository root:
% addpath(fullfile('research','E01_basic_FOG','simulations','matlab'));
% out = run_E01("BOTH");
%
% NOTE: all sources are DEMO spectra. Figures are MODEL outputs, not lab
% measurements or a validated noise simulation.

here = fileparts(mfilename('fullpath'));
cfg = E01_config();
if nargin<1 || isempty(sourceType)
    sourceType = cfg.source_type;
end
sourceType = upper(string(sourceType));
if ~ismember(sourceType, ["LASER","ASE","BOTH"])
    error('E01:Mode','Choose "LASER", "ASE", or "BOTH".');
end
if nargin<2 || isempty(outputDir)
    if cfg.parasitic_enabled
        caseName = 'single_stray_demo';
    elseif cfg.noise_enabled
        caseName = 'source_noise_demo';
    else
        caseName = 'deterministic';
    end
    outputDir = fullfile(here,'..','..','results', ...
        ['EXP_E01_' lower(char(sourceType)) '_' caseName]);
end
if ~isfolder(outputDir)
    mkdir(outputDir);
end

if sourceType=="BOTH"
    kinds=["LASER","ASE"];
else
    kinds=sourceType;
end
if cfg.show_figures
    visibility='on';
else
    visibility='off';
end
models=cell(1,numel(kinds));

for k=1:numel(kinds)
    source=E01_source(cfg,kinds(k));
    models{k}=E01_model(cfg,source);
end
out.cfg=cfg;
out.sourceMode=char(sourceType);
out.models=models;

fprintf('\nFOG-E01-MIS | SOURCE SWITCH DEMO (no polarization / noise)\n');
fprintf('Coil L=%.0f m, D=%.0f mm, tau=%.6f us, fm=%.3f kHz\n', ...
    cfg.L_m,cfg.D_m*1000,cfg.tau_s*1e6,cfg.fm_Hz/1e3);
fprintf('Source mode: %s | input power: %.3f mW | beta: %.3f rad\n', ...
    char(sourceType),cfg.input_power_W*1e3,models{1}.beta_rad);
fprintf('K_sag(lambda0)=%.9f rad/(rad/s)\n', ...
    2*pi*cfg.L_m*cfg.D_m/(cfg.lambda0_nm*1e-9*cfg.c_m_s));
fprintf('Parasitic delayed field model: %d (0 = off, 1 = toy model)\n', ...
    cfg.parasitic_enabled);
fprintf('Source/photodiode fluctuations enabled: %d, bandwidth %.0f kHz\n', ...
    cfg.noise_enabled,cfg.electrical_bandwidth_Hz/1e3);
fprintf('WARNING: DEMO spectra and toy stray-field model, NOT laboratory measurements.\n\n');

% Figure 1: spectra. Two panels show wide view and local peak zoom.
fig=figure('Visible',visibility,'Name','E01: Spectrum','Color','w');
subplot(1,2,1);hold on;grid on;
for k=1:numel(models)
    s=models{k}.source;
    plot(s.lambda_nm, s.S_W_per_nm/max(s.S_W_per_nm), ...
        'DisplayName', s.kind,'LineWidth',1.6);
end
xlim([cfg.lambda0_nm-2*cfg.ase_fwhm_nm, ...
      cfg.lambda0_nm+2*cfg.ase_fwhm_nm]);
xlabel('Wavelength [nm]'); ylabel('Normalized spectral density');
title('Same total source power');legend('show');
subplot(1,2,2);hold on;grid on;
for k=1:numel(models)
    s=models{k}.source;
    plot(s.lambda_nm,s.S_W_per_nm,'DisplayName',s.kind,'LineWidth',1.6);
end
xlabel('Wavelength [nm]');ylabel('S_{\lambda} [W/nm]');
title('Actual spectral density scales');legend('show');
save_plot(fig,outputDir,'01_spectra.png',cfg.save_outputs,cfg.show_figures);

% Figure 2: phase timing, independent of the source.
m=models{1}; t_us=m.t_s*1e6;
fig=figure('Visible',visibility,'Name','E01: Phase modulation','Color','w');
plot(t_us,m.phase_late_rad,'LineWidth',1.2,'DisplayName','phase(t)');
hold on;grid on;
plot(t_us,m.phase_early_rad,'LineWidth',1.2,'DisplayName','phase(t-tau)');
plot(t_us,m.phase_diff_rad,'LineWidth',1.6,'DisplayName','differential phase');
xlim([0,4/cfg.fm_Hz*1e6]);xlabel('Time [us]');ylabel('Phase [rad]');
title('Both beams see one modulator at different times');legend('show');
save_plot(fig,outputDir,'02_modulator.png',cfg.save_outputs,cfg.show_figures);

% Figure 3: SELECTED SOURCE photodiode for omega=-1,0,+1 deg/s.
fig=figure('Visible',visibility,'Name','E01: Photodiode current','Color','w');
hold on;grid on;
testCases=[-1 0 1];
for j=1:numel(testCases)
    idx=find(abs(m.omega_deg_s-testCases(j))<1e-12,1);
    if isempty(idx), continue; end
    plot(t_us,m.current_measured_A(idx,:)*1e6,'LineWidth',1.4, ...
        'DisplayName',sprintf('%+.0f deg/s',testCases(j)));
end
xlim([0,4/cfg.fm_Hz*1e6]);
xlabel('Time [us]');ylabel('Photodiode current [uA]');
title(['DETECTOR B | SOURCE = ' m.source.kind]);legend('show');
if cfg.parasitic_enabled
    idx=find(m.omega_deg_s==cfg.omega_plot_deg_s,1);
    if ~isempty(idx)
        plot(t_us,m.current_A(idx,:)*1e6,'k--', ...
            'LineWidth',1.2,'DisplayName','ideal FOG reference');
    end
    legend('show');
end
save_plot(fig,outputDir,'03_photodiode.png',cfg.save_outputs,cfg.show_figures);

% Figure 4: PHOTOdiode comparison and ideal lock-in curve.
fig=figure('Visible',visibility,'Name','E01: Source comparison','Color','w');
subplot(2,1,1);hold on;grid on;
for k=1:numel(models)
    q=models{k};
    idx=find(abs(q.omega_deg_s-1)<1e-12,1);
    plot(q.t_s*1e6,q.current_observed_A(idx,:)*1e6,'LineWidth',1.3, ...
        'DisplayName',q.source.kind);
end
xlim([0,4/cfg.fm_Hz*1e6]);
xlabel('Time [us]');ylabel('Current at +1 deg/s [uA]');
title('Detected current at +1 deg/s (source change only)');legend('show');
subplot(2,1,2);hold on;grid on;
for k=1:numel(models)
    q=models{k};
    plot(q.sweep_deg_s,q.lockin_sweep_A*1e6,'LineWidth',1.5, ...
        'DisplayName',q.source.kind);
end
xlabel('Rotation [deg/s]');ylabel('First lock-in harmonic [uA]');
title('IDEAL lock-in response (stray field excluded)');legend('show');
save_plot(fig,outputDir,'04_laser_vs_ase.png',cfg.save_outputs,cfg.show_figures);

% Figure 5: normalized coherence is a separate parasitic-path illustration.
fig=figure('Visible',visibility,'Name','E01: Coherence','Color','w');
hold on;grid on;
for k=1:numel(models)
    q=models{k};
    plot(q.coherence_delay_ps,q.coherence_abs,'LineWidth',1.5, ...
        'DisplayName',q.source.kind);
end
xlabel('ADDITIONAL path delay [ps]');ylabel('|gamma(delta t)|');
title('Surrogate: visibility of delayed parasitic field');
ylim([0 1.05]);legend('show');
save_plot(fig,outputDir,'05_coherence_surrogate.png', ...
    cfg.save_outputs,cfg.show_figures);

% Figure 6: linear approximation illustrates open-loop nonlinearity.
fig=figure('Visible',visibility,'Name','E01: Estimate linearity','Color','w');
hold on;grid on;
plot(cfg.omega_sweep_deg_s,cfg.omega_sweep_deg_s,'k--', ...
     'LineWidth',1,'DisplayName','ideal Omega');
for k=1:numel(models)
    q=models{k};
    plot(q.sweep_deg_s,q.est_sweep_deg_s,'LineWidth',1.5, ...
         'DisplayName',[q.source.kind ' linear estimate']);
end
xlabel('True Omega [deg/s]');ylabel('Estimated Omega [deg/s]');
title('Small-signal estimator, not absolute metrology');legend('show');
save_plot(fig,outputDir,'06_linear_estimate.png', ...
    cfg.save_outputs,cfg.show_figures);

% Figure 7: source-dependent stochastic fluctuations near the photodiode.
% We deliberately plot the difference to the deterministic signal: otherwise
% ASE noise can be hard to see against the large phase-modulated photocurrent.
fig=figure('Visible',visibility,'Name','E01: Source intensity noise','Color','w');
subplot(2,1,1);hold on;grid on;
noiseRms_uA=zeros(1,numel(models));
noiseNames=cell(1,numel(models));
for k=1:numel(models)
    q=models{k};
    idx=find(abs(q.omega_deg_s-1)<1e-12,1);
    residual=q.current_measured_A(idx,:)-q.current_observed_A(idx,:);
    plot(q.t_s*1e6,residual*1e6,'LineWidth',1.1, ...
        'DisplayName',q.source.kind);
    noiseRms_uA(k)=sqrt(mean(residual.^2))*1e6;
    noiseNames{k}=q.source.kind;
end
xlim([0,4/cfg.fm_Hz*1e6]);
xlabel('Time [us]');ylabel('Random current deviation [uA]');
title('Photodiode fluctuations: noisy current minus deterministic current');
legend('show');
subplot(2,1,2);grid on;
bar(noiseRms_uA);
set(gca,'XTick',1:numel(models),'XTickLabel',noiseNames);
ylabel('RMS deviation [uA]');
title(sprintf('Illustrative noise in %.0f kHz detector bandwidth', ...
    cfg.electrical_bandwidth_Hz/1e3));
save_plot(fig,outputDir,'07_source_noise.png', ...
    cfg.save_outputs,cfg.show_figures);

% Reproducible text/CSV/JSON outputs with named units.
for k=1:numel(models)
    q=models{k};
    fprintf('%s: FWHM=%.4f nm | I1 ideal (+1)=%.6f uA, deterministic(+1)=%.6f uA | source RIN=%.2f dB/Hz\n', ...
        q.source.kind,q.source.fwhm_nm, ...
        q.lockin_A(q.omega_deg_s==1)*1e6, ...
        q.lockin_observed_A(q.omega_deg_s==1)*1e6, ...
        q.noise_rin_dB_Hz);

    if cfg.save_outputs
        spectrum=table(q.source.lambda_nm,q.source.S_W_per_nm, ...
            q.source.weights,'VariableNames', ...
            {'lambda_nm','spectral_density_W_per_nm','quadrature_weight'});
        writetable(spectrum,fullfile(outputDir, ...
            ['spectrum_' lower(q.source.kind) '.csv']));
        idxN=find(q.omega_deg_s==-1,1);
        idx0=find(q.omega_deg_s==0,1);
        idxP=find(q.omega_deg_s==1,1);
        signals=table(q.t_s(:),q.phase_late_rad(:), ...
            q.phase_early_rad(:),q.phase_diff_rad(:), ...
            q.current_A(idxN,:).',q.current_A(idx0,:).', ...
            q.current_A(idxP,:).','VariableNames', ...
            {'time_s','phase_m_t_rad','phase_m_delayed_rad', ...
             'phase_diff_rad','i_minus1_ideal_A','i_zero_ideal_A','i_plus1_ideal_A'});
        signals.i_minus1_observed_A=q.current_observed_A(idxN,:).';
        signals.i_zero_observed_A=q.current_observed_A(idx0,:).';
        signals.i_plus1_observed_A=q.current_observed_A(idxP,:).';
        signals.i_minus1_noisy_A=q.current_measured_A(idxN,:).';
        signals.i_zero_noisy_A=q.current_measured_A(idx0,:).';
        signals.i_plus1_noisy_A=q.current_measured_A(idxP,:).';
        signals.i_plus1_source_rin_A=q.noise_rin_A(idxP,:).';
        signals.i_plus1_shot_A=q.noise_shot_A(idxP,:).';
        writetable(signals,fullfile(outputDir, ...
            ['waveform_' lower(q.source.kind) '.csv']));
        sweep=table(q.sweep_deg_s(:),q.lockin_sweep_A(:), ...
            q.est_sweep_deg_s(:),'VariableNames', ...
            {'omega_true_deg_s','lockin_I1_A','omega_linear_est_deg_s'});
        writetable(sweep,fullfile(outputDir, ...
            ['sweep_' lower(q.source.kind) '.csv']));
        coherence=table(q.coherence_delay_ps(:),q.coherence_abs(:),...
            'VariableNames',{'extra_delay_ps','gamma_abs'});
        writetable(coherence,fullfile(outputDir, ...
            ['coherence_' lower(q.source.kind) '.csv']));
    end
end

if cfg.save_outputs
    settings=cfg;
    settings.sourceMode=char(sourceType);
    settings.matlabVersion=version;
    fid=fopen(fullfile(outputDir,'config.json'),'w');
    assert(fid>0,'Could not create config.json');
    cleaner=onCleanup(@()fclose(fid));
    fprintf(fid,'%s\n',jsonencode(settings,'PrettyPrint',true));
    clear cleaner
    fid=fopen(fullfile(outputDir,'README.txt'),'w');
    assert(fid>0,'Could not create report README');
    fprintf(fid,['FOG-E01-MIS -- DETERMINISTIC, IDEAL OR SINGLE-STRAY-FIELD DEMO.\n', ...
        'Source parameters are hypothetical, not measurements.\n', ...
        'Includes ILLUSTRATIVE source-RIN and photodiode shot noise if enabled.\n', ...
        'No distributed Rayleigh backscatter, real polarization or electronics.\n', ...
        'Observed diode includes OPTIONAL single delayed stray field (toy model).\n', ...
        'Ideal/observed photodiode currents saved as separate columns.\n', ...
        'CSV units specified in every column name; check config.json.\n', ...
        'This file was generated by run_E01.m; MATLAB %s.\n'], version);
    fclose(fid);
    fprintf('\nSaved demonstration results: %s\n',outputDir);
end
end

function save_plot(fig,dirPath,fileName,saveOutputs,showFigures)
if saveOutputs
    exportgraphics(fig,fullfile(dirPath,fileName),'Resolution',160);
end
if ~showFigures
    close(fig);
end
end
