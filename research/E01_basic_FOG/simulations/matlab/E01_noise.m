function noise = E01_noise(cfg, src, i_reference_A, sampling_Hz)
%E01_NOISE Reduced-order photodiode fluctuations: ASE excess RIN + shot noise.
%
% This is NOT a time-resolved optical field simulation. FOG delay is ~5 us,
% while ASE optical coherence time is ~0.2 ps. Resolving the optical field
% over the full FOG transit would be computationally prohibitive.
%
% The optical spectral density is used to estimate effective noise
% bandwidth B_eff = (integral S_nu dnu)^2 / integral S_nu^2 dnu.
%
% Thermal-like SCALAR ASE has approximate one-sided low-frequency RIN
% PSD ~ 2/(M*B_eff) [Hz^-1] for M statistically independent modes.
% Real ASE depends on polarization, filtering, pump, gain and other noise.
% For LASER we use an ILLUSTRATIVE measured-like flat RIN parameter,
% not inferred from spectral linewidth. Both include ideal shot noise:
% variance = 2*q*I*B_e for single-sided bandwidth B_e.
%
% Independent band-limited random signals are applied around deterministic
% detected current. This is an ELECTRICAL-ENVELOPE approximation, not
% propagation of stochastic ASE waveforms or a full receiver noise budget.

assert(isfield(cfg,'noise_enabled'), 'Missing noise configuration');
assert(sampling_Hz>0 && cfg.electrical_bandwidth_Hz>0, ...
    'Sampling and electrical bandwidth must be positive');
assert(cfg.electrical_bandwidth_Hz < sampling_Hz/2, ...
    'Receiver bandwidth must be below electrical Nyquist frequency');

lam_m=src.lambda_nm(:)*1e-9;
density_W_nm=src.S_W_per_nm(:);
dlambda_nm=src.lambda_nm(2)-src.lambda_nm(1);
quadrature=ones(size(lam_m));
quadrature([1 end])=0.5;

% S_nu = S_lambda_nm * abs(dlambda_nm/dnu) with
% abs(dlambda_nm/dnu) = 1e9*lambda_m^2/c [nm/Hz].
int_s2_dnu=sum(quadrature .* (density_W_nm.^2) .* ...
    (1e9*lam_m.^2/cfg.c_m_s)) * dlambda_nm;
optical_eff_Hz=src.input_power_W^2/int_s2_dnu;
assert(optical_eff_Hz>0 && isfinite(optical_eff_Hz), ...
    'Invalid optical effective bandwidth');

if strcmpi(src.kind,'ASE')
    rin_one_sided_per_Hz=2/(cfg.ase_effective_mode_count*optical_eff_Hz);
else
    rin_one_sided_per_Hz=10^(cfg.laser_rin_dB_Hz/10);
end
assert(rin_one_sided_per_Hz>0, 'Invalid source RIN');

noise.source_rin_per_Hz=rin_one_sided_per_Hz;
noise.source_rin_dB_Hz=10*log10(rin_one_sided_per_Hz);
noise.optical_effective_bandwidth_Hz=optical_eff_Hz;
noise.electrical_bandwidth_Hz=cfg.electrical_bandwidth_Hz;
noise.current_reference_A=i_reference_A;
noise.current_noisy_A=i_reference_A;
noise.source_rin_A=zeros(size(i_reference_A));
noise.shot_A=zeros(size(i_reference_A));
noise.noise_enabled=cfg.noise_enabled;

if ~cfg.noise_enabled
    return;
end

% Separate deterministic seeds per source; do not contaminate global RNG.
seed=cfg.noise_seed + sum(double(src.kind));
stream=RandStream('mt19937ar','Seed',seed);
[Nomega,Nt]=size(i_reference_A);
for k=1:Nomega
    zSource=filtered_white(stream,Nt,sampling_Hz, ...
        cfg.electrical_bandwidth_Hz);
    zShot=filtered_white(stream,Nt,sampling_Hz, ...
        cfg.electrical_bandwidth_Hz);
    iClean=max(i_reference_A(k,:),0);
    rinAmplitude=sqrt(rin_one_sided_per_Hz * ...
        cfg.electrical_bandwidth_Hz);
    noise.source_rin_A(k,:)=iClean .* rinAmplitude .* zSource;
    noise.shot_A(k,:)=sqrt(2*cfg.electron_charge_C .* iClean .* ...
        cfg.electrical_bandwidth_Hz) .* zShot;
end
noise.current_noisy_A = i_reference_A + ...
    noise.source_rin_A + noise.shot_A;
end

function y=filtered_white(stream,N,fs,B)
% Band-limited, normalized real Gaussian noise without any toolbox.
z=randn(stream,1,N);
f=(0:N-1)*fs/N;
mask=(f<=B)|(f>=fs-B);
y=real(ifft(fft(z).*mask));
s=std(y,1);
assert(s>0,'Invalid spectral noise realization');
y=(y-mean(y))/s;
end
