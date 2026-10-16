function src = E01_source(cfg,kind)
%E01_SOURCE Source power density, spectral weights and profile metadata.
% R2023b. Backward-compatible Gaussian default, optional Lorentzian
% laser and imported measured spectrum CSV (lambda_nm, S_W_per_nm).
% Same integrated optical power is used for fair LASER vs ASE comparison.
%
% Optional:
%  cfg.laser_profile = "GAUSSIAN" | "LORENTZIAN" | "CSV";
%  cfg.ase_profile   = "GAUSSIAN" | "LORENTZIAN" | "CSV";
%  cfg.laser_spectrum_csv = "path/to/laser.csv";
%  cfg.ase_spectrum_csv = "path/to/ase.csv";
%
% CSV is interpreted as relative spectral density and normalized to
% cfg.input_power_W. Never represent a laboratory measurement by demo PSD.

kind=upper(string(kind));
switch kind
    case "LASER"
        fwhm_nm=cfg.laser_fwhm_nm;
        prefix='laser';
    case "ASE"
        fwhm_nm=cfg.ase_fwhm_nm;
        prefix='ase';
    otherwise
        error('E01:Source','Zrodlo LASER albo ASE.');
end
assert(fwhm_nm>0 && cfg.n_spectral_samples>=5 && ...
    cfg.input_power_W>0,'Niepoprawna moc lub szerokosc widma.');

profileField=[prefix '_profile'];
csvField=[prefix '_spectrum_csv'];
profile="GAUSSIAN";
if isfield(cfg,profileField)
    profile=upper(string(cfg.(profileField)));
end
csvFile='';
if isfield(cfg,csvField)
    csvFile=char(string(cfg.(csvField)));
end

switch profile
    case "GAUSSIAN"
        sigma_nm=fwhm_nm/(2*sqrt(2*log(2)));
        lambda_nm=linspace(cfg.lambda0_nm-4.5*sigma_nm, ...
            cfg.lambda0_nm+4.5*sigma_nm,cfg.n_spectral_samples).';
        shape=exp(-0.5*((lambda_nm-cfg.lambda0_nm)/sigma_nm).^2);
    case "LORENTZIAN"
        % A Lorentzian has long tails. ±100 half widths resolves them
        % without assigning power to the optical carrier oscillation.
        halfWidth=fwhm_nm/2;
        lambda_nm=linspace(cfg.lambda0_nm-100*halfWidth, ...
            cfg.lambda0_nm+100*halfWidth,cfg.n_spectral_samples).';
        shape=1./(1+((lambda_nm-cfg.lambda0_nm)/halfWidth).^2);
    case "CSV"
        assert(~isempty(csvFile)&&isfile(csvFile), ...
            'Brak pliku widma CSV dla %s: %s',kind,csvFile);
        raw=readmatrix(csvFile);
        assert(size(raw,2)>=2 && size(raw,1)>=5 && ...
            all(isfinite(raw(:,1:2)),'all'), ...
            'CSV musi miec >=5 wierszy lambda_nm, S_W_per_nm.');
        lambda_nm=raw(:,1);
        shape=raw(:,2);
        [lambda_nm,order]=sort(lambda_nm);
        shape=shape(order);
        assert(all(diff(lambda_nm)>0)&&all(shape>=0), ...
            'Dlugosci fal musza byc unikalne a gestosci nieujemne.');
    otherwise
        error('E01:Source','Nierozpoznany profil zrodla: %s',profile);
end
assert(all(lambda_nm>0)&&trapz(lambda_nm,shape)>0, ...
    'Widmo musi zawierac dodatnia moc i dodatnie dlugosci fal.');

S=cfg.input_power_W*shape/trapz(lambda_nm,shape);
dLambda=diff(lambda_nm);
trapWeights=zeros(size(lambda_nm));
trapWeights(1)=dLambda(1)/2;
trapWeights(end)=dLambda(end)/2;
trapWeights(2:end-1)=(dLambda(1:end-1)+dLambda(2:end))/2;
weights=S.*trapWeights;
weights=weights/sum(weights);

src.kind=char(kind);
src.lambda_nm=lambda_nm;
src.nu_Hz=cfg.c_m_s./(lambda_nm*1e-9);
src.S_W_per_nm=S;
src.weights=weights;
src.fwhm_nm=fwhm_nm;
src.profile=char(profile);
src.spectrum_csv=csvFile;
src.input_power_W=cfg.input_power_W;
end
