function ok = test_E01()
%TEST_E01 Deterministic unit checks for MATLAB E01 model (no Simulink).
% Call:
%   addpath(fullfile('research','E01_basic_FOG','simulations','matlab'));
%   assert(test_E01());
%
% These are numerical MODEL tests, not hardware or metrological validation.

cfg=E01_config();
cfg.parasitic_enabled=false;   % Validate the ideal model independently.
c=cfg.c_m_s;
K0=2*pi*cfg.L_m*cfg.D_m/(cfg.lambda0_nm*1e-9*c);
assert(abs(K0-2.1635)<0.001, 'Unexpected Sagnac scale.');
assert(abs(cfg.fm_Hz*2*cfg.tau_s-1)<1e-12, ...
    'Proper frequency does not match group delay.');

l=E01_source(cfg,"LASER");
a=E01_source(cfg,"ASE");
assert(abs(sum(l.weights)-1)<1e-12 && ...
       abs(sum(a.weights)-1)<1e-12, 'Weights do not sum to 1.');
assert(abs(trapz(l.lambda_nm,l.S_W_per_nm)-cfg.input_power_W)<1e-12);
assert(abs(trapz(a.lambda_nm,a.S_W_per_nm)-cfg.input_power_W)<1e-12);

mL=E01_model(cfg,l);
mA=E01_model(cfg,a);
assert(abs(mL.beta_rad-2*cfg.phi0_rad)<1e-11, ...
    'Modulator: incorrect differential amplitude at proper frequency.');
assert(max(abs(mL.phase_diff_rad-(mL.phase_late_rad-...
    mL.phase_early_rad)))<1e-12,'Modulator difference mismatch.');

for m={mL,mA}
    q=m{1};
    assert(min(q.powerB_W(:)) > -1e-11, ...
        'Negative optical power detected.');
    assert(max(q.powerB_W(:)) <= cfg.input_power_W*(1+1e-12), ...
        'Energy conservation violated.');
    assert(max(abs(q.lockin_A-q.lockin_formula_A)) < 1e-10, ...
        'Lock-in disagrees with the analytic Bessel coefficient.');
    iP=find(q.omega_deg_s==1,1);
    iN=find(q.omega_deg_s==-1,1);
    iZ=find(q.omega_deg_s==0,1);
    assert(q.lockin_A(iP)>0 && q.lockin_A(iN)<0, ...
        'Rotation direction not recovered correctly.');
    assert(abs(q.lockin_A(iP)+q.lockin_A(iN))<1e-10, ...
        'Signed lock-in not antisymmetric.');
    assert(abs(q.lockin_A(iZ))<1e-10,'Lock-in zero-rate bias.');
    assert(abs(q.coherence_abs(1)-1)<1e-10, ...
        'Zero-delay coherence must equal unity.');
end
assert(mA.coherence_abs(end)<0.1 && mL.coherence_abs(end)>0.95, ...
    'Coherence demonstration fails to distinguish bandwidths.');

% Switch off modulation. Output power must be even in Omega.
cfgZero=cfg; cfgZero.phi0_rad=0;
q=E01_model(cfgZero,l);
iP=find(q.omega_deg_s==1,1);
iN=find(q.omega_deg_s==-1,1);
iZ=find(q.omega_deg_s==0,1);
assert(max(abs(q.powerB_W(iP,:)-q.powerB_W(iN,:)))<1e-10, ...
    'Unmodulated response should be even in Omega.');
assert(max(abs(q.powerB_W(iZ,:)))<1e-10, ...
    'Dark port at rest should be zero without modulation.');

% At 1/tau sinusoidal differential phase vanishes, unlike at 1/(2*tau).
cfgNull=cfg;
cfgNull.fm_Hz=1/cfg.tau_s;
qNull=E01_model(cfgNull,l);
assert(max(abs(qNull.phase_diff_rad))<1e-10, ...
    'Frequency of zero differential modulation failed.');

% Source-dependent *observed* current with one extra delayed optical path.
cfgStray=cfg;
cfgStray.parasitic_enabled=true;
qL=E01_model(cfgStray,l);
qA=E01_model(cfgStray,a);
iP=find(qL.omega_deg_s==1,1);
assert(max(abs(qL.current_observed_A(iP,:)- ...
    qA.current_observed_A(iP,:)))>1e-6, ...
    'Switching source does not change the observed photodiode waveform.');
assert(max(abs(qL.current_A(:)-mL.current_A(:)))<1e-12, ...
    'Enabling parasitic field must not change the original ideal output.');
assert(max(abs(qA.current_A(:)-mA.current_A(:)))<1e-12, ...
    'Enabling parasitic field must not change the original ideal ASE output.');

fprintf('PASS: E01 optical power, spectra, phase, lock-in, coherence and source switching.\n');
fprintf('Scope: ideal numerical model, not MATLAB/Simulink hardware validation.\n');
ok=true;
end
