function out = E01_model(cfg, src)
%E01_MODEL Ideal FOG: common coupler, coil, modulator, photodiode.
% A = source, B = dark detector port at zero phase, C/D = loop ends.
%
% P_B(t,lambda) = P_in(lambda)/2*(1-cos(phi_s+phi_mod)).
% No polarization, losses, RIN, shot noise or Rayleigh backscatter.
% Optional parasitic field is a deliberately simplified extra delayed
% detector-side coherent field, NOT distributed Rayleigh scattering.
% Ideal photodiode arrays remain separate for analytic model tests.

c = cfg.c_m_s;
tau_s = cfg.tau_s;
fm = cfg.fm_Hz;
phi0 = cfg.phi0_rad;
beta = 2*phi0*sin(pi*fm*tau_s);   % SIGNED modulation depth

Nt = cfg.n_periods*cfg.samples_per_period;
t_s = (0:Nt-1)/(cfg.samples_per_period*fm);
phase_early_rad = phi0*sin(2*pi*fm*(t_s-tau_s));
phase_late_rad = phi0*sin(2*pi*fm*t_s);
phase_diff_rad = phase_late_rad-phase_early_rad;
theta_rad = 2*pi*fm*(t_s-tau_s/2);
ref = cos(theta_rad);            % lock-in reference, same for BOTH sources

K_rad_per_rad_s = 2*pi*cfg.L_m*cfg.D_m./(src.lambda_nm*1e-9*c);
nOmega = numel(cfg.omega_test_deg_s);
current_A = zeros(nOmega,Nt);
powerB_W = zeros(nOmega,Nt);
lockin_A = zeros(nOmega,1);
lockin_formula_A = zeros(nOmega,1);
powerB_observed_W = zeros(nOmega,Nt);
current_observed_A = zeros(nOmega,Nt);
lockin_observed_A = zeros(nOmega,1);

hasParasitic = isfield(cfg,'parasitic_enabled') && cfg.parasitic_enabled;
if hasParasitic
    eta=cfg.parasitic_power_fraction;
    assert(eta>=0 && eta<1, ...
        'Parasitic power fraction must be between 0 and 1.');
    nu0=c/(cfg.lambda0_nm*1e-9);
    % The optical carrier phase at nu0 is absorbed in the phase offset.
    strayField = sqrt(eta)*exp(1i*(cfg.parasitic_phase_rad + ...
        2*pi*(src.nu_Hz-nu0)*cfg.parasitic_delay_ps*1e-12));
end
for k = 1:nOmega
    omega_rad_s = cfg.omega_test_deg_s(k)*pi/180;
    phiS = K_rad_per_rad_s*omega_rad_s;
    phase = phiS+phase_diff_rad;           % Nx1 plus 1xNt
    pB = cfg.input_power_W/2 * ...
         sum(src.weights.*(1-cos(phase)),1);
    powerB_W(k,:) = pB;
    current_A(k,:) = cfg.responsivity_A_W*pB;
    if hasParasitic
        % Base normalized detector amplitude produces the dark-port power:
        % abs((1-exp(1i*phase))/2)^2 = (1-cos(phase))/2.
        mainField = (1-exp(1i*phase))/2;
        % A SINGLE stray detector-side path for a COHERENCE DEMONSTRATION.
        % It is not a calibrated, fully unitary scattering network.
        observed = cfg.input_power_W * ...
            sum(src.weights.*abs(mainField+strayField).^2,1);
    else
        observed = pB;
    end
    powerB_observed_W(k,:) = observed;
    current_observed_A(k,:) = cfg.responsivity_A_W*observed;
    lockin_observed_A(k) = 2*mean(current_observed_A(k,:).*ref);
    lockin_A(k) = 2*mean(current_A(k,:).*ref);
    lockin_formula_A(k) = cfg.responsivity_A_W* ...
        cfg.input_power_W*besselj(1,beta)* ...
        sum(src.weights.*sin(phiS));
end

sweep_deg_s = cfg.omega_sweep_deg_s(:).';
phiSweep = K_rad_per_rad_s*(sweep_deg_s*pi/180);
I1_sweep_A = cfg.responsivity_A_W*cfg.input_power_W* ...
    besselj(1,beta)*sum(src.weights.*sin(phiSweep),1);
gain_A_per_rad_s = cfg.responsivity_A_W*cfg.input_power_W* ...
    besselj(1,beta)*sum(src.weights.*K_rad_per_rad_s);
if abs(gain_A_per_rad_s)<eps
    est_deg_s = nan(size(sweep_deg_s));
else
    est_deg_s = I1_sweep_A/gain_A_per_rad_s*180/pi;
end

% Coarse-grained source statistics at the PHOTOdiode electrical bandwidth.
% Keep deterministic and random signals as separate arrays for comparison.
sampling_Hz=cfg.samples_per_period*cfg.fm_Hz;
noise=E01_noise(cfg,src,current_observed_A,sampling_Hz);

% Degree-of-coherence magnitude versus DELAY OF AN EXTRA PATH.
% Optical carrier removed to avoid ultrafast fringes; modulus unchanged.
delay_s = cfg.coherence_delay_ps(:).'*1e-12;
nu_center = c/(cfg.lambda0_nm*1e-9);
gamma = sum(src.weights.*exp(1i*2*pi* ...
    (src.nu_Hz-nu_center)*delay_s),1);

out.source = src;
out.t_s = t_s;
out.phase_early_rad = phase_early_rad;
out.phase_late_rad = phase_late_rad;
out.phase_diff_rad = phase_diff_rad;
out.reference = ref;
out.beta_rad = beta;
out.tau_s = tau_s;
out.K_lambda = K_rad_per_rad_s;
out.omega_deg_s = cfg.omega_test_deg_s(:);
out.powerB_W = powerB_W;
out.current_A = current_A;
out.powerB_observed_W = powerB_observed_W;
out.current_observed_A = current_observed_A;
out.current_measured_A = noise.current_noisy_A;
out.noise_rin_A = noise.source_rin_A;
out.noise_shot_A = noise.shot_A;
out.noise_rin_dB_Hz = noise.source_rin_dB_Hz;
out.optical_noise_bandwidth_Hz = noise.optical_effective_bandwidth_Hz;
out.electrical_bandwidth_Hz = noise.electrical_bandwidth_Hz;
out.noise_enabled = noise.noise_enabled;
out.lockin_observed_A = lockin_observed_A;
out.parasitic_enabled = hasParasitic;
out.lockin_A = lockin_A;
out.lockin_formula_A = lockin_formula_A;
out.sweep_deg_s = sweep_deg_s;
out.lockin_sweep_A = I1_sweep_A;
out.est_sweep_deg_s = est_deg_s;
out.coherence_delay_ps = cfg.coherence_delay_ps;
out.coherence_abs = abs(gamma);
end
