function cfg = E01_config()
%E01_CONFIG Demonstration parameters for the independent FOG-E01-MIS model.
% MATLAB R2023b. All optical parameters are IDEALIZED, NOT lab measurements.
% Units are explicit in names.
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
cfg.demo_only = true;

cfg.tau_s = cfg.n_group * cfg.L_m / cfg.c_m_s;
if cfg.fm_Hz == 0
    cfg.fm_Hz = 1/(2*cfg.tau_s);
end
end
