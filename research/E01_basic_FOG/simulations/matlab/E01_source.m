function src = E01_source(cfg, kind)
%E01_SOURCE Generate laser or ASE *spectral power* model for one FOG.
% Source switch changes only spectrum.  Each lambda grid has its own
% resolution; a 0.02 nm laser peak is NOT sampled on the 20 nm ASE grid.
% All numerical profiles are DEMONSTRATIVE Gaussians, not measured spectra.

kind = upper(string(kind));
switch kind
    case "LASER"
        fwhm_nm = cfg.laser_fwhm_nm;
    case "ASE"
        fwhm_nm = cfg.ase_fwhm_nm;
    otherwise
        error('E01:Source', 'Choose LASER or ASE.');
end
assert(fwhm_nm>0 && cfg.n_spectral_samples>=5, ...
    'Positive FWHM and at least five spectral samples required.');

sigma_nm = fwhm_nm/(2*sqrt(2*log(2)));
lambda_nm = linspace(cfg.lambda0_nm-4.5*sigma_nm, ...
                     cfg.lambda0_nm+4.5*sigma_nm, ...
                     cfg.n_spectral_samples).';
assert(all(lambda_nm>0), 'Invalid wavelength interval.');
shape = exp(-0.5*((lambda_nm-cfg.lambda0_nm)/sigma_nm).^2);

% Density [W/nm] integrated over wavelength [nm] -> source power [W].
density_W_per_nm = cfg.input_power_W*shape/trapz(lambda_nm,shape);
d_nm = lambda_nm(2)-lambda_nm(1);
q = ones(size(lambda_nm)); q([1 end])=0.5; % trapezoid weights
weights = q.*density_W_per_nm*d_nm / cfg.input_power_W;
weights = weights/sum(weights);

src.kind = char(kind);
src.lambda_nm = lambda_nm;
src.nu_Hz = cfg.c_m_s./(lambda_nm*1e-9);
src.S_W_per_nm = density_W_per_nm;
src.weights = weights;
src.fwhm_nm = fwhm_nm;
src.input_power_W = cfg.input_power_W;
end
