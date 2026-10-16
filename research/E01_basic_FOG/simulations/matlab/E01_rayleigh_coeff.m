function out=E01_rayleigh_coeff(cfg,src)
%E01_RAYLEIGH_COEFF Weak N-path Rayleigh-like leakage at FOG detector.
%
% This is an effective FINITE set of double/near-degenerate excess paths.
% It is NOT a calibrated 1000 m distributed Rayleigh propagation solver.
% Each optical source is integrated over its own spectral density.
%
% E_ray(ni) = sqrt(eta_total/N) sum_j exp(i theta_j) *
%             exp(i*2*pi*(ni-nu0)*tau_j).
% Correlated part C=<E_ray>_spectrum;
% noninterfering background q=<|E_ray|^2>-|C|^2.
% The same random scatterer realization is used for LASER and ASE.
%
% Used by Simulink extended blocks, not just plot code.
M=cfg.rayleigh_path_count;
assert(M==floor(M)&&M>=1&&M<=1024, ...
    'Rayleigh requires integer path count 1..1024.');
eta=cfg.rayleigh_total_power_fraction;
assert(eta>=0 && eta<1,'Invalid Rayleigh power fraction.');
d=cfg.rayleigh_excess_delay_ps;
assert(numel(d)==2 && all(isfinite(d)) && ...
    d(1)>=0 && d(2)>=d(1),'Invalid Rayleigh delay range.');

rs=RandStream('mt19937ar','Seed',cfg.rayleigh_random_seed);
theta=2*pi*rand(rs,1,M);
tau=linspace(d(1),d(2),M)*1e-12;
nu0=cfg.c_m_s/(cfg.lambda0_nm*1e-9);
freq=(src.nu_Hz(:)-nu0);
phasors=exp(1i*2*pi*(freq*tau));
e=sqrt(eta/M)*(phasors*exp(1i*theta(:)));
weights=src.weights(:);
C=sum(weights.*e);
meanP=sum(weights.*abs(e).^2);
q=max(0,real(meanP-abs(C)^2));
out=struct('coherent',C,'incoherent',q, ...
    'total_power_fraction',meanP, ...
    'path_count',M,'delay_ps',d);
end
