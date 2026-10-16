function cfg = E01_config()
%E01_CONFIG Demonstration parameters for the independent FOG-E01-MIS model.
% MATLAB R2023b. All optical parameters are IDEALIZED, NOT lab measurements.
% Units are explicit in names.
% Switch the optical source here, without changing the FOG geometry.
cfg.source_type = "LASER";      % "LASER", "ASE", or "BOTH"

% Optional simplified detector-side stray optical field (NOT full Rayleigh).
% This reveals coherence effects; disable to observe ideal Sagnac alone.
cfg.parasitic_enabled = false;
cfg.parasitic_delay_ps = 1.0;       % extra path delay versus main field
cfg.parasitic_power_fraction = 4e-4;% parasitic optical power / input power
cfg.parasitic_phase_rad = 0.8;      % relative phase at lambda0
cfg.omega_plot_deg_s = 1;          % main photodiode waveform

cfg.c_m_s = 299792458;
cfg.L_m = 1000;
cfg.D_m = 0.160;
cfg.n_group = 1.4682;          % Assumed constant over the ASE spectrum
cfg.lambda0_nm = 1550;

cfg.input_power_W = 1e-3;      % Equal input power in both source modes
cfg.responsivity_A_W = 0.9;   % Constant photodiode responsivity (assumption)
cfg.laser_fwhm_nm = 0.02;     % DEMO Gaussian linewidth, not a real laser
cfg.ase_fwhm_nm = 20;        % DEMO spectrum, not laboratory ASE data
cfg.n_spectral_samples = 801;

cfg.phi0_rad = 0.92;           % Single-pass phase modulation amplitude
cfg.fm_Hz = 0;                % 0 -> proper frequency = 1/(2*tau)
cfg.n_periods = 16;
cfg.samples_per_period = 96;
cfg.omega_test_deg_s = [-10 -1 0 1 10];
cfg.omega_sweep_deg_s = linspace(-30,30,121);
cfg.coherence_delay_ps = linspace(0,10,401);
cfg.show_figures = true;
cfg.save_outputs = true;
% Source-dependent electrical photodetection noise (DEMO, not measured).
% Compare noise RMS on the diode even when the mean LASER/ASE trace overlaps.
cfg.noise_enabled = true;
cfg.electrical_bandwidth_Hz = 0.8e6; % idealized receiver noise bandwidth
cfg.laser_rin_dB_Hz = -155;          % illustrative flat laser RIN [dB/Hz]
cfg.ase_effective_mode_count = 1;    % scalar thermal ASE assumption
cfg.noise_seed = 20261016;           % reproducible random realization
cfg.electron_charge_C = 1.602176634e-19;
% Extended E01 optical physics. By default, do not load measured data.
% Optional spectral model: "GAUSSIAN", "LORENTZIAN", "CSV".
cfg.laser_profile = "GAUSSIAN";
cfg.ase_profile = "GAUSSIAN";
cfg.laser_spectrum_csv = "";
cfg.ase_spectrum_csv = "";

% Kerr effective differential phase. Identical CW/CCW powers -> no bias.
% gamma_nonlin [1/(W*m)], length [m], relative CW/CCW imbalance [-].
cfg.kerr_enabled = true;
cfg.kerr_gamma_Wm = 1.3e-3;         % illustrative SMF near 1550 nm
cfg.kerr_relative_power_imbalance = 0.05; % DEMO only, not measured

% Single external parasitic reflection: uses parasitic_* above.
% Rayleigh proxy = MANY weak paths with short EXCESS delays, random phases,
% and total scattered power fraction. This is NOT a physical solution of
% distributed first-/double-Rayleigh scattering in 1 km.
cfg.rayleigh_enabled = true;
cfg.rayleigh_path_count = 48;
cfg.rayleigh_total_power_fraction = 2e-5;
cfg.rayleigh_excess_delay_ps = [0.4 15]; % demonstrative path overlap
cfg.rayleigh_random_seed = 20261016;

% Curve experiment is independent of auto-running the Simulink engine.
% No callback may start sweep_E01_simulink() or E01_current_layers().
cfg.omega_layer_points = 101;
cfg.demo_only = true;

cfg.tau_s = cfg.n_group * cfg.L_m / cfg.c_m_s;
if cfg.fm_Hz == 0
    cfg.fm_Hz = 1/(2*cfg.tau_s);
end
end
