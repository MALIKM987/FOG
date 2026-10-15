function out = E01_model(cfg, src)
%E01_MODEL Ideal FOG: common coupler, coil, modulator, photodiode.
% A = source, B = dark detector port at zero phase, C/D = loop ends.
%
% P_B(t,lambda) = P_in(lambda)/2*(1-cos(phi_s+phi_mod)).
% No polarization, losses, RIN, shot noise or Rayleigh backscatter.
% The coherence plot is a SEPARATE surrogate for a delayed parasitic path.

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
for k = 1:nOmega
    omega_rad_s = cfg.omega_test_deg_s(k)*pi/180;
    phiS = K_rad_per_rad_s*omega_rad_s;
    phase = phiS+phase_diff_rad;           % Nx1 plus 1xNt
    pB = cfg.input_power_W/2 * ...
         sum(src.weights.*(1-cos(phase)),1);
    powerB_W(k,:) = pB;
    current_A(k,:) = cfg.responsivity_A_W*pB;
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
out.lockin_A = lockin_A;
out.lockin_formula_A = lockin_formula_A;
out.sweep_deg_s = sweep_deg_s;
out.lockin_sweep_A = I1_sweep_A;
out.est_sweep_deg_s = est_deg_s;
out.coherence_delay_ps = cfg.coherence_delay_ps;
out.coherence_abs = abs(gamma);
end
